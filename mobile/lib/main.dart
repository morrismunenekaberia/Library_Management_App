import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client/api_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/token_storage/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core singletons
  const tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final _router = AppRouter.createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
