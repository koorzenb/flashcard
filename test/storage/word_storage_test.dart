import 'dart:io';

import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/storage/word_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../test_helper.dart';

const kTestDataFolder = './test_data_word_storage';
const kBoxName = '${kTestDataFolder}_WordStorage';

void main() {
  setUpAll(() async {
    TestsHelper.deleteTestDataFolder(kTestDataFolder);
    Hive.init(Directory(kTestDataFolder).path);
    await WordStorage.init(kTestDataFolder);
  });

  tearDownAll(() async {
    await Hive.close();
    TestsHelper.deleteTestDataFolder(kTestDataFolder);
  });

  group('WordStorage.words is a tolerant reader', () {
    setUp(() async {
      await Hive.box(kBoxName).deleteAll(Hive.box(kBoxName).keys);
    });

    test('returns an empty list when nothing was ever written', () {
      expect(WordStorage.box.words, isEmpty);
    });

    test('returns an empty list for a payload that is not valid JSON', () {
      Hive.box(kBoxName).put('wordListJson', '{not json');

      expect(WordStorage.box.words, isEmpty);
    });

    test('returns an empty list for a JSON payload that is not a list', () {
      Hive.box(kBoxName).put('wordListJson', '{"schemaVersion":1}');

      expect(WordStorage.box.words, isEmpty);
    });

    test('returns an empty list for a non-string payload', () {
      Hive.box(kBoxName).put('wordListJson', 42);

      expect(WordStorage.box.words, isEmpty);
    });

    test('keeps the valid records of a payload with one malformed record', () {
      Hive.box(kBoxName).put(
        'wordListJson',
        '[{"native":"der Hund","translation":"dog"},'
            '"not a map",'
            '{"native":"die Katze","translation":"cat"}]',
      );

      final words = WordStorage.box.words;

      expect(words.length, 2);
      expect(words[0].native, 'der Hund');
      expect(words[1].native, 'die Katze');
    });

    test('reads a legacy attributes string from the persisted payload', () {
      Hive.box(kBoxName).put(
        'wordListJson',
        '[{"native":"der Hund","attributes":"masculine"}]',
      );

      final words = WordStorage.box.words;

      expect(words.length, 1);
      expect(words.first.attributes.gender, Gender.male);
    });

    test('round-trips a written word list', () {
      WordStorage.box.words = [
        Word(native: 'x', pronunciation: 'p', translation: 't'),
      ];

      final words = WordStorage.box.words;

      expect(words.length, 1);
      expect(words.first.native, 'x');
      expect(words.first.translation, 't');
    });
  });
}
