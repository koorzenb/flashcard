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
    //TODO: backup .env
    implemtnt firebase - see Udemy lesson
    https://firebase.google.com/docs/cli?hl=en&authuser=0&_gl=1*8yu11z*_ga*MTA0ODI4NTAyLjE3MDMwNTc5MzA.*_ga_CW55HF8NVT*MTcwMzA1NzkzMC4xLjEuMTcwMzA1ODQ2OC42MC4wLjA.#cli-ci-systems
  }
}
