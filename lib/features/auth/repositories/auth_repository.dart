import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/auth/datasources/auth_remote_data_source.dart';
import 'package:orbytis_atlas/features/auth/errors/auth_exception.dart';
import 'package:orbytis_atlas/features/auth/models/login_response.dart';

final class AuthRepository {
  AuthRepository({
    required this._remoteDataSource,
    required this._secureStorageService,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      await _secureStorageService.saveAccessToken(response.accessToken);

      return response;
    } on NetworkException catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<bool> hasStoredSession() async {
    final token = await _secureStorageService.readAccessToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorageService.deleteAccessToken();
  }

  AuthException _mapAuthError(NetworkException error) {
    switch (error.type) {
      case NetworkErrorType.unauthorized:
        return const AuthException('E-mail ou senha inválidos.');

      case NetworkErrorType.timeout:
        return const AuthException(
          'Tempo de conexão excedido. Tente novamente.',
        );

      case NetworkErrorType.connection:
        return const AuthException('Não foi possível conectar ao servidor.');

      case NetworkErrorType.badResponse:
        return const AuthException('Não foi possível realizar o login.');

      case NetworkErrorType.cancelled:
        return const AuthException('A solicitação foi cancelada.');

      case NetworkErrorType.badCertificate:
        return const AuthException(
          'Não foi possível estabelecer uma conexão segura.',
        );

      case NetworkErrorType.unknown:
        return const AuthException('Ocorreu um erro inesperado.');
    }
  }
}
