/// Flexible summary of a Halqa for the teacher home list.
class HalqaSummary {
  const HalqaSummary({
    required this.id,
    required this.name,
    required this.studentsCount,
  });

  final String id;
  final String name;
  final int studentsCount;

  factory HalqaSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final enrollments = json['enrollments'];
    final fromEnrollments =
        enrollments is List ? enrollments.length : null;

    final studentsCount = asInt(json['studentsCount']) ??
        asInt(json['students_count']) ??
        fromEnrollments ??
        asInt(json['studentLimit']) ??
        asInt(json['student_limit']) ??
        0;

    return HalqaSummary(
      id: id,
      name: name,
      studentsCount: studentsCount,
    );
  }
}