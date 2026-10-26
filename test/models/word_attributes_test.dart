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

      expect(
        attributes.gender,
        Gender.male,
        reason: 'the "gender" map entry maps to the matching enum value',
      );
      expect(
        attributes.isPlural,
        isTrue,
        reason: 'the "isPlural" map entry is preserved',
      );
    });

    test('accepts a legacy free-text string', () {
      final attributes = WordAttributes.fromJson('masculine');

      expect(
        attributes.gender,
        Gender.male,
        reason: '"masculine" legacy token maps to Gender.male',
      );
      expect(
        attributes.isPlural,
        isFalse,
        reason: 'legacy string without a plural token stays singular',
      );
    });

    test('accepts null and missing attributes as blank', () {
      expect(
        WordAttributes.fromJson(null),
        const WordAttributes.blank(),
        reason: 'null input degrades to the neutral singular default',
      );
      expect(
        WordAttributes.fromJson({'gender': 'male'}),
        const WordAttributes(gender: Gender.male, isPlural: false),
        reason: 'missing isPlural defaults to false while gender is kept',
      );
    });

    test('falls back to neutral for an unknown gender', () {
      final attributes = WordAttributes.fromJson({'gender': 'bogus'});

      expect(
        attributes.gender,
        Gender.neutral,
        reason: 'an unrecognized gender token falls back to neutral',
      );
      expect(
        attributes.isPlural,
        isFalse,
        reason: 'an unrecognized gender record defaults to singular',
      );
    });

    test('falls back to neutral for an unexpected value type', () {
      expect(
        WordAttributes.fromJson(42),
        const WordAttributes.blank(),
        reason: 'a non-map/non-string payload degrades to blank',
      );
      expect(
        WordAttributes.fromJson(<dynamic>[]),
        const WordAttributes.blank(),
        reason: 'a list payload (not an envelope) degrades to blank',
      );
    });
  });

  group('WordAttributes.fromLegacy maps legacy free text', () {
    test('maps known gender tokens', () {
      expect(
        WordAttributes.fromLegacy('masculine').gender,
        Gender.male,
        reason: '"masculine" maps to Gender.male',
      );
      expect(
        WordAttributes.fromLegacy('male').gender,
        Gender.male,
        reason: '"male" maps to Gender.male',
      );
      expect(
        WordAttributes.fromLegacy('m').gender,
        Gender.male,
        reason: '"m" single-letter token maps to Gender.male',
      );
      expect(
        WordAttributes.fromLegacy('feminine').gender,
        Gender.female,
        reason: '"feminine" maps to Gender.female',
      );
      expect(
        WordAttributes.fromLegacy('female').gender,
        Gender.female,
        reason: '"female" maps to Gender.female',
      );
      expect(
        WordAttributes.fromLegacy('f').gender,
        Gender.female,
        reason: '"f" single-letter token maps to Gender.female',
      );
      expect(
        WordAttributes.fromLegacy('neutral').gender,
        Gender.neutral,
        reason: '"neutral" maps to Gender.neutral',
      );
    });

    test('is case insensitive', () {
      expect(
        WordAttributes.fromLegacy('Masculine').gender,
        Gender.male,
        reason: 'gender tokens are matched case-insensitively (Masculine)',
      );
      expect(
        WordAttributes.fromLegacy('FEMININE').gender,
        Gender.female,
        reason: 'gender tokens are matched case-insensitively (FEMININE)',
      );
    });

    test('detects plural markers', () {
      expect(
        WordAttributes.fromLegacy('plural').isPlural,
        isTrue,
        reason: 'a lone plural token sets isPlural',
      );
      expect(
        WordAttributes.fromLegacy('feminine plural').isPlural,
        isTrue,
        reason: 'a plural token combined with a gender sets isPlural',
      );
      expect(
        WordAttributes.fromLegacy('feminine plural').gender,
        Gender.female,
        reason: 'the gender token is still parsed alongside the plural token',
      );
      expect(
        WordAttributes.fromLegacy('masculine').isPlural,
        isFalse,
        reason: 'a gender-only token leaves isPlural false',
      );
    });

    test('defaults unknown text to neutral and singular', () {
      final attributes = WordAttributes.fromLegacy('noun');

      expect(
        attributes.gender,
        Gender.neutral,
        reason: 'an unknown token has no gender match, defaults to neutral',
      );
      expect(
        attributes.isPlural,
        isFalse,
        reason: 'an unknown token sets no plural marker, defaults to singular',
      );
    });

    test('defaults empty text to blank', () {
      expect(
        WordAttributes.fromLegacy(''),
        const WordAttributes.blank(),
        reason: 'empty input yields the neutral singular blank value',
      );
    });
  });
}
