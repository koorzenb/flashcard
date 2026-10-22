/// Stable, loggable identifiers for why a migration step failed.
///
/// The [wireName] is what appears in the console output and in telemetry, so
/// it must stay stable across releases - do not rename an existing code.
enum MigrationFailureCode {
  /// A record could not be parsed into its target shape.
  parseFailed('parse_failed'),

  /// The migrated data could not be written to the container.
  writeFailed('write_failed'),

  /// The integrity check found a discrepancy between the pre- and
  /// post-migration payloads.
  integrityMismatch('integrity_mismatch'),

  /// The data was written but the version marker could not be advanced.
  versionAdvanceFailed('version_advance_failed'),

  /// The container could not be reached (offline, permission denied, ...).
  networkUnavailable('network_unavailable'),

  /// The step was intentionally skipped or aborted by the caller.
  cancelled('cancelled'),

  /// An error that does not fit any other code.
  unknown('unknown');

  const MigrationFailureCode(this.wireName);

  /// The stable, machine-readable name used in logs and telemetry.
  final String wireName;
}

/// A structured migration failure.
///
/// Carries a stable [code] so that failures can be counted and triaged, plus
/// the [stepId] that produced it. The [details] map may only contain counts,
/// version numbers and identifiers - never word text, translations or audio
/// URLs (see the plan's Security Requirements).
class MigrationFailure implements Exception {
  MigrationFailure({
    required this.code,
    required this.stepId,
    required this.message,
    this.cause,
    this.stackTrace,
    this.details = const {},
  });

  /// Why the step failed.
  final MigrationFailureCode code;

  /// The migration step that failed (e.g. `m001_attributes_to_map`).
  final String stepId;

  /// A human-readable, content-free description.
  final String message;

  /// The original error, if any.
  final Object? cause;

  /// The stack trace of the original error, if any.
  final StackTrace? stackTrace;

  /// Extra diagnostic values: counts, versions, identifiers. Never content.
  final Map<String, Object?> details;

  @override
  String toString() =>
      'MigrationFailure(${code.wireName}, step: $stepId): $message';
}
