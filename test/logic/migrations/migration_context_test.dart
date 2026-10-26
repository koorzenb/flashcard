import 'dart:convert';
import 'dart:io';

import 'package:flashcard/logic/migrations/hive_word_migration_context.dart';
import 'package:flashcard/models/word.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../test_helper.dart';

const kTestDataFolder = './test_data_migration_context';
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

  group('HiveWordMigrationContext.readVersion', () {
    test('reads a legacy bare-list box as version 0', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {'id': 'a', 'native': 'x'},
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());

      expect(await ctx.readVersion(), 0);
    });

    test('reads the version from the envelope', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode({
          'schemaVersion': 3,
          'words': [
            {'id': 'a', 'native': 'x'},
          ],
        }),
      );

      final ctx = HiveWordMigrationContext(box: _box());

      expect(await ctx.readVersion(), 3);
    });

    test('reads version 0 for an empty box', () async {
      final ctx = HiveWordMigrationContext(box: _box());

      expect(await ctx.readVersion(), 0);
    });
  });

  group('HiveWordMigrationContext.readWords', () {
    test('reads a legacy bare list', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {'id': 'a', 'native': 'x'},
          {'id': 'b', 'native': 'y'},
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      final words = await ctx.readWords();

      expect(words.length, 2);
      expect(words.first.id, 'a');
    });

    test('reads an envelope', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode({
          'schemaVersion': 1,
          'words': [
            {'id': 'a', 'native': 'x'},
          ],
        }),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      final words = await ctx.readWords();

      expect(words.length, 1);
      expect(words.first.id, 'a');
    });

    test('reads an empty list for a missing payload', () async {
      final ctx = HiveWordMigrationContext(box: _box());

      expect(await ctx.readWords(), isEmpty);
    });
  });

  group('HiveWordMigrationContext.writeWords', () {
    test('round-trips a word list', () async {
      final ctx = HiveWordMigrationContext(box: _box());

      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
      ]);

      final words = await ctx.readWords();

      expect(words.length, 1);
      expect(words.first.id, 'a');
      expect(words.first.native, 'x');
    });

    test('preserves the pre-migration payload as a backup', () async {
      final legacy = jsonEncode([
        {'id': 'a', 'native': 'x'},
      ]);
      await _box().put(HiveWordMigrationContext.wordsKey, legacy);

      final ctx = HiveWordMigrationContext(box: _box());
      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
      ]);

      expect(
        _box().get(HiveWordMigrationContext.backupKey),
        legacy,
        reason: 'the backup must hold the pre-migration payload verbatim',
      );
    });

    test('leaves no shadow key behind', () async {
      final ctx = HiveWordMigrationContext(box: _box());

      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
      ]);

      expect(_box().get(HiveWordMigrationContext.shadowKey), isNull);
    });

    test('writes an envelope, not a bare list', () async {
      final ctx = HiveWordMigrationContext(box: _box());

      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
      ]);

      final decoded = jsonDecode(
        _box().get(HiveWordMigrationContext.wordsKey) as String,
      );
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded.containsKey('schemaVersion'), isTrue);
    });
  });

  group('HiveWordMigrationContext.writeVersion', () {
    test('advances the version inside the envelope', () async {
      final ctx = HiveWordMigrationContext(box: _box());
      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
      ]);

      await ctx.writeVersion(1);

      expect(await ctx.readVersion(), 1);
      final decoded =
          jsonDecode(_box().get(HiveWordMigrationContext.wordsKey) as String)
              as Map<String, dynamic>;
      expect(decoded['schemaVersion'], 1);
    });

    test('keeps the words while advancing the version', () async {
      final ctx = HiveWordMigrationContext(box: _box());
      await ctx.writeWords([
        Word(id: 'a', native: 'x', pronunciation: 'p', translation: 'y'),
        Word(id: 'b', native: 'z', pronunciation: 'q', translation: 'w'),
      ]);

      await ctx.writeVersion(2);

      final words = await ctx.readWords();
      expect(words.length, 2);
      expect(await ctx.readVersion(), 2);
    });

    test('upgrades a legacy bare list to an envelope', () async {
      await _box().put(
        HiveWordMigrationContext.wordsKey,
        jsonEncode([
          {'id': 'a', 'native': 'x'},
        ]),
      );

      final ctx = HiveWordMigrationContext(box: _box());
      await ctx.writeVersion(1);

      expect(await ctx.readVersion(), 1);
      final words = await ctx.readWords();
      expect(words.length, 1);
      expect(words.first.id, 'a');
    });
  });
}
