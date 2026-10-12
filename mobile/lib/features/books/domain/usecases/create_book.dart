import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Use case to create a new book.
class CreateBook {
  final BookRepository _repository;

  const CreateBook(this._repository);

  Future<Book> call({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  }) {
    return _repository.createBook(
      isbn: isbn,
      title: title,
      author: author,
      category: category,
      totalCopies: totalCopies,
      availableCopies: availableCopies,
    );
  }
}

