import '../../storage/word_storage.dart';
import 'hive_word_migration_context.dart';
import 'migration_registry.dart';
import 'migration_runner.dart';
import 'migration_run_result.dart';

/// Runs the migrations for the local (per-user) word container.
///
/// This is called during the app bootstrap, **after** the user's word box has
/// been opened and **before** the word list is read into the controller.
/// Running it earlier would let the controller read un-migrated data and
/// write it back, re-contaminating the box.
///
/// A failed migration is **not** fatal: the runner returns an aborted result
/// and the app continues with the data as it is. The tolerant readers
/// guarantee the data is still usable, and the next launch retries.
class WordMigrationBootstrap {
  const WordMigrationBootstrap._();

  /// Runs the outstanding migrations for the signed-in user's word box.
  static Future<MigrationRunResult> run() async {
    if (!WordStorage.isInitialized) {
      return const MigrationRunResult.success(
        fromVersion: 0,
        toVersion: 0,
        stepsRun: 0,
      );
    }

    final context = HiveWordMigrationContext(
      box: WordStorage.box.rawBox,
      scopeLabel: 'local-words',
    );

    final runner = MigrationRunner(steps: MigrationRegistry.steps);
    return runner.run(context);
  }
}
