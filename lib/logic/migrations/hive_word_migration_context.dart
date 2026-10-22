import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/word.dart';
import 'migration_context.dart';
import 'migration_failure.dart';
import 'word_payload.dart';

/// The local (Hive) side of a migration container.
///
/// The words live in a single key, `wordListJson`, which holds an envelope
/// `{"schemaVersion": <int>, "words": [...]}` (see [WordPayloadCodec]). The
/// envelope is written in the *same* Hive write as the words, so the data and
/// its version can never diverge.
///
/// Writes are **backup-first**: the current payload is copied to
/// `wordListJson_backup` before the new payload is written, and the new
/// payload is first written to a shadow key (`wordListJson_new`) and only
/// then swapped into place. A crash can therefore never leave the box
/// without a readable word list.
class HiveWordMigrationContext implements MigrationContext {
  HiveWordMigrationContext({
    required Box box,
    String scopeLabel = 'hive',
  })  : _box = box,
        _scopeLabel = scopeLabel;

  /// The key holding the word payload.
  static const String wordsKey = 'wordListJson';

  /// The key holding the pre-migration payload.
  static const String backupKey = 'wordListJson_backup';

  /// The shadow key the new payload is staged in before the swap.
  static const String shadowKey = 'wordListJson_new';

  /// The key holding the container's schema version.
  static const String versionKey = 'wordSchemaVersion';

  final Box _box;
  final String _scopeLabel;

  @override
  String get scopeLabel => _scopeLabel;

  @override
  Future<List<Word>> readWords() async {
    final payload = WordPayloadCodec.decode(_box.get(wordsKey));
    return payload.words;
  }

  @override
  Future<void> writeWords(List<Word> words) async {
    try {
      // 1. Preserve the current payload so the pre-migration state is always
      //    recoverable.
      final dynamic current = _box.get(wordsKey);
      if (current != null) {
        await _box.put(backupKey, current);
      }

      // 2. Stage the new payload under a shadow key. If the process dies
      //    here, the live key still holds the old (readable) payload.
      final version = await readVersion();
      final staged = WordPayloadCodec.encode(
        WordPayload(version: version, words: words),
      );
      await _box.put(shadowKey, staged);

      // 3. Swap the shadow key into the live key, then drop the shadow.
      await _box.put(wordsKey, staged);
      await _box.delete(shadowKey);
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.writeFailed,
        stepId: 'hive_write',
        message: 'could not write the word payload',
        cause: e,
        stackTrace: s,
        details: {'wordCount': words.length},
      );
    }
  }

  @override
  Future<int> readVersion() async {
    // The envelope carries the version together with the data, so it is the
    // primary source. A container written by a legacy build has a bare list
    // and therefore reports version 0.
    final payload = WordPayloadCodec.decode(_box.get(wordsKey));
    if (payload.version > 0) {
      return payload.version;
    }

    // Fall back to a separately recorded marker, if one exists.
    final dynamic marker = _box.get(versionKey);
    return marker is int ? marker : 0;
  }

  @override
  Future<void> writeVersion(int version) async {
    try {
      // The version is patched **into the existing payload**, so the data and
      // its version are always written together and can never diverge. The
      // raw word array is copied verbatim - it is never re-encoded from the
      // parsed [Word] list, because that would silently drop any record the
      // tolerant parser skipped.
      final dynamic raw = _box.get(wordsKey);
      final String updated;

      if (raw is String && raw.isNotEmpty) {
        dynamic decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (_) {
          decoded = null;
        }
        if (decoded is Map) {
          updated =
              jsonEncode({...decoded, WordPayloadCodec.versionKey: version});
        } else if (decoded is List) {
          // A legacy bare list becomes an envelope, keeping every record.
          updated = jsonEncode({
            WordPayloadCodec.versionKey: version,
            WordPayloadCodec.wordsKey: decoded,
          });
        } else {
          updated = jsonEncode({
            WordPayloadCodec.versionKey: version,
            WordPayloadCodec.wordsKey: const <dynamic>[],
          });
        }
      } else {
        updated = jsonEncode({
          WordPayloadCodec.versionKey: version,
          WordPayloadCodec.wordsKey: const <dynamic>[],
        });
      }

      await _box.put(wordsKey, updated);

      // The standalone marker is kept in sync as a secondary source, so a
      // partially written payload can still be identified.
      await _box.put(versionKey, version);
    } catch (e, s) {
      throw MigrationFailure(
        code: MigrationFailureCode.versionAdvanceFailed,
        stepId: 'hive_version',
        message: 'could not advance the container version',
        cause: e,
        stackTrace: s,
        details: {'version': version},
      );
    }
  }

  /// The pre-migration payload, if one was preserved.
  ///
  /// Returns `null` when no migration has run yet.
  Future<String?> readBackup() async {
    final dynamic raw = _box.get(backupKey);
    return raw is String ? raw : null;
  }
}
