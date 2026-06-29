import 'package:flutter_test/flutter_test.dart';

import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('home opens hero choice', (WidgetTester tester) async {
    await tester.pumpWidget(const DiceThroneSurvieApp());

    expect(find.text('Version 1.1.3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Survival mode'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your hero'), findsOneWidget);
    expect(find.text('Barbare'), findsOneWidget);
    expect(find.text('Elfe lunaire'), findsOneWidget);
    expect(find.text('Tacticien'), findsOneWidget);
    expect(find.text('Deadpool'), findsOneWidget);
  });
}
