import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../core/util/school_calendar.dart';
import '../../auth/data/auth_repository.dart';
import '../../halaqa/data/dto/halaqa_student.dart';
import 'dto/halqa_summary.dart';
import 'dto/progress_models.dart';
import 'home_api.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    api: ref.watch(homeApiProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// Thrown when home data cannot be loaded.
class HomeException implements Exception {
  HomeException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HomeRepository {
  HomeRepository({required this.api, required this.storage});

  final HomeApi api;
  final SecureStorageService storage;

  /// Resolves teacher (User) id: secure storage first, then JWT `sub`/`userId`.
  Future<String> resolveTeacherId() async {
    final stored = await storage.readUserId();
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw HomeException('تعذر تحديد هوية المعلم. يرجى تسجيل الدخول مجدداً');
    }

    final fromJwt = _userIdFromJwt(token);
    if (fromJwt != null && fromJwt.isNotEmpty) {
      await storage.writeUserId(fromJwt);
      return fromJwt;
    }

    throw HomeException('تعذر تحديد هوية المعلم. يرجى تسجيل الدخول مجدداً');
  }

  Future<List<HalqaSummary>> getHalqasForCurrentTeacher() async {
    final teacherId = await resolveTeacherId();
    try {
      final res = await api.getHalqasByTeacherId(teacherId);
      return _parseHalqaList(res.data);
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Students roster for a ḥalaqa on [date] (YYYY-MM-DD).
  /// 404 / empty body → empty list (never crash).
  Future<List<HalaqaStudent>> getStudentsByHalqaId({
    required String halaqaId,
    required String date,
  }) async {
    try {
      final res = await api.getStudentsByHalqaId(halaqaId, date: date);
      return _parseStudentList(res.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return const [];
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Optional study plans for the ḥalaqa (plan types / metadata).
  Future<List<Map<String, dynamic>>> getStudyPlans(String halaqaId) async {
    try {
      final res = await api.getStudyPlans(halaqaId);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return const [];
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Optional ḥalaqa title from `GET /halqa/{id}`.
  Future<String?> getHalqaName(String halaqaId) async {
    try {
      final res = await api.getHalqaById(halaqaId);
      final map = _unwrapMap(res.data);
      if (map == null) return null;
      final name = map['name']?.toString().trim();
      if (name == null || name.isEmpty) return null;
      return name;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return null;
      // Non-fatal for title — detail screen can keep default.
      return null;
    }
  }

  /// Extract term id from a ḥalaqa payload.
  /// Nest GetHalqaDto uses `assignedToTermId` (not always `termId`).
  Future<String?> getHalqaTermId(String halaqaId) async {
    try {
      final res = await api.getHalqaById(halaqaId);
      final map = _unwrapMap(res.data);
      if (map == null) return null;
      return _extractTermId(map);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Holiday dates (YYYY-MM-DD) for the ḥalaqa's term.
  ///
  /// Prefers embedded `holidayDates` / `term.holidayDates` on `GET /halqa/{id}`;
  /// otherwise `GET term/{termId}/holiday-dates`. Failures → empty set (never throw).
  Future<Set<String>> getHolidayDatesForHalqa(String halaqaId) async {
    try {
      final res = await api.getHalqaById(halaqaId);
      final map = _unwrapMap(res.data);
      if (map != null) {
        final embedded = _extractHolidayDatesFromHalqa(map);
        if (embedded.isNotEmpty) return embedded;

        final termId = _extractTermId(map);
        if (termId != null && termId.isNotEmpty) {
          return await _fetchHolidayDatesForTerm(termId);
        }
      }
    } catch (_) {
      // Fall through — try term id path alone below if needed.
    }

    try {
      final termId = await getHalqaTermId(halaqaId);
      if (termId == null || termId.isEmpty) return const {};
      return await _fetchHolidayDatesForTerm(termId);
    } catch (_) {
      return const {};
    }
  }


  /// Resolve Nest `termDayId` for [date] (YYYY-MM-DD) via ḥalaqa → termId → term-day/by-date.
  Future<int> resolveTermDayId({
    required String halaqaId,
    required String date,
  }) async {
    final termId = await getHalqaTermId(halaqaId);
    if (termId == null || termId.isEmpty) {
      throw HomeException('تعذر تحديد الفصل الدراسي للحلقة');
    }
    try {
      final res = await api.getTermDayByDate(date: date, termId: termId);
      final map = _unwrapMap(res.data);
      if (map == null) {
        throw HomeException('لا يوجد يوم دراسي لهذا التاريخ');
      }
      final id = map['id'] ?? map['termDayId'] ?? map['term_day_id'];
      if (id == null) {
        throw HomeException('لا يوجد يوم دراسي لهذا التاريخ');
      }
      final n = id is num ? id.toInt() : int.tryParse(id.toString());
      if (n == null) {
        throw HomeException('لا يوجد يوم دراسي لهذا التاريخ');
      }
      return n;
    } on HomeException {
      rethrow;
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Save one student's attendance for a term day.
  ///
  /// Heuristic: null / empty / NOT_MARKED → POST create; else PUT update.
  /// On 400/409 from the first attempt, retries the other verb.
  Future<void> saveStudentAttendance({
    required String halaqaId,
    required String date,
    required String studentUserId,
    required String status,
    String? previousStatus,
  }) async {
    final termDayId = await resolveTermDayId(halaqaId: halaqaId, date: date);
    final userId = int.tryParse(studentUserId.trim());
    if (userId == null) {
      throw HomeException('معرّف الطالب غير صالح');
    }
    final nestStatus = status.trim().toUpperCase();
    final body = <String, dynamic>{
      'termDayId': termDayId,
      'students': [
        {'userId': userId, 'status': nestStatus},
      ],
    };

    final prev = previousStatus?.trim().toUpperCase() ?? '';
    final isCreate = prev.isEmpty ||
        prev == 'NOT_MARKED' ||
        prev == 'NULL' ||
        prev == 'HOLIDAY';

    Future<void> post() async {
      await api.bulkAttendance(body);
    }

    Future<void> put() async {
      await api.updateBulkAttendance(body);
    }

    bool shouldFlip(DioException e) {
      final code = e.response?.statusCode;
      return code == 400 || code == 409;
    }

    try {
      if (isCreate) {
        try {
          await post();
        } on DioException catch (e) {
          if (shouldFlip(e)) {
            await put();
          } else {
            throw HomeException(nestErrorMessage(e));
          }
        }
      } else {
        try {
          await put();
        } on DioException catch (e) {
          if (shouldFlip(e)) {
            await post();
          } else {
            throw HomeException(nestErrorMessage(e));
          }
        }
      }
    } on HomeException {
      rethrow;
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Nest: `GET study-plan/student/{id}?date=` — plan items for the day.
  /// Empty list = unbound (no study plan).
  Future<List<StudyPlanItemRef>> getStudentStudyPlan({
    required String studentId,
    required String date,
  }) async {
    try {
      final res = await api.getStudentStudyPlan(studentId, date: date);
      return _parseStudyPlanItems(res.data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return const [];
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Nest: get-or-create suggested daily progress for one plan item.
  Future<DailyProgressSnapshot> getDailyProgress({
    required String studentId,
    required String date,
    required int studyPlanItemId,
  }) async {
    final sid = int.tryParse(studentId.trim());
    if (sid == null) {
      throw HomeException('معرّف الطالب غير صالح');
    }
    try {
      final res = await api.getDailyProgress(
        studentId: sid,
        date: date,
        studyPlanItemId: studyPlanItemId,
      );
      return _parseDailyProgress(res.data);
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Optional plan-item reference (from/to range).
  Future<StudyPlanItemRef?> getPlanItemReference(int studyPlanItemId) async {
    try {
      final res = await api.getPlanReference(studyPlanItemId);
      final map = _unwrapMap(res.data);
      if (map == null) return null;
      return StudyPlanItemRef.fromJson(map);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) return null;
      throw HomeException(nestErrorMessage(e));
    }
  }

  Future<List<QuranSurah>> getQuranSurahs() async {
    try {
      final res = await api.getQuranSurahs();
      return _parseSurahs(res.data);
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Save HIFZ / TATHBEET — create or update based on existing progress id.
  Future<void> saveDailyProgress({
    required String studentId,
    required String termDayDate,
    required int studyPlanItemId,
    required int actualStartSurah,
    required int actualStartAyah,
    required int actualEndSurah,
    required int actualEndAyah,
    int? existingProgressId,
  }) async {
    final sid = int.tryParse(studentId.trim());
    if (sid == null) {
      throw HomeException('معرّف الطالب غير صالح');
    }
    final teacherIdStr = await resolveTeacherId();
    final teacherId = int.tryParse(teacherIdStr.trim());
    if (teacherId == null) {
      throw HomeException('معرّف المعلّم غير صالح');
    }
    final body = <String, dynamic>{
      'studentId': sid,
      'termDayDate': termDayDate,
      'studyPlanItemId': studyPlanItemId,
      'markedByTeacherId': teacherId,
      'actualStartSurah': actualStartSurah,
      'actualStartAyah': actualStartAyah,
      'actualEndSurah': actualEndSurah,
      'actualEndAyah': actualEndAyah,
    };
    try {
      if (existingProgressId != null && existingProgressId > 0) {
        await api.updateDailyProgress(existingProgressId, body);
      } else {
        await api.createDailyProgress(body);
      }
    } on DioException catch (e) {
      // Retry opposite verb on conflict / already-exists style errors.
      final code = e.response?.statusCode;
      if (code == 400 || code == 409) {
        try {
          if (existingProgressId != null && existingProgressId > 0) {
            await api.createDailyProgress(body);
          } else {
            // Without id we cannot PUT; surface original error.
            throw HomeException(nestErrorMessage(e));
          }
          return;
        } on DioException catch (e2) {
          throw HomeException(nestErrorMessage(e2));
        }
      }
      throw HomeException(nestErrorMessage(e));
    }
  }

  /// Save MURAJAA — POST murajaa-plan with progressRanges.
  Future<void> saveMurajaaProgress({
    required String studentId,
    required String termDayDate,
    required int studyPlanItemId,
    required List<Map<String, int>> progressRanges,
  }) async {
    final sid = int.tryParse(studentId.trim());
    if (sid == null) {
      throw HomeException('معرّف الطالب غير صالح');
    }
    final teacherIdStr = await resolveTeacherId();
    final teacherId = int.tryParse(teacherIdStr.trim());
    if (teacherId == null) {
      throw HomeException('معرّف المعلّم غير صالح');
    }
    if (progressRanges.isEmpty) {
      throw HomeException('أضف نطاقاً واحداً على الأقل للمراجعة');
    }
    final body = <String, dynamic>{
      'studentId': sid,
      'termDayDate': termDayDate,
      'studyPlanItemId': studyPlanItemId,
      'markedByTeacherId': teacherId,
      'progressRanges': progressRanges,
    };
    try {
      await api.createMurajaaProgress(body);
    } on DioException catch (e) {
      throw HomeException(nestErrorMessage(e));
    }
  }


  Future<Set<String>> _fetchHolidayDatesForTerm(String termId) async {
    try {
      final res = await api.getHolidayDates(termId);
      return _parseHolidayDateSet(res.data);
    } on DioException {
      return const {};
    } catch (_) {
      return const {};
    }
  }

  /// Nest GetHalqaDto: `assignedToTermId` is the ḥalaqa's term; `termId` is a
  /// fallback. Missing this field makes `resolveTermDayId` fail and attendance
  /// save show «تعذر تحديد الفصل الدراسي للحلقة».
  static String? _extractTermId(Map<String, dynamic> map) {
    final direct = map['assignedToTermId'] ??
        map['assigned_to_term_id'] ??
        map['termId'] ??
        map['term_id'];
    if (direct != null) {
      final s = direct.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    final term = map['term'];
    if (term is Map) {
      final t = Map<String, dynamic>.from(term);
      final id = t['id'] ??
          t['termId'] ??
          t['term_id'] ??
          t['assignedToTermId'] ??
          t['assigned_to_term_id'];
      if (id != null) {
        final s = id.toString().trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    } else if (term != null && term is! Map) {
      final s = term.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  /// Test seam for [_extractTermId] (GetHalqaDto `assignedToTermId`).
  static String? extractTermId(Map<String, dynamic> map) => _extractTermId(map);

  static Set<String> _extractHolidayDatesFromHalqa(Map<String, dynamic> map) {
    final top = map['holidayDates'] ?? map['holiday_dates'];
    final fromTop = _parseHolidayDateSet(top);
    if (fromTop.isNotEmpty) return fromTop;

    final term = map['term'];
    if (term is Map) {
      final t = Map<String, dynamic>.from(term);
      final nested = t['holidayDates'] ?? t['holiday_dates'];
      return _parseHolidayDateSet(nested);
    }
    return const {};
  }

  /// Accepts raw list, `{ data: [...] }`, or list of maps with a date field.
  static Set<String> _parseHolidayDateSet(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      list = map['data'] ??
          map['holidayDates'] ??
          map['holiday_dates'] ??
          map['items'] ??
          map['result'] ??
          map['dates'];
    }
    if (list == null) return const {};
    if (list is! List) {
      // Single string?
      final one = SchoolCalendar.parseYmd(list.toString());
      if (one != null) return {SchoolCalendar.toYmd(one)};
      return const {};
    }

    final out = <String>{};
    for (final item in list) {
      if (item == null) continue;
      if (item is String || item is num) {
        final d = SchoolCalendar.parseYmd(item.toString());
        if (d != null) out.add(SchoolCalendar.toYmd(d));
        continue;
      }
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final v = m['date'] ??
            m['holidayDate'] ??
            m['holiday_date'] ??
            m['day'] ??
            m['value'];
        if (v != null) {
          final d = SchoolCalendar.parseYmd(v.toString());
          if (d != null) out.add(SchoolCalendar.toYmd(d));
        }
      }
    }
    return out;
  }

  static List<HalqaSummary> _parseHalqaList(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      list = map['data'] ?? map['halqas'] ?? map['items'] ?? map['result'];
    }
    if (list == null) return const [];
    if (list is! List) return const [];

    final out = <HalqaSummary>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(HalqaSummary.fromJson(item));
      } else if (item is Map) {
        out.add(HalqaSummary.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return out;
  }

  static List<HalaqaStudent> _parseStudentList(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      list = map['data'] ??
          map['students'] ??
          map['items'] ??
          map['result'] ??
          map['rows'];
      // Some envelopes wrap again: data: { students: [...] }
      if (list is Map) {
        final inner = Map<String, dynamic>.from(list);
        list = inner['students'] ??
            inner['items'] ??
            inner['data'] ??
            inner['result'];
      }
    }
    if (list == null) return const [];
    if (list is! List) return const [];

    final out = <HalaqaStudent>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(HalaqaStudent.fromJson(item));
      } else if (item is Map) {
        out.add(HalaqaStudent.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    // Drop rows without id
    return out.where((s) => s.id.isNotEmpty).toList(growable: false);
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      list = map['data'] ?? map['items'] ?? map['result'];
    }
    if (list == null) return const [];
    if (list is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }


  static List<StudyPlanItemRef> _parseStudyPlanItems(dynamic raw) {
    dynamic root = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      root = map['data'] ?? map['studyPlan'] ?? map['result'] ?? map;
    }

    List<dynamic>? items;
    if (root is List) {
      // Could be list of plans or list of items
      if (root.isNotEmpty && root.first is Map) {
        final first = Map<String, dynamic>.from(root.first as Map);
        if (first.containsKey('studyPlanItems') ||
            first.containsKey('study_plan_items') ||
            first.containsKey('items')) {
          // list of plans — flatten items
          final out = <StudyPlanItemRef>[];
          for (final p in root) {
            if (p is! Map) continue;
            out.addAll(_itemsFromPlanMap(Map<String, dynamic>.from(p)));
          }
          return out;
        }
        // list of items directly
        items = root;
      } else {
        items = root;
      }
    } else if (root is Map) {
      final map = Map<String, dynamic>.from(root);
      items = _extractItemsList(map);
      if (items == null) {
        // Single plan object
        final fromPlan = _itemsFromPlanMap(map);
        if (fromPlan.isNotEmpty) return fromPlan;
      }
    }

    if (items == null) return const [];
    final out = <StudyPlanItemRef>[];
    for (final item in items) {
      if (item is Map) {
        final ref = StudyPlanItemRef.fromJson(Map<String, dynamic>.from(item));
        if (ref.id > 0) out.add(ref);
      }
    }
    return out;
  }

  static List<dynamic>? _extractItemsList(Map<String, dynamic> map) {
    final candidates = [
      map['studyPlanItems'],
      map['study_plan_items'],
      map['items'],
      map['planItems'],
      map['plan_items'],
    ];
    for (final c in candidates) {
      if (c is List) return c;
    }
    final nested = map['studyPlan'] ?? map['study_plan'] ?? map['plan'];
    if (nested is Map) {
      return _extractItemsList(Map<String, dynamic>.from(nested));
    }
    return null;
  }

  static List<StudyPlanItemRef> _itemsFromPlanMap(Map<String, dynamic> map) {
    final list = _extractItemsList(map);
    if (list == null) return const [];
    final out = <StudyPlanItemRef>[];
    for (final item in list) {
      if (item is Map) {
        final ref = StudyPlanItemRef.fromJson(Map<String, dynamic>.from(item));
        if (ref.id > 0) out.add(ref);
      }
    }
    return out;
  }

  static DailyProgressSnapshot _parseDailyProgress(dynamic raw) {
    // MURAJAA strategy may return a list of progress rows.
    if (raw is List) {
      return _snapshotFromProgressList(raw);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final data = map['data'];
      if (data is List) {
        return _snapshotFromProgressList(data);
      }
      if (data is Map) {
        final inner = Map<String, dynamic>.from(data);
        // Nested list under progressRanges / progresses
        final ranges = inner['progressRanges'] ??
            inner['progresses'] ??
            inner['items'];
        if (ranges is List && ranges.isNotEmpty) {
          final base = DailyProgressSnapshot.fromJson(inner);
          return _mergeRanges(base, ranges);
        }
        return DailyProgressSnapshot.fromJson(inner);
      }
      final ranges = map['progressRanges'] ?? map['progresses'];
      if (ranges is List && ranges.isNotEmpty) {
        final base = DailyProgressSnapshot.fromJson(map);
        return _mergeRanges(base, ranges);
      }
      return DailyProgressSnapshot.fromJson(map);
    }
    return const DailyProgressSnapshot();
  }

  static DailyProgressSnapshot _snapshotFromProgressList(List<dynamic> list) {
    if (list.isEmpty) return const DailyProgressSnapshot();
    final maps = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map) maps.add(Map<String, dynamic>.from(item));
    }
    if (maps.isEmpty) return const DailyProgressSnapshot();
    final first = DailyProgressSnapshot.fromJson(maps.first);
    if (maps.length == 1) return first;
    return _mergeRanges(first, maps);
  }

  static DailyProgressSnapshot _mergeRanges(
    DailyProgressSnapshot base,
    List<dynamic> ranges,
  ) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final parsed = <({int? endSurah, int? endAyah, int? startSurah, int? startAyah})>[];
    for (final r in ranges) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r);
      parsed.add((
        startSurah: asInt(m['actualStartSurah'] ?? m['suggestedStartSurah']),
        startAyah: asInt(m['actualStartAyah'] ?? m['suggestedStartAyah']),
        endSurah: asInt(m['actualEndSurah'] ?? m['suggestedEndSurah']),
        endAyah: asInt(m['actualEndAyah'] ?? m['suggestedEndAyah']),
      ));
    }
    return DailyProgressSnapshot(
      id: base.id,
      isProgress: base.isProgress,
      actualStartSurah: base.actualStartSurah,
      actualStartAyah: base.actualStartAyah,
      actualEndSurah: base.actualEndSurah,
      actualEndAyah: base.actualEndAyah,
      suggestedStartSurah: base.suggestedStartSurah,
      suggestedStartAyah: base.suggestedStartAyah,
      suggestedEndSurah: base.suggestedEndSurah,
      suggestedEndAyah: base.suggestedEndAyah,
      plannedAmountType: base.plannedAmountType,
      plannedAmountValue: base.plannedAmountValue,
      murajaaRanges: parsed,
    );
  }

  static List<QuranSurah> _parseSurahs(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      list = map['data'] ?? map['surahs'] ?? map['items'] ?? map['result'];
    }
    if (list is! List) return const [];
    final out = <QuranSurah>[];
    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final numVal = m['number'] ??
          m['surahNumber'] ??
          m['surah_number'] ??
          m['id'];
      final name = (m['name'] ??
              m['surahName'] ??
              m['surah_name'] ??
              m['nameAr'] ??
              m['arabicName'] ??
              '')
          .toString()
          .trim();
      final n = numVal is num ? numVal.toInt() : int.tryParse('$numVal');
      if (n == null || n < 1) continue;
      out.add(QuranSurah(number: n, name: name.isEmpty ? 'سورة $n' : name));
    }
    out.sort((a, b) => a.number.compareTo(b.number));
    return out;
  }


  static Map<String, dynamic>? _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }
    return null;
  }

  static String? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
        case 3:
          payload += '=';
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      if (map is! Map) return null;
      final sub = map['sub']?.toString();
      final userId = map['userId']?.toString() ?? map['user_id']?.toString();
      final id = (userId != null && userId.isNotEmpty) ? userId : sub;
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }
}
