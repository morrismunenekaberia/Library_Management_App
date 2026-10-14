import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
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

  static const String splashRoute = '/splash';
  static const String homeRoute = '/';
  static const String booksRoute = '/books';
  static const String newBookRoute = '/books/new';
  static const String loginRoute = '/login';

  /// Tracks whether the cold-start splash screen has already been shown in this process.
  static bool splashSeen = false;

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Creates and configures the application router with authentication guards.
  static GoRouter createRouter(
    AuthController authController, {
    String? initialLocation,
  }) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation ?? (splashSeen ? homeRoute : splashRoute),
      refreshListenable: authController,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isSplash = loc == splashRoute;

        // While on splash screen and splash has not finished, never redirect away
        if (isSplash && !splashSeen) {
          return null;
        }

        final isAuthenticated = authController.isAuthenticated;
        final isLoggingIn = loc == loginRoute;

        // If user is not authenticated, redirect to login (unless still on splash)
        if (!isAuthenticated) {
          if (isSplash && !splashSeen) return null;
          return isLoggingIn ? null : loginRoute;
        }

        // If user is authenticated and attempts to visit login or splash screen, redirect to home
        if (isLoggingIn || isSplash) {
          return homeRoute;
        }

        // Prevent members from accessing librarian-only book modification routes
        final isLibrarianOnlyRoute = loc == newBookRoute || loc.endsWith('/edit');
        if (isLibrarianOnlyRoute && authController.user?.isLibrarian != true) {
          return homeRoute;
        }

        return null;
      },
      routes: [
        // Cold start video splash route
        GoRoute(
          path: splashRoute,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Authentication route
        GoRoute(
          path: loginRoute,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Authenticated Main Shell with Material 3 NavigationBar and PageView
        GoRoute(
          path: homeRoute,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MainShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
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
