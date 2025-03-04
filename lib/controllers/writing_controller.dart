import 'package:flashcard/logic/word_logic.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/services/flashcard_api_service.dart';
import 'package:flashcard/services/flashcard_auth_service.dart';
import 'package:flashcard/storage/word_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WritingController extends GetxController {
  late List<Word> _filteredWords = [];
  Word _currentWord = Word(native: '', pronunciation: '', translation: '');
  Icon? _resultsIcon;

  Icon? get resultsIcon => _resultsIcon;
  Word get currentWord => _currentWord;

  static WritingController create() {
    return Get.put(WritingController._());
  }

  static WritingController get instance {
    return Get.find<WritingController>();
  }

  WritingController._() {
    WordLogic.initializeWords(WordStorage.box.words, FlashcardApiService(FlashcardAuthService.userId).getWords).then((words) {
      if (words.isNotEmpty) {
        updateCurrentWord(words);
      }
    });
  }

  @override
  void onClose() {
    // TODO: implement onClose - dispose controllers when you navigate away from the screen
    super.onClose();
  }

  Future<bool> onCheckWord(String enteredText) async {
    // Add your logic to check the word here
    print('Entered text: $enteredText');

    final isCorrect = enteredText == _currentWord.native;

    if (!isCorrect) {
      _resultsIcon = Icon(
        Icons.close,
        color: Colors.red,
      );
    } else {
      _resultsIcon = Icon(
        Icons.check,
        color: Colors.green,
      );
    }
    update();

    await Future.delayed(const Duration(seconds: 2), () {});

    _resultsIcon = null;

    if (isCorrect) {
      _currentWord = WordLogic.instance.getWord(_filteredWords);
    }

    update();
    return isCorrect;
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
