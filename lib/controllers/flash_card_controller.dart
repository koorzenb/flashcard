import 'package:cloud_firestore/cloud_firestore.dart';
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
  }

  void addWord(Word word) {
    _words.add(word);
    WordStorage.box.words = _words;
    update();
    FirebaseFirestore.instance.collection('words').add({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }

  void updateWord(Word originalWord, Word updatedWord) async {
    final index = _words.indexOf(originalWord);
    _words[index] = updatedWord;
    WordStorage.box.words = _words;
    update();

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
  }

  void updateDisplayedWord() {}
}
