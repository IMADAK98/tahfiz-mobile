import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/theme/app_colors.dart';
import 'package:thafiz_teacher/features/halaqa/data/attendance_status.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';

void main() {
  group('parseNestAttendanceStatus', () {
    test('unmarked / null / holiday stay null — not حاضر', () {
      expect(parseNestAttendanceStatus(null), isNull);
      expect(parseNestAttendanceStatus(''), isNull);
      expect(parseNestAttendanceStatus('NOT_MARKED'), isNull);
      expect(parseNestAttendanceStatus('null'), isNull);
      expect(parseNestAttendanceStatus('HOLIDAY'), isNull);
    });

    test('keeps Nest PRESENT / ABSENT / LATE / LEAVE', () {
      expect(parseNestAttendanceStatus('PRESENT'), NestAttendanceStatus.present);
      expect(parseNestAttendanceStatus('ABSENT'), NestAttendanceStatus.absent);
      expect(parseNestAttendanceStatus('LATE'), NestAttendanceStatus.late);
      expect(parseNestAttendanceStatus('LEAVE'), NestAttendanceStatus.leave);
      expect(parseNestAttendanceStatus('EXCUSED'), NestAttendanceStatus.leave);
    });
  });

  group('canRecordDailyProgress', () {
    test('PRESENT and LATE only', () {
      expect(canRecordDailyProgress('PRESENT'), isTrue);
      expect(canRecordDailyProgress('LATE'), isTrue);
      expect(canRecordDailyProgress('ABSENT'), isFalse);
      expect(canRecordDailyProgress('LEAVE'), isFalse);
      expect(canRecordDailyProgress('NOT_MARKED'), isFalse);
      expect(canRecordDailyProgress(null), isFalse);
      expect(canRecordDailyProgress('HOLIDAY'), isFalse);
    });

    test('blocked copy matches unmarked vs absent vs excused', () {
      expect(
        dailyProgressBlockedMessage('NOT_MARKED'),
        'سجّل الحضور أولاً قبل تسجيل التقدّم',
      );
      expect(
        dailyProgressBlockedMessage('ABSENT'),
        'لا يُسجَّل تقدّم للطالب الغائب',
      );
      expect(
        dailyProgressBlockedMessage('LEAVE'),
        'لا يُسجَّل تقدّم للطالب المعذور',
      );
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
    test('NOT_MARKED stays raw and is not treated as حاضر', () {
      final s = HalaqaStudent.fromJson({
        'id': 1001,
        'userId': 15,
        'name': 'أحمد',
        'attendance': {'status': 'NOT_MARKED'},
      });
      expect(s.id, '15');
      expect(s.attendanceStatus, 'NOT_MARKED');
      expect(s.isPresent, isFalse);
      expect(parseNestAttendanceStatus(s.attendanceStatus), isNull);
      expect(attendanceLabelAr(null), 'لم يُعلَّم');
    });
  });
}
