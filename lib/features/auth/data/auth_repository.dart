import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'auth_api.dart';
import 'dto/center_option.dart';
import 'dto/create_pending_teacher_request.dart';
import 'dto/login_response.dart';
import 'dto/nest_field_errors.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// Thrown when Nest returns an auth/API error with a user-facing message.
class AuthException implements Exception {
  AuthException(this.message, {this.fieldErrors = const {}});
  final String message;

  /// Nest `errors[].fieldName` → message (teacher signup validation).
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

String nestErrorMessage(Object error) {
  if (error is AuthException) return error.message;
  if (error is DioException) {
    final parsed = NestFieldErrors.parse(error.response?.data);
    if (parsed.message.isNotEmpty) return parsed.message;
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  return error.toString();
}

class AuthRepository {
  AuthRepository({required this.api, required this.storage});

  final AuthApi api;
  final SecureStorageService storage;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await api.login(email: email, password: password);
      final raw = res.data;
      final Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is Map) {
        map = Map<String, dynamic>.from(raw);
      } else {
        throw AuthException('استجابة غير متوقعة من الخادم');
      }

      final parsed = LoginResponse.fromJson(map);
      if (parsed.accessToken.isEmpty || parsed.refreshToken.isEmpty) {
        throw AuthException('لم يتم استلام رموز الدخول');
      }

      await storage.writeTokens(
        accessToken: parsed.accessToken,
        refreshToken: parsed.refreshToken,
      );
      if (parsed.userId != null && parsed.userId!.isNotEmpty) {
        await storage.writeUserId(parsed.userId!);
      }
      return parsed;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      final parsed = NestFieldErrors.parse(e.response?.data);
      throw AuthException(parsed.message, fieldErrors: parsed.byField);
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Always clear local session.
    } finally {
      await storage.clearTokens();
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await api.requestPasswordReset(email: email);
    } on DioException catch (e) {
      final parsed = NestFieldErrors.parse(e.response?.data);
      throw AuthException(parsed.message, fieldErrors: parsed.byField);
    }
  }

  Future<void> resetPassword({
    required String code,
    required String email,
    required String newPassword,
  }) async {
    try {
      await api.resetPassword(
        code: code,
        email: email,
        newPassword: newPassword,
      );
    } on DioException catch (e) {
      final parsed = NestFieldErrors.parse(e.response?.data);
      throw AuthException(parsed.message, fieldErrors: parsed.byField);
    }
  }

  Future<List<CenterOption>> fetchCenters() async {
    try {
      final res = await api.fetchCenters();
      return parseCentersResponse(res.data);
    } on DioException catch (e) {
      final parsed = NestFieldErrors.parse(
        e.response?.data,
        fallback: 'تعذر تحميل المراكز',
      );
      throw AuthException(parsed.message, fieldErrors: parsed.byField);
    }
  }

  /// Public `POST pending-teacher-request` — no auth header required.
  Future<void> submitPendingTeacher(CreatePendingTeacherRequest body) async {
    try {
      await api.pendingTeacherRequest(body.toJson());
    } on DioException catch (e) {
      final parsed = NestFieldErrors.parse(
        e.response?.data,
        fallback: 'تعذر إرسال طلب التسجيل',
      );
      throw AuthException(parsed.message, fieldErrors: parsed.byField);
    }
  }

  Future<bool> hasAccessToken() async {
    final token = await storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
