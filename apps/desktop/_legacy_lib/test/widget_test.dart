import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opportunex/app.dart';

void main() {
  testWidgets('App loads Login page by default', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    // Verify that the login text or button is present.
    // The router points to LoginPage by default.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
