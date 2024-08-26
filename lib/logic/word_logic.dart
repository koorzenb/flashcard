import 'dart:math';

import 'package:flashcard/models/word.dart';
import 'package:flutter/foundation.dart';

import '../storage/word_storage.dart';

class WordLogic {
  static List<Word> _unReadWords = [];
  List<Word> _words = [];

  WordLogic(List<Word> words) {
    _words = words;

    if (_unReadWords.isEmpty) {
      _unReadWords = words.toList();
      // TODO: improve unread words - show words that you are having probelms with
    }
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
    return word;
  }

  static void reset() {
    _unReadWords.clear();
  }

  @visibleForTesting
  static List<Word> get unreadWords => _unReadWords;
}
