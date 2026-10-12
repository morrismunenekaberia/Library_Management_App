import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/features/books/domain/entities/book.dart';
import 'package:library_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:library_mobile/features/books/domain/usecases/create_book.dart';
import 'package:library_mobile/features/books/domain/usecases/delete_book.dart';
import 'package:library_mobile/features/books/domain/usecases/get_book.dart';
import 'package:library_mobile/features/books/domain/usecases/list_books.dart';
import 'package:library_mobile/features/books/domain/usecases/update_book.dart';
import 'package:library_mobile/features/books/presentation/controllers/books_controller.dart';

class FakeBookRepository implements BookRepository {
  final List<Book> books = [
    const Book(
      id: 1,
      isbn: '9780132350884',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Software Engineering',
      totalCopies: 5,
      availableCopies: 3,
    ),
    const Book(
      id: 2,
      isbn: '9780201616224',
      title: 'The Pragmatic Programmer',
      author: 'Andrew Hunt',
      category: 'Software Engineering',
      totalCopies: 4,
      availableCopies: 0,
    ),
  ];

  bool shouldThrow = false;

  @override
  Future<List<Book>> listBooks({String? search}) async {
    if (shouldThrow) throw Exception('Failed to load books from server');
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      return books
          .where((b) =>
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query) ||
              b.isbn.contains(query))
          .toList();
    }
    return List.of(books);
  }

  @override
  Future<Book> getBook(int id) async {
    if (shouldThrow) throw Exception('Book not found');
    return books.firstWhere((b) => b.id == id);
  }

  @override
  Future<Book> createBook({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  }) async {
    if (shouldThrow) throw Exception('Duplicate ISBN conflict');
    final newBook = Book(
      id: books.length + 1,
      isbn: isbn,
      title: title,
      author: author,
      category: category,
      totalCopies: totalCopies,
      availableCopies: availableCopies ?? totalCopies,
    );
    books.add(newBook);
    return newBook;
  }

  @override
  Future<Book> updateBook(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  }) async {
    if (shouldThrow) throw Exception('Update failed');
    final index = books.indexWhere((b) => b.id == id);
    final existing = books[index];
    final updated = existing.copyWith(
      isbn: isbn,
      title: title,
      author: author,
      category: category,
      totalCopies: totalCopies,
    );
    books[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteBook(int id) async {
    if (shouldThrow) throw Exception('Cannot delete book with active loans');
    books.removeWhere((b) => b.id == id);
  }
}

void main() {
  group('Books Feature Tests', () {
    late FakeBookRepository fakeRepo;
    late BooksController controller;

    setUp(() {
      fakeRepo = FakeBookRepository();
      controller = BooksController(
        listBooksUseCase: ListBooks(fakeRepo),
        getBookUseCase: GetBook(fakeRepo),
        createBookUseCase: CreateBook(fakeRepo),
        updateBookUseCase: UpdateBook(fakeRepo),
        deleteBookUseCase: DeleteBook(fakeRepo),
      );
    });

    test('fetchBooks loads books into controller state', () async {
      expect(controller.books, isEmpty);
      await controller.fetchBooks();

      expect(controller.books.length, 2);
      expect(controller.books.first.title, 'Clean Code');
      expect(controller.errorMessage, isNull);
    });

    test('search filters books according to query', () async {
      await controller.search('Pragmatic');

      expect(controller.books.length, 1);
      expect(controller.books.first.title, 'The Pragmatic Programmer');
    });

    test('fetchBooks sets errorMessage on failure', () async {
      fakeRepo.shouldThrow = true;
      await controller.fetchBooks();

      expect(controller.books, isEmpty);
      expect(controller.errorMessage, 'Failed to load books from server');
    });

    test('fetchBookDetails loads specific book into selectedBook', () async {
      final book = await controller.fetchBookDetails(1);

      expect(book, isNotNull);
      expect(book!.title, 'Clean Code');
      expect(controller.selectedBook?.id, 1);
    });

    test('createBook successfully creates and prepends book to state', () async {
      final created = await controller.createBook(
        isbn: '9780131103627',
        title: 'The C Programming Language',
        author: 'Brian W. Kernighan',
        category: 'Computer Science',
        totalCopies: 3,
      );

      expect(created, isNotNull);
      expect(created!.title, 'The C Programming Language');
      expect(controller.books.first.id, created.id);
      expect(controller.formErrorMessage, isNull);
    });

    test('createBook captures formErrorMessage on conflict failure', () async {
      fakeRepo.shouldThrow = true;
      final created = await controller.createBook(
        isbn: '9780131103627',
        title: 'The C Programming Language',
        author: 'Brian W. Kernighan',
        totalCopies: 3,
      );

      expect(created, isNull);
      expect(controller.formErrorMessage, 'Duplicate ISBN conflict');
    });

    test('updateBook successfully modifies book', () async {
      await controller.fetchBooks();
      final updated = await controller.updateBook(
        1,
        title: 'Clean Code: Second Edition',
        totalCopies: 10,
      );

      expect(updated, isNotNull);
      expect(updated!.title, 'Clean Code: Second Edition');
      expect(updated.totalCopies, 10);
      expect(controller.books.firstWhere((b) => b.id == 1).title,
          'Clean Code: Second Edition');
    });

    test('deleteBook successfully removes book from state', () async {
      await controller.fetchBooks();
      expect(controller.books.length, 2);

      final success = await controller.deleteBook(1);

      expect(success, isTrue);
      expect(controller.books.length, 1);
      expect(controller.books.any((b) => b.id == 1), isFalse);
    });

    test('deleteBook captures error message when deletion fails', () async {
      fakeRepo.shouldThrow = true;
      final success = await controller.deleteBook(1);

      expect(success, isFalse);
      expect(controller.errorMessage, 'Cannot delete book with active loans');
    });
  });
}

