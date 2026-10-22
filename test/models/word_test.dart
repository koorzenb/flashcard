import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Word JSON round trip', () {
    test('toJson() then fromJson() preserves all fields including attributes',
        () {
      final word = Word(
        id: 'abc123',
        native: 'der Hund',
        pronunciation: 'dehr hhoont',
        translation: 'dog',
        attributes: const WordAttributes(gender: Gender.male, isPlural: false),
        audioId: 'abc123',
        isNew: true,
      );

      final restored = Word.fromJson(word.toJson());

      expect(restored.id, word.id);
      expect(restored.native, word.native);
      expect(restored.pronunciation, word.pronunciation);
      expect(restored.translation, word.translation);
      expect(restored.attributes, word.attributes);
      expect(restored.audioId, word.audioId);
      expect(restored.isNew, word.isNew);
    });

    test('fromJson() reads the nested attributes map', () {
      final json = {
        'id': 'doc1',
        'native': 'die Katze',
        'pronunciation': 'dee kaat-zeh',
        'translation': 'cat',
        'attributes': {'gender': 'female', 'isPlural': true},
        'audioId': '',
        'isNew': false,
      };

      final word = Word.fromJson(json);

      expect(word.attributes.gender, Gender.female);
      expect(word.attributes.isPlural, isTrue);
    });

    test('blank attributes default to neutral + singular', () {
      final word = Word(native: 'x', pronunciation: '', translation: '');

      expect(word.attributes, const WordAttributes.blank());
      expect(word.attributes.gender, Gender.neutral);
      expect(word.attributes.isPlural, isFalse);
      expect(Word.fromJson(word.toJson()).attributes,
          const WordAttributes.blank());
    });
  });
}
