import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/word.dart';
import '../widgets/flashcard_snackbar.dart';

class FirebaseService {
  late String _userId;

  FirebaseService(String userId) {
    _userId = userId;
  }

  static void importWords() {
    // fetch words from firebase

    // save to local storage
  }

  Future<void> exportWords() async {
    List<Word> words = [];

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').get();

    snapshot.docs.forEach((doc) {
      words.add(Word(
        id: doc.id,
        native: doc['native'],
        pronunciation: doc['pronunciation'],
        translation: doc['translation'],
        attributes: doc['attributes'],
      ));
    });

    final json = words.map((word) => word.toJson()).toList();
    final jsonString = jsonEncode(json);

    try {
      final directory = (await getApplicationDocumentsDirectory()).path;
      final filePath = path.join(directory, 'flashcards.json');
      final file = File(filePath);

      // Ensure the file exists
      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      // Write to file in the application's documents directory
      await file.writeAsString(jsonString);

      print('Exported words to $filePath');
    } catch (e) {
      print('error occurred: $e');
    }
  }

  Future<void> migrateWords() async {
    try {
      final directory = (await getApplicationDocumentsDirectory()).path;
      final filePath = path.join(directory, 'flashcards.json');
      final file = File(filePath);

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      for (var word in json) {
        await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').add({
          'native': word['hebrew'], // T
          'pronunciation': word['pronunciation'],
          'translation': word['translation'],
          'attributes': word['attributes'],
        });
      }

      print('Migrated words from flashcards.json');
    } catch (e) {
      print('error occurred: $e');
    }
  }

  Future<Word?> addWord(Word word) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').add({
        'native': word.native,
        'pronunciation': word.pronunciation,
        'translation': word.translation,
        'attributes': word.attributes,
      });

      return Word(
        id: snapshot.id,
        native: word.native,
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

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').get();
      // need to wrap in try-catch block to handle errors
      snapshot.docs.forEach((doc) {
        words.add(Word(
          id: doc.id,
          native: doc['native'],
          pronunciation: doc['pronunciation'],
          translation: doc['translation'],
          attributes: doc['attributes'],
        ));
      });
    } catch (e) {
      FlashcardSnackbar.showSnackBar('Error fetching words');
    }

    return words;
  }

  void updateWord(Word word) {
    FirebaseFirestore.instance.collection('users').doc(_userId).collection('words').doc(word.id).update({
      'native': word.native,
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
