/// Login API payload. Parses flexibly if tokens are nested under `data`.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String? userId;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data;
    final nested = json['data'];
    if (nested is Map<String, dynamic>) {
      data = nested;
    } else if (nested is Map) {
      data = Map<String, dynamic>.from(nested);
    } else {
      data = json;
    }

    String? asString(dynamic v) => v?.toString();

    final access = asString(data['accessToken']) ??
        asString(data['access_token']) ??
        '';
    final refresh = asString(data['refreshToken']) ??
        asString(data['refresh_token']) ??
        '';
    final userId = asString(data['userId']) ?? asString(data['user_id']);

    return LoginResponse(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
    );
  }
}