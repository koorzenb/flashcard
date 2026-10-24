# PLAN — `migrate_attributes` review & follow-ups

Living plan captured during the code review of the `migrate_attributes → main`
pull request (schema migration: word `attributes` from a free-text `String` to
a structured `WordAttributes` value, surfaced through a new
`WordAttributesInput` widget).

## Scope reviewed this pass
- `lib/widgets/word_attributes_input.dart` (new) — gender + singular/plural `SegmentedButton` input.
- `lib/screens/word_details_screen.dart` — wires the new widget; drops the old string `_attributesTextController`.
- `lib/models/{gender,word_attributes,word}.dart` — new model + tolerant JSON parsing.
- `lib/logic/migrations/*` — backfill / migration / integrity engine.
- `lib/logic/word_logic.dart`, `lib/widgets/flash_card.dart` — feature consumers.
- `test/models/word_attributes_test.dart`, `test/logic/word_logic_test.dart` — model/logic coverage.

## ✅ Done in this pass (fixes applied per the review)
- **#1** Named the leading-icon-size fallback and form spacing as static consts
  in `WordAttributesInput` (replaces magic numbers `24.0`, `16`, `8`).
- **#2** Extracted the two `SegmentedButton`s into `_genderButton()` /
  `_numberButton()` so `build()` stays well under the 50-line guideline.
- **#3** Added a `reason:` to every `expect()` in `word_attributes_test.dart`
  (project testing standard).
- **#5** Hoisted the `'Plural'` and `' · '` literals in `FlashCardWidgetState`
  to named constants.

## ⏭️ Out of scope (deferred per request, not implemented)
- **#4** Widget test for `WordAttributesInput` — intentionally skipped this pass.

## ✅ Verification
- `flutter analyze` → no issues.
- `flutter test` → all tests pass (incl. `word_attributes_test.dart`).

---

## 📉 Technical Debt (architectural issues found)

All items below are **pre-existing** — not introduced by this PR — but were
flagged while reviewing files in (or adjacent to) the feature. Line numbers
refer to the post-PR tree.

### 1. Logic layer reaches into the UI  (Architecture — Medium)
- `lib/logic/word_logic.dart:8` imports `../widgets/flashcard_snackbar.dart`.
- `lib/logic/word_logic.dart:52` calls `FlashcardSnackbar.showSnackBar(...)`
  from `WordLogic.getWord()`.
- **Problem:** business logic depends on a presentation widget, breaking
  testability and the project's separation-of-concerns guideline.
- **Fix:** have `getWord()` return an outcome/result (e.g. an enum or result
  object) and let the *screen* decide how to surface "all words read". If a
  callback is preferred, define a small `SnackBarSink` interface in the logic
  layer and inject it.

### 2. `print()` used for logging  (Logging — Medium)
- `lib/logic/word_logic.dart:56` — `print('Word = ${word.translation}');`
- `lib/widgets/flash_card.dart:62` — `debugPrint('disabled');`
- **Problem:** bypasses the project's logging convention; output is
  uncategorizable and stripped in release.
- **Fix:** route through a logger abstraction with a named tag and level.

### 3. Global mutable singleton state  (Architecture — Medium)
- `lib/logic/word_logic.dart:11-12,41-48` — static `_unReadWords` / `_instance`
  managed by manual `create()` / `dispose()`.
- **Problem:** lifecycle is not tied to the widget tree; relies on correct
  manual disposal and is hard to test in isolation.
- **Fix:** manage via GetX `WordController` (already used elsewhere via
  `WordController.instance`) or pass state in rather than holding it on a
  singleton.

### 4. Over-long `build()` in the details screen  (Code quality — Low)
- `lib/screens/word_details_screen.dart:54-213` — ~160-line `build()` mixing
  form layout, validation, audio record/playback, and attribute input.
- **Fix:** split into focused sub-widgets (`_NativeField`,
  `_PronunciationField`, `_TranslationField`, `_SaveButton`) and extract the
  audio Row.

### 5. Translation validator checks the wrong field  (Correctness — Low)
- `lib/screens/word_details_screen.dart:183-187` — the **Translation** field's
  `validator` errors on `_nativeTextController.text`, not on the translation
  value.
- **Fix:** validate `_translationTextController.text` and message appropriately.
  Confirm intended product behavior first (is cross-field validation intended?).

### 6. Inline magic numbers / strings across the UI  (Code quality — Low)
- `lib/widgets/flash_card.dart` (`8.0`, `48`, `26`, `1`) and the details form
  (`8.0`, `24`).
- **Fix:** introduce a shared `lib/constants/` spacing module and centralize
  attribute wording on the model so `WordAttributesInput` and
  `FlashCardWidget` share labels.

### 7. `FlashCardWidget` `build()` length & debug logging  (Code quality — Low)
- `lib/widgets/flash_card.dart:42-140` — ~100-line `build()`.
- Extract the progress/opacity animation subtree and the attribute display; see
  also #2 (the `debugPrint`).
