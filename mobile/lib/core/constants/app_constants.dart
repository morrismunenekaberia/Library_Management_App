/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Base URL for the Library Management Backend API.
  /// Defaults to `http://10.0.2.2:3000/api` for the Android emulator.
  /// For a physical phone, pass `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:3000/api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Key used to store the JWT auth token securely in FlutterSecureStorage.
  static const String tokenStorageKey = 'jwt_token';

  /// Key used to store the cached user session in FlutterSecureStorage.
  static const String userStorageKey = 'cached_user';

  /// Application display name.
  static const String appTitle = 'Library Management';
}
