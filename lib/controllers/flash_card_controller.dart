import 'package:flashcard/word_storage.dart';
import 'package:get/get.dart';

import '../models/word.dart';

class FlashCardController extends GetxController {
  late List<Word> _words;

  static FlashCardController get getOrPut {
    try {
      return Get.find<FlashCardController>();
    } catch (e) {
      return Get.put(FlashCardController._());
    }
  }

  FlashCardController._() {
    _words = WordStorage.box.words;
  }

  List<Word> get words {
    return _words;
  }

  set words(List<Word> words) {
    _words = words;
    update();
  }

  void updateWords() {}

  void updateDisplayedWord() {}
}
