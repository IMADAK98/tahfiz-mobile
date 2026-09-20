import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/features/auth/data/auth_repository.dart';
import 'package:thafiz_teacher/features/auth/data/dto/create_pending_teacher_request.dart';
import 'package:thafiz_teacher/features/auth/data/teacher_signup_options.dart';

void main() {
  group('CreatePendingTeacherRequestDto', () {
    test('toJson keys match OpenAPI CreatePendingTeacherRequestDto 1:1', () {
      const dto = CreatePendingTeacherRequestDto(
        teacherName: 'تحفيظ',
        email: 'a@b.com',
        password: 'password1',
        nationality: 'أفغانستان',
        phone: '+558 89 965 5',
        address: 'yyrrdd',
        birthDate: '20-09-2026',
        qualification: 'DIPLOMA',
        hasCertificate: true,
        numberOfMemorizedJuz: 2,
        hasIjazahInHifz: true,
        hasSanadInHifz: true,
        tajweedLevel: 'ADVANCED',
        teachingAgeGroup: ['PRIMARY_LOWER'],
        availableWorkPeriod: ['WEEKDAYS', 'AFTER_FAJR'],
        centerId: 2,
      );

      expect(dto.toJson().keys.toSet(), {
        'teacherName',
        'email',
        'password',
        'nationality',
        'phone',
        'address',
        'birthDate',
        'qualification',
        'hasCertificate',
        'numberOfMemorizedJuz',
        'hasIjazahInHifz',
        'hasSanadInHifz',
        'tajweedLevel',
        'teachingAgeGroup',
        'availableWorkPeriod',
        'centerId',
      });
      expect(dto.toJson()['centerId'], 2);
      expect(dto.toJson()['numberOfMemorizedJuz'], 2);
      expect(dto.toJson()['hasCertificate'], isTrue);
    });
  });

  group('teacher signup option maps', () {
    test('qualification labels match locked HTML', () {
      expect(qualificationOptions.map((o) => o.label).toList(), [
        'الدبلوم',
        'ثانوية',
        'بكالوريوس',
        'ماجستير',
        'دكتوراه',
        'أخرى',
      ]);
      expect(qualificationOptions.map((o) => o.value).toList(), [
        'DIPLOMA',
        'HIGH_SCHOOL',
        'BACHELOR',
        'MASTER',
        'PHD',
        'OTHER',
      ]);
    });

    test('tajweed values stay on Nest enum', () {
      expect(tajweedLevelOptions.map((o) => o.value).toSet(), {
        'BEGINNER',
        'INTERMEDIATE',
        'ADVANCED',
      });
    });

    test('age / work period labels match locked HTML', () {
      expect(teachingAgeGroupOptions.first.label, 'الابتدائية (6-11 سنوات)');
      expect(teachingAgeGroupOptions.last.label, 'الكبار (23 فما أعلى)');
      expect(availableWorkPeriodOptions.first.value, 'WEEKDAYS');
      expect(availableWorkPeriodOptions.first.label,
          'أيام العمل الأسبوعية (من الأحد حتى الخميس)');
    });

    test('formatSignupBirthDate is dd-MM-yyyy', () {
      expect(formatSignupBirthDate(DateTime(2026, 9, 20)), '20-09-2026');
    });
  });

  group('nestFieldErrors', () {
    test('maps Nest errors[{fieldName,message}] and joins duplicates', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/pending-teacher-request'),
        response: Response(
          requestOptions: RequestOptions(path: '/pending-teacher-request'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message': 'Validation failed',
            'errors': [
              {'fieldName': 'email', 'message': 'حقل email مطلوب'},
              {'fieldName': 'email', 'message': 'يجب أن يكون email نصاً'},
              {'fieldName': 'centerId', 'message': 'حقل centerId مطلوب'},
            ],
          },
        ),
      );

      final fields = nestFieldErrors(err);
      expect(fields['email'], 'حقل email مطلوب\nيجب أن يكون email نصاً');
      expect(fields['centerId'], 'حقل centerId مطلوب');
      expect(firstSignupStepForFields(fields), 0);
      expect(firstSignupStepForFields({'centerId': 'x'}), 1);
      expect(firstSignupStepForFields({'birthDate': 'x'}), 2);
      expect(firstSignupStepForFields({'teachingAgeGroup': 'x'}), 3);
    });
  });
}
