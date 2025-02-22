import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/widgets/flashcard_snackbar.dart';

import '../models/word.dart';

class FlashcardApiService {
  late String _userId;

  FlashcardApiService(String userId) {
    _userId = userId;
  }

  static void importWords() {
    // fetch words from firebase

    // save to local storage
  }

  static void exportWords() {
    // to implement
  }

  Future<Word?> addWord(Word word) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').add({
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

  Future<List<Word>> getWords() async {
    List<Word> words = [];

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').get();

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

  void updateWord(Word word) {
    FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').doc(word.id).update({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }

  // leave here. Not used in the app, but useful
  void clearDatabase() {
    FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').get().then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    FlashcardSnackbar.showSnackBar('All words deleted');
  }
}
