import '../entities/user.dart';

/// Abstract contract for authentication data operations.
abstract class AuthRepository {
  /// Authenticates with username and password, persisting the received token.
  Future<User> login({
    required String username,
    required String password,
  });

  /// Invalidates session on the backend and purges stored credentials.
  Future<void> logout();

  /// Attempts to restore the user session from local secure storage.
  /// Returns null if no valid token exists or verification fails.
  Future<User?> restoreSession();
}

