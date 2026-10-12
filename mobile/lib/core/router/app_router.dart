import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App routing configuration using GoRouter.
/// Contains placeholder routes for login and home.
class AppRouter {
  AppRouter._();

  static const String homeRoute = '/';
  static const String loginRoute = '/login';

  /// Creates and configures the application router.
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: homeRoute,
      routes: [
        GoRoute(
          path: homeRoute,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Library Home',
            message: 'Home screen placeholder. Feature screens will be added here.',
          ),
        ),
        GoRoute(
          path: loginRoute,
          builder: (context, state) => const _PlaceholderScreen(
            title: 'Sign In',
            message: 'Login screen placeholder. Feature screens will be added here.',
          ),
        ),
      ],
    );
  }
}

/// Simple placeholder screen used during core setup.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
