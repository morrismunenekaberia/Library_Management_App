import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/token_storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Concrete implementation of [AuthRepository].
/// Coordinates remote API calls and local token/session persistence.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
    this.secureStorage = const FlutterSecureStorage(),
  });

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final result = await remoteDataSource.login(
      username: username,
      password: password,
    );

    // Save token securely for future API requests
    await tokenStorage.saveToken(result.token);

    // Cache user profile
    await _cacheUser(result.user);

    return result.user;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Even if remote call fails (e.g. offline), clear local session
    } finally {
      await tokenStorage.deleteToken();
      await _clearCachedUser();
    }
  }

  @override
  Future<User?> restoreSession() async {
    final hasToken = await tokenStorage.hasToken();
    if (!hasToken) {
      return null;
    }

    try {
      // Verify token live with the backend
      final user = await remoteDataSource.getProfile();
      await _cacheUser(user);
      return user;
    } on UnauthorizedException {
      // Token is expired or invalid: purge local credentials
      await tokenStorage.deleteToken();
      await _clearCachedUser();
      return null;
    } on NetworkException {
      // If network is offline, attempt to restore from local cache
      return _getCachedUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    await secureStorage.write(
      key: AppConstants.userStorageKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> _getCachedUser() async {
    final raw = await secureStorage.read(key: AppConstants.userStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCachedUser() async {
    await secureStorage.delete(key: AppConstants.userStorageKey);
  }
}
