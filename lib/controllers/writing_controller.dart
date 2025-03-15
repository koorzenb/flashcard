import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../logic/writing_logic.dart';
import '../models/word.dart';
import '../services/firebase_service.dart';
import '../services/flashcard_auth_service.dart';
import '../storage/word_storage.dart';

class WritingController extends GetxController {
  late List<Word> _filteredWords = [];
  Word _currentWord = Word(native: '', pronunciation: '', translation: '');
  Icon? _resultsIcon;
  int _attemptsRemaining = 2;
  int _score = 0;
  String _resultTranslation = '';

  Icon? get resultsIcon => _resultsIcon;
  Word get currentWord => _currentWord;
  int get attemptsRemaining => _attemptsRemaining;
  int get score => _score;
  get resultTranslation => _resultTranslation;

  static WritingController create() {
    return Get.put(WritingController._());
  }

  static WritingController get instance {
    return Get.find<WritingController>();
  }

  WritingController._() {
    WordLogic.initializeWords(WordStorage.box.words, FirebaseService(FlashcardAuthService.userId).getWords).then((words) {
      if (words.isNotEmpty) {
        updateCurrentWord(words);
      }
    });
  }

  Future<bool> onCheckWord(String enteredText) async {
    final result = WritingLogic.checkWord(enteredText, _currentWord, _attemptsRemaining, _score);

    _resultsIcon = result.icon;
    _attemptsRemaining = result.attemptsRemaining;
    _score = result.score;
    _resultTranslation = result.translation;
    update(); // updating icon

    await Future.delayed(const Duration(seconds: 2), () {});

    _resultsIcon = null;

    if (result.updateCurrentWord) {
      _currentWord = WordLogic.instance.getWord(_filteredWords);
    }

    update(); // reset icon and update current word
    return result.isCorrect;
  }

  void updateCurrentWord(List<Word> words) {
    _filteredWords = words.where((word) => word.audioId.isNotEmpty).toList();

    for (var word in words) {
      print('Native: ${word.native}, audioId: ${word.audioId}');
    }

    if (_filteredWords.isNotEmpty) {
      _currentWord = WordLogic.instance.getWord(_filteredWords, true);
      update();
    }
  }
}
