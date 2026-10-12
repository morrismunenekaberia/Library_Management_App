/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Base URL for the Library Management Backend API.
  /// 10.0.2.2 points to host machine loopback inside Android Emulator.
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  /// Key used to store the JWT auth token securely in FlutterSecureStorage.
  static const String tokenStorageKey = 'jwt_token';

  /// Application display name.
  static const String appTitle = 'Library Management';
}

