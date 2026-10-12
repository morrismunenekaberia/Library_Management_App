import '../../../../core/api_client/api_client.dart';
import '../models/book_model.dart';

/// Remote data source contract for Books.
abstract class BooksRemoteDataSource {
  Future<List<BookModel>> listBooks({String? search});
  Future<BookModel> getBook(int id);
  Future<BookModel> createBook(Map<String, dynamic> body);
  Future<BookModel> updateBook(int id, Map<String, dynamic> body);
  Future<void> deleteBook(int id);
}

/// Implementation of [BooksRemoteDataSource] communicating with the backend REST API.
class BooksRemoteDataSourceImpl implements BooksRemoteDataSource {
  final ApiClient _apiClient;

  const BooksRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<BookModel>> listBooks({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      '/books',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<BookModel> getBook(int id) async {
    final response = await _apiClient.get('/books/$id');
    return BookModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BookModel> createBook(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/books', body: body);
    return BookModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BookModel> updateBook(int id, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/books/$id', body: body);
    return BookModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBook(int id) async {
    await _apiClient.delete('/books/$id');
  }
}
