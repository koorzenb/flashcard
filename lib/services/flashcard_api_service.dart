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

  static Future<Word?> addWord(Word word) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('words').add({
        'hebrew': word.hebrew,
        'pronunciation': word.pronunciation,
        'translation': word.translation,
        'attributes': word.attributes,
      });
      return Word(
        id: snapshot.id,
        hebrew: word.hebrew,
        pronunciation: word.pronunciation,
        translation: word.translation,
        attributes: word.attributes,
      );
    } catch (e) {
      return null;
    }
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

  static void updateWord(Word word) {
    FirebaseFirestore.instance.collection('words').doc(word.id).update({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }
}
