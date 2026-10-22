import 'migration_context.dart';
import 'migration_failure.dart';

/// A single, versioned, idempotent data migration.
///
/// A step transforms a container from [fromVersion] to [toVersion]. Steps are
/// applied in ascending [fromVersion] order and each one must be safe to
/// re-run: applying it to already-migrated data must be a no-op.
abstract class Migration {
  const Migration();

  /// The version this step consumes (the container version before it runs).
  int get fromVersion;

  /// The version this step produces (the container version after it runs).
  int get toVersion;

  /// A stable identifier, e.g. `m001_attributes_to_map`.
  ///
  /// Appears in logs and telemetry; must not change between releases.
  String get id;

  /// A grouping label, e.g. `attributes`.
  ///
  /// Used for grouping in telemetry and in the "Repair data" UI. It does
  /// **not** affect ordering or versioning - there is one counter.
  String get family;

  /// Applies the migration to the container behind [ctx].
  ///
  /// Implementations must throw a [MigrationFailure] (or any error) to abort
  /// the run. The runner catches it, leaves the version untouched and
  /// reports the failure. Implementations must never advance the version
  /// themselves - the runner owns that, after the integrity check passes.
  Future<void> run(MigrationContext ctx);
}
