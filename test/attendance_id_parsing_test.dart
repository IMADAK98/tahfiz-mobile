import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

void main() {
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
    test('reads Nest roster snake_case *_percentage', () {
      final s = HalaqaStudent.fromJson({
        'user': {'id': 30, 'name': 'TEST Student PriorTerm'},
        'attendance': {'status': 'PRESENT'},
        'hifz_status': 'INCOMPLETE',
        'hifz_percentage': 0,
        'tathbeet_status': 'COMPLETE',
        'tathbeet_percentage': 119,
        'murajaa_status': 'COMPLETE',
        'murajaa_percentage': 200,
      });
      expect(s.id, '30');
      expect(s.hifzPercent, 0);
      expect(s.tathbeetPercent, 100);
      expect(s.murajaaPercent, 100);
    });

    test('reads reports/progress planItemType + totalPercentage', () {
      final s = HalaqaStudent.fromJson({
        'studentId': 30,
        'studentName': 'TEST Student PriorTerm',
        'progress': [
          {'planItemType': 'HIFZ', 'totalPercentage': 59},
          {'planItemType': 'TATHBEET', 'totalPercentage': 119},
          {'planItemType': 'MURAJAA', 'totalPercentage': 200},
        ],
      });
      expect(s.hifzPercent, 59);
      expect(s.tathbeetPercent, 100);
      expect(s.murajaaPercent, 100);
    });
  });

  group('HomeRepository.mergeReportPercents', () {
    test('overlays term totals onto roster rows by studentId', () {
      const roster = [
        HalaqaStudent(id: '30', name: 'TEST Student PriorTerm'),
      ];
      final merged = HomeRepository.mergeReportPercents(roster, {
        'status': 200,
        'data': {
          'students': [
            {
              'studentId': 30,
              'studentName': 'TEST Student PriorTerm',
              'progress': [
                {'planItemType': 'HIFZ', 'totalPercentage': 59},
                {'planItemType': 'TATHBEET', 'totalPercentage': 119},
                {'planItemType': 'MURAJAA', 'totalPercentage': 200},
              ],
            },
          ],
        },
      });
      expect(merged.single.hifzPercent, 59);
      expect(merged.single.tathbeetPercent, 100);
      expect(merged.single.murajaaPercent, 100);
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
