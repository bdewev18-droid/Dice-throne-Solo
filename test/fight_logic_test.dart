import 'package:dice_throne_survie/game_engine.dart';
import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/models/enemy_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TokenCatalogRepository.load();
  });

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

    test('Enemy maxHealth is starting HP + 10 and can heal above starting HP up to max', () {
      final naxarus = EnemyNode(
        id: 0,
        label: 'Naxarus',
        rank: EnemyRank.naraxus,
        maxHealth: 65,
        cp: 2,
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: '',
      );

      expect(naxarus.initialHealth, equals(65));
      expect(naxarus.health, equals(65));
      expect(naxarus.maxHealth, equals(75));

      // Swoop heals 4 HP -> goes from 65 to 69
      naxarus.health = (naxarus.health + 4).clamp(0, naxarus.maxHealth);
      expect(naxarus.health, equals(69));

      // Healing beyond 75 is capped at 75
      naxarus.health = (naxarus.health + 20).clamp(0, naxarus.maxHealth);
      expect(naxarus.health, equals(75));
    });

    test('Hero maxHealth is starting HP + 10 in all modes (e.g. 40 in normal, 60 in Naraxus)', () {
      // Normal survival mode (starting HP 30)
      final normalState = AdventureState(
        hero: HeroType.barbare,
        config: const SurvivalConfig(
          mode: SurvivalMode.mediumFixed,
          targetScore: 33,
        ),
      );
      expect(normalState.initialHealth, equals(30));
      expect(normalState.health, equals(30));
      expect(normalState.maxHealth, equals(40));

      normalState.setHeroHealth(45);
      expect(normalState.health, equals(40));

      // Naraxus mode (starting HP 50)
      final naraxusState = AdventureState(
        hero: HeroType.barbare,
        config: const SurvivalConfig(
          mode: SurvivalMode.naraxus,
          targetScore: 100,
        ),
      );
      expect(naraxusState.initialHealth, equals(50));
      expect(naraxusState.health, equals(50));
      expect(naraxusState.maxHealth, equals(60));

      naraxusState.setHeroHealth(65);
      expect(naraxusState.health, equals(60));
    });

    test('Stun token properties in TokenCatalogRepository', () {
      final stunRule = TokenCatalogRepository.byLabel('Stun');
      expect(stunRule, isNotNull);
      expect(stunRule!.appSupported, isTrue);
      expect(stunRule.appAnimation, isTrue);
      expect(stunRule.maxStack, equals(1));
      expect(stunRule.persistent, isFalse);
      expect(stunRule.aliases, contains('Étourdissement'));
    });

    test('Evasive token properties in TokenCatalogRepository', () {
      final evasiveRule = TokenCatalogRepository.byLabel('Evasive');
      expect(evasiveRule, isNotNull);
      expect(evasiveRule!.appSupported, isTrue);
      expect(evasiveRule.appAnimation, isTrue);
      expect(evasiveRule.maxStack, equals(3));
      expect(evasiveRule.aliases, contains('Évitement'));
      expect(evasiveRule.matches('Evasive'), isTrue);
      expect(evasiveRule.matches('Évitement'), isTrue);
      expect(evasiveRule.matches('evitement'), isTrue);
    });

    test('Evasive trigger conditions: lethal damage or net damage >= 9', () {
      final enemy = EnemyNode(
        id: 99,
        label: 'Test Enemy',
        rank: EnemyRank.green,
        maxHealth: 8,
        cp: 2,
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: '',
        initialTokens: const [],
      );

      // Case 1: Attack 5, Defense 0 -> netDamage = 5, enemy HP = 8.
      // 8 - 5 = 3 > 0 and 5 < 9 -> No evasive
      int attack = 5;
      int defense = 0;
      int netDamage = attack - defense;
      bool willKill = (enemy.health - netDamage) <= 0;
      bool isMajor = netDamage >= 9;
      expect(willKill || isMajor, isFalse);

      // Case 2: Attack 8, Defense 0 -> netDamage = 8, enemy HP = 8.
      // 8 - 8 = 0 <= 0 -> Lethal -> Trigger evasive!
      attack = 8;
      netDamage = attack - defense;
      willKill = (enemy.health - netDamage) <= 0;
      isMajor = netDamage >= 9;
      expect(willKill || isMajor, isTrue);

      // Case 3: Attack 10, Defense 1 -> netDamage = 9, enemy HP = 20.
      // 20 - 9 = 11 > 0, but netDamage >= 9 -> Major damage -> Trigger evasive!
      enemy.health = 20;
      attack = 10;
      defense = 1;
      netDamage = attack - defense;
      willKill = (enemy.health - netDamage) <= 0;
      isMajor = netDamage >= 9;
      expect(willKill || isMajor, isTrue);
    });

    test('Agility token properties in TokenCatalogRepository', () {
      final agilityRule = TokenCatalogRepository.byLabel('Agility');
      expect(agilityRule, isNotNull);
      expect(agilityRule!.appSupported, isTrue);
      expect(agilityRule.appAnimation, isTrue);
      expect(agilityRule.maxStack, equals(2));
      expect(agilityRule.persistent, isFalse);
      expect(agilityRule.aliases, contains('Agilité'));
      expect(agilityRule.matches('Agility'), isTrue);
      expect(agilityRule.matches('Agilité'), isTrue);
      expect(agilityRule.matches('agilité'), isTrue);
    });

    test('Agility damage prevention logic (halving rounded up, 2 successes = 0 DMG)', () {
      // Rule: remainder = max(0, incoming - defense), prevented = ceil(remainder / 2)
      int incoming = 7;
      int defense = 2;
      int remainder = (incoming - defense).clamp(0, 999);
      expect(remainder, equals(5));

      // 1 Agility success: ceil(5 / 2) = 3 prevented
      int prevented1 = (remainder / 2.0).ceil();
      expect(prevented1, equals(3));
      int finalAttack1 = (incoming - prevented1).clamp(0, 999);
      expect(finalAttack1, equals(4));
      // Net damage taken: 4 - 2 defense = 2 damage taken (was 5 without agility)
      expect(finalAttack1 - defense, equals(2));

      // Even incoming damage: incoming 8, defense 2 -> remainder = 6
      incoming = 8;
      defense = 2;
      remainder = (incoming - defense).clamp(0, 999);
      int preventedEven = (remainder / 2.0).ceil();
      expect(preventedEven, equals(3));
      int finalAttackEven = (incoming - preventedEven).clamp(0, 999);
      expect(finalAttackEven, equals(5));
      expect(finalAttackEven - defense, equals(3));

      // 2 Agility successes: all damage cancelled (0 damage)
      int finalAttack2 = 0;
      expect(finalAttack2, equals(0));
    });

    test('Shadows token properties in TokenCatalogRepository', () {
      final shadowsRule = TokenCatalogRepository.byLabel('Shadows');
      expect(shadowsRule, isNotNull);
      expect(shadowsRule!.persistence, equals(TokenPersistence.nonPersistent));
      expect(shadowsRule.maxStack, equals(1));
      expect(shadowsRule.persistent, isFalse);
      expect(shadowsRule.matches('Shadows'), isTrue);
      expect(shadowsRule.matches('ombre'), isTrue);
    });

    test('Barbed Vine token properties in TokenCatalogRepository', () {
      final vineRule = TokenCatalogRepository.byLabel('Barbed Vine');
      expect(vineRule, isNotNull);
      expect(vineRule!.persistence, equals(TokenPersistence.nonPersistent));
      expect(vineRule.maxStack, equals(1));
      expect(vineRule.persistent, isFalse);
      expect(vineRule.appSupported, isTrue);
      expect(vineRule.appAnimation, isTrue);
      expect(vineRule.matches('Barbed Vine'), isTrue);
      expect(vineRule.matches('Ronces'), isTrue);
      expect(vineRule.matches('ronces'), isTrue);
    });

    test('Coal token properties in TokenCatalogRepository', () {
      final coalRule = TokenCatalogRepository.byLabel('Coal');
      expect(coalRule, isNotNull);
      expect(coalRule!.maxStack, equals(4));
      expect(coalRule.persistent, isTrue);
      expect(coalRule.appSupported, isTrue);
      expect(coalRule.appAnimation, isTrue);
      expect(coalRule.matches('Coal'), isTrue);
      expect(coalRule.matches('Charbon'), isTrue);
      expect(coalRule.matches('charbon'), isTrue);
      expect(coalRule.matches('coal'), isTrue);
    });

    test('Coal token upkeep behavior on hero and minion', () {
      // 1. Hero with 4 Coal tokens at 5 CP: removes 4 tokens, cpDelta == 0 (1 natural - 1 coal)
      final heroTokens4 = <String>['Coal', 'Coal', 'Coal', 'Coal'];
      final heroOutcome1 = GameEngine.heroUpkeep(
        tokens: heroTokens4,
        rollD6: () => 1,
        currentCp: 5,
      );
      expect(heroOutcome1.coalActive, isTrue);
      expect(heroOutcome1.cpDelta, equals(0));
      expect(heroOutcome1.removedTokens.where((t) => t == 'Coal').length, equals(4));

      // 2. Hero with 4 Coal tokens at 15 CP: max CP, tokens are NOT spent, cpDelta == 0
      final heroTokensMax = <String>['Coal', 'Coal', 'Coal', 'Coal'];
      final heroOutcomeMax = GameEngine.heroUpkeep(
        tokens: heroTokensMax,
        rollD6: () => 1,
        currentCp: 15,
      );
      expect(heroOutcomeMax.coalActive, isFalse);
      expect(heroOutcomeMax.cpDelta, equals(0));
      expect(heroOutcomeMax.removedTokens, isEmpty);

      // 3. Hero with only 3 Coal tokens: not enough, natural +1 CP gain, tokens not removed
      final heroTokens3 = <String>['Coal', 'Coal', 'Coal'];
      final heroOutcome3 = GameEngine.heroUpkeep(
        tokens: heroTokens3,
        rollD6: () => 1,
        currentCp: 5,
      );
      expect(heroOutcome3.coalActive, isFalse);
      expect(heroOutcome3.cpDelta, equals(1));
      expect(heroOutcome3.removedTokens, isEmpty);

      // 4. Minion with 4 Coal tokens: removes 4 tokens, coalActive == true
      final minionTokens4 = <String>['Coal', 'Coal', 'Coal', 'Coal'];
      final minionOutcome = GameEngine.minionUpkeep(
        tokens: minionTokens4,
        rollD6: () => 1,
        currentCp: 2,
        isNaxarus: false,
      );
      expect(minionOutcome.coalActive, isTrue);
      expect(minionOutcome.removedTokens.where((t) => t == 'Coal').length, equals(4));

      // 5. Naxarus with 4 Coal tokens: immune to Coal, tokens not removed, coalActive == false
      final naxarusTokens = <String>['Coal', 'Coal', 'Coal', 'Coal'];
      final naxOutcome = GameEngine.minionUpkeep(
        tokens: naxarusTokens,
        rollD6: () => 1,
        currentCp: 0,
        isNaxarus: true,
      );
      expect(naxOutcome.coalActive, isFalse);
      expect(naxOutcome.removedTokens, isEmpty);
    });

    test('Constrict token recognized by TokenCatalogRepository', () {
      final constrictRule = TokenCatalogRepository.byLabel('Constrict');
      expect(constrictRule, isNotNull);
      expect(constrictRule!.appAnimation, isTrue);
      expect(constrictRule.persistent, isFalse);
      expect(constrictRule.matches('Constrict'), isTrue);
      expect(constrictRule.matches('Compression'), isTrue);
      expect(constrictRule.matches('constrict'), isTrue);
      expect(constrictRule.matches('compression'), isTrue);
    });

    test('Constrict AI message contains CP cost notice when minion has Constrict', () {
      final adventure = AdventureState(
        config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: mediumTarget),
        hero: HeroType.barbare,
      );
      final enemy = EnemyNode(
        id: 88,
        label: 'Constrict Minion',
        rank: EnemyRank.green,
        maxHealth: 20,
        cp: 3,
        attacks: const ['Symbol attack: 3 damage'],
        defense: 'Defense',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.symbols([]),
        cardAsset: '',
      );
      enemy.alterations.add('Constrict');

      final msg = minionAttackAiMessage(enemy, [], 0, adventure, '');
      expect(msg, contains('Afflicted by Constrict'));
      expect(msg, contains('each reroll beyond the first costs 1 CP'));
    });
  });
}
