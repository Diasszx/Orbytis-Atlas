import 'package:dio/dio.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/features/auth/models/login_response.dart';

final class AuthRemoteDataSource {
  AuthRemoteDataSource({required DioClient dioClient}) : _dio = dioClient.dio;

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException('Invalid login response');
    }

    return LoginResponse.fromJson(data);
  }
}
