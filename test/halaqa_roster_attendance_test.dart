import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_study_plan.dart';
import 'package:thafiz_teacher/features/halaqa/presentation/halaqa_detail_page.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

class _SaveCall {
  const _SaveCall({
    required this.studentUserId,
    required this.status,
    required this.previousStatus,
  });

  final String studentUserId;
  final String status;
  final String? previousStatus;
}

class _FakeHomeRepo extends HomeRepository {
  _FakeHomeRepo(this.students)
      : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  List<HalaqaStudent> students;
  final saves = <_SaveCall>[];

  @override
  Future<Set<String>> getHolidayDatesForHalqa(String halaqaId) async => {};

  @override
  Future<List<HalaqaStudent>> getStudentsByHalqaId({
    required String halaqaId,
    required String date,
  }) async =>
      students;

  @override
  Future<String?> getHalqaName(String halaqaId) async => 'حلقة الاختبار';

  @override
  Future<List<HalaqaStudyPlan>> listHalaqaStudyPlans(String halaqaId) async =>
      const [];

  @override
  Future<void> saveStudentAttendance({
    required String halaqaId,
    required String date,
    required String studentUserId,
    required String status,
    String? previousStatus,
  }) async {
    saves.add(
      _SaveCall(
        studentUserId: studentUserId,
        status: status,
        previousStatus: previousStatus,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pumpRoster(
    WidgetTester tester,
    _FakeHomeRepo repo, {
    bool startInEdit = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp(
          home: HalaqaDetailPage(
            halaqaId: '7',
            startInEdit: startInEdit,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('unmarked roster shows لم يُعلَّم and tapping the name does not save',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '15',
        name: 'أحمد',
        attendanceStatus: 'NOT_MARKED',
      ),
    ]);
    await pumpRoster(tester, repo);

    expect(find.text('لم يُعلَّم'), findsOneWidget);
    expect(find.text('حاضر'), findsNothing);

    await tester.tap(find.text('أحمد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.saves, isEmpty);
    expect(find.text('تعديل الحضور'), findsOneWidget);
    expect(find.text('حفظ الحضور'), findsNothing);
  });

  testWidgets(
      'تعديل الحضور then غائب then حفظ الحضور saves ABSENT from NOT_MARKED',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '15',
        name: 'أحمد',
        attendanceStatus: 'NOT_MARKED',
      ),
    ]);
    await pumpRoster(tester, repo);

    await tester.tap(find.text('تعديل الحضور'));
    await tester.pump();

    expect(find.text('حفظ الحضور'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('att-chip-15-ABSENT')));
    await tester.pump();

    await tester.tap(find.text('حفظ الحضور'));
    await tester.pump();
    await tester.pump();

    expect(repo.saves, hasLength(1));
    expect(repo.saves.single.studentUserId, '15');
    expect(repo.saves.single.status, 'ABSENT');
    expect(repo.saves.single.previousStatus, 'NOT_MARKED');
  });

  testWidgets('LATE displays متأخر; saving معذور sends LEAVE', (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '22',
        name: 'سارة',
        attendanceStatus: 'LATE',
      ),
    ]);
    await pumpRoster(tester, repo);

    expect(find.text('متأخر'), findsWidgets);

    await tester.tap(find.text('تعديل الحضور'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('att-chip-22-LEAVE')));
    await tester.pump();

    await tester.tap(find.text('حفظ الحضور'));
    await tester.pump();
    await tester.pump();

    expect(repo.saves.single.status, 'LEAVE');
    expect(repo.saves.single.previousStatus, 'LATE');
    expect(repo.saves.single.studentUserId, '22');
  });

  testWidgets('three tab labels الحضور / التقدم / نظرة عامة are present',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '15',
        name: 'أحمد',
        attendanceStatus: 'NOT_MARKED',
      ),
    ]);
    await pumpRoster(tester, repo);

    expect(find.text('الحضور'), findsOneWidget);
    expect(find.text('التقدم'), findsOneWidget);
    expect(find.text('نظرة عامة'), findsOneWidget);

    await tester.tap(find.text('التقدم'));
    await tester.pump();
    expect(find.text('تسجيل تقدّم'), findsOneWidget);
    expect(find.text('تعديل الحضور'), findsNothing);

    await tester.tap(find.text('نظرة عامة'));
    await tester.pump();
    expect(find.text('أحد–خميس'), findsWidgets);
    expect(find.text('تعديل الحضور'), findsNothing);
  });

  testWidgets(
      'attendance roster card is display-only and progress tab still opens',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '81',
        name: 'SMOKE E2E D2 prefills',
        attendanceStatus: 'PRESENT',
      ),
    ]);
    final router = GoRouter(
      initialLocation: '/halaqa/7',
      routes: [
        GoRoute(
          path: '/halaqa/:id',
          builder: (_, state) => HalaqaDetailPage(
            halaqaId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/student/:id',
          builder: (_, _) => const Scaffold(body: Text('HUB_OPEN')),
        ),
        GoRoute(
          path: '/student/:id/progress',
          builder: (_, _) => const Scaffold(body: Text('PROGRESS_OPEN')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('SMOKE E2E D2 prefills'), findsOneWidget);
    expect(find.text('حاضر'), findsOneWidget);
    expect(find.text('تعديل الحضور'), findsOneWidget);

    final card = find.byKey(const ValueKey('roster-81'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.chevron_left)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byType(InkWell)),
      findsNothing,
    );

    await tester.tap(find.text('SMOKE E2E D2 prefills'));
    await tester.pump();
    expect(find.text('HUB_OPEN'), findsNothing);
    expect(find.text('تعديل الحضور'), findsOneWidget);
    expect(repo.saves, isEmpty);

    await tester.tap(find.text('تعديل الحضور'));
    await tester.pump();
    expect(find.text('حفظ الحضور'), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.chevron_left)),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('att-chip-81-PRESENT')), findsOneWidget);

    await tester.tap(find.text('SMOKE E2E D2 prefills'));
    await tester.pump();
    expect(find.text('HUB_OPEN'), findsNothing);
    expect(find.text('حفظ الحضور'), findsOneWidget);

    await tester.tap(find.byKey(const Key('halaqa-tab-progress')));
    await tester.pump();
    expect(find.text('تعديل الحضور'), findsNothing);
    expect(find.text('حفظ الحضور'), findsNothing);
    await tester.tap(find.text('تسجيل تقدّم'));
    await tester.pumpAndSettle();
    expect(find.text('PROGRESS_OPEN'), findsOneWidget);
    expect(find.text('HUB_OPEN'), findsNothing);
  });
}
