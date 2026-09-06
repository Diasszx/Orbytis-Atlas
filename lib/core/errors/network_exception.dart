enum NetworkErrorType {
  unauthorized,
  timeout,
  connection,
  badResponse,
  cancelled,
  badCertificate,
  unknown,
}

final class NetworkException implements Exception {
  const NetworkException({required this.type, this.statusCode, this.message});

  final NetworkErrorType type;
  final String? message;
  final int? statusCode;
}
