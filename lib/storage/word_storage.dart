import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/word.dart';

class WordStorage {
  static const _kStorageName = 'WordStorage';
  static WordStorage? _wordStorage;
  static late Box _staticBox;

  static Future<void> init() async =>
      _staticBox = await Hive.openBox(_kStorageName);

  static Future<void> close() async => await _staticBox.close();

  static WordStorage get box {
    _wordStorage ??= WordStorage._(_staticBox);
    return _wordStorage!;
  }

  final Box _box;
  WordStorage._(this._box);

  Future<void> erase() async {
    await _box.deleteAll(_box.keys);
  }

  static const String _kWordListJsonKey = 'wordListJson';
  List<Word> get words =>
      Word.listFromJsonList(jsonDecode(_box.get(_kWordListJsonKey) ?? '[]'));
  set words(List<Word> value) => _box.put(_kWordListJsonKey, jsonEncode(value));

  static const String _kDisplayedWelcomeScreen = 'displayedWelcomeScreen';
  bool get displayedWelcomeScreen =>
      _box.get(_kDisplayedWelcomeScreen) ?? false;
  set displayedWelcomeScreen(bool value) =>
      _box.put(_kDisplayedWelcomeScreen, value);
}
