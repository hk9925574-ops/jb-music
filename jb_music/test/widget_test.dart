import 'package:flutter_test/flutter_test.dart';
import 'package:jb_music/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  testWidgets('JB Music app loads UI', (tester) async {
    app.main();

    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}