import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/word.dart';
import '../storage/word_storage.dart';

class WordLogic {
  static List<Word> _unReadWords = [];
  static WordLogic? _instance;
  List<Word> _words = [];

  static WordLogic get instance {
    assert(_instance != null, 'WordLogic is not created yet');
    return _instance!;
  }

  WordLogic._(List<Word> words) {
    _words = words;
    _unReadWords = words;
  }

  static WordLogic create(List<Word> words) {
    if (_instance == null) {
      _instance = WordLogic._(words);
    }
    return _instance!;
  }

  List<Word> addWord(Word word) {
    _words.add(word);
    _words.sort((firstWords, secondWord) => firstWords.translation.compareTo(secondWord.translation));
    WordStorage.box.words = _words.toList();
    return _words;
  }

  Word getWord() {
    final int randomIndex = Random().nextInt(_unReadWords.length);
    final Word word = _unReadWords[randomIndex];
    _unReadWords.removeAt(randomIndex);

    if (_unReadWords.isEmpty) {
      reset();
    }

    return word;
  }

  void reset() {
    _unReadWords = _words.toList();

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
}
