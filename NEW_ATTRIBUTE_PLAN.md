# Plan: Word Attribute Schema Migration (`attributes`: String → `WordAttributes`)

## Context

- **Goal**: Migrate persisted word data from the legacy free-text `attributes` field to the new structured `WordAttributes` model, without data loss, using a versioned, idempotent migration framework that covers both local (Hive) and remote (Firestore) storage.
- **User Story**: As a user with existing words, I want my words to survive the schema change and keep working, so that the new gender/plural attributes do not wipe my vocabulary.
- **Dependencies**:
  - `lib/models/word.dart` — `Word`, `Word.toJson()`, `Word.fromJson()`, `Word.listFromJsonList()`
  - `lib/models/word_attributes.dart` — `WordAttributes`, `WordAttributes.fromJson()`
  - `lib/models/gender.dart` — `Gender` enum (`male`, `female`, `neutral`)
  - `lib/storage/word_storage.dart` — per-user Hive box `{username}_WordStorage`, key `wordListJson`
  - `lib/storage/main_app_storage.dart` — global Hive box `MainAppStorage`
  - `lib/services/firebase_service.dart` — `getWords()`, `addWord()`, `updateWord()`, `exportWords()`, `migrateWords()`
  - `lib/controllers/app_controller.dart` — `_init(User)` bootstrap, `WordStorage.init(username)` then `WordController.create()`
  - `lib/controllers/word_controller.dart` — `WordController._()` reads `WordStorage.box.words` then falls back to `FirebaseService.getWords()`
  - `lib/logic/word_logic.dart` — `WordLogic.initializeWords()` (local-first, caches remote words into Hive)
  - `lib/main_common.dart` — `commonInit()` → `_initializeStorage()` → `_initializeFirebase()` → `AppController.initialize()`
  - `PRD.md` — product context for the attribute feature

## Scope

**In Scope:**

- Tolerant (backward-compatible) readers for every deserialization path.
- A versioned migration framework in `lib/logic/migrations/` with per-step transformers and a runner.
- Version metadata stored in `MainAppStorage` (app scope) and `{username}_WordStorage` (per-user scope).
- Local (Hive) and remote (Firestore) migration paths sharing one canonical transformation logic via a `MigrationContext` abstraction.
- Automatic, resumable Firestore backfill running in the background after sign-in.
- Legacy string → structured attributes mapping with the original raw string preserved.
- Fixture-based tests for every migration step and every reader path.

**Out of Scope:**

- Changing the `Word`/`WordAttributes` public API beyond additive, non-breaking changes.
- Deleting legacy data, removing backups, or dropping legacy read support (that is Phase 4).
- Migrating the orphan top-level `words` collection (ownership is ambiguous — see Phase 3, Step 3.4).
- Import/export file format redesign (`flashcards.json` key mismatch is fixed in Phase 2, Step 2.6).
- UI/UX redesign of the attribute input widgets.
- Any behavior change visible to the user beyond the attribute values themselves.

## Security Requirements

- **Credentials**: none introduced. Existing `FirebaseOptions` in `lib/firebase_options_prod.dart` and Firebase Auth are used unchanged. Migration code must not log or copy auth tokens.
- **API Scopes**: Firestore access stays within the already-used `users/{uid}/words` subcollection. The backfill must not read or write any other user's data and must not enumerate the top-level `words` collection.
- **Data Privacy**: word data is user content. Backups stay on-device (Hive box) and in the user's own Firestore subcollection. Migration logs must contain counts and error types only — never word text, translations, or audio URLs.

## Risk Assessment

- **Technical**: Hive writes are per-key atomic but a full-list replace is not — a crash mid-write can leave `wordListJson` missing. Mitigated by writing to a shadow key first, then swapping (Phase 3, Step 3.2). Firestore batches are limited to 500 operations — backfill must chunk.
- **Integration**: an old app build reading data written by the new build will fail on the map shape. Mitigated by the Expand/Contract ordering: new builds accept both shapes, and the legacy read path is only removed in Phase 4 after old clients are dead.
- **Data loss**: `Word.listFromJsonList` currently swallows all errors and returns `[]`, so one malformed record silently discards the entire vocabulary. Mitigated in Phase 1 (per-record parsing) — this is the highest-priority fix.
- **Mitigation**: every phase ships with a backup-first write path, non-deleting semantics, a recorded schema version, and a fixture test proving the old format still reads.

---

## Phase 1: Tolerant Readers (no data loss, no version bump)

**Goal**: Make every read path accept legacy `attributes` strings, missing `attributes`, and malformed records — so no data is lost even before any migration runs.
**Dependencies**: `lib/models/word_attributes.dart`, `lib/models/word.dart`, `lib/services/firebase_service.dart`

### Step 1.1: Make `WordAttributes.fromJson` total (never throws)

- **Action**: Change the factory to accept `dynamic` and normalize three shapes: (a) `Map` with `gender`/`isPlural` (current format), (b) `String` (legacy free text), (c) `null`/missing → `WordAttributes.blank()`. For the map case, replace the throwing `Gender.values.firstWhere(...)` with a safe lookup that falls back to `Gender.neutral` for unknown/missing gender. Add a static helper `WordAttributes.fromLegacy(String raw)` that maps legacy text to a structured value (mapping table defined in Step 2.1).
- **Files**: `lib/models/word_attributes.dart`
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: `WordAttributes.fromJson('masculine')`, `WordAttributes.fromJson(null)`, `WordAttributes.fromJson({'gender': 'bogus'})` and `WordAttributes.fromJson({'gender': 'male', 'isPlural': true})` all return a valid object and none throw.

### Step 1.2: Make `Word.fromJson` null-safe

- **Action**: Default missing `id`, `native`, `pronunciation`, `translation`, `audioId` to `''` instead of passing `null` into non-nullable `String` parameters. Route `attributes` through the tolerant `WordAttributes.fromJson`.
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: `Word.fromJson({'native': 'x'})` returns a `Word` with empty strings and blank attributes; the existing round-trip tests in `test/models/word_test.dart` still pass.

### Step 1.3: Parse words per record instead of all-or-nothing

- **Action**: Replace the `try { ... } catch (_) { return []; }` body of `Word.listFromJsonList` with a per-record parse that collects valid words and skips malformed ones, keeping the list non-empty if at least one record is valid. Report invalid records via a debug log rather than an exception.
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: a list containing one malformed record and two valid records returns the two valid words instead of `[]`.

### Step 1.4: Route Firestore reads through the tolerant parser

- **Action**: In `FirebaseService.getWords()` and `FirebaseService.exportWords()`, stop calling `WordAttributes.fromJson(doc['attributes'])` directly on the raw document field. Build the word from the document map via the tolerant `Word.fromJson` (mapping `doc.id` → `id`), so a legacy string `attributes` field or a missing field no longer throws and aborts the whole fetch.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart` (use `fake_cloud_firestore` if it is already a dependency; otherwise assert the parsing helper on representative doc maps in `test/models/word_test.dart`)
- **Success**: fetching a collection whose documents contain string `attributes` returns words instead of raising "Error fetching words".

---

## Phase 2: Versioned Migration Framework (the scalable core)

**Goal**: Introduce an explicit, ordered, idempotent migration mechanism with per-scope version metadata, shared by local and remote storage.
**Dependencies**: Phase 1 complete (readers must tolerate old data before any migration runs)

### Step 2.1: Define the legacy → new attribute mapping

- **Action**: Add a canonical mapping used by every migration and by the tolerant reader: `masculine|male|m` → `Gender.male`; `feminine|female|f` → `Gender.female`; `neutral|n` → `Gender.neutral`; text containing `plural|pl` → `isPlural: true`; anything else → `Gender.neutral`, `isPlural: false`. Always keep the original legacy string in a new `attributesRaw` field on `WordAttributes` so nothing is discarded and the user can correct it later.
- **Files**: `lib/models/word_attributes.dart`, `lib/models/word.dart` (add `attributesRaw` to the model, `toJson()`, and `fromJson()`)
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: a table-driven test proves each legacy token maps to the expected `Gender`/`isPlural`, that unknown text maps to neutral/singular, and that the raw text survives a `toJson()`/`fromJson()` round trip.

### Step 2.2: Create the migration abstraction

- **Action**: Add `lib/logic/migrations/migration.dart` defining `abstract class Migration { int get fromVersion; int get toVersion; String get id; Future<void> run(MigrationContext ctx); }` and `lib/logic/migrations/migration_context.dart` defining the storage-agnostic context interface (`readWords()`, `writeWords()`, `readVersion()`, `writeVersion()`, plus chunked/partial-apply hooks). Keep these files free of Firebase and Hive imports so they stay unit-testable.
- **Files**: `lib/logic/migrations/migration.dart`, `lib/logic/migrations/migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_test.dart`
- **Success**: the abstraction compiles, has no `firebase`/`hive` imports, and a fake context can be passed to a test migration.

### Step 2.3: Implement the migration runner

- **Action**: Add `lib/logic/migrations/migration_runner.dart`. Semantics: read the current version (default `0`); select all registered steps whose `fromVersion >= currentVersion`, sorted ascending; run them in order; **persist the version after each successful step** (so a crash resumes at the last completed step); on failure, log the error type, keep the backup, do **not** advance the version, and surface a non-blocking message. Reject any registered step whose `toVersion` exceeds the app's declared current schema version (guards against a downgrade) and skip steps whose `fromVersion` is already satisfied.
- **Files**: `lib/logic/migrations/migration_runner.dart`, `lib/app_constants.dart` (add `appSchemaVersion` constant)
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`
- **Success**: with a fake context and two fake steps, the runner executes them in ascending order, persists version `1` then `2`, skips already-applied steps, stops at the failing step without advancing past it, and re-running the runner is a no-op.

### Step 2.4: Add the two storage contexts

- **Action**: Implement `HiveWordMigrationContext` (reads/writes `wordListJson` and `schemaVersion` in `{username}_WordStorage`) and `FirestoreWordMigrationContext` (reads/writes `users/{uid}/words` and the per-user version marker). Both expose the same interface so a migration's `run()` is written once. Hive writes go through a shadow key first, then swap (see Phase 3, Step 3.2).
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`, `lib/logic/migrations/firestore_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: a Hive-backed context round-trips a word list and a version; the Firestore context maps each document to/from a word map with the doc id preserved.

### Step 2.5: Wire the runner into the app bootstrap

- **Action**: (a) In `main_common.dart::commonInit`, run app-scope migrations (`MainAppStorage` box, key `appSchemaVersion`) after `_initializeStorage()` and before `AppController.initialize()`. (b) In `AppController._init(User)`, run per-user migrations **after** `WordStorage.init(username)` and **before** `WordController.create()` — otherwise `WordController` reads un-migrated data into `_words` and writes it back, re-contaminating the box.
- **Files**: `lib/main_common.dart`, `lib/controllers/app_controller.dart`
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`, `flutter analyze`
- **Success**: with legacy data present, the per-user version marker is written before any word list is read; `flutter analyze` reports 0 issues.

### Step 2.6: Fix the export/import key mismatch

- **Action**: `FirebaseService.migrateWords()` reads `word['hebrew']` while `exportWords()` writes `word['native']`. Read `word['native']` first and fall back to `word['hebrew']` for older exported files. Also normalize the imported `attributes` (legacy string) through the tolerant parser before writing to Firestore.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart`
- **Success**: importing a legacy `flashcards.json` produces words with a non-null `native` value and structured `attributes`.

---

## Phase 3: Concrete Data Migrations + Automatic Backfill

**Goal**: Ship the actual transformers that move existing data to the new shape, locally and in Firestore, automatically and resumably.
**Dependencies**: Phase 2 complete

### Step 3.1: Implement `m001_attributes_to_map`

- **Action**: Add `lib/logic/migrations/m001_attributes_to_map.dart` (`fromVersion: 0`, `toVersion: 1`). For every word, if `attributes` is a legacy `String`, convert it via the canonical mapping and store the result as a map; preserve the original text in `attributesRaw`. If `attributes` is already a map, leave it untouched. The step must be idempotent: re-running it on already-migrated data is a no-op.
- **Files**: `lib/logic/migrations/m001_attributes_to_map.dart`
- **Test**: `flutter test test/logic/migrations/m001_attributes_to_map_test.dart`
- **Success**: a legacy list of three words (one string `attributes`, one map `attributes`, one missing `attributes`) is fully converted; running the step twice produces byte-identical output.

### Step 3.2: Implement the safe local write path

- **Action**: In `HiveWordMigrationContext.writeWords()`, write the new payload to a shadow key `wordListJson_new`, then copy `wordListJson` to `wordListJson_backup`, then set `wordListJson` to the new payload, then delete the shadow key. Never delete the backup during a migration.
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: after a write, `wordListJson` contains the new list, `wordListJson_backup` contains the pre-migration list, and no `wordListJson_new` key remains.

### Step 3.3: Implement the resumable Firestore backfill

- **Action**: Add `lib/logic/migrations/firestore_backfill.dart`. Read all documents in `users/{uid}/words`; for each document whose `attributes` is a legacy string or whose `attributes`/`audioId`/`id` fields are missing, write the normalized document (including a `schemaVersion` field on the document so partial progress is detectable). Commit updates in `WriteBatch` chunks of at most 500 operations. Track a resume cursor (last processed document id) in the per-user Hive box so an app kill mid-backfill resumes rather than restarts. Skip documents already at the target version (idempotent).
- **Files**: `lib/logic/migrations/firestore_backfill.dart`, `lib/logic/migrations/firestore_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`
- **Success**: given 1200 legacy documents, the backfill completes in three batches, each document ends with a map `attributes` and a `schemaVersion` field, and a second run performs zero writes.

### Step 3.4: Detect the orphan top-level `words` collection (report only)

- **Action**: The legacy app stored some words in a top-level `words` collection; `WordController.deleteWord` still targets it while all reads now use `users/{uid}/words`. Because that collection is not user-scoped, ownership is ambiguous. Implement a **detection-only** step that reports how many orphan documents exist and which ones plausibly belong to the signed-in user (by matching `native`/`translation` against the user's own words). Do **not** copy or delete anything; a later release may promote the matches after manual review.
- **Files**: `lib/logic/migrations/firestore_backfill.dart`, `lib/controllers/word_controller.dart` (fix `deleteWord` to target `users/{uid}/words`)
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`
- **Success**: `deleteWord` removes the document from `users/{uid}/words` (verified against a fake Firestore), and the detection step reports orphan counts without mutating data.

### Step 3.5: Run the backfill automatically after sign-in

- **Action**: In `AppController._init(User)`, after the per-user local migration and before `WordController.create()`, launch the Firestore backfill as a **non-blocking background task** (unawaited future with error handling). It must not delay first paint and must not block the UI on network latency. On failure, log the error type, leave the version marker unchanged, and retry on the next sign-in. The user's own newly created words must never be overwritten by a backfill write — the backfill only updates documents it read as legacy.
- **Files**: `lib/controllers/app_controller.dart`
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`, `flutter analyze`
- **Success**: after sign-in with legacy cloud data, the app renders immediately, the backfill completes afterwards, and a subsequent sign-in performs no writes.

### Step 3.6: Add the manual recovery path

- **Action**: Add a "Repair data" action in the settings/drawer area that re-runs the local and remote migrations (forcing the runner to re-evaluate every step). Use it for users whose backfill was interrupted or who want to apply the mapping after manually fixing a legacy string.
- **Files**: `lib/widgets/main_drawer.dart`, `lib/controllers/app_controller.dart`, `lib/logic/migrations/migration_runner.dart`
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`
- **Success**: invoking "Repair data" re-runs the applicable steps and reports the outcome without clearing the user's words.

---

## Phase 4: Contract (later release — only after old clients are dead)

**Goal**: Remove legacy read support and enforce the new shape, once no old app build can write the old format.
**Dependencies**: Phase 3 shipped and stable; telemetry shows the backfill has run for the active user base; old app versions no longer in use.

### Step 4.1: Drop the legacy `String` branch

- **Action**: Remove the `String` handling from `WordAttributes.fromJson` so only a map is accepted. Keep `attributesRaw` as a first-class field (it holds user-meaningful original text) rather than deleting it.
- **Files**: `lib/models/word_attributes.dart`
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: a map is required; a legacy string raises a controlled, logged error rather than silently mis-parsing.

### Step 4.2: Enforce required fields in Firestore writes

- **Action**: Make `attributes` a required map on write in `FirebaseService.addWord`/`updateWord`, and add a server-side (or startup) validation pass that flags documents still missing `attributes`.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart`
- **Success**: every document written by the app contains a map `attributes`; the validation pass lists any documents that do not.

### Step 4.3: Remove the local backup key (last)

- **Action**: Only after the app-scope version marker proves the local migration ran at least once, delete `wordListJson_backup` on a successful startup, and stop writing it.
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: the backup key is absent on a device that has already migrated and backfilled successfully.

---

## Validation Checklist

- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` — all tests pass (existing 12 tests plus the new migration/reader tests)
- [ ] `dart format lib/ test/` produces no changes
- [ ] Legacy Hive fixture still loads: all words present, no records dropped
- [ ] Legacy Firestore fixture still loads: no "Error fetching words" snackbar
- [ ] Kill-and-resume: interrupting the backfill mid-run and restarting completes it without duplicate writes
- [ ] Offline: the app starts and shows local words with no network; the backfill retries on the next sign-in
- [ ] Two users on one device: each user's Hive box has its own independent `schemaVersion`
- [ ] Backup exists after migration: `wordListJson_backup` contains the pre-migration payload
- [ ] Manual "Repair data" run is idempotent (a second run performs no writes)
- [ ] Documentation updated: this plan's phases referenced from `PRD.md` / changelog

---

## Rollback Plan

If issues arise:

1. Stop the release: roll the affected step out of the registry (remove it from the migration list) and rebuild — readers remain tolerant, so old data still loads.
2. Restore local data: the pre-migration payload is preserved in `wordListJson_backup` in `{username}_WordStorage`; copy it back to `wordListJson` on-device.
3. Restore remote data: the backfill only **adds/normalizes** fields and never deletes documents or fields, so a rolled-back build that reads legacy shapes still finds the original `attributes` string in the `attributesRaw` field of the new document. Provide a small one-off script to rewrite `attributes` back to `attributesRaw` for affected documents if required.
4. Re-enable: fix the failing step, re-run the "Repair data" action, and the runner resumes from the recorded version.

## Rollout Order

1. Phase 1 (tolerant readers) — safe to ship immediately; no writes.
2. Phase 2 (framework) + Phase 3 local migration only.
3. Phase 3 Firestore backfill (automatic) — monitored rollout; watch failure counters for the first release.
4. Phase 4 (contract) — only after the backfill has proven stable.

## Telemetry

- Count of local migrations run, per step, with success/failure (no user content).
- Count of Firestore documents migrated, batches written, and backfill resumes.
- Count of records skipped as malformed during parsing.
- Count of legacy strings that could not be confidently mapped (these become `attributesRaw` review candidates).

---

## Success Criteria

The plan is complete when:

- [ ] All requirements are clearly defined and in/out of scope is stated
- [ ] Work is broken into logical phases with explicit dependencies
- [ ] Every step is independently testable (action + files + validation command + success condition)
- [ ] Dependencies on existing code are identified by concrete file/symbol
- [ ] Risks are assessed with mitigation
- [ ] Security requirements are addressed (or explicitly noted as not applicable)

---

**Note for implementing agents**: This document is advisory. It describes *how* to migrate; it does not itself change behavior. Do not implement Phase 4 until explicitly requested.
