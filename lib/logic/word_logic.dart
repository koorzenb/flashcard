import 'dart:math';

import 'package:flashcard/models/word.dart';

class WordLogic {
  List<Word> _allWords = [];
  List<Word> _unReadWords = [];

  WordLogic(List<Word> words) {
    _allWords = words;
  }

  Word get word {
    if (_unReadWords.isEmpty) {
      _unReadWords = _allWords;
    }
    final Random random = Random();
    final int randomIndex = random.nextInt(_unReadWords.length);
    final Word word = _unReadWords[randomIndex];
    _unReadWords.removeAt(randomIndex);
    return word;
  }
}
