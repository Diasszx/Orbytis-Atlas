import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/auth/datasources/auth_remote_data_source.dart';
import 'package:orbytis_atlas/features/auth/models/login_response.dart';

final class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorageService,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorageService = secureStorageService;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    await _secureStorageService.saveAccessToken(response.accessToken);

    return response;
  }

  Future<bool> hasStoredSession() async {
    final token = await _secureStorageService.readAccessToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorageService.deleteAccessToken();
  }
}
