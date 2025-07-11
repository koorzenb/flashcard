import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../logic/word_logic.dart';
import '../models/word.dart';
import '../screens/word_details_screen.dart';
import '../services/firebase_service.dart';
import '../services/flashcard_auth_service.dart';
import '../storage/word_storage.dart';
import 'sound_controller.dart';

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
    WordLogic.initializeWords(WordStorage.box.words, FirebaseService(FlashcardAuthService.userId).getWords).then((words) {
      if (words.isNotEmpty) {
        // TODO: do search for audioFiles (will return a list of audio files) and update the words with their audioIds
        // TODO:  ListTiles in WordList widget should then have an audio icon if the word has an audio file
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

  Future<Word?>? _addWord(Word word) async {
    final updatedWord = await FirebaseService(FlashcardAuthService.userId).addWord(word);
    if (updatedWord != null) {
      WordLogic.instance.addWord(updatedWord, _words);
      update();
    }

    return updatedWord;
  }

  Future<bool> _updateWord(Word word) async {
    FirebaseService(FlashcardAuthService.userId).updateWord(word);
    final index = _words.indexWhere((element) => element.id == word.id);

    if (index == -1) {
      // scenario where words are out of sync with the server
      return false;
    } else {
      _words[index] = word;
      WordStorage.box.words = _words.toList();
      update();
      return true;
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

  Future<void> saveWord(Word word) async {
    if (word.isNew) {
      final updatedWord = await _addWord(word);

      // update all audio file references to 'temp-id' with the new id received from Firebase
      if (updatedWord != null && word.audioId.isNotEmpty) {
        await updateAudioFileName(word, updatedWord);
        unawaited(SoundController.getOrPut.uploadAudioFile(updatedWord.id));
      }
    } else {
      final res = await _updateWord(word);

      if (!res) {
        await _addWord(word);
      }
    }
  }

  Future<void> updateAudioFileName(Word currentWord, Word updatedWord) async {
    await SoundController.getOrPut.updateStorageAudioFilename(currentWord.audioId, updatedWord.id);
    updatedWord.audioId = updatedWord.id;
    await _updateWord(updatedWord); //  updated the Firebase audioId
  }

  // TODO: method for downloading audio files
  downloadAudioFile(String id) {
    SoundController.getOrPut.downloadAudioFile(id);
  }
}
