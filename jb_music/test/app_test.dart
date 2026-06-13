import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jb_music/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Find interactive UI elements', (tester) async {
    app.main();

    await tester.pumpAndSettle(const Duration(seconds: 6));

    final elements = find.byType(GestureDetector);
    expect(elements, findsWidgets);
  });
}