import '../repositories/book_repository.dart';

/// Use case to delete a book by ID.
class DeleteBook {
  final BookRepository _repository;

  const DeleteBook(this._repository);

  Future<void> call(int id) {
    return _repository.deleteBook(id);
  }
}
