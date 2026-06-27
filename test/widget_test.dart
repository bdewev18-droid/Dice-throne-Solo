import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('home opens hero choice', (WidgetTester tester) async {
    await tester.pumpWidget(const DiceThroneSurvieApp());

    expect(find.text('Mode survie solo'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Mode survie'));
    await tester.pumpAndSettle();

    expect(find.text('Choix du hero'), findsOneWidget);
    expect(find.text('Barbare'), findsOneWidget);
    expect(find.text('Elfe lunaire'), findsOneWidget);
  });
}
