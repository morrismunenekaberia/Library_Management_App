import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

/// Application routing configuration using [GoRouter].
/// Handles authentication redirects based on [AuthController] state.
class AppRouter {
  AppRouter._();

  static const String homeRoute = '/';
  static const String loginRoute = '/login';

  /// Creates and configures the application router with authentication guards.
  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      initialLocation: homeRoute,
      refreshListenable: authController,
      redirect: (context, state) {
        final isAuthenticated = authController.isAuthenticated;
        final isLoggingIn = state.matchedLocation == loginRoute;

        // If user is not authenticated, redirect to login
        if (!isAuthenticated) {
          return isLoggingIn ? null : loginRoute;
        }

        // If user is authenticated and attempts to visit login screen, redirect to home
        if (isLoggingIn) {
          return homeRoute;
        }

        // No redirection needed
        return null;
      },
      routes: [
        GoRoute(
          path: homeRoute,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );
  }
}
