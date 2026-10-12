import '../../../../core/api_client/api_client.dart';
import '../models/user_model.dart';

/// Remote data source contract for authentication API calls.
abstract class AuthRemoteDataSource {
  /// Calls POST /api/auth/login.
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  });

  /// Calls POST /api/auth/logout.
  Future<void> logout();

  /// Calls GET /api/auth/me to verify token and fetch user profile.
  Future<UserModel> getProfile();
}

/// Implementation of [AuthRemoteDataSource] using [ApiClient].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'username': username, 'password': password},
    );

    final map = response as Map<String, dynamic>;
    final token = map['token'] as String;
    final user = UserModel.fromJson(map['user'] as Map<String, dynamic>);

    return (token: token, user: user);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get('/auth/me');
    final map = response as Map<String, dynamic>;
    return UserModel.fromJson(map['user'] as Map<String, dynamic>);
  }
}
