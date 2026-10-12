import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:library_mobile/core/api_client/api_client.dart';
import 'package:library_mobile/core/errors/app_exceptions.dart';
import 'package:library_mobile/core/token_storage/token_storage.dart';

class FakeTokenStorage extends TokenStorage {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}

void main() {
  group('ApiClient Core Tests', () {
    late FakeTokenStorage fakeTokenStorage;

    setUp(() {
      fakeTokenStorage = FakeTokenStorage();
    });

    test('Injects Authorization Bearer header when token is present', () async {
      await fakeTokenStorage.saveToken('test_jwt_token_123');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test_jwt_token_123');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      final result = await apiClient.get('/test');
      expect(result, {'status': 'ok'});
    });

    test('Omits Authorization header when token is absent', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      final result = await apiClient.get('/test');
      expect(result, {'status': 'ok'});
    });

    test('Maps 400 Bad Request to ValidationException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Missing field'}), 400);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.post('/test', body: {}),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Missing field',
        )),
      );
    });

    test('Maps 401 Unauthorized to UnauthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Invalid token'}), 401);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.get('/protected'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Maps 403 Forbidden to ForbiddenException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Forbidden'}), 403);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.get('/admin-only'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('Maps 404 Not Found to NotFoundException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Book not found'}), 404);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.get('/books/999'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('Maps 409 Conflict to ConflictException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({'error': 'A book with this ISBN already exists'}), 409);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.post('/books', body: {}),
        throwsA(isA<ConflictException>()),
      );
    });

    test('Maps 500 Internal Error to ServerException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Server crashed'}), 500);
      });

      final apiClient = ApiClient(
        client: mockClient,
        tokenStorage: fakeTokenStorage,
        baseUrl: 'http://localhost:3000/api',
      );

      expect(
        () => apiClient.get('/crash'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
