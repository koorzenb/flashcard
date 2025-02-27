import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/word.dart';
import '../storage/word_storage.dart';
import '../widgets/flashcard_snackbar.dart';

class WordLogic {
  static List<Word> _unReadWords = [];
  static WordLogic? _instance;

  static WordLogic get instance {
    assert(_instance != null, 'WordLogic is not created yet');
    return _instance!;
  }

  WordLogic._(List<Word> words) {
    _unReadWords = words.toList();
  }

  static WordLogic create(List<Word> words) {
    if (_instance == null) {
      _instance = WordLogic._(words);
    }
    return _instance!;
  }

  static dispose() {
    _instance = null;
  }

  void addWord(Word word, List<Word> words) {
    words.add(word);
    words.sort((firstWords, secondWord) => firstWords.translation.compareTo(secondWord.translation));
    WordStorage.box.words = words.toList();
  }

  Word getWord(List<Word> words) {
    final int randomIndex = Random().nextInt(_unReadWords.length);
    final Word word = _unReadWords[randomIndex];
    _unReadWords.removeAt(randomIndex);

    if (_unReadWords.isEmpty) {
      reset(words);
      FlashcardSnackbar.showSnackBar('All words have been read. Starting over.');
    }

    return word;
  }

  void reset(List<Word> words) {
    _unReadWords = words.toList();

    // start new branch - word weight

    // add weight to words - 1 to 5: 1 == 2secs, 2 == 4 secs, 3 == 6 secs, 4 == 8 secs, 5 == 10 secs
    // add CircularProgressIndicator below word to show time

    // logic
    // - if tapped before time, decrease weight by 1. alternatively, if not tapped, increase weight by 1
  }

  void clearCache() {
    _unReadWords.clear();
  }

  @visibleForTesting
  List<Word> get unreadWords => _unReadWords;

  @visibleForTesting
  static void removeInstance() {
    _instance = null;
  }

  static Future<List<Word>> initializeWords(
    List<Word> words,
    Future<List<Word>> Function() fetchWords,
  ) async {
    if (words.isNotEmpty) {
      return words;
    } else {
      final fetchedWords = await fetchWords();

      if (fetchedWords.isNotEmpty) {
        fetchedWords.sort((a, b) => a.translation.compareTo(b.translation));
        WordStorage.box.words = fetchedWords;
        return fetchedWords;
      } else {
        return [Word(native: '', pronunciation: '', translation: '', attributes: '')];
      }
    }
  }
}
