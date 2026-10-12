import '../entities/book.dart';

/// Repository interface for Book domain operations.
abstract class BookRepository {
  /// Fetches a list of books, optionally filtered by a search query.
  Future<List<Book>> listBooks({String? search});

  /// Fetches a single book by its identifier.
  Future<Book> getBook(int id);

  /// Creates a new book entry in the catalogue.
  Future<Book> createBook({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  });

  /// Updates an existing book.
  Future<Book> updateBook(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  });

  /// Deletes a book by its identifier.
  Future<void> deleteBook(int id);
}
