import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/features/auth/domain/entities/user.dart';
import 'package:library_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:library_mobile/features/auth/domain/usecases/login_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/logout_user.dart';
import 'package:library_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:library_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:library_mobile/features/books/domain/entities/book.dart';
import 'package:library_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:library_mobile/features/books/domain/usecases/create_book.dart';
import 'package:library_mobile/features/books/domain/usecases/delete_book.dart';
import 'package:library_mobile/features/books/domain/usecases/get_book.dart';
import 'package:library_mobile/features/books/domain/usecases/list_books.dart';
import 'package:library_mobile/features/books/domain/usecases/update_book.dart';
import 'package:library_mobile/features/books/presentation/controllers/books_controller.dart';
import 'package:library_mobile/features/books/presentation/screens/book_detail_screen.dart';
import 'package:library_mobile/main.dart';
import 'package:provider/provider.dart';

class FakeAuthRepository implements AuthRepository {
  User? user;

  FakeAuthRepository({this.user});

  @override
  Future<User> login({required String username, required String password}) async =>
      user!;

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  Future<User?> restoreSession() async => user;
}

class FakeBookRepository implements BookRepository {
  final List<Book> books;

  FakeBookRepository(this.books);

  @override
  Future<List<Book>> listBooks({String? search}) async => books;

  @override
  Future<Book> getBook(int id) async => books.firstWhere((b) => b.id == id);

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
        id: books.length + 1,
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
      books.firstWhere((b) => b.id == id);

  @override
  Future<void> deleteBook(int id) async {
    books.removeWhere((b) => b.id == id);
  }
}

void main() {
  final sampleBooks = [
    const Book(
      id: 1,
      isbn: '9780132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Software Engineering',
      totalCopies: 5,
      availableCopies: 3,
    ),
  ];

  testWidgets('Bottom navigation switches to Books tab and displays books',
      (WidgetTester tester) async {
    final authRepo = FakeAuthRepository(
      user: const User(id: 1, username: 'admin', role: 'librarian'),
    );
    final authController = AuthController(
      loginUserUseCase: LoginUser(authRepo),
      logoutUserUseCase: LogoutUser(authRepo),
      restoreSessionUseCase: RestoreSession(authRepo),
    );
    await authController.restoreSession();

    final bookRepo = FakeBookRepository(List.of(sampleBooks));
    final booksController = BooksController(
      listBooksUseCase: ListBooks(bookRepo),
      getBookUseCase: GetBook(bookRepo),
      createBookUseCase: CreateBook(bookRepo),
      updateBookUseCase: UpdateBook(bookRepo),
      deleteBookUseCase: DeleteBook(bookRepo),
    );

    await tester.pumpWidget(
      LibraryApp(
        authController: authController,
        booksController: booksController,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home tab is initially visible
    expect(find.text('Welcome, admin'), findsOneWidget);

    // Tap on Books bottom navigation item
    await tester.tap(find.text('Books'));
    await tester.pumpAndSettle();

    // Verify Books catalogue screen is displayed
    expect(find.text('Books Catalogue'), findsOneWidget);
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('By Robert C. Martin'), findsOneWidget);
    expect(find.text('3 / 5 avail'), findsOneWidget);
    // Librarian sees Add Book FAB
    expect(find.text('Add Book'), findsOneWidget);
  });

  testWidgets('Member role hides Add Book FloatingActionButton in BookListScreen',
      (WidgetTester tester) async {
    final authRepo = FakeAuthRepository(
      user: const User(id: 2, username: 'student1', role: 'member'),
    );
    final authController = AuthController(
      loginUserUseCase: LoginUser(authRepo),
      logoutUserUseCase: LogoutUser(authRepo),
      restoreSessionUseCase: RestoreSession(authRepo),
    );
    await authController.restoreSession();

    final bookRepo = FakeBookRepository(List.of(sampleBooks));
    final booksController = BooksController(
      listBooksUseCase: ListBooks(bookRepo),
      getBookUseCase: GetBook(bookRepo),
      createBookUseCase: CreateBook(bookRepo),
      updateBookUseCase: UpdateBook(bookRepo),
      deleteBookUseCase: DeleteBook(bookRepo),
    );

    await tester.pumpWidget(
      LibraryApp(
        authController: authController,
        booksController: booksController,
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Browse bottom navigation (or Books)
    final browseTab = find.text('Browse');
    if (browseTab.evaluate().isNotEmpty) {
      await tester.tap(browseTab);
    } else {
      await tester.tap(find.text('Books'));
    }
    await tester.pumpAndSettle();

    // Verify member sees catalogue but NOT the Add Book FAB
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Add Book'), findsNothing);
  });

  testWidgets('BookDetailScreen shows edit and delete controls for librarian',
      (WidgetTester tester) async {
    final authRepo = FakeAuthRepository(
      user: const User(id: 1, username: 'admin', role: 'librarian'),
    );
    final authController = AuthController(
      loginUserUseCase: LoginUser(authRepo),
      logoutUserUseCase: LogoutUser(authRepo),
      restoreSessionUseCase: RestoreSession(authRepo),
    );
    await authController.restoreSession();

    final bookRepo = FakeBookRepository(List.of(sampleBooks));
    final booksController = BooksController(
      listBooksUseCase: ListBooks(bookRepo),
      getBookUseCase: GetBook(bookRepo),
      createBookUseCase: CreateBook(bookRepo),
      updateBookUseCase: UpdateBook(bookRepo),
      deleteBookUseCase: DeleteBook(bookRepo),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<BooksController>.value(value: booksController),
        ],
        child: MaterialApp(
          home: BookDetailScreen(
            bookId: 1,
            initialBook: sampleBooks.first,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify book details are rendered
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('By Robert C. Martin'), findsOneWidget);
    expect(find.text('9780132350884'), findsOneWidget);

    // Librarian controls should be visible
    expect(find.byIcon(Icons.edit_rounded), findsWidgets);
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
    expect(find.text('Edit Book Information'), findsOneWidget);
    expect(find.text('Delete Book'), findsWidgets);
  });

  testWidgets('BookDetailScreen hides edit and delete controls for member',
      (WidgetTester tester) async {
    final authRepo = FakeAuthRepository(
      user: const User(id: 2, username: 'student1', role: 'member'),
    );
    final authController = AuthController(
      loginUserUseCase: LoginUser(authRepo),
      logoutUserUseCase: LogoutUser(authRepo),
      restoreSessionUseCase: RestoreSession(authRepo),
    );
    await authController.restoreSession();

    final bookRepo = FakeBookRepository(List.of(sampleBooks));
    final booksController = BooksController(
      listBooksUseCase: ListBooks(bookRepo),
      getBookUseCase: GetBook(bookRepo),
      createBookUseCase: CreateBook(bookRepo),
      updateBookUseCase: UpdateBook(bookRepo),
      deleteBookUseCase: DeleteBook(bookRepo),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<BooksController>.value(value: booksController),
        ],
        child: MaterialApp(
          home: BookDetailScreen(
            bookId: 1,
            initialBook: sampleBooks.first,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify book details are rendered
    expect(find.text('Clean Code'), findsOneWidget);

    // Member should NOT see any edit or delete controls
    expect(find.byIcon(Icons.edit_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.text('Edit Book Information'), findsNothing);
    expect(find.text('Delete Book'), findsNothing);
  });
}

