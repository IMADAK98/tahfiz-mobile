import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
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
    _FakeHomeRepo repo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(
          home: HalaqaDetailPage(halaqaId: '7'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('unmarked roster shows حاضر then tap cycles and debounced-saves',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '15',
        name: 'أحمد',
        attendanceStatus: 'NOT_MARKED',
      ),
    ]);
    await pumpRoster(tester, repo);

    expect(find.text('حاضر'), findsOneWidget);

    await tester.tap(find.text('أحمد'));
    await tester.pump();
    expect(find.text('غائب'), findsOneWidget);
    expect(repo.saves, isEmpty);

    await tester.tap(find.text('أحمد'));
    await tester.pump();
    expect(find.text('متأخر'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(repo.saves, hasLength(1));
    expect(repo.saves.single.studentUserId, '15');
    expect(repo.saves.single.status, 'LATE');
    expect(repo.saves.single.previousStatus, 'NOT_MARKED');
  });

  testWidgets('Nest LATE is shown as متأخر and next tap is معذور',
      (tester) async {
    final repo = _FakeHomeRepo([
      const HalaqaStudent(
        id: '22',
        name: 'سارة',
        attendanceStatus: 'LATE',
      ),
    ]);
    await pumpRoster(tester, repo);

    expect(find.text('متأخر'), findsOneWidget);
    expect(find.text('حاضر'), findsNothing);

    await tester.tap(find.text('سارة'));
    await tester.pump();
    expect(find.text('معذور'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(repo.saves.single.status, 'LEAVE');
    expect(repo.saves.single.previousStatus, 'LATE');
    expect(repo.saves.single.studentUserId, '22');
  });
}
