import 'package:flashcard/logic/migrations/migration_integrity_check.dart';
import 'package:flashcard/models/gender.dart';
import 'package:flashcard/models/word.dart';
import 'package:flashcard/models/word_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Word> words(int count) => List<Word>.generate(
    count,
    (i) => Word(
      id: 'id$i',
      native: 'native$i',
      pronunciation: 'pron$i',
      translation: 'trans$i',
    ),
  );

  group('MigrationIntegrityCheck.compare', () {
    test('reports an identical payload as fully unchanged', () {
      final before = words(50);
      final report = MigrationIntegrityCheck.compare(before, words(50));

      expect(report.beforeCount, 50);
      expect(report.afterCount, 50);
      expect(report.missing, isEmpty);
      expect(report.added, isEmpty);
      expect(report.changed, isEmpty);
      expect(report.unchanged, 50);
      expect(report.isValid, isTrue);
    });

    test('reports exactly the dropped record as missing', () {
      final before = words(3);
      final after = [before[0], before[2]];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.missing.length, 1);
      expect(report.missing.first, 'id:id1');
      expect(report.added, isEmpty);
      expect(report.isValid, isFalse);
    });

    test('reports an added record', () {
      final before = words(2);
      final after = [...words(2), words(3)[2]];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.added.length, 1);
      expect(report.missing, isEmpty);
    });

    test('reports a changed record without failing the check', () {
      final before = words(2);
      final after = [
        before[0],
        Word(
          id: before[1].id,
          native: before[1].native,
          pronunciation: before[1].pronunciation,
          translation: 'changed',
        ),
      ];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.changed.length, 1);
      expect(report.unchanged, 1);
      expect(report.missing, isEmpty);
      // A changed record is not a data loss.
      expect(report.isValid, isTrue);
    });

    test('matches records by id, not by list position', () {
      final before = words(3);
      final after = [before[2], before[0], before[1]];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.missing, isEmpty);
      expect(report.added, isEmpty);
      expect(report.changed, isEmpty);
      expect(report.unchanged, 3);
    });

    test('falls back to native + translation for records without an id', () {
      final before = [
        Word(id: '', native: 'der Hund', pronunciation: '', translation: 'dog'),
      ];
      final after = [
        Word(id: '', native: 'der Hund', pronunciation: '', translation: 'dog'),
      ];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.missing, isEmpty);
      expect(report.unchanged, 1);
    });

    test('treats a legacy attributes string as equivalent to its mapping', () {
      final before = [
        Word(
          id: 'a',
          native: 'der Hund',
          pronunciation: '',
          translation: 'dog',
          attributes: WordAttributes.fromLegacy('masculine'),
        ),
      ];
      final after = [
        Word(
          id: 'a',
          native: 'der Hund',
          pronunciation: '',
          translation: 'dog',
          attributes: const WordAttributes(
            gender: Gender.male,
            isPlural: false,
          ),
        ),
      ];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.changed, isEmpty);
      expect(report.unchanged, 1);
    });

    test('reports a changed attributes mapping', () {
      final before = [
        Word(
          id: 'a',
          native: 'der Hund',
          pronunciation: '',
          translation: 'dog',
          attributes: const WordAttributes(
            gender: Gender.male,
            isPlural: false,
          ),
        ),
      ];
      final after = [
        Word(
          id: 'a',
          native: 'der Hund',
          pronunciation: '',
          translation: 'dog',
          attributes: const WordAttributes(
            gender: Gender.female,
            isPlural: false,
          ),
        ),
      ];

      final report = MigrationIntegrityCheck.compare(before, after);

      expect(report.changed.length, 1);
    });

    test('reports an empty payload as losing everything', () {
      final report = MigrationIntegrityCheck.compare(words(3), const <Word>[]);

      expect(report.missing.length, 3);
      expect(report.isValid, isFalse);
    });

    test('reports an empty before-payload as adding everything', () {
      final report = MigrationIntegrityCheck.compare(const <Word>[], words(3));

      expect(report.added.length, 3);
      expect(report.missing, isEmpty);
      expect(report.isValid, isTrue);
    });

    test('produces a content-free summary', () {
      final report = MigrationIntegrityCheck.compare(words(3), words(2));

      expect(report.summary, contains('before=3'));
      expect(report.summary, contains('after=2'));
      expect(report.summary, contains('missing=1'));
    });
  });
}
