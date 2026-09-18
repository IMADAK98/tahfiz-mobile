import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thafiz_teacher/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://tahfiz.onrender.com/',
    );
  });

  testWidgets('App boots to login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ThafizTeacherApp()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('دخول'), findsWidgets);
  });
}