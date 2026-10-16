# PRD — Kards (FlashCard App)

> Purpose: single source of truth for humans and AI agents to understand this project quickly when starting a new session. Keep it concise, factual, and up to date with the code.

---

## 1. Overview

**Kards** (package name `flashcard`) is a mobile Flutter app for practicing foreign-language vocabulary with flashcards. The primary language pair is **Hebrew → English** (the app bundles the *Noto Sans Hebrew* font and models grammatical gender), but the app is language-agnostic — any native language can be entered per word.

**Goal:** strengthen language learning through three practice modes:

1. **Reading** — see the native word, recall the translation, then reveal it (flashcard with timed reveal).
2. **Writing (dictation)** — hear a recorded audio clip of the native word and type it; answer checked against the stored word (2 attempts, score tracking).
3. **Audio recognition** — recognize words from audio (mode introduced in v0.3.0; overlaps with Writing).

Users maintain their own vocabulary list (add / edit / delete / search), record audio per word, and their data is isolated per Firebase-authenticated user.

- **App display name:** Kards
- **Version:** `0.10.0+1002` (see `pubspec.yaml`)
- **Repo:** https://github.com/koorzenb/flashcard.git
- **Platform:** Android-first (APK builds via `build-prod-apk.bat`); `android/` folder present, no iOS folder.

---

## 2. Tech Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (FVM-managed; CI uses **3.27.1**) | Dart SDK `>=3.6.0 <4.0.0` |
| State management | **GetX** (`get ^4.6.6`) | `GetxController` + `Get.find/put`; navigation via `Get.to` |
| Local storage | **Hive** (`hive_flutter`) | JSON-serialized word list; per-user box name |
| Backend | **Firebase**: Auth, Cloud Firestore, Firebase Storage | Email auth via `firebase_ui_auth` |
| Audio | **flutter_sound** | Record/play AAC ADTS, 16 kHz / 16 kbps (low quality, small files) |
| Mic permission | `permission_handler` | Requested in `SoundController._init()` |
| Tests | `flutter_test` | Pure logic units under `test/logic/` |
| CI | GitHub Actions (`.github/workflows/flutter-ci.yml`) | `flutter pub get` → `flutter analyze` → `flutter test` |
| Git hooks | husky + `.husky/` | Node-based pre-commit tooling |
| Versioning | manual + `CHANGELOG.md` | Auto-semver tooling referenced in changelog |

**Entry points:**
- `lib/main_prod.dart` — active production entry (Firebase prod options, `ServerEnvironment.prod`).
- `lib/main_dev.dart` — dev entry, **fully commented out**.
- `lib/main_common.dart` — shared init: Hive → Firebase → `AppController.initialize()`; defines `MyApp` (`GetMaterialApp`, theme from `lib/styles/themes.dart`).

There is **no `lib/main.dart`**. Build/run with `-t lib/main_prod.dart`.

---

## 3. Architecture / Code Map

Follow the existing layering when adding code. All paths relative to `lib/`.

```
lib/
├── main_prod.dart / main_dev.dart / main_common.dart   # entry points & app bootstrap
├── app_config.dart        # InheritedWidget: appDisplayName, appInternalId (dev/prod distinction)
├── app_constants.dart     # audio codec + file extension constants
├── app_settings.dart      # clearAppData() — sign-out cleanup (disposes Hive box, controllers, routes)
├── models/                # plain data classes
│   ├── word.dart          # Word: id, native, pronunciation, translation, attributes, audioId, isNew; JSON (de)serialization
│   ├── word_attributes.dart  # WordAttributes: Gender gender + bool isPlural (WordAttributes.blank())
│   ├── gender.dart        # Gender enum (masculine / feminine / neutral)
│   ├── server_environment.dart
│   └── constants.dart
├── logic/                 # pure/testable business logic (no Firebase)
│   ├── word_logic.dart    # WordLogic singleton: random "unread word" queue, addWord, reset, initializeWords
│   ├── writing_logic.dart # WritingLogic.checkWord: answer checking, attempts (2), scoring → CheckWordResult
│   └── check_word_result.dart
├── controllers/           # GetX controllers (UI-facing state)
│   ├── app_controller.dart       # AppController singleton: auth listener, per-user init (WordStorage, WordController, WritingController, SoundController)
│   ├── word_controller.dart      # word CRUD (Firestore + Hive cache), search/filter, current flashcard word
│   ├── writing_controller.dart   # dictation flow; only words WITH audio are used
│   ├── sound_controller.dart     # record/play/upload local AAC clips; files at documentsDir/audio-clips/{id}.aac
│   └── ...
├── services/              # Firebase access
│   ├── firebase_service.dart     # WORD CRUD: users/{uid}/words Firestore subcollection; import/export/migrate helpers
│   ├── firestore_service.dart    # AUDIO upload/delete: Firebase Storage audio/{userId}/{audioId}.aac (misnamed — not Firestore)
│   └── flashcard_auth_service.dart # GetX auth wrapper; SignInScreen (firebase_ui_auth, email provider), signOut
├── storage/               # Hive wrappers (static box singletons)
│   ├── main_app_storage.dart     # global box 'MainAppStorage' (displayedWelcomeScreen flag)
│   ├── auth_storage.dart         # userId, username persistence
│   └── word_storage.dart         # per-user box '{username}_WordStorage'; 'wordListJson' key holds full JSON list
├── screens/               # home_screen, reading_screen, writing_screen, word_list_screen, word_details_screen
├── widgets/               # flash_card.dart (animated reveal card), word_list.dart, main_drawer.dart, record_audio_page.dart, etc.
└── styles/themes.dart
```

### Key flows

- **Bootstrap:** `commonInit` → Hive init → Firebase init → `AppController.initialize()` (subscribes to `authStateChanges()`; if a user exists, `_init(user)` runs immediately).
- **Auth gate:** `AppController.instance.home` returns `SignInScreen` when signed out, `HomeScreen` when signed in. On sign-in, username is extracted from email (`extractUsername`) and persisted in `AuthStorage`; `WordStorage.init(username)` opens the per-user Hive box; `WordController` and `WritingController` are `Get.put`-created.
- **Word data flow:** Firestore `users/{uid}/words` is the source of truth; Hive caches the full list as JSON for offline. `WordLogic.initializeWords()` returns cached words if present, otherwise fetches from Firestore and caches. On sign-out, `clearAppData()` disposes Hive box + controllers and routes back to sign-in.
- **Flashcard selection:** `WordLogic` keeps a static `_unReadWords` list; `getWord()` picks a random word and removes it; when exhausted it resets and shows a snackbar ("All words have been read. Starting over.").
- **Audio:** user long-presses the mic button in `WordDetailsScreen` while typing a word → recorded to a temp file keyed by the native text → on save, file is renamed to the Firestore document ID and uploaded to Firebase Storage. `WritingController` filters to words where `audioId.isNotEmpty`.

### Data model

**Word** (Firestore doc in `users/{uid}/words`, mirrored in Hive JSON):
```json
{
  "id": "<firestore doc id>",
  "native": "hebrew word",
  "pronunciation": "romanization",
  "translation": "english translation",
  "attributes": { "gender": "masculine|feminine|neutral", "isPlural": false },
  "audioId": "<word id used as audio filename; empty = no audio>",
  "isNew": false
}
```

**Storage layout:**
- Firebase Storage: `audio/{userId}/{audioId}.aac`
- Device: `{appDocumentsDirectory}/audio-clips/{audioId}.aac`
- Hive: `MainAppStorage` (global), auth box (`AuthStorage`), `{username}_WordStorage` with key `wordListJson`.

---

## 4. Features (current)

- **Authentication:** email/password sign-in and sign-up via `firebase_ui_auth`; auth state persisted by Firebase; per-user data isolation (Firestore subcollection + per-user Hive box + per-user Storage folder).
- **Home / Reading (flashcards):** tap card → new random word → 4 s `CircularProgressIndicator` → pronunciation + translation + attributes fade in over 2 s. Long-press card → edit word.
- **Word list:** searchable list (searches both native and translation fields); tap to view/edit details.
- **Add / edit word:** form with native word, pronunciation, English translation, attributes; optional hold-to-record audio; delete from app bar.
- **Writing / dictation:** plays the word's audio; user types the native word; exact-match check; 2 attempts (correct answer revealed after 0 attempts); score increments only on first-attempt correct; next word after a 2 s delay.
- **Welcome message** shown once on first launch (flag in `MainAppStorage`).
- **Sign out:** clears local data, returns to sign-in.
- **Version display** on home screen (`VersionCodeText`).

---

## 5. Non-Goals / Out of Scope (currently)

- iOS builds (no `ios/` folder).
- Multi-language decks or deck management — one flat vocabulary list per user.
- Offline-write queue — local Hive is a read cache refreshed by explicit save operations.
- Social/sharing features.

---

## 6. Conventions & Rules for Agents

- **State management:** use GetX following existing patterns (`GetxController`, `GetBuilder`, `Get.put/find`). Do not introduce Riverpod/Bloc/provider.
- **Persistence:** Hive only for local caching; wrap boxes in a `storage/` class with static `init`/`box` accessors — do not use Hive directly in widgets.
- **Firebase access:** words go through `FirebaseService`, audio files through `FirestoreService`. Avoid calling `FirebaseFirestore` directly from screens/controllers (note: `WordController.deleteWord` currently violates this — legacy top-level `words` collection; see §7).
- **Logic separation:** keep decision logic in `lib/logic/` as static/pure classes so it stays unit-testable; add tests in `test/logic/`.
- **Navigation:** `Get.to(() => Screen())`.
- **Linting:** `analysis_options.yaml` with `flutter_lints ^5.0.0`; CI fails on `flutter analyze` errors and test failures.
- **Changelog:** add an entry to `CHANGELOG.md` for user-facing changes.
- **Naming caution:** the product is branded "Kards" but package/repo are `flashcard`; `FirestoreService` handles audio, `FirebaseService` handles words. Preserve existing names unless doing a dedicated refactor.

### Build & test commands

```bash
# Dependencies (FVM-managed Flutter; see .fvmrc / .vscode/settings.json)
fvm flutter pub get

# Analyze & test (same as CI)
fvm flutter analyze
fvm flutter test

# Run app (prod entry — there is no main.dart)
fvm flutter run -t lib/main_prod.dart

# Release APK (Windows; requires SED per README; outputs release/%BUILD_VERSION%/*.apk)
build-prod-apk.bat
```

## 8. Roadmap Ideas (from TODOs in code — not committed commitments)

- **Weighted / spaced-repetition scheduling:** `WordLogic.reset()` contains a sketched design — assign each word a weight 1–5 mapped to reveal time (2–10 s); tapping before time expires decreases weight, failing to tap increases it. This would replace the uniform-random unread queue.
- **Audio download & offline sync:** implement `downloadAudioFile` so clips recorded on another device can be fetched from Storage.
- **Word-list audio indicator:** show an audio icon on list items that have recordings.
- **Reversed practice direction:** toggle showing translation → native (currently always native-first).
- **Richer attributes UI:** checkboxes for gender/plural with color-coded display.

---

## 9. Testing

- `test/logic/word_logic_test.dart` — WordLogic queue behavior (uses `@visibleForTesting` hooks like `WordLogic.removeInstance()`, `unreadWords`).
- `test/logic/writing_logic_test.dart` — WritingLogic.checkWord scoring/attempts.
- `test/test_helper.dart` — shared helpers.
- Convention: new logic classes should be pure enough to unit-test without Firebase or widgets. UI/controller tests are currently absent.

---

## 10. Release Process

1. Update `version:` in `pubspec.yaml` and add a `CHANGELOG.md` entry.
2. Run `build-prod-apk.bat` (Windows; copies pubspec, builds obfuscated release APK with `--split-debug-info=./debug-info`, moves artifact to `release/{version}/flashcard-{version}.apk`).
3. APKs are committed under `release/` per version.
4. CI (`flutter-ci.yml`) runs analyze + test on push/PR to `main`.
