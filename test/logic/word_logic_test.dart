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
    await WordStorage.init();
  });

  group('getWord', () {
    late WordLogic wordLogic;
    late List<Word> words;

    setUp(() {
      words = [
        Word(hebrew: 'word1', pronunciation: 'pronunciation1', translation: 'translation1'),
        Word(hebrew: 'word2', pronunciation: 'pronunciation2', translation: 'translation2'),
        Word(hebrew: 'word3', pronunciation: 'pronunciation3', translation: 'translation3'),
      ];

      WordLogic.reset();
      wordLogic = WordLogic(words);
    });

    test('getWord - should return a word, unread words should not contain given word', () {
      final word1 = wordLogic.getWord();

      expect(word1, isA<Word>());

      var expectedUnreadWords = words.where((element) => element.hebrew != word1.hebrew).toList();
      expect(WordLogic.unreadWords, expectedUnreadWords);

      final word2 = wordLogic.getWord();

      expect(word2, isA<Word>());

      expectedUnreadWords = words.where((element) => element.hebrew != word1.hebrew && element.hebrew != word2.hebrew).toList();
      expect(WordLogic.unreadWords, expectedUnreadWords);
      expect(WordLogic.unreadWords.length, 1);
    });

    test('addWord()', () {
      final words = [
        Word(hebrew: 'wordB', pronunciation: 'pronunciationB', translation: 'translationB'),
      ];

      final wordLogic = WordLogic(words);
      wordLogic.addWord(Word(hebrew: 'wordA', pronunciation: 'pronunciationA', translation: 'translationA'));

      final expectedWords = [
        Word(hebrew: 'wordA', pronunciation: 'pronunciationA', translation: 'translationA'),
        Word(hebrew: 'wordB', pronunciation: 'pronunciationB', translation: 'translationB'),
      ];

      expect(WordStorage.box.words[0].translation, expectedWords[0].translation, reason: 'should add a word to the list, sort the list and save to storage');
    });
  });
}
