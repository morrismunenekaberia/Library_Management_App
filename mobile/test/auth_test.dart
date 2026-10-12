import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/core/errors/app_exceptions.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';

class FakeAuthRepository implements AuthRepository {
  User? currentUser;
  bool shouldFailLogin = false;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    if (shouldFailLogin) {
      throw const UnauthorizedException('Invalid username or password');
    }
    final user = User(
      id: 1,
      username: username,
      role: username == 'admin' ? 'librarian' : 'member',
    );
    currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<User?> restoreSession() async {
    return currentUser;
  }
}

void main() {
  group('Auth Feature Tests', () {
    late FakeAuthRepository fakeRepo;
    late LoginUser loginUser;
    late LogoutUser logoutUser;
    late RestoreSession restoreSession;
    late AuthController authController;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      loginUser = LoginUser(fakeRepo);
      logoutUser = LogoutUser(fakeRepo);
      restoreSession = RestoreSession(fakeRepo);
      authController = AuthController(
        loginUserUseCase: loginUser,
        logoutUserUseCase: logoutUser,
        restoreSessionUseCase: restoreSession,
      );
    });

    test('LoginUser use case successfully returns authenticated User', () async {
      final user = await loginUser(
        username: 'admin',
        password: 'password123',
      );

      expect(user.id, 1);
      expect(user.username, 'admin');
      expect(user.role, 'librarian');
      expect(user.isLibrarian, isTrue);
    });

    test('AuthController.login updates status to authenticated on success', () async {
      expect(authController.status, AuthStatus.initial);

      final success = await authController.login('admin', 'admin123');

      expect(success, isTrue);
      expect(authController.status, AuthStatus.authenticated);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.user?.username, 'admin');
      expect(authController.role, 'librarian');
      expect(authController.errorMessage, isNull);
    });

    test('AuthController.login sets unauthenticated and captures error message on failure', () async {
      fakeRepo.shouldFailLogin = true;

      final success = await authController.login('admin', 'wrong_pass');

      expect(success, isFalse);
      expect(authController.status, AuthStatus.unauthenticated);
      expect(authController.isAuthenticated, isFalse);
      expect(authController.user, isNull);
      expect(authController.errorMessage, 'Invalid username or password');
    });

    test('AuthController.logout clears user session', () async {
      await authController.login('admin', 'admin123');
      expect(authController.isAuthenticated, isTrue);

      await authController.logout();

      expect(authController.isAuthenticated, isFalse);
      expect(authController.status, AuthStatus.unauthenticated);
      expect(authController.user, isNull);
    });

    test('AuthController.restoreSession successfully restores saved user', () async {
      fakeRepo.currentUser = const User(
        id: 2,
        username: 'ADM-2024-001',
        role: 'member',
        memberId: 10,
      );

      await authController.restoreSession();

      expect(authController.isAuthenticated, isTrue);
      expect(authController.user?.username, 'ADM-2024-001');
      expect(authController.role, 'member');
      expect(authController.user?.isMember, isTrue);
    });
  });
}
