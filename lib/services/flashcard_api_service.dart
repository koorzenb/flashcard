import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/models/word.dart';

class FlashCardApiService {
  static void importWords() {
    // fetch words from firebase

    // save to local storage
  }

  static void exportWords() {
    // to implement
  }

  static void addWord(Word word) {
    FirebaseFirestore.instance.collection('words').add({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }
}
