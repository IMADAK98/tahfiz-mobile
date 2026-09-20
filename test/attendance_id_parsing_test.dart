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
      expect(s.attendanceMark, isNull);
    });

    test('LEAVE and EXCUSED map to معذور', () {
      expect(AttendanceMarkX.tryParse('LEAVE'), AttendanceMark.leave);
      expect(AttendanceMarkX.tryParse('EXCUSED'), AttendanceMark.leave);
      expect(AttendanceMark.leave.labelAr, 'معذور');
    });

    test('parses hasProgressToday from nested dailyProgress.isProgress', () {
      final recorded = HalaqaStudent.fromJson({
        'userId': 1,
        'name': 'خالد',
        'dailyProgress': {'isProgress': true},
      });
      expect(recorded.hasProgressToday, isTrue);

      final none = HalaqaStudent.fromJson({
        'userId': 2,
        'name': 'سارة',
      });
      expect(none.hasProgressToday, isFalse);
    });
  });

  group('HomeRepository.isCreateAttendanceStatus', () {
    test('unmarked statuses create; PRESENT/ABSENT/LATE/LEAVE update', () {
      expect(HomeRepository.isCreateAttendanceStatus(null), isTrue);
      expect(HomeRepository.isCreateAttendanceStatus('NOT_MARKED'), isTrue);
      expect(HomeRepository.isCreateAttendanceStatus('HOLIDAY'), isTrue);
      expect(HomeRepository.isCreateAttendanceStatus('PRESENT'), isFalse);
      expect(HomeRepository.isCreateAttendanceStatus('LEAVE'), isFalse);
    });
  });
}
