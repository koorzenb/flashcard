import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive/hive.dart';

import '../models/word.dart';

class WordStorage {
  static WordStorage? _wordStorage;
  static Box? _staticBox;
  final Box _box;

  WordStorage._(this._box);

  /// The underlying Hive box.
  ///
  /// Exposed so the migration layer can read and write the word payload and
  /// the container's schema version directly, without going through the
  /// `Word` model (which would lose any record the tolerant parser skipped).
  Box get rawBox => _box;

  static Future<void> init(String storageName) async =>
      _staticBox = await Hive.openBox(
        storageName.isEmpty ? 'WordStorage' : '${storageName}_WordStorage',
      );

  static Future<void> close() async => await _staticBox?.close();

  static bool get isInitialized => _staticBox?.isOpen ?? false;
  static WordStorage get box {
    _wordStorage ??= WordStorage._(_staticBox!);
    return _wordStorage!;
  }

  Future<void> erase() async {
    await _box.deleteAll(_box.keys);
  }

  static void disposeBox() {
    _wordStorage?.erase();
    _wordStorage?._box.close();
    _wordStorage = null;
  }

  static const String _kWordListJsonKey = 'wordListJson';

  /// Reads the persisted word list.
  ///
  /// The read is deliberately tolerant: a missing key, a non-string value or
  /// a payload that is not valid JSON yields an empty list instead of
  /// throwing, so a corrupt box can never prevent the app from starting.
  /// Malformed *records* inside a valid payload are skipped individually by
  /// [Word.listFromJsonList] rather than discarding the whole list.
  List<Word> get words {
    final dynamic raw = _box.get(_kWordListJsonKey);
    if (raw is! String || raw.isEmpty) {
      return <Word>[];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Word>[];
      }
      return Word.listFromJsonList(decoded);
    } catch (e) {
      // Counts only - never the word content.
      developer.log(
        'wordStorage.read.invalidPayload error=${e.runtimeType}',
        name: 'WORD_PARSE',
        level: 900,
      );
      return <Word>[];
    }
  }

  set words(List<Word> value) => _box.put(_kWordListJsonKey, jsonEncode(value));

  static const String _kDisplayedWelcomeScreen = 'displayedWelcomeScreen';
  bool get displayedWelcomeScreen =>
      _box.get(_kDisplayedWelcomeScreen) ?? false;
  set displayedWelcomeScreen(bool value) =>
      _box.put(_kDisplayedWelcomeScreen, value);
}
