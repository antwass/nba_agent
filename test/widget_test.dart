import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nba_agent/features/start/start_screen.dart';

void main() {
  testWidgets('menu appears', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));
    expect(find.text('NBA Agent'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);
  });
}
