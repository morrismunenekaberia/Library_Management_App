import '../repositories/auth_repository.dart';

/// Use case: Logs out the user and clears stored session.
class LogoutUser {
  final AuthRepository _repository;

  const LogoutUser(this._repository);

  Future<void> call() {
    return _repository.logout();
  }
}

