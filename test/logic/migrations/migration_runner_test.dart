import 'package:flashcard/logic/migrations/migration_failure.dart';
import 'package:flashcard/logic/migrations/migration_runner.dart';
import 'package:flashcard/models/word.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migration_test_helpers.dart';

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

  group('MigrationRunner.selectSteps', () {
    test('selects the steps whose toVersion is above the current version', () {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final step2 = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final runner = MigrationRunner(steps: [step1, step2], targetVersion: 2);

      expect(runner.selectSteps(0).map((s) => s.id), ['s1', 's2']);
      expect(runner.selectSteps(1).map((s) => s.id), ['s2']);
      expect(runner.selectSteps(2), isEmpty);
    });

    test('sorts the selected steps ascending by fromVersion', () {
      final step2 = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final runner = MigrationRunner(steps: [step2, step1], targetVersion: 2);

      expect(runner.selectSteps(0).map((s) => s.id), ['s1', 's2']);
    });

    test('skips the steps that are already applied', () {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);

      expect(runner.selectSteps(1), isEmpty);
    });

    test('rejects a step whose toVersion exceeds the app schema version', () {
      final future = FakeMigration(fromVersion: 1, toVersion: 99, id: 'future');
      final runner = MigrationRunner(steps: [future], targetVersion: 2);

      expect(runner.selectSteps(0), isEmpty);
    });
  });

  group('MigrationRunner.run - abort semantics', () {
    test('stops at the first failing step', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final step2 = FakeMigration(
        fromVersion: 1,
        toVersion: 2,
        id: 's2',
        error: StateError('boom'),
      );
      final step3 = FakeMigration(fromVersion: 2, toVersion: 3, id: 's3');
      final runner =
          MigrationRunner(steps: [step1, step2, step3], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      expect(step1.executionOrder, ['s1']);
      expect(step2.executionOrder, ['s2']);
      expect(step3.executionOrder, isEmpty);
    });

    test('does not advance the version past the failing step', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final step2 = FakeMigration(
        fromVersion: 1,
        toVersion: 2,
        id: 's2',
        error: StateError('boom'),
      );
      final runner = MigrationRunner(steps: [step1, step2], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      // Step 1 succeeded, so its version stays advanced; step 2 never does.
      expect(ctx.writtenVersions, [1]);
      expect(result.toVersion, 1);
      expect(result.stepsRun, 1);
    });

    test('leaves the container untouched when the first step fails', () async {
      final step1 = FakeMigration(
        fromVersion: 0,
        toVersion: 1,
        id: 's1',
        error: StateError('boom'),
      );
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      expect(result.fromVersion, 0);
      expect(result.toVersion, 0);
      expect(ctx.writtenVersions, isEmpty);
      expect(ctx.writtenWords, isEmpty);
    });

    test('reports the failure with a stable code and the step id', () async {
      final step1 = FakeMigration(
        fromVersion: 0,
        toVersion: 1,
        id: 's1',
        error: MigrationFailure(
          code: MigrationFailureCode.parseFailed,
          stepId: 's1',
          message: 'could not parse a record',
        ),
      );
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      expect(result.failure, isNotNull);
      expect(result.failure!.code, MigrationFailureCode.parseFailed);
      expect(result.failure!.stepId, 's1');
    });

    test('wraps a non-MigrationFailure error into a MigrationFailure',
        () async {
      final step1 = FakeMigration(
        fromVersion: 0,
        toVersion: 1,
        id: 's1',
        error: StateError('boom'),
      );
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      expect(result.failure!.code, MigrationFailureCode.unknown);
      expect(result.failure!.stepId, 's1');
      expect(result.failure!.cause, isA<StateError>());
    });

    test('resumes at the failing step on the next run', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final failing = FakeMigration(
        fromVersion: 1,
        toVersion: 2,
        id: 's2',
        error: StateError('boom'),
      );
      final runner = MigrationRunner(steps: [step1, failing], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      await runner.run(ctx);
      expect(ctx.writtenVersions, [1]);

      // The step is fixed and the runner is run again.
      final fixed = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final second =
          await MigrationRunner(steps: [step1, fixed], targetVersion: 2)
              .run(ctx);

      expect(second.isSuccess, isTrue);
      expect(fixed.executionOrder, ['s2']);
      expect(ctx.writtenVersions, [1, 2]);
    });
  });

  group('MigrationRunner.run - integrity validation', () {
    test('blocks the version advance when a record was lost', () async {
      final step = DroppingMigration(fromVersion: 0, toVersion: 1);
      final runner = MigrationRunner(steps: [step], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isAborted, isTrue);
      expect(result.failure!.code, MigrationFailureCode.integrityMismatch);
      expect(ctx.writtenVersions, isEmpty);
      expect(result.toVersion, 0);
    });

    test('allows the version advance when a record was only changed', () async {
      final step = ChangingMigration(fromVersion: 0, toVersion: 1);
      final runner = MigrationRunner(steps: [step], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(ctx.writtenVersions, [1]);
    });

    test('allows the version advance for a no-op step', () async {
      final step = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final runner = MigrationRunner(steps: [step], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(ctx.writtenVersions, [1]);
    });
  });

  group('MigrationRunner.run - incremental semantics', () {
    test('runs the outstanding steps in ascending order', () async {
      final step2 = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final runner = MigrationRunner(steps: [step2, step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(step1.executionOrder, ['s1']);
      expect(step2.executionOrder, ['s2']);
    });

    test('persists the version after each successful step', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final step2 = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final runner = MigrationRunner(steps: [step1, step2], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(ctx.writtenVersions, [1, 2]);
      expect(result.fromVersion, 0);
      expect(result.toVersion, 2);
      expect(result.stepsRun, 2);
    });

    test('skips the already-applied steps', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final step2 = FakeMigration(fromVersion: 1, toVersion: 2, id: 's2');
      final runner = MigrationRunner(steps: [step1, step2], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3), version: 1);

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(step1.executionOrder, isEmpty);
      expect(step2.executionOrder, ['s2']);
      expect(ctx.writtenVersions, [2]);
    });

    test('re-running an up-to-date container is a no-op', () async {
      final step1 = FakeMigration(fromVersion: 0, toVersion: 1, id: 's1');
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3), version: 1);

      final result = await runner.run(ctx);

      expect(result.isSuccess, isTrue);
      expect(result.stepsRun, 0);
      expect(step1.executionOrder, isEmpty);
      expect(ctx.writtenVersions, isEmpty);
      expect(ctx.writtenWords, isEmpty);
    });

    test('is idempotent: a second run performs no writes', () async {
      final step1 = FakeMigration(
        fromVersion: 0,
        toVersion: 1,
        id: 's1',
        mutate: (w) => w,
      );
      final runner = MigrationRunner(steps: [step1], targetVersion: 2);
      final ctx = FakeMigrationContext(words: words(3));

      await runner.run(ctx);
      final writesAfterFirst = ctx.writtenWords.length;
      final second = await runner.run(ctx);

      expect(second.isSuccess, isTrue);
      expect(second.stepsRun, 0);
      expect(ctx.writtenWords.length, writesAfterFirst);
    });
  });
}
