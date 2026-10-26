## [0.33.1] - 2026-10-26
  
### Refactor
  
- removed unused files

## 0.33.0

### Feat

- add niqqud reference card and integrate with word details screen

## [0.32.0] - 2026-10-26
  
### Feature
  
- update branding from 'Kards' to 'FlashCard' in main files

## 0.31.1

### Fix

- update branding from "Kards" to "FlashCard" in documentation and spell check

## [0.31.0] - 2026-10-26
  
### Feature
  
- add niqqud reference card and integrate with word details screen

## 0.30.0

### Other

- 0.27.0

## 0.29.0

### Fix(android)

- bump Kotlin 2.1.0 + AGP 8.7.0 to resolve firebase-auth 23.x metadata mismatch

## 0.28.0

### Other

- fix: pin flutter_sound_platform_interface to ^9.28.0 for CI (Dart 3.6.0)

CI (flutter-ci.yml) installs Dart 3.6.0 via a pinned dart-lang/setup-dart action that overrides Flutter 3.27.1's bundled Dart. ^9.30.0 requires Dart SDK >=3.7.2, so pub resolution failed. ^9.28.0 is the highest version line compatible with flutter_sound ^9.23.1 under Dart 3.6.0; on local (Dart 3.10.7) it still resolves to 9.30.0, so no local behavior change.

## 0.27.0

### Other

- refactor: hoist constants, extract button builders, add test reasons

Address code-review findings #1,#2,#3,#5: replace magic numbers with named consts and extract _genderButton()/_numberButton() in WordAttributesInput (build stays under 50 lines); add reason: to every expect() in word_attributes_test; hoist 'Plural'/'·' literals to consts in FlashCardWidget; add PLAN.md with tech-debt notes. (#4 widget tests deferred per request.)

## 0.26.0

### Refactor

- Improve layout and padding in WordAttributesInput widget

## 0.25.0

### Other

- feat: Implement Firestore backfill and migration logic

- Added FirestoreBackfill class for shape-driven normalization of legacy documents in the user's cloud word collection.
- Integrated Firestore backfill into AppController to run as a background task on user sign-in.
- Updated WordController to reference user-specific word collections in Firestore.
- Introduced repairData method in AppController to re-run migrations and backfill on user request.
- Enhanced migration logging to include step IDs and force re-run capability.
- Added tests for FirestoreBackfill and MigrationRunner to ensure correct functionality and edge case handling.
- Removed deprecated Firestore backfill service from the codebase.

## [0.24.0] - 2026-10-24
  
### Refactor
  
- Improve layout and padding in WordAttributesInput widget

## 0.23.0

### Enh

- Implement Firestore backfill and migration logic


## [0.22.0] - 2026-10-23
  
### Enhancement
  
- Implement Firestore backfill and migration logic

- Added FirestoreBackfill class for shape-driven normalization of legacy documents in the user's cloud word collection.
- Integrated Firestore backfill into AppController to run as a background task on user sign-in.
- Updated WordController to reference user-specific word collections in Firestore.
- Introduced repairData method in AppController to re-run migrations and backfill on user request.
- Enhanced migration logging to include step IDs and force re-run capability.
- Added tests for FirestoreBackfill and MigrationRunner to ensure correct functionality and edge case handling.
- Removed deprecated Firestore backfill service from the codebase.

## 0.22.1

### Refactor

- complete Phase 1 of word attributes migration with legacy support and tests

## 0.21.0

### Feat

- Created a tolerant reader pending new word migration

## [0.20.2] - 2026-10-23
  
### Refactor
  
- complete Phase 1 of word attributes migration with legacy support and tests

## 0.20.1

### Refactor

- enhance WordAttributes with legacy support and improved JSON handling

## [0.20.0] - 2026-10-22
  
### Feature
  
- Created a tolerant reader pending new word migration

## 0.19.0

### Docs

- add migration plan for word attribute schema from String to WordAttributes

## [0.18.1] - 2026-10-22
  
### Refactor
  
- enhance WordAttributes with legacy support and improved JSON handling

## 0.18.0

### Other

- Refactor word attributes handling and improve code formatting

## 0.17.0

### Other

- Refactor word attributes handling and improve code formatting

## [0.15.0] - 2026-10-22
  
### Enhancement
  
Refactor word attributes handling and improve code formatting

- Introduced a new `Gender` enum and `WordAttributes` model to manage grammatical attributes of words.
- Updated `Word` model to use `WordAttributes` instead of a string for attributes.
- Refactored `SoundController`, `WritingController`, and `WordLogic` to accommodate changes in word attributes.
- Enhanced UI components to include `WordAttributesInput` for selecting gender and plurality.
- Improved code formatting for better readability across multiple files.
- Removed deprecated `pubspec.template.yaml` file.
- Added tests to ensure proper functionality of word logic with new attributes.

## [0.14.0]

### Refactor

- update Flutter SDK path and streamline build scripts

## [0.13.0] - 2026-10-16
  
### Refactor
  
- update Flutter SDK path and streamline build scripts

### Docs

- add Product Requirements Document (PRD) for Kards app


## 0.12.0

### Docs

- add Product Requirements Document (PRD) for Kards app

## 0.11.0

### Feat

- improved word list display

## 0.10.0

### Feat

- update version to 0.7.0 and enhance changelog

## 0.9.0

### Feat

- update version to 0.7.0 and enhance changelog

## 0.8.0

### Enh

- included searching on native words

## 0.7.0

### Enh

- included searching on native words

## 0.6.0

### Other

- Optimised authentication process to work with new storage structure

## 0.5.0

### Other

- Minor changes

Co-authored-by: Copilot <copilot@github.com>

## 0.4.2

- Optimised authentication process to work with new storage structure

## 0.4.1

### Refactor

- Refactored saving of audioFile

## 0.4.0

### Chore

- Implemented auto semver update

# CHANGELOG

## 0.0.0 (2023-07-01)

- Initial release

## 0.0.1 (2023-07-02)

-

## 0.0.2 (2024-07-04)

### Bugfix

- Fixed updating of words

## 0.1.0 (2024-07-09)

### Feature

- Renamed Project
- Changed main font
- Updated Readme
- Changed app logo

## 0.1.1 (2024-07-11)

### Feature

- Added version identifier

### Fix

- Closing Drawer immediately on tap

## 0.1.2 (2024-07-24)

### Fix

- Fixed updating of words

## 0.1.3 (2024-08-25)

### Feature

- Added Welcome Screen

## 0.1.4

### Fix

- Fixed Storage url

## 0.1.5

### Feature

- Added search functionality in WordList Screen
- Added circularProgressIndicator to show time left to guess word

## 0.1.6

### Fix

- Fix splash screen to have background match splash image background

## 0.1.7

### Fix

- Fixed environments

## 0.2.0

### SDK

- Upgraded Flutter and upgraded all dependencies

### Feature

- Separated user data by means of authentication

### Chore

- Update build script to no longer need .env files
- Added Github Action CI/CD

# 0.3.0

## Feature

- Added a mode for recognizing words from audio
- Separated user data by means of authentication
