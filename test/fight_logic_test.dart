import 'package:dice_throne_survie/game_engine.dart';
import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/models/enemy_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Game Engine & Fight Logic Tests', () {
    test('Naraxus tie logic awards 50 points', () {
      // 1. Setup Adventure Run for Naraxus where both hero and boss die
      final adventure = AdventureState(
        config: SurvivalConfig(mode: SurvivalMode.naraxus, targetScore: SurvivalMode.naraxus.defaultTarget),
        hero: HeroType.barbare,
      );
      
      // Hero has 0 HP
      adventure.health = 0;
      
      // Boss has 0 HP
      final naraxus = adventure.enemies.first;
      naraxus.health = 0; // Both dead = Tie
      
      // Set the initial score
      adventure.score = 100;
      
      // Complete combat
      adventure.completeCombat(naraxus);

      // Assert score increased by 50
      expect(adventure.score, equals(150));
    });

    test('Upkeep CP gain increments hero CP by 1', () {
      final adventure = AdventureState(
        config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget),
        hero: HeroType.barbare,
      );
      adventure.combatPoints = 5;
      
      // Apply upkeep
      adventure.applyHeroUpkeep();
      
      // Checking that CP increment logic operates correctly inside the app
      expect(adventure.combatPoints, equals(6)); 
    });

    test('Minion Rush mode (Rush - Medium) generates correct enemies', () {
      // Minion Rush is medium mode
      final config = SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget);
      final adventure = AdventureState(
        config: config,
        hero: HeroType.barbare,
      );
      
      expect(adventure.enemies.isNotEmpty, isTrue);
      // And the score target is mediumTarget (33)
      expect(adventure.config.targetScore, equals(33));
    });

    test('Enemy with Premiere Frappe / First Strike starts combat on minionUpkeep', () {
      final normalEnemy = EnemyNode(
        id: 1,
        label: 'Gobelin',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 2,
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: '',
        initialTokens: const [],
      );
      expect(firstCombatPhaseFor(normalEnemy), equals(CombatPhase.heroUpkeep));

      final firstStrikeEnemy = EnemyNode(
        id: 2,
        label: 'Vaurien',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 2,
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: '',
        initialTokens: const ['Première Frappe'],
      );
      expect(firstCombatPhaseFor(firstStrikeEnemy), equals(CombatPhase.minionUpkeep));
    });

    test('Minion upkeep consumes First Strike / Premiere Frappe token', () {
      final tokens = <String>['Première Frappe'];
      final outcome = GameEngine.minionUpkeep(tokens: tokens, rollD6: () => 1);
      expect(outcome.removedTokens, contains('Première Frappe'));
    });

    test('Minion suite with 1,2,4,2,6 does not form a validated suite', () {
      final diceValues = [1, 2, 4, 2, 6];
      final decision = MinionDiceEngine.chooseSuiteHold(
        diceValues.map((v) => GameDie(id: 0)..value = v).toList(),
      );
      expect(decision.reason, contains('micro-suite start'));
      expect(decision.values, equals([1, 2]));
    });

    test('Hex token is preserved during minion upkeep and hero upkeep', () {
      final tokens = <String>['Hex'];
      final minionOutcome = GameEngine.minionUpkeep(tokens: tokens, rollD6: () => 1);
      expect(minionOutcome.removedTokens, isNot(contains('Hex')));

      final heroOutcome = GameEngine.heroUpkeep(tokens: tokens, rollD6: () => 1);
      expect(heroOutcome.removedTokens, isNot(contains('Hex')));
    });

    test('Burn deals 2 damage during hero and minion upkeep', () {
      final heroTokens = <String>['Burn'];
      final heroOutcome = GameEngine.heroUpkeep(tokens: heroTokens, rollD6: () => 1);
      expect(heroOutcome.healthDelta, equals(-2));
      expect(heroOutcome.removedTokens, isNot(contains('Burn'))); // Persistent

      final minionTokens = <String>['Brûlure'];
      final minionOutcome = GameEngine.minionUpkeep(tokens: minionTokens, rollD6: () => 1);
      expect(minionOutcome.healthDelta, equals(-2));
      expect(minionOutcome.removedTokens, isNot(contains('Brûlure')));
    });

    test('Knockdown subtracts up to 2 CP before natural hero upkeep CP gain', () {
      // Case 1: Hero with 1 CP -> loses 1 CP (to 0), gains 1 CP -> net delta 0
      final outcome1 = GameEngine.heroUpkeep(
        tokens: ['Knockdown'],
        rollD6: () => 1,
        currentCp: 1,
      );
      expect(outcome1.cpDelta, equals(0));
      expect(outcome1.removedTokens, contains('Knockdown'));

      // Case 2: Hero with 0 CP -> loses 0 CP (to 0), gains 1 CP -> net delta +1
      final outcome2 = GameEngine.heroUpkeep(
        tokens: ['Knockdown'],
        rollD6: () => 1,
        currentCp: 0,
      );
      expect(outcome2.cpDelta, equals(1));
      expect(outcome2.removedTokens, contains('Knockdown'));

      // Case 3: Hero with 3 CP -> loses 2 CP (to 1), gains 1 CP -> net delta -1
      final outcome3 = GameEngine.heroUpkeep(
        tokens: ['Knockdown'],
        rollD6: () => 1,
        currentCp: 3,
      );
      expect(outcome3.cpDelta, equals(-1));
      expect(outcome3.removedTokens, contains('Knockdown'));
    });

    test('Knockdown on minion removes up to 2 CP and Naxarus is immune', () {
      // Normal minion
      final minionOutcome = GameEngine.minionUpkeep(
        tokens: ['Knockdown'],
        rollD6: () => 1,
        currentCp: 3,
        isNaxarus: false,
      );
      expect(minionOutcome.cpDelta, equals(-2));
      expect(minionOutcome.removedTokens, contains('Knockdown'));

      // Naxarus immune
      final naxarusOutcome = GameEngine.minionUpkeep(
        tokens: ['Knockdown'],
        rollD6: () => 1,
        currentCp: 3,
        isNaxarus: true,
      );
      expect(naxarusOutcome.cpDelta, equals(0));
      expect(naxarusOutcome.removedTokens, isNot(contains('Knockdown')));
    });
  });
}
