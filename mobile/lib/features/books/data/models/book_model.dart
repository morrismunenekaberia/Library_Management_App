import '../../domain/entities/book.dart';

/// Data model representing a book with JSON serialization.
class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.isbn,
    required super.title,
    required super.author,
    super.category,
    required super.totalCopies,
    required super.availableCopies,
  });

  /// Creates a [BookModel] instance from a JSON map.
  /// Handles both camelCase and snake_case backend keys gracefully.
  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: (json['id'] as num).toInt(),
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      category: json['category'] as String?,
      totalCopies: ((json['totalCopies'] ?? json['total_copies']) as num).toInt(),
      availableCopies:
          ((json['availableCopies'] ?? json['available_copies']) as num).toInt(),
    );
  }

  /// Converts this [BookModel] instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'category': category,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
    };
  }

  /// Factory to convert a domain [Book] into a [BookModel].
  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      isbn: book.isbn,
      title: book.title,
      author: book.author,
      category: book.category,
      totalCopies: book.totalCopies,
      availableCopies: book.availableCopies,
    );
  }
}

