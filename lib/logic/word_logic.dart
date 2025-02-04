import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/word.dart';
import '../storage/word_storage.dart';

class WordLogic {
  static List<Word> _unReadWords = [];
  List<Word> _words = [];

  WordLogic(List<Word> words) {
    _words = words;

    if (_unReadWords.isEmpty) {
      _unReadWords = words.toList();

      // start new branch - word wieght

      // add weight to words - 1 to 5: 1 == 2secs, 2 == 4 secs, 3 == 6 secs, 4 == 8 secs, 5 == 10 secs
      // add CircularProgressIndicator below word to show time

      // logic
      // - if tapped before time, decrease weight by 1. alternatively, if not tapped, increase weight by 1
    }
  }

  List<Word> addWord(Word word) {
    _words.add(word);
    _words.sort((firstWords, secondWord) =>
        firstWords.translation.compareTo(secondWord.translation));
    WordStorage.box.words = _words.toList();
    return _words;
  }

  Word getWord() {
    final int randomIndex = Random().nextInt(_unReadWords.length);
    final Word word = _unReadWords[randomIndex];
    _unReadWords.removeAt(randomIndex);
    return word;
  }

  static void reset() {
    _unReadWords.clear();
  }

  @visibleForTesting
  static List<Word> get unreadWords => _unReadWords;
}
