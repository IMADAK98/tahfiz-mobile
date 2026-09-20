/// Locked attendance chips: حاضر / غائب / متأخر / معذور (LEAVE→معذور).
enum AttendanceMark { present, absent, late, leave }

extension AttendanceMarkX on AttendanceMark {
  String get apiValue => switch (this) {
        AttendanceMark.present => 'PRESENT',
        AttendanceMark.absent => 'ABSENT',
        AttendanceMark.late => 'LATE',
        AttendanceMark.leave => 'LEAVE',
      };

  String get labelAr => switch (this) {
        AttendanceMark.present => 'حاضر',
        AttendanceMark.absent => 'غائب',
        AttendanceMark.late => 'متأخر',
        AttendanceMark.leave => 'معذور',
      };

  static AttendanceMark? tryParse(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toUpperCase();
    if (s.isEmpty || s == 'NOT_MARKED' || s == 'HOLIDAY' || s == 'NULL') {
      return null;
    }
    return switch (s) {
      'PRESENT' => AttendanceMark.present,
      'ABSENT' => AttendanceMark.absent,
      'LATE' => AttendanceMark.late,
      'LEAVE' || 'EXCUSED' => AttendanceMark.leave,
      _ => null,
    };
  }
}

/// One student row on the ḥalaqa detail roster (defensive Nest parsing).
class HalaqaStudent {
  const HalaqaStudent({
    required this.id,
    required this.name,
    this.attendanceStatus,
    this.hifzPercent = 0,
    this.tathbeetPercent = 0,
    this.murajaaPercent = 0,
    this.hasProgressToday = false,
  });

  final String id;
  final String name;

  /// Raw Nest attendance enum: PRESENT / ABSENT / LATE / LEAVE / NOT_MARKED / …
  final String? attendanceStatus;

  final double hifzPercent;
  final double tathbeetPercent;
  final double murajaaPercent;

  /// Date-scoped roster hint for «تم اليوم» vs «لم يُسجَّل اليوم».
  final bool hasProgressToday;

  bool get isPresent {
    final s = attendanceStatus?.toUpperCase().trim();
    return s == 'PRESENT';
  }

  AttendanceMark? get attendanceMark =>
      AttendanceMarkX.tryParse(attendanceStatus);

  HalaqaStudent copyWith({
    String? attendanceStatus,
    bool? hasProgressToday,
  }) {
    return HalaqaStudent(
      id: id,
      name: name,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      hifzPercent: hifzPercent,
      tathbeetPercent: tathbeetPercent,
      murajaaPercent: murajaaPercent,
      hasProgressToday: hasProgressToday ?? this.hasProgressToday,
    );
  }

  factory HalaqaStudent.fromJson(Map<String, dynamic> json) {
    final nestedUser = _asMap(json['user']);
    final nestedStudent = _asMap(json['student']);

    // Nest attendance/progress expect User.id. Roster `id` is often the
    // enrollment / ḥalaqa-student row, which bulk `students[].userId` rejects.
    final id = _firstNonEmpty([
      json['userId'],
      json['user_id'],
      nestedUser?['id'],
      json['studentId'],
      json['student_id'],
      nestedStudent?['studentId'],
      nestedStudent?['userId'],
      nestedStudent?['id'],
      json['id'],
    ]) ?? '';

    final name = _firstNonEmpty([
      json['name'],
      json['fullName'],
      json['full_name'],
      json['studentName'],
      json['student_name'],
      nestedStudent?['name'],
      nestedStudent?['fullName'],
      nestedUser?['name'],
      nestedUser?['fullName'],
    ]) ?? 'طالب';

    final attendanceStatus = _extractAttendanceStatus(json);
    final percents = _extractPercents(json);

    return HalaqaStudent(
      id: id,
      name: name,
      attendanceStatus: attendanceStatus,
      hifzPercent: percents.$1,
      tathbeetPercent: percents.$2,
      murajaaPercent: percents.$3,
      hasProgressToday: _extractHasProgressToday(json),
    );
  }

  static String? _extractAttendanceStatus(Map<String, dynamic> json) {
    final direct = json['attendanceStatus'] ??
        json['attendance_status'] ??
        json['status'];
    if (direct != null && direct is! Map) {
      final s = direct.toString().trim();
      // Avoid treating HTTP-ish or unrelated status numbers as attendance
      if (s.isNotEmpty &&
          !RegExp(r'^\d+$').hasMatch(s) &&
          s.toUpperCase() != 'SUCCESS') {
        final upper = s.toUpperCase();
        const known = {
          'PRESENT',
          'ABSENT',
          'LATE',
          'LEAVE',
          'EXCUSED',
          'NOT_MARKED',
          'HOLIDAY',
        };
        if (known.contains(upper) ||
            upper.contains('PRESENT') ||
            upper.contains('ABSENT') ||
            upper.contains('LATE') ||
            upper.contains('LEAVE')) {
          return s;
        }
      }
    }

    final attendance = json['attendance'];
    if (attendance is Map) {
      final map = Map<String, dynamic>.from(attendance);
      final nested = map['status'] ??
          map['attendanceStatus'] ??
          map['attendance_status'];
      if (nested != null) return nested.toString().trim();
    } else if (attendance != null && attendance is! Map) {
      final s = attendance.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Roster is already date-scoped; treat explicit progress flags as "today".
  static bool _extractHasProgressToday(Map<String, dynamic> json) {
    bool asBool(dynamic v) {
      if (v == true) return true;
      if (v == false) return false;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    }

    bool fromMap(Map<String, dynamic> map) {
      if (asBool(map['isProgress']) ||
          asBool(map['is_progress']) ||
          asBool(map['hasProgress']) ||
          asBool(map['has_progress']) ||
          asBool(map['recorded']) ||
          asBool(map['isRecorded'])) {
        return true;
      }
      return false;
    }

    final flags = [
      json['hasProgressToday'],
      json['has_progress_today'],
      json['progressRecordedToday'],
      json['progress_recorded_today'],
      json['hasDailyProgress'],
      json['has_daily_progress'],
      json['isProgressToday'],
      json['dailyProgressRecorded'],
      json['isProgress'],
      json['is_progress'],
    ];
    for (final f in flags) {
      if (f != null && asBool(f)) return true;
    }

    final nested = [
      json['dailyProgress'],
      json['daily_progress'],
      json['todayProgress'],
      json['today_progress'],
      json['progressToday'],
      json['progress_today'],
    ];
    for (final n in nested) {
      if (n is Map && fromMap(Map<String, dynamic>.from(n))) return true;
      if (n is List) {
        for (final item in n) {
          if (item is Map && fromMap(Map<String, dynamic>.from(item))) {
            return true;
          }
        }
      }
    }

    final candidates = <dynamic>[
      json['progress'],
      json['progresses'],
      json['studyPlanItems'],
      json['study_plan_items'],
    ];
    for (final c in candidates) {
      if (c is! List) continue;
      for (final item in c) {
        if (item is Map && fromMap(Map<String, dynamic>.from(item))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns (hifz, tathbeet, murajaa) percentages in 0–100.
  static (double, double, double) _extractPercents(Map<String, dynamic> json) {
    var hifz = _asPercent(
      json['hifzProgress'] ??
          json['hifz_progress'] ??
          json['hifzPercentage'] ??
          json['hifz'],
    );
    var tathbeet = _asPercent(
      json['tathbeetProgress'] ??
          json['tathbeet_progress'] ??
          json['retentionProgress'] ??
          json['tathbeetPercentage'] ??
          json['tathbeet'],
    );
    var murajaa = _asPercent(
      json['murajaaProgress'] ??
          json['murajaa_progress'] ??
          json['revisionProgress'] ??
          json['murajaaPercentage'] ??
          json['murajaa'],
    );

    final candidates = <dynamic>[
      json['progress'],
      json['progresses'],
      json['studyPlanItems'],
      json['study_plan_items'],
      json['planItems'],
      json['items'],
      _asMap(json['studyPlan'])?['studyPlanItems'],
      _asMap(json['study_plan'])?['studyPlanItems'],
    ];

    for (final c in candidates) {
      if (c is! List) continue;
      for (final item in c) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = (map['type'] ??
                map['planItemType'] ??
                map['plan_item_type'] ??
                map['planType'] ??
                '')
            .toString()
            .toUpperCase()
            .trim();
        final pct = _asPercent(
          map['completionPercentage'] ??
              map['completion_percentage'] ??
              map['progressPercentage'] ??
              map['progress_percentage'] ??
              map['percentage'] ??
              map['totalPercentage'] ??
              map['total_percentage'] ??
              map['progress'] ??
              map['value'],
        );
        if (type == 'HIFZ' || type == 'MEMORIZATION') {
          hifz = pct;
        } else if (type == 'TATHBEET' || type == 'RETENTION') {
          tathbeet = pct;
        } else if (type == 'MURAJAA' || type == 'REVISION') {
          murajaa = pct;
        }
      }
    }

    return (hifz, tathbeet, murajaa);
  }

  static double _asPercent(dynamic v) {
    if (v == null) return 0;
    if (v is num) {
      final n = v.toDouble();
      if (n > 0 && n <= 1) return (n * 100).clamp(0, 100);
      return n.clamp(0, 100);
    }
    if (v is String) {
      final cleaned = v.replaceAll('%', '').trim();
      final n = double.tryParse(cleaned);
      if (n == null) return 0;
      if (n > 0 && n <= 1) return (n * 100).clamp(0, 100);
      return n.clamp(0, 100);
    }
    return 0;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }
}
