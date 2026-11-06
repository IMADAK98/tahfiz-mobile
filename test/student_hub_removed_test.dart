import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:thafiz_teacher/core/router/app_router.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/home/data/dto/halqa_summary.dart';
import 'package:thafiz_teacher/features/home/data/dto/progress_models.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';

class _RouteFakeRepo extends HomeRepository {
  _RouteFakeRepo()
      : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  @override
  Future<List<HalqaSummary>> getHalqasForCurrentTeacher() async => const [];

  @override
  Future<Set<String>> getHolidayDatesForHalqa(String halaqaId) async => {};

  @override
  Future<List<HalaqaStudent>> getStudentsByHalqaId({
    required String halaqaId,
    required String date,
  }) async =>
      const [
        HalaqaStudent(
          id: '81',
          name: 'SMOKE E2E D2 prefills',
          attendanceStatus: 'PRESENT',
        ),
      ];

  @override
  Future<String?> getHalqaName(String halaqaId) async => 'حلقة الفجر';

  @override
  Future<List<StudyPlanItemRef>> getStudentStudyPlan({
    required String studentId,
    required String date,
    String? halaqaId,
  }) async =>
      const [];

  @override
  Future<List<QuranSurah>> getQuranSurahs() async => const [];
}

List<GoRoute> _goRoutes(List<RouteBase> routes) {
  final out = <GoRoute>[];
  for (final route in routes) {
    if (route is! GoRoute) continue;
    out.add(route);
    out.addAll(_goRoutes(route.routes));
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({'accessToken': 'tok'});
  });

  test('app router has no student hub and keeps attendance and progress', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    final routes = _goRoutes(router.configuration.routes);
    final paths = routes.map((route) => route.path).toList();
    final names = routes.map((route) => route.name).whereType<String>().toList();

    expect(paths, isNot(contains('/student/:id')));
    expect(names, isNot(contains('student')));
    expect(paths, contains('/student/:id/attendance'));
    expect(paths, contains('/student/:id/progress'));
    expect(names, containsAll(['studentAttendance', 'studentProgress']));
  });

  testWidgets('hub URL is missing; attendance and progress editors still open',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWith((ref) => _RouteFakeRepo()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/student/81');
    await tester.pumpAndSettle();

    expect(find.textContaining('المسار غير موجود'), findsOneWidget);
    expect(find.text('تسجيل الحضور'), findsNothing);
    expect(find.text('تسجيل التقدّم'), findsNothing);
    expect(find.text('الطالب #81'), findsNothing);

    router.go('/student/81/progress?date=2026-11-09&halaqaId=7');
    await tester.pumpAndSettle();

    expect(find.textContaining('المسار غير موجود'), findsNothing);
    expect(find.text('لا توجد خطة دراسية مربوطة'), findsOneWidget);

    router.go('/student/81/attendance?date=2026-11-09&halaqaId=7');
    await tester.pumpAndSettle();

    expect(find.text('SMOKE E2E D2 prefills'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('الطالب #81'), findsNothing);
  });
}
