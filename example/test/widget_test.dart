// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:localization_example/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // Verify that the demo starts with one item.
    expect(find.text('Count: 1'), findsOneWidget);
    expect(find.text('Count: 2'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    // Verify that the counter row incremented to two items.
    expect(find.text('Count: 2'), findsOneWidget);
  });
}
