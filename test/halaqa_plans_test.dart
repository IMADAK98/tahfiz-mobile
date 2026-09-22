import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/core/theme/app_theme.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_study_plan.dart';
import 'package:thafiz_teacher/features/halaqa/presentation/halaqa_detail_page.dart';
import 'package:thafiz_teacher/features/halaqa/presentation/halaqa_plans_page.dart';
import 'package:thafiz_teacher/features/home/data/dto/progress_models.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

class _FakeHomeRepo extends HomeRepository {
  _FakeHomeRepo({
    required this.students,
    this.plans = const [],
    this.detailsById = const {},
  }) : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  List<HalaqaStudent> students;
  List<HalaqaStudyPlan> plans;
  Map<int, HalaqaStudyPlan> detailsById;
  int? deletedPlanId;
  List<int>? lastAssignIds;
  List<int>? lastUnassignIds;
  Map<String, dynamic>? lastCreateBody;

  @override
  Future<Set<String>> getHolidayDatesForHalqa(String halaqaId) async =>
      const {};

  @override
  Future<List<HalaqaStudent>> getStudentsByHalqaId({
    required String halaqaId,
    required String date,
  }) async {
    return students;
  }

  @override
  Future<String?> getHalqaName(String halaqaId) async => 'حلقة الفجر';

  @override
  Future<List<HalaqaStudyPlan>> listHalaqaStudyPlans(String halaqaId) async =>
      plans;

  @override
  Future<HalaqaStudyPlan> getStudyPlanDetails(int planId) async {
    return detailsById[planId] ??
        plans.firstWhere(
          (p) => p.id == planId,
          orElse: () => HalaqaStudyPlan(id: planId, name: 'خطة'),
        );
  }

  @override
  Future<List<QuranSurah>> getQuranSurahs() async => const [
        QuranSurah(number: 1, name: 'الفاتحة'),
        QuranSurah(number: 2, name: 'البقرة'),
      ];

  @override
  Future<void> deleteStudyPlan(int planId) async {
    deletedPlanId = planId;
    plans = plans.where((p) => p.id != planId).toList();
  }

  @override
  Future<void> unassignStudentsFromPlan({
    required int planId,
    required List<int> studentIds,
  }) async {
    lastUnassignIds = studentIds;
  }

  @override
  Future<void> assignStudentsToPlan({
    required int planId,
    required List<int> studentIds,
  }) async {
    lastAssignIds = studentIds;
  }

  @override
  Future<HalaqaStudyPlan> createStudyPlan({
    required String name,
    required int halaqaId,
    required List<Map<String, dynamic>> studyPlanItems,
    List<int>? studentIds,
  }) async {
    lastCreateBody = {
      'name': name,
      'halqaId': halaqaId,
      'studyPlanItems': studyPlanItems,
      if (studentIds != null) 'studentIds': studentIds,
    };
    return HalaqaStudyPlan(id: 99, name: name, items: const []);
  }

  @override
  Future<void> saveStudentAttendance({
    required String halaqaId,
    required String date,
    required String studentUserId,
    required String status,
    String? previousStatus,
  }) async {}
}

List<HalaqaStudent> sampleStudents() => const [
      HalaqaStudent(id: '1', name: 'TEST Student CoS'),
      HalaqaStudent(id: '2', name: 'أحمد محمد'),
      HalaqaStudent(id: '3', name: 'سارة علي'),
      HalaqaStudent(id: '4', name: 'خالد يوسف'),
    ];

HalaqaStudyPlan samplePlan() => HalaqaStudyPlan(
      id: 9,
      name: 'TEST Study Plan CoS',
      studentsCount: 1,
      items: const [
        StudyPlanItemRef(
          id: 1,
          type: PlanItemType.hifz,
          fromSurah: 1,
          fromAyah: 1,
          toSurah: 1,
          toAyah: 7,
          fromSurahName: 'الفاتحة',
          toSurahName: 'الفاتحة',
          amountType: 'LINE',
          amountValue: 5,
        ),
        StudyPlanItemRef(
          id: 2,
          type: PlanItemType.tathbeet,
          fromSurah: 1,
          fromAyah: 1,
          toSurah: 1,
          toAyah: 4,
          fromSurahName: 'الفاتحة',
          toSurahName: 'الفاتحة',
          amountType: 'LINE',
          amountValue: 3,
        ),
      ],
      students: const [
        PlanAssignedStudent(id: '1', name: 'TEST Student CoS'),
      ],
      detailsLoaded: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://tahfiz.onrender.com/',
    );
  });

  test('HalaqaStudyPlan.fromJson parses list payload', () {
    final plan = HalaqaStudyPlan.fromJson({
      'id': 9,
      'name': 'TEST Study Plan CoS',
      'studentsCount': 1,
      'studyPlanItems': [
        {
          'id': 1,
          'type': 'HIFZ',
          'fromSurah': 1,
          'fromAyah': 1,
          'toSurah': 1,
          'toAyah': 7,
          'amountType': 'LINE',
          'amountValue': 5,
        },
      ],
    });
    expect(plan.id, 9);
    expect(plan.items.length, 1);
    expect(plan.items.first.type, PlanItemType.hifz);
    expect(plan.items.first.formatPlanRange(full: true),
        contains('من'));
    expect(HalaqaPlansCopy.plansEntrySubtitle(2), 'خطتان · اضغط للإدارة');
    expect(HalaqaPlansCopy.studentsPill(1), 'طالب 1');
  });

  test('create item body omits to*', () {
    final body = {
      'type': 'HIFZ',
      'direction': 'NORMAL',
      'fromSurah': 1,
      'fromAyah': 1,
      'amountType': 'LINE',
      'amountValue': 5,
    };
    expect(body.containsKey('toSurah'), isFalse);
    expect(body.containsKey('toAyah'), isFalse);
  });

  Future<void> pumpDetail(WidgetTester tester, _FakeHomeRepo repo) async {
    final router = GoRouter(
      initialLocation: '/halaqa/1',
      routes: [
        GoRoute(
          path: '/halaqa/:id',
          builder: (_, state) => HalaqaDetailPage(
            halaqaId: state.pathParameters['id'] ?? '1',
          ),
          routes: [
            GoRoute(
              path: 'plans',
              builder: (_, state) => HalaqaPlansPage(
                halaqaId: state.pathParameters['id'] ?? '1',
                halaqaName: 'حلقة الفجر',
                studentCount: 4,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('overview shows الخطط entry and opens plans list',
      (tester) async {
    final plan = samplePlan();
    final repo = _FakeHomeRepo(
      students: sampleStudents(),
      plans: [plan],
      detailsById: {9: plan},
    );
    await pumpDetail(tester, repo);

    await tester.tap(find.byKey(const Key('halaqa-tab-overview')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('halaqa-plans-entry')), findsOneWidget);
    expect(find.text('الخطط'), findsWidgets);
    expect(find.textContaining('اضغط للإدارة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('halaqa-plans-entry')));
    await tester.pumpAndSettle();

    expect(find.text('خطط الدراسة'), findsOneWidget);
    expect(find.text('TEST Study Plan CoS'), findsOneWidget);
    expect(find.text('إضافة خطة'), findsOneWidget);
  });

  testWidgets('plans expand shows from→to and delete confirm', (tester) async {
    final plan = samplePlan();
    final repo = _FakeHomeRepo(
      students: sampleStudents(),
      plans: [plan],
      detailsById: {9: plan},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: HalaqaPlansPage(
              halaqaId: '1',
              halaqaName: 'حلقة الفجر',
              studentCount: 4,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('من الفاتحة آية 1 → إلى الفاتحة آية 7'), findsOneWidget);
    expect(find.text('تعيين طلاب'), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan-delete-9')));
    await tester.pumpAndSettle();
    expect(find.text('حذف الخطة'), findsOneWidget);
    expect(find.text('تأكيد حذف'), findsOneWidget);

    await tester.tap(find.text('تأكيد حذف'));
    await tester.pumpAndSettle();
    expect(repo.deletedPlanId, 9);
  });
}
