import 'package:dio/dio.dart';

import '../errors/network_exception.dart';

NetworkException mapDioException(DioException error) {
  final statusCode = error.response?.statusCode;

  if (statusCode == 401) {
    return NetworkException(
      type: NetworkErrorType.unauthorized,
      statusCode: statusCode,
    );
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return NetworkException(
        type: NetworkErrorType.timeout,
        statusCode: statusCode,
      );

    case DioExceptionType.connectionError:
      return NetworkException(
        type: NetworkErrorType.connection,
        statusCode: statusCode,
      );

    case DioExceptionType.badResponse:
      return NetworkException(
        type: NetworkErrorType.badResponse,
        statusCode: statusCode,
      );

    case DioExceptionType.cancel:
      return NetworkException(
        type: NetworkErrorType.cancelled,
        statusCode: statusCode,
      );

    case DioExceptionType.badCertificate:
      return NetworkException(
        type: NetworkErrorType.badCertificate,
        statusCode: statusCode,
      );

    case DioExceptionType.unknown:
      return NetworkException(
        type: NetworkErrorType.unknown,
        statusCode: statusCode,
      );
  }
}
