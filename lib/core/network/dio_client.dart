import 'package:dio/dio.dart';
import 'package:orbytis_atlas/core/auth/session_expired_notifier.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';

import '../config/app_config.dart';

final class DioClient {
  DioClient({
    required SecureStorageService secureStorageService,
    required SessionExpiredNotifier sessionExpiredNotifier,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: AppConfig.apiBaseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
           sendTimeout: const Duration(seconds: 10),
           headers: const {'Content-Type': 'application/json'},
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isLoginRequest = options.path == '/auth/login';

          if (!isLoginRequest) {
            final token = await secureStorageService.readAccessToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isLoginRequest = error.requestOptions.path == '/auth/login';
          final isUnauthorized = error.response?.statusCode == 401;

          if (isUnauthorized && !isLoginRequest) {
            await secureStorageService.deleteAccessToken();

            sessionExpiredNotifier.notifySessionExpired();
          }

          handler.next(error);
        },
      ),
    );
  }
  final Dio dio;
}
