import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/theme/app_colors.dart';
import 'package:thafiz_teacher/features/halaqa/data/attendance_status.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';

void main() {
  group('displayAttendanceStatus', () {
    test('defaults NOT_MARKED / null / empty to PRESENT', () {
      expect(displayAttendanceStatus(null), NestAttendanceStatus.present);
      expect(displayAttendanceStatus(''), NestAttendanceStatus.present);
      expect(displayAttendanceStatus('NOT_MARKED'), NestAttendanceStatus.present);
      expect(displayAttendanceStatus('null'), NestAttendanceStatus.present);
      expect(displayAttendanceStatus('HOLIDAY'), NestAttendanceStatus.present);
    });

    test('keeps Nest PRESENT / ABSENT / LATE / LEAVE', () {
      expect(displayAttendanceStatus('PRESENT'), NestAttendanceStatus.present);
      expect(displayAttendanceStatus('ABSENT'), NestAttendanceStatus.absent);
      expect(displayAttendanceStatus('LATE'), NestAttendanceStatus.late);
      expect(displayAttendanceStatus('LEAVE'), NestAttendanceStatus.leave);
      expect(displayAttendanceStatus('EXCUSED'), NestAttendanceStatus.leave);
    });

    test('parseNestAttendanceStatus leaves unmarked as null (POST heuristic)', () {
      expect(parseNestAttendanceStatus(null), isNull);
      expect(parseNestAttendanceStatus('NOT_MARKED'), isNull);
      expect(parseNestAttendanceStatus('PRESENT'), NestAttendanceStatus.present);
    });
  });

  group('NestAttendanceStatus.next', () {
    test('cycles PRESENT → ABSENT → LATE → LEAVE → PRESENT', () {
      expect(NestAttendanceStatus.present.next, NestAttendanceStatus.absent);
      expect(NestAttendanceStatus.absent.next, NestAttendanceStatus.late);
      expect(NestAttendanceStatus.late.next, NestAttendanceStatus.leave);
      expect(NestAttendanceStatus.leave.next, NestAttendanceStatus.present);
    });

    test('Arabic chips: LEAVE is معذور', () {
      expect(NestAttendanceStatus.present.labelAr, 'حاضر');
      expect(NestAttendanceStatus.absent.labelAr, 'غائب');
      expect(NestAttendanceStatus.late.labelAr, 'متأخر');
      expect(NestAttendanceStatus.leave.labelAr, 'معذور');
      expect(NestAttendanceStatus.leave.apiValue, 'LEAVE');
    });
  });

  group('visuals reuse AppColors', () {
    test('حاضر is soft light-green; others use distinct accents', () {
      expect(
        NestAttendanceStatus.present.cardBackground,
        AppColors.presentSoft,
      );
      expect(NestAttendanceStatus.present.accent, AppColors.brand);
      expect(
        NestAttendanceStatus.absent.cardBackground,
        AppColors.absentSoft,
      );
      expect(NestAttendanceStatus.absent.accent, AppColors.absent);
      expect(NestAttendanceStatus.late.cardBackground, AppColors.lateSoft);
      expect(NestAttendanceStatus.late.accent, AppColors.murajaa);
      expect(
        NestAttendanceStatus.leave.cardBackground,
        AppColors.excusedSoft,
      );
      expect(NestAttendanceStatus.leave.accent, AppColors.excused);
    });
  });

  group('HalaqaStudent raw Nest vs UI default', () {
    test('NOT_MARKED stays raw (userId parse untouched) while UI defaults PRESENT', () {
      final s = HalaqaStudent.fromJson({
        'id': 1001,
        'userId': 15,
        'name': 'أحمد',
        'attendance': {'status': 'NOT_MARKED'},
      });
      expect(s.id, '15');
      expect(s.attendanceStatus, 'NOT_MARKED');
      expect(s.isPresent, isFalse);
      expect(displayAttendanceStatus(s.attendanceStatus), NestAttendanceStatus.present);
    });
  });
}
