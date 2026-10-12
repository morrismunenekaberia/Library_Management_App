/// Book domain entity.
class Book {
  final int id;
  final String isbn;
  final String title;
  final String author;
  final String? category;
  final int totalCopies;
  final int availableCopies;

  const Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.category,
    required this.totalCopies,
    required this.availableCopies,
  });

  /// Returns true if at least one copy of this book is currently available.
  bool get isAvailable => availableCopies > 0;

  Book copyWith({
    int? id,
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
    int? availableCopies,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isbn == other.isbn &&
          title == other.title &&
          author == other.author &&
          category == other.category &&
          totalCopies == other.totalCopies &&
          availableCopies == other.availableCopies;

  @override
  int get hashCode =>
      id.hashCode ^
      isbn.hashCode ^
      title.hashCode ^
      author.hashCode ^
      category.hashCode ^
      totalCopies.hashCode ^
      availableCopies.hashCode;
}
