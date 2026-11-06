import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/features/halaqa/data/dto/halaqa_student.dart';
import 'package:thafiz_teacher/features/home/data/home_api.dart';
import 'package:thafiz_teacher/features/home/data/home_repository.dart';
import 'package:thafiz_teacher/features/student/presentation/student_attendance_page.dart';
import 'package:thafiz_teacher/shared/widgets/thafiz_toast.dart';

class _AttendanceRepo extends HomeRepository {
  _AttendanceRepo(this.students)
      : super(
          api: HomeApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  final List<HalaqaStudent> students;
  var saveCalls = 0;
  Object? saveError;

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
    saveCalls++;
    if (saveError != null) throw saveError!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(ThafizToast.dismiss);

  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    Widget? body,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: body ?? const SizedBox.expand()),
      ),
    );
    return tester.element(find.byType(Scaffold));
  }

  testWidgets('success, error, and info use distinct icon, color, and role',
      (tester) async {
    final handle = tester.ensureSemantics();
    final context = await pumpHost(tester);
    try {

    Future<void> expectKind(
      ThafizToastKind kind,
      String message,
      IconData icon,
      Color background,
      SemanticsRole role,
    ) async {
      ThafizToast.show(context, message: message, kind: kind);
      await tester.pump();

      expect(find.byType(ThafizToastCard), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(tester.widget<ThafizToastCard>(find.byType(ThafizToastCard)).kind, kind);
      final text = tester.widget<Text>(find.text(message));
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.textAlign, TextAlign.start);

      final boxes = find.descendant(
        of: find.byType(ThafizToastCard),
        matching: find.byType(DecoratedBox),
      );
      final surface = tester.widget<DecoratedBox>(boxes.at(0)).decoration as BoxDecoration;
      expect(surface.color, ThafizToast.surface);
      expect(
        surface.borderRadius,
        const BorderRadius.all(Radius.circular(ThafizToast.radius)),
      );
      expect(surface.boxShadow, ThafizToast.shadow);
      final glyph = tester.widget<DecoratedBox>(boxes.at(1)).decoration as BoxDecoration;
      expect(glyph.color, background);
      expect(glyph.shape, BoxShape.circle);

      final data = tester.getSemantics(find.byType(ThafizToastCard)).getSemanticsData();
      expect(data.label, message);
      expect(data.role, role);
      expect(data.textDirection, TextDirection.rtl);
      expect(data.hasAction(SemanticsAction.dismiss), isTrue);
      expect(find.byType(SnackBar), findsNothing);
      ThafizToast.dismiss();
      await tester.pump();
    }

    await expectKind(
      ThafizToastKind.success,
      'تم حفظ التقدّم',
      Icons.check,
      ThafizToast.successBg,
      SemanticsRole.status,
    );
    await expectKind(
      ThafizToastKind.error,
      'يرجى تحديد حالة الحضور أولاً',
      Icons.error_outline,
      ThafizToast.errorBg,
      SemanticsRole.alert,
    );
    await expectKind(
      ThafizToastKind.info,
      'تم تحديث الحضور',
      Icons.info_outline,
      ThafizToast.infoBg,
      SemanticsRole.status,
    );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('a new toast replaces the current one and does not stack',
      (tester) async {
    final context = await pumpHost(tester);
    ThafizToast.show(
      context,
      message: 'تم حفظ التقدّم',
      kind: ThafizToastKind.success,
    );
    await tester.pump();
    ThafizToast.show(
      context,
      message: 'تعذر حفظ الحضور',
      kind: ThafizToastKind.error,
    );
    await tester.pump();

    expect(find.byType(ThafizToastCard), findsOneWidget);
    expect(find.text('تم حفظ التقدّم'), findsNothing);
    expect(find.text('تعذر حفظ الحضور'), findsOneWidget);
    expect(
      tester.widget<ThafizToastCard>(find.byType(ThafizToastCard)).kind,
      ThafizToastKind.error,
    );
  });

  testWidgets('tap dismisses, and success/info leave before an error does',
      (tester) async {
    final context = await pumpHost(tester);
    ThafizToast.show(
      context,
      message: 'تم حفظ التقدّم',
      kind: ThafizToastKind.success,
    );
    await tester.pump();
    await tester.tap(find.byType(ThafizToastCard));
    await tester.pump();
    expect(find.byType(ThafizToastCard), findsNothing);

    ThafizToast.show(
      context,
      message: 'تم حفظ التقدّم',
      kind: ThafizToastKind.success,
    );
    await tester.pump();
    await tester.pump(ThafizToast.successDuration - const Duration(milliseconds: 1));
    expect(find.text('تم حفظ التقدّم'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('تم حفظ التقدّم'), findsNothing);

    ThafizToast.show(
      context,
      message: 'تم تحديث الحضور',
      kind: ThafizToastKind.info,
    );
    await tester.pump();
    await tester.pump(ThafizToast.infoDuration);
    await tester.pump();
    expect(find.text('تم تحديث الحضور'), findsNothing);

    ThafizToast.show(
      context,
      message: 'تعذر حفظ الحضور',
      kind: ThafizToastKind.error,
    );
    await tester.pump();
    await tester.pump(ThafizToast.successDuration);
    await tester.pump();
    expect(find.text('تعذر حفظ الحضور'), findsOneWidget);
    await tester.pump(ThafizToast.errorDuration - ThafizToast.successDuration);
    await tester.pump();
    expect(find.text('تعذر حفظ الحضور'), findsNothing);
  });

  testWidgets('RTL card sits above the save button and above the home indicator',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    var taps = 0;
    final context = await pumpHost(
      tester,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => taps++,
                  child: const Text('حفظ التقدّم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ThafizToast.show(
      context,
      message: 'تم حفظ التقدّم',
      kind: ThafizToastKind.success,
    );
    await tester.pump();

    final direction = tester.widget<Directionality>(
      find.descendant(
        of: find.byType(ThafizToastCard),
        matching: find.byType(Directionality),
      ),
    );
    expect(direction.textDirection, TextDirection.rtl);
    final icon = tester.getCenter(find.byIcon(Icons.check));
    final label = tester.getCenter(find.text('تم حفظ التقدّم'));
    expect(icon.dx, greaterThan(label.dx));

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final toast = tester.getRect(find.byType(ThafizToastCard));
    final save = tester.getRect(find.widgetWithText(FilledButton, 'حفظ التقدّم'));
    expect(toast.left, ThafizToast.horizontalInset);
    expect(screen.width - toast.right, ThafizToast.horizontalInset);
    expect(screen.height - toast.bottom, ThafizToast.bottomClearance + 34);
    expect(toast.bottom, lessThanOrEqualTo(save.top));
    expect(toast.bottom, greaterThan(34));

    await tester.tap(find.text('حفظ التقدّم'));
    await tester.pump();
    expect(taps, 1);
    expect(find.byType(ThafizToastCard), findsOneWidget);
  });

  testWidgets('attendance-only save toasts تم حفظ الحضور only after the API',
      (tester) async {
    final student = const HalaqaStudent(
      id: '30',
      name: 'TEST Student',
      attendanceStatus: 'PRESENT',
    );
    final repo = _AttendanceRepo([student]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const MaterialApp(
          home: StudentAttendancePage(
            studentId: '30',
            halaqaId: '7',
            date: '2026-09-20',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ThafizToastCard), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'تعديل'));
    await tester.pump();
    await tester.pump();

    expect(repo.saveCalls, 1);
    expect(find.text('تم حفظ الحضور'), findsOneWidget);
    expect(
      tester.widget<ThafizToastCard>(find.byType(ThafizToastCard)).kind,
      ThafizToastKind.success,
    );
    final toast = tester.getRect(find.byType(ThafizToastCard));
    final save = tester.getRect(find.widgetWithText(FilledButton, 'تعديل'));
    expect(toast.bottom, lessThanOrEqualTo(save.top));

    ThafizToast.dismiss();
    await tester.pump();
    repo.saveError = HomeException('تعذر حفظ الحضور');
    await tester.tap(find.widgetWithText(FilledButton, 'تعديل'));
    await tester.pump();
    await tester.pump();

    expect(repo.saveCalls, 2);
    expect(find.text('تم حفظ الحضور'), findsNothing);
    expect(find.text('تعذر حفظ الحضور'), findsOneWidget);
    expect(
      tester.widget<ThafizToastCard>(find.byType(ThafizToastCard)).kind,
      ThafizToastKind.error,
    );
  });
}
