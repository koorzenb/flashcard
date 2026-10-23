import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_constants.dart';
import 'firestore_word_migration_context.dart';
import 'migration_failure.dart';
import 'migration_integrity_check.dart';
import 'migration_log.dart';

/// Shape-driven normalization of legacy documents in the user's cloud word
/// collection, plus report-only orphan detection.
///
/// Unlike the [MigrationRunner] (which is version-driven), this backfill
/// always inspects the actual document shapes so that legacy data written by
/// an older app build — after the version marker advanced — is still caught.
///
/// Writes are committed in [WriteBatch] chunks of at most
/// [FirestoreBackfill.maxBatchSize] operations, staying within Firestore's
/// 500-operation limit.
class FirestoreBackfill {
  FirestoreBackfill(this._firestore, this._userId);

  final FirebaseFirestore _firestore;
  final String _userId;

  /// Firestore's hard limit on operations per [WriteBatch].
  static const int maxBatchSize = 500;

  /// The collection holding the user's cloud words.
  CollectionReference<Map<String, dynamic>> get _wordsRef =>
      _firestore.collection('users').doc(_userId).collection('words');

  /// The user document that holds the container version marker.
  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_userId);

  // ─── Pure, testable helpers ──────────────────────────────────────────

  /// Returns `true` when a Firestore document still holds a legacy
  /// free-text `attributes` string or is missing `attributes` entirely.
  static bool documentNeedsNormalization(Map<String, dynamic>? data) {
    if (data == null) return true;
    return data['attributes'] is! Map;
  }

  /// Converts a raw Firestore document into the normalized shape.
  ///
  /// The document id is applied to the `id` field and every other field
  /// goes through the tolerant reader, so a legacy string `attributes`
  /// becomes a structured map.
  static Map<String, dynamic> normalizeDocument(
    Map<String, dynamic>? data,
    String docId,
  ) {
    final word = FirestoreWordMigrationContext.wordFromDocument(docId, data);
    return FirestoreWordMigrationContext.wordToDocument(word);
  }

  /// Splits [list] into sub-lists of at most [size] elements.
  static List<List<T>> chunkList<T>(List<T> list, int size) {
    if (size <= 0) throw ArgumentError('size must be positive');
    if (list.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = i + size > list.length ? list.length : i + size;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  /// Matches orphan top-level documents against the user's own words.
  ///
  /// Both arguments are lists of raw Firestore document data maps (i.e.
  /// `QueryDocumentSnapshot.data()`). Returns the total orphan count and
  /// how many matched by `native` + `translation`.
  ///
  /// This is a pure function and does **not** mutate any data.
  static OrphanMatchResult matchOrphans(
    List<Map<String, dynamic>?> orphanData,
    List<Map<String, dynamic>?> userData,
  ) {
    final userKeys = userData
        .whereType<Map<String, dynamic>>()
        .map(
          (d) => '${d['native'] ?? ''}\u0000${d['translation'] ?? ''}',
        )
        .toSet();

    var matched = 0;
    for (final data in orphanData) {
      if (data == null) continue;
      final key = '${data['native'] ?? ''}\u0000${data['translation'] ?? ''}';
      if (userKeys.contains(key)) matched++;
    }

    return OrphanMatchResult(count: orphanData.length, matched: matched);
  }

  // ─── Firestore I/O ───────────────────────────────────────────────────

  /// Runs the shape-driven backfill.
  ///
  /// Reads all documents in `users/{uid}/words`, normalizes any that still
  /// carry a legacy `attributes` string, writes them in batches of
  /// [maxBatchSize], verifies that no document ids were lost, and advances
  /// the container version marker.
  ///
  /// A second run performs zero writes (idempotent).
  Future<BackfillReport> run() async {
    final snapshot = await _wordsRef.get();
    final docs = snapshot.docs;

    final toNormalize = docs
        .where((doc) => documentNeedsNormalization(doc.data()))
        .toList(growable: false);

    if (toNormalize.isEmpty) {
      final version = await _readVersion();
      if (version < AppConstants.currentWordSchemaVersion) {
        await _writeVersion(AppConstants.currentWordSchemaVersion);
      }
      return const BackfillReport(
        action: BackfillAction.none,
        localCount: 0,
        writtenCount: 0,
        skippedCount: 0,
        error: null,
      );
    }

    final before = docs
        .map((d) =>
            FirestoreWordMigrationContext.wordFromDocument(d.id, d.data()))
        .toList();
    var written = 0;

    try {
      for (final batch in chunkList(toNormalize, maxBatchSize)) {
        final writeBatch = _firestore.batch();
        for (final doc in batch) {
          final normalized = normalizeDocument(doc.data(), doc.id);
          writeBatch.set(doc.reference, normalized, SetOptions(merge: true));
          written++;
        }
        await writeBatch.commit();
      }

      // Integrity check: compare the pre- and post-migration Word lists.
      final afterSnapshot = await _wordsRef.get();
      final after = afterSnapshot.docs
          .map((d) =>
              FirestoreWordMigrationContext.wordFromDocument(d.id, d.data()))
          .toList();
      final report = MigrationIntegrityCheck.compare(before, after);

      MigrationLog.integrity(
        stepId: 'm001_attributes_to_map',
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
          stepId: 'm001_attributes_to_map',
          message: 'the integrity check found missing records',
          details: {
            'beforeCount': report.beforeCount,
            'afterCount': report.afterCount,
            'missing': report.missing.length,
          },
        );
      }

      await _writeVersion(AppConstants.currentWordSchemaVersion);
    } catch (e) {
      MigrationLog.warning('FirestoreBackfill.run failed: ${e.runtimeType}');
      return BackfillReport(
        action: BackfillAction.failure,
        localCount: toNormalize.length,
        writtenCount: written,
        skippedCount: toNormalize.length - written,
        error: e.toString(),
      );
    }

    return BackfillReport(
      action: BackfillAction.success,
      localCount: toNormalize.length,
      writtenCount: written,
      skippedCount: 0,
      error: null,
    );
  }

  /// Report-only orphan detection.
  ///
  /// Reads the top-level `words` collection and matches against the user's
  /// own `users/{uid}/words` collection by `native` + `translation`.
  ///
  /// This method does **not** copy or delete anything.
  Future<OrphanReport> detectOrphans() async {
    final topLevelSnapshot = await _firestore.collection('words').get();
    if (topLevelSnapshot.docs.isEmpty) {
      return const OrphanReport(count: 0, matched: 0);
    }

    final userSnapshot = await _wordsRef.get();
    final result = matchOrphans(
      topLevelSnapshot.docs.map((d) => d.data()).toList(),
      userSnapshot.docs.map((d) => d.data()).toList(),
    );

    return OrphanReport(count: result.count, matched: result.matched);
  }

  Future<int> _readVersion() async {
    final snapshot = await _userRef.get();
    final dynamic version =
        snapshot.data()?[FirestoreWordMigrationContext.versionField];
    return version is int ? version : 0;
  }

  Future<void> _writeVersion(int version) async {
    await _userRef.set(
      {FirestoreWordMigrationContext.versionField: version},
      SetOptions(merge: true),
    );
  }
}

/// The outcome of a backfill run.
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
}

/// The kind of action a backfill reported.
enum BackfillAction {
  none,
  success,
  failure,
}

/// Result of matching orphan documents against the user's own words.
class OrphanMatchResult {
  const OrphanMatchResult({required this.count, required this.matched});

  final int count;
  final int matched;
}

/// The outcome of report-only orphan detection.
class OrphanReport {
  const OrphanReport({required this.count, required this.matched});

  final int count;
  final int matched;
}
