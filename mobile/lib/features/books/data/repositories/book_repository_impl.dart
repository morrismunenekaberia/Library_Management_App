import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/books_remote_data_source.dart';

/// Implementation of [BookRepository] coordinating with [BooksRemoteDataSource].
class BookRepositoryImpl implements BookRepository {
  final BooksRemoteDataSource _remoteDataSource;

  const BookRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Book>> listBooks({String? search}) async {
    return _remoteDataSource.listBooks(search: search);
  }

  @override
  Future<Book> getBook(int id) async {
    return _remoteDataSource.getBook(id);
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
    final body = <String, dynamic>{
      'isbn': isbn,
      'title': title,
      'author': author,
      'totalCopies': totalCopies,
    };

    if (category != null && category.trim().isNotEmpty) {
      body['category'] = category.trim();
    }
    if (availableCopies != null) {
      body['availableCopies'] = availableCopies;
    }

    return _remoteDataSource.createBook(body);
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
    final body = <String, dynamic>{};
    if (isbn != null && isbn.trim().isNotEmpty) {
      body['isbn'] = isbn.trim();
    }
    if (title != null && title.trim().isNotEmpty) {
      body['title'] = title.trim();
    }
    if (author != null && author.trim().isNotEmpty) {
      body['author'] = author.trim();
    }
    if (category != null) {
      body['category'] = category.trim().isEmpty ? null : category.trim();
    }
    if (totalCopies != null) {
      body['totalCopies'] = totalCopies;
    }

    return _remoteDataSource.updateBook(id, body);
  }

  @override
  Future<void> deleteBook(int id) async {
    return _remoteDataSource.deleteBook(id);
  }
}
