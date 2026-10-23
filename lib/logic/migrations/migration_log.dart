import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'migration_failure.dart';

/// Emits structured, privacy-safe diagnostics for the migration framework.
///
/// Every log line is prefixed with a stable tag so that a developer can
/// filter the console output with a single search (e.g. `MIGRATION`).
///
/// Privacy rules (enforced by convention and by the plan's Security
/// Requirements): log **counts, version numbers, step ids and failure
/// codes** only. Never log word text, translations, pronunciations, audio
/// URLs, e-mail addresses or user ids.
class MigrationLog {
  const MigrationLog._();

  /// The tag every migration log line starts with.
  static const String tag = 'MIGRATION';

  /// Verbose events (run/step lifecycle) are emitted in debug and profile
  /// builds only. Warnings and failures are **always** emitted, including in
  /// release builds, because a failed migration is exactly the situation a
  /// user needs to report.
  static bool get _verboseEnabled => !kReleaseMode;

  /// Logs the start of a migration run.
  static void runStart({
    required String scope,
    required int currentVersion,
    required int targetVersion,
    required List<String> stepIds,
    bool force = false,
  }) {
    if (!_verboseEnabled) return;
    _emit(
      'run.start',
      'scope=$scope current=$currentVersion target=$targetVersion '
          'steps=${stepIds.isEmpty ? 'none' : stepIds.join(',')}'
          '${force ? ' force=true' : ''}',
    );
  }

  /// Logs that a run finished successfully.
  static void runSuccess({
    required String scope,
    required int fromVersion,
    required int toVersion,
    required int stepsRun,
  }) {
    if (!_verboseEnabled) return;
    _emit(
      'run.success',
      'scope=$scope from=$fromVersion to=$toVersion steps=$stepsRun',
    );
  }

  /// Logs that a run was aborted because a step failed.
  ///
  /// This is the key diagnostic line: it states explicitly that the
  /// operation was **aborted**, that the version was **not** advanced, and
  /// what the operator should look at next.
  static void runAborted({
    required String scope,
    required int currentVersion,
    required MigrationFailure failure,
    required int stepsCompleted,
  }) {
    _emit(
      'run.aborted',
      'scope=$scope current=$currentVersion stepsCompleted=$stepsCompleted '
          'code=${failure.code.wireName} step=${failure.stepId} '
          'message=${failure.message}'
          '${failure.details.isEmpty ? '' : ' details=${failure.details}'}',
      isError: true,
    );
  }

  /// Logs the start of a single step.
  static void stepStart({
    required String stepId,
    required String family,
    required int fromVersion,
    required int toVersion,
  }) {
    if (!_verboseEnabled) return;
    _emit(
      'step.start',
      'id=$stepId family=$family from=$fromVersion to=$toVersion',
    );
  }

  /// Logs the successful completion of a single step.
  static void stepSuccess({
    required String stepId,
    required int fromVersion,
    required int toVersion,
    int recordsRead = 0,
    int recordsWritten = 0,
  }) {
    if (!_verboseEnabled) return;
    _emit(
      'step.success',
      'id=$stepId from=$fromVersion to=$toVersion '
          'read=$recordsRead written=$recordsWritten',
    );
  }

  /// Logs a failed step. The operation is aborted by the caller.
  static void stepFailure(MigrationFailure failure) {
    _emit(
      'step.failure',
      'code=${failure.code.wireName} step=${failure.stepId} '
          'message=${failure.message}'
          '${failure.details.isEmpty ? '' : ' details=${failure.details}'}',
      isError: true,
    );
  }

  /// Logs the result of the integrity check.
  static void integrity({
    required String stepId,
    required int beforeCount,
    required int afterCount,
    required int missing,
    required int added,
    required int changed,
    required int unchanged,
  }) {
    _emit(
      'integrity',
      'step=$stepId before=$beforeCount after=$afterCount '
          'missing=$missing added=$added changed=$changed unchanged=$unchanged',
      // A non-zero `missing` or `added` count means the data does not match;
      // that is a failure condition and must be visible in release builds.
      isError: missing > 0 || added > 0,
    );
  }

  /// Logs a free-form, content-free diagnostic message.
  static void info(String message) {
    if (!_verboseEnabled) return;
    _emit('info', message);
  }

  /// Logs a warning. Always emitted.
  static void warning(String message) => _emit('warn', message);

  static void _emit(String event, String message, {bool isError = false}) {
    developer.log(
      '$event $message',
      name: tag,
      level: isError ? 1000 : 500,
      error: isError ? message : null,
    );
  }
}
