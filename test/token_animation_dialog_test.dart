import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dice_throne_survie/main.dart';

void main() {
  testWidgets('TokenAnimationDialog edit controls fit cleanly without overflow', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Poison',
      frLabel: 'Poison',
      kind: StatusTokenKind.negative,
      maxStack: 5,
      persistent: true,
      removable: true,
      appSupported: true,
      description: 'Deals 1 damage per token at start of turn.',
    );

    // Test on a narrow mobile screen size (360x640) to verify overflow prevention
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TokenAnimationDialog.show(
                    context,
                    rule: rule,
                    initialCount: 2,
                    targetName: 'Hero',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Poison (x2)'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // Tap Edit button to reveal token counter controls (+ and -)
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Tokens: '), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Tap + icon to increment
    final addIcon = find.byIcon(Icons.add_circle_outline);
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);

    // Tap - icon to decrement
    final removeIcon = find.byIcon(Icons.remove_circle_outline);
    expect(removeIcon, findsOneWidget);
    await tester.tap(removeIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    // Ensure no overflow exception was thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('TokenAnimationDialog for First Strike displays only OK button without edit button', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'First Strike',
      frLabel: 'Première Frappe',
      kind: StatusTokenKind.unique,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'This unit starts first.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  TokenAnimationDialog.show(
                    context,
                    rule: rule,
                    initialCount: 1,
                    targetName: 'Gobelin Vaurien',
                  );
                },
                child: const Text('Open First Strike'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open First Strike'));
    await tester.pumpAndSettle();

    expect(find.text('First Strike'), findsOneWidget);
    expect(find.text('Triggered on Gobelin Vaurien'), findsOneWidget);
    expect(find.text('This unit starts first.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('First Strike'), findsNothing);
  });

  testWidgets('CombatAiChatDock renders portrait with HP, CP, and token strip on roll phases', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    adventure.health = 42;
    adventure.combatPoints = 5;
    adventure.setAlterations(['Poison', 'Poison']);

    final enemy = adventure.enemies.first;
    enemy.health = 25;
    enemy.combatPoints = 2;

    bool editHeroCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero roll phase',
            phase: CombatPhase.hero,
            adventure: adventure,
            enemy: enemy,
            primaryEnemy: enemy,
            canSwitchTarget: false,
            onSelectTarget: (_) {},
            returnDamage: 0,
            returnDamageUndefendable: false,
            lifeSteal: 0,
            enemyHeal: 0,
            cpSteal: 0,
            heroTokens: adventure.alterations,
            minionTokens: enemy.alterations,
            notes: const [],
            showResolution: true,
            attackValue: 0,
            defenseValue: 0,
            onAttackChanged: (_) {},
            onDefenseChanged: (_) {},
            onApply: () {},
            onFinish: null,
            onChanged: () {},
            onEditHeroTokens: () => editHeroCalled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify HP and CP are rendered on portrait
    expect(find.text('42'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Verify edit pencil icon is present in the token bar
    final editIcons = find.byIcon(Icons.edit);
    expect(editIcons, findsWidgets);

    // Tap the edit icon on portrait
    await tester.tap(editIcons.first);
    await tester.pumpAndSettle();
    expect(editHeroCalled, isTrue);
  });

  testWidgets('TokenAnimationDialog for Entangle and Hex displays info only with OK button', (WidgetTester tester) async {
    const entangleRule = StatusTokenRule(
      label: 'Entangle',
      frLabel: 'Enchevêtrement',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'A player afflicted with this token gets 1 fewer Roll Attempts.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: entangleRule,
                initialCount: 1,
                targetName: 'Hero',
              ),
              child: const Text('Open Entangle'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Entangle'));
    await tester.pumpAndSettle();

    expect(find.text('Entangle'), findsOneWidget);
    expect(find.text('A player afflicted with this token gets 1 fewer Roll Attempts.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Entangle'), findsNothing);
  });

  test('GameDie with isHexed treats 6 as blank (null)', () {
    final die = GameDie(id: 1);
    die.value = 6;
    expect(die.effectiveValue, 6);
    expect(die.symbol, isNotNull);

    die.isHexed = true;
    expect(die.effectiveValue, isNull);
    expect(die.symbol, isNull);

    die.value = 5;
    expect(die.effectiveValue, 5);
    expect(die.symbol, DieSymbol.yellow);
  });

  testWidgets('TokenAnimationDialog for persistent token (Targeted) displays mask checkbox and returns result', (WidgetTester tester) async {
    const targetedRule = StatusTokenRule(
      label: 'Targeted',
      frLabel: 'Pris pour cible',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: true,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'Incoming Attack damage is increased by 2.',
    );

    TokenAnimationResult? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await TokenAnimationDialog.show(
                  context,
                  rule: targetedRule,
                  initialCount: 1,
                  targetName: 'Gobelin',
                );
              },
              child: const Text('Open Targeted'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Targeted'));
    await tester.pumpAndSettle();

    expect(find.text('Targeted'), findsOneWidget);
    expect(find.text('Hide future reminders'), findsOneWidget);

    // Tap the checkbox to check it
    await tester.tap(find.text('Hide future reminders'));
    await tester.pumpAndSettle();

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(dialogResult, isNotNull);
    expect(dialogResult!.dontShowAgain, isTrue);
  });

  testWidgets('CombatAiChatDock renders Targeted banner when defender has Targeted', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;
    enemy.alterations.add('Targeted');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero attacks targeted enemy',
            phase: CombatPhase.hero,
            adventure: adventure,
            enemy: enemy,
            primaryEnemy: enemy,
            canSwitchTarget: false,
            onSelectTarget: (_) {},
            returnDamage: 0,
            returnDamageUndefendable: false,
            lifeSteal: 0,
            enemyHeal: 0,
            cpSteal: 0,
            heroTokens: adventure.alterations,
            minionTokens: enemy.alterations,
            notes: const [],
            showResolution: true,
            attackValue: 5,
            defenseValue: 0,
            onAttackChanged: (_) {},
            onDefenseChanged: (_) {},
            onApply: () {},
            onFinish: null,
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Targeted banner is rendered with active indicator
    expect(find.text('Targeted : '), findsOneWidget);
    expect(find.text('Actif (+2)'), findsOneWidget);
  });

  testWidgets('showAlterationDialog displays Duel, Positive, Negative, Unique segments', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAlterationDialog(context, const ['Targeted']),
              child: const Text('Open Alterations'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Alterations'));
    await tester.pumpAndSettle();

    expect(find.text('Duel'), findsOneWidget);
    expect(find.text('Positive'), findsOneWidget);
    expect(find.text('Negative'), findsOneWidget);
    expect(find.text('Unique'), findsOneWidget);
  });

  testWidgets('showAlterationDialog with isMapPage: true and empty tokens defaults to Negative tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAlterationDialog(context, const [], isMapPage: true),
              child: const Text('Open Map Alterations Empty'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Map Alterations Empty'));
    await tester.pumpAndSettle();

    // Verify dialog opened without error
    expect(find.text('Status tokens'), findsOneWidget);
    expect(find.text('Negative'), findsOneWidget);
  });

  testWidgets('TokenOrderingDialog displays timeline preview, items, and returns reordered list', (WidgetTester tester) async {
    const poisonRule = StatusTokenRule(
      label: 'Poison',
      frLabel: 'Poison',
      kind: StatusTokenKind.negative,
      maxStack: 5,
      persistent: true,
      removable: true,
      appSupported: true,
      description: 'Deals 1 damage per token at start of turn.',
    );
    const burnRule = StatusTokenRule(
      label: 'Burn',
      frLabel: 'Brûlure',
      kind: StatusTokenKind.negative,
      maxStack: 3,
      persistent: true,
      removable: true,
      appSupported: true,
      description: 'Deals 2 damage at start of turn.',
    );
    List<StatusTokenRule>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TokenOrderingDialog.show(
                  context,
                  rules: const [poisonRule, burnRule],
                  targetName: 'Hero',
                  isRollPhase: false,
                );
              },
              child: const Text('Open Ordering Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Ordering Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Token Resolution Order'), findsOneWidget);
    expect(find.text('Target: Hero • Upkeep Phase'), findsOneWidget);
    expect(find.text('Confirm Order'), findsOneWidget);

    // Tap confirm order
    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, equals(2));
    expect(result![0].label, equals('Poison'));
    expect(result![1].label, equals('Burn'));
  });

  testWidgets('TokenAnimationDialog with Evasive allows die roll and success on 1-2', (WidgetTester tester) async {
    const evasiveRule = StatusTokenRule(
      label: 'Evasive',
      frLabel: 'Evitement',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: true,
      persistence: TokenPersistence.semiPersistent,
      removable: true,
      appSupported: true,
      description: 'Roll 1 die. If 1-2, no damage received.',
    );

    TokenAnimationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TokenAnimationDialog.show(
                  context,
                  rule: evasiveRule,
                  initialCount: 1,
                  targetName: 'Minion',
                );
              },
              child: const Text('Open Evasive Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Evasive Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Evasive'), findsWidgets);
    expect(find.text('Evasive Roll (1 D6)'), findsOneWidget);
    expect(find.text('Roll Die'), findsOneWidget);
    expect(find.text('Edit Die'), findsOneWidget);

    // Click Edit Die to pick face 1
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();

    // Tap face '1'
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('Evasive roll: 1 -> Attack Avoided! (0 Damage taken)'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.count, equals(1));
  });

  testWidgets('TokenAnimationDialog with Evasive allows die roll and failure on 3-6', (WidgetTester tester) async {
    const evasiveRule = StatusTokenRule(
      label: 'Evasive',
      frLabel: 'Evitement',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: true,
      persistence: TokenPersistence.semiPersistent,
      removable: true,
      appSupported: true,
      description: 'Roll 1 die. If 1-2, no damage received.',
    );

    TokenAnimationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TokenAnimationDialog.show(
                  context,
                  rule: evasiveRule,
                  initialCount: 1,
                  targetName: 'Minion',
                );
              },
              child: const Text('Open Evasive Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Evasive Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Evasive Roll (1 D6)'), findsOneWidget);

    // Click Edit Die to pick face 4
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();

    // Tap face '4'
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();

    // Verify failure message
    expect(find.text('Evasive roll: 4 -> Evasive Failed! (Normal damage applies)'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.count, equals(4));
  });

  testWidgets('TokenAnimationDialog for Burn displays -2 HP and Hide future reminders checkbox', (WidgetTester tester) async {
    const burnRule = StatusTokenRule(
      label: 'Burn',
      frLabel: 'Brûlure',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: true,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/burn.png',
      description: 'A player afflicted with this token is dealt 2 dmg during their Upkeep Phase. Persistent.',
      aliases: ['Brûlure', 'Burn'],
      appDetails: 'Géré automatiquement en phase Upkeep (-2 PV, persistant).',
      appAnimation: true,
      minionAllowed: true,
      editorVisible: true,
    );

    TokenAnimationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TokenAnimationDialog.show(
                  context,
                  rule: burnRule,
                  initialCount: 1,
                  targetName: 'Hero',
                  currentHp: 20,
                );
              },
              child: const Text('Open Burn Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Burn Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Burn'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('18'), findsOneWidget); // 20 - 2 = 18
    expect(find.text('Hide future reminders'), findsOneWidget);

    // Toggle hide checkbox
    await tester.tap(find.text('Hide future reminders'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dontShowAgain, isTrue);
  });

  testWidgets('TokenAnimationDialog for Knockdown displays CP delta', (WidgetTester tester) async {
    const knockdownRule = StatusTokenRule(
      label: 'Knockdown',
      frLabel: 'A terre',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      persistence: TokenPersistence.nonPersistent,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/A-terre.png',
      description: 'A player afflicted with this token loses 2 CP during their Upkeep Phase.',
      aliases: ['A terre', 'Knockdown'],
      appDetails: 'En phase Upkeep : déduit 2 PC.',
      appAnimation: true,
      minionAllowed: true,
      editorVisible: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: knockdownRule,
                initialCount: 1,
                targetName: 'Hero',
                currentCp: 3,
              ),
              child: const Text('Open Knockdown Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Knockdown Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Knockdown'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 3 - 2 = 1
    expect(find.textContaining('before +1 CP upkeep'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog for Delayed Poison displays -3 HP per token', (WidgetTester tester) async {
    const delayedPoisonRule = StatusTokenRule(
      label: 'Delayed Poison',
      frLabel: 'Poison latent',
      kind: StatusTokenKind.negative,
      maxStack: 2,
      persistent: false,
      persistence: TokenPersistence.nonPersistent,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/Delayed-Poison.png',
      description: 'A player inflicted with this token removes it at the conclusion of their turn and receives 3 dmg.',
      aliases: ['Delayed Poison', 'Poison latent'],
      appDetails: 'Géré en fin de tour.',
      appAnimation: true,
      minionAllowed: true,
      editorVisible: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: delayedPoisonRule,
                initialCount: 2,
                targetName: 'Hero',
                currentHp: 20,
              ),
              child: const Text('Open Delayed Poison Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Delayed Poison Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Delayed Poison (x2)'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('14'), findsOneWidget); // 20 - 2*3 = 14
  });
}
