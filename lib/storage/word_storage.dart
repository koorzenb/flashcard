import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/word.dart';

class WordStorage {
  static WordStorage? _wordStorage;
  static Box? _staticBox;
  final Box _box;

  WordStorage._(this._box);

  static Future<void> init(String storageName) async => _staticBox = await Hive.openBox(storageName.isEmpty ? 'WordStorage' : '${storageName}_WordStorage');

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
  List<Word> get words => Word.listFromJsonList(jsonDecode(_box.get(_kWordListJsonKey) ?? '[]'));
  set words(List<Word> value) => _box.put(_kWordListJsonKey, jsonEncode(value));

  static const String _kDisplayedWelcomeScreen = 'displayedWelcomeScreen';
  bool get displayedWelcomeScreen => _box.get(_kDisplayedWelcomeScreen) ?? false;
  set displayedWelcomeScreen(bool value) => _box.put(_kDisplayedWelcomeScreen, value);
}
