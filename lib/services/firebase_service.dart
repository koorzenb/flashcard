import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/word.dart';
import '../models/word_attributes.dart';
import '../widgets/flashcard_snackbar.dart';

class FirebaseService {
  late String _userId;

  FirebaseService(String userId) {
    _userId = userId;
  }

  /// Builds a [Word] from a Firestore document, tolerating any legacy shape.
  ///
  /// The document id is the authoritative identity of a word, so it is always
  /// applied to the `id` field (a document may not even carry an `id` field).
  /// Every other field goes through the tolerant [Word.fromJson], so a
  /// missing field, a `null` value or a legacy free-text `attributes` string
  /// degrades gracefully instead of throwing and aborting the whole fetch.
  ///
  /// Exposed as a static helper so it can be unit-tested without a live
  /// Firestore instance.
  static Word wordFromDocument(Map<String, dynamic>? data, String docId) {
    final Map<String, dynamic> fields = Map<String, dynamic>.from(
      data ?? const <String, dynamic>{},
    );
    fields['id'] = docId;
    return Word.fromJson(fields);
  }

  static void importWords() {
    // fetch words from firebase

    // save to local storage
  }

  Future<void> exportWords() async {
    List<Word> words = [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('words')
        .get();

    snapshot.docs.forEach((doc) {
      words.add(wordFromDocument(doc.data(), doc.id));
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
      final json = jsonDecode(jsonString) as List<dynamic>;

      for (var word in json) {
        // Normalize the 'native' field: prefer 'native', fall back to 'hebrew'
        // for older exported flashcards.json files.
        final native = word['native'] ?? word['hebrew'] ?? '';

        // Normalize 'attributes' through the tolerant parser so that a legacy
        // free-text string is converted to the structured map shape before
        // writing to Firestore.
        final attributesRaw = word['attributes'];
        final attributes = attributesRaw is String
            ? WordAttributes.fromLegacy(attributesRaw)
            : (attributesRaw is Map
                ? WordAttributes.fromJson(attributesRaw)
                : WordAttributes.blank());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('words')
            .add({
          'native': native,
          'pronunciation': word['pronunciation'] ?? '',
          'translation': word['translation'] ?? '',
          'attributes': attributes.toJson(),
        });
      }

      print('Migrated words from flashcards.json');
    } catch (e) {
      print('error occurred: $e');
    }
  }

  Future<Word?> addWord(Word word) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('words')
          .add({
        'native': word.native,
        'pronunciation': word.pronunciation,
        'translation': word.translation,
        'attributes': word.attributes.toJson(),
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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('words')
          .get();
      // Each document is parsed independently through the tolerant parser, so
      // one legacy-shaped or incomplete document cannot abort the whole
      // fetch.
      for (final doc in snapshot.docs) {
        try {
          words.add(wordFromDocument(doc.data(), doc.id));
        } catch (e) {
          // Counts only - never the word content.
          developer.log(
            'firebase.getWords.skippedDocument error=${e.runtimeType}',
            name: 'WORD_PARSE',
            level: 900,
          );
        }
      }
    } catch (e) {
      FlashcardSnackbar.showSnackBar('Error fetching words');
    }

    return words;
  }

  void updateWord(Word word) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('words')
        .doc(word.id)
        .update({
      'native': word.native,
      'pronunciation': word.pronunciation,
      'translation': word.translation,
      'attributes': word.attributes.toJson(),
    });
  }

  // leave here. Not used in the app, but useful
  void clearDatabase() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('words')
        .get()
        .then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });

    FlashcardSnackbar.showSnackBar('All words deleted');
  }
}
