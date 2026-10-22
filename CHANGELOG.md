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
