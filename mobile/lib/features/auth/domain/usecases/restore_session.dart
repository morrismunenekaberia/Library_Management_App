import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: Restores an active user session from stored tokens.
class RestoreSession {
  final AuthRepository _repository;

  const RestoreSession(this._repository);

  Future<User?> call() {
    return _repository.restoreSession();
  }
}
