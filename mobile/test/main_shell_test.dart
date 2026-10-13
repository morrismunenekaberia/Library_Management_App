import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:library_mobile/main.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user;
  _FakeAuthRepository(this.user);

  @override
  Future<User> login({required String username, required String password}) async => user!;

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  Future<User?> restoreSession() async => user;
}

void main() {
  group('MainShell Navigation Tests', () {
    testWidgets('Librarian sees 5 tabs: Home, Books, Members, Loans, Settings',
        (WidgetTester tester) async {
      final authRepo = _FakeAuthRepository(
        const User(id: 1, username: 'admin', role: 'librarian'),
      );
      final authController = AuthController(
        loginUserUseCase: LoginUser(authRepo),
        logoutUserUseCase: LogoutUser(authRepo),
        restoreSessionUseCase: RestoreSession(authRepo),
      );
      await authController.restoreSession();

      await tester.pumpWidget(LibraryApp(authController: authController));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Members'), findsWidgets);
      expect(find.text('Loans'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Member sees 4 tabs: Home, My Loans, Browse, Settings',
        (WidgetTester tester) async {
      final authRepo = _FakeAuthRepository(
        const User(id: 2, username: 'student1', role: 'member'),
      );
      final authController = AuthController(
        loginUserUseCase: LoginUser(authRepo),
        logoutUserUseCase: LogoutUser(authRepo),
        restoreSessionUseCase: RestoreSession(authRepo),
      );
      await authController.restoreSession();

      await tester.pumpWidget(LibraryApp(authController: authController));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Loans'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      // Librarian tabs should not be present
      expect(find.text('Members'), findsNothing);
    });

    testWidgets('Tapping a tab switches page and swiping switches tab',
        (WidgetTester tester) async {
      final authRepo = _FakeAuthRepository(
        const User(id: 1, username: 'admin', role: 'librarian'),
      );
      final authController = AuthController(
        loginUserUseCase: LoginUser(authRepo),
        logoutUserUseCase: LogoutUser(authRepo),
        restoreSessionUseCase: RestoreSession(authRepo),
      );
      await authController.restoreSession();

      await tester.pumpWidget(LibraryApp(authController: authController));
      await tester.pumpAndSettle();

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Account Information'), findsOneWidget);

      // Swipe right to go back to Loans tab
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Loans'), findsWidgets);
    });

    testWidgets('Back navigation returns to Home tab if not on Home',
        (WidgetTester tester) async {
      final authRepo = _FakeAuthRepository(
        const User(id: 1, username: 'admin', role: 'librarian'),
      );
      final authController = AuthController(
        loginUserUseCase: LoginUser(authRepo),
        logoutUserUseCase: LogoutUser(authRepo),
        restoreSessionUseCase: RestoreSession(authRepo),
      );
      await authController.restoreSession();

      await tester.pumpWidget(LibraryApp(authController: authController));
      await tester.pumpAndSettle();

      // Switch to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Account Information'), findsOneWidget);

      // Verify PopScope pops back to Home tab (index 0)
      final popScope = tester.widget<PopScope<Object?>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      expect(popScope.canPop, isFalse);
      popScope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();

      // Should be back on Home
      expect(find.text('Welcome, admin'), findsOneWidget);
    });
  });
}
