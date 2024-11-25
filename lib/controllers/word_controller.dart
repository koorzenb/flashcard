import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/models/server_environment.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';
import '../services/flashcard_api_service.dart';
import '../storage/word_storage.dart';

class WordController extends GetxController {
  late List<Word> _words;
  late List<Word> _filteredWords;
  Word displayedWord = FlashCardApiService().serverEnvironment == ServerEnvironment.dev
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

  List<Word> get words => _words;
  List<Word> get filteredWords => _filteredWords;

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

  void updateWord(Word value) async {
//  fix updating of words. first get dev env to work - do not write to prod data. push once done

    FlashCardApiService().updateWord(value);
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

  void onLongPress() async {
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
