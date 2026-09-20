import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/features/auth/data/dto/center_option.dart';
import 'package:thafiz_teacher/features/auth/data/dto/create_pending_teacher_request.dart';
import 'package:thafiz_teacher/features/auth/data/dto/nest_field_errors.dart';

void main() {
  group('birthDateToIso', () {
    test('passes through ISO dates', () {
      expect(birthDateToIso('2026-09-20'), '2026-09-20');
    });

    test('converts DD-MM-YYYY mock display to ISO', () {
      expect(birthDateToIso('20-09-2026'), '2026-09-20');
      expect(birthDateToIso('5-1-1990'), '1990-01-05');
    });

    test('rejects empty / garbage', () {
      expect(birthDateToIso(''), isNull);
      expect(birthDateToIso('not-a-date'), isNull);
    });
  });

  group('Nest teachingAgeGroup mapping', () {
    test('primary 6-11 expands to PRIMARY_LOWER + PRIMARY_UPPER', () {
      expect(
        nestTeachingAgeGroups({UiTeachingAge.primary611}),
        ['PRIMARY_LOWER', 'PRIMARY_UPPER'],
      );
    });

    test('maps remaining mock chips 1:1', () {
      expect(
        nestTeachingAgeGroups({
          UiTeachingAge.middle1214,
          UiTeachingAge.high1517,
          UiTeachingAge.university1822,
          UiTeachingAge.adults23,
        }),
        ['MIDDLE_SCHOOL', 'HIGH_SCHOOL', 'UNIVERSITY', 'ADULTS'],
      );
    });
  });

  group('Nest availableWorkPeriod mapping', () {
    test('maps all five mock periods', () {
      expect(
        nestWorkPeriods(UiWorkPeriod.values),
        [
          'WEEKDAYS',
          'AFTER_FAJR',
          'AFTER_ASR',
          'AFTER_MAGHRIB',
          'AFTER_ISHA',
        ],
      );
    });
  });

  group('CreatePendingTeacherRequest.toJson', () {
    test('emits Nest field names 1:1', () {
      final body = CreatePendingTeacherRequest(
        teacherName: 'أحمد',
        email: 'a@b.com',
        password: 'password1',
        nationality: 'السعودية',
        phone: '+966500000000',
        address: 'الرياض',
        birthDate: '1990-01-05',
        qualification: 'DIPLOMA',
        hasCertificate: true,
        numberOfMemorizedJuz: 2,
        hasIjazahInHifz: false,
        hasSanadInHifz: true,
        tajweedLevel: 'ADVANCED',
        teachingAgeGroup: const ['PRIMARY_LOWER', 'PRIMARY_UPPER'],
        availableWorkPeriod: const ['WEEKDAYS', 'AFTER_FAJR'],
        centerId: 1,
      );

      expect(body.toJson(), {
        'teacherName': 'أحمد',
        'email': 'a@b.com',
        'password': 'password1',
        'nationality': 'السعودية',
        'phone': '+966500000000',
        'address': 'الرياض',
        'birthDate': '1990-01-05',
        'qualification': 'DIPLOMA',
        'hasCertificate': true,
        'numberOfMemorizedJuz': 2,
        'hasIjazahInHifz': false,
        'hasSanadInHifz': true,
        'tajweedLevel': 'ADVANCED',
        'teachingAgeGroup': ['PRIMARY_LOWER', 'PRIMARY_UPPER'],
        'availableWorkPeriod': ['WEEKDAYS', 'AFTER_FAJR'],
        'centerId': 1,
      });
    });
  });

  group('NestFieldErrors.parse', () {
    test('maps errors[].fieldName under inputs', () {
      final parsed = NestFieldErrors.parse({
        'statusCode': 400,
        'error': 'Bad Request',
        'message': 'Validation failed',
        'errors': [
          {'fieldName': 'email', 'message': 'email must be an email'},
          {'fieldName': 'email', 'message': 'duplicate ignored'},
          {'fieldName': 'password', 'message': 'password is too short'},
        ],
      });

      expect(parsed.message, 'Validation failed');
      expect(parsed.byField['email'], 'email must be an email');
      expect(parsed.byField['password'], 'password is too short');
    });

    test('handles message-only 400 (duplicate request)', () {
      final parsed = NestFieldErrors.parse({
        'statusCode': 400,
        'message': 'طلب تسجيل مسبق موجود لهذا البريد',
      });
      expect(parsed.byField, isEmpty);
      expect(parsed.message, contains('طلب تسجيل'));
    });
  });

  group('parseCentersResponse', () {
    test('unwraps {status,data:[...]}', () {
      final centers = parseCentersResponse({
        'status': 200,
        'data': [
          {'id': 2, 'name': 'Simon test'},
          {'id': 1, 'name': 'مركز 1'},
        ],
      });
      expect(centers.map((c) => c.name), ['Simon test', 'مركز 1']);
      expect(centers.first.id, 2);
    });
  });
}
