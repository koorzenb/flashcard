import '../../models/word.dart';
import 'migration.dart';
import 'migration_context.dart';

/// The first schema step: `attributes` from a free-text string to a
/// structured [WordAttributes] value.
///
/// This step is **idempotent**: running it on already-migrated data is a
/// no-op, because a word that already holds a structured value is written
/// back unchanged.
///
/// The step does not decide *what* a legacy string means - that mapping lives
/// in [WordAttributes.fromLegacy] and is applied by the tolerant reader when
/// the word is parsed. By the time this step runs, every word already carries
/// a structured value; the step's job is to make the container's data
/// explicitly carry the new shape, including the `attributesRaw` field.
class AttributesMigration extends Migration {
  const AttributesMigration();

  @override
  int get fromVersion => 0;

  @override
  int get toVersion => 1;

  @override
  String get id => 'm001_attributes_to_map';

  @override
  String get family => 'attributes';

  @override
  Future<void> run(MigrationContext ctx) async {
    final words = await ctx.readWords();

    // Every word is rewritten with its normalized attributes. Words that are
    // already in the target shape are written unchanged, so re-running the
    // step is a no-op. We preserve `attributesRaw` so the original legacy
    // string survives the round-trip.
    await ctx.writeWords([
      for (final word in words)
        Word(
          id: word.id,
          native: word.native,
          pronunciation: word.pronunciation,
          translation: word.translation,
          attributes: word.attributes,
          attributesRaw: word.attributesRaw,
          audioId: word.audioId,
          isNew: word.isNew,
        ),
    ]);
  }
}
