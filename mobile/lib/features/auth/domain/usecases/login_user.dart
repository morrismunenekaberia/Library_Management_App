import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: Authenticates the user with username and password.
class LoginUser {
  final AuthRepository _repository;

  const LoginUser(this._repository);

  Future<User> call({required String username, required String password}) {
    return _repository.login(username: username, password: password);
  }
}
