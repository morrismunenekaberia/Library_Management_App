import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/books/domain/entities/book.dart';
import '../../features/books/presentation/screens/book_detail_screen.dart';
import '../../features/books/presentation/screens/book_form_screen.dart';
import '../widgets/main_shell.dart';

/// Application routing configuration using [GoRouter].
/// Handles authentication redirects, bottom navigation shell, and feature routes.
class AppRouter {
  AppRouter._();

  static const String homeRoute = '/';
  static const String booksRoute = '/books';
  static const String newBookRoute = '/books/new';
  static const String loginRoute = '/login';

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Creates and configures the application router with authentication guards.
  static GoRouter createRouter(AuthController authController) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
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

        return null;
      },
      routes: [
        // Authentication route
        GoRoute(
          path: loginRoute,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),

        // Authenticated Main Shell with Material 3 NavigationBar and PageView
        GoRoute(
          path: homeRoute,
          builder: (context, state) => const MainShell(),
        ),
        // Keep books route backward-compatible if pushed directly or linked
        GoRoute(
          path: booksRoute,
          builder: (context, state) => const MainShell(initialIndex: 1),
        ),

        // Book details and form routes (opened as full screens)
        GoRoute(
          path: newBookRoute,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const BookFormScreen(),
        ),
        GoRoute(
          path: '/books/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final initialBook = state.extra as Book?;
            return BookDetailScreen(
              bookId: id,
              initialBook: initialBook,
            );
          },
        ),
        GoRoute(
          path: '/books/:id/edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            final initialBook = state.extra as Book?;
            return BookFormScreen(
              bookId: id,
              initialBook: initialBook,
            );
          },
        ),
      ],
    );
  }
}
