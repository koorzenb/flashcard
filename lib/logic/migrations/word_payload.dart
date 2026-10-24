import 'dart:convert';

import '../../models/word.dart';

/// A word payload together with the schema version of its data.
///
/// The version tags the **data**, not the app: it records the shape the
/// payload is actually written in, so the runner knows what still has to be
/// migrated.
class WordPayload {
  const WordPayload({required this.version, required this.words});

  /// The schema version of [words].
  final int version;

  /// The words in the payload.
  final List<Word> words;

  /// The number of words in the payload.
  int get count => words.length;
}

/// Reads and writes the local word payload envelope.
///
/// The Hive value at `wordListJson` used to be a bare JSON list. It now holds
/// an envelope `{"schemaVersion": <int>, "words": [...]}` so that the data and
/// its version are written in the same operation and can never diverge.
///
/// The reader is deliberately **total**: it accepts both the envelope and the
/// legacy bare list, so a box written by an older build still loads. A bare
/// list is reported as version `0` (the pre-envelope version), which is
/// exactly what the runner needs to know in order to migrate it.
///
/// This file is pure (JSON in / JSON out) and has no Hive import, so it is
/// unit-testable without any storage.
class WordPayloadCodec {
  const WordPayloadCodec._();

  /// The key under which the schema version is stored inside an envelope.
  static const String versionKey = 'schemaVersion';

  /// The key under which the words are stored inside an envelope.
  static const String wordsKey = 'words';

  /// Decodes a persisted payload.
  ///
  /// Returns a payload at version `0` for a legacy bare list, at the declared
  /// version for an envelope, and an empty payload at version `0` for
  /// anything unreadable (a missing key, a non-string value, invalid JSON).
  /// It never throws.
  static WordPayload decode(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return const WordPayload(version: 0, words: <Word>[]);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const WordPayload(version: 0, words: <Word>[]);
    }

    if (decoded is List) {
      // Legacy bare list: version 0.
      return WordPayload(
        version: 0,
        words: Word.listFromJsonList(decoded),
      );
    }

    if (decoded is Map) {
      final version = decoded[versionKey];
      final words = decoded[wordsKey];
      return WordPayload(
        version: version is int ? version : 0,
        words: words is List ? Word.listFromJsonList(words) : const <Word>[],
      );
    }

    return const WordPayload(version: 0, words: <Word>[]);
  }

  /// Encodes a payload into the envelope format.
  static String encode(WordPayload payload) => jsonEncode({
        versionKey: payload.version,
        wordsKey: payload.words.map((word) => word.toJson()).toList(),
      });
}
