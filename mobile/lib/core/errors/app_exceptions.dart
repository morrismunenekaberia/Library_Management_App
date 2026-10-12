/// Base class for all application exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thrown when request input fails server validation (HTTP 400).
class ValidationException extends AppException {
  const ValidationException(super.message, [super.statusCode = 400]);
}

/// Thrown when authentication is missing, invalid, or expired (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, [super.statusCode = 401]);
}

/// Thrown when user lacks permission to access resource (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, [super.statusCode = 403]);
}

/// Thrown when the requested resource was not found (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.statusCode = 404]);
}

/// Thrown when an operation conflicts with current state, e.g. duplicate ISBN or active loans (HTTP 409).
class ConflictException extends AppException {
  const ConflictException(super.message, [super.statusCode = 409]);
}

/// Thrown when the server encounters an internal error (HTTP 500+).
class ServerException extends AppException {
  const ServerException(super.message, [super.statusCode = 500]);
}

/// Thrown when network connection is unreachable, timed out, or drops.
class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Cannot reach the server. Check Wi-Fi and that the API is running.',
  ]);
}
