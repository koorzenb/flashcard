import 'migration_failure.dart';

/// The outcome of a migration run.
///
/// A run either completes every selected step, or it is **aborted** at the
/// first failure with nothing further applied. There is no partial-success
/// state: the caller always knows exactly where the container stands.
final class MigrationRunResult {
  const MigrationRunResult._({
    required this.status,
    required this.fromVersion,
    required this.toVersion,
    required this.stepsRun,
    this.failure,
    this.stepIds = const [],
  });

  /// The run completed and the version was advanced to [toVersion].
  const MigrationRunResult.success({
    required int fromVersion,
    required int toVersion,
    required int stepsRun,
    List<String> stepIds = const [],
  }) : this._(
         status: MigrationRunStatus.success,
         fromVersion: fromVersion,
         toVersion: toVersion,
         stepsRun: stepsRun,
         stepIds: stepIds,
       );

  /// The run was aborted at the first failing step.
  ///
  /// [fromVersion] is the version the container had before the run and
  /// [toVersion] is the version it has after it.
  ///
  /// The two differ when earlier steps of the same run had already
  /// succeeded: their versions stay advanced (each step's version is
  /// persisted the moment that step succeeds), so the next run resumes at the
  /// failing step instead of redoing completed work. When the **first**
  /// selected step fails, [toVersion] equals [fromVersion] and the container
  /// is completely untouched.
  ///
  /// The failing step's own version is **never** advanced.
  const MigrationRunResult.aborted({
    required int fromVersion,
    required int toVersion,
    required MigrationFailure failure,
    required int stepsRun,
    List<String> stepIds = const [],
  }) : this._(
         status: MigrationRunStatus.aborted,
         fromVersion: fromVersion,
         toVersion: toVersion,
         stepsRun: stepsRun,
         failure: failure,
         stepIds: stepIds,
       );

  /// Whether the run completed or was aborted.
  final MigrationRunStatus status;

  /// The container version before the run.
  final int fromVersion;

  /// The container version after the run.
  ///
  /// On an aborted run this is the version of the last step that completed
  /// successfully, which equals [fromVersion] when the first selected step
  /// was the one that failed.
  final int toVersion;

  /// The number of steps that completed successfully.
  final int stepsRun;

  /// The failure that aborted the run, if any.
  final MigrationFailure? failure;

  /// The ids of every step that was executed in this run.
  ///
  /// Empty for a no-op run (when the container was already up to date and
  /// `force` was not requested). Populated even for idempotent re-runs when
  /// `force` is `true`.
  final List<String> stepIds;

  /// Whether the run completed successfully.
  bool get isSuccess => status == MigrationRunStatus.success;

  /// Whether the run was aborted.
  bool get isAborted => status == MigrationRunStatus.aborted;

  @override
  String toString() =>
      'MigrationRunResult(${status.name}, '
      'from: $fromVersion, to: $toVersion, steps: $stepsRun'
      '${failure == null ? '' : ', failure: $failure'})';
}

/// The outcome of a migration run.
enum MigrationRunStatus {
  /// Every selected step completed and the version was advanced.
  success,

  /// The run stopped at the first failure. Nothing after that point was
  /// applied and the version was not advanced past the failing step.
  aborted,
}
