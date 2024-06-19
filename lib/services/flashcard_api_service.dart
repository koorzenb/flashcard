import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/models/word.dart';

class FlashCardApiService {
  static void downloadWords() async {
    final exportedWords = _toJson(await FirebaseFirestore.instance.collection('words').get());

    // add file to downloads
    // show snackbar with success message
    // add Drawer item
  }

  static List<Map<String, dynamic>> _toJson(QuerySnapshot querySnapshot) {
    final List<Map<String, dynamic>> json = [];

    querySnapshot.docs.forEach((doc) {
      final word = {
        'hebrew': doc['hebrew'],
        'pronunciation': doc['pronunciation'],
        'translation': doc['translation'],
        'attributes': doc['attributes'],
      };
      json.add(word);
    });

    return json;
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
}
