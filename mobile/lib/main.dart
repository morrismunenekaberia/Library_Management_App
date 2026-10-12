import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client/api_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/token_storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/books/data/datasources/books_remote_data_source.dart';
import 'features/books/data/repositories/book_repository_impl.dart';
import 'features/books/domain/entities/book.dart';
import 'features/books/domain/repositories/book_repository.dart';
import 'features/books/domain/usecases/create_book.dart';
import 'features/books/domain/usecases/delete_book.dart';
import 'features/books/domain/usecases/get_book.dart';
import 'features/books/domain/usecases/list_books.dart';
import 'features/books/domain/usecases/update_book.dart';
import 'features/books/presentation/controllers/books_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core singletons
  const tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  // Auth feature dependency wiring
  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    tokenStorage: tokenStorage,
  );
  final loginUser = LoginUser(authRepository);
  final logoutUser = LogoutUser(authRepository);
  final restoreSession = RestoreSession(authRepository);

  final authController = AuthController(
    loginUserUseCase: loginUser,
    logoutUserUseCase: logoutUser,
    restoreSessionUseCase: restoreSession,
  );

  // Automatically log user out when API returns 401 Unauthorized
  apiClient.onUnauthorized = () {
    authController.handleSessionExpired();
  };

  // Books feature dependency wiring
  final booksRemoteDataSource = BooksRemoteDataSourceImpl(apiClient);
  final bookRepository = BookRepositoryImpl(booksRemoteDataSource);
  final listBooks = ListBooks(bookRepository);
  final getBook = GetBook(bookRepository);
  final createBook = CreateBook(bookRepository);
  final updateBook = UpdateBook(bookRepository);
  final deleteBook = DeleteBook(bookRepository);

  final booksController = BooksController(
    listBooksUseCase: listBooks,
    getBookUseCase: getBook,
    createBookUseCase: createBook,
    updateBookUseCase: updateBook,
    deleteBookUseCase: deleteBook,
  );

  // Restore session from persisted credentials on app startup
  authController.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<BookRepository>.value(value: bookRepository),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<BooksController>.value(value: booksController),
      ],
      child: LibraryApp(
        authController: authController,
        booksController: booksController,
      ),
    ),
  );
}

class LibraryApp extends StatefulWidget {
  final AuthController authController;
  final BooksController? booksController;

  const LibraryApp({
    super.key,
    required this.authController,
    this.booksController,
  });

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final _router = AppRouter.createRouter(widget.authController);
  late final BooksController _effectiveBooksController;

  @override
  void initState() {
    super.initState();
    _effectiveBooksController = widget.booksController ??
        BooksController(
          listBooksUseCase: const ListBooks(_NoopBookRepository()),
          getBookUseCase: const GetBook(_NoopBookRepository()),
          createBookUseCase: const CreateBook(_NoopBookRepository()),
          updateBookUseCase: const UpdateBook(_NoopBookRepository()),
          deleteBookUseCase: const DeleteBook(_NoopBookRepository()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(
          value: widget.authController,
        ),
        ChangeNotifierProvider<BooksController>.value(
          value: _effectiveBooksController,
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

/// Fallback repository used only if [LibraryApp] is constructed without [BooksController] in tests.
class _NoopBookRepository implements BookRepository {
  const _NoopBookRepository();

  @override
  Future<List<Book>> listBooks({String? search}) async => const [];

  @override
  Future<Book> getBook(int id) async => Book(
        id: id,
        isbn: '000',
        title: 'Untitled',
        author: 'Unknown',
        totalCopies: 1,
        availableCopies: 1,
      );

  @override
  Future<Book> createBook({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  }) async =>
      Book(
        id: 1,
        isbn: isbn,
        title: title,
        author: author,
        category: category,
        totalCopies: totalCopies,
        availableCopies: availableCopies ?? totalCopies,
      );

  @override
  Future<Book> updateBook(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  }) async =>
      Book(
        id: id,
        isbn: isbn ?? '000',
        title: title ?? 'Untitled',
        author: author ?? 'Unknown',
        category: category,
        totalCopies: totalCopies ?? 1,
        availableCopies: totalCopies ?? 1,
      );

  @override
  Future<void> deleteBook(int id) async {}
}
