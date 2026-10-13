import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../token_storage/token_storage.dart';

/// HTTP API client wrapping the [http] package.
/// - Reads base URL from [apiBaseUrl].
/// - Automatically injects the `Authorization: Bearer <token>` header if available.
/// - Decodes JSON responses.
/// - Maps HTTP status codes and socket errors to typed [AppException]s.
class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 10);

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String _baseUrl;
  void Function()? onUnauthorized;

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    String? baseUrl,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? const TokenStorage(),
       _baseUrl = baseUrl ?? apiBaseUrl;

  /// Builds standardized request headers including Authorization token if available.
  Future<Map<String, String>> _buildHeaders([
    Map<String, String>? customHeaders,
  ]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Resolves the absolute URI for a given path and optional query parameters.
  Uri _resolveUri(String path, [Map<String, dynamic>? queryParams]) {
    final trimmedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$trimmedPath';

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      // Map query params to string values, removing nulls
      final cleanParams = queryParams
          .where((key, value) => value != null)
          .map((key, value) => MapEntry(key, value.toString()));
      return uri.replace(queryParameters: cleanParams);
    }

    return uri;
  }

  /// Processes HTTP response and maps status codes to typed exceptions.
  dynamic _handleResponse(http.Response response) {
    dynamic decodedBody;
    String errorMessage =
        'Request failed with status code ${response.statusCode}';

    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('error')) {
          errorMessage = decodedBody['error'].toString();
        }
      } catch (_) {
        errorMessage = response.body;
      }
    }

    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(errorMessage);
      case 401:
        onUnauthorized?.call();
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 409:
        throw ConflictException(errorMessage);
      default:
        if (statusCode >= 500) {
          throw ServerException(errorMessage, statusCode);
        }
        throw ValidationException(errorMessage, statusCode);
    }
  }

  /// Executes an HTTP GET request.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _resolveUri(path, queryParams);
      final resolvedHeaders = await _buildHeaders(headers);
      final response = await _client
          .get(uri, headers: resolvedHeaders)
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw const NetworkException();
    } on TimeoutException catch (_) {
      throw const NetworkException();
    } on http.ClientException catch (_) {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unexpected network error: $e');
    }
  }

  /// Executes an HTTP POST request.
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _resolveUri(path);
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .post(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw const NetworkException();
    } on TimeoutException catch (_) {
      throw const NetworkException();
    } on http.ClientException catch (_) {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unexpected network error: $e');
    }
  }

  /// Executes an HTTP PUT request.
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _resolveUri(path);
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .put(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw const NetworkException();
    } on TimeoutException catch (_) {
      throw const NetworkException();
    } on http.ClientException catch (_) {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unexpected network error: $e');
    }
  }

  /// Executes an HTTP DELETE request.
  Future<dynamic> delete(String path, {Map<String, String>? headers}) async {
    try {
      final uri = _resolveUri(path);
      final resolvedHeaders = await _buildHeaders(headers);
      final response = await _client
          .delete(uri, headers: resolvedHeaders)
          .timeout(defaultTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw const NetworkException();
    } on TimeoutException catch (_) {
      throw const NetworkException();
    } on http.ClientException catch (_) {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unexpected network error: $e');
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}

extension _MapFilterExtension on Map<String, dynamic> {
  Map<String, dynamic> where(bool Function(String key, dynamic value) test) {
    final result = <String, dynamic>{};
    forEach((key, value) {
      if (test(key, value)) {
        result[key] = value;
      }
    });
    return result;
  }
}
