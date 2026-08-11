import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('home opens hero choice', (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dt_solo_quest/active_adventure'),
          (call) async => null,
        );

    await tester.pumpWidget(const DiceThroneSurvieApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(appVersionLabel), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Minion rush'));
    await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

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
