import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/models/enemy_profile.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TokenCatalogRepository.load();
  });

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
      persistent: false,
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
    expect(find.text('Hide future reminders'), findsNothing);

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
    expect(result!.spentCount, equals(1));
  });

  testWidgets('TokenAnimationDialog with Evasive allows die roll and failure on 3-6', (WidgetTester tester) async {
    const evasiveRule = StatusTokenRule(
      label: 'Evasive',
      frLabel: 'Evitement',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: false,
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
    expect(find.text('Hide future reminders'), findsNothing);

    // Click Edit Die to pick face 4
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();

    // Tap face '4'
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();

    // Verify failure message (only 1 token, so 0 remaining)
    expect(find.text('Evasive roll: 4 -> Evasive Failed! (Normal damage applies)'), findsOneWidget);
    expect(find.textContaining('Use again'), findsNothing);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.count, equals(1));
    expect(result!.dieRoll, equals(4));
    expect(result!.spentCount, equals(1));
  });

  testWidgets('TokenAnimationDialog with multi-stack Evasive offers Utiliser de nouveau button on failure', (WidgetTester tester) async {
    const evasiveRule = StatusTokenRule(
      label: 'Evasive',
      frLabel: 'Evitement',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: false,
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
                  initialCount: 3,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Multi Evasive Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Multi Evasive Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Hide future reminders'), findsNothing);

    // Fail first roll with face 4
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();

    // 2 tokens remaining out of 3, so button shows 'Use again (2)'
    expect(find.text('Evasive roll: 4 -> Failed. (2 token(s) remaining)'), findsOneWidget);
    expect(find.text('Use again (2)'), findsOneWidget);

    // Click 'Use again (2)' to spend 2nd token
    await tester.tap(find.text('Use again (2)'));
    await tester.pumpAndSettle();

    // Now edit face to 1 (success)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();

    expect(find.text('Evasive roll: 1 -> Attack Avoided! (0 Damage taken)'), findsOneWidget);
    // Success -> reroll button should not appear
    expect(find.textContaining('Use again'), findsNothing);

    // Click OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.spentCount, equals(2));
  });

  testWidgets('TokenAnimationDialog with multi-stack Evasive allows player to decline reroll and click OK', (WidgetTester tester) async {
    const evasiveRule = StatusTokenRule(
      label: 'Evasive',
      frLabel: 'Evitement',
      kind: StatusTokenKind.positive,
      maxStack: 3,
      persistent: false,
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
                  initialCount: 3,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Multi Evasive Dialog 2'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Multi Evasive Dialog 2'));
    await tester.pumpAndSettle();

    // Fail first roll with face 5
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.text('Use again (2)'), findsOneWidget);

    // Player decides not to reroll and taps OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.spentCount, equals(1));
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

  testWidgets('TokenAnimationDialog for Concussion displays only OK button without Edit button', (WidgetTester tester) async {
    const concussionRule = StatusTokenRule(
      label: 'Concussion',
      frLabel: 'Commotion',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/concussion.png',
      description: 'A player afflicted with this token skips gaining CP during their Upkeep Phase and then removes this token.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: concussionRule,
                initialCount: 1,
                targetName: 'Hero',
                currentCp: 2,
              ),
              child: const Text('Open Concussion Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Concussion Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Concussion'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Hide future reminders'), findsNothing);
  });

  testWidgets('TokenAnimationDialog for Stun displays only OK button without Edit button', (WidgetTester tester) async {
    const stunRule = StatusTokenRule(
      label: 'Stun',
      frLabel: 'Étourdissement',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/stun.png',
      description: 'A player afflicted with this token may take no actions of any kind.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: stunRule,
                initialCount: 1,
                targetName: 'Gobelin',
              ),
              child: const Text('Open Stun Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Stun Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Stun'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Hide future reminders'), findsNothing);
  });

  testWidgets('TokenAnimationDialog increments cannot exceed rule.maxStack', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Burn',
      frLabel: 'Brûlure',
      kind: StatusTokenKind.negative,
      maxStack: 3,
      persistent: true,
      removable: true,
      appSupported: true,
      description: 'Deals 2 dmg at upkeep.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => TokenAnimationDialog.show(
                context,
                rule: rule,
                initialCount: 2,
                targetName: 'Hero',
              ),
              child: const Text('Open Burn'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Burn'));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    final addIcon = find.byIcon(Icons.add_circle_outline);
    // Tap to increment to 3 (maxStack)
    await tester.tap(addIcon, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);

    // Tap again when already at maxStack (3)
    await tester.tap(addIcon, warnIfMissed: false);
    await tester.pumpAndSettle();
    // Count should still be 3
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog with Time Bomb 1 rolls 1-5 transitions to Time Bomb 2 and does not offer reroll', (WidgetTester tester) async {
    const timeBomb1Rule = StatusTokenRule(
      label: 'Time bomb 1',
      frLabel: 'Bombe à retardement 1',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/time-bomb-2.webp',
      description: 'Roll 1 die during Upkeep. 1-5: advances to Time bomb 2. 6: transfers to opponent.',
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
                  rule: timeBomb1Rule,
                  initialCount: 1,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Time Bomb 1'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Time Bomb 1'));
    await tester.pumpAndSettle();

    expect(find.text('Time Bomb 1 (1 D6)'), findsOneWidget);
    expect(find.text('Hide future reminders'), findsNothing);

    // Edit die to 3 (1-5)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(find.text('Time bomb roll: 3 -> Transforms into Time Bomb 2!'), findsOneWidget);
    expect(find.textContaining('Use again'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(3));
    expect(result!.count, equals(1));
  });

  testWidgets('TokenAnimationDialog with Time Bomb 1 rolls 6 transfers to opponent', (WidgetTester tester) async {
    const timeBomb1Rule = StatusTokenRule(
      label: 'Time bomb 1',
      frLabel: 'Bombe à retardement 1',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/time-bomb-2.webp',
      description: 'Roll 1 die during Upkeep. 1-5: advances to Time bomb 2. 6: transfers to opponent.',
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
                  rule: timeBomb1Rule,
                  initialCount: 1,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Time Bomb 1 - Roll 6'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Time Bomb 1 - Roll 6'));
    await tester.pumpAndSettle();

    expect(find.text('Time Bomb 1 (1 D6)'), findsOneWidget);

    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();

    expect(find.text('Time bomb roll: 6 -> Transferred to opponent!'), findsOneWidget);
    expect(find.textContaining('Use again'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(6));
    expect(result!.count, equals(1));
  });

  testWidgets('TokenAnimationDialog with Time Bomb 2 rolls 1-5 explodes and rolls 6 transfers', (WidgetTester tester) async {
    const timeBomb2Rule = StatusTokenRule(
      label: 'Time bomb 2',
      frLabel: 'Bombe à retardement 2',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/token-time-bomb-1.webp',
      description: 'Roll 1 die during Upkeep. 1-5: explodes for 4 undefendable dmg. 6: transfers to opponent.',
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
                  rule: timeBomb2Rule,
                  initialCount: 1,
                  targetName: 'Hero',
                  currentHp: 20,
                );
              },
              child: const Text('Open Time Bomb 2'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Time Bomb 2'));
    await tester.pumpAndSettle();

    expect(find.text('Time Bomb 2 (1 D6)'), findsOneWidget);

    // Roll 2 -> explodes
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(find.text('Time bomb roll: 2 -> Explodes! (4 undefendable dmg)'), findsOneWidget);
    expect(find.textContaining('Use again'), findsNothing);

    // Roll 6 -> transfer
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();

    expect(find.text('Time bomb roll: 6 -> Transferred to opponent!'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(6));
    expect(result!.count, equals(1));
  });

  testWidgets('TokenAnimationDialog with Agility rolls 1-3 halves damage and 4-6 fails', (WidgetTester tester) async {
    const agilityRule = StatusTokenRule(
      label: 'Agility',
      frLabel: 'Agilité',
      kind: StatusTokenKind.positive,
      maxStack: 2,
      persistent: false,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/Agility.webp',
      description: 'Spend to roll 1 die. 1-3: halve damage. 2 Agility: avoid all damage.',
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
                  rule: agilityRule,
                  initialCount: 1,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Agility 1'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Agility 1'));
    await tester.pumpAndSettle();

    expect(find.text('Agility Roll (1 D6)'), findsOneWidget);

    // Roll 2 -> succeeds (halves damage)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(find.text('Agility roll: 2 -> Success! (1/2 damage prevented)'), findsOneWidget);
    expect(find.textContaining('Use again'), findsNothing);

    // Roll 5 -> fails
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.text('Agility roll: 5 -> Failed! (0 damage prevented)'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(5));
    expect(result!.agilitySuccessCount, equals(0));
    expect(result!.spentCount, equals(1));
  });

  testWidgets('TokenAnimationDialog with 2 Agility tokens allows using second token and stacks successes', (WidgetTester tester) async {
    const agilityRule = StatusTokenRule(
      label: 'Agility',
      frLabel: 'Agilité',
      kind: StatusTokenKind.positive,
      maxStack: 2,
      persistent: false,
      removable: true,
      appSupported: true,
      imageAsset: 'assets/token/Agility.webp',
      description: 'Spend to roll 1 die. 1-3: halve damage. 2 Agility: avoid all damage.',
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
                  rule: agilityRule,
                  initialCount: 2,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Agility 2'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Agility 2'));
    await tester.pumpAndSettle();

    expect(find.text('Agility Roll (1 D6)'), findsOneWidget);

    // Roll 1: edit to 2 (success)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(find.text('Agility roll: 2 -> Success! (1/2 damage prevented)'), findsOneWidget);
    expect(find.textContaining('Use again'), findsOneWidget);

    // Tap "Use again" to spend second token
    await tester.tap(find.textContaining('Use again'));
    await tester.pumpAndSettle();

    expect(find.text('Agility Roll 2 (1 D6)'), findsOneWidget);

    // Roll 2: edit to 3 (success)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(find.text('Agility rolls: 2, 3 -> 2 Successes! Attack Avoided! (0 Damage taken)'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.agilitySuccessCount, equals(2));
    expect(result!.spentCount, equals(2));
    expect(result!.allDiceRolls, equals([2, 3]));
  });

  testWidgets('TokenAnimationDialog for Bleed has no close button and requires die roll before OK', (WidgetTester tester) async {
    const bleedRule = StatusTokenRule(
      label: 'Bleed',
      frLabel: 'Hémorragie',
      kind: StatusTokenKind.negative,
      maxStack: 2,
      persistent: true,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/Bleed.png',
      description: 'In Dice Throne, Bleed is a negative status effect with a stack limit of 2 that deals damage or gets removed during your upkeep phase.',
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
                  rule: bleedRule,
                  initialCount: 1,
                  targetName: 'Barbarian',
                  currentHp: 20,
                );
              },
              child: const Text('Open Bleed'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Bleed'));
    await tester.pumpAndSettle();

    // Verification that close X button is absent (cannot dismiss without rolling)
    expect(find.byIcon(Icons.close), findsNothing);
    // OK button not visible before rolling
    expect(find.text('OK'), findsNothing);
    expect(find.text('Bleed Roll (1 D6)'), findsOneWidget);

    // Roll die with 3
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(find.text('Bleed roll: 3 -> Deals 1 Damage! Token remains.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Verify HP preview: 20 -> 19
    expect(find.text('20'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(3));
    expect(result!.count, equals(1)); // token remains
    expect(result!.allDiceRolls, equals([3]));
  });

  testWidgets('TokenAnimationDialog for Bleed rolls 5-6 removes token', (WidgetTester tester) async {
    const bleedRule = StatusTokenRule(
      label: 'Bleed',
      frLabel: 'Hémorragie',
      kind: StatusTokenKind.negative,
      maxStack: 2,
      persistent: true,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/Bleed.png',
      description: 'In Dice Throne, Bleed is a negative status effect with a stack limit of 2 that deals damage or gets removed during your upkeep phase.',
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
                  rule: bleedRule,
                  initialCount: 1,
                  targetName: 'Barbarian',
                  currentHp: 20,
                );
              },
              child: const Text('Open Bleed 6'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Bleed 6'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();

    expect(find.text('Bleed roll: 6 -> Token Removed! (0 Damage)'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(6));
    expect(result!.count, equals(0)); // token removed
    expect(result!.allDiceRolls, equals([6]));
  });

  testWidgets('TokenAnimationDialog for 2 Bleed tokens allows resolving second token immediately', (WidgetTester tester) async {
    const bleedRule = StatusTokenRule(
      label: 'Bleed',
      frLabel: 'Hémorragie',
      kind: StatusTokenKind.negative,
      maxStack: 2,
      persistent: true,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/Bleed.png',
      description: 'In Dice Throne, Bleed is a negative status effect with a stack limit of 2 that deals damage or gets removed during your upkeep phase.',
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
                  rule: bleedRule,
                  initialCount: 2,
                  targetName: 'Barbarian',
                  currentHp: 20,
                );
              },
              child: const Text('Open Bleed 2 Tokens'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Bleed 2 Tokens'));
    await tester.pumpAndSettle();

    // Roll 1: set to 2
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(find.text('Bleed roll: 2 -> Deals 1 Damage! Token remains.'), findsOneWidget);
    expect(find.textContaining('Resolve next token'), findsOneWidget);

    // Tap "Resolve next token"
    await tester.tap(find.textContaining('Resolve next token'));
    await tester.pumpAndSettle();

    expect(find.text('Bleed Roll 2 (1 D6)'), findsOneWidget);
    // OK button should be hidden again until second die is rolled
    expect(find.text('OK'), findsNothing);

    // Roll 2: set to 5
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.text('Bleed rolls: 2, 5 -> 1 Damage taken, 1 Token(s) removed'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.spentCount, equals(2));
    expect(result!.allDiceRolls, equals([2, 5]));
    expect(result!.count, equals(1)); // 2 initial - 1 removed (from 5) = 1 remaining
  });

  testWidgets('TokenAnimationDialog with 2 Time Bomb 1 tokens allows resolving second token immediately', (tester) async {
    const rule = StatusTokenRule(
      label: 'Time bomb 1',
      frLabel: 'Bombe à retardement 1',
      kind: StatusTokenKind.negative,
      maxStack: 2,
      persistent: true,
      removable: true,
      appSupported: true,
      appAnimation: true,
      imageAsset: 'assets/token/TimeBomb1.png',
      description: 'Roll 1 die. 1-5: transforms into Time bomb 2. 6: transferred to opponent.',
    );
    TokenAnimationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await TokenAnimationDialog.show(
                context,
                rule: rule,
                initialCount: 2,
                targetName: 'Hero',
                currentHp: 20,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Roll 1: set to 3 -> transforms to Time Bomb 2
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Resolve next token'), findsOneWidget);

    // Tap "Resolve next token"
    await tester.tap(find.textContaining('Resolve next token'));
    await tester.pumpAndSettle();

    // Roll 2: set to 6 -> transfers to opponent
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.spentCount, equals(2));
    expect(result!.allDiceRolls, equals([3, 6]));
  });

  testWidgets('CombatAiChatDock with Shadows token in defense phase is automatically active with Actif and covers attack with Shadows (0 DMG) without Use button', (tester) async {
    final adventure = AdventureState(
      config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget),
      hero: HeroType.shadowThief,
    );
    adventure.setAlterations(['Shadows']);
    final enemy = adventure.enemies.first;

    const bool shadowsActive = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: false,
            aiMessage: 'Minion attack',
            phase: CombatPhase.minionAttack,
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
            attackValue: 7,
            defenseValue: 2,
            shadowsActive: shadowsActive,
            heroShadowsCount: 1,
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

    // Verify Shadows row is shown with 'Actif' badge and NO 'Use' button
    expect(find.text('Shadows'), findsWidgets);
    expect(find.text('Use'), findsNothing);
    expect(find.text('Actif'), findsOneWidget);

    // Attack counter is immediately covered by 'Shadows (0 DMG)'
    expect(find.text('Shadows (0 DMG)'), findsOneWidget);
    // Defense value 2 is STILL visible
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog with Sneak Attack rolls 1-6 computes ceil(roll / 2) bonus and returns in TokenAnimationResult', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Sneak Attack',
      frLabel: 'Attaque furtive',
      kind: StatusTokenKind.positive,
      maxStack: 2,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'Spend to roll 1 D6 and add half rounded up to attack.',
    );

    TokenAnimationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await TokenAnimationDialog.show(
                    context,
                    rule: rule,
                    initialCount: 1,
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

    expect(find.text('Sneak Attack'), findsOneWidget);
    expect(find.text('Sneak Attack Roll (1 D6)'), findsOneWidget);
    // OK button is NOT shown until die is rolled
    expect(find.text('OK'), findsNothing);

    // Click 'Edit Die' to choose a specific value (e.g., 3)
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();

    // Select value 3 (half rounded up of 3 is 2)
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // Verify result text says: Sneak Attack roll: 3 -> +2 Attack Modifier!
    expect(find.text('Sneak Attack roll: 3 -> +2 Attack Modifier!'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(3));
    expect(result!.sneakAttackBonus, equals(2));
  });

  testWidgets('CombatAiChatDock with Sneak Attack displays Use button when damage passes and Actif (+bonus) when active', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final adventure = AdventureState(
      config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget),
      hero: HeroType.shadowThief,
    );
    adventure.setAlterations(['Sneak Attack']);
    final enemy = adventure.enemies.first;

    var sneakAttackActive = false;
    var sneakAttackBonus = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CombatAiChatDock(
              aiMode: false,
              aiMessage: '',
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
              defenseValue: 2,
              attackerSneakAttackCount: sneakAttackActive ? 0 : 1,
              attackerSneakAttackActive: sneakAttackActive,
              attackerSneakAttackBonus: sneakAttackBonus,
              canUseAttackerSneakAttack: true,
              onUseAttackerSneakAttack: () {
                setState(() {
                  sneakAttackActive = true;
                  sneakAttackBonus = 2;
                });
              },
              onAttackChanged: (_) {},
              onDefenseChanged: (_) {},
              onApply: () {},
              onFinish: null,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Sneak Attack row is shown with 'Use' button
    expect(find.text('Sneak Attack'), findsWidgets);
    expect(find.text('Use'), findsOneWidget);

    // Tap Use
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();

    // Now row shows Actif (+2)
    expect(find.text('Actif (+2)'), findsOneWidget);
  });

  testWidgets('CombatAiChatDock with Sneak Attack disables Use button when canUseAttackerSneakAttack is false', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final adventure = AdventureState(
      config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget),
      hero: HeroType.shadowThief,
    );
    adventure.setAlterations(['Sneak Attack']);
    final enemy = adventure.enemies.first;

    var used = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: false,
            aiMessage: '',
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
            attackValue: 0, // 0 damage
            defenseValue: 0,
            attackerSneakAttackCount: 1,
            attackerSneakAttackActive: false,
            attackerSneakAttackBonus: 0,
            canUseAttackerSneakAttack: false, // disabled because 0 damage passes
            onUseAttackerSneakAttack: () {
              used = true;
            },
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

    final useButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Use'));
    expect(useButton.onPressed, isNull);

    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(used, isFalse);
  });

  testWidgets('TokenAnimationDialog unitary upkeep displays -1 HP for 1 Poison token with running HP', (WidgetTester tester) async {
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
                    targetName: 'Hero',
                    currentHp: 20,
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

    // Dialog title must be 'Poison', not 'Poison (x3)'
    expect(find.text('Poison'), findsOneWidget);
    // HP must show 20 -> 19 (unitary -1 HP)
    expect(find.text('20'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog for Barbed Vine displays info only with OK button', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Barbed Vine',
      frLabel: 'Ronces',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'A player afflicted with this token receives 1 dmg for each Roll Attempt beyond the first...',
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
                    targetName: 'Hero',
                  );
                },
                child: const Text('Open Barbed Vine'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Barbed Vine'));
    await tester.pumpAndSettle();

    expect(find.text('Barbed Vine'), findsOneWidget);
    expect(find.text('Triggered on Hero'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Barbed Vine'), findsNothing);
  });

  testWidgets('CombatAiChatDock displays Barbed Vine row with Actif badge during roll phase', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Minion attack roll phase',
            phase: CombatPhase.minionAttack,
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
            barbedVineActive: true,
            barbedVineCount: 1,
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

    expect(find.text('Barbed Vine'), findsWidgets);
    expect(find.text('Actif'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog for Constrict displays info only with OK button', (WidgetTester tester) async {
    const rule = StatusTokenRule(
      label: 'Constrict',
      frLabel: 'Compression',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'A player afflicted with this token must pay 1 CP for each Roll Attempt beyond the first.',
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
                    targetName: 'Hero',
                  );
                },
                child: const Text('Open Constrict'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Constrict'));
    await tester.pumpAndSettle();

    expect(find.text('Constrict'), findsOneWidget);
    expect(find.text('Triggered on Hero'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Constrict'), findsNothing);
  });

  testWidgets('CombatAiChatDock displays Constrict row with Actif badge during roll phase', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Minion attack roll phase',
            phase: CombatPhase.minionAttack,
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
            constrictActive: true,
            constrictCount: 1,
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

    expect(find.text('Constrict'), findsWidgets);
    expect(find.text('Actif'), findsOneWidget);
  });

  testWidgets('TokenAnimationDialog with Wellspring rolls 1 D6 and calculates heal (ceil(die/2))', (WidgetTester tester) async {
    const wellspringRule = StatusTokenRule(
      label: 'Wellspring',
      frLabel: 'Source',
      kind: StatusTokenKind.positive,
      maxStack: 1,
      persistent: false,
      persistence: TokenPersistence.semiPersistent,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'Spend during Upkeep or Roll Phase: roll 1 die and gain half value as HP (rounded up).',
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
                  rule: wellspringRule,
                  initialCount: 1,
                  targetName: 'Hero',
                  currentHp: 20,
                );
              },
              child: const Text('Open Wellspring'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Wellspring'));
    await tester.pumpAndSettle();

    expect(find.text('Wellspring'), findsWidgets);
    expect(find.text('Wellspring Roll (1 D6)'), findsOneWidget);

    // Pick die face 5 -> heal should be ceil(5/2) = 3
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(find.text('Wellspring roll: 5 -> +3 Health restored!'), findsOneWidget);

    // Verify HP preview updates from 20 to 23
    expect(find.text('20'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(5));
  });

  testWidgets('CombatAiChatDock renders Wellspring row with Use button during Upkeep/Hero phase', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;
    bool wellspringUsed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero upkeep phase',
            phase: CombatPhase.heroUpkeep,
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
            heroTokens: const ['Wellspring'],
            minionTokens: const [],
            notes: const [],
            showResolution: false,
            attackValue: 0,
            defenseValue: 0,
            heroWellspringCount: 1,
            onUseHeroWellspring: () => wellspringUsed = true,
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

    expect(find.text('Wellspring'), findsWidgets);
    final useButton = find.widgetWithText(ElevatedButton, 'Use');
    expect(useButton, findsOneWidget);

    await tester.tap(useButton);
    await tester.pumpAndSettle();
    expect(wellspringUsed, isTrue);
  });

  testWidgets('CombatAiChatDock covers ATK with Blinding Light button and masks OK button', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;
    bool blindingLightPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero attack phase',
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
            heroTokens: const ['Blinding Light'],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 6,
            defenseValue: 0,
            showBlindingLightAttackCover: true,
            onBlindingLightPressed: () => blindingLightPressed = true,
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

    // Verify Blinding Light covers ATK
    final coverButton = find.widgetWithText(ElevatedButton, 'Blinding Light');
    expect(coverButton, findsOneWidget);

    // Verify OK button is hidden/invisible
    final okButtonFinder = find.widgetWithText(Visibility, 'OK');
    expect(okButtonFinder, findsOneWidget);
    final visibilityWidget = tester.widget<Visibility>(okButtonFinder);
    expect(visibilityWidget.visible, isFalse);

    await tester.tap(coverButton);
    await tester.pumpAndSettle();
    expect(blindingLightPressed, isTrue);
  });

  testWidgets('TokenAnimationDialog with Blinding Light handles roll 1, 2, and 4 outcomes', (WidgetTester tester) async {
    const blindingRule = StatusTokenRule(
      label: 'Blinding Light',
      frLabel: 'Lumière aveuglante',
      kind: StatusTokenKind.negative,
      maxStack: 1,
      persistent: false,
      persistence: TokenPersistence.nonPersistent,
      removable: true,
      appSupported: true,
      appAnimation: true,
      description: 'Roll 1: on 1 attack fails, on 2-3 damage is halved, on 4-6 full damage.',
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
                  rule: blindingRule,
                  initialCount: 1,
                  targetName: 'Hero',
                );
              },
              child: const Text('Open Blinding Light'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Blinding Light'));
    await tester.pumpAndSettle();

    expect(find.text('Blinding Light'), findsWidgets);
    expect(find.text('Blinding Light Roll (1 D6)'), findsOneWidget);

    // Roll 1: Offensive Ability fails
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    expect(find.text('Blinding Light roll: 1 -> Attack fails to activate! (0 damage dealt)'), findsOneWidget);

    // Roll 3: damage halved
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    expect(find.text('Blinding Light roll: 3 -> Attack damage reduced by 1/2 (rounded up)'), findsOneWidget);

    // Roll 4: full damage
    await tester.tap(find.text('Edit Die'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    expect(find.text('Blinding Light roll: 4 -> Attack succeeds normally! (Full damage)'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dieRoll, equals(4));
  });

  testWidgets('CombatAiChatDock displays locked 0 damage in green when Blinding Light rolls 1', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero attack failed',
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
            heroTokens: const [],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 0,
            defenseValue: 0,
            blindingLightZeroDamage: true,
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

    expect(find.text('0'), findsWidgets);
    // When locked, + and - buttons on ATK counter should not be rendered
    expect(find.byTooltip('Add'), findsOneWidget); // Only DEF has Add
    expect(find.byTooltip('Remove'), findsOneWidget); // Only DEF has Remove
  });

  testWidgets('CombatAiChatDock displays base attack and -reduced damage modifier when Blinding Light rolls 2-3', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero attack halved',
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
            heroTokens: const [],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 3,
            defenseValue: 0,
            blindingLightBaseAttack: 6,
            blindingLightReducedDamage: 3,
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

    // Base attack displayed is 6, modifier is -3
    expect(find.text('6'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
  });

  testWidgets('CompactItemBadge renders StatusTokenImage and not "BA" for Barbed Vine_active', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompactItemBadge(
            value: 'BA',
            tooltip: 'Barbed Vine_active',
            color: Colors.green,
            size: 24,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Must find StatusTokenImage and NOT find text 'BA'
    expect(find.byType(StatusTokenImage), findsOneWidget);
    expect(find.text('BA'), findsNothing);
  });

  test('minionAttackAiMessage explains stopping early when afflicted with Barbed Vine', () {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemySuite = EnemyNode(
      id: 99,
      label: 'Suite Minion',
      rank: EnemyRank.green,
      maxHealth: 20,
      cp: 2,
      attacks: const ['Suite attack: 5 damage'],
      defense: 'Defense',
      defenseDice: 1,
      attackPlan: const MinionAttackPlan.suite(),
      cardAsset: '',
    );
    enemySuite.alterations.add('Barbed Vine');

    // Roll 0 (Suite): minion states it will stop rolling as soon as a suite is validated
    final msgRoll0 = minionAttackAiMessage(
      enemySuite,
      [],
      0,
      adventure,
      '',
    );
    expect(msgRoll0, contains('Afflicted by Barbed Vine'));
    expect(msgRoll0, contains('I will stop rolling as soon as a suite is validated to avoid counter damage.'));

    // Roll 1 with micro suite (1, 2, 3, 5, 6): minion validates micro suite and stops early
    final diceSuite = [
      GameDie(id: 1, value: 1, reserved: true),
      GameDie(id: 2, value: 2, reserved: true),
      GameDie(id: 3, value: 3, reserved: true),
      GameDie(id: 4, value: 5, reserved: false),
      GameDie(id: 5, value: 6, reserved: false),
    ];
    final msgRoll1Suite = minionAttackAiMessage(
      enemySuite,
      diceSuite,
      1,
      adventure,
      '',
    );
    expect(msgRoll1Suite, contains('Afflicted by Barbed Vine, I stop my attack rolls here to avoid taking counter damage.'));

    // Roll 1 without valid suite (1, 1, 1, 5, 6): minion states rerolling inflicts 1 counter damage
    final diceNoSuite = [
      GameDie(id: 1, value: 1, reserved: false),
      GameDie(id: 2, value: 1, reserved: false),
      GameDie(id: 3, value: 1, reserved: false),
      GameDie(id: 4, value: 5, reserved: false),
      GameDie(id: 5, value: 6, reserved: false),
    ];
    final msgRoll1NoSuite = minionAttackAiMessage(
      enemySuite,
      diceNoSuite,
      1,
      adventure,
      '',
    );
    expect(msgRoll1NoSuite, contains('Afflicted by Barbed Vine: rerolling will inflict 1 counter damage on me.'));

    // Symbol minion
    final enemySymbol = adventure.enemies.first;
    enemySymbol.alterations.add('Barbed Vine');
    final msgRoll0Symbol = minionAttackAiMessage(
      enemySymbol,
      [],
      0,
      adventure,
      '',
    );
    expect(msgRoll0Symbol, contains('Afflicted by Barbed Vine'));
    expect(msgRoll0Symbol, contains('I will stop rolling as soon as an attack is validated to avoid counter damage.'));
  });

  testWidgets('CombatAiChatDock interprets Blinding Light rolls in chat text', (WidgetTester tester) async {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = adventure.enemies.first;

    Finder findChatText(String text) => find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains(text),
        );

    // Test 1: roll 1 (failure, 0 damage)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero phase',
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
            heroTokens: const [],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 0,
            defenseValue: 0,
            blindingLightRoll: 1,
            blindingLightZeroDamage: true,
            blindingLightBaseAttack: 6,
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
    expect(
      findChatText('Blinding Light (D6: 1) on ${adventure.hero.label}: Offensive Ability fails to activate! 0 damage dealt.'),
      findsOneWidget,
    );

    // Test 2: roll 2 (halved damage)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero phase',
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
            heroTokens: const [],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 3,
            defenseValue: 0,
            blindingLightRoll: 2,
            blindingLightReducedDamage: 3,
            blindingLightBaseAttack: 6,
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
    expect(
      findChatText('Blinding Light (D6: 2) on ${adventure.hero.label}: Attack damage is reduced by half (-3). Net attack: 3.'),
      findsOneWidget,
    );

    // Test 3: roll 5 (full damage)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CombatAiChatDock(
            aiMode: true,
            aiMessage: 'Hero phase',
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
            heroTokens: const [],
            minionTokens: const [],
            notes: const [],
            showResolution: true,
            attackValue: 6,
            defenseValue: 0,
            blindingLightRoll: 5,
            blindingLightBaseAttack: 6,
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
    expect(
      findChatText('Blinding Light (D6: 5) on ${adventure.hero.label}: Attack applies at full strength (6 damage).'),
      findsOneWidget,
    );
  });

  test('minionAttackAiMessage interprets Blinding Light roll 1 (fails, 0 damage) and roll 2 (halved damage)', () {
    final adventure = AdventureState(
      hero: HeroType.barbare,
      config: const SurvivalConfig(
        mode: SurvivalMode.mediumFixed,
        targetScore: mediumTarget,
      ),
    );
    final enemy = EnemyNode(
      id: 99,
      label: 'Suite Minion',
      rank: EnemyRank.green,
      maxHealth: 20,
      cp: 2,
      attacks: const ['Suite attack: 6 damage'],
      defense: 'Defense',
      defenseDice: 1,
      attackPlan: const MinionAttackPlan.suite(),
      cardAsset: '',
      profileKey: 'fee',
    );
    enemy.alterations.add('Blinding Light');

    // Valid suite attack dice (1, 2, 3, 4, 5)
    final dice = [
      GameDie(id: 1, value: 1, reserved: true),
      GameDie(id: 2, value: 2, reserved: true),
      GameDie(id: 3, value: 3, reserved: true),
      GameDie(id: 4, value: 4, reserved: true),
      GameDie(id: 5, value: 5, reserved: true),
    ];

    // Roll 1: Offensive ability fails to activate, 0 damage, No damage is dealt
    final msgRoll1 = minionAttackAiMessage(
      enemy,
      dice,
      3,
      adventure,
      '',
      blindingLightRoll: 1,
      blindingLightZeroDamage: true,
      blindingLightBaseAttack: 6,
    );
    expect(msgRoll1, contains('Blinding Light (D6: 1): Offensive Ability fails to activate! 0 damage dealt.'));
    expect(msgRoll1, contains('No damage is dealt.'));

    // Roll 2: Attack damage is reduced by half
    final msgRoll2 = minionAttackAiMessage(
      enemy,
      dice,
      3,
      adventure,
      '',
      blindingLightRoll: 2,
      blindingLightBaseAttack: 6,
      blindingLightReducedDamage: 3,
    );
    expect(msgRoll2, contains('Blinding Light (D6: 2): Attack damage is reduced by half (-3). Net attack: 3.'));
    expect(msgRoll2, contains('${adventure.hero.label} should perform a defense roll.'));
  });

  testWidgets('TokenAnimationDialog for Coal displays CP reduction and returns 0 count when 4 tokens', (WidgetTester tester) async {
    final coalRule = TokenCatalogRepository.byLabel('Coal')!;
    TokenAnimationResult? returnedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await TokenAnimationDialog.show(
                  context,
                  rule: coalRule,
                  initialCount: 4,
                  targetName: 'Hero',
                  currentCp: 5,
                  currentHp: 20,
                );
              },
              child: const Text('Open Coal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Coal'));
    await tester.pumpAndSettle();

    expect(find.text('Coal (x4)'), findsOneWidget);
    expect(find.textContaining('(+1 CP upkeep reduced by 1 ➔ 0 CP gained)'), findsOneWidget);
    expect(find.textContaining('All 4 Coal tokens removed'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(returnedResult, isNotNull);
    expect(returnedResult!.count, equals(0));
  });

  testWidgets('TokenAnimationDialog for Coal with fewer than 4 tokens does not show reduction subtext', (WidgetTester tester) async {
    final coalRule = TokenCatalogRepository.byLabel('Coal')!;
    TokenAnimationResult? returnedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await TokenAnimationDialog.show(
                  context,
                  rule: coalRule,
                  initialCount: 2,
                  targetName: 'Hero',
                  currentCp: 5,
                  currentHp: 20,
                );
              },
              child: const Text('Open Coal 2'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Coal 2'));
    await tester.pumpAndSettle();

    expect(find.text('Coal (x2)'), findsOneWidget);
    expect(find.textContaining('All 4 Coal tokens removed'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(returnedResult, isNotNull);
    expect(returnedResult!.count, equals(2));
  });
}

