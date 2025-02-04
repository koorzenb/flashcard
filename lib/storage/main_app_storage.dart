import 'package:hive/hive.dart';

class MainAppStorage {
  static const _kStorageName = 'MainAppStorage';
  static MainAppStorage? _wordStorage;
  static late Box _staticBox;

  static Future<void> init() async =>
      _staticBox = await Hive.openBox(_kStorageName);

  static Future<void> close() async => await _staticBox.close();

  static MainAppStorage get box {
    _wordStorage ??= MainAppStorage._(_staticBox);
    return _wordStorage!;
  }

  final Box _box;
  MainAppStorage._(this._box);

  Future<void> erase() async {
    await _box.deleteAll(_box.keys);
  }

  static const String _kDisplayedWelcomeScreen = 'displayedWelcomeScreen';
  bool get displayedWelcomeScreen =>
      _box.get(_kDisplayedWelcomeScreen) ?? false;
  set displayedWelcomeScreen(bool value) =>
      _box.put(_kDisplayedWelcomeScreen, value);
}
