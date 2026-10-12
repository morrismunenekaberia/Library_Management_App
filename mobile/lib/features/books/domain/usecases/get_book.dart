import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Use case to retrieve a single book by ID.
class GetBook {
  final BookRepository _repository;

  const GetBook(this._repository);

  Future<Book> call(int id) {
    return _repository.getBook(id);
  }
}

