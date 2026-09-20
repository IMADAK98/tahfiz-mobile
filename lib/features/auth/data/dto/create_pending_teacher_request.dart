/// Nest `CreatePendingTeacherRequestDto` body + UI↔Nest enum maps.
///
/// Field names and enum values match live OpenAPI on tahfiz.onrender.com.
class CreatePendingTeacherRequest {
  const CreatePendingTeacherRequest({
    required this.teacherName,
    required this.email,
    required this.password,
    required this.nationality,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.qualification,
    required this.hasCertificate,
    required this.numberOfMemorizedJuz,
    required this.hasIjazahInHifz,
    required this.hasSanadInHifz,
    required this.tajweedLevel,
    required this.teachingAgeGroup,
    required this.availableWorkPeriod,
    required this.centerId,
  });

  final String teacherName;
  final String email;
  final String password;
  final String nationality;
  final String phone;
  final String address;

  /// ISO `YYYY-MM-DD` as Nest expects for [birthDate].
  final String birthDate;
  final String qualification;
  final bool hasCertificate;
  final int numberOfMemorizedJuz;
  final bool hasIjazahInHifz;
  final bool hasSanadInHifz;
  final String tajweedLevel;
  final List<String> teachingAgeGroup;
  final List<String> availableWorkPeriod;
  final num centerId;

  Map<String, dynamic> toJson() => {
        'teacherName': teacherName,
        'email': email,
        'password': password,
        'nationality': nationality,
        'phone': phone,
        'address': address,
        'birthDate': birthDate,
        'qualification': qualification,
        'hasCertificate': hasCertificate,
        'numberOfMemorizedJuz': numberOfMemorizedJuz,
        'hasIjazahInHifz': hasIjazahInHifz,
        'hasSanadInHifz': hasSanadInHifz,
        'tajweedLevel': tajweedLevel,
        'teachingAgeGroup': teachingAgeGroup,
        'availableWorkPeriod': availableWorkPeriod,
        'centerId': centerId,
      };
}

/// Qualification options shown in the locked mock (Nest enums only).
const kQualificationOptions = <({String value, String label})>[
  (value: 'HIGH_SCHOOL', label: 'ثانوية'),
  (value: 'DIPLOMA', label: 'الدبلوم'),
  (value: 'BACHELOR', label: 'بكالوريوس'),
  (value: 'MASTER', label: 'ماجستير'),
  (value: 'PHD', label: 'دكتوراه'),
  (value: 'OTHER', label: 'أخرى'),
];

/// Nest only exposes 3 tajweed levels — do not send «متقن».
const kTajweedOptions = <({String value, String label})>[
  (value: 'BEGINNER', label: 'مبتدئ'),
  (value: 'INTERMEDIATE', label: 'متوسط'),
  (value: 'ADVANCED', label: 'متقدم'),
];

/// UI age chips (mock has 5; Nest has 7 — PRESCHOOL omitted).
enum UiTeachingAge {
  primary611,
  middle1214,
  high1517,
  university1822,
  adults23,
}

extension UiTeachingAgeX on UiTeachingAge {
  String get label => switch (this) {
        UiTeachingAge.primary611 => 'الابتدائية (6-11 سنوات)',
        UiTeachingAge.middle1214 => 'المتوسطة (12-14 سنة)',
        UiTeachingAge.high1517 => 'الثانوية (15-17 سنة)',
        UiTeachingAge.university1822 => 'الجامعية (18-22 سنة)',
        UiTeachingAge.adults23 => 'الكبار (23 فما أعلى)',
      };

  /// Maps one UI chip to one or more Nest `teachingAgeGroup` values.
  /// Primary 6–11 covers Nest's PRIMARY_LOWER + PRIMARY_UPPER split.
  List<String> get nestValues => switch (this) {
        UiTeachingAge.primary611 => const ['PRIMARY_LOWER', 'PRIMARY_UPPER'],
        UiTeachingAge.middle1214 => const ['MIDDLE_SCHOOL'],
        UiTeachingAge.high1517 => const ['HIGH_SCHOOL'],
        UiTeachingAge.university1822 => const ['UNIVERSITY'],
        UiTeachingAge.adults23 => const ['ADULTS'],
      };
}

List<String> nestTeachingAgeGroups(Iterable<UiTeachingAge> selected) {
  final out = <String>[];
  for (final age in selected) {
    out.addAll(age.nestValues);
  }
  return out;
}

enum UiWorkPeriod {
  weekdays,
  afterFajr,
  afterAsr,
  afterMaghrib,
  afterIsha,
}

extension UiWorkPeriodX on UiWorkPeriod {
  String get label => switch (this) {
        UiWorkPeriod.weekdays =>
          'أيام العمل الأسبوعية (من الأحد حتى الخميس)',
        UiWorkPeriod.afterFajr => 'بعد الفجر (ساعتين)',
        UiWorkPeriod.afterAsr => 'بعد العصر (ساعتين)',
        UiWorkPeriod.afterMaghrib => 'بعد المغرب (ساعة)',
        UiWorkPeriod.afterIsha => 'بعد العشاء (ساعتين)',
      };

  String get nestValue => switch (this) {
        UiWorkPeriod.weekdays => 'WEEKDAYS',
        UiWorkPeriod.afterFajr => 'AFTER_FAJR',
        UiWorkPeriod.afterAsr => 'AFTER_ASR',
        UiWorkPeriod.afterMaghrib => 'AFTER_MAGHRIB',
        UiWorkPeriod.afterIsha => 'AFTER_ISHA',
      };
}

List<String> nestWorkPeriods(Iterable<UiWorkPeriod> selected) =>
    selected.map((e) => e.nestValue).toList();

/// Converts UI date text (`DD-MM-YYYY` or `YYYY-MM-DD`) to Nest ISO date.
String? birthDateToIso(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(t);
  if (iso != null) return t;
  final dmy = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(t);
  if (dmy != null) {
    final d = dmy.group(1)!.padLeft(2, '0');
    final m = dmy.group(2)!.padLeft(2, '0');
    final y = dmy.group(3)!;
    return '$y-$m-$d';
  }
  return null;
}

String formatBirthDateDisplay(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd-$mm-${d.year}';
}
