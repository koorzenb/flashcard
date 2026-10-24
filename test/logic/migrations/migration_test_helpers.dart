import 'package:flashcard/logic/migrations/migration.dart';
import 'package:flashcard/logic/migrations/migration_context.dart';
import 'package:flashcard/models/word.dart';
import 'package:flutter_test/flutter_test.dart';

/// A migration context backed by an in-memory list.
class FakeMigrationContext implements MigrationContext {
  FakeMigrationContext({
    List<Word>? words,
    int version = 0,
    this.onWrite,
  })  : _words = List<Word>.from(words ?? const <Word>[]),
        _version = version;

  List<Word> _words;
  int _version;

  /// The versions that were written, in order.
  final List<int> writtenVersions = [];

  /// The payloads that were written, in order.
  final List<List<Word>> writtenWords = [];

  /// An optional hook invoked before a write, used to simulate a failure.
  final void Function(int wordCount)? onWrite;

  @override
  Future<List<Word>> readWords() async => List<Word>.from(_words);

  @override
  Future<void> writeWords(List<Word> words) async {
    onWrite?.call(words.length);
    _words = List<Word>.from(words);
    writtenWords.add(List<Word>.from(words));
  }

  @override
  Future<int> readVersion() async => _version;

  @override
  Future<void> writeVersion(int version) async {
    _version = version;
    writtenVersions.add(version);
  }

  @override
  String get scopeLabel => 'fake';
}

/// A migration that records that it ran and optionally mutates the words.
class FakeMigration implements Migration {
  FakeMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.id,
    this.family = 'test',
    this.mutate,
    this.error,
  });

  @override
  final int fromVersion;

  @override
  final int toVersion;

  @override
  final String id;

  @override
  final String family;

  /// Transforms the words, if any.
  final List<Word> Function(List<Word> words)? mutate;

  /// When set, the step throws this error instead of running.
  final Object? error;

  /// The order in which this step was executed.
  final List<String> executionOrder = [];

  @override
  Future<void> run(MigrationContext ctx) async {
    executionOrder.add(id);
    final error = this.error;
    if (error != null) {
      throw error;
    }
    final words = await ctx.readWords();
    final mutate = this.mutate;
    if (mutate != null) {
      await ctx.writeWords(mutate(words));
    }
  }
}

/// A step that drops a record, used to test the integrity check.
class DroppingMigration extends FakeMigration {
  DroppingMigration({required super.fromVersion, required super.toVersion})
      : super(id: 'dropping');

  @override
  Future<void> run(MigrationContext ctx) async {
    executionOrder.add(id);
    final words = await ctx.readWords();
    await ctx.writeWords(words.skip(1).toList());
  }
}

/// A step that changes a record's content without losing it.
class ChangingMigration extends FakeMigration {
  ChangingMigration({required super.fromVersion, required super.toVersion})
      : super(id: 'changing');

  @override
  Future<void> run(MigrationContext ctx) async {
    executionOrder.add(id);
    final words = await ctx.readWords();
    await ctx.writeWords([
      for (final word in words)
        Word(
          id: word.id,
          native: word.native,
          pronunciation: word.pronunciation,
          translation: '${word.translation}!',
          attributes: word.attributes,
          audioId: word.audioId,
        ),
    ]);
  }
}
