import 'dart:io';

import 'package:flashcard/logic/word_logic.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/storage/word_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../test_helper.dart';

const kTestDataFolder = './test_data_word_logic';

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

  group('getWord', () {
    late WordLogic wordLogic;
    late List<Word> _words;

    setUp(() {
      _words = [
        Word(
          native: 'word1',
          pronunciation: 'pronunciation1',
          translation: 'translation1',
        ),
        Word(
          native: 'word2',
          pronunciation: 'pronunciation2',
          translation: 'translation2',
        ),
        Word(
          native: 'word3',
          pronunciation: 'pronunciation3',
          translation: 'translation3',
        ),
      ];

      wordLogic = WordLogic.create(_words);
    });

    test('getWord - should return a word, unread words should not contain given word', () {
      final word1 = wordLogic.getWord(_words);

      expect(word1, isA<Word>());

      var expectedUnreadWords = _words.where((element) => element.native != word1.native).toList();
      expect(wordLogic.unreadWords, expectedUnreadWords);

      final word2 = wordLogic.getWord(_words);

      expect(word2, isA<Word>());
      expectedUnreadWords = _words.where((element) => element.native != word1.native && element.native != word2.native).toList();
      expect(wordLogic.unreadWords, expectedUnreadWords);
      expect(wordLogic.unreadWords.length, 1);
    });

    test('addWord()', () {
      final words = [
        Word(
          native: 'wordB',
          pronunciation: 'pronunciationB',
          translation: 'translationB',
        ),
      ];

      WordLogic.removeInstance();

      final wordLogic = WordLogic.create(words);
      wordLogic.addWord(
          Word(
            native: 'wordA',
            pronunciation: 'pronunciationA',
            translation: 'translationA',
          ),
          words);

      final expectedWords = [
        Word(
          native: 'wordA',
          pronunciation: 'pronunciationA',
          translation: 'translationA',
        ),
        Word(
          native: 'wordB',
          pronunciation: 'pronunciationB',
          translation: 'translationB',
        ),
      ];

      expect(WordStorage.box.words[0].translation, expectedWords[0].translation, reason: 'should add a word to the list, sort the list and save to storage');
    });
  });

  group('initializeWords() -', () {
    late List<Word> _database;
    late List<Word> _passedWords;

    setUp(() {
      _database = [
        Word(
          native: 'word2',
          pronunciation: 'pronunciation2',
          translation: 'translation2',
        ),
        Word(
          native: 'word1',
          pronunciation: 'pronunciation1',
          translation: 'translation1',
        ),
        Word(
          native: 'word3',
          pronunciation: 'pronunciation3',
          translation: 'translation3',
        ),
      ];

      _passedWords = [
        Word(
          native: 'word4',
          pronunciation: 'pronunciation4',
          translation: 'translation4',
        ),
        Word(
          native: 'word5',
          pronunciation: 'pronunciation5',
          translation: 'translation5',
        ),
        Word(
          native: 'word6',
          pronunciation: 'pronunciation6',
          translation: 'translation6',
        )
      ];
    });

    test('no words provided and no words on database', () async {
      final words = await WordLogic.initializeWords([], () async => []);

      expect(words.isNotEmpty, isTrue);
      expect(words[0].native.isEmpty, isTrue);
    });

    test('no words provided and words on database', () async {
      final words = await WordLogic.initializeWords([], () async => _database.toList());

      expect(words[0].native, _database[1].native, reason: 'should return words from database and have it sorted');
    });

    test('words provided and no words on database', () async {
      final words = await WordLogic.initializeWords(_passedWords.toList(), () async => []);

      expect(words[0].native, _passedWords[0].native, reason: 'should return words from provided list and have it sorted');
    });

    test('words provided and words on database', () async {
      final words = await WordLogic.initializeWords(_passedWords.toList(), () async => _database);

      expect(words[0].native, _passedWords[0].native, reason: 'should return words from provided list and have it sorted');
    });
  });
}
