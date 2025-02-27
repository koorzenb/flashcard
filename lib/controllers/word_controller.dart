import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';
import '../services/flashcard_api_service.dart';
import '../services/flashcard_auth_service.dart';
import '../storage/word_storage.dart';

class WordController extends GetxController {
  late List<Word> _words;
  List<Word> _filteredWords = [];
  Word _currentWord = Word(native: '', pronunciation: '', translation: '');

  static WordController create() {
    return Get.put(WordController._());
  }

  static WordController get instance {
    return Get.find<WordController>();
  }

  WordController._() {
    WordLogic.initializeWords(WordStorage.box.words, FlashcardApiService(FlashcardAuthService.userId).getWords).then((words) {
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
    _words.removeWhere((element) => element.native == word.native && element.translation == word.translation);
    WordStorage.box.words = _words.toList();
    update();

    try {
      final collectionReference = FirebaseFirestore.instance.collection('words');
      QuerySnapshot querySnapshot = await collectionReference.where('native', isEqualTo: word.native).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('error: $e');
    }

    Get.back();
  }

  Future<void> addWord(Word word) async {
    final updatedWord = await FlashcardApiService(FlashcardAuthService.userId).addWord(word);
    if (updatedWord != null) {
      WordLogic.instance.addWord(updatedWord, _words);
      update();
    }
  }

  Future<void> updateWord(Word value) async {
    FlashcardApiService(FlashcardAuthService.userId).updateWord(value);
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
    if (_currentWord.native.isNotEmpty) {
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
