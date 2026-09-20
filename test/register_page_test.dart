import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thafiz_teacher/core/storage/secure_storage_service.dart';
import 'package:thafiz_teacher/core/theme/app_theme.dart';
import 'package:thafiz_teacher/features/auth/data/auth_api.dart';
import 'package:thafiz_teacher/features/auth/data/auth_repository.dart';
import 'package:thafiz_teacher/features/auth/data/dto/center_option.dart';
import 'package:thafiz_teacher/features/auth/data/dto/create_pending_teacher_request.dart';
import 'package:thafiz_teacher/features/auth/presentation/register_page.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(
          api: AuthApi(Dio()),
          storage: SecureStorageService(const FlutterSecureStorage()),
        );

  CreatePendingTeacherRequestDto? lastDto;
  AuthException? submitError;

  @override
  Future<List<CenterOption>> listCenters() async {
    return const [CenterOption(id: 2, name: 'Simon test')];
  }

  @override
  Future<void> submitPendingTeacherRequest(
    CreatePendingTeacherRequestDto dto,
  ) async {
    lastDto = dto;
    if (submitError != null) throw submitError!;
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

  Future<void> pumpRegister(
    WidgetTester tester,
    _FakeAuthRepository repo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RegisterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdown(
    WidgetTester tester,
    Key key,
    String label,
  ) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 shows locked account fields, pager CTA, login link',
      (tester) async {
    await pumpRegister(tester, _FakeAuthRepository());

    expect(find.text('تسجيل المعلم'), findsOneWidget);
    expect(find.text('تحفيظ'), findsOneWidget);
    expect(find.text('اسم المعلم'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsNWidgets(2));
    expect(find.text('التالي'), findsOneWidget);
    expect(find.textContaining('هل لديك حساب؟'), findsOneWidget);
    expect(find.textContaining('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('التالي without name stays on step 1 with field error',
      (tester) async {
    await pumpRegister(tester, _FakeAuthRepository());
    await tester.tap(find.text('التالي'));
    await tester.pump();

    expect(find.text('يرجى إدخال اسم المعلم'), findsOneWidget);
    expect(find.text('المؤهل'), findsNothing);
  });

  testWidgets('password mismatch stays on step 1', (tester) async {
    await pumpRegister(tester, _FakeAuthRepository());
    await tester.enterText(find.byType(TextField).at(0), 'test');
    await tester.enterText(find.byType(TextField).at(1), 'testto@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), 'password1');
    await tester.enterText(find.byType(TextField).at(3), 'nomatch');
    await tester.tap(find.text('التالي'));
    await tester.pump();
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(find.text('المؤهل'), findsNothing);
  });

  testWidgets('walks 4 steps and POSTs CreatePendingTeacherRequestDto',
      (tester) async {
    final repo = _FakeAuthRepository();
    await pumpRegister(tester, repo);
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.enterText(find.byType(TextField).at(0), 'test');
    await tester.enterText(find.byType(TextField).at(1), 'testto@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), 'password1');
    await tester.enterText(find.byType(TextField).at(3), 'password1');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('المؤهل'), findsOneWidget);
    expect(find.text('مستوى التجويد'), findsOneWidget);
    expect(find.text('مركز العمل'), findsOneWidget);
    expect(
      find.text('هل لديك شهادة خاتم للقرآن الكريم من جمعية مكنون أو غيرها؟'),
      findsOneWidget,
    );
    expect(find.text('لديه إجازة في الحفظ؟'), findsOneWidget);
    expect(find.text('لديه سند في الحفظ؟'), findsOneWidget);

    await selectDropdown(tester, const Key('qualification'), 'الدبلوم');
    await selectDropdown(tester, const Key('tajweedLevel'), 'متقدم');
    await selectDropdown(tester, const Key('centerId'), 'Simon test');

    await tester.tap(
      find.text('هل لديك شهادة خاتم للقرآن الكريم من جمعية مكنون أو غيرها؟'),
    );
    await tester.tap(find.text('لديه إجازة في الحفظ؟'));
    await tester.tap(find.text('لديه سند في الحفظ؟'));
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('الجنسية'), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('المؤهل'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await selectDropdown(tester, const Key('nationality'), 'أفغانستان');
    await tester.enterText(find.byType(TextField).at(0), 'yyrrdd');
    await tester.enterText(find.byType(TextField).at(1), '+558 89 965 5');
    await tester.enterText(find.byType(TextField).at(2), '20-09-2026');
    await tester.enterText(find.byType(TextField).at(3), '2');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('الابتدائية (6-11 سنوات)'), findsOneWidget);
    expect(find.text('فترة العمل المتاحة'), findsOneWidget);
    expect(find.text('تسجيل'), findsOneWidget);
    expect(find.textContaining('هل لديك حساب؟'), findsOneWidget);

    await tester.tap(find.text('الابتدائية (6-11 سنوات)'));
    await tester.tap(find.text('أيام العمل الأسبوعية (من الأحد حتى الخميس)'));
    await tester.tap(find.text('بعد الفجر (ساعتين)'));
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    expect(repo.lastDto, isNotNull);
    final json = repo.lastDto!.toJson();
    expect(json['teacherName'], 'test');
    expect(json['email'], 'testto@gmail.com');
    expect(json['password'], 'password1');
    expect(json['qualification'], 'DIPLOMA');
    expect(json['tajweedLevel'], 'ADVANCED');
    expect(json['centerId'], 2);
    expect(json['hasCertificate'], isTrue);
    expect(json['hasIjazahInHifz'], isTrue);
    expect(json['hasSanadInHifz'], isTrue);
    expect(json['nationality'], 'أفغانستان');
    expect(json['address'], 'yyrrdd');
    expect(json['phone'], '+558 89 965 5');
    expect(json['birthDate'], '20-09-2026');
    expect(json['numberOfMemorizedJuz'], 2);
    expect(json['teachingAgeGroup'], ['PRIMARY_LOWER']);
    expect(json['availableWorkPeriod'], ['WEEKDAYS', 'AFTER_FAJR']);
  });

  testWidgets('Nest field errors surface under email', (tester) async {
    final repo = _FakeAuthRepository()
      ..submitError = AuthException(
        'Validation failed',
        fieldErrors: const {'email': 'حقل email مطلوب'},
      );
    await pumpRegister(tester, repo);
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.enterText(find.byType(TextField).at(0), 'test');
    await tester.enterText(find.byType(TextField).at(1), 'bad@x.com');
    await tester.enterText(find.byType(TextField).at(2), 'password1');
    await tester.enterText(find.byType(TextField).at(3), 'password1');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await selectDropdown(tester, const Key('qualification'), 'الدبلوم');
    await selectDropdown(tester, const Key('tajweedLevel'), 'متقدم');
    await selectDropdown(tester, const Key('centerId'), 'Simon test');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await selectDropdown(tester, const Key('nationality'), 'أفغانستان');
    await tester.enterText(find.byType(TextField).at(0), 'addr');
    await tester.enterText(find.byType(TextField).at(1), '0500000000');
    await tester.enterText(find.byType(TextField).at(2), '01-01-1990');
    await tester.enterText(find.byType(TextField).at(3), '1');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الكبار (23 فما أعلى)'));
    await tester.tap(find.text('بعد العصر (ساعتين)'));
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    expect(find.text('حقل email مطلوب'), findsOneWidget);
    expect(find.text('اسم المعلم'), findsOneWidget);
  });
}
