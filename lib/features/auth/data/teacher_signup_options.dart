// Locked Brand-B teacher signup labels → Nest `CreatePendingTeacherRequestDto` enums.
// UI copy from `teacher-signup-*.html` (Imad 2026-09-20). Values from live `/api-json`.

class SignupOption {
  const SignupOption(this.value, this.label);
  final String value;
  final String label;
}

/// HTML order: الدبلوم · ثانوية · بكالوريوس · ماجستير · دكتوراه · أخرى
const qualificationOptions = <SignupOption>[
  SignupOption('DIPLOMA', 'الدبلوم'),
  SignupOption('HIGH_SCHOOL', 'ثانوية'),
  SignupOption('BACHELOR', 'بكالوريوس'),
  SignupOption('MASTER', 'ماجستير'),
  SignupOption('PHD', 'دكتوراه'),
  SignupOption('OTHER', 'أخرى'),
];

/// Nest tajweedLevel is BEGINNER | INTERMEDIATE | ADVANCED (no متقن).
const tajweedLevelOptions = <SignupOption>[
  SignupOption('ADVANCED', 'متقدم'),
  SignupOption('BEGINNER', 'مبتدئ'),
  SignupOption('INTERMEDIATE', 'متوسط'),
];

/// Locked HTML nationality select (do not invent extra countries).
const nationalityOptions = <String>[
  'أفغانستان',
  'السعودية',
  'سوريا',
  'مصر',
  'الأردن',
];

/// Locked mock is 5 groups. Nest also has PRESCHOOL + PRIMARY_UPPER — omitted.
const teachingAgeGroupOptions = <SignupOption>[
  SignupOption('PRIMARY_LOWER', 'الابتدائية (6-11 سنوات)'),
  SignupOption('MIDDLE_SCHOOL', 'المتوسطة (12-14 سنة)'),
  SignupOption('HIGH_SCHOOL', 'الثانوية (15-17 سنة)'),
  SignupOption('UNIVERSITY', 'الجامعية (18-22 سنة)'),
  SignupOption('ADULTS', 'الكبار (23 فما أعلى)'),
];

const availableWorkPeriodOptions = <SignupOption>[
  SignupOption('WEEKDAYS', 'أيام العمل الأسبوعية (من الأحد حتى الخميس)'),
  SignupOption('AFTER_FAJR', 'بعد الفجر (ساعتين)'),
  SignupOption('AFTER_ASR', 'بعد العصر (ساعتين)'),
  SignupOption('AFTER_MAGHRIB', 'بعد المغرب (ساعة)'),
  SignupOption('AFTER_ISHA', 'بعد العشاء (ساعتين)'),
];

const signupStepFields = <Set<String>>[
  {'teacherName', 'email', 'password'},
  {
    'qualification',
    'tajweedLevel',
    'centerId',
    'hasCertificate',
    'hasIjazahInHifz',
    'hasSanadInHifz',
  },
  {'nationality', 'address', 'phone', 'birthDate', 'numberOfMemorizedJuz'},
  {'teachingAgeGroup', 'availableWorkPeriod'},
];

/// Earliest wizard step that owns a Nest `fieldName`.
int firstSignupStepForFields(Map<String, String> errors) {
  for (var i = 0; i < signupStepFields.length; i++) {
    if (errors.keys.any(signupStepFields[i].contains)) return i;
  }
  return 0;
}

/// UI date `dd-MM-yyyy` — live Nest accepted this on POST pending-teacher-request.
String formatSignupBirthDate(DateTime date) {
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd-$mm-${date.year}';
}
