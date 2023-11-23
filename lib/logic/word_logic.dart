import 'dart:math';

import 'package:flashcard/models/word.dart';

class WordLogic {
  List<Word> _allWords = [];
  List<Word> _unDisplayedWords = [];

  WordLogic(List<Word> words) {
    _allWords = words;
  }

  Word get word {
    if (_unDisplayedWords.isEmpty) {
      _unDisplayedWords = _allWords;
    }
    final Random random = Random();
    final int randomIndex = random.nextInt(_unDisplayedWords.length);
    final Word word = _unDisplayedWords[randomIndex];
    _unDisplayedWords.removeAt(randomIndex);
    return word;
  }
}
