import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/core/theme/app_theme.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/halaqa/presentation/halaqa_detail_page.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

class _FakeHomeRepo extends HomeRepository {
  _FakeHomeRepo({required this.students})
      : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  List<HalaqaStudent> students;
  List<({String userId, String status, String? previousStatus})>? lastSave;

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
  Future<void> saveHalaqaAttendance({
    required String halaqaId,
    required String date,
    required List<({String userId, String status, String? previousStatus})>
        entries,
  }) async {
    lastSave = entries;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://tahfiz.onrender.com/',
    );
  });

  List<HalaqaStudent> sampleStudents() => const [
        HalaqaStudent(
          id: '1',
          name: 'TEST Student CoS',
          attendanceStatus: 'PRESENT',
          hifzPercent: 62,
          murajaaPercent: 35,
          tathbeetPercent: 0,
          hasProgressToday: true,
        ),
        HalaqaStudent(
          id: '2',
          name: 'أحمد محمد',
          attendanceStatus: 'ABSENT',
          hifzPercent: 18,
          murajaaPercent: 10,
          tathbeetPercent: 0,
        ),
        HalaqaStudent(
          id: '3',
          name: 'سارة علي',
          attendanceStatus: 'LEAVE',
          hifzPercent: 78,
          murajaaPercent: 55,
          tathbeetPercent: 40,
        ),
        HalaqaStudent(
          id: '4',
          name: 'خالد يوسف',
          attendanceStatus: 'PRESENT',
          hifzPercent: 45,
          murajaaPercent: 22,
          tathbeetPercent: 5,
          hasProgressToday: true,
        ),
      ];

  Future<void> pumpDetail(
    WidgetTester tester,
    _FakeHomeRepo repo,
  ) async {
    final router = GoRouter(
      initialLocation: '/halaqa/1',
      routes: [
        GoRoute(
          path: '/halaqa/:id',
          builder: (_, state) => HalaqaDetailPage(
            halaqaId: state.pathParameters['id'] ?? '1',
          ),
        ),
        GoRoute(
          path: '/student/:id/progress',
          builder: (_, state) => Scaffold(
            body: Text('progress-editor-${state.pathParameters['id']}'),
          ),
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

  testWidgets('default tab is الحضور in view mode with locked badges',
      (tester) async {
    await pumpDetail(tester, _FakeHomeRepo(students: sampleStudents()));

    expect(find.text('المعلم'), findsOneWidget);
    expect(find.text('حلقة الفجر'), findsWidgets);
    expect(find.text('4 طلاب'), findsWidgets);
    expect(find.text('تعديل الحضور'), findsOneWidget);
    expect(find.text('حفظ الحضور'), findsNothing);
    expect(find.text('حاضر'), findsWidgets);
    expect(find.text('غائب'), findsWidgets);
    expect(find.text('معذور'), findsWidgets);
    expect(find.byKey(const Key('att-chip-2-ABSENT')), findsNothing);
    expect(
      find.text('أيام العمل أحد–خميس · يتخطى الجمعة/السبت والعطل'),
      findsOneWidget,
    );
  });

  testWidgets('تعديل الحضور unlocks chips; حفظ الحضور bulk-saves userId',
      (tester) async {
    final repo = _FakeHomeRepo(students: sampleStudents());
    await pumpDetail(tester, repo);

    await tester.tap(find.text('تعديل الحضور'));
    await tester.pumpAndSettle();

    expect(find.text('حفظ الحضور'), findsOneWidget);
    expect(find.byKey(const Key('att-chip-2-ABSENT')), findsOneWidget);

    await tester.tap(find.byKey(const Key('att-chip-2-PRESENT')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ الحضور'));
    await tester.pumpAndSettle();

    expect(repo.lastSave, isNotNull);
    expect(repo.lastSave!.length, 4);
    expect(repo.lastSave!.map((e) => e.userId).toList(), ['1', '2', '3', '4']);
    final ahmad = repo.lastSave!.firstWhere((e) => e.userId == '2');
    expect(ahmad.status, 'PRESENT');
    expect(ahmad.previousStatus, 'ABSENT');
    expect(find.text('تم حفظ الحضور'), findsOneWidget);
    expect(find.text('تعديل الحضور'), findsOneWidget);
  });

  testWidgets('progress tab opens existing progress editor route',
      (tester) async {
    await pumpDetail(tester, _FakeHomeRepo(students: sampleStudents()));

    await tester.tap(find.byKey(const Key('halaqa-tab-progress')));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل تقدّم'), findsNWidgets(2));
    expect(find.text('تعديل'), findsNWidgets(2));
    expect(find.text('تم اليوم'), findsNWidgets(2));
    expect(find.text('لم يُسجَّل اليوم'), findsNWidgets(2));
    expect(find.text('تعديل الحضور'), findsNothing);

    await tester.tap(find.text('تسجيل تقدّم').first);
    await tester.pumpAndSettle();
    expect(find.text('progress-editor-2'), findsOneWidget);
  });

  testWidgets('overview is read-only meta + names', (tester) async {
    await pumpDetail(tester, _FakeHomeRepo(students: sampleStudents()));

    await tester.tap(find.byKey(const Key('halaqa-tab-overview')));
    await tester.pumpAndSettle();

    expect(find.text('قائمة الطلاب'), findsOneWidget);
    expect(find.text('أحد–خميس'), findsOneWidget);
    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('تعديل الحضور'), findsNothing);
    expect(find.text('حفظ الحضور'), findsNothing);
    expect(find.text('تسجيل تقدّم'), findsNothing);
  });
}
