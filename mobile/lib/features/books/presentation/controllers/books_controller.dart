import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/create_book.dart';
import '../../domain/usecases/delete_book.dart';
import '../../domain/usecases/get_book.dart';
import '../../domain/usecases/list_books.dart';
import '../../domain/usecases/update_book.dart';

/// State management controller for the Books feature.
class BooksController extends ChangeNotifier {
  final ListBooks listBooksUseCase;
  final GetBook getBookUseCase;
  final CreateBook createBookUseCase;
  final UpdateBook updateBookUseCase;
  final DeleteBook deleteBookUseCase;

  BooksController({
    required this.listBooksUseCase,
    required this.getBookUseCase,
    required this.createBookUseCase,
    required this.updateBookUseCase,
    required this.deleteBookUseCase,
  });

  List<Book> _books = [];
  Book? _selectedBook;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _formErrorMessage;
  String _searchQuery = '';

  List<Book> get books => List.unmodifiable(_books);
  Book? get selectedBook => _selectedBook;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get formErrorMessage => _formErrorMessage;
  String get searchQuery => _searchQuery;

  /// Loads books catalogue with optional search filter.
  Future<void> fetchBooks({String? search, bool isRefresh = false}) async {
    _searchQuery = search ?? _searchQuery;
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await listBooksUseCase(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _books = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Searches books by query string.
  Future<void> search(String query) async {
    _searchQuery = query.trim();
    await fetchBooks(search: _searchQuery);
  }

  /// Clears search filter and reloads all books.
  Future<void> clearSearch() async {
    _searchQuery = '';
    await fetchBooks(search: '');
  }

  /// Fetches a specific book's details by ID.
  Future<Book?> fetchBookDetails(int id) async {
    _isDetailLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final book = await getBookUseCase(id);
      _selectedBook = book;
      return book;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new book entry.
  Future<Book?> createBook({
    required String isbn,
    required String title,
    required String author,
    String? category,
    required int totalCopies,
    int? availableCopies,
  }) async {
    _isSaving = true;
    _formErrorMessage = null;
    notifyListeners();

    try {
      final createdBook = await createBookUseCase(
        isbn: isbn,
        title: title,
        author: author,
        category: category,
        totalCopies: totalCopies,
        availableCopies: availableCopies,
      );
      _books = [createdBook, ..._books];
      return createdBook;
    } catch (e) {
      _formErrorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates an existing book.
  Future<Book?> updateBook(
    int id, {
    String? isbn,
    String? title,
    String? author,
    String? category,
    int? totalCopies,
  }) async {
    _isSaving = true;
    _formErrorMessage = null;
    notifyListeners();

    try {
      final updated = await updateBookUseCase(
        id,
        isbn: isbn,
        title: title,
        author: author,
        category: category,
        totalCopies: totalCopies,
      );

      // Update in local cache
      final index = _books.indexWhere((b) => b.id == id);
      if (index != -1) {
        _books[index] = updated;
      }
      if (_selectedBook?.id == id) {
        _selectedBook = updated;
      }
      return updated;
    } catch (e) {
      _formErrorMessage = _cleanErrorMessage(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes a book by ID.
  Future<bool> deleteBook(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deleteBookUseCase(id);
      _books.removeWhere((b) => b.id == id);
      if (_selectedBook?.id == id) {
        _selectedBook = null;
      }
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Clears any active error message.
  void clearError() {
    _errorMessage = null;
    _formErrorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred';
    if (error is AppException) return error.message;
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}

