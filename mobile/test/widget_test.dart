import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:library_mobile/main.dart';

class FakeAuthRepository implements AuthRepository {
  User? currentUser;

  @override
  Future<User> login({required String username, required String password}) async {
    final user = User(id: 1, username: username, role: 'librarian');
    currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<User?> restoreSession() async => currentUser;
}

void main() {
  testWidgets('Unauthenticated user is redirected to LoginScreen',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();
    final authController = AuthController(
      loginUserUseCase: LoginUser(fakeRepo),
      logoutUserUseCase: LogoutUser(fakeRepo),
      restoreSessionUseCase: RestoreSession(fakeRepo),
    );

    await tester.pumpWidget(LibraryApp(authController: authController));
    await tester.pumpAndSettle();

    // Verifies that unauthenticated user sees LoginScreen
    expect(find.text('Library Manager'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Username or Admission Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    // Verifies debug-only base URL display
    expect(find.text('http://10.0.2.2:3000/api'), findsOneWidget);
  });

  testWidgets('Authenticated user is redirected to HomeScreen displaying their role',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();
    fakeRepo.currentUser = const User(
      id: 1,
      username: 'admin',
      role: 'librarian',
    );

    final authController = AuthController(
      loginUserUseCase: LoginUser(fakeRepo),
      logoutUserUseCase: LogoutUser(fakeRepo),
      restoreSessionUseCase: RestoreSession(fakeRepo),
    );
    await authController.restoreSession();

    await tester.pumpWidget(LibraryApp(authController: authController));
    await tester.pumpAndSettle();

    // Verifies that authenticated user sees HomeScreen with their role
    expect(find.text('Welcome, admin'), findsOneWidget);
    expect(find.text('Role: Librarian'), findsOneWidget);
    expect(find.text('Sign Out'), findsWidgets);
  });
}
