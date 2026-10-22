# Plan: Versioned Word Data Schema (`attributes`: String -> `WordAttributes`)

> **Revision 2** - generalized from a one-off attribute migration to a reusable, container-level data versioning framework. Every future schema change (attributes today, media tomorrow) becomes an incremental step in the same registry. The attribute migration is simply the first step (`0 -> 1`).

## Context

- **Goal**: Evolve persisted word data to new shapes without data loss, using a **versioned, incremental, idempotent** migration framework that covers local (Hive) and remote (Firestore) storage. Each data version bump applies only the steps between the stored version and the app's current version - never "all rules, every time".
- **User Story**: As a user with existing words, I want my words to survive schema changes and keep working, so that a new release (today: gender/plural attributes; tomorrow: something else) never wipes my vocabulary.
- **Data Versioning Model** (the core decision of this revision):
  - **One monotonic integer per container.** A container is either the local word list (`{username}_WordStorage`) or the user's cloud word collection (`users/{uid}/words`). Each container carries a single integer version, e.g. `wordSchemaVersion: 3`.
  - **The version tags the data, not the app.** The app declares the version it understands (`AppConstants.currentWordSchemaVersion`); each container records the version its data is actually at. The delta between the two is the work to do.
  - **Version lives with the data, atomically.** The local version is embedded *inside* the `wordListJson` payload (not a sibling Hive key) so a crash can never leave data and version out of sync. The cloud version is stored once per user (see Phase 2, Step 2.5).
  - **One counter, not per-domain counters.** A future `media` migration is step `2 -> 3` on the same counter. It carries a `family` label (`attributes`, `media`, ...) purely for grouping, telemetry and the "Repair data" UI - not for independent versioning. This keeps "current schema version" a single meaningful number and keeps the runner trivial. Reconsider per-domain counters only when two migrations are genuinely independent *and* one of them is expensive enough to be worth skipping.
  - **Tolerant readers are unconditional and independent of versioning.** A version tag tells you *when* to migrate; it never removes the need to read old shapes, because an older app build can write legacy-shaped data at any time.
- **Dependencies**:
  - `lib/models/word.dart` - `Word`, `Word.toJson()`, `Word.fromJson()`, `Word.listFromJsonList()`
  - `lib/models/word_attributes.dart` - `WordAttributes`, `WordAttributes.fromJson()`, `WordAttributes.fromLegacy()` (added in Phase 1, Step 1.1)
  - `lib/models/gender.dart` - `Gender` enum (`male`, `female`, `neutral`)
  - `lib/storage/word_storage.dart` - per-user Hive box `{username}_WordStorage`, key `wordListJson`
  - `lib/storage/main_app_storage.dart` - global Hive box `MainAppStorage`
  - `lib/services/firebase_service.dart` - `getWords()`, `addWord()`, `updateWord()`, `exportWords()`, `migrateWords()`
  - `lib/controllers/app_controller.dart` - `_init(User)` bootstrap, `WordStorage.init(username)` then `WordController.create()`
  - `lib/controllers/word_controller.dart` - `WordController._()` reads `WordStorage.box.words` then falls back to `FirebaseService.getWords()`
  - `lib/logic/word_logic.dart` - `WordLogic.initializeWords()` (local-first, caches remote words into Hive)
  - `lib/main_common.dart` - `commonInit()` -> `_initializeStorage()` -> `_initializeFirebase()` -> `AppController.initialize()`
  - `lib/app_constants.dart` - app-level constants (target for `currentWordSchemaVersion`)
  - `PRD.md` - product context for the attribute feature

## Scope

**In Scope:**

- Tolerant (backward-compatible) readers for every deserialization path, able to read *any* version <= current.
- A container-level data version tag stored alongside the data, per store, atomically with the data.
- A versioned migration framework in `lib/logic/migrations/` with an ordered registry of steps (`fromVersion`/`toVersion`/`family`) and a runner that applies **only** the outstanding steps.
- A generic step-registration API so future migrations (media, tags, ...) are added as new steps, not new subsystems.
- Local (Hive) and remote (Firestore) migration paths sharing one canonical transformation logic via a `MigrationContext` abstraction.
- Automatic Firestore backfill running in the background after sign-in, normalized to the container's current version.
- Legacy string -> structured attributes mapping with the original raw string preserved.
- Fixture-based tests for every migration step, every reader path, and the runner's incremental semantics.
- An **integrity check** that compares the pre-migration and post-migration payloads of every container (local and cloud) and reports missing / added / changed records, blocking the version advance on a mismatch (Phase 3, Step 3.3).
- Telemetry of how many containers are still at each version (this is the real signal for "are old clients dead?").

**Out of Scope:**

- Changing the `Word`/`WordAttributes` public API beyond additive, non-breaking changes.
- Per-document version tags in Firestore (superseded by the container-level decision above) and per-document `schemaVersion` fields.
- Deleting legacy data, removing backups, or dropping legacy read support (that is Phase 4).
- Migrating the orphan top-level `words` collection (ownership is ambiguous - see Phase 3, Step 3.5).
- Import/export file format redesign (`flashcards.json` key mismatch is fixed in Phase 2, Step 2.7).
- UI/UX redesign of the attribute input widgets.
- Any behavior change visible to the user beyond the attribute values themselves.
- A server-side/Admin-SDK consumer of the word data (confirmed out of scope - the data is only read by the app).

## Security Requirements

- **Credentials**: none introduced. Existing `FirebaseOptions` in `lib/firebase_options_prod.dart` and Firebase Auth are used unchanged. Migration code must not log or copy auth tokens.
- **API Scopes**: Firestore access stays within the already-used `users/{uid}/words` subcollection plus the `users/{uid}` user document that holds the container version marker. The backfill must not read or write any other user's data and must not enumerate the top-level `words` collection.
- **Data Privacy**: word data is user content. Backups stay on-device (Hive box) and in the user's own Firestore subcollection. Migration logs must contain counts, version numbers and error types only - never word text, translations, or audio URLs.

## Risk Assessment

- **Technical**: Hive writes are per-key atomic but a full-list replace is not - a crash mid-write can leave `wordListJson` missing. Mitigated by writing to a shadow key first, then swapping (Phase 3, Step 3.2). Firestore batches are limited to 500 operations - the backfill must chunk.
- **Integration**: an old app build reading data written by the new build will fail on the map shape. Mitigated by the Expand/Contract ordering: new builds accept both shapes, and the legacy read path is only removed in Phase 4 after old clients are dead.
- **Data loss**: `Word.listFromJsonList` currently swallows all errors and returns `[]`, so one malformed record silently discards the entire vocabulary. Mitigated in Phase 1 (per-record parsing) - this is the highest-priority fix.
- **Silent partial loss**: a migration could drop, duplicate or corrupt records without throwing. Mitigated by the **integrity check** (Phase 3, Step 3.3) which compares the pre- and post-migration payloads record-by-record on a stable identity key and blocks the version advance on a mismatch.
- **Version/ordering**: advancing a version before the corresponding data is durably written causes permanent loss. Mitigated by the ordering rule *write data -> verify -> then advance version*, enforced by the runner (Phase 2, Step 2.4).
- **Stale version markers**: a container-level version can be "correct" while individual cloud documents are still legacy (an old build wrote them after the marker advanced). Mitigated by making the backfill a **shape-driven** scan rather than a version-driven one (Phase 3, Step 3.4), and by keeping readers tolerant.
- **Mitigation**: every phase ships with a backup-first write path, non-deleting semantics, a recorded schema version, and a fixture test proving the old format still reads.

---

## Phase 1: Tolerant Readers (no data loss, no version bump)

**Goal**: Make every read path accept legacy `attributes` strings, missing `attributes`, and malformed records - so no data is lost even before any migration runs. Tolerant readers are a permanent, unconditional capability, not a temporary migration aid.
**Dependencies**: `lib/models/word_attributes.dart`, `lib/models/word.dart`, `lib/services/firebase_service.dart`

### Step 1.1: Make `WordAttributes.fromJson` total (never throws) - DONE

- **Action**: Change the factory to accept `dynamic` and normalize three shapes: (a) `Map` with `gender`/`isPlural` (current format), (b) `String` (legacy free text), (c) `null`/missing -> `WordAttributes.blank()`. For the map case, replace the throwing `Gender.values.firstWhere(...)` with a safe lookup that falls back to `Gender.neutral` for unknown/missing gender. Add a static helper `WordAttributes.fromLegacy(String raw)` that maps legacy text to a structured value (mapping table defined in Step 2.1).
- **Files**: `lib/models/word_attributes.dart`
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: `WordAttributes.fromJson('masculine')`, `WordAttributes.fromJson(null)`, `WordAttributes.fromJson({'gender': 'bogus'})` and `WordAttributes.fromJson({'gender': 'male', 'isPlural': true})` all return a valid object and none throw.

### Step 1.2: Make `Word.fromJson` null-safe

- **Action**: Default missing `id`, `native`, `pronunciation`, `translation`, `audioId` to `''` instead of passing `null` into non-nullable `String` parameters. Route `attributes` through the tolerant `WordAttributes.fromJson`. Ignore unknown fields (a newer app build may add fields this build does not know).
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: `Word.fromJson({'native': 'x'})` returns a `Word` with empty strings and blank attributes; the existing round-trip tests in `test/models/word_test.dart` still pass.

### Step 1.3: Parse words per record instead of all-or-nothing

- **Action**: Replace the `try { ... } catch (_) { return []; }` body of `Word.listFromJsonList` with a per-record parse that collects valid words and skips malformed ones, keeping the list non-empty if at least one record is valid. Report invalid records via a debug log rather than an exception.
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: a list containing one malformed record and two valid records returns the two valid words instead of `[]`.

### Step 1.4: Route Firestore reads through the tolerant parser

- **Action**: In `FirebaseService.getWords()` and `FirebaseService.exportWords()`, stop calling `WordAttributes.fromJson(doc['attributes'])` directly on the raw document field. Build the word from the document map via the tolerant `Word.fromJson` (mapping `doc.id` -> `id`), so a legacy string `attributes` field or a missing field no longer throws and aborts the whole fetch.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart` (use `fake_cloud_firestore` if it is already a dependency; otherwise assert the parsing helper on representative doc maps in `test/models/word_test.dart`)
- **Success**: fetching a collection whose documents contain string `attributes` returns words instead of raising "Error fetching words".

---

## Phase 2: Versioned Migration Framework (the reusable core)

**Goal**: Introduce an explicit, ordered, incremental, idempotent migration mechanism keyed on a **container-level data version**, shared by local and remote storage, so that each future schema change is registered as one new step instead of a new mechanism.
**Dependencies**: Phase 1 complete (readers must tolerate old data before any migration runs)

### Step 2.1: Define the legacy -> new attribute mapping

- **Action**: Add a canonical mapping used by every migration and by the tolerant reader: `masculine|male|m` -> `Gender.male`; `feminine|female|f` -> `Gender.female`; `neutral|n` -> `Gender.neutral`; text containing `plural|pl` -> `isPlural: true`; anything else -> `Gender.neutral`, `isPlural: false`. Always keep the original legacy string in a new `attributesRaw` field on `WordAttributes` so nothing is discarded and the user can correct it later. The mapping already lives in `WordAttributes.fromLegacy()` (Phase 1, Step 1.1) - Step 2.1 only adds the `attributesRaw` field and its round-trip.
- **Files**: `lib/models/word_attributes.dart`, `lib/models/word.dart` (add `attributesRaw` to the model, `toJson()`, and `fromJson()`)
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: a table-driven test proves each legacy token maps to the expected `Gender`/`isPlural`, that unknown text maps to neutral/singular, and that the raw text survives a `toJson()`/`fromJson()` round trip.

### Step 2.2: Define the data version contract (version tag + payload envelope)

- **Action**: Establish the two halves of the contract, in `lib/logic/migrations/schema_version.dart`:
  - `AppConstants.currentWordSchemaVersion` - the version this build understands (currently `1`).
  - A **container envelope** for the local payload. The Hive value at `wordListJson` changes from a bare JSON list to an envelope `{"schemaVersion": <int>, "words": [...]}`. The envelope is written in the *same* Hive write as the words, so data and version can never diverge. Add a tolerant container reader that accepts **both** shapes: an envelope (version = its `schemaVersion`) or a bare legacy list (version = `0`). A bare list must still load without error - the container envelope is a Phase 2 write format, not a Phase 2 read requirement.
  - The envelope reader/writer lives in `lib/logic/migrations/word_payload.dart` and is pure (JSON in / JSON out), so it is unit-testable without Hive.
- **Files**: `lib/app_constants.dart`, `lib/logic/migrations/schema_version.dart`, `lib/logic/migrations/word_payload.dart`
- **Test**: `flutter test test/logic/migrations/word_payload_test.dart`
- **Success**: a bare legacy list reads as version `0` with all words intact; an envelope reads as its declared version; writing an envelope round-trips the words and the version; an envelope with an unknown/absent version falls back to `0` rather than throwing.

### Step 2.3: Create the migration abstraction

- **Action**: Add `lib/logic/migrations/migration.dart` defining `abstract class Migration { int get fromVersion; int get toVersion; String get id; String get family; Future<void> run(MigrationContext ctx); }` and `lib/logic/migrations/migration_context.dart` defining the storage-agnostic context interface (`readWords()`, `writeWords()`, `readVersion()`, `writeVersion()`, plus chunked/partial-apply hooks). Keep these files free of Firebase and Hive imports so they stay unit-testable. The `family` label groups related steps for telemetry and the "Repair data" UI; it does **not** affect ordering or versioning (there is one counter).
- **Files**: `lib/logic/migrations/migration.dart`, `lib/logic/migrations/migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_test.dart`
- **Success**: the abstraction compiles, has no `firebase`/`hive` imports, and a fake context can be passed to a test migration.

### Step 2.4: Implement the migration runner (incremental semantics)

- **Action**: Add `lib/logic/migrations/migration_runner.dart`. Semantics: read the current version (default `0`); select all registered steps whose `toVersion > currentVersion` (i.e. the steps still to be applied), sorted ascending by `fromVersion`; run them in order; **persist the version after each successful step** (so a crash resumes at the last completed step); on failure, log the error type, keep the backup, do **not** advance the version, and surface a non-blocking message. Reject any registered step whose `toVersion` exceeds the app's declared current schema version (guards against a downgrade); a step is never re-run when `fromVersion == currentVersion` and it has already been applied, because the runner skips steps whose `toVersion` is already satisfied by the recorded version. Ordering rule: the data write completes, the **integrity check passes** (Phase 3, Step 3.3), and only then does the version advance.
- **Files**: `lib/logic/migrations/migration_runner.dart`, `lib/app_constants.dart` (add `currentWordSchemaVersion` constant)
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`
- **Success**: with a fake context and two fake steps, the runner executes them in ascending order, persists version `1` then `2`, skips already-applied steps, stops at the failing step without advancing past it, and re-running the runner is a no-op.

### Step 2.5: Add the two storage contexts

- **Action**: Implement `HiveWordMigrationContext` (reads/writes the `wordListJson` envelope and its `schemaVersion`, using the tolerant envelope reader so a legacy bare-list box reads as version `0`) and `FirestoreWordMigrationContext` (reads/writes `users/{uid}/words` plus a **container-level** version marker stored on the user document `users/{uid}` under a dedicated field). Both expose the same interface so a migration's `run()` is written once. Hive writes go through a shadow key first, then swap (see Phase 3, Step 3.2).
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`, `lib/logic/migrations/firestore_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: a Hive-backed context round-trips a word list and a version (including reading a legacy bare-list box as version `0`); the Firestore context maps each document to/from a word map with the doc id preserved and reads/writes the user-document version marker.

### Step 2.6: Wire the runner into the app bootstrap

- **Action**: (a) In `main_common.dart::commonInit`, run app-scope migrations (`MainAppStorage` box) after `_initializeStorage()` and before `AppController.initialize()`. (b) In `AppController._init(User)`, run per-user migrations **after** `WordStorage.init(username)` and **before** `WordController.create()` - otherwise `WordController` reads un-migrated data into `_words` and writes it back, re-contaminating the box.
- **Files**: `lib/main_common.dart`, `lib/controllers/app_controller.dart`
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`, `flutter analyze`
- **Success**: with legacy data present, the per-user version marker is written before any word list is read; `flutter analyze` reports 0 issues.

### Step 2.7: Fix the export/import key mismatch

- **Action**: `FirebaseService.migrateWords()` reads `word['hebrew']` while `exportWords()` writes `word['native']`. Read `word['native']` first and fall back to `word['hebrew']` for older exported files. Also normalize the imported `attributes` (legacy string) through the tolerant parser before writing to Firestore, and stamp the written document with the current container version.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart`
- **Success**: importing a legacy `flashcards.json` produces words with a non-null `native` value and structured `attributes`.

---

## Phase 3: Concrete Data Migrations + Automatic Backfill

**Goal**: Ship the actual transformers that move existing data to the new shape, locally and in Firestore, automatically, incrementally and resumably. This phase proves the framework with the attribute step (`0 -> 1`); every later schema change repeats the same shape with a new step.
**Dependencies**: Phase 2 complete

### Step 3.1: Implement `m001_attributes_to_map` (family `attributes`)

- **Action**: Add `lib/logic/migrations/m001_attributes_to_map.dart` (`fromVersion: 0`, `toVersion: 1`, `family: 'attributes'`). For every word, if `attributes` is a legacy `String`, convert it via the canonical mapping and store the result as a map; preserve the original text in `attributesRaw`. If `attributes` is already a map, leave it untouched. The step must be idempotent: re-running it on already-migrated data is a no-op.
- **Files**: `lib/logic/migrations/m001_attributes_to_map.dart`
- **Test**: `flutter test test/logic/migrations/m001_attributes_to_map_test.dart`
- **Success**: a legacy list of three words (one string `attributes`, one map `attributes`, one missing `attributes`) is fully converted; running the step twice produces byte-identical output.

### Step 3.2: Implement the safe local write path

- **Action**: In `HiveWordMigrationContext.writeWords()`, write the new payload (envelope + words) to a shadow key `wordListJson_new`, then copy `wordListJson` to `wordListJson_backup`, then set `wordListJson` to the new payload, then delete the shadow key. Never delete the backup during a migration. Note that this is a **sequence of individual Hive writes, not one atomic operation** - the atomicity guarantee comes from the *ordering* (shadow written and verified before the live key is replaced) plus the retained backup, so that a crash at any point leaves either the old payload or the new payload intact, never a partial list. After the swap, run the local integrity check (Step 3.3) comparing `wordListJson_backup` against `wordListJson`.
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: after a write, `wordListJson` contains the new envelope (with the new version), `wordListJson_backup` contains the pre-migration payload, and no `wordListJson_new` key remains.

### Step 3.3: Implement the migration integrity check (old data vs. restructured data)

- **Action**: Add `lib/logic/migrations/migration_integrity_check.dart`, a storage-agnostic verifier that compares a container's **pre-migration payload** against its **post-migration payload** and reports a structured `IntegrityReport` (no writes, no data movement - read and compare only). The report contains: `beforeCount` / `afterCount`, `missing` (word ids present before but absent after - the data-loss signal), `added` (ids present after but not before), `changed` (ids present in both whose content differs), and `unchanged` count. The comparison is done on the **stable identity key** `id` (falling back to `native` + `translation` for legacy records with no `id`), never on list position, because a migration may legitimately reorder the list. Content equality is checked on the fields that survive the migration - `id`, `native`, `pronunciation`, `translation`, `audioId` - plus a **semantic** attributes comparison: the migrated `WordAttributes` must be *equivalent to* the legacy string parsed by `WordAttributes.fromLegacy()`, i.e. `gender` and `isPlural` match, and `attributesRaw` must equal the original legacy string verbatim (this proves the original text was preserved, not re-derived). The check must be **non-destructive**: it never repairs and never deletes; it only reports. Two entry points: a local one that compares `wordListJson_backup` against `wordListJson` after a Hive migration, and a cloud one that compares the set of documents captured before the backfill against the documents after it (the backfill must keep the same document ids - it may only normalize field shapes, never add or remove documents).
- **Files**: `lib/logic/migrations/migration_integrity_check.dart`, `lib/logic/migrations/hive_word_migration_context.dart` (invoke the local check after `writeWords()`), `lib/logic/migrations/firestore_backfill.dart` (invoke the cloud check after the last batch)
- **Test**: `flutter test test/logic/migrations/migration_integrity_check_test.dart`
- **Success**: a fixture of 50 legacy words migrates with `beforeCount == afterCount == 50`, `missing`/`added` empty, and every migrated word's `attributesRaw` equal to its original legacy string. Deliberately dropping one word during a migration makes the check report exactly that word as `missing` and fails the test.

### Step 3.4: Implement the resumable Firestore backfill (shape-driven, not version-driven)

- **Action**: Add `lib/logic/migrations/firestore_backfill.dart`. Read all documents in `users/{uid}/words`; for each document whose `attributes` is a legacy string or whose `attributes`/`audioId`/`id` fields are missing, write the normalized document. The scan is **shape-driven** (inspect the actual documents) rather than trusting the container version marker, because an old app build may have written legacy documents after the marker advanced. Commit updates in `WriteBatch` chunks of at most 500 operations. Skip documents that are already in the target shape (idempotent). Partial progress is detectable because a partially-normalized collection is simply "some documents still legacy" - the next run continues exactly where the last stopped, so no separate resume cursor is required. Advance the container version marker only after the last batch commits successfully **and** the cloud integrity check (Step 3.3) confirms the document id set is unchanged.
- **Files**: `lib/logic/migrations/firestore_backfill.dart`, `lib/logic/migrations/firestore_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`
- **Success**: given 1200 legacy documents, the backfill completes in three batches, each document ends with a map `attributes`, and a second run performs zero writes.

### Step 3.5: Detect the orphan top-level `words` collection (report only)

- **Action**: The legacy app stored some words in a top-level `words` collection; `WordController.deleteWord` still targets it while all reads now use `users/{uid}/words`. Because that collection is not user-scoped, ownership is ambiguous. Implement a **detection-only** step that reports how many orphan documents exist and which ones plausibly belong to the signed-in user (by matching `native`/`translation` against the user's own words). Do **not** copy or delete anything; a later release may promote the matches after manual review.
- **Files**: `lib/logic/migrations/firestore_backfill.dart`, `lib/controllers/word_controller.dart` (fix `deleteWord` to target `users/{uid}/words`)
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`
- **Success**: `deleteWord` removes the document from `users/{uid}/words` (verified against a fake Firestore), and the detection step reports orphan counts without mutating data.

### Step 3.6: Run the backfill automatically after sign-in

- **Action**: In `AppController._init(User)`, after the per-user local migration and before `WordController.create()`, launch the Firestore backfill as a **non-blocking background task** (unawaited future with error handling). It must not delay first paint and must not block the UI on network latency. On failure, log the error type, leave the version marker unchanged, and retry on the next sign-in. The user's own newly created words must never be overwritten by a backfill write - the backfill only updates documents it read as legacy.
- **Files**: `lib/controllers/app_controller.dart`
- **Test**: `flutter test test/logic/migrations/firestore_backfill_test.dart`, `flutter analyze`
- **Success**: after sign-in with legacy cloud data, the app renders immediately, the backfill completes afterwards, and a subsequent sign-in performs no writes.

### Step 3.7: Add the manual recovery path ("Repair data")

- **Action**: Add a "Repair data" action in the settings/drawer area that re-runs the local and remote migrations (forcing the runner to re-evaluate every step). Use it for users whose backfill was interrupted or who want to apply the mapping after manually fixing a legacy string. The action reports the version before and after, and the steps it re-ran (grouped by `family`), without clearing the user's words.
- **Files**: `lib/widgets/main_drawer.dart`, `lib/controllers/app_controller.dart`, `lib/logic/migrations/migration_runner.dart`
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`
- **Success**: invoking "Repair data" re-runs the applicable steps and reports the outcome without clearing the user's words.

---

## Phase 4: Contract (later release - only after old clients are dead)

**Goal**: Remove legacy read support and enforce the new shape, once no old app build can write the old format. The gate is telemetry on the container version distribution (see the Telemetry section), not a date.
**Dependencies**: Phase 3 shipped and stable; telemetry shows the backfill has run for the active user base; old app versions no longer in use.

### Step 4.1: Drop the legacy `String` branch

- **Action**: Remove the `String` handling from `WordAttributes.fromJson` so only a map is accepted. Keep `attributesRaw` as a first-class field (it holds user-meaningful original text) rather than deleting it.
- **Files**: `lib/models/word_attributes.dart`
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: a map is required; a legacy string raises a controlled, logged error rather than silently mis-parsing.

### Step 4.2: Enforce required fields in Firestore writes

- **Action**: Make `attributes` a required map on write in `FirebaseService.addWord`/`updateWord`, and add a startup validation pass that flags documents still missing `attributes` (a shape check, independent of the version marker).
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart`
- **Success**: every document written by the app contains a map `attributes`; the validation pass lists any documents that do not.

### Step 4.3: Remove the local backup key (last)

- **Action**: Only after the container version proves the local migration ran at least once (i.e. the stored version is at or above the version that introduced the envelope), delete `wordListJson_backup` on a successful startup, and stop writing it.
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: the backup key is absent on a device that has already migrated and backfilled successfully.

---

## Validation Checklist

- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` - all tests pass (existing 22 tests plus the new migration/reader tests)
- [ ] `dart format lib/ test/` produces no changes
- [ ] Legacy Hive fixture still loads: all words present, no records dropped
- [ ] Legacy Firestore fixture still loads: no "Error fetching words" snackbar
- [ ] **Integrity check**: for every fixture, `beforeCount == afterCount`, `missing` and `added` are empty, and every migrated word's `attributesRaw` equals the original legacy string
- [ ] **Integrity check detects loss**: a deliberately dropped word is reported as `missing` and the version is not advanced
- [ ] Integrity check is non-destructive: running it twice changes nothing
- [ ] Incremental runner: a container at version `1` runs only the `1 -> 2` step, not the whole registry
- [ ] Crash-safe ordering: killing the app mid-migration leaves the version at the last completed step, and re-running completes it
- [ ] Kill-and-resume: interrupting the backfill mid-run and restarting completes it without duplicate writes
- [ ] Offline: the app starts and shows local words with no network; the backfill retries on the next sign-in
- [ ] Two users on one device: each user's Hive box has its own independent version and envelope
- [ ] Backup exists after migration: `wordListJson_backup` contains the pre-migration payload
- [ ] Manual "Repair data" run is idempotent (a second run performs no writes)
- [ ] Documentation updated: this plan's phases referenced from `PRD.md` / changelog

---

## Rollback Plan

If issues arise:

1. Stop the release: roll the affected step out of the registry (remove it from the migration list) and rebuild - readers remain tolerant, so old data still loads.
2. Restore local data: the pre-migration payload is preserved in `wordListJson_backup` in `{username}_WordStorage`; copy it back to `wordListJson` on-device (the backup holds the pre-envelope bare-list payload, which the tolerant reader still accepts).
3. Restore remote data: the backfill only **adds/normalizes** fields and never deletes documents or fields, so a rolled-back build that reads legacy shapes still finds the original `attributes` string in the `attributesRaw` field of the new document. Provide a small one-off script to rewrite `attributes` back to `attributesRaw` for affected documents if required.
4. Re-enable: fix the failing step, re-run the "Repair data" action, and the runner resumes from the recorded version.

## Rollout Order

1. Phase 1 (tolerant readers) - safe to ship immediately; no writes.
2. Phase 2 (framework) + Phase 3 local migration only.
3. Phase 3 Firestore backfill (automatic) - monitored rollout; watch failure counters for the first release.
4. Phase 4 (contract) - only after the version telemetry shows the backfill has proven stable.

## Telemetry

- Container version distribution (local and cloud): how many containers are at each version. This is the signal for "are old clients dead?" and gates Phase 4.
- Count of migrations run, per step and per `family`, with success/failure (no user content).
- Count of Firestore documents normalized, batches written, and backfill resumes.
- Count of records skipped as malformed during parsing.
- **Integrity report per migration**: counts of `missing` / `added` / `changed` / `unchanged` (never word content), so a silent loss shows up as a non-zero `missing` counter.
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

**Note for implementing agents**: This document is advisory. It describes *how* to migrate; it does not itself change behavior. Do not implement Phase 4 until explicitly requested. When adding a new schema change, add a new step to the registry (`lib/logic/migrations/`), bump `AppConstants.currentWordSchemaVersion`, and extend the envelope read/write - do not build a second migration mechanism.
