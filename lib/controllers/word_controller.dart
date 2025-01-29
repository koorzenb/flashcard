import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/server_environment.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';
import '../services/flashcard_api_service.dart';
import '../storage/word_storage.dart';

class WordController extends GetxController {
  late List<Word> _words;
  late List<Word> _filteredWords;
  Word displayedWord = KardsApiService().serverEnvironment == ServerEnvironment.dev
      ? Word(hebrew: 'דָבָר', pronunciation: 'pronunciation', translation: 'translation')
      : Word(hebrew: 'דָבָר', pronunciation: 'de-var', translation: 'word');

  static WordController get getOrPut {
    try {
      return Get.find<WordController>();
    } catch (e) {
      return Get.put(WordController._());
    }
  }

  WordController._() {
    _filteredWords = _words = WordStorage.box.words;

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

  List<Word> get words => _words;
  List<Word> get filteredWords => _filteredWords;

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

  Future<void> updateWord(Word value) async {
    KardsApiService().updateWord(value);
    final index = _words.indexWhere((element) => element.id == value.id);
    _words[index] = value;
    WordStorage.box.words = _words.toList();
    update();
  }

  void onTap() {
    displayedWord = WordLogic(WordController.getOrPut.words).getWord();
    debugPrint(displayedWord.translation);
    update();
  }

  Future<void> onLongPress() async {
    final updatedWord = await Get.to(() => WordDetailsScreen(title: 'Update Word', word: displayedWord));
    if (updatedWord != null) {
      displayedWord = updatedWord;
      update();
    }
  }

  void onSearchChange(String text) {
    _filteredWords = _words.where((word) => word.translation.contains(text) || word.translation.startsWith(text)).toList();
    update();
  }
}
