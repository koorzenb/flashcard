import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/server_environment.dart';
import '../models/word.dart';

class FlashCardApiService {
  static ServerEnvironment _serverEnvironment = ServerEnvironment.prod;

  static void init(ServerEnvironment serverEnvironment) {
    _serverEnvironment = serverEnvironment;
  }

  ServerEnvironment get serverEnvironment => _serverEnvironment;

  static void importWords() {
    // fetch words from firebase

    // save to local storage
  }

  static void exportWords() {
    // to implement
  }

  Future<Word?> addWord(Word word) async {
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

  // TODO: setup flavor for dev/prod data in Firebase

  Future<List<Word>> getWords() async {
    if (_serverEnvironment == ServerEnvironment.dev) {
      return [Word(id: 'id', hebrew: 'בְּדִיקָה', pronunciation: "b'dee-QAH", translation: 'test', attributes: '')];
    }

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

  void updateWord(Word word) {
    FirebaseFirestore.instance.collection('words').doc(word.id).update({
      'hebrew': word.hebrew,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes,
    });
  }
}
