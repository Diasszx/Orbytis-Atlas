import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
