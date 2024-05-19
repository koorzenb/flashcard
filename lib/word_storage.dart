import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import 'models/word.dart';

class WordStorage {
  static const _kStorageName = 'WordStorage';
  static WordStorage? _wordBox;

  static Future<void> init() async => await GetStorage.init(_kStorageName);

  static WordStorage get box {
    _wordBox ??= WordStorage._(GetStorage(_kStorageName));
    return _wordBox!;
  }

  final GetStorage _box;
  WordStorage._(this._box);

  Future<void> erase() async => await _box.erase();

  static const String _kWordListJsonKey = 'wordListJson';
  List<Word> get words =>
      Word.listFromJsonList(jsonDecode(_box.read(_kWordListJsonKey) ?? '[{"hebrew":"דָבָר","pronunciation":"de-var","translation":"word","attributes":""}]'));
  set words(List<Word> value) => _box.write(_kWordListJsonKey, jsonEncode(value));
}
