import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:library_mobile/features/splash/presentation/splash_screen.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:library_mobile/core/router/app_router.dart';

class _FakeAuthRepo implements AuthRepository {
  User? user;
  _FakeAuthRepo();

  @override
  Future<User> login({required String username, required String password}) async =>
      user ?? const User(id: 1, username: 'test', role: 'member');

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  Future<User?> restoreSession() async => user;
}

void main() {
  setUp(() {
    AppRouter.splashSeen = false;
  });

  testWidgets('SplashScreen renders background and Skip button', (tester) async {
    final authController = AuthController(
      loginUserUseCase: LoginUser(_FakeAuthRepo()),
      logoutUserUseCase: LogoutUser(_FakeRepo()),
      restoreSessionUseCase: RestoreSession(_FakeRepo()),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Tapping Skip navigates when session restore is complete', (tester) async {
    final authController = AuthController(
      loginUserUseCase: LoginUser(_FakeAuthRepo()),
      logoutUserUseCase: LogoutUser(_FakeRepo()),
      restoreSessionUseCase: RestoreSession(_FakeRepo()),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: MaterialApp.router(
          routerConfig: AppRouter.createRouter(authController),
        ),
      ),
    );

    expect(find.text('Skip'), findsOneWidget);

    // Tap skip
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Since unauthenticated, should navigate to Login screen
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}

class _FakeRepo implements AuthRepository {
  @override
  Future<User> login({required String username, required String password}) async =>
      const User(id: 1, username: 'test', role: 'member');

  @override
  Future<void> logout() async {}

  @override
  Future<User?> restoreSession() async => null;
}
