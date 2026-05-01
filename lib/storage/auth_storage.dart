import 'package:hive/hive.dart';

class AuthStorage {
  static const _kStorageName = 'AuthStorage';
  static AuthStorage? _instance;
  static late Box _staticBox;

  static Future<void> init() async =>
      _staticBox = await Hive.openBox(_kStorageName);

  static Future<void> close() async => await _staticBox.close();

  static AuthStorage get box {
    _instance ??= AuthStorage._(_staticBox);
    return _instance!;
  }

  final Box _box;
  AuthStorage._(this._box);

  Future<void> clear() async {
    await _box.clear();
  }

  static const String _kUsername = 'username';
  String get username => _box.get(_kUsername) ?? '';
  set username(String value) => _box.put(_kUsername, value);

  static const String _kUserId = 'userId';
  String get userId => _box.get(_kUserId) ?? '';
  set userId(String value) => _box.put(_kUserId, value);
}
