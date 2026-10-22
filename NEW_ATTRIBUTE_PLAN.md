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
- **Data loss**: `Word.listFromJsonList` used to swallow all errors and return `[]`, so one malformed record silently discarded the entire vocabulary. **Mitigated in Phase 1** - the parser is now per-record (Steps 1.3 and 1.5). This was the highest-priority fix and is now closed.
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

### Step 1.2: Make `Word.fromJson` null-safe - DONE

- **Action**: Default missing `id`, `native`, `pronunciation`, `translation`, `audioId` to `''` instead of passing `null` into non-nullable `String` parameters. Route `attributes` through the tolerant `WordAttributes.fromJson`. Ignore unknown fields (a newer app build may add fields this build does not know).
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: `Word.fromJson({'native': 'x'})` returns a `Word` with empty strings and blank attributes; the existing round-trip tests in `test/models/word_test.dart` still pass.
- **Implementation notes**: a private `Word._readString(dynamic)` helper normalizes a value to a `String`, falling back to `''` for a missing, `null` or non-string value (so a persisted `42` or `['a']` can no longer blow up the parser). `isNew` is now read as `json['isNew'] == true` rather than `json['isNew'] ?? false`, because the old form would throw on a non-boolean value such as `'yes'`. `attributes` was already routed through the tolerant `WordAttributes.fromJson` in Step 1.1. Unknown fields are ignored by construction - only known keys are read. The parser never throws for any input.
- **Tests added** (in `test/models/word_test.dart`, group `Word.fromJson is null-safe`): missing fields, a fully empty record, explicit `null` values, non-string values, a non-boolean `isNew`, legacy and current `attributes` shapes, unknown fields, and a hostile record that must not throw.

### Step 1.3: Parse words per record instead of all-or-nothing - DONE

- **Action**: Replace the `try { ... } catch (_) { return []; }` body of `Word.listFromJsonList` with a per-record parse that collects valid words and skips malformed ones, keeping the list non-empty if at least one record is valid. Report invalid records via a debug log rather than an exception.
- **Files**: `lib/models/word.dart`
- **Test**: `flutter test test/models/word_test.dart`
- **Success**: a list containing one malformed record and two valid records returns the two valid words instead of `[]`.
- **Implementation notes**: the method now iterates the list record by record. A record that is not a `Map`, or whose parse throws, is counted in a `skipped` counter and skipped; the remaining records are still returned. The count is reported through `dart:developer` under the `WORD_PARSE` log name at level 900 (`INFO`), carrying counts only - never word content. An empty input list returns an empty list without logging; a list in which *every* record is malformed also returns an empty list, which is the only remaining case where the vocabulary can be lost (and it is logged).
- **Tests added** (in `test/models/word_test.dart`, group `Word.listFromJsonList parses record by record`): a malformed record between two valid ones, several malformed records, an all-malformed list, an empty list, a legacy `attributes` string inside a list record, and a list of `Map<String, dynamic>` records.

### Step 1.4: Route Firestore reads through the tolerant parser - DONE

- **Action**: In `FirebaseService.getWords()` and `FirebaseService.exportWords()`, stop calling `WordAttributes.fromJson(doc['attributes'])` directly on the raw document field. Build the word from the document map via the tolerant `Word.fromJson` (mapping `doc.id` -> `id`), so a legacy string `attributes` field or a missing field no longer throws and aborts the whole fetch.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart` (use `fake_cloud_firestore` if it is already a dependency; otherwise assert the parsing helper on representative doc maps in `test/models/word_test.dart`)
- **Success**: fetching a collection whose documents contain string `attributes` returns words instead of raising "Error fetching words".
- **Implementation notes**: `fake_cloud_firestore` is **not** a dependency of this project, so the parsing was extracted into a pure static helper `FirebaseService.wordFromDocument(Map<String, dynamic>? data, String docId)` that can be tested without a live Firestore instance. The helper copies the document data, forces `id` to the document id (the document id is the authoritative identity and a document need not carry an `id` field at all), and delegates every other field to the tolerant `Word.fromJson`. Both `getWords()` and `exportWords()` now use it, and `getWords()` additionally parses each document inside its own `try`/`catch` so a single unparseable document is logged and skipped rather than aborting the whole fetch. The now-unused `word_attributes.dart` import was removed from the service.
- **Tests added** (in `test/services/firebase_service_test.dart`, group `FirebaseService.wordFromDocument`): a current-shaped document, a legacy free-text `attributes` string, a missing `attributes` field, a `null` document body, explicit `null` field values, and a document whose stored `id` is overridden by the document id.

### Step 1.5: Make the local (Hive) read path tolerant - DONE

- **Action**: `WordStorage.words` previously called `jsonDecode(_box.get('wordListJson') ?? '[]')` unguarded, so a corrupt or non-JSON payload threw during app start. Read the raw value defensively: a missing key, a non-`String` value, invalid JSON, or a JSON value that is not a list all yield an empty list instead of an exception. Malformed *records* inside a valid payload continue to be skipped individually by `Word.listFromJsonList`.
- **Files**: `lib/storage/word_storage.dart`
- **Test**: `flutter test test/storage/word_storage_test.dart`
- **Success**: a box containing `{not json` reads as an empty list rather than throwing; a payload with one malformed record still yields the two valid words.
- **Implementation notes**: the getter now checks the raw value's type before decoding and guards the decode with a `try`/`catch` that logs the error *type* only (level 900, `WORD_PARSE`) and returns an empty list. The writer (`set words`) is unchanged. This step was not in the original plan, but it is the same class of defect as Step 1.3 (an all-or-nothing read that can silently discard the whole vocabulary) and it sits directly on the Phase 1 "no data loss" critical path, so it was implemented here rather than deferred.
- **Tests added** (in `test/storage/word_storage_test.dart`, group `WordStorage.words is a tolerant reader`): an empty box, invalid JSON, a JSON object instead of a list, a non-string payload, a payload with one malformed record, a legacy `attributes` string, and a write/read round trip.

---

## Phase 1 Summary - COMPLETE

Phase 1 makes every read path total (never throws, never discards a whole vocabulary for one bad record) and performs **no writes** - it is safe to ship on its own.

| Path | Before | After |
| --- | --- | --- |
| `WordAttributes.fromJson` | threw on an unknown gender | total; unknown -> neutral, legacy string -> mapped (Step 1.1) |
| `Word.fromJson` | threw on missing / null / wrong-typed fields | total; every field defaults safely (Step 1.2) |
| `Word.listFromJsonList` | one bad record -> `[]` (whole vocabulary lost) | per-record parse; bad records skipped and counted (Step 1.3) |
| `FirebaseService.getWords` / `exportWords` | raw `doc['attributes']` could throw and abort the fetch | tolerant per-document parse via `wordFromDocument` (Step 1.4) |
| `WordStorage.words` | corrupt JSON threw during app start | tolerant; returns an empty list and logs the error type (Step 1.5) |

**Validation**: `flutter test` -> 49/49 passing; `flutter analyze --no-pub` -> 0 issues; `dart format` clean.

---

## Phase 2: Versioned Migration Framework (the reusable core)

**Goal**: Introduce an explicit, ordered, incremental, idempotent migration mechanism keyed on a **container-level data version**, shared by local and remote storage, so that each future schema change is registered as one new step instead of a new mechanism.
**Dependencies**: Phase 1 complete (readers must tolerate old data before any migration runs)

### Step 2.1: Define the legacy -> new attribute mapping - PARTIALLY DONE

- **Action**: Add a canonical mapping used by every migration and by the tolerant reader: `masculine|male|m` -> `Gender.male`; `feminine|female|f` -> `Gender.female`; `neutral|n` -> `Gender.neutral`; text containing `plural|pl` -> `isPlural: true`; anything else -> `Gender.neutral`, `isPlural: false`. Always keep the original legacy string in a new `attributesRaw` field on `WordAttributes` so nothing is discarded and the user can correct it later. The mapping already lives in `WordAttributes.fromLegacy()` (Phase 1, Step 1.1) - Step 2.1 only adds the `attributesRaw` field and its round-trip.
- **Files**: `lib/models/word_attributes.dart`, `lib/models/word.dart` (add `attributesRaw` to the model, `toJson()`, and `fromJson()`)
- **Test**: `flutter test test/models/word_attributes_test.dart`
- **Success**: a table-driven test proves each legacy token maps to the expected `Gender`/`isPlural`, that unknown text maps to neutral/singular, and that the raw text survives a `toJson()`/`fromJson()` round trip.
- **Status**: the mapping table and `WordAttributes.fromLegacy()` are **DONE** (Phase 1, Step 1.1). The `attributesRaw` field is **NOT DONE** - it is deliberately deferred, because it changes the persisted shape of `WordAttributes` and therefore belongs with a versioned schema change (it would be introduced by a new registered step `1 -> 2`, not as an unversioned model edit). The tolerant reader currently *discards* an unmappable legacy string; adding `attributesRaw` in a later step restores the original text for the user to correct.

### Step 2.2: Define the data version contract (version tag + payload envelope) - DONE

- **Action**: Establish the two halves of the contract, in `lib/logic/migrations/schema_version.dart`:
  - `AppConstants.currentWordSchemaVersion` - the version this build understands (currently `1`).
  - A **container envelope** for the local payload. The Hive value at `wordListJson` changes from a bare JSON list to an envelope `{"schemaVersion": <int>, "words": [...]}`. The envelope is written in the *same* Hive write as the words, so data and version can never diverge. Add a tolerant container reader that accepts **both** shapes: an envelope (version = its `schemaVersion`) or a bare legacy list (version = `0`). A bare list must still load without error - the container envelope is a Phase 2 write format, not a Phase 2 read requirement.
  - The envelope reader/writer lives in `lib/logic/migrations/word_payload.dart` and is pure (JSON in / JSON out), so it is unit-testable without Hive.
- **Files**: `lib/app_constants.dart`, `lib/logic/migrations/schema_version.dart`, `lib/logic/migrations/word_payload.dart`
- **Test**: `flutter test test/logic/migrations/word_payload_test.dart`
- **Success**: a bare legacy list reads as version `0` with all words intact; an envelope reads at its declared version; writing an envelope round-trips the words and the version; an envelope with an unknown/absent version falls back to `0` rather than throwing.
- **Implementation notes**: `AppConstants.currentWordSchemaVersion = 1` was added. A separate `schema_version.dart` file turned out to be unnecessary and was **not** created - the constant lives on `AppConstants` (as the plan specifies) and the envelope codec lives in `word_payload.dart` (as the plan specifies), so the extra file would have held nothing. `WordPayloadCodec.decode` is total: it accepts an envelope, a legacy bare list (reported as version `0`), and anything unreadable (an empty payload at version `0`). `WordPayloadCodec.encode` always writes the envelope shape.
- **Tests added** (in `test/logic/migrations/word_payload_test.dart`): a legacy bare list, an envelope, an envelope with an invalid version, an envelope without a words list, invalid JSON, a missing/non-string value, a JSON scalar, malformed records inside a list, a legacy `attributes` string, an encode/decode round trip, and a check that the encoded form is an envelope rather than a bare list.

### Step 2.3: Create the migration abstraction - DONE

- **Action**: Add `lib/logic/migrations/migration.dart` defining `abstract class Migration { int get fromVersion; int get toVersion; String get id; String get family; Future<void> run(MigrationContext ctx); }` and `lib/logic/migrations/migration_context.dart` defining the storage-agnostic context interface (`readWords()`, `writeWords()`, `readVersion()`, `writeVersion()`, plus chunked/partial-apply hooks). Keep these files free of Firebase and Hive imports so they stay unit-testable. The `family` label groups related steps for telemetry and the "Repair data" UI; it does **not** affect ordering or versioning (there is one counter).
- **Files**: `lib/logic/migrations/migration.dart`, `lib/logic/migrations/migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_test.dart`
- **Success**: the abstraction compiles, has no `firebase`/`hive` imports, and a fake context can be passed to a test migration.
- **Implementation notes**: `migration.dart` and `migration_context.dart` were created and contain **no** Hive and no Firebase imports, so both stay unit-testable with a fake context. The `MigrationContext` interface is `readWords()`, `writeWords(List<Word>)`, `readVersion()`, `writeVersion(int)` plus an optional `scopeLabel` used to identify the container in log lines. The chunked / partial-apply hooks mentioned in the action text were **not** added: the Firestore backfill (Step 3.4) does its own chunking internally, so a hook on the shared interface would have been unused complexity. `MigrationFailure` and `MigrationLog` (the failure and diagnostics contracts) were added alongside the abstraction.
- **Tests added**: the fake context and fake steps live in `test/logic/migrations/migration_test_helpers.dart` and are exercised by the runner, context and end-to-end test suites.

### Step 2.4: Implement the migration runner (incremental semantics) - DONE

- **Action**: Add `lib/logic/migrations/migration_runner.dart`. Semantics: read the current version (default `0`); select all registered steps whose `toVersion > currentVersion` (i.e. the steps still to be applied), sorted ascending by `fromVersion`; run them in order; **persist the version after each successful step** (so a crash resumes at the last completed step); on failure, log the error type, keep the backup, do **not** advance the version, and surface a non-blocking message. Reject any registered step whose `toVersion` exceeds the app's declared current schema version (guards against a downgrade); a step is never re-run when `fromVersion == currentVersion` and it has already been applied, because the runner skips steps whose `toVersion` is already satisfied by the recorded version. Ordering rule: the data write completes, the **integrity check passes** (Phase 3, Step 3.3), and only then does the version advance.
- **Files**: `lib/logic/migrations/migration_runner.dart`, `lib/app_constants.dart` (add `currentWordSchemaVersion` constant)
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`
- **Success**: with a fake context and two fake steps, the runner executes them in ascending order, persists version `1` then `2`, skips already-applied steps, stops at the failing step without advancing past it, and re-running the runner is a no-op.
- **Implementation notes**: `lib/logic/migrations/migration_runner.dart` was created. The runner reads the current version, selects the steps whose `toVersion` is greater than it (sorted ascending by `fromVersion`), and runs them in order. For each step the order is strictly **write data -> verify -> advance version**: the pre-migration payload is captured, the step runs, the post-migration payload is read back, the integrity check compares the two, and only a valid result advances the version. A step whose `toVersion` exceeds the app's declared schema version is rejected (downgrade guard) and logged as a warning. The runner **never throws**: a failure is captured in the returned `MigrationRunResult`, so a migration failure cannot take the app down at start-up.
- **Abort semantics (resolved)**: the run stops at the **first** failing step. The failing step's own version is **never** advanced. Steps that had *already* succeeded keep their advanced version, because each step's version is persisted the moment that step succeeds - this is what makes a crash resumable at the next outstanding step. Therefore:
  - If the **first** selected step fails, the container is completely untouched (`fromVersion == toVersion`).
  - If a **later** step fails, the container stands at the version of the last successful step (`toVersion == fromVersion + completed steps`).
  - In both cases the run is reported as `aborted` with the failing step's id and a stable failure code, and the **next run resumes at the failing step** rather than redoing completed work.
  - A **rollback** of earlier completed steps was considered and rejected: rolling back would require re-applying the inverse of every completed step, which is not generally possible and would risk losing data. Leaving the completed steps advanced is safe because every step is individually idempotent and the version is only ever advanced *after* the data was written and verified.
- **The runner's target version is injectable** (`MigrationRunner(steps: [...], targetVersion: n)`) and defaults to `AppConstants.currentWordSchemaVersion`. This keeps the app-wide constant honest while letting the tests exercise a multi-step version chain.
- **Tests added** (in `test/logic/migrations/migration_runner_test.dart`): selection by `toVersion`, ascending ordering, skipping applied steps, rejecting a step beyond the target version, running the outstanding steps in order, persisting the version after each step, skipping applied steps on a partial container, a no-op re-run, idempotency, stopping at the first failure, not advancing past the failing step, leaving the container untouched when the first step fails, reporting the stable failure code and step id, wrapping a non-`MigrationFailure` error, resuming at the failing step on the next run, and the two integrity cases (a lost record blocks the version advance; a changed record does not).

### Step 2.5: Add the two storage contexts - DONE

- **Action**: Implement `HiveWordMigrationContext` (reads/writes the `wordListJson` envelope and its `schemaVersion`, using the tolerant envelope reader so a legacy bare-list box reads as version `0`) and `FirestoreWordMigrationContext` (reads/writes `users/{uid}/words` plus a **container-level** version marker stored on the user document `users/{uid}` under a dedicated field). Both expose the same interface so a migration's `run()` is written once. Hive writes go through a shadow key first, then swap (see Phase 3, Step 3.2).
- **Files**: `lib/logic/migrations/hive_word_migration_context.dart`, `lib/logic/migrations/firestore_word_migration_context.dart`
- **Test**: `flutter test test/logic/migrations/migration_context_test.dart`
- **Success**: a Hive-backed context round-trips a word list and a version (including reading a legacy bare-list box as version `0`); the Firestore context maps each document to/from a word map with the doc id preserved and reads/writes the user-document version marker.
- **Implementation notes**: `hive_word_migration_context.dart` and `firestore_word_migration_context.dart` were created, both implementing `MigrationContext`.
  - **Hive**: the words live in `wordListJson` as an envelope; the version is read from that envelope and falls back to a standalone `wordSchemaVersion` marker. Writes are **backup-first**: the current payload is copied to `wordListJson_backup`, the new payload is staged in the shadow key `wordListJson_new`, and only then is it swapped into the live key (the shadow key is deleted afterwards, so no `wordListJson_new` is left behind). `writeVersion` patches the version **into the existing payload**, copying the raw word array verbatim - it never re-encodes from the parsed `Word` list, because that would silently drop any record the tolerant parser skipped. A legacy bare list is upgraded to an envelope by `writeVersion` without losing a record.
  - **Firestore**: the words live in `users/{uid}/words` and the container version is stored on the user document `users/{uid}` under `wordSchemaVersion`. Writes are **non-deleting**: only documents that already exist are updated (a word without an id cannot be matched to a document and is skipped rather than creating one), and the body never contains the `id`, because the document id is the authoritative identity and duplicating it in the body would let the two drift apart. `wordFromDocument` and `wordToDocument` are static helpers, so the mapping is unit-testable without a live Firestore instance.
  - The Firestore context could not be covered by an automated test: `fake_cloud_firestore` is **not** a dependency of this project and adding a dependency was out of scope for this step. Its mapping helpers are pure and were verified through the shared tolerant parser, but the Firestore *I/O* path is untested.
- **Tests added** (in `test/logic/migrations/migration_context_test.dart`): reading the version from a legacy bare list, from an envelope and from an empty box; reading the words from a bare list, from an envelope and from a missing payload; a word-list round trip; the backup holding the pre-migration payload verbatim; no shadow key left behind; the written payload being an envelope; advancing the version inside the envelope; keeping the words while advancing the version; and upgrading a legacy bare list to an envelope.

### Step 2.6: Wire the runner into the app bootstrap - DONE (local scope only)

- **Action**: (a) In `main_common.dart::commonInit`, run app-scope migrations (`MainAppStorage` box) after `_initializeStorage()` and before `AppController.initialize()`. (b) In `AppController._init(User)`, run per-user migrations **after** `WordStorage.init(username)` and **before** `WordController.create()` - otherwise `WordController` reads un-migrated data into `_words` and writes it back, re-contaminating the box.
- **Files**: `lib/main_common.dart`, `lib/controllers/app_controller.dart`
- **Test**: `flutter test test/logic/migrations/migration_runner_test.dart`, `flutter analyze`
- **Success**: with legacy data present, the per-user version marker is written before any word list is read; `flutter analyze` reports 0 issues.
- **Implementation notes**: part (b) is **DONE**: `AppController._init(User)` now calls `WordMigrationBootstrap.run()` **after** `WordStorage.init(username)` and **before** `WordController.create()`, so the controller can never read un-migrated data into `_words` and write it back. `WordMigrationBootstrap` (in `lib/logic/migrations/word_migration_bootstrap.dart`) opens a `HiveWordMigrationContext` over `WordStorage.box.rawBox` and runs `MigrationRunner(steps: MigrationRegistry.steps)`. A failed migration is **not** fatal - the run is reported as aborted and the app continues with the data as it is, because the tolerant readers guarantee the data is still usable and the next launch retries. Part (a) - app-scope migrations over the `MainAppStorage` box - was **not** implemented: there is no app-scoped schema to migrate yet (the `MainAppStorage` box holds only `displayedWelcomeScreen`), so a runner call there would be a no-op. It should be added when the first app-scoped schema change appears. The Firestore (cloud) side of the bootstrap is Phase 3 and was not wired here.
- **Supporting changes**: `WordStorage.rawBox` was exposed so the migration layer can read and write the raw payload (re-encoding from the parsed `Word` list would lose any record the tolerant parser skipped).

### Step 2.7: Fix the export/import key mismatch

- **Action**: `FirebaseService.migrateWords()` reads `word['hebrew']` while `exportWords()` writes `word['native']`. Read `word['native']` first and fall back to `word['hebrew']` for older exported files. Also normalize the imported `attributes` (legacy string) through the tolerant parser before writing to Firestore, and stamp the written document with the current container version.
- **Files**: `lib/services/firebase_service.dart`
- **Test**: `flutter test test/services/firebase_service_test.dart`
- **Success**: importing a legacy `flashcards.json` produces words with a non-null `native` value and structured `attributes`.

---

---

## Phase 2 Summary - COMPLETE (framework core)

The reusable migration framework is in place. A new schema change is added as a **new step**, never as a new mechanism:

1. Create a `Migration` subclass in `lib/logic/migrations/`.
2. Register it in `MigrationRegistry.steps`.
3. Bump `AppConstants.currentWordSchemaVersion`.

| File | Role |
| --- | --- |
| `migration.dart` | the `Migration` abstraction (`fromVersion`, `toVersion`, `id`, `family`, `run`) |
| `migration_context.dart` | the storage-agnostic `MigrationContext` (no Hive, no Firebase imports) |
| `migration_runner.dart` | the runner: selection, ordering, integrity gate, version advancement, abort |
| `migration_registry.dart` | the ordered registry of known steps |
| `attributes_migration.dart` | the first real step (`0 -> 1`, `attributes` to a structured value) |
| `migration_failure.dart` | `MigrationFailure` + stable `MigrationFailureCode` wire names |
| `migration_log.dart` | privacy-safe structured diagnostics (`dart:developer`, tag `MIGRATION`) |
| `migration_run_result.dart` | `MigrationRunResult` + `MigrationRunStatus` (`success` / `aborted`) |
| `migration_integrity_check.dart` | the non-destructive pre/post payload comparison |
| `word_payload.dart` | the pure envelope reader/writer (`WordPayloadCodec`) |
| `hive_word_migration_context.dart` | the local container (backup-first writes) |
| `firestore_word_migration_context.dart` | the cloud container (non-deleting writes) |
| `word_migration_bootstrap.dart` | the app-bootstrap entry point for the local container |

**Ordering rule enforced by the runner**: `write data -> verify integrity -> advance version`. A container can therefore never claim a version its data does not have.

**Privacy**: the logs carry counts, version numbers, step ids and failure codes only - never word text, translations, pronunciations, audio URLs, e-mail addresses or user ids.

**Validation**: `flutter test` -> 116/116 passing; `flutter analyze --no-pub` -> 0 issues; `dart format` clean.

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

### Step 3.3: Implement the migration integrity check (old data vs. restructured data) - DONE (core), PARTIAL (per-storage entry points)

- **Action**: Add `lib/logic/migrations/migration_integrity_check.dart`, a storage-agnostic verifier that compares a container's **pre-migration payload** against its **post-migration payload** and reports a structured `IntegrityReport` (no writes, no data movement - read and compare only). The report contains: `beforeCount` / `afterCount`, `missing` (word ids present before but absent after - the data-loss signal), `added` (ids present after but not before), `changed` (ids present in both whose content differs), and `unchanged` count. The comparison is done on the **stable identity key** `id` (falling back to `native` + `translation` for legacy records with no `id`), never on list position, because a migration may legitimately reorder the list. Content equality is checked on the fields that survive the migration - `id`, `native`, `pronunciation`, `translation`, `audioId` - plus a **semantic** attributes comparison: the migrated `WordAttributes` must be *equivalent to* the legacy string parsed by `WordAttributes.fromLegacy()`, i.e. `gender` and `isPlural` match, and `attributesRaw` must equal the original legacy string verbatim (this proves the original text was preserved, not re-derived). The check must be **non-destructive**: it never repairs and never deletes; it only reports. Two entry points: a local one that compares `wordListJson_backup` against `wordListJson` after a Hive migration, and a cloud one that compares the set of documents captured before the backfill against the documents after it (the backfill must keep the same document ids - it may only normalize field shapes, never add or remove documents).
- **Files**: `lib/logic/migrations/migration_integrity_check.dart`, `lib/logic/migrations/hive_word_migration_context.dart` (invoke the local check after `writeWords()`), `lib/logic/migrations/firestore_backfill.dart` (invoke the cloud check after the last batch)
- **Test**: `flutter test test/logic/migrations/migration_integrity_check_test.dart`
- **Success**: a fixture of 50 legacy words migrates with `beforeCount == afterCount == 50`, `missing`/`added` empty, and every migrated word's `attributesRaw` equal to its original legacy string. Deliberately dropping one word during a migration makes the check report exactly that word as `missing` and fails the test.
- **Implementation notes**: the **core** verifier is **DONE** in `lib/logic/migrations/migration_integrity_check.dart`. It compares the pre- and post-migration payloads on the stable identity key `id` (falling back to `native` + `translation` for legacy records with no id), never on list position. Content equality covers `id`, `native`, `pronunciation`, `translation` and `audioId`, plus a **semantic** attributes comparison (`gender` and `isPlural` must match, so a legacy string and its mapping are equivalent). The report exposes `beforeCount`, `afterCount`, `missing`, `added`, `changed` and `unchanged`, and a content-free `summary` safe to log. `isValid` is `missing.isEmpty`: a **missing** record is always a defect, whereas an **added** or **changed** record is not - a migration may legitimately change a record. The check is non-destructive: it never repairs and never deletes.
  - The **runner** now invokes the check automatically between the data write and the version advancement, so a lost record blocks the version advance. This is the *primary* entry point and it is generic (it works for both storages).
  - The two **per-storage entry points** named in the action text were **not** implemented: comparing `wordListJson_backup` against `wordListJson` after a Hive migration, and comparing the captured document set before and after a Firestore backfill. The generic runner-level check already covers the Hive case (it compares the payload before and after the step, which is the same information the backup comparison would use). The Firestore case belongs to the Phase 3 backfill, which was not implemented.
  - The `attributesRaw` clause of the success criterion does not apply yet, because `attributesRaw` is not implemented (see Step 2.1). The semantic comparison currently proves that the legacy string was mapped to the equivalent structured value, but it cannot yet prove the original text was preserved verbatim.
- **Tests added** (in `test/logic/migrations/migration_integrity_check_test.dart`): an identical 50-word payload, exactly one dropped record reported as missing, an added record, a changed record (which does not fail the check), matching by id rather than by position, the `native` + `translation` fallback for records without an id, a legacy `attributes` string compared against its mapping, a changed attributes mapping, an empty payload reported as losing everything, an empty before-payload reported as adding everything, and the content-free summary. The runner's use of the check is covered in `migration_runner_test.dart` (a dropped record blocks the version advance; a changed record does not).

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
