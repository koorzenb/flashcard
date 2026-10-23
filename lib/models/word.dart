import 'dart:developer' as developer;

import 'word_attributes.dart';

class Word {
  final String id;
  final String native;
  final String pronunciation;
  final String translation;
  final WordAttributes attributes;
  final String? attributesRaw; // Raw JSON string for legacy attribute storage
  String audioId;
  final bool isNew;

  Word(
      {this.id = '',
      required this.native,
      required this.pronunciation,
      required this.translation,
      this.attributes = const WordAttributes.blank(),
      this.attributesRaw,
      this.audioId = '',
      this.isNew = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'native': native,
        'pronunciation': pronunciation,
        'translation': translation,
        'attributes': attributes.toJson(),
        'audioId': audioId,
        'isNew': isNew,
        'attributesRaw': attributesRaw,
      };

  static List<dynamic> arrayToJsonList(List<Word> words) {
    return List<dynamic>.from(
      words.map((x) => x.toJson()),
    );
  }

  /// Builds a [Word] from any persisted shape.
  ///
  /// The parser is intentionally total: every field is read defensively so a
  /// single incomplete record can never abort the loading of an entire word
  /// list. Missing or non-string values fall back to an empty string, a
  /// missing [isNew] falls back to `false`, and `attributes` is delegated to
  /// the tolerant [WordAttributes.fromJson] (which accepts both the current
  /// map format and the legacy free-text string). Unknown fields are ignored,
  /// so a record written by a newer app build still loads.
  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: _readString(json['id']),
        native: _readString(json['native']),
        pronunciation: _readString(json['pronunciation']),
        translation: _readString(json['translation']),
        attributes: WordAttributes.fromJson(json['attributes']),
        audioId: _readString(json['audioId']),
        isNew: json['isNew'] == true,
        attributesRaw: json['attributesRaw'] as String?,
      );

  /// Reads a persisted string field, tolerating a missing, null or
  /// non-string value by falling back to an empty string.
  static String _readString(dynamic value) => value is String ? value : '';

  /// Parses a persisted word list **record by record**.
  ///
  /// A malformed record is skipped instead of discarding the whole list: one
  /// broken entry must never wipe a user's vocabulary. Records that are not
  /// maps (or that fail to parse) are counted and reported through a debug
  /// log; the valid records are still returned.
  ///
  /// The returned list is empty only when the input list is empty or when
  /// *every* record is malformed.
  static List<Word> listFromJsonList(List<dynamic> jsonList) {
    if (jsonList.isEmpty) {
      return <Word>[];
    }

    final words = <Word>[];
    var skipped = 0;

    for (final dynamic record in jsonList) {
      if (record is! Map) {
        skipped++;
        continue;
      }
      try {
        words.add(Word.fromJson(Map<String, dynamic>.from(record)));
      } catch (e) {
        // A single unparseable record must not abort the whole list.
        skipped++;
      }
    }

    if (skipped > 0) {
      // Counts only - never the word content (see the plan's Security
      // Requirements).
      developer.log(
        'word.parse.skippedRecords invalid=$skipped total=${jsonList.length} '
        'parsed=${words.length}',
        name: 'WORD_PARSE',
        level: 900,
      );
    }

    return words;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          native == other.native &&
          pronunciation == other.pronunciation &&
          translation == other.translation &&
          attributes == other.attributes &&
          attributesRaw == other.attributesRaw &&
          audioId == other.audioId &&
          isNew == other.isNew;

  @override
  int get hashCode => Object.hash(
        id,
        native,
        pronunciation,
        translation,
        attributes,
        attributesRaw,
        audioId,
        isNew,
      );
}
