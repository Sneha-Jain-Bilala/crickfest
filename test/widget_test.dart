// Smoke test for CrickifyApp — verifies the app launches without crashing
// and that the JoinScreen renders its key UI elements.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crickfest/main.dart';

void main() {
  testWidgets('JoinScreen renders correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const CrickifyApp());

    // The app header text is visible
    expect(find.text('STADIUM CONTROL ROOM'), findsOneWidget);

    // The golden CTA button is shown
    expect(find.text('Walk out to bat'), findsOneWidget);

    // Both mode tab labels are present
    expect(find.text('IPL Trivia'), findsOneWidget);
    expect(find.text('Hand Cricket'), findsOneWidget);
  });
}
