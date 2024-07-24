import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/services/flashcard_api_service.dart';
import 'package:flashcard/word_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';

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

    if (_words.isEmpty) {
      FlashCardApiService().getWords().then((words) {
        if (words.isEmpty) {
          words = [Word(id: 'id', hebrew: 'דָבָר', pronunciation: 'de-var', translation: 'word', attributes: '')];
        }

        words.sort((a, b) => a.translation.compareTo(b.translation));
        _words = words;
        WordStorage.box.words = _words;
        update();
      });
    }
  }

  List<Word> get words {
    return WordStorage.box.words;
  }

  set words(List<Word> words) {
    _words = words;
    update();
  }

  void deleteWord(Word word) async {
    _words.removeWhere((element) => element.hebrew == word.hebrew && element.translation == word.translation);
    WordStorage.box.words = _words.toList();
    update();

    try {
      final collectionReference = FirebaseFirestore.instance.collection('words');
      QuerySnapshot querySnapshot = await collectionReference.where('hebrew', isEqualTo: word.hebrew).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('error: $e');
    }

    Get.back();
  }

  void addWord(Word word) async {
    final updatedWord = await FlashCardApiService().addWord(word);

    // TODO: check if you can access Firebase (Firebase API?). If not, set a tempId and update once you receive updated response from server
    if (updatedWord != null) {
      WordLogic(words).addWord(updatedWord);
      update();
    }
  }

  void updateWord(Word word) async {
//  fix updating of words. first get dev env to work - do not write to prod data. push once done

    FlashCardApiService().updateWord(word);
    _words[_words.indexWhere((element) => element.id == word.id)] = word;
    WordStorage.box.words = _words.toList();
    update();
  }

  void onTap() {
    displayedWord = WordLogic(FlashCardController.getOrPut.words).getWord();
    debugPrint(displayedWord.translation);
  }

  void onLongPress() async {
    final updatedWord = await Get.to(() => WordDetailsScreen(displayedWord)); // TODO: consider having an setup mode - then hide update and add button
    if (updatedWord != null) {
      displayedWord = updatedWord;
      update();
    }
  }
}
