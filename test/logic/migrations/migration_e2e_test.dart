import 'dart:convert';
import 'dart:io';

import 'package:flashcard/logic/migrations/hive_word_migration_context.dart';
import 'package:flashcard/logic/migrations/migration_registry.dart';
import 'package:flashcard/logic/migrations/migration_runner.dart';
import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../test_helper.dart';

const kTestDataFolder = './test_data_migration_e2e';
const kBoxName = '${kTestDataFolder}_WordStorage';

void main() {
  setUpAll(() async {
    TestsHelper.deleteTestDataFolder(kTestDataFolder);
    Hive.init(Directory(kTestDataFolder).path);
    await Hive.openBox(kBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    TestsHelper.deleteTestDataFolder(kTestDataFolder);
  });

  Box _box() => Hive.box(kBoxName);

  setUp(() async {
    await _box().deleteAll(_box().keys);
  });

  group('end-to-end migration of a legacy word box', () {
    test('migrates a legacy bare-list box to the new envelope', () async {
      // A box as an older app build would have written it: a bare list with
      // a legacy free-text `attributes` string.
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {
            'id': 'a',
            'native': 'der Hund',
            'translation': 'dog',
            'attributes': 'masculine'
          },
          {
            'id': 'b',
            'native': 'die Katze',
            'translation': 'cat',
            'attributes': 'feminine'
          },
          {
            'id': 'c',
            'native': 'das Haus',
            'translation': 'house',
            'attributes': 'neuter'
          },
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      final runner = MigrationRunner(steps: MigrationRegistry.steps);

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(result.fromVersion, 0);
      expect(result.toVersion, 1);

      // The container now holds an envelope at version 1.
      expect(await ctx.readVersion(), 1);
      final decoded =
          jsonDecode(_box().get(HiveWordMigrationContext.wordsKey) as String)
              as Map<String, dynamic>;
      expect(decoded['schemaVersion'], 1);
      expect((decoded['words'] as List).length, 3);

      // Every word survived, and the legacy attributes were mapped.
      final words = await ctx.readWords();
      expect(words.length, 3);
      expect(words[0].attributes.gender, Gender.male);
      expect(words[1].attributes.gender, Gender.female);
      expect(words[2].attributes.gender, Gender.neutral);
      expect(words.map((w) => w.id), ['a', 'b', 'c']);
    });

    test('keeps the pre-migration payload as a backup', () async {
      final legacy = jsonEncode([
        {'id': 'a', 'native': 'דָּבָר', 'attributes': 'masculine'},
      ]);
      await _box().put(HiveWordMigrationContext.wordsKey, legacy);

      final ctx = HiveWordMigrationContext(box: _box());
      await MigrationRunner(steps: MigrationRegistry.steps).run(ctx);

      expect(
        _box().get(HiveWordMigrationContext.backupKey),
        legacy,
      );
    });

    test('a second run performs no writes', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {'id': 'a', 'native': 'דָּבָר', 'attributes': 'masculine'},
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      final runner = MigrationRunner(steps: MigrationRegistry.steps);

      await runner.run(ctx);
      final payloadAfterFirst = _box().get(HiveWordMigrationContext.wordsKey);

      final second = await runner.run(ctx);

      expect(second.isSuccess, isTrue);
      expect(second.stepsRun, 0);
      expect(_box().get(HiveWordMigrationContext.wordsKey), payloadAfterFirst);
    });

    test('an already-migrated box is left untouched', () async {
      final ctx = HiveWordMigrationContext(box: _box());
      await ctx.writeWords([
        Word(
          id: 'a',
          native: 'דָּבָר',
          pronunciation: '',
          translation: 'thing',
          attributes:
              const WordAttributes(gender: Gender.male, isPlural: false),
        ),
      ]);
      await ctx.writeVersion(1);

      final payloadBefore = _box().get(HiveWordMigrationContext.wordsKey);
      final result =
          await MigrationRunner(steps: MigrationRegistry.steps).run(ctx);

      expect(result.isSuccess, isTrue);
      expect(result.stepsRun, 0);
      expect(_box().get(HiveWordMigrationContext.wordsKey), payloadBefore);
    });

    test('does not lose a record when the payload holds a malformed one',
        () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {'id': 'a', 'native': 'der Hund', 'attributes': 'masculine'},
          'not a map',
          {'id': 'b', 'native': 'die Katze', 'attributes': 'feminine'},
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      final result =
          await MigrationRunner(steps: MigrationRegistry.steps).run(ctx);

      expect(result.isSuccess, isTrue);
      final words = await ctx.readWords();
      expect(words.length, 2);
      expect(words.map((w) => w.id), ['a', 'b']);
    });
  });
}
