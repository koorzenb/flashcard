import 'package:flashcard/logic/migrations/attributes_migration.dart';
import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_test_helpers.dart';

void main() {
  group('m001_attributes_to_map migration', () {
    test('converts a legacy string attributes to a structured map', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'der Hund',
            pronunciation: '',
            translation: 'dog',
            attributes: WordAttributes.fromLegacy('masculine'),
          ),
        ],
      );

      await const AttributesMigration().run(ctx);

      final words = await ctx.readWords();
      expect(words.length, 1);
      expect(words.first.attributes.gender, Gender.male);
      expect(words.first.attributes.isPlural, isFalse);
      // The original legacy string is preserved.
      expect(words.first.attributes.attributesRaw, 'masculine');
    });

    test('a legacy list of three words (mixed shapes) is fully converted',
        () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'der Hund',
            pronunciation: '',
            translation: 'dog',
            attributes: WordAttributes.fromLegacy('masculine'),
          ),
          Word(
            id: 'b',
            native: 'die Katze',
            pronunciation: '',
            translation: 'cat',
            attributes: const WordAttributes(
              gender: Gender.female,
              isPlural: false,
            ),
          ),
          Word(
            id: 'c',
            native: 'das Haus',
            pronunciation: '',
            translation: 'house',
            attributes: const WordAttributes.blank(),
          ),
        ],
      );

      await const AttributesMigration().run(ctx);

      final words = await ctx.readWords();
      expect(words.length, 3);
      expect(words[0].attributes.gender, Gender.male);
      expect(words[0].attributes.attributesRaw, 'masculine');
      expect(words[1].attributes.gender, Gender.female);
      expect(words[2].attributes.gender, Gender.neutral);
      expect(words.map((w) => w.id), ['a', 'b', 'c']);
    });

    test('running the step twice produces byte-identical output', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'der Hund',
            pronunciation: '',
            translation: 'dog',
            attributes: WordAttributes.fromLegacy('masculine'),
          ),
        ],
      );

      const migration = AttributesMigration();
      await migration.run(ctx);
      final first = await ctx.readWords();
      final firstJson = first.map((w) => w.toJson()).toList();

      await migration.run(ctx);
      final second = await ctx.readWords();
      final secondJson = second.map((w) => w.toJson()).toList();

      expect(second, equals(first));
      expect(secondJson, equals(firstJson));
      // Raw string survives both passes.
      expect(second.first.attributes.attributesRaw, 'masculine');
    });

    test('preserves all other fields unchanged', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'w1',
            native: 'le livre',
            pronunciation: 'luh luhvruh',
            translation: 'book',
            attributes: WordAttributes.fromLegacy('feminine'),
            audioId: 'audio-abc',
            isNew: true,
          ),
        ],
      );

      await const AttributesMigration().run(ctx);

      final word = (await ctx.readWords()).first;
      expect(word.id, 'w1');
      expect(word.native, 'le livre');
      expect(word.pronunciation, 'luh luhvruh');
      expect(word.translation, 'book');
      expect(word.audioId, 'audio-abc');
      expect(word.isNew, isTrue);
      expect(word.attributes.gender, Gender.female);
      expect(word.attributes.attributesRaw, 'feminine');
    });

    test('leaves already-structured attributes untouched', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'x',
            pronunciation: '',
            translation: 'y',
            attributes: const WordAttributes(
              gender: Gender.male,
              isPlural: true,
            ),
          ),
        ],
      );

      await const AttributesMigration().run(ctx);

      final word = (await ctx.readWords()).first;
      expect(word.attributes.gender, Gender.male);
      expect(word.attributes.isPlural, isTrue);
      expect(word.attributes.attributesRaw, isNull);
    });

    test('keeps the record count unchanged', () async {
      final ctx = FakeMigrationContext(
        words: List<Word>.generate(
          5,
          (i) => Word(
            id: 'id$i',
            native: 'native$i',
            pronunciation: '',
            translation: 'trans$i',
          ),
        ),
      );

      await const AttributesMigration().run(ctx);

      expect((await ctx.readWords()).length, 5);
    });
  });
}
