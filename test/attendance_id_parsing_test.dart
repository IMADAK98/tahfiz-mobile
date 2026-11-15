import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

class _FakeRosterApi extends HomeApi {
  _FakeRosterApi(this.rowByDate) : super(Dio());

  final Map<String, Map<String, dynamic>> rowByDate;
  var reportCalls = 0;

  @override
  Future<Response<dynamic>> getStudentsByHalqaId(
    String halaqaId, {
    required String date,
  }) async =>
      Response<dynamic>(
        requestOptions: RequestOptions(path: '/halqa/students'),
        data: {
          'data': [
            {
              'user': {'id': 30, 'name': 'طالب'},
              'term': {'startDate': '2026-09-10'},
              ...rowByDate[date]!,
            },
          ],
        },
      );

  @override
  Future<Response<dynamic>> getProgressReport({
    required String halaqaId,
    required String startingDate,
    required String endingDate,
  }) async {
    reportCalls++;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/reports/progress'),
      data: {
        'data': {
          'students': [
            {
              'studentId': 30,
              'progress': [
                {'planItemType': 'HIFZ', 'totalPercentage': 77},
              ],
            },
          ],
        },
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => FlutterSecureStorage.setMockInitialValues({}));

  group('HomeRepository.extractTermId', () {
    test('reads Nest GetHalqaDto assignedToTermId', () {
      expect(
        HomeRepository.extractTermId({'assignedToTermId': 42}),
        '42',
      );
      expect(
        HomeRepository.extractTermId({'assigned_to_term_id': '7'}),
        '7',
      );
    });

    test('falls back to termId / nested term', () {
      expect(HomeRepository.extractTermId({'termId': 3}), '3');
      expect(
        HomeRepository.extractTermId({
          'term': {'id': 9},
        }),
        '9',
      );
    });

    test('prefers assignedToTermId over termId', () {
      expect(
        HomeRepository.extractTermId({
          'assignedToTermId': 11,
          'termId': 99,
        }),
        '11',
      );
    });
  });

  group('HalaqaStudent.fromJson userId', () {
    test('prefers userId over enrollment id', () {
      final s = HalaqaStudent.fromJson({
        'id': 1001,
        'userId': 15,
        'name': 'أحمد',
      });
      expect(s.id, '15');
    });

    test('prefers nested user.id over top-level id', () {
      final s = HalaqaStudent.fromJson({
        'id': 1001,
        'user': {'id': 22, 'name': 'سارة'},
      });
      expect(s.id, '22');
      expect(s.name, 'سارة');
    });

    test('keeps nested attendance.status including NOT_MARKED', () {
      final s = HalaqaStudent.fromJson({
        'userId': 8,
        'name': 'علي',
        'attendance': {'status': 'NOT_MARKED'},
      });
      expect(s.id, '8');
      expect(s.attendanceStatus, 'NOT_MARKED');
      expect(s.isPresent, isFalse);
    });
  });

  group('HalaqaStudent.fromJson percents', () {
    test('reads Nest roster snake_case *_percentage uncapped', () {
      final s = HalaqaStudent.fromJson({
        'user': {'id': 30, 'name': 'TEST Student PriorTerm'},
        'attendance': {'status': 'PRESENT'},
        'hifz_status': 'INCOMPLETE',
        'hifz_percentage': 0,
        'tathbeet_status': 'COMPLETE',
        'tathbeet_percentage': 115,
        'murajaa_status': 'COMPLETE',
        'murajaa_percentage': 200,
      });
      expect(s.id, '30');
      expect(s.hifzPercent, 0);
      expect(s.tathbeetPercent, 115);
      expect(s.murajaaPercent, 200);
    });

    test('null stays null; small values are not treated as fractions', () {
      final s = HalaqaStudent.fromJson({
        'userId': 31,
        'hifz_percentage': 0.5,
        'tathbeet_percentage': null,
        'murajaa_percentage': '1',
      });
      expect(s.hifzPercent, 0.5);
      expect(s.tathbeetPercent, isNull);
      expect(s.murajaaPercent, 1);
    });
  });

  group('HomeRepository.getStudentsByHalqaId daily %', () {
    test('returns that day roster % and never calls reports/progress', () async {
      final api = _FakeRosterApi({
        '2026-09-20': {'hifz_percentage': 59, 'attendance': {'status': 'PRESENT'}},
        '2026-09-21': {'hifz_percentage': 0, 'attendance': {'status': 'ABSENT'}},
      });
      final repo = HomeRepository(
        api: api,
        storage: SecureStorageService(const FlutterSecureStorage()),
      );

      final day1 = await repo.getStudentsByHalqaId(halaqaId: '16', date: '2026-09-20');
      final day2 = await repo.getStudentsByHalqaId(halaqaId: '16', date: '2026-09-21');

      expect(day1.single.hifzPercent, 59);
      expect(day2.single.hifzPercent, 0);
      expect(api.reportCalls, 0);
    });
  });

  group('ProgressAttendanceException', () {
    RequestOptions opts() => RequestOptions(path: '/student-daily-progress');

    test('parses 409 ATTENDANCE_REQUIRED', () {
      final parsed = ProgressAttendanceException.tryParse(
        DioException(
          requestOptions: opts(),
          response: Response<dynamic>(
            requestOptions: opts(),
            statusCode: 409,
            data: {
              'statusCode': 409,
              'message': 'سجّل الحضور قبل تسجيل التقدّم',
              'error': 'Conflict',
              'code': 'ATTENDANCE_REQUIRED',
              'attendanceStatus': 'NOT_MARKED',
            },
          ),
        ),
      );
      expect(parsed, isNotNull);
      expect(parsed!.code, 'ATTENDANCE_REQUIRED');
      expect(parsed.attendanceStatus, 'NOT_MARKED');
    });

    test('ignores other 409 bodies (create/update conflict)', () {
      expect(
        ProgressAttendanceException.tryParse(
          DioException(
            requestOptions: opts(),
            response: Response<dynamic>(
              requestOptions: opts(),
              statusCode: 409,
              data: {'message': 'already exists'},
            ),
          ),
        ),
        isNull,
      );
    });
  });
}
