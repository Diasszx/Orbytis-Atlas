import 'auth_user.dart';

final class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid user data');
    }

    return LoginResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      user: AuthUser.fromJson(userJson),
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;
}
