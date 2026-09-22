import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_paths.dart';
import '../../../core/network/dio_client.dart';

final homeApiProvider = Provider<HomeApi>((ref) {
  return HomeApi(ref.watch(dioProvider));
});

/// Teacher home / halqa / students HTTP client.
class HomeApi {
  HomeApi(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> getTeacherProfile() {
    return _dio.get(ApiPaths.teacherProfile);
  }

  Future<Response<dynamic>> getTeacherProfileById(String teacherId) {
    return _dio.get('${ApiPaths.teacherProfileById}/$teacherId');
  }

  Future<Response<dynamic>> getHalqasByTeacherId(String teacherId) {
    return _dio.get('${ApiPaths.halqaByTeacherId}/$teacherId');
  }

  /// Roster for a ḥalaqa on a given day. Nest requires `date` (YYYY-MM-DD).
  Future<Response<dynamic>> getStudentsByHalqaId(
    String halaqaId, {
    required String date,
  }) {
    return _dio.get(
      '${ApiPaths.halqaStudentsByHalqaId}$halaqaId',
      queryParameters: {'date': date},
    );
  }

  Future<Response<dynamic>> getStudyPlans(String halaqaId) {
    return _dio.get('${ApiPaths.halqaStudyPlans}$halaqaId');
  }

  Future<Response<dynamic>> getHalqaById(String halaqaId) {
    return _dio.get('${ApiPaths.halqaById}$halaqaId');
  }

  /// Nest: `GET term/{termId}/holiday-dates`.
  Future<Response<dynamic>> getHolidayDates(String termId) {
    return _dio.get('${ApiPaths.term}$termId/${ApiPaths.holidayDates}');
  }

  /// Nest: `GET term-day/by-date?date=&termId=`.
  Future<Response<dynamic>> getTermDayByDate({
    required String date,
    required String termId,
  }) {
    return _dio.get(
      ApiPaths.termDayByDate,
      queryParameters: {
        'date': date,
        'termId': termId,
      },
    );
  }

  Future<Response<dynamic>> bulkAttendance(Map<String, dynamic> body) {
    return _dio.post(ApiPaths.attendanceBulk, data: body);
  }

  /// Nest: `PUT attendance/bulk` (UpdateBulkTermDayAttendanceDto).
  Future<Response<dynamic>> updateBulkAttendance(Map<String, dynamic> body) {
    return _dio.put(ApiPaths.attendanceBulk, data: body);
  }

  /// Nest: `GET study-plan/student/{studentId}` — `date` optional.
  /// With `date`, Nest 404s «سجل الحضور غير موجود» if that term-day has no attendance row.
  Future<Response<dynamic>> getStudentStudyPlan(
    String studentId, {
    String? date,
  }) {
    return _dio.get(
      '${ApiPaths.studyPlanStudent}$studentId',
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
  }

  /// Nest: `GET /study-plan/{id}/students`.
  Future<Response<dynamic>> getStudyPlanStudents(String planId) {
    return _dio.get('${ApiPaths.studyPlanSlash}$planId/students');
  }

  /// Nest: `GET student-daily-progress/progress?studentId=&date=&studyPlanItemId=`.
  Future<Response<dynamic>> getDailyProgress({
    required int studentId,
    required String date,
    required int studyPlanItemId,
  }) {
    return _dio.get(
      ApiPaths.studentDailyProgressProgress,
      queryParameters: {
        'studentId': studentId,
        'date': date,
        'studyPlanItemId': studyPlanItemId,
      },
    );
  }

  /// Nest: `GET student-daily-progress/plan-reference/{studyPlanItemId}`.
  Future<Response<dynamic>> getPlanReference(int studyPlanItemId) {
    return _dio.get(
      '${ApiPaths.studentDailyProgressPlanReference}$studyPlanItemId',
    );
  }

  /// Nest: `POST student-daily-progress` (CreateStudentDailyProgressDto).
  Future<Response<dynamic>> createDailyProgress(Map<String, dynamic> body) {
    return _dio.post(ApiPaths.studentDailyProgress, data: body);
  }

  /// Nest: `PUT student-daily-progress/{id}`.
  Future<Response<dynamic>> updateDailyProgress(
    int id,
    Map<String, dynamic> body,
  ) {
    return _dio.put('${ApiPaths.studentDailyProgress}/$id', data: body);
  }

  /// Nest: `POST student-daily-progress/murajaa-plan`.
  Future<Response<dynamic>> createMurajaaProgress(Map<String, dynamic> body) {
    return _dio.post(ApiPaths.studentDailyProgressMurajaa, data: body);
  }

  @Deprecated('Use createDailyProgress')
  Future<Response<dynamic>> studentDailyProgress(Map<String, dynamic> body) {
    return createDailyProgress(body);
  }

  @Deprecated('Use getStudentStudyPlan with date')
  Future<Response<dynamic>> getStudyPlan(String studentId) {
    return _dio.get('${ApiPaths.studyPlanStudent}$studentId');
  }

  Future<Response<dynamic>> getQuranSurahs() {
    return _dio.get(ApiPaths.quranSurahs);
  }

  /// Nest: `GET reports/progress?halqaId=&startingDate=&endingDate=`.
  /// Omit `period` so Nest uses the given dates (period overwrites them).
  Future<Response<dynamic>> getProgressReport({
    required String halaqaId,
    required String startingDate,
    required String endingDate,
  }) {
    return _dio.get(
      ApiPaths.reportsProgress,
      queryParameters: {
        'halqaId': halaqaId,
        'startingDate': startingDate,
        'endingDate': endingDate,
      },
    );
  }
}
