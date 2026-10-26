import 'package:flashcard/app_constants.dart';
import 'package:flashcard/logic/migrations/attributes_migration.dart';
import 'package:flashcard/logic/migrations/migration_registry.dart';
import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_test_helpers.dart';

void main() {
  group('AttributesMigration', () {
    test('has the expected identity', () {
      const migration = AttributesMigration();

      expect(migration.fromVersion, 0);
      expect(migration.toVersion, 1);
      expect(migration.id, 'm001_attributes_to_map');
      expect(migration.family, 'attributes');
    });

    test('normalizes a legacy attributes string', () async {
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
    });

    test('preserves every other field', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'der Hund',
            pronunciation: 'dehr hhoont',
            translation: 'dog',
            audioId: 'audio1',
            isNew: true,
          ),
        ],
      );

      await const AttributesMigration().run(ctx);

      final word = (await ctx.readWords()).first;
      expect(word.id, 'a');
      expect(word.native, 'der Hund');
      expect(word.pronunciation, 'dehr hhoont');
      expect(word.translation, 'dog');
      expect(word.audioId, 'audio1');
      expect(word.isNew, isTrue);
    });

    test('is idempotent: a second run changes nothing', () async {
      final ctx = FakeMigrationContext(
        words: [
          Word(
            id: 'a',
            native: 'der Hund',
            pronunciation: '',
            translation: 'dog',
            attributes: WordAttributes.fromLegacy('feminine'),
          ),
        ],
      );

      const migration = AttributesMigration();
      await migration.run(ctx);
      final first = await ctx.readWords();
      await migration.run(ctx);
      final second = await ctx.readWords();

      expect(second.length, first.length);
      expect(second.first.attributes, first.first.attributes);
      expect(second.first.native, first.first.native);
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

  group('MigrationRegistry', () {
    test('registers the attributes migration', () {
      expect(
        MigrationRegistry.steps.map((s) => s.id),
        contains('m001_attributes_to_map'),
      );
    });

    test('registers the steps in ascending fromVersion order', () {
      final versions =
          MigrationRegistry.steps.map((s) => s.fromVersion).toList();

      for (var i = 1; i < versions.length; i++) {
        expect(versions[i], greaterThan(versions[i - 1]));
      }
    });

    test('registers steps whose toVersion does not exceed the app version', () {
      for (final step in MigrationRegistry.steps) {
        expect(
          step.toVersion,
          lessThanOrEqualTo(AppConstants.currentWordSchemaVersion),
        );
      }
    });

    test('registers unique step ids', () {
      final ids = MigrationRegistry.steps.map((s) => s.id).toList();

      expect(ids.toSet().length, ids.length);
    });
  });
}
