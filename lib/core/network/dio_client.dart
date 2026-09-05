import 'package:dio/dio.dart';

import '../config/app_config.dart';

final class DioClient {
  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: const {'Content-Type': 'application/json'},
        ),
      );
  final Dio dio;
}
