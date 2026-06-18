// Smoke test for CrickifyApp.
// Verifies that the app launches without crashing and renders the
// branded placeholder join screen introduced in Milestone 1.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crickfest/main.dart';

void main() {
  testWidgets('CrickifyApp launches and shows branded shell',
      (WidgetTester tester) async {
    // Build the app and trigger the first frame.
    await tester.pumpWidget(const CrickifyApp());

    // The placeholder screen displays the app name kicker text.
    expect(
      find.text('Floodlights on. Dugout loud. Every tap counts.'),
      findsOneWidget,
    );

    // The golden CTA button is present.
    expect(find.text('Walk Out to Bat'), findsOneWidget);

    // The milestone marker card is visible.
    expect(find.text('MILESTONE 1 COMPLETE'), findsOneWidget);
  });
}
