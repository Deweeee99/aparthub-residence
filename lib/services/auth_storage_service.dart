import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_debug_logger.dart';

class AuthStorageService {
  AuthStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'resident_auth_token';
  static const _residentJsonKey = 'resident_auth_resident_json';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    appDebugLog('AuthStorage', 'Saving token ${maskToken(token)}');
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    appDebugLog('AuthStorage', 'Loaded token ${maskToken(token)}');
    return token;
  }

  Future<void> clearToken() async {
    appDebugLog('AuthStorage', 'Clearing token');
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveResidentJson(String json) async {
    appDebugLog('AuthStorage', 'Saving resident JSON cache');
    await _storage.write(key: _residentJsonKey, value: json);
  }

  Future<String?> getResidentJson() async {
    final residentJson = await _storage.read(key: _residentJsonKey);
    appDebugLog(
      'AuthStorage',
      residentJson == null
          ? 'No cached resident JSON'
          : 'Loaded cached resident JSON',
    );
    return residentJson;
  }

  Future<void> clearSession() async {
    appDebugLog('AuthStorage', 'Clearing resident session');
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _residentJsonKey),
    ]);
  }
}
