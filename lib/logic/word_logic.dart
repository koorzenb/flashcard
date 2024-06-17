import 'dart:math';

import 'package:flashcard/models/word.dart';
import 'package:flutter/foundation.dart';

class WordLogic {
  static List<Word> _unReadWords = [];

  WordLogic(List<Word> words) {
    if (_unReadWords.isEmpty) {
      _unReadWords = words.toList();
    }
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
