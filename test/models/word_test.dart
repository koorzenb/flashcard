import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Word JSON round trip', () {
    test(
      'toJson() then fromJson() preserves all fields including attributes',
      () {
        final word = Word(
          id: 'abc123',
          native: 'der Hund',
          pronunciation: 'dehr hhoont',
          translation: 'dog',
          attributes: const WordAttributes(
            gender: Gender.male,
            isPlural: false,
          ),
          audioId: 'abc123',
          isNew: true,
        );

        final restored = Word.fromJson(word.toJson());

        expect(restored.id, word.id);
        expect(restored.native, word.native);
        expect(restored.pronunciation, word.pronunciation);
        expect(restored.translation, word.translation);
        expect(restored.attributes, word.attributes);
        expect(restored.audioId, word.audioId);
        expect(restored.isNew, word.isNew);
      },
    );

    test('fromJson() reads the nested attributes map', () {
      final json = {
        'id': 'doc1',
        'native': 'die Katze',
        'pronunciation': 'dee kaat-zeh',
        'translation': 'cat',
        'attributes': {'gender': 'female', 'isPlural': true},
        'audioId': '',
        'isNew': false,
      };

      final word = Word.fromJson(json);

      expect(word.attributes.gender, Gender.female);
      expect(word.attributes.isPlural, isTrue);
    });

    test('blank attributes default to neutral + singular', () {
      final word = Word(native: 'x', pronunciation: '', translation: '');

      expect(word.attributes, const WordAttributes.blank());
      expect(word.attributes.gender, Gender.neutral);
      expect(word.attributes.isPlural, isFalse);
      expect(
        Word.fromJson(word.toJson()).attributes,
        const WordAttributes.blank(),
      );
    });
  });

  group('Word.fromJson is null-safe', () {
    test('defaults every missing string field to an empty string', () {
      final word = Word.fromJson({'native': 'x'});

      expect(word.id, '');
      expect(word.native, 'x');
      expect(word.pronunciation, '');
      expect(word.translation, '');
      expect(word.audioId, '');
      expect(word.isNew, isFalse);
      expect(word.attributes, const WordAttributes.blank());
    });

    test('defaults an entirely empty record to a blank word', () {
      final word = Word.fromJson({});

      expect(word.id, '');
      expect(word.native, '');
      expect(word.pronunciation, '');
      expect(word.translation, '');
      expect(word.audioId, '');
      expect(word.isNew, isFalse);
      expect(word.attributes, const WordAttributes.blank());
    });

    test('treats explicit null values as empty strings', () {
      final word = Word.fromJson({
        'id': null,
        'native': null,
        'pronunciation': null,
        'translation': null,
        'audioId': null,
        'attributes': null,
        'isNew': null,
      });

      expect(word.id, '');
      expect(word.native, '');
      expect(word.pronunciation, '');
      expect(word.translation, '');
      expect(word.audioId, '');
      expect(word.isNew, isFalse);
      expect(word.attributes, const WordAttributes.blank());
    });

    test('treats non-string values as empty strings', () {
      final word = Word.fromJson({
        'id': 42,
        'native': ['a'],
        'pronunciation': {'b': 1},
        'translation': true,
        'audioId': 7,
      });

      expect(word.id, '');
      expect(word.native, '');
      expect(word.pronunciation, '');
      expect(word.translation, '');
      expect(word.audioId, '');
    });

    test('treats a non-boolean isNew as false', () {
      expect(Word.fromJson({'isNew': 'yes'}).isNew, isFalse);
      expect(Word.fromJson({'isNew': 1}).isNew, isFalse);
      expect(Word.fromJson({'isNew': true}).isNew, isTrue);
    });

    test('routes attributes through the tolerant parser', () {
      final legacy = Word.fromJson({
        'native': 'der Hund',
        'attributes': 'masculine',
      });
      expect(legacy.attributes.gender, Gender.male);
      expect(legacy.attributes.isPlural, isFalse);

      final current = Word.fromJson({
        'native': 'die Katze',
        'attributes': {'gender': 'female', 'isPlural': true},
      });
      expect(current.attributes.gender, Gender.female);
      expect(current.attributes.isPlural, isTrue);
    });

    test('ignores unknown fields written by a newer build', () {
      final word = Word.fromJson({
        'native': 'x',
        'translation': 'y',
        'someFutureField': 'ignored',
        'media': {'recordingId': 'abc'},
      });

      expect(word.native, 'x');
      expect(word.translation, 'y');
    });

    test('never throws on a hostile record', () {
      expect(
        () => Word.fromJson({
          'id': null,
          'attributes': <dynamic>[],
          'isNew': 'nope',
        }),
        returnsNormally,
      );
    });
  });

  group('Word.listFromJsonList parses record by record', () {
    test('keeps the valid records when one record is malformed', () {
      final words = Word.listFromJsonList([
        {'native': 'der Hund', 'translation': 'dog'},
        'not a map',
        {'native': 'die Katze', 'translation': 'cat'},
      ]);

      expect(words.length, 2);
      expect(words[0].native, 'der Hund');
      expect(words[1].native, 'die Katze');
    });

    test('does not collapse the whole list to empty for one bad element', () {
      final words = Word.listFromJsonList([
        {'native': 'a'},
        null,
        {'native': 'b'},
        42,
      ]);

      expect(words.length, 2);
      expect(words.map((w) => w.native), ['a', 'b']);
    });

    test('returns an empty list only when every record is malformed', () {
      expect(Word.listFromJsonList(['a', 1, null, true]), isEmpty);
    });

    test('returns an empty list for an empty input', () {
      expect(Word.listFromJsonList([]), isEmpty);
    });

    test('accepts a legacy attributes string inside a list record', () {
      final words = Word.listFromJsonList([
        {'native': 'der Hund', 'attributes': 'masculine'},
      ]);

      expect(words.length, 1);
      expect(words.first.attributes.gender, Gender.male);
    });

    test('accepts a list of Map<String, dynamic> records', () {
      final words = Word.listFromJsonList([
        {'native': 'x', 'translation': 'y'},
        {'native': 'z', 'translation': 'w'},
      ]);

      expect(words.length, 2);
      expect(words[1].native, 'z');
    });
  });
}
