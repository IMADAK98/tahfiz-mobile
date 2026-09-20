import 'package:dio/dio.dart';

import '../../../core/network/api_paths.dart';

/// Low-level auth HTTP client against Nest `/auth/*` contracts.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> login({
    required String email,
    required String password,
  }) {
    return _dio.post(
      ApiPaths.login,
      data: {'email': email, 'password': password},
    );
  }

  Future<Response<dynamic>> logout({String? refreshToken}) {
    return _dio.post(
      ApiPaths.logout,
      data: refreshToken == null || refreshToken.isEmpty
          ? null
          : {'refreshToken': refreshToken},
    );
  }

  Future<Response<dynamic>> refresh({required String refreshToken}) {
    return _dio.post(
      ApiPaths.refresh,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<Response<dynamic>> requestPasswordReset({required String email}) {
    return _dio.post(
      ApiPaths.requestPasswordReset,
      data: {'email': email},
    );
  }

  Future<Response<dynamic>> resetPassword({
    required String code,
    required String email,
    required String newPassword,
  }) {
    return _dio.post(
      ApiPaths.resetPassword,
      data: {
        'code': code,
        'email': email,
        'newPassword': newPassword,
      },
    );
  }

  Future<Response<dynamic>> pendingTeacherRequest(Map<String, dynamic> body) {
    return _dio.post(ApiPaths.pendingTeacherRequest, data: body);
  }

  Future<Response<dynamic>> register(Map<String, dynamic> body) {
    return _dio.post(ApiPaths.register, data: body);
  }

  /// Public `GET /center` for signup مركز العمل.
  Future<Response<dynamic>> getCenters() {
    return _dio.get(ApiPaths.centers);
  }
}
