/// School-day helpers for Saudi week (Sun–Thu) + term holidays.
///
/// Compare holidays by local date-only (year/month/day), never by instant/TZ.
library;

abstract final class SchoolCalendar {
  SchoolCalendar._();

  /// Friday=5, Saturday=6 in [DateTime.weekday].
  static bool isWeekend(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.weekday == DateTime.friday || day.weekday == DateTime.saturday;
  }

  /// True when [d] is Sun–Thu and not in [holidayYmd] (YYYY-MM-DD).
  static bool isSchoolDay(DateTime d, Set<String> holidayYmd) {
    final day = DateTime(d.year, d.month, d.day);
    if (isWeekend(day)) return false;
    if (holidayYmd.contains(toYmd(day))) return false;
    return true;
  }

  /// Nearest school day on or before [from] (walks back over weekend/holiday).
  static DateTime snapToSchoolDay(DateTime from, Set<String> holidays) {
    var d = DateTime(from.year, from.month, from.day);
    // Safety cap: never walk forever if holidays are malformed.
    for (var i = 0; i < 400; i++) {
      if (isSchoolDay(d, holidays)) return d;
      d = d.subtract(const Duration(days: 1));
    }
    return DateTime(from.year, from.month, from.day);
  }

  /// Previous school day strictly before [from].
  static DateTime previousSchoolDay(DateTime from, Set<String> holidays) {
    var d = DateTime(from.year, from.month, from.day)
        .subtract(const Duration(days: 1));
    for (var i = 0; i < 400; i++) {
      if (isSchoolDay(d, holidays)) return d;
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  /// Next school day strictly after [from].
  static DateTime nextSchoolDay(DateTime from, Set<String> holidays) {
    var d = DateTime(from.year, from.month, from.day).add(const Duration(days: 1));
    for (var i = 0; i < 400; i++) {
      if (isSchoolDay(d, holidays)) return d;
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static String toYmd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Parses YYYY-MM-DD (optionally with time suffix). Returns local date-only.
  static DateTime? parseYmd(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final datePart = s.length >= 10 ? s.substring(0, 10) : s;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(datePart);
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d);
  }
}
