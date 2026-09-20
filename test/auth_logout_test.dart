import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/auth/data/auth_api.dart';
import 'package:thafiz_teacher/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.logout', () {
    test('calls API with refresh token then clears session', () async {
      final api = _FakeAuthApi();
      final storage = _FakeStorage()..refresh = 'refresh-1';
      final repo = AuthRepository(api: api, storage: storage);

      await repo.logout();

      expect(api.logoutCalled, isTrue);
      expect(api.refreshToken, 'refresh-1');
      expect(storage.cleared, isTrue);
    });

    test('clears session even when API logout fails', () async {
      final api = _FakeAuthApi()..fail = true;
      final storage = _FakeStorage()..refresh = 'refresh-1';
      final repo = AuthRepository(api: api, storage: storage);

      await repo.logout();

      expect(api.logoutCalled, isTrue);
      expect(storage.cleared, isTrue);
    });
  });
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());

  bool logoutCalled = false;
  bool fail = false;
  String? refreshToken;

  @override
  Future<Response<dynamic>> logout({String? refreshToken}) async {
    logoutCalled = true;
    this.refreshToken = refreshToken;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: 'auth/logout'),
      );
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: 'auth/logout'),
      statusCode: 200,
    );
  }
}

class _FakeStorage extends SecureStorageService {
  _FakeStorage() : super(const FlutterSecureStorage());

  String? refresh;
  bool cleared = false;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> clearTokens() async {
    cleared = true;
    refresh = null;
  }
}
