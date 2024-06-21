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

  static void addWord(Word word) async {
    await FirebaseFirestore.instance.collection('words').add({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }

  static Future<List<Word>> getWords() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('words').get();

    List<Word> words = [];

    snapshot.docs.forEach((doc) {
      words.add(Word(
        id: doc.id,
        hebrew: doc['hebrew'],
        pronunciation: doc['pronunciation'],
        translation: doc['translation'],
        attributes: doc['attributes'],
      ));
    });

    return words;
  }
}
