import '../../app_constants.dart';
import 'migration.dart';
import 'migration_context.dart';
import 'migration_failure.dart';
import 'migration_integrity_check.dart';
import 'migration_log.dart';
import 'migration_run_result.dart';

/// Applies the outstanding migration steps to a container.
///
/// The runner owns the **incremental** semantics:
///
/// 1. Read the container's current version (default `0`).
/// 2. Select the registered steps whose `toVersion` is greater than the
///    current version - i.e. the steps still to be applied - sorted ascending
///    by `fromVersion`.
/// 3. Run them in that order. For each step: run the migration, then verify
///    the integrity of the result, and only then advance the recorded
///    version to the step's `toVersion`.
/// 4. Stop at the **first** failing step. The failing step's version is not
///    advanced, the version stays at the last successfully applied step, and
///    the failure is reported.
///
/// The ordering rule (write data -> verify -> advance version) is what makes
/// a crash safe: a container can never claim a version whose data it does not
/// have. Because the version is persisted after every successful step, a
/// crash or a failure resumes exactly at the next outstanding step.
///
/// Re-running the runner against an up-to-date container is a no-op.
class MigrationRunner {
  const MigrationRunner({
    required this.steps,
    int? targetVersion,
    this.force = false,
  }) : _targetVersion = targetVersion;

  /// The ordered registry of known steps.
  ///
  /// The runner sorts them itself, so the registration order does not matter.
  final List<Migration> steps;

  /// When `true`, re-runs every step up to [targetVersion] regardless of the
  /// container's current version. Used by the "Repair data" flow to recover
  /// from a partially-interrupted migration.
  final bool force;

  /// The schema version this runner migrates up to.
  ///
  /// Defaults to [AppConstants.currentWordSchemaVersion]. It is injectable
  /// so a runner can be tested against a specific version chain without
  /// changing the app-wide constant.
  final int? _targetVersion;

  /// The version this runner migrates up to.
  int get targetVersion =>
      _targetVersion ?? AppConstants.currentWordSchemaVersion;

  /// Runs every outstanding step against [ctx].
  ///
  /// Never throws: a failure is captured in the returned
  /// [MigrationRunResult]. This keeps a migration failure from taking the
  /// app down at start-up.
  Future<MigrationRunResult> run(MigrationContext ctx) async {
    final scope = ctx.scopeLabel;

    final int currentVersion;
    try {
      currentVersion = await ctx.readVersion();
    } catch (e, s) {
      final failure = MigrationFailure(
        code: MigrationFailureCode.unknown,
        stepId: _runnerStepId,
        message: 'could not read the container version',
        cause: e,
        stackTrace: s,
      );
      MigrationLog.stepFailure(failure);
      return MigrationRunResult.aborted(
        fromVersion: 0,
        toVersion: 0,
        failure: failure,
        stepsRun: 0,
      );
    }

    final selected = selectSteps(currentVersion);

    MigrationLog.runStart(
      scope: scope,
      currentVersion: currentVersion,
      targetVersion: targetVersion,
      stepIds: selected.map((step) => step.id).toList(growable: false),
      force: force,
    );

    if (selected.isEmpty) {
      MigrationLog.runSuccess(
        scope: scope,
        fromVersion: currentVersion,
        toVersion: currentVersion,
        stepsRun: 0,
      );
      return MigrationRunResult.success(
        fromVersion: currentVersion,
        toVersion: currentVersion,
        stepsRun: 0,
      );
    }

    var containerVersion = currentVersion;
    var stepsRun = 0;
    final stepIds = <String>[];

    for (final step in selected) {
      MigrationLog.stepStart(
        stepId: step.id,
        family: step.family,
        fromVersion: step.fromVersion,
        toVersion: step.toVersion,
      );

      try {
        // The pre-migration payload is captured before the step runs, so the
        // integrity check can compare it with the post-migration payload.
        final before = await ctx.readWords();

        await step.run(ctx);

        final after = await ctx.readWords();
        final report = MigrationIntegrityCheck.compare(before, after);

        MigrationLog.integrity(
          stepId: step.id,
          beforeCount: report.beforeCount,
          afterCount: report.afterCount,
          missing: report.missing.length,
          added: report.added.length,
          changed: report.changed.length,
          unchanged: report.unchanged,
        );

        if (!report.isValid) {
          throw MigrationFailure(
            code: MigrationFailureCode.integrityMismatch,
            stepId: step.id,
            message: 'the integrity check found missing records',
            details: {
              'beforeCount': report.beforeCount,
              'afterCount': report.afterCount,
              'missing': report.missing.length,
            },
          );
        }

        // Only now, with the data durably written and verified, is the
        // version advanced.
        await ctx.writeVersion(step.toVersion);
        containerVersion = step.toVersion;
        stepsRun++;
        stepIds.add(step.id);

        MigrationLog.stepSuccess(
          stepId: step.id,
          fromVersion: step.fromVersion,
          toVersion: step.toVersion,
          recordsRead: report.beforeCount,
          recordsWritten: report.afterCount,
        );
      } catch (e, s) {
        final failure = _toFailure(e, s, step);
        MigrationLog.stepFailure(failure);
        MigrationLog.runAborted(
          scope: scope,
          currentVersion: containerVersion,
          failure: failure,
          stepsCompleted: stepsRun,
        );
        return MigrationRunResult.aborted(
          fromVersion: currentVersion,
          toVersion: containerVersion,
          failure: failure,
          stepsRun: stepsRun,
          stepIds: stepIds,
        );
      }
    }

    MigrationLog.runSuccess(
      scope: scope,
      fromVersion: currentVersion,
      toVersion: containerVersion,
      stepsRun: stepsRun,
    );

    return MigrationRunResult.success(
      fromVersion: currentVersion,
      toVersion: containerVersion,
      stepsRun: stepsRun,
      stepIds: stepIds,
    );
  }

  /// Selects the steps that still have to be applied to a container at
  /// [currentVersion].
  ///
  /// A step is outstanding when its `toVersion` is greater than the recorded
  /// version. The steps are returned sorted ascending by `fromVersion`, so
  /// they are always applied in order.
  ///
  /// A step whose `toVersion` exceeds the app's declared current schema
  /// version is **rejected**: it would advance a container past what this
  /// build understands, which is a downgrade hazard. Such a step is skipped
  /// and reported through the log.
  List<Migration> selectSteps(int currentVersion) {
    final selected = steps
        .where((step) => force || step.toVersion > currentVersion)
        .where((step) => step.toVersion <= targetVersion)
        .toList()
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));

    for (final step in steps) {
      if (step.toVersion > targetVersion) {
        MigrationLog.warning(
          'step.rejected id=${step.id} toVersion=${step.toVersion} '
          'exceeds the app schema version $targetVersion',
        );
      }
    }

    return selected;
  }

  /// Normalizes an arbitrary error into a [MigrationFailure].
  static MigrationFailure _toFailure(Object e, StackTrace s, Migration step) {
    if (e is MigrationFailure) {
      return e;
    }
    return MigrationFailure(
      code: MigrationFailureCode.unknown,
      stepId: step.id,
      message: 'the migration step failed',
      cause: e,
      stackTrace: s,
    );
  }

  /// The synthetic step id used for failures that happen outside a step.
  static const String _runnerStepId = 'runner';
}
