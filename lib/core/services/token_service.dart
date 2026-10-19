import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  TokenService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String accessTokenKey = "access_token";
  static bool _signedOut = false;

  static Future<void> saveToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
    _signedOut = false;
  }

  static Future<String?> getToken() async {
    if (_signedOut) return null;
    return await _storage.read(key: accessTokenKey);
  }

  static Future<void> removeToken() async {
    // Do not reuse a credential in this process even if platform erasure fails.
    _signedOut = true;
    await _storage.delete(key: accessTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    return (await getToken()) != null;
  }
}
