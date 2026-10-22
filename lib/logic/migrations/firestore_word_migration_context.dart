import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/word.dart';
import 'migration_context.dart';
import 'migration_failure.dart';

/// The cloud (Firestore) side of a migration container.
///
/// The words live in `users/{uid}/words` and the container's schema version
/// is stored on the user document `users/{uid}` under [versionField].
///
/// Writes are **non-deleting**: this context only normalizes the shape of
/// the existing documents. It never adds a document and never removes one,
/// because a document id is the only stable identity the cloud data has.
class FirestoreWordMigrationContext implements MigrationContext {
  FirestoreWordMigrationContext({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  /// The field on the user document that holds the container's schema version.
  static const String versionField = 'wordSchemaVersion';

  /// The name of the words subcollection.
  static const String wordsCollection = 'words';

  final FirebaseFirestore _firestore;
  final String _userId;

  @override
  String get scopeLabel => 'firestore';

  @override
  Future<List<Word>> readWords() async {
    try {
      final snapshot = await _wordsRef().get();
      return snapshot.docs
          .map((doc) => wordFromDocument(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.networkUnavailable,
        stepId: 'firestore_read',
        message: 'could not read the word documents',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> writeWords(List<Word> words) async {
    try {
      // Only the documents that already exist are updated. A word without an
      // id cannot be matched to a document, so it is skipped rather than
      // creating a new document.
      final batch = _firestore.batch();
      var updated = 0;

      for (final word in words) {
        if (word.id.isEmpty) {
          continue;
        }
        batch.set(
          _wordsRef().doc(word.id),
          wordToDocument(word),
          SetOptions(merge: true),
        );
        updated++;
      }

      if (updated > 0) {
        await batch.commit();
      }
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.writeFailed,
        stepId: 'firestore_write',
        message: 'could not write the word documents',
        cause: e,
        stackTrace: s,
        details: {'wordCount': words.length},
      );
    }
  }

  @override
  Future<int> readVersion() async {
    try {
      final snapshot = await _userRef().get();
      final dynamic version = snapshot.data()?[versionField];
      return version is int ? version : 0;
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.networkUnavailable,
        stepId: 'firestore_version',
        message: 'could not read the container version',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> writeVersion(int version) async {
    try {
      await _userRef().set({versionField: version}, SetOptions(merge: true));
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.versionAdvanceFailed,
        stepId: 'firestore_version',
        message: 'could not advance the container version',
        cause: e,
        stackTrace: s,
        details: {'version': version},
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _wordsRef() =>
      _firestore.collection('users').doc(_userId).collection(wordsCollection);

  DocumentReference<Map<String, dynamic>> _userRef() =>
      _firestore.collection('users').doc(_userId);

  /// Builds a [Word] from a Firestore document.
  ///
  /// The document id is the authoritative identity of a word, so it is always
  /// applied to the `id` field. Every other field goes through the tolerant
  /// [Word.fromJson], so a legacy string `attributes` field or a missing
  /// field degrades gracefully instead of throwing.
  static Word wordFromDocument(String docId, Map<String, dynamic>? data) {
    final Map<String, dynamic> fields =
        Map<String, dynamic>.from(data ?? const <String, dynamic>{});
    fields['id'] = docId;
    return Word.fromJson(fields);
  }

  /// Builds the document body for [word].
  ///
  /// The `id` is deliberately **not** part of the body: it is the document
  /// id, and duplicating it in the body would let the two drift apart.
  static Map<String, dynamic> wordToDocument(Word word) => {
        'native': word.native,
        'pronunciation': word.pronunciation,
        'translation': word.translation,
        'attributes': word.attributes.toJson(),
        'audioId': word.audioId,
        'isNew': word.isNew,
      };
}
