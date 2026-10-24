import '../../models/word.dart';

/// The storage-agnostic interface a migration operates on.
///
/// Implementations exist for Hive (`HiveWordMigrationContext`) and for
/// Firestore (`FirestoreWordMigrationContext`), so a migration's `run()` is
/// written exactly once and works against both.
///
/// This file deliberately contains no Hive and no Firebase imports, so the
/// migration layer stays unit-testable with a fake context.
abstract class MigrationContext {
  /// The words currently stored in the container, in whatever persisted shape
  /// they have. The implementation is responsible for tolerating legacy
  /// shapes (see the tolerant readers in Phase 1).
  Future<List<Word>> readWords();

  /// Replaces the container's words with [words].
  ///
  /// For Hive this must use the backup-first write sequence (write a shadow
  /// key, copy the current value to a backup, then swap). For Firestore this
  /// must only normalize field shapes - it must never add or remove
  /// documents.
  ///
  /// Throws a [MigrationFailure] if the write could not be completed.
  Future<void> writeWords(List<Word> words);

  /// The container's current data version.
  ///
  /// Returns `0` for a container that has never been migrated.
  Future<int> readVersion();

  /// Advances the container's data version to [version].
  ///
  /// The runner calls this **only after** the data write and the integrity
  /// check have both succeeded, so a crash can never leave a container
  /// claiming a version its data does not have.
  Future<void> writeVersion(int version);

  /// Optional hook: a short label for the container, used in log lines to
  /// identify the scope of a run. Defaults to an empty string.
  String get scopeLabel => '';
}
