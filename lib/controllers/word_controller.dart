import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/services/flashcard_api_service.dart';
import 'package:flashcard/storage/word_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';

class WordController extends GetxController {
  late List<Word> _words;
  Word displayedWord = Word(hebrew: 'דָבָר', pronunciation: 'de-var', translation: 'word');

  static WordController get getOrPut {
    try {
      return Get.find<WordController>();
    } catch (e) {
      return Get.put(WordController._());
    }
  }

  WordController._() {
    _words = WordStorage.box.words;

    if (_words.isEmpty) {
      KardsApiService().getWords().then((words) {
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

  Future<void> deleteWord(Word word) async {
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

  Future<void> addWord(Word word) async {
    final updatedWord = await KardsApiService().addWord(word);
    if (updatedWord != null) {
      WordLogic(words).addWord(updatedWord);
      update();
    }
  }

  Future<void> updateWord(Word word) async {
    KardsApiService().updateWord(word);
    _words[_words.indexWhere((element) => element.id == word.id)] = word;
    WordStorage.box.words = _words.toList();
    update();
  }

  void onTap() {
    displayedWord = WordLogic(WordController.getOrPut.words).getWord();
    debugPrint(displayedWord.translation);
  }

  Future<void> onLongPress() async {
    final updatedWord = await Get.to(() => WordDetailsScreen(title: 'Update Word', word: displayedWord));
    if (updatedWord != null) {
      displayedWord = updatedWord;
      update();
    }
  }
}
