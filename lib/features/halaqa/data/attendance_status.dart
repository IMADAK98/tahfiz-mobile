import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Nest attendance enums used by chips (LEAVE → معذور label only).
enum NestAttendanceStatus { present, absent, late, leave }

extension NestAttendanceStatusX on NestAttendanceStatus {
  String get apiValue => switch (this) {
        NestAttendanceStatus.present => 'PRESENT',
        NestAttendanceStatus.absent => 'ABSENT',
        NestAttendanceStatus.late => 'LATE',
        NestAttendanceStatus.leave => 'LEAVE',
      };

  String get labelAr => switch (this) {
        NestAttendanceStatus.present => 'حاضر',
        NestAttendanceStatus.absent => 'غائب',
        NestAttendanceStatus.late => 'متأخر',
        NestAttendanceStatus.leave => 'معذور',
      };

  /// PRESENT → ABSENT → LATE → LEAVE → PRESENT.
  NestAttendanceStatus get next => switch (this) {
        NestAttendanceStatus.present => NestAttendanceStatus.absent,
        NestAttendanceStatus.absent => NestAttendanceStatus.late,
        NestAttendanceStatus.late => NestAttendanceStatus.leave,
        NestAttendanceStatus.leave => NestAttendanceStatus.present,
      };

  Color get cardBackground => switch (this) {
        NestAttendanceStatus.present => AppColors.presentSoft,
        NestAttendanceStatus.absent => AppColors.absentSoft,
        NestAttendanceStatus.late => AppColors.lateSoft,
        NestAttendanceStatus.leave => AppColors.excusedSoft,
      };

  Color get accent => switch (this) {
        NestAttendanceStatus.present => AppColors.brand,
        NestAttendanceStatus.absent => AppColors.absent,
        NestAttendanceStatus.late => AppColors.murajaa,
        NestAttendanceStatus.leave => AppColors.excused,
      };
}

/// Real Nest status, or null when unmarked / unknown.
NestAttendanceStatus? parseNestAttendanceStatus(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toUpperCase();
  if (s.isEmpty || s == 'NOT_MARKED' || s == 'HOLIDAY' || s == 'NULL') {
    return null;
  }
  return switch (s) {
    'PRESENT' => NestAttendanceStatus.present,
    'ABSENT' => NestAttendanceStatus.absent,
    'LATE' => NestAttendanceStatus.late,
    'LEAVE' || 'EXCUSED' => NestAttendanceStatus.leave,
    _ => null,
  };
}

/// Daily progress write: committed حاضر or متأخر only.
bool canRecordDailyProgress(String? raw) {
  final s = parseNestAttendanceStatus(raw);
  return s == NestAttendanceStatus.present || s == NestAttendanceStatus.late;
}

String dailyProgressBlockedMessage(String? raw) {
  final s = parseNestAttendanceStatus(raw);
  return switch (s) {
    NestAttendanceStatus.absent => 'لا يُسجَّل تقدّم للطالب الغائب',
    NestAttendanceStatus.leave => 'لا يُسجَّل تقدّم للطالب المعذور',
    _ => 'سجّل الحضور أولاً قبل تسجيل التقدّم',
  };
}

const unmarkedAttendanceLabel = 'لم يُعلَّم';

String attendanceLabelAr(NestAttendanceStatus? status) =>
    status?.labelAr ?? unmarkedAttendanceLabel;
