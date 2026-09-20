import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'auth_api.dart';
import 'dto/center_option.dart';
import 'dto/create_pending_teacher_request.dart';
import 'dto/login_response.dart';

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

  /// Nest `errors[{fieldName,message}]` — first/joined message per field.
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

String nestErrorMessage(Object error) {
  if (error is AuthException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((e) => e.toString()).join('\n');
      }
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  return error.toString();
}

/// Parse Nest `{ errors: [{ fieldName, message }] }` (and AuthException).
Map<String, String> nestFieldErrors(Object error) {
  if (error is AuthException) return error.fieldErrors;
  if (error is DioException) {
    return _fieldErrorsFromData(error.response?.data);
  }
  return const {};
}

Map<String, String> _fieldErrorsFromData(dynamic data) {
  if (data is! Map) return const {};
  final errors = data['errors'];
  if (errors is! List) return const {};
  final collected = <String, List<String>>{};
  for (final item in errors) {
    if (item is! Map) continue;
    final name = item['fieldName']?.toString() ?? '';
    final message = item['message']?.toString() ?? '';
    if (name.isEmpty || message.isEmpty) continue;
    collected.putIfAbsent(name, () => []).add(message);
  }
  if (collected.isEmpty) return const {};
  return collected.map((key, value) => MapEntry(key, value.join('\n')));
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
      throw AuthException(nestErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await storage.readRefreshToken();
      await api.logout(refreshToken: refreshToken);
    } catch (_) {
      // Always clear local session so the teacher can leave even if the API fails.
    } finally {
      await storage.clearTokens();
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await api.requestPasswordReset(email: email);
    } on DioException catch (e) {
      throw AuthException(nestErrorMessage(e));
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
      throw AuthException(nestErrorMessage(e));
    }
  }

  Future<bool> hasAccessToken() async {
    final token = await storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<List<CenterOption>> listCenters() async {
    try {
      final res = await api.getCenters();
      return _parseCenters(res.data);
    } on DioException catch (e) {
      throw AuthException(nestErrorMessage(e), fieldErrors: nestFieldErrors(e));
    }
  }

  Future<void> submitPendingTeacherRequest(
    CreatePendingTeacherRequestDto dto,
  ) async {
    try {
      await api.pendingTeacherRequest(dto.toJson());
    } on DioException catch (e) {
      throw AuthException(
        nestErrorMessage(e),
        fieldErrors: nestFieldErrors(e),
      );
    }
  }

  static List<CenterOption> _parseCenters(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      list = raw['data'] ?? raw['centers'] ?? raw['items'];
    }
    if (list is! List) return const [];
    final out = <CenterOption>[];
    for (final item in list) {
      if (item is! Map) continue;
      final option = CenterOption.fromJson(Map<String, dynamic>.from(item));
      if (option.id <= 0 || option.name.isEmpty) continue;
      final active = item['isActive'];
      if (active == false) continue;
      out.add(option);
    }
    return out;
  }
}