import 'dart:convert';

import 'package:flashcard/logic/migrations/word_payload.dart';
import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordPayloadCodec.decode', () {
    test('reads a legacy bare list as version 0', () {
      final payload = WordPayloadCodec.decode(
        jsonEncode([
          {'id': 'a', 'native': 'x', 'translation': 'y'},
          {'id': 'b', 'native': 'z', 'translation': 'w'},
        ]),
      );

      expect(payload.version, 0);
      expect(payload.words.length, 2);
      expect(payload.words.first.id, 'a');
    });

    test('reads an envelope at its declared version', () {
      final payload = WordPayloadCodec.decode(
        jsonEncode({
          'schemaVersion': 3,
          'words': [
            {'id': 'a', 'native': 'x'},
          ],
        }),
      );

      expect(payload.version, 3);
      expect(payload.words.length, 1);
      expect(payload.count, 1);
    });

    test('reads an envelope with an invalid version as version 0', () {
      final payload = WordPayloadCodec.decode(
        jsonEncode({'schemaVersion': 'three', 'words': []}),
      );

      expect(payload.version, 0);
    });

    test('reads an envelope without a words list as empty', () {
      final payload = WordPayloadCodec.decode(jsonEncode({'schemaVersion': 2}));

      expect(payload.version, 2);
      expect(payload.words, isEmpty);
    });

    test('returns an empty payload for invalid JSON', () {
      final payload = WordPayloadCodec.decode('{not json');

      expect(payload.version, 0);
      expect(payload.words, isEmpty);
    });

    test('returns an empty payload for a missing or non-string value', () {
      expect(WordPayloadCodec.decode(null).words, isEmpty);
      expect(WordPayloadCodec.decode('').words, isEmpty);
      expect(WordPayloadCodec.decode(42).words, isEmpty);
    });

    test('returns an empty payload for a JSON value that is neither a list '
        'nor a map', () {
      expect(WordPayloadCodec.decode('"hello"').words, isEmpty);
    });

    test('skips malformed records inside a legacy bare list', () {
      final payload = WordPayloadCodec.decode(
        jsonEncode([
          {'id': 'a', 'native': 'x'},
          'not a map',
          {'id': 'b', 'native': 'y'},
        ]),
      );

      expect(payload.words.length, 2);
    });

    test('reads a legacy attributes string inside a legacy bare list', () {
      final payload = WordPayloadCodec.decode(
        jsonEncode([
          {'id': 'a', 'attributes': 'masculine'},
        ]),
      );

      expect(payload.words.first.attributes.gender, Gender.male);
    });
  });

  group('WordPayloadCodec.encode', () {
    test('round-trips through decode', () {
      final original = WordPayload(
        version: 4,
        words: [
          Word(
            id: 'a',
            native: 'x',
            pronunciation: 'p',
            translation: 'y',
            attributes: const WordAttributes(
              gender: Gender.female,
              isPlural: true,
            ),
          ),
        ],
      );

      final decoded = WordPayloadCodec.decode(
        WordPayloadCodec.encode(original),
      );

      expect(decoded.version, 4);
      expect(decoded.words.length, 1);
      expect(decoded.words.first.id, 'a');
      expect(decoded.words.first.attributes.gender, Gender.female);
      expect(decoded.words.first.attributes.isPlural, isTrue);
    });

    test('writes an envelope, not a bare list', () {
      final encoded = WordPayloadCodec.encode(
        const WordPayload(version: 1, words: []),
      );

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded.containsKey('schemaVersion'), isTrue);
      expect(decoded.containsKey('words'), isTrue);
    });
  });
}
