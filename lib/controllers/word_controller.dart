import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/storage/word_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';
import '../services/flashcard_api_service.dart';

class WordController extends GetxController {
  late List<Word> _words;
  List<Word> _filteredWords = [];
  Word _currentWord = Word(hebrew: '', pronunciation: '', translation: '');

  static WordController get getOrPut {
    try {
      return Get.find<WordController>();
    } catch (e) {
      return Get.put(WordController._());
    }
  }

  WordController._() {
    WordLogic.initializeWords(WordStorage.box.words, KardsApiService().getWords).then((words) {
      if (words.isNotEmpty) {
        _filteredWords = _words = words;
        final wordLogic = WordLogic.create(words);
        _currentWord = wordLogic.getWord(words);
        update();
      }
    });
  }

  List<Word> get words => _words;
  List<Word> get filteredWords => _filteredWords;
  Word get currentWord => _currentWord;

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
      WordLogic.instance.addWord(updatedWord, _words);
      update();
    }
  }

  Future<void> updateWord(Word value) async {
    KardsApiService().updateWord(value);
    final index = _words.indexWhere((element) => element.id == value.id);

    if (index == -1) {
      // scenario where words are out of sync with the server
      await addWord(value);
    } else {
      _words[index] = value;
      WordStorage.box.words = _words.toList();
      update();
    }
  }

  void onTap() {
    _currentWord = WordLogic.instance.getWord(_words);
    debugPrint(_currentWord.translation);
    update();
  }

  Future<void> onLongPress() async {
    if (_currentWord.hebrew.isNotEmpty) {
      final updatedWord = await Get.to(() => WordDetailsScreen(title: 'Update Word', word: _currentWord)); //TODO: show updated word
      if (updatedWord != null) {
        _currentWord = updatedWord;
        update();
      }
    }
  }

  void onSearchChange(String text) {
    _filteredWords = _words.where((word) => word.translation.contains(text) || word.translation.startsWith(text)).toList();
    update();
  }
}
