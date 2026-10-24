import 'package:flashcard/logic/migrations/firestore_backfill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreBackfill.maxBatchSize', () {
    test('is 500 (Firestore batch limit)', () {
      expect(FirestoreBackfill.maxBatchSize, 500);
    });
  });

  group('FirestoreBackfill.documentNeedsNormalization', () {
    test('a legacy string attributes needs normalization', () {
      expect(
        FirestoreBackfill.documentNeedsNormalization({'attributes': 'masc'}),
        isTrue,
      );
    });

    test('a map attributes does not need normalization', () {
      expect(
        FirestoreBackfill.documentNeedsNormalization(
          {
            'attributes': {'gender': 'male'}
          },
        ),
        isFalse,
      );
    });

    test('missing attributes needs normalization', () {
      expect(
        FirestoreBackfill.documentNeedsNormalization({'native': 'x'}),
        isTrue,
      );
    });

    test('null data needs normalization', () {
      expect(FirestoreBackfill.documentNeedsNormalization(null), isTrue);
    });

    test('an empty map needs normalization', () {
      expect(FirestoreBackfill.documentNeedsNormalization({}), isTrue);
    });
  });

  group('FirestoreBackfill.normalizeDocument', () {
    test('converts a legacy string attributes to a map', () {
      final doc = {'native': 'der Hund', 'attributes': 'masculine'};
      final normalized = FirestoreBackfill.normalizeDocument(doc, 'id1');
      expect(normalized['attributes'], isA<Map>());
      expect(normalized['attributes']['gender'], 'male');
      expect(normalized['attributes']['isPlural'], isFalse);
      expect(normalized['attributes']['attributesRaw'], 'masculine');
    });

    test('handles a compound legacy string (gender + plural)', () {
      final doc = {
        'native': 'les chats',
        'translation': 'cats',
        'attributes': 'feminine plural',
      };
      final normalized = FirestoreBackfill.normalizeDocument(doc, 'id2');
      expect(normalized['attributes']['gender'], 'female');
      expect(normalized['attributes']['isPlural'], isTrue);
      expect(normalized['attributes']['attributesRaw'], 'feminine plural');
    });

    test('preserves other fields', () {
      final doc = {
        'native': 'le chat',
        'pronunciation': 'luh shah',
        'translation': 'cat',
        'attributes': 'masculine',
        'audioId': 'audio-abc',
        'isNew': true,
      };
      final normalized = FirestoreBackfill.normalizeDocument(doc, 'id3');
      expect(normalized['native'], 'le chat');
      expect(normalized['pronunciation'], 'luh shah');
      expect(normalized['translation'], 'cat');
      expect(normalized['audioId'], 'audio-abc');
      expect(normalized['isNew'], isTrue);
      expect(normalized['attributes']['gender'], 'male');
    });

    test('does not include id in the body', () {
      final doc = {'attributes': 'masculine'};
      final normalized = FirestoreBackfill.normalizeDocument(doc, 'doc-id');
      expect(normalized.containsKey('id'), isFalse);
    });

    test('already-normalized documents stay normalized', () {
      final doc = {
        'attributes': {'gender': 'male', 'isPlural': false},
        'native': 'x',
      };
      final normalized = FirestoreBackfill.normalizeDocument(doc, 'id4');
      expect(normalized['attributes'], isA<Map>());
      expect(normalized['attributes']['gender'], 'male');
    });
  });

  group('FirestoreBackfill.chunkList', () {
    test('splits 1200 items into 3 chunks of 500, 500, 200', () {
      final items = List.generate(1200, (i) => i);
      final chunks = FirestoreBackfill.chunkList(
        items,
        FirestoreBackfill.maxBatchSize,
      );
      expect(chunks.length, 3);
      expect(chunks[0].length, 500);
      expect(chunks[1].length, 500);
      expect(chunks[2].length, 200);
    });

    test('an empty list produces no chunks', () {
      expect(FirestoreBackfill.chunkList([], 500), isEmpty);
    });

    test('a list smaller than the chunk size produces one chunk', () {
      final items = List.generate(3, (i) => i);
      final chunks = FirestoreBackfill.chunkList(items, 500);
      expect(chunks.length, 1);
      expect(chunks[0].length, 3);
    });

    test('a list exactly equal to the chunk size produces one chunk', () {
      final items = List.generate(500, (i) => i);
      final chunks = FirestoreBackfill.chunkList(items, 500);
      expect(chunks.length, 1);
      expect(chunks[0].length, 500);
    });

    test('throws on non-positive chunk size', () {
      expect(
        () => FirestoreBackfill.chunkList([1, 2, 3], 0),
        throwsArgumentError,
      );
    });
  });

  group('FirestoreBackfill.matchOrphans', () {
    test('matches orphans by native and translation', () {
      final orphans = [
        {'native': 'der Hund', 'translation': 'dog'},
        {'native': 'le chat', 'translation': 'cat'},
      ];
      final userWords = [
        {'native': 'der Hund', 'translation': 'dog'},
        {'native': 'la table', 'translation': 'table'},
      ];
      final result = FirestoreBackfill.matchOrphans(orphans, userWords);
      expect(result.count, 2);
      expect(result.matched, 1);
    });

    test('returns zero count when no orphans exist', () {
      final result = FirestoreBackfill.matchOrphans([], []);
      expect(result.count, 0);
      expect(result.matched, 0);
    });

    test('handles null orphan data', () {
      final result = FirestoreBackfill.matchOrphans([null], []);
      expect(result.count, 1);
      expect(result.matched, 0);
    });

    test('all orphans match when all user words match', () {
      final orphans = [
        {'native': 'a', 'translation': 'b'},
        {'native': 'c', 'translation': 'd'},
      ];
      final userWords = [
        {'native': 'a', 'translation': 'b'},
        {'native': 'c', 'translation': 'd'},
      ];
      final result = FirestoreBackfill.matchOrphans(orphans, userWords);
      expect(result.count, 2);
      expect(result.matched, 2);
    });

    test('handles missing native/translation in orphan data', () {
      final orphans = [
        {'translation': 'dog'},
        {'native': 'x', 'translation': 'y'},
      ];
      final userWords = [
        {'native': 'x', 'translation': 'y'},
      ];
      final result = FirestoreBackfill.matchOrphans(orphans, userWords);
      expect(result.count, 2);
      expect(result.matched, 1);
    });
  });

  group('BackfillReport', () {
    test('constructs with all fields', () {
      const report = BackfillReport(
        action: BackfillAction.success,
        localCount: 5,
        writtenCount: 5,
        skippedCount: 0,
        error: null,
      );
      expect(report.action, BackfillAction.success);
      expect(report.localCount, 5);
      expect(report.writtenCount, 5);
      expect(report.skippedCount, 0);
      expect(report.error, isNull);
    });
  });

  group('OrphanReport', () {
    test('constructs with count and matched', () {
      const report = OrphanReport(count: 10, matched: 3);
      expect(report.count, 10);
      expect(report.matched, 3);
    });
  });
}
