import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/home/data/dto/progress_models.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';
import 'package:thafiz_teacher/features/student/presentation/student_progress_page.dart';
import 'package:thafiz_teacher/shared/widgets/thafiz_toast.dart';

class _FakeProgressRepo extends HomeRepository {
  _FakeProgressRepo({
    required this.students,
    required this.items,
    this.saved = false,
    this.saveError,
    this.snapshot,
  }) : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  List<HalaqaStudent> students;
  List<StudyPlanItemRef> items;
  bool saved;
  Object? saveError;
  DailyProgressSnapshot? snapshot;
  var saveCalls = 0;
  var progressLoads = 0;

  @override
  Future<Set<String>> getHolidayDatesForHalqa(String halaqaId) async => {};

  @override
  Future<List<HalaqaStudent>> getStudentsByHalqaId({
    required String halaqaId,
    required String date,
  }) async =>
      students;

  @override
  Future<String?> getHalqaName(String halaqaId) async => 'نموذج عماد';

  @override
  Future<List<StudyPlanItemRef>> getStudentStudyPlan({
    required String studentId,
    required String date,
    String? halaqaId,
  }) async =>
      items;

  @override
  Future<List<QuranSurah>> getQuranSurahs() async => const [
        QuranSurah(number: 1, name: 'الفاتحة'),
        QuranSurah(number: 2, name: 'البقرة'),
      ];

  @override
  Future<StudyPlanItemRef?> getPlanItemReference(int studyPlanItemId) async =>
      null;

  @override
  Future<DailyProgressSnapshot> getDailyProgress({
    required String studentId,
    required String date,
    required int studyPlanItemId,
  }) async {
    progressLoads++;
    if (snapshot != null) return snapshot!;
    return DailyProgressSnapshot(
      id: saved ? 9 : null,
      isProgress: saved,
      actualEndSurah: saved ? 2 : null,
      actualEndAyah: saved ? 5 : null,
    );
  }

  @override
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
    saveCalls++;
    if (saveError != null) throw saveError!;
    saved = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(ThafizToast.dismiss);

  group('DailyProgressSnapshot.fromJson', () {
    test('Nest suggestion (isProgress false + INCOMPLETE + old id) is not saved today',
        () {
      final snap = DailyProgressSnapshot.fromJson({
        'id': 21,
        'status': 'INCOMPLETE',
        'isProgress': false,
        'actualEndSurah': 2,
        'actualEndAyah': 5,
      });
      expect(snap.isProgress, isFalse);
      expect(snap.hasSavedProgress, isFalse);
      expect(snap.id, 21);
    });

    test('today’s row (isProgress true) is saved', () {
      final snap = DailyProgressSnapshot.fromJson({
        'id': 40,
        'status': 'INCOMPLETE',
        'isProgress': true,
        'actualEndSurah': 2,
        'actualEndAyah': 5,
      });
      expect(snap.hasSavedProgress, isTrue);
    });
  });

  const student = HalaqaStudent(
    id: '30',
    name: 'TEST Student PriorTerm',
    attendanceStatus: 'PRESENT',
    hifzPercent: 59,
    tathbeetPercent: 100,
    murajaaPercent: 100,
  );

  const hifzItem = StudyPlanItemRef(
    id: 23,
    type: PlanItemType.hifz,
    fromSurah: 1,
    fromAyah: 1,
    toSurah: 2,
    toAyah: 1,
    fromSurahName: 'الفاتحة',
    toSurahName: 'البقرة',
    amountType: 'PAGE',
    amountValue: 1,
  );

  Future<void> pumpPage(
    WidgetTester tester,
    _FakeProgressRepo repo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(
          home: StudentProgressPage(
            studentId: '30',
            date: '2026-09-20',
            halaqaId: '16',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('v2 chrome: date pill, one حاضر badge, daily %, type tabs',
      (tester) async {
    await pumpPage(
      tester,
      _FakeProgressRepo(students: const [student], items: const [hifzItem]),
    );

    expect(find.text('نموذج عماد'), findsOneWidget);
    expect(find.text('2026-09-20'), findsOneWidget);
    expect(find.text('الأحد'), findsOneWidget);
    expect(find.text('TEST Student PriorTerm'), findsOneWidget);
    expect(find.text('حاضر'), findsOneWidget);
    expect(find.text('غائب'), findsNothing);
    expect(find.text('الطلاب'), findsNothing);
    expect(find.text('حفظ 59%'), findsOneWidget);
    // Plan has HIFZ only: unplanned مراجعة / تثبيت chips stay hidden.
    expect(find.textContaining('مراجعة '), findsNothing);
    expect(find.textContaining('تثبيت '), findsNothing);
    expect(find.text('حفظ'), findsWidgets);
    expect(find.text('لم يُسجَّل اليوم'), findsOneWidget);
    expect(find.text('نطاق الخطة (للقراءة)'), findsOneWidget);
    expect(find.text('المقدار المطلوب اليوم'), findsOneWidget);
    expect(find.text('1 صفحة'), findsOneWidget);
    expect(find.text('ما أنجزه الطالب اليوم'), findsOneWidget);
    expect(find.text('حفظ التقدّم'), findsOneWidget);
  });

  testWidgets('unbound plan shows empty CTA, not a blank editor',
      (tester) async {
    await pumpPage(
      tester,
      _FakeProgressRepo(students: const [student], items: const []),
    );

    expect(find.text('لا توجد خطة دراسية مربوطة'), findsOneWidget);
    expect(find.text('تعيين / ربط خطة دراسية'), findsOneWidget);
    expect(find.text('حفظ التقدّم'), findsNothing);
    expect(find.text('الخطة: غير محددة'), findsOneWidget);
  });

  testWidgets('unmarked attendance shows blocked copy, not the assign CTA',
      (tester) async {
    const unmarked = HalaqaStudent(
      id: '30',
      name: 'TEST Student PriorTerm',
      attendanceStatus: 'NOT_MARKED',
      hifzPercent: 59,
      tathbeetPercent: 100,
      murajaaPercent: 100,
    );
    final repo = _FakeProgressRepo(
      students: const [unmarked],
      items: const [hifzItem],
    );
    await pumpPage(tester, repo);

    expect(find.text('سجّل الحضور أولاً قبل تسجيل التقدّم'), findsOneWidget);
    expect(find.text('لم يُعلَّم'), findsOneWidget);
    expect(find.text('تعيين / ربط خطة دراسية'), findsNothing);
    expect(find.text('حفظ التقدّم'), findsNothing);
    expect(find.text('نطاق الخطة (للقراءة)'), findsNothing);
    expect(repo.progressLoads, 0);
    expect(repo.saveCalls, 0);
  });

  testWidgets('حفظ التقدّم posts daily progress then shows تم اليوم',
      (tester) async {
    final repo = _FakeProgressRepo(
      students: const [student],
      items: const [hifzItem],
    );
    await pumpPage(tester, repo);

    await tester.tap(find.text('حفظ التقدّم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.saveCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
    final card = tester.widget<ThafizToastCard>(find.byType(ThafizToastCard));
    expect(card.kind, ThafizToastKind.success);
    expect(card.message, 'تم حفظ التقدّم');
    final toast = tester.getRect(find.byType(ThafizToastCard));
    final save = tester.getRect(find.widgetWithText(FilledButton, 'حفظ التقدّم'));
    expect(toast.bottom, lessThanOrEqualTo(save.top));
    expect(find.text('تم اليوم'), findsOneWidget);
  });

  testWidgets('failed progress save keeps the inline error and skips success',
      (tester) async {
    final repo = _FakeProgressRepo(
      students: const [student],
      items: const [hifzItem],
      saveError: HomeException('تعذر الحفظ من الخادم'),
    );
    await pumpPage(tester, repo);

    await tester.tap(find.text('حفظ التقدّم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.saveCalls, 1);
    expect(find.text('تعذر الحفظ من الخادم'), findsOneWidget);
    expect(find.text('تم حفظ التقدّم'), findsNothing);
    expect(find.byType(ThafizToastCard), findsNothing);
    expect(find.text('حفظ التقدّم'), findsOneWidget);
  });

  testWidgets('attendance 409 does not show a success toast', (tester) async {
    final repo = _FakeProgressRepo(
      students: const [student],
      items: const [hifzItem],
      saveError: ProgressAttendanceException(
        'blocked',
        code: 'ATTENDANCE_REQUIRED',
        attendanceStatus: 'NOT_MARKED',
      ),
    );
    await pumpPage(tester, repo);

    await tester.tap(find.text('حفظ التقدّم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.saveCalls, 1);
    expect(find.text('تم حفظ التقدّم'), findsNothing);
    expect(find.byType(ThafizToastCard), findsNothing);
    expect(find.text('سجّل الحضور أولاً قبل تسجيل التقدّم'), findsOneWidget);
    expect(find.text('تعيين / ربط خطة دراسية'), findsNothing);
  });

  const murajaaItem = StudyPlanItemRef(
    id: 25,
    type: PlanItemType.murajaa,
    fromSurah: 2,
    fromAyah: 1,
    toSurah: 2,
    toAyah: 16,
    fromSurahName: 'البقرة',
    toSurahName: 'البقرة',
    amountType: 'PAGE',
    amountValue: 1,
  );
  const tathbeetItem = StudyPlanItemRef(
    id: 24,
    type: PlanItemType.tathbeet,
    fromSurah: 1,
    fromAyah: 1,
    toSurah: 2,
    toAyah: 5,
  );

  testWidgets('مراجعة suggestion without an end leaves the end empty, not the plan end',
      (tester) async {
    final repo = _FakeProgressRepo(
      students: const [student],
      items: const [murajaaItem],
      snapshot: const DailyProgressSnapshot(
        id: 70,
        suggestedStartSurah: 2,
        suggestedStartAyah: 17,
      ),
    );
    await pumpPage(tester, repo);

    expect(find.text('ما أنجزه الطالب اليوم — مراجعة'), findsOneWidget);
    final ayah = tester.widget<TextField>(find.byType(TextField).first);
    expect(ayah.controller!.text, isEmpty);
    expect(find.text('16'), findsNothing);
    final surah = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>).first,
    );
    expect(surah.value, isNull);
  });

  testWidgets('chips show the real uncapped % and hide null types',
      (tester) async {
    const over = HalaqaStudent(
      id: '30',
      name: 'TEST Student PriorTerm',
      attendanceStatus: 'PRESENT',
      hifzPercent: 115,
      murajaaPercent: 200,
      tathbeetPercent: null,
    );
    await pumpPage(
      tester,
      _FakeProgressRepo(
        students: const [over],
        items: const [hifzItem, murajaaItem, tathbeetItem],
      ),
    );
    expect(find.text('حفظ 115%'), findsOneWidget);
    expect(find.text('مراجعة 200%'), findsOneWidget);
    expect(find.textContaining('تثبيت '), findsNothing);
  });

  testWidgets('unplanned types hide even when the roster sends 0',
      (tester) async {
    const unplannedZero = HalaqaStudent(
      id: '30',
      name: 'TEST Student PriorTerm',
      attendanceStatus: 'PRESENT',
      hifzPercent: 0,
      murajaaPercent: 0,
      tathbeetPercent: 0,
    );
    await pumpPage(
      tester,
      _FakeProgressRepo(students: const [unplannedZero], items: const [hifzItem]),
    );
    expect(find.text('حفظ 0%'), findsOneWidget);
    expect(find.textContaining('مراجعة '), findsNothing);
    expect(find.textContaining('تثبيت '), findsNothing);
  });
}
