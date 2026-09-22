import '../../../home/data/dto/progress_models.dart';

/// Assigned student on a study plan (from details / students payload).
class PlanAssignedStudent {
  const PlanAssignedStudent({required this.id, required this.name});

  final String id;
  final String name;

  factory PlanAssignedStudent.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final nestedStudent = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : null;

    final id = _firstNonEmpty([
          json['userId'],
          json['user_id'],
          nestedUser?['id'],
          json['studentId'],
          json['student_id'],
          nestedStudent?['id'],
          json['id'],
        ]) ??
        '';

    final name = _firstNonEmpty([
          json['name'],
          json['fullName'],
          json['full_name'],
          nestedUser?['name'],
          nestedStudent?['name'],
        ]) ??
        'طالب';

    return PlanAssignedStudent(id: id, name: name);
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}

/// ḥalaqa study plan row from `GET /halqa/study-plans/{id}` (+ optional details).
class HalaqaStudyPlan {
  const HalaqaStudyPlan({
    required this.id,
    required this.name,
    this.studentsCount = 0,
    this.assignedToHalqaId,
    this.items = const [],
    this.students = const [],
    this.detailsLoaded = false,
  });

  final int id;
  final String name;
  final int studentsCount;
  final int? assignedToHalqaId;
  final List<StudyPlanItemRef> items;
  final List<PlanAssignedStudent> students;
  final bool detailsLoaded;

  Set<PlanItemType> get typeSummary {
    final out = <PlanItemType>{};
    for (final item in items) {
      out.add(item.type);
    }
    return out;
  }

  int get displayStudentCount =>
      detailsLoaded ? students.length : studentsCount;

  HalaqaStudyPlan copyWith({
    String? name,
    int? studentsCount,
    List<StudyPlanItemRef>? items,
    List<PlanAssignedStudent>? students,
    bool? detailsLoaded,
  }) {
    return HalaqaStudyPlan(
      id: id,
      name: name ?? this.name,
      studentsCount: studentsCount ?? this.studentsCount,
      assignedToHalqaId: assignedToHalqaId,
      items: items ?? this.items,
      students: students ?? this.students,
      detailsLoaded: detailsLoaded ?? this.detailsLoaded,
    );
  }

  factory HalaqaStudyPlan.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final id = asInt(json['id']) ?? 0;
    final name = (json['name'] ?? json['planName'] ?? '').toString().trim();
    final studentsCount = asInt(
          json['studentsCount'] ??
              json['students_count'] ??
              json['studentCount'],
        ) ??
        0;

    final itemsRaw = json['studyPlanItems'] ??
        json['study_plan_items'] ??
        json['items'];
    final items = <StudyPlanItemRef>[];
    if (itemsRaw is List) {
      for (final raw in itemsRaw) {
        if (raw is Map) {
          final ref = StudyPlanItemRef.fromJson(Map<String, dynamic>.from(raw));
          if (ref.id > 0 || ref.fromSurah != null) {
            items.add(ref);
          }
        }
      }
    }

    final studentsRaw = json['students'] ?? json['assignedStudents'];
    final students = <PlanAssignedStudent>[];
    if (studentsRaw is List) {
      for (final raw in studentsRaw) {
        if (raw is Map) {
          final s = PlanAssignedStudent.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (s.id.isNotEmpty) students.add(s);
        }
      }
    }

    final count = students.isNotEmpty ? students.length : studentsCount;

    return HalaqaStudyPlan(
      id: id,
      name: name.isEmpty ? 'خطة دراسة' : name,
      studentsCount: count,
      assignedToHalqaId: asInt(
        json['assignedToHalqaId'] ?? json['halqaId'] ?? json['halqa_id'],
      ),
      items: items,
      students: students,
      detailsLoaded: studentsRaw is List,
    );
  }
}

/// Arabic copy helpers locked to HALAQA-PLANS mocks.
abstract final class HalaqaPlansCopy {
  static String studentsPill(int count) {
    if (count == 1) return 'طالب 1';
    return '$count طلاب';
  }

  static String plansEntrySubtitle(int count) {
    final label = switch (count) {
      0 => 'لا خطط',
      1 => 'خطة واحدة',
      2 => 'خطتان',
      _ => '$count خطط',
    };
    return '$label · اضغط للإدارة';
  }
}
