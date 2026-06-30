import 'package:flutter_test/flutter_test.dart';

import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('home opens hero choice', (WidgetTester tester) async {
    await tester.pumpWidget(const DiceThroneSurvieApp());

    expect(find.text('Version 1.1.5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Survival mode'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your hero'), findsOneWidget);
    expect(find.text('Barbarian'), findsOneWidget);
    expect(find.text('Moon Elf'), findsOneWidget);
    expect(find.text('Tactician'), findsOneWidget);
    expect(find.text('Monk'), findsOneWidget);
    expect(find.text('Paladin'), findsOneWidget);
    expect(find.text('Pyromancer'), findsOneWidget);
    expect(find.text('Shadow Thief'), findsOneWidget);
    expect(find.text('Deadpool'), findsOneWidget);
  });
}
