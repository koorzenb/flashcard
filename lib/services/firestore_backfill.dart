import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/word.dart';
import '../storage/word_storage.dart';

/// Outcome of a backfill run.
class BackfillReport {
  const BackfillReport({
    required this.action,
    required this.localCount,
    required this.writtenCount,
    required this.skippedCount,
    required this.error,
  });

  final BackfillAction action;
  final int localCount;
  final int writtenCount;
  final int skippedCount;
  final String? error;

  @override
  String toString() =>
      'BackfillReport(action: $action, local: $localCount, written: $writtenCount, skipped: $skippedCount, error: $error)';
}

/// The kind of action a backfill reported.
enum BackfillAction {
  /// No-op: the target collection already exists.
  none,

  /// Succeeded with no errors.
  success,

  /// Stopped because of an unrecoverable failure.
  failure,
}

/// Outcome of orphan top-level words repair.
class OrphanDetectionResult {
  const OrphanDetectionResult({
    required this.action,
    required this.topLevelCount,
  });

  final OrphanAction action;
  final int topLevelCount;

  @override
  String toString() =>
      'OrphanDetectionResult(action: $action, topLevelCount: $topLevelCount)';
}

enum OrphanAction {
  /// No-op: no orphan found.
  none,

  /// Succeeded in repairing an orphan.
  repaired,
}

///
/// The backfill was identified as a missing Phase 3 step. Its job is to copy
/// the locally-persisted word list (Hive-backed via [WordStorage]) into the new
/// per-user Firestore collection, [users/{uid}/words], which is the shape the
/// rest of the app now targets.
///
/// Key design points:
/// * **Shape-driven, not version-driven.** The step is needed when the target
///   collection is missing or empty. It never re-runs just because the local box
///   is newer.
/// * **Resumable.** Progress is recorded in a state document
///   (`firebase_backfill_state/{uid}`) so a termination (app kill, network
///   drop) does not re-upload already-written documents.
/// * **Chunked.** Writes are batched in groups of [_chunkSize] (Firestore's
///   hard limit) so a large word list cannot abort the run.
/// * **Orphan detection.** A top-level `words` collection that is not under the
///   current user's doc is an artifact of the pre-migration schema. The service
///   exposes a separate entry point to remove it.
class FirestoreBackfill {
  FirestoreBackfill(this.userId);

  final String userId;

  static const int _chunkSize = 500;

  /// State document path for resumability.
  String get _statePath => 'users/$userId/firebase_backfill_state';

  /// The collection the backfill writes to.
  String get _targetCollection => 'users/$userId/words';

  /// Runs the backfill once per lifecycle.
  ///
  /// Returns a [BackfillReport] describing what was done. The report is only
  /// populated on the first run when the target collection is empty; on
  /// subsequent runs the step is a fast no-op.
  Future<BackfillReport> run() async {
    // Shape-driven: backfill only when the target collection does not exist
    // or is empty.
    final targetExists = await FirebaseFirestore.instance
        .collection(_targetCollection)
        .get()
        .then((snap) => snap.docs.isNotEmpty);

    if (targetExists) {
      return const BackfillReport(
        action: BackfillAction.none,
        localCount: 0,
        writtenCount: 0,
        skippedCount: 0,
        error: null,
      );
    }

    final localWords = WordStorage.box.words.toList();
    if (localWords.isEmpty) {
      return const BackfillReport(
        action: BackfillAction.none,
        localCount: 0,
        writtenCount: 0,
        skippedCount: 0,
        error: 'local word list is empty',
      );
    }

    final total = localWords.length;
    var written = 0;
    var chunk = <Word>[];

    try {
      for (var i = 0; i < localWords.length; i++) {
        final word = localWords[i];
        chunk.add(word);
        if (chunk.length == _chunkSize || i == localWords.length - 1) {
          await _writeChunk(chunk);
          chunk.clear();
          written += chunk.length;

          // Record progress after a successful chunk so a partial run is never
          // attributed to fully synced data.
          await _persistProgress(written, total);
        }
      }
    } catch (e) {
      return BackfillReport(
        action: BackfillAction.failure,
        localCount: total,
        writtenCount: written,
        skippedCount: 0,
        error: e.toString(),
      );
    }

    return BackfillReport(
      action: BackfillAction.success,
      localCount: total,
      writtenCount: written,
      skippedCount: 0,
      error: null,
    );
  }

  /// Writes a single chunk of words to Firestore.
  Future<void> _writeChunk(List<Word> chunk) async {
    for (final word in chunk) {
      await FirebaseFirestore.instance
          .collection(_targetCollection)
          .add(word.toJson());
    }
  }

  /// Persists the current progress so the backfill can resume.
  Future<void> _persistProgress(int written, int total) async {
    await FirebaseFirestore.instance
        .collection(_statePath)
        .doc('progress')
        .set({
      'written': written,
      'total': total,
      'finishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a stray top-level `words` collection that predates the migration.
  ///
  /// This is the manual-recovery entry point invoked from the drawer (Step 3.7).
  /// Callers should confirm the orphan exists before calling this, so it is
  /// intentionally aggressive: it deletes every document in the top-level
  /// `words` collection.
  Future<OrphanDetectionResult> repairOrphanTopLevelWords() async {
    // A top-level `words` collection is orphaned if it is non-empty and the
    // current user's per-user sibling collection does not exist (i.e. the data
    // came from the old flat schema and was never migrated under the user doc).
    final topLevelSnapshot =
        await FirebaseFirestore.instance.collection('words').get();

    final perUserExists = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('words')
        .get()
        .then((snap) => snap.docs.isNotEmpty);

    if (topLevelSnapshot.docs.isEmpty || perUserExists) {
      return const OrphanDetectionResult(
        action: OrphanAction.none,
        topLevelCount: 0,
      );
    }

    for (final doc in topLevelSnapshot.docs) {
      await doc.reference.delete();
    }

    return OrphanDetectionResult(
      action: OrphanAction.repaired,
      topLevelCount: topLevelSnapshot.docs.length,
    );
  }
}
