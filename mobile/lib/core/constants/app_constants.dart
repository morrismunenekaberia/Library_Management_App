export 'api_config.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Key used to store the JWT auth token securely in FlutterSecureStorage.
  static const String tokenStorageKey = 'jwt_token';

  /// Key used to store the cached user session in FlutterSecureStorage.
  static const String userStorageKey = 'cached_user';

  /// Application display name.
  static const String appTitle = 'Library Management';
}
