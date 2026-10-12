import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Use case to update an existing book.
class UpdateBook {
  final BookRepository _repository;

  const UpdateBook(this._repository);

  Future<Book> call(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  }) {
    return _repository.updateBook(
      id,
      isbn: isbn,
      title: title,
      author: author,
      category: category,
      totalCopies: totalCopies,
    );
  }
}
