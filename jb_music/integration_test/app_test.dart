import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:jb_music/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches successfully',
      (WidgetTester tester) async {

    app.main();

    await tester.pumpAndSettle();

    expect(find.byType(Object), findsWidgets);
  });
}