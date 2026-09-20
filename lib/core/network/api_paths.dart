/// API path constants reverse-engineered from sa_work (com.example.sa_work).
/// Relative to [Env.apiBaseUrl].
abstract final class ApiPaths {
  // Auth
  static const login = 'auth/login';
  static const logout = 'auth/logout';
  static const refresh = 'auth/refresh';
  static const requestPasswordReset = 'auth/mobile/request-password-reset';
  static const resetPassword = 'auth/mobile/reset-password';
  static const pendingTeacherRequest = 'pending-teacher-request';
  static const register = 'register';

  /// Public centers list for teacher signup (`GET /center`, @Public).
  static const center = 'center';

  // Teacher / home
  static const teacherProfile = 'teacher-profile/';
  static const teacherProfileById = 'teacher-profile/by-teacher-id';
  static const halqaByTeacherId = 'halqa/by-teacher-id';
  static const usersStudents = 'users/students';

  // Halqa / students
  static const halqaById = 'halqa/';
  static const halqaStudentsByHalqaId = 'halqa/students/by-halqa-id/';
  static const halqaStudyPlans = 'halqa/study-plans/';
  static const students = 'students';
  static const student = 'student';
  static const assignStudents = 'assign-students';
  static const unassignStudents = 'unassign-students';

  // Study plans / daily progress
  static const studyPlan = 'study-plan';
  static const studyPlanSlash = 'study-plan/';
  static const studyPlanStudent = 'study-plan/student/';
  static const studentDailyProgress = 'student-daily-progress';
  static const studentDailyProgressSlash = 'student-daily-progress/';
  static const studentDailyProgressProgress = 'student-daily-progress/progress';
  static const studentDailyProgressMurajaa =
      'student-daily-progress/murajaa-plan';
  static const studentDailyProgressPlanReference =
      'student-daily-progress/plan-reference/';
  static const murajaaPlan = 'murajaa-plan';

  // Attendance / calendar / Quran
  static const attendanceBulk = 'attendance/bulk';
  static const termDayByDate = 'term-day/by-date';
  static const holidayDates = 'holiday-dates';
  static const term = 'term/';
  static const quranSurah = 'quran/surah/';
  static const quranSurahs = 'quran/surahs';
}
