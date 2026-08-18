import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('TokenPickerCard renders add/minus buttons without overflow in narrow 3-column grid', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Accuracy',
      frLabel: 'Precision',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: true,
      removable: true,
      appSupported: true,
      description: 'Increases hit chance.',
    );

    int count = 1;

    // Simulate mobile screen width of 360px
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return TokenPickerCard(
                    rule: rule,
                    count: count,
                    onImageTap: () {},
                    onMinus: count > 0 ? () => setState(() => count--) : null,
                    onPlus: count < rule.maxStack ? () => setState(() => count++) : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Accuracy'), findsNWidgets(3));
    expect(find.text('1'), findsNWidgets(3));

    // Tap plus button on first card
    final plusButtons = find.byIcon(Icons.add);
    expect(plusButtons, findsNWidgets(3));
    await tester.tap(plusButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(count, 2);

    // Tap minus button on first card
    final minusButtons = find.byIcon(Icons.remove);
    expect(minusButtons, findsNWidgets(3));
    await tester.tap(minusButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(count, 1);

    // Verify zero rendering exceptions or overflow
    expect(tester.takeException(), isNull);
  });
}
