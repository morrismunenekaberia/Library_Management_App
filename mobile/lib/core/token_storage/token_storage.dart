import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Secure token storage service backed by [FlutterSecureStorage].
/// Encrypts and persists JWT auth tokens on Android keystore.
class TokenStorage {
  final FlutterSecureStorage _storage;

  const TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Persists the authentication token securely.
  Future<void> saveToken(String token) async {
    await _storage.write(
      key: AppConstants.tokenStorageKey,
      value: token,
    );
  }

  /// Retrieves the saved token, or null if none exists.
  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenStorageKey);
  }

  /// Clears the stored token on logout.
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenStorageKey);
  }

  /// Checks if a valid token is present.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
