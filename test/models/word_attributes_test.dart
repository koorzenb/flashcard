import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordAttributes.fromJson is total (never throws)', () {
    test('accepts the current map format', () {
      final attributes = WordAttributes.fromJson({
        'gender': 'male',
        'isPlural': true,
      });

      expect(attributes.gender, Gender.male);
      expect(attributes.isPlural, isTrue);
    });

    test('accepts a legacy free-text string', () {
      final attributes = WordAttributes.fromJson('masculine');

      expect(attributes.gender, Gender.male);
      expect(attributes.isPlural, isFalse);
    });

    test('accepts null and missing attributes as blank', () {
      expect(WordAttributes.fromJson(null), const WordAttributes.blank());
      expect(
        WordAttributes.fromJson({'gender': 'male'}),
        const WordAttributes(gender: Gender.male, isPlural: false),
      );
    });

    test('falls back to neutral for an unknown gender', () {
      final attributes = WordAttributes.fromJson({'gender': 'bogus'});

      expect(attributes.gender, Gender.neutral);
      expect(attributes.isPlural, isFalse);
    });

    test('falls back to neutral for an unexpected value type', () {
      expect(WordAttributes.fromJson(42), const WordAttributes.blank());
      expect(
        WordAttributes.fromJson(<dynamic>[]),
        const WordAttributes.blank(),
      );
    });
  });

  group('WordAttributes.fromLegacy maps legacy free text', () {
    test('maps known gender tokens', () {
      expect(WordAttributes.fromLegacy('masculine').gender, Gender.male);
      expect(WordAttributes.fromLegacy('male').gender, Gender.male);
      expect(WordAttributes.fromLegacy('m').gender, Gender.male);
      expect(WordAttributes.fromLegacy('feminine').gender, Gender.female);
      expect(WordAttributes.fromLegacy('female').gender, Gender.female);
      expect(WordAttributes.fromLegacy('f').gender, Gender.female);
      expect(WordAttributes.fromLegacy('neutral').gender, Gender.neutral);
    });

    test('is case insensitive', () {
      expect(WordAttributes.fromLegacy('Masculine').gender, Gender.male);
      expect(WordAttributes.fromLegacy('FEMININE').gender, Gender.female);
    });

    test('detects plural markers', () {
      expect(WordAttributes.fromLegacy('plural').isPlural, isTrue);
      expect(WordAttributes.fromLegacy('feminine plural').isPlural, isTrue);
      expect(
          WordAttributes.fromLegacy('feminine plural').gender, Gender.female);
      expect(WordAttributes.fromLegacy('masculine').isPlural, isFalse);
    });

    test('defaults unknown text to neutral and singular', () {
      final attributes = WordAttributes.fromLegacy('noun');

      expect(attributes.gender, Gender.neutral);
      expect(attributes.isPlural, isFalse);
    });

    test('defaults empty text to blank', () {
      expect(WordAttributes.fromLegacy(''), const WordAttributes.blank());
    });
  });
}
