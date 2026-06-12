import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jb_music/main.dart' as app;
import 'package:jb_music/presentation/screens/main_navigation_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

 testWidgets('Find interactive UI elements', (tester) async {
  app.main();

  await tester.pumpAndSettle(const Duration(seconds: 6));

  // Print all tappable widgets (debug helper)
  final elements = find.byType(GestureDetector);
  expect(elements, findsWidgets);
});