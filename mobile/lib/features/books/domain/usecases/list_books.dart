import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Use case to retrieve a list of books with optional search query.
class ListBooks {
  final BookRepository _repository;

  const ListBooks(this._repository);

  Future<List<Book>> call({String? search}) {
    return _repository.listBooks(search: search);
  }
}

