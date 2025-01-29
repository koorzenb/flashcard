import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashcard/models/server_environment.dart';
import 'package:flashcard/models/word.dart';

class KardsApiService {
  static ServerEnvironment serverEnvironment = ServerEnvironment.prod;
  late String _userId;

  KardsApiService() {
    final flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

    if (flavor != 'prod') {
      serverEnvironment = ServerEnvironment.dev;
    }

    _userId = FirebaseAuth.instance.currentUser!.uid;
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
    if (serverEnvironment == ServerEnvironment.dev) {
      return [Word(id: 'id', hebrew: 'בְּדִיקָה', pronunciation: "b'dee-QAH", translation: 'test', attributes: '')];
    }

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
}
