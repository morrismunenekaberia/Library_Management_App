import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/restore_session.dart';

/// Authentication state phases.
enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Presentation controller managing authentication state across the application.
class AuthController extends ChangeNotifier {
  final LoginUser loginUserUseCase;
  final LogoutUser logoutUserUseCase;
  final RestoreSession restoreSessionUseCase;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthController({
    required this.loginUserUseCase,
    required this.logoutUserUseCase,
    required this.restoreSessionUseCase,
  });

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  /// True when a valid user session is active.
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  /// Role of the currently authenticated user (e.g. 'librarian' or 'member').
  String? get role => _user?.role;

  /// Restores session on app startup from stored tokens.
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final restored = await restoreSessionUseCase();
      if (restored != null) {
        _user = restored;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  /// Logs in with credentials. Returns true on success, false on failure.
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loggedInUser = await loginUserUseCase(
        username: username,
        password: password,
      );
      _user = loggedInUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logs out and resets authentication state.
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await logoutUserUseCase();
    } finally {
      _user = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Handles 401 Unauthorized signal from ApiClient.
  /// If user is authenticated, logs them out immediately and resets session.
  Future<void> handleSessionExpired() async {
    if (isAuthenticated) {
      await logout();
    }
  }
}
