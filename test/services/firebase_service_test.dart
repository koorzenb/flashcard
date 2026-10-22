import 'package:flashcard/models/gender.dart';
import 'package:flashcard/services/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseService.wordFromDocument', () {
    test('reads a current-shaped document', () {
      final word = FirebaseService.wordFromDocument({
        'native': 'der Hund',
        'pronunciation': 'dehr hhoont',
        'translation': 'dog',
        'attributes': {'gender': 'male', 'isPlural': false},
      }, 'doc1');

      expect(word.id, 'doc1');
      expect(word.native, 'der Hund');
      expect(word.pronunciation, 'dehr hhoont');
      expect(word.translation, 'dog');
      expect(word.attributes.gender, Gender.male);
      expect(word.attributes.isPlural, isFalse);
    });

    test('tolerates a legacy free-text attributes string', () {
      final word = FirebaseService.wordFromDocument({
        'native': 'die Katze',
        'translation': 'cat',
        'attributes': 'feminine',
      }, 'doc2');

      expect(word.id, 'doc2');
      expect(word.attributes.gender, Gender.female);
    });

    test('tolerates a missing attributes field', () {
      final word = FirebaseService.wordFromDocument({
        'native': 'x',
      }, 'doc3');

      expect(word.attributes.gender, Gender.neutral);
      expect(word.attributes.isPlural, isFalse);
    });

    test('tolerates a null document body', () {
      final word = FirebaseService.wordFromDocument(null, 'doc4');

      expect(word.id, 'doc4');
      expect(word.native, '');
      expect(word.translation, '');
      expect(word.attributes.gender, Gender.neutral);
    });

    test('tolerates missing and null fields', () {
      final word = FirebaseService.wordFromDocument({
        'native': null,
        'pronunciation': null,
        'translation': null,
        'attributes': null,
      }, 'doc5');

      expect(word.native, '');
      expect(word.pronunciation, '');
      expect(word.translation, '');
      expect(word.attributes.gender, Gender.neutral);
    });

    test('derives the id from the document id, overriding a stored id', () {
      final word = FirebaseService.wordFromDocument({
        'id': 'stale-id',
        'native': 'x',
      }, 'doc6');

      expect(word.id, 'doc6');
    });
  });
}
