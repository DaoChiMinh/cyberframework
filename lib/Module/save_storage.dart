import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  AppStorage._();

  static final FlutterSecureStorage _storage =
      FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked,
          
        ),
      );

  static Future<void> set(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String> get(String key) async {
    return await _storage.read(key: key)??"";
  }

  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
