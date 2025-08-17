// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smollm_flutter/main.dart';

void main() {
  testWidgets('SmolLM app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmolLMApp());

    // Verify that the welcome text appears
    expect(find.text('Welcome to SmolLM Flutter!'), findsOneWidget);
    expect(find.text('A lightweight language model running on device'), findsOneWidget);

    // Verify that the FAB exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Try SmolLM'), findsOneWidget);
  });
}
