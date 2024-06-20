import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/services/flashcard_api_service.dart';
import 'package:flashcard/word_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/update_screen.dart';

class FlashCardController extends GetxController {
  late List<Word> _words;
  Word displayedWord = Word(hebrew: 'דָבָר', pronunciation: 'de-var', translation: 'word');

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

  void deleteWord(Word word) async {
    // _words.remove(word);
    WordStorage.box.words = _words;
    update();

    try {
      final collectionReference = FirebaseFirestore.instance.collection('words');
      QuerySnapshot querySnapshot = await collectionReference.where('hebrew', isEqualTo: word.hebrew).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    } catch (e) {
      print('error: $e');
    }

    Get.back();
  }

  void addWord(Word word) {
    _words.add(word);
    WordStorage.box.words = _words;
    update();
    FlashCardApiService.addWord(word);
  }

  void updateWord(Word originalWord, Word updatedWord) async {
    _words[_words.indexWhere((element) => element.hebrew == originalWord.hebrew && element.pronunciation == originalWord.pronunciation)] = updatedWord;

    // TODO: on launch, if storage is empty, get latest list of words from firestore

    try {
      final collectionReference = FirebaseFirestore.instance.collection('words');
      QuerySnapshot querySnapshot = await collectionReference.where('hebrew', isEqualTo: originalWord.hebrew).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.update(
          {
            'hebrew': updatedWord.hebrew,
            'pronunciation': updatedWord.pronunciation,
            'translation': updatedWord.translation,
            'attributes': updatedWord.attributes,
          },
        );
      }
    } catch (e) {
      print('error: $e');
    }
    update();
  }

  void onTap() {
    displayedWord = WordLogic(FlashCardController.getOrPut.words).getWord();
    debugPrint(displayedWord.translation);
  }

  void onLongPress() async {
    final updatedWord = await Get.to(() => UpdateScreen(word: displayedWord)); // TODO: consider having an setup mode - then hide update and add button
    if (updatedWord != null) {
      displayedWord = updatedWord;
      update();
    }
  }
}
