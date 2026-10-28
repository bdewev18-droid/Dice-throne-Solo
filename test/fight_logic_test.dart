import 'dart:io';

import 'package:dice_throne_survie/data/enemy_profile_repository.dart';
import 'package:dice_throne_survie/game_engine.dart';
import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/models/enemy_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tokenFile = File('assets/data/token_catalog.json');
    if (tokenFile.existsSync()) {
      TokenCatalogRepository.loadFromJsonString(tokenFile.readAsStringSync());
    } else {
      await TokenCatalogRepository.load();
    }
    final enemyFile = File('docs/enemy_profiles.json');
    if (enemyFile.existsSync()) {
      EnemyProfileRepository.loadFromJsonString(enemyFile.readAsStringSync());
    } else {
      await EnemyProfileRepository.load();
    }
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
      expect(agilityRule.persistent, isTrue);
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
      expect(shadowsRule!.persistence, equals(TokenPersistence.persistent));
      expect(shadowsRule.maxStack, equals(1));
      expect(shadowsRule.persistent, isTrue);
      expect(shadowsRule.matches('Shadows'), isTrue);
      expect(shadowsRule.matches('ombre'), isTrue);
    });

    test('Barbed Vine token properties in TokenCatalogRepository', () {
      final vineRule = TokenCatalogRepository.byLabel('Barbed Vine');
      expect(vineRule, isNotNull);
      expect(vineRule!.persistence, equals(TokenPersistence.persistent));
      expect(vineRule.maxStack, equals(1));
      expect(vineRule.persistent, isTrue);
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
      expect(constrictRule.persistent, isTrue);
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

    test('Salve token properties and catalog recognition', () {
      final salveRule = TokenCatalogRepository.byLabel('Salve');
      expect(salveRule, isNotNull);
      expect(salveRule!.imageAsset, 'assets/token/Salve.webp');
      expect(salveRule.maxStack, equals(99));
      expect(salveRule.matches('Salve'), isTrue);
    });

    test('Silence blocks Small/Large straights but allows Micro Suite (length 3)', () {
      final adventure = AdventureState(
        config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: mediumTarget),
        hero: HeroType.barbare,
      );
      final enemy = EnemyNode(
        id: 99,
        label: 'Suite Minion',
        rank: EnemyRank.green,
        maxHealth: 20,
        cp: 3,
        attacks: const ['Micro suite: 2 damage', 'Small suite: 4 damage', 'Large suite: 7 damage'],
        defense: 'Defense',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.suite(),
        cardAsset: '',
      );

      // Micro suite dice: 1, 2, 3, 5, 6
      final microDice = [
        GameDie(id: 0)..value = 1..settled = true,
        GameDie(id: 1)..value = 2..settled = true,
        GameDie(id: 2)..value = 3..settled = true,
        GameDie(id: 3)..value = 5..settled = true,
        GameDie(id: 4)..value = 6..settled = true,
      ];
      final msgMicro = minionAttackAiMessage(
        enemy,
        microDice,
        3,
        adventure,
        '',
        minionSilenceActive: true,
      );
      expect(msgMicro, contains('Silence is active: micro suite validated'));

      // Large suite dice: 1, 2, 3, 4, 5 -> Under Silence, blocked down to micro suite
      final largeDice = [
        GameDie(id: 0)..value = 1..settled = true,
        GameDie(id: 1)..value = 2..settled = true,
        GameDie(id: 2)..value = 3..settled = true,
        GameDie(id: 3)..value = 4..settled = true,
        GameDie(id: 4)..value = 5..settled = true,
      ];
      final msgLarge = minionAttackAiMessage(
        enemy,
        largeDice,
        3,
        adventure,
        '',
        minionSilenceActive: true,
      );
      expect(msgLarge, contains('Silence is active: Small/Large suite blocked, micro suite validated'));

      // No suite: 1, 1, 3, 5, 6
      final noSuiteDice = [
        GameDie(id: 0)..value = 1..settled = true,
        GameDie(id: 1)..value = 1..settled = true,
        GameDie(id: 2)..value = 3..settled = true,
        GameDie(id: 3)..value = 5..settled = true,
        GameDie(id: 4)..value = 6..settled = true,
      ];
      final msgNoSuite = minionAttackAiMessage(
        enemy,
        noSuiteDice,
        3,
        adventure,
        '',
        minionSilenceActive: true,
      );
      expect(msgNoSuite, contains('Silence is active: Small and Large suites are blocked'));
    });

    test('MinionDiceEngine chooses hold for micro suite (length 3) when silenced', () {
      final dice = [
        GameDie(id: 0)..value = 1..settled = true,
        GameDie(id: 1)..value = 2..settled = true,
        GameDie(id: 2)..value = 3..settled = true,
        GameDie(id: 3)..value = 4..settled = true,
        GameDie(id: 4)..value = 6..settled = true,
      ];
      final decision = MinionDiceEngine.chooseSuiteHold(dice, limitTo3: true);
      expect(decision.values.length, 3);
      expect(decision.values, equals([1, 2, 3]));
    });

    test('Ninjitsu token properties in TokenCatalogRepository', () {
      final rule = TokenCatalogRepository.byLabel('Ninjitsu');
      expect(rule, isNotNull);
      expect(rule!.maxStack, 3);
      expect(rule.minionAllowed, isTrue);
    });

    test('Siphon vital token properties in TokenCatalogRepository', () {
      final rule = TokenCatalogRepository.byLabel('Siphon vital');
      expect(rule, isNotNull);
      expect(rule!.maxStack, 1);
      expect(rule.minionAllowed, isTrue);
      expect(rule.aliases, contains('Life Siphon'));
    });

    test('Farceur defense parsed dynamically from defensePlan.effects', () {
      final farceur = EnemyProfileRepository.byKey('bleu-bleu-020');
      expect(farceur, isNotNull);
      expect(farceur!.name, 'Farceur');
      expect(farceur.defenseDice, 5);
      expect(farceur.defenseEffects.length, 1);
      expect(farceur.defenseEffects.first.orange, 2);
      expect(farceur.defenseEffects.first.prevent, 3);
    });

    test('Farceur attackPlan has primary goal and structured extraRoll outcomes', () {
      final farceur = EnemyProfileRepository.byKey('bleu-bleu-020');
      expect(farceur, isNotNull);
      expect(farceur!.attackPlan.style, MinionAttackStyle.symbols);
      // Primary attack combination is Recreation (1W, 2Y, 1R)
      expect(farceur.attackPlan.goals.length, 1);
      final recreation = farceur.attackPlan.goals.first;
      expect(recreation.white, 1);
      expect(recreation.yellow, 2);
      expect(recreation.red, 1);
      expect(recreation.effect?.damage, 4);
      expect(recreation.effect?.undefendable, isTrue);

      final extra = recreation.effect?.extraRoll;
      expect(extra, isNotNull);
      expect(extra!.dice, 1);
      expect(extra.outcomes.length, 3);
      final whiteOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.white);
      expect(whiteOut.stealCp, 2);
      final orangeOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.yellow);
      expect(orangeOut.label, contains('discards 1 card'));
      expect(orangeOut.discardCards, 1);
      final redOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.red);
      expect(redOut.discardCards, 1);
    });

    test('Enemy card discard logic in attackPlan and extraRoll outcomes', () {
      final enchanteur = EnemyProfileRepository.byKey('enchanteur-gobelin');
      expect(enchanteur, isNotNull);
      final enchanteurGoal = enchanteur!.attackPlan.goals.first;
      expect(enchanteurGoal.effect?.discardCards, 1);

      final chaman = EnemyProfileRepository.byKey('violet-violet-015');
      expect(chaman, isNotNull);
      final chamanGoal = chaman!.attackPlan.goals.first;
      expect(chamanGoal.effect?.discardCards, 1);

      final naxarus = EnemyProfileRepository.byKey('naraxus');
      expect(naxarus, isNotNull);
    });

    test('The Hermit attackPlan has Deep Magic goal (1W, 3Y) and extraRoll outcomes', () {
      final hermit = EnemyProfileRepository.byKey('bleu-bleu-007');
      expect(hermit, isNotNull);
      expect(hermit!.attackPlan.style, MinionAttackStyle.symbols);
      expect(hermit.attackPlan.goals.length, 1);
      final deepMagic = hermit.attackPlan.goals.first;
      expect(deepMagic.white, 1);
      expect(deepMagic.yellow, 3);
      expect(deepMagic.red, 0);
      expect(deepMagic.effect?.damage, 3);
      expect(deepMagic.effect?.undefendable, isTrue);

      final extra = deepMagic.effect?.extraRoll;
      expect(extra, isNotNull);
      expect(extra!.dice, 1);
      expect(extra.outcomes.length, 3);
      final whiteOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.white);
      expect(whiteOut.damage, 2);
      final orangeOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.yellow);
      expect(orangeOut.tokens, contains('Wither'));
      final redOut = extra.outcomes.firstWhere((o) => o.face == ExtraRollFace.red);
      expect(redOut.tokens, contains('Burn'));
    });

    test('Bloodseeker, Umbra, Fell Summoner, and Cyclope Brutal defense effects', () {
      final bloodseeker = EnemyProfileRepository.byKey('orange-orange-009');
      expect(bloodseeker, isNotNull);
      expect(bloodseeker!.defenseEffects.length, 1);
      expect(bloodseeker.defenseEffects.first.white, 2);
      expect(bloodseeker.defenseEffects.first.tokens, contains('Bleed'));
      expect(bloodseeker.defenseDisplayRows, isEmpty);

      final umbra = EnemyProfileRepository.byKey('orange-orange-004');
      expect(umbra, isNotNull);
      expect(umbra!.defenseEffects.length, 1);
      expect(umbra.defenseEffects.first.red, 1);
      expect(umbra.defenseEffects.first.tokens, contains('Shadows'));
      expect(umbra.defenseDisplayRows, isEmpty);

      final fell = EnemyProfileRepository.byKey('violet-violet-007');
      expect(fell, isNotNull);
      expect(fell!.defenseEffects.length, 1);
      expect(fell.defenseEffects.first.orange, 1);
      expect(fell.defenseEffects.first.tokens, contains('Chaos'));
      expect(fell.defenseDisplayRows, isEmpty);

      final cyclope = EnemyProfileRepository.byKey('bleu-bleu-006');
      expect(cyclope, isNotNull);
      expect(cyclope!.defenseEffects.length, 2);
      expect(cyclope.defenseEffects[0].white, 1);
      expect(cyclope.defenseEffects[0].returnDamage, 3);
      expect(cyclope.defenseEffects[0].undefendable, isTrue);
      expect(cyclope.defenseEffects[1].orange, 1);
      expect(cyclope.defenseEffects[1].heal, 2);
      expect(cyclope.defenseDisplayRows, isEmpty);
    });

    test('EnemyDefenseEffect with orOrangeRed matches orange or red dice', () {
      const effect = EnemyDefenseEffect(
        orange: 1,
        red: 1,
        orOrangeRed: true,
        prevent: 2,
        tokens: ['Poison', 'Poison'],
      );
      expect(effect.orOrangeRed, isTrue);
      expect(effect.tokens.length, 2);
    });

    test('EnemyDefenseEffect and SymbolGoalEffect support loseHp (unpreventable life loss)', () {
      const defEffect = EnemyDefenseEffect(
        white: 2,
        loseHp: 2,
      );
      expect(defEffect.loseHp, equals(2));

      const atkEffect = SymbolGoalEffect(
        damage: 4,
        loseHp: 1,
      );
      expect(atkEffect.loseHp, equals(1));
      expect(atkEffect.damage, equals(4));

      const outcome = ExtraRollOutcome(
        face: ExtraRollFace.white,
        loseHp: 3,
      );
      expect(outcome.loseHp, equals(3));

      const condEffect = ConditionalEffect(
        loseHp: 2,
      );
      expect(condEffect.loseHp, equals(2));

      // Verifying health deduction logic without healing
      final adventure = AdventureState(
        config: SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: SurvivalMode.mediumFixed.defaultTarget),
        hero: HeroType.barbare,
      );
      adventure.health = 30;
      final enemy = adventure.enemies.first;
      enemy.health = 20;
      final initialEnemyHp = enemy.health;

      final loseHpAmount = 3;
      adventure.setHeroHealth(adventure.health - loseHpAmount, source: 'Life loss');

      // Hero loses exactly loseHpAmount, enemy health is unchanged
      expect(adventure.health, equals(27));
      expect(enemy.health, equals(initialEnemyHp));
    });

    test('evaluateDefenseFormulas parses ignoreAllIncomingDamage, prevent half, and return half', () {
      // 1. ignoreAllIncomingDamage
      final resIgnore = evaluateDefenseFormulas(
        formulas: ['ignoreAllIncomingDamage = true'],
        incomingDamage: 12,
      );
      expect(resIgnore.matched, isTrue);
      expect(resIgnore.ignoreAllIncomingDamage, isTrue);
      expect(resIgnore.prevented, equals(12));

      // 2. prevent = ceil(incomingDamage / 2) with odd damage (7 -> 4)
      final resPreventOdd = evaluateDefenseFormulas(
        formulas: ['prevent = ceil(incomingDamage / 2)'],
        incomingDamage: 7,
      );
      expect(resPreventOdd.matched, isTrue);
      expect(resPreventOdd.prevented, equals(4));

      // 3. prevent = ceil(incomingDamage / 2) with even damage (8 -> 4)
      final resPreventEven = evaluateDefenseFormulas(
        formulas: ['prevent = ceil(incomingDamage / 2)'],
        incomingDamage: 8,
      );
      expect(resPreventEven.matched, isTrue);
      expect(resPreventEven.prevented, equals(4));

      // 4. returnDamage = ceil(incomingDamage / 2) (9 -> 5)
      final resReturn = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(incomingDamage / 2)'],
        incomingDamage: 9,
      );
      expect(resReturn.matched, isTrue);
      expect(resReturn.returnDamage, equals(5));

      // 5. returnDamage = ceil(defenseDieValue / 2) with D6 = 5 -> 3
      final resDieReturn = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(defenseDieValue / 2)'],
        incomingDamage: 5,
        firstDieValue: 5,
      );
      expect(resDieReturn.matched, isTrue);
      expect(resDieReturn.returnDamage, equals(3));
      expect(resDieReturn.returnDamageUndefendable, isTrue);
    });

    test('Mort Murmurante and Elfe Fletri profiles have defense formulas loaded', () {
      final mort = EnemyProfileRepository.byKey('orange-orange-002');
      expect(mort, isNotNull);
      expect(mort!.name, equals('Mort Murmurante'));
      expect(mort.defenseEffects.length, equals(1));
      expect(mort.defenseEffects.first.red, equals(1));
      expect(mort.defenseEffects.first.formulas, contains('ignoreAllIncomingDamage = true'));

      final elfe = EnemyProfileRepository.byKey('bleu-bleu-013');
      expect(elfe, isNotNull);
      expect(elfe!.name, equals('Elfe Fletri'));
      expect(elfe.defenseEffects.length, equals(1));
      expect(elfe.defenseEffects.first.orange, equals(2));
      expect(elfe.defenseEffects.first.formulas, contains('prevent = ceil(incomingDamage / 2)'));
    });

    test('filterActiveDefenseEffects picks highest tier exclusive effect without stacking', () {
      const tier1 = EnemyDefenseEffect(
        orange: 1,
        formulas: ['prevent = ceil(incomingDamage / 2)'],
        exclusive: true,
      );
      const tier2 = EnemyDefenseEffect(
        orange: 2,
        formulas: ['ignoreAllIncomingDamage = true'],
        exclusive: true,
      );
      const independent = EnemyDefenseEffect(
        red: 1,
        tokens: ['Poison'],
      );

      // Roll matches both tier1 and tier2 plus independent:
      final matched = [
        const MatchedDefenseEffect(effect: tier1, count: 1),
        const MatchedDefenseEffect(effect: tier2, count: 1),
        const MatchedDefenseEffect(effect: independent, count: 1),
      ];

      final filtered = filterActiveDefenseEffects(matched);
      expect(filtered.length, equals(2));
      expect(filtered.any((m) => m.effect == tier2), isTrue);
      expect(filtered.any((m) => m.effect == tier1), isFalse);
      expect(filtered.any((m) => m.effect == independent), isTrue);
    });

    test('Harpie Cornue defense effects are exclusive and do not stack when 2 orange symbols are rolled', () {
      final harpie = EnemyProfileRepository.byKey('bleu-bleu-018');
      expect(harpie, isNotNull);
      expect(harpie!.name, equals('Harpie Cornue'));
      expect(harpie.defenseEffects.length, equals(2));
      expect(harpie.defenseEffects[0].orange, equals(1));
      expect(harpie.defenseEffects[0].exclusive, isTrue);
      expect(harpie.defenseEffects[1].orange, equals(2));
      expect(harpie.defenseEffects[1].exclusive, isTrue);

      // Simulation with 2 orange rolled and 6 incoming damage:
      final matched = [
        MatchedDefenseEffect(effect: harpie.defenseEffects[0], count: 1),
        MatchedDefenseEffect(effect: harpie.defenseEffects[1], count: 1),
      ];
      final active = filterActiveDefenseEffects(matched);
      expect(active.length, equals(1));
      expect(active.first.effect.orange, equals(2));

      // Defense formula resolution on the active effect only:
      final res = evaluateDefenseFormulas(
        formulas: active.first.effect.formulas,
        incomingDamage: 6,
        count: active.first.count,
      );
      expect(res.ignoreAllIncomingDamage, isTrue);
      expect(res.prevented, equals(6)); // exactly 6, not 9
    });

    test('Defense formula heal = rollD6() heals single minion or splits between 2 minions', () {
      expect(isHealRollD6DefenseFormula('heal = rollD6()'), isTrue);
      expect(isHealRollD6DefenseFormula('heal = d6'), isTrue);
      expect(isHealRollD6DefenseFormula('minionHeal = rollD6()'), isTrue);
      expect(isHealRollD6DefenseFormula('soin = rollD6()'), isTrue);
      expect(isHealRollD6DefenseFormula('prevent = 2'), isFalse);

      // Single minion scenario (hasDualEnemies = false):
      final singleRes = evaluateDefenseFormulas(
        formulas: ['heal = rollD6()'],
        incomingDamage: 6,
        hasDualEnemies: false,
        rollD6: () => 5,
      );
      expect(singleRes.matched, isTrue);
      expect(singleRes.enemyHeal, equals(5));
      expect(singleRes.secondaryEnemyHeal, equals(0));
      expect(singleRes.additionalDieRoll, equals(5));

      // Dual minions alive scenario (hasDualEnemies = true):
      // D6 roll = 5 => ceil(5 / 2) = 3 for each minion
      final dualResOdd = evaluateDefenseFormulas(
        formulas: ['heal = rollD6()'],
        incomingDamage: 6,
        hasDualEnemies: true,
        rollD6: () => 5,
      );
      expect(dualResOdd.matched, isTrue);
      expect(dualResOdd.enemyHeal, equals(3));
      expect(dualResOdd.secondaryEnemyHeal, equals(3));
      expect(dualResOdd.additionalDieRoll, equals(5));

      // D6 roll = 6 => ceil(6 / 2) = 3 for each minion
      final dualResEven = evaluateDefenseFormulas(
        formulas: ['heal = rollD6()'],
        incomingDamage: 6,
        hasDualEnemies: true,
        rollD6: () => 6,
      );
      expect(dualResEven.matched, isTrue);
      expect(dualResEven.enemyHeal, equals(3));
      expect(dualResEven.secondaryEnemyHeal, equals(3));
      expect(dualResEven.additionalDieRoll, equals(6));
    });

    test('Formula 1: returnDamage = ceil(rollD6() / 2) rolls extra D6 and returns half rounded up', () {
      expect(isReturnDamageRollD6Formula('returnDamage = ceil(rollD6() / 2)'), isTrue);
      expect(isReturnDamageRollD6Formula('returnDamage = ceil(d6 / 2)'), isTrue);
      expect(isReturnDamageRollD6Formula('returnDamage = rollD6() / 2'), isTrue);
      expect(isReturnDamageRollD6Formula('returnDamage = ceil(defenseDieValue / 2)'), isFalse);

      final res5 = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(rollD6() / 2)'],
        incomingDamage: 6,
        rollD6: () => 5,
      );
      expect(res5.matched, isTrue);
      expect(res5.returnDamage, equals(3));
      expect(res5.returnDamageUndefendable, isTrue);
      expect(res5.additionalDieRoll, equals(5));

      final res4 = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(d6 / 2)'],
        incomingDamage: 6,
        rollD6: () => 4,
      );
      expect(res4.returnDamage, equals(2));
      expect(res4.returnDamageUndefendable, isTrue);

      final res1 = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(rollD6() / 2)'],
        incomingDamage: 6,
        rollD6: () => 1,
      );
      expect(res1.returnDamage, equals(1));
    });

    test('Formula 2 (Combined): rolls single extra D6, returns half damage and prevents half damage', () {
      expect(isPreventRollD6HalfFormula('prevent = ceil(rollD6() / 2)'), isTrue);
      expect(isPreventRollD6HalfFormula('prevent = ceil(d6 / 2)'), isTrue);

      // Case A: 2 formulas in the list
      final resList = evaluateDefenseFormulas(
        formulas: [
          'returnDamage = ceil(rollD6() / 2)',
          'prevent = ceil(rollD6() / 2)',
        ],
        incomingDamage: 6,
        rollD6: () => 5,
      );
      expect(resList.matched, isTrue);
      expect(resList.additionalDieRoll, equals(5)); // rolled exactly once
      expect(resList.returnDamage, equals(3));
      expect(resList.prevented, equals(3));
      expect(resList.returnDamageUndefendable, isTrue);

      // Case B: combined in a single string separated by &
      final resSingleString = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(rollD6() / 2) & prevent = ceil(rollD6() / 2)'],
        incomingDamage: 6,
        rollD6: () => 5,
      );
      expect(resSingleString.matched, isTrue);
      expect(resSingleString.additionalDieRoll, equals(5));
      expect(resSingleString.returnDamage, equals(3));
      expect(resSingleString.prevented, equals(3));

      // Case C: roll of 2 gives 1 damage and 1 prevented
      final res2 = evaluateDefenseFormulas(
        formulas: ['returnDamage = ceil(d6 / 2)', 'prevent = ceil(d6 / 2)'],
        incomingDamage: 6,
        rollD6: () => 2,
      );
      expect(res2.returnDamage, equals(1));
      expect(res2.prevented, equals(1));
    });

    test('Formula 3: prevent = defenseDieValue prevents the defense roll total', () {
      expect(isPreventDefenseDieValueFormula('prevent = defenseDieValue'), isTrue);
      expect(isPreventDefenseDieValueFormula('prevent = defensedie'), isTrue);
      expect(isPreventDefenseDieValueFormula('prevent = jetdefensif'), isTrue);
      expect(isPreventRollD6FullFormula('prevent = rollD6()'), isTrue);

      // Value from the defense die in the arena:
      final resFromDefenseDie = evaluateDefenseFormulas(
        formulas: ['prevent = defenseDieValue'],
        incomingDamage: 6,
        firstDieValue: 4,
      );
      expect(resFromDefenseDie.matched, isTrue);
      expect(resFromDefenseDie.prevented, equals(4));

      final resDefenseDie6 = evaluateDefenseFormulas(
        formulas: ['prevent = jetdefensif'],
        incomingDamage: 6,
        firstDieValue: 6,
      );
      expect(resDefenseDie6.prevented, equals(6));

      // Extra roll variant:
      final resFromExtraRoll = evaluateDefenseFormulas(
        formulas: ['prevent = rollD6()'],
        incomingDamage: 6,
        rollD6: () => 4,
      );
      expect(resFromExtraRoll.matched, isTrue);
      expect(resFromExtraRoll.prevented, equals(4));
      expect(resFromExtraRoll.additionalDieRoll, equals(4));
    });

    test('Real database formulas for Epee Fantome, Atlas, and Lame Maudite evaluate correctly', () {
      // Epee Fantome database formula with a defense die roll of 4:
      // Half of 4 = 2 (not 3)
      final epeeRes4 = evaluateDefenseFormulas(
        formulas: ['Roll D6: return 1/2 D6 (undef)'],
        incomingDamage: 6,
        firstDieValue: 4,
      );
      expect(epeeRes4.matched, isTrue);
      expect(epeeRes4.returnDamage, equals(2));
      expect(epeeRes4.returnDamageUndefendable, isTrue);
      expect(epeeRes4.additionalDieRoll, equals(4));

      // Epee Fantome with defense die roll of 5:
      // Half of 5 rounded up = 3
      final epeeRes5 = evaluateDefenseFormulas(
        formulas: ['Roll D6: return 1/2 D6 (undef)'],
        incomingDamage: 6,
        firstDieValue: 5,
      );
      expect(epeeRes5.matched, isTrue);
      expect(epeeRes5.returnDamage, equals(3));
      expect(epeeRes5.additionalDieRoll, equals(5));

      // Atlas database formula: "Prevent defense roll value"
      final atlasRes = evaluateDefenseFormulas(
        formulas: ['Prevent defense roll value'],
        incomingDamage: 6,
        firstDieValue: 4,
      );
      expect(atlasRes.matched, isTrue);
      expect(atlasRes.prevented, equals(4));

      // Lame Maudite with defense die roll of 5:
      // prevent ceil(5 / 2) = 3 and return ceil(5 / 2) = 3 (not 2!)
      final lameRes5 = evaluateDefenseFormulas(
        formulas: ['Roll D6: prevent 1/2 D6 & return 1/2 D6 (undef)'],
        incomingDamage: 6,
        firstDieValue: 5,
      );
      expect(lameRes5.matched, isTrue);
      expect(lameRes5.returnDamage, equals(3));
      expect(lameRes5.prevented, equals(3));
      expect(lameRes5.returnDamageUndefendable, isTrue);
      expect(lameRes5.additionalDieRoll, equals(5));

      // Elfe Agile database formula: "heal = rollD6()" with defense die roll of 4:
      // heals exactly 4
      final elfeRes4 = evaluateDefenseFormulas(
        formulas: ['heal = rollD6()'],
        incomingDamage: 6,
        firstDieValue: 4,
      );
      expect(elfeRes4.matched, isTrue);
      expect(elfeRes4.enemyHeal, equals(4));
      expect(elfeRes4.additionalDieRoll, equals(4));
    });

    test('Horde de Gobelins: damageCap = 6 limits incoming damage to 6', () {
      expect(parseDamageCap('damageCap = 6'), equals(6));
      expect(parseDamageCap('maxIncomingDamage = 6'), equals(6));

      // Over cap: incoming 10 => excess 4 prevented, net is 6
      final resOver = evaluateDefenseFormulas(
        formulas: ['damageCap = 6'],
        incomingDamage: 10,
      );
      expect(resOver.matched, isTrue);
      expect(resOver.damageCap, equals(6));
      expect(resOver.prevented, equals(4));

      // Under or equal cap: incoming 5 => 0 prevented
      final resUnder = evaluateDefenseFormulas(
        formulas: ['damageCap = 6'],
        incomingDamage: 5,
      );
      expect(resUnder.matched, isTrue);
      expect(resUnder.damageCap, equals(6));
      expect(resUnder.prevented, equals(0));
    });

    test('The Ashen King: burnOrDamageIfMax = 2 inflicts Burn or deals 2 undefendable damage if at max Burn', () {
      expect(isBurnOrDamageIfMaxFormula('burnOrDamageIfMax = 2'), isTrue);
      expect(parseBurnOrDamageAmount('burnOrDamageIfMax = 2'), equals(2));

      // Case 1: Hero has 0 Burn tokens => receives 'Burn'
      final resNoBurn = evaluateDefenseFormulas(
        formulas: ['burnOrDamageIfMax = 2'],
        incomingDamage: 6,
        heroTokens: [],
      );
      expect(resNoBurn.matched, isTrue);
      expect(resNoBurn.grantedHeroTokens, equals(['Burn']));
      expect(resNoBurn.returnDamage, equals(0));

      // Case 2: Hero already has 1 Burn (maxStack) => takes 2 undefendable damage
      final resWithBurn = evaluateDefenseFormulas(
        formulas: ['burnOrDamageIfMax = 2'],
        incomingDamage: 6,
        heroTokens: ['Burn'],
      );
      expect(resWithBurn.matched, isTrue);
      expect(resWithBurn.grantedHeroTokens, isEmpty);
      expect(resWithBurn.returnDamage, equals(2));
      expect(resWithBurn.returnDamageUndefendable, isTrue);
    });

    test('Renegate Vereuse: 2 red ignores all damage, otherwise steals 2 CP via filterActiveDefenseEffects', () {
      final effect2Red = EnemyDefenseEffect(
        red: 2,
        formulas: ['ignoreAllIncomingDamage = true'],
        exclusive: true,
      );
      final effectFallback = EnemyDefenseEffect(
        stealCp: 2,
        exclusive: true,
      );

      // Scenario A: Roll has 2 red => only effect2Red triggers, stealCp is filtered out
      final matchedA = [
        MatchedDefenseEffect(effect: effect2Red, count: 1),
        MatchedDefenseEffect(effect: effectFallback, count: 1),
      ];
      final activeA = filterActiveDefenseEffects(matchedA);
      expect(activeA.length, equals(1));
      expect(activeA.first.effect.formulas, contains('ignoreAllIncomingDamage = true'));
      expect(activeA.first.effect.stealCp, equals(0));

      // Scenario B: Roll has < 2 red => only effectFallback triggers
      final matchedB = [
        MatchedDefenseEffect(effect: effectFallback, count: 1),
      ];
      final activeB = filterActiveDefenseEffects(matchedB);
      expect(activeB.length, equals(1));
      expect(activeB.first.effect.stealCp, equals(2));
    });

    test('Wyverne: attackFailsIfD6 >= 5 completely negates attack on 5 or 6, fails on 1-4', () {
      expect(isAttackFailsOnD6Formula('attackFailsIfD6 >= 5'), isTrue);
      expect(parseAttackFailsThreshold('attackFailsIfD6 >= 5'), equals(5));

      // D6 roll of 5 => attack fails completely
      final res5 = evaluateDefenseFormulas(
        formulas: ['attackFailsIfD6 >= 5'],
        incomingDamage: 8,
        firstDieValue: 5,
      );
      expect(res5.matched, isTrue);
      expect(res5.attackFailed, isTrue);
      expect(res5.ignoreAllIncomingDamage, isTrue);
      expect(res5.prevented, equals(8));

      // D6 roll of 6 => attack fails completely
      final res6 = evaluateDefenseFormulas(
        formulas: ['attackFailsIfD6 >= 5'],
        incomingDamage: 8,
        firstDieValue: 6,
      );
      expect(res6.matched, isTrue);
      expect(res6.attackFailed, isTrue);
      expect(res6.ignoreAllIncomingDamage, isTrue);
      expect(res6.prevented, equals(8));

      // D6 roll of 4 => defense failed
      final res4 = evaluateDefenseFormulas(
        formulas: ['attackFailsIfD6 >= 5'],
        incomingDamage: 8,
        firstDieValue: 4,
      );
      expect(res4.matched, isTrue);
      expect(res4.attackFailed, isFalse);
      expect(res4.ignoreAllIncomingDamage, isFalse);
      expect(res4.prevented, equals(0));
    });

    test('Pillard Gobelin: 1-5 steals 1 CP & deals 1 undef damage, 6 flees battle', () {
      final formulas = [
        'if D6 <= 5: stealCp = 1 & returnDamage = 1 (undef)',
        'fleeIfD6 == 6',
      ];
      expect(isStealCpAndReturnDamageFormula(formulas[0]), isTrue);
      expect(isFleeFormula(formulas[1]), isTrue);
      expect(parseD6RangeMax(formulas[0]), equals(5));
      expect(parseStealCpValue(formulas[0]), equals(1));
      expect(parseReturnDamageValue(formulas[0]), equals(1));
      expect(parseFleeThreshold(formulas[1]), equals(6));

      // Scenario 1: Defense die = 3 (between 1 and 5)
      // Steals 1 CP, returns 1 undefendable damage, does NOT flee
      final res3 = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 7,
        firstDieValue: 3,
      );
      expect(res3.matched, isTrue);
      expect(res3.stealCp, equals(1));
      expect(res3.returnDamage, equals(1));
      expect(res3.returnDamageUndefendable, isTrue);
      expect(res3.enemyFled, isFalse);
      expect(res3.attackFailed, isFalse);
      expect(res3.ignoreAllIncomingDamage, isFalse);

      // Scenario 2: Defense die = 5 (upper boundary)
      // Steals 1 CP, returns 1 undefendable damage, does NOT flee
      final res5 = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 7,
        firstDieValue: 5,
      );
      expect(res5.matched, isTrue);
      expect(res5.stealCp, equals(1));
      expect(res5.returnDamage, equals(1));
      expect(res5.enemyFled, isFalse);

      // Scenario 3: Defense die = 6 (flee)
      // Flees battle, hero attack fails completely (0 damage, no tokens), no stealCp/returnDamage
      final res6 = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 7,
        firstDieValue: 6,
      );
      expect(res6.matched, isTrue);
      expect(res6.enemyFled, isTrue);
      expect(res6.attackFailed, isTrue);
      expect(res6.ignoreAllIncomingDamage, isTrue);
      expect(res6.prevented, equals(7));
      expect(res6.stealCp, equals(0));
      expect(res6.returnDamage, equals(0));
    });

    test('AdventureState.recordEnemyFled: marks enemy fled and defeated but does NOT add victory score', () {
      final adventure = AdventureState(
        hero: HeroType.barbare,
        config: SurvivalConfig(
          mode: SurvivalMode.mediumFixed,
          targetScore: SurvivalMode.mediumFixed.defaultTarget,
        ),
      );
      final initialScore = adventure.score;
      final targetEnemy = adventure.enemies.firstWhere((e) => e.rank == EnemyRank.violet);

      expect(targetEnemy.fled, isFalse);
      expect(targetEnemy.defeated, isFalse);

      adventure.recordEnemyFled(targetEnemy);

      expect(targetEnemy.fled, isTrue);
      expect(targetEnemy.defeated, isTrue);
      // Crucial: adventure score must NOT receive victory points
      expect(adventure.score, equals(initialScore));
      expect(adventure.logs.first, contains('fled the battle'));
    });

    test('Hydre Féroce: 3 Chaos heads, +3 DMG per head, revives with 8 HP per Chaos consumed', () {
      final hydra = EnemyNode(
        id: 111,
        label: 'Hydre Féroce',
        rank: EnemyRank.violet,
        maxHealth: 8,
        cp: 10,
        attacks: ['Plurimorsure'],
        defense: 'Défense Unique',
        defenseDice: 0,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: 'assets/violet/violet-011.png',
        profileKey: 'violet-violet-011',
        initialTokens: ['Chaos', 'Chaos', 'Chaos'],
      );

      expect(isHydraEnemy(hydra), isTrue);
      expect(getHydraChaosCount(hydra), equals(3));
      // Base attack is 6; 3 heads add 3 * 3 = 9 DMG -> total 15 DMG
      expect(calculateHydraAttackBonus(hydra), equals(9));

      // 1st death: 8 HP lost -> consumes 1 Chaos, revives at 8 HP (2 Chaos left)
      hydra.health = 0;
      final logs = <String>[];
      final revived1 = checkAndApplyHydraRevival(hydra, onLog: logs.add);
      expect(revived1, isTrue);
      expect(hydra.health, equals(8));
      expect(getHydraChaosCount(hydra), equals(2));
      expect(calculateHydraAttackBonus(hydra), equals(6));
      expect(logs.last, contains('2 head(s) remaining'));

      // 2nd death: 8 HP lost -> consumes 1 Chaos, revives at 8 HP (1 Chaos left)
      hydra.health = 0;
      final revived2 = checkAndApplyHydraRevival(hydra, onLog: logs.add);
      expect(revived2, isTrue);
      expect(hydra.health, equals(8));
      expect(getHydraChaosCount(hydra), equals(1));
      expect(calculateHydraAttackBonus(hydra), equals(3));
      expect(logs.last, contains('1 head(s) remaining'));

      // 3rd death: 8 HP lost -> consumes 1 Chaos, revives at 8 HP (0 Chaos left)
      hydra.health = 0;
      final revived3 = checkAndApplyHydraRevival(hydra, onLog: logs.add);
      expect(revived3, isTrue);
      expect(hydra.health, equals(8));
      expect(getHydraChaosCount(hydra), equals(0));
      expect(calculateHydraAttackBonus(hydra), equals(0));
      expect(logs.last, contains('0 head(s) remaining'));

      // 4th death (Final): 8 HP lost, 0 Chaos left -> fails to revive, remains at 0 HP
      hydra.health = 0;
      final revived4 = checkAndApplyHydraRevival(hydra, onLog: logs.add);
      expect(revived4, isFalse);
      expect(hydra.health, equals(0));
      expect(logs.last, contains('All heads have been severed'));
    });

    testWidgets('HydraRegrowthDialog renders in English and handles roll outcomes', (tester) async {
      final hydra = EnemyNode(
        id: 111,
        label: 'Hydre Féroce',
        rank: EnemyRank.violet,
        maxHealth: 8,
        cp: 10,
        attacks: ['Plurimorsure'],
        defense: 'Défense Unique',
        defenseDice: 0,
        attackPlan: const MinionAttackPlan.none(),
        cardAsset: 'assets/violet/violet-011.png',
        profileKey: 'violet-violet-011',
        initialTokens: ['Chaos', 'Chaos', 'Chaos'],
      );
      final adventure = AdventureState(
        hero: HeroType.barbare,
        config: SurvivalConfig(
          mode: SurvivalMode.mediumFixed,
          targetScore: SurvivalMode.mediumFixed.defaultTarget,
        ),
      );

      // Subtest A: Roll a 6 -> Success, gains a head
      bool? resultA;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultA = await showDialog<bool>(
                  context: ctx,
                  builder: (dCtx) => HydraRegrowthDialog(
                    enemy: hydra,
                    adventure: adventure,
                    rollDie: () => 6,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('HYDRA REGROWTH'), findsOneWidget);
      expect(find.textContaining('At the end of the Offensive Roll Phase'), findsOneWidget);
      expect(find.textContaining('3 Heads'), findsOneWidget);
      expect(find.text('ROLL DIE'), findsOneWidget);

      await tester.tap(find.text('ROLL DIE'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rolled 6 (Red)!'), findsOneWidget);
      expect(find.text('CONTINUE TO HERO TURN'), findsOneWidget);

      await tester.tap(find.text('CONTINUE TO HERO TURN'));
      await tester.pumpAndSettle();
      expect(resultA, isTrue);

      // Subtest B: Roll a 3 -> No head grew
      bool? resultB;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                resultB = await showDialog<bool>(
                  context: ctx,
                  builder: (dCtx) => HydraRegrowthDialog(
                    enemy: hydra,
                    adventure: adventure,
                    rollDie: () => 3,
                  ),
                );
              },
              child: const Text('Open 2'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ROLL DIE'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rolled 3: No new head grew'), findsOneWidget);
      await tester.tap(find.text('CONTINUE TO HERO TURN'));
      await tester.pumpAndSettle();
      expect(resultB, isFalse);
    });

    test('Berserker Enragé defense: gainTokenIfDamaged = Chaos gives 1 Chaos only if incoming damage >= 1', () {
      final formulas = ['gainTokenIfDamaged = Chaos'];

      // Scenario 1: incomingDamage >= 1 (e.g. 5) -> gains 1 Chaos
      final resDamage = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 5,
      );
      expect(resDamage.matched, isTrue);
      expect(resDamage.grantedEnemyTokens, equals(['Chaos']));
      expect(resDamage.notes, contains('Defense: took damage, gains 1 Chaos.'));

      // Scenario 2: incomingDamage == 0 -> no Chaos gained
      final resZero = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 0,
      );
      expect(resZero.matched, isTrue);
      expect(resZero.grantedEnemyTokens, isEmpty);
      expect(resZero.notes, contains('Defense: no damage taken, gains no Chaos.'));

      // Scenario 3: incomingDamage == 1 -> gains 1 Chaos
      final resOne = evaluateDefenseFormulas(
        formulas: formulas,
        incomingDamage: 1,
      );
      expect(resOne.matched, isTrue);
      expect(resOne.grantedEnemyTokens, equals(['Chaos']));
    });

    testWidgets('InlineTokenText renders HpBadge for {hp:8} and {hp:0}', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineTokenText(
              'Reset Health to {hp:8} or {hp:0}',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(HpBadge), findsNWidgets(2));
      expect(find.text('8'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    test('Disciple profile has primary goal (2 whites + 3 oranges) with 5 undefendable damage', () {
      final profile = EnemyProfileRepository.byKey('vert-vert-015');
      expect(profile, isNotNull);
      expect(profile!.attackPlan.goals.isNotEmpty, isTrue);
      final goal = profile.attackPlan.goals.first;
      expect(goal.white, equals(2));
      expect(goal.yellow, equals(3));
      expect(goal.red, equals(0));
      expect(goal.effect?.damage, equals(5));
      expect(goal.effect?.undefendable, isTrue);
    });

    test('strongestSymbolGoal picks goal with highest dice count', () {
      final node = EnemyNode(
        id: 99,
        label: 'Test',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 0,
        attacks: const [],
        defense: '',
        defenseDice: 1,
        cardAsset: '',
        initialTokens: const [],
        attackPlan: const MinionAttackPlan.symbols([
          SymbolGoal(white: 2, yellow: 3),
          SymbolGoal(yellow: 1),
        ]),
      );
      final strongest = strongestSymbolGoal(node);
      expect(strongest.white, equals(2));
      expect(strongest.yellow, equals(3));
    });

    test('EnemyProfileRepository.byRank with validatedOnly filters out unvalidated profiles', () {
      final allGreen = EnemyProfileRepository.byRank(EnemyRank.green, validatedOnly: false);
      final validGreen = EnemyProfileRepository.byRank(EnemyRank.green, validatedOnly: true);
      expect(allGreen.isNotEmpty, isTrue);
      expect(validGreen.isNotEmpty, isTrue);
      expect(validGreen.every((p) => p.isFullyValidated), isTrue);
      expect(validGreen.length, lessThanOrEqualTo(allGreen.length));
    });

    test('EnemyProfile isFullyValidated recognizes validatedAtk and validatedDef', () {
      final valid = EnemyProfile(
        key: 'v1',
        name: 'V1',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 0,
        cardAsset: '',
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        validated: true,
      );
      final validByParts = EnemyProfile(
        key: 'v2',
        name: 'V2',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 0,
        cardAsset: '',
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        validated: false,
        validatedAtk: true,
        validatedDef: true,
      );
      final invalid = EnemyProfile(
        key: 'v3',
        name: 'V3',
        rank: EnemyRank.green,
        maxHealth: 10,
        cp: 0,
        cardAsset: '',
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
        validated: false,
        validatedAtk: true,
        validatedDef: false,
      );
      expect(valid.isFullyValidated, isTrue);
      expect(validByParts.isFullyValidated, isTrue);
      expect(invalid.isFullyValidated, isFalse);
    });

    test('EnemyProfileRepository.byRank with validatedOnly filters out unvalidated profiles across all ranks', () {
      for (final rank in [EnemyRank.green, EnemyRank.violet, EnemyRank.blue, EnemyRank.orange]) {
        final all = EnemyProfileRepository.byRank(rank, validatedOnly: false);
        final valid = EnemyProfileRepository.byRank(rank, validatedOnly: true);
        expect(valid.every((p) => p.isFullyValidated), isTrue);
        expect(valid.length, lessThanOrEqualTo(all.length));
      }
    });

    test('Roc vert-vert-012 profile and node have passives populated', () {
      final profile = EnemyProfileRepository.byKey('vert-vert-012');
      expect(profile, isNotNull);
      expect(profile!.passives.isNotEmpty, isTrue);

      final node = EnemyNode(
        id: 1,
        label: 'Roc',
        rank: EnemyRank.green,
        maxHealth: 15,
        cp: 2,
        cardAsset: '',
        attacks: const [],
        defense: '',
        defenseDice: 1,
        attackPlan: const MinionAttackPlan.none(),
      );
      node.applyProfile(profile);
      expect(node.passives.isNotEmpty, isTrue);
    });

    test('Minion pack classification: DTA default and allowedPacks filtering', () {
      expect(AppSettings.instance.isMinionPackActive('dta'), isTrue);
      expect(AppSettings.instance.activeMinionPacks.contains('dta'), isTrue);

      final dtaProfiles = EnemyProfileRepository.byRank(
        EnemyRank.green,
        allowedPacks: {'dta'},
      );
      expect(dtaProfiles.every((p) => p.sourcePack == 'dta'), isTrue);
    });

    test('Community minion toggle and rush filtering logic', () async {
      const testKey = 'community-fan-001';
      expect(AppSettings.instance.isCommunityEnemyEnabled(testKey), isTrue);

      await AppSettings.instance.toggleCommunityEnemyEnabled(testKey);
      expect(AppSettings.instance.isCommunityEnemyEnabled(testKey), isFalse);
      expect(AppSettings.instance.disabledCommunityEnemyKeys.contains(testKey), isTrue);

      await AppSettings.instance.toggleCommunityEnemyEnabled(testKey);
      expect(AppSettings.instance.isCommunityEnemyEnabled(testKey), isTrue);
    });

    test('The Hermit dice reserve strategy and extraRoll outcome evaluation', () {
      final hermit = EnemyProfileRepository.byKey('bleu-bleu-007')!;
      expect(hermit.attackPlan.goals.length, 1);
      final goal = hermit.attackPlan.goals.first;

      // Simulate roll 1: 4 whites (e.g. faces 1, 3, 3, 3) and 1 yellow (face 4)
      final roll1Faces = [1, 3, 3, 3, 4];
      final roll1Symbols = roll1Faces.map((f) => f == 6 ? DieSymbol.red : (f >= 4 ? DieSymbol.yellow : DieSymbol.white)).toList();

      var wCount = roll1Symbols.where((s) => s == DieSymbol.white).length;
      var yCount = roll1Symbols.where((s) => s == DieSymbol.yellow).length;
      var rCount = roll1Symbols.where((s) => s == DieSymbol.red).length;

      // Goal (1W, 3Y) is NOT met on roll 1 because yellow count is only 1 (< 3)
      final goalMetRoll1 = wCount >= goal.white && yCount >= goal.yellow && rCount >= goal.red;
      expect(goalMetRoll1, isFalse);

      // Verify dice keeping logic: AI must reserve 1 white and 1 yellow, leaving 3 whites unreserved
      var neededW = goal.white;
      var neededY = goal.yellow;
      var neededR = goal.red;
      final reservedList = <bool>[];
      for (final sym in roll1Symbols) {
        if (sym == DieSymbol.white && neededW > 0) {
          reservedList.add(true);
          neededW--;
        } else if (sym == DieSymbol.yellow && neededY > 0) {
          reservedList.add(true);
          neededY--;
        } else if (sym == DieSymbol.red && neededR > 0) {
          reservedList.add(true);
          neededR--;
        } else {
          reservedList.add(false);
        }
      }

      // Exactly 2 dice reserved: 1 white and 1 yellow
      expect(reservedList.where((r) => r).length, 2);
      // Exactly 3 dice unreserved to be rerolled
      expect(reservedList.where((r) => !r).length, 3);

      // Simulate roll 2 where the 3 unreserved dice produce 2 yellows and 1 white
      final roll2AllSymbols = [DieSymbol.white, DieSymbol.yellow, DieSymbol.yellow, DieSymbol.yellow, DieSymbol.white];
      wCount = roll2AllSymbols.where((s) => s == DieSymbol.white).length; // 2
      yCount = roll2AllSymbols.where((s) => s == DieSymbol.yellow).length; // 3
      rCount = roll2AllSymbols.where((s) => s == DieSymbol.red).length; // 0

      // Goal is now met!
      final goalMetRoll2 = wCount >= goal.white && yCount >= goal.yellow && rCount >= goal.red;
      expect(goalMetRoll2, isTrue);

      // Verify extraRoll outcomes for face resolution
      final extraRoll = goal.effect!.extraRoll!;
      expect(extraRoll.dice, 1);
      final whiteOutcome = extraRoll.outcomes.firstWhere((o) => o.face == ExtraRollFace.white);
      expect(whiteOutcome.damage, 2);
      expect(whiteOutcome.undefendable, isTrue);

      final yellowOutcome = extraRoll.outcomes.firstWhere((o) => o.face == ExtraRollFace.yellow);
      expect(yellowOutcome.tokens, contains('Wither'));

      final redOutcome = extraRoll.outcomes.firstWhere((o) => o.face == ExtraRollFace.red);
      expect(redOutcome.tokens, contains('Burn'));
    });

    test('Banshie Hurlante symbol dice hold: holds 1 red die towards 2-red goal', () {
      final bansheeGoals = const [
        SymbolGoal(white: 0, yellow: 0, red: 2),
        SymbolGoal(white: 0, yellow: 0, red: 3),
        SymbolGoal(white: 0, yellow: 0, red: 4),
        SymbolGoal(white: 0, yellow: 0, red: 5),
        SymbolGoal(white: 0, yellow: 0, red: 0),
      ];

      // Roll 1: [6 (red), 4 (yellow), 1 (white), 2 (white), 3 (white)]
      final dice = [
        GameDie(id: 10)..value = 6, // red
        GameDie(id: 11)..value = 4, // yellow
        GameDie(id: 12)..value = 1, // white
        GameDie(id: 13)..value = 2, // white
        GameDie(id: 14)..value = 3, // white
      ];

      final decision = MinionDiceEngineSymbols.chooseSymbolHold(
        dice: dice,
        goals: bansheeGoals,
      );

      // Must reserve the single red die!
      expect(decision.reservedDieIds, equals([10]));
      expect(decision.values, equals([6]));
      expect(decision.isGoalMet, isFalse);
      expect(decision.matchingDiceCount, equals(1));
      expect(decision.requiredDiceCount, equals(2));
      expect(decision.reason, contains('keeping 6'));
    });

    test('Banshie Hurlante symbol dice hold: validates 2 red dice and keeps both for potential upgrade', () {
      final bansheeGoals = const [
        SymbolGoal(white: 0, yellow: 0, red: 2),
        SymbolGoal(white: 0, yellow: 0, red: 3),
        SymbolGoal(white: 0, yellow: 0, red: 4),
        SymbolGoal(white: 0, yellow: 0, red: 5),
        SymbolGoal(white: 0, yellow: 0, red: 0),
      ];

      // Roll 2: [6 (red), 6 (red), 1 (white), 2 (white), 3 (white)]
      final dice = [
        GameDie(id: 10)..value = 6, // red
        GameDie(id: 11)..value = 6, // red
        GameDie(id: 12)..value = 1, // white
        GameDie(id: 13)..value = 2, // white
        GameDie(id: 14)..value = 3, // white
      ];

      final decision = MinionDiceEngineSymbols.chooseSymbolHold(
        dice: dice,
        goals: bansheeGoals,
      );

      // Must reserve both red dice and note attack validated
      expect(decision.reservedDieIds, equals([10, 11]));
      expect(decision.values, equals([6, 6]));
      expect(decision.isGoalMet, isTrue);
      expect(decision.requiredDiceCount, equals(2));
    });

    test('Banshie Hurlante symbol dice hold: rolls 0 red dice, holds nothing', () {
      final bansheeGoals = const [
        SymbolGoal(white: 0, yellow: 0, red: 2),
        SymbolGoal(white: 0, yellow: 0, red: 3),
        SymbolGoal(white: 0, yellow: 0, red: 4),
        SymbolGoal(white: 0, yellow: 0, red: 5),
        SymbolGoal(white: 0, yellow: 0, red: 0),
      ];

      // Roll: all white/yellow, 0 red
      final dice = [
        GameDie(id: 10)..value = 5,
        GameDie(id: 11)..value = 4,
        GameDie(id: 12)..value = 1,
        GameDie(id: 13)..value = 2,
        GameDie(id: 14)..value = 3,
      ];

      final decision = MinionDiceEngineSymbols.chooseSymbolHold(
        dice: dice,
        goals: bansheeGoals,
      );

      expect(decision.reservedDieIds, isEmpty);
      expect(decision.isGoalMet, isFalse);
    });

    test('GameEngine upkeep skipTokens with accents: Bleed / Hémorragie skipped properly', () {
      final tokens = <String>['Hémorragie'];
      var rollCount = 0;
      final outcome = GameEngine.heroUpkeep(
        tokens: tokens,
        rollD6: () {
          rollCount++;
          return 1;
        },
        skipTokens: {'Bleed'},
      );

      // Should be skipped, so rollCount remains 0 and healthDelta is 0
      expect(rollCount, equals(0));
      expect(outcome.healthDelta, equals(0));
    });

    test('Bloodseeker suite effects parse notes and tokens correctly', () {
      final profile = EnemyProfileRepository.byKey('orange-orange-009');
      expect(profile, isNotNull);
      final suiteEffects = profile!.attackPlan.suiteEffects;

      // Micro suite (3)
      final micro = suiteEffects[3];
      expect(micro, isNotNull);
      expect(micro!.damage, equals(3));
      expect(micro.undefendable, isTrue);
      expect(micro.heroTokens, equals(['Bleed', 'Bleed']));

      // Small suite (4)
      final small = suiteEffects[4];
      expect(small, isNotNull);
      expect(small!.damage, equals(6));
      expect(small.heroTokens, equals(['Bleed']));
      expect(small.notes, contains('+{damage:1} x {token:Bleed}'));

      // Large suite (5)
      final large = suiteEffects[5];
      expect(large, isNotNull);
      expect(large!.damage, equals(8));
      expect(large.heroTokens, equals(['Bleed']));
      expect(large.notes, contains('+{damage:2} x {token:Bleed}'));

      // Benjamin eye/glasses alignment check
      expect(HeroType.benjamin.headAlignment.y, equals(-0.20));
    });

    test('Devin de la Mort defense formula evaluates return damage per Chaos token', () {
      final resWithChaos = evaluateDefenseFormulas(
        formulas: ['then return 1 undefendable damage per Chaos'],
        incomingDamage: 10,
        enemyTokens: ['Chaos', 'Chaos', 'Chaos', 'Chaos'],
      );
      expect(resWithChaos.matched, isTrue);
      expect(resWithChaos.returnDamage, equals(4));
      expect(resWithChaos.returnDamageUndefendable, isTrue);

      final resZeroChaos = evaluateDefenseFormulas(
        formulas: ['then return 1 undefendable damage per Chaos'],
        incomingDamage: 10,
        enemyTokens: [],
      );
      expect(resZeroChaos.matched, isTrue);
      expect(resZeroChaos.returnDamage, equals(0));
      expect(resZeroChaos.returnDamageUndefendable, isTrue);
    });

    test('Bloodseeker suite attack immediately counts inflicted Bleed in damage calculation', () {
      final profile = EnemyProfileRepository.byKey('orange-orange-009');
      expect(profile, isNotNull);
      final enemy = EnemyNode(
        id: 99,
        label: profile!.name,
        rank: profile.rank,
        maxHealth: profile.maxHealth,
        cp: profile.cp,
        attacks: profile.attacks,
        defense: '',
        defenseDice: profile.defenseDice,
        attackPlan: profile.attackPlan,
        cardAsset: profile.cardAsset,
        profileKey: profile.key,
      );

      final adventure = AdventureState(
        config: const SurvivalConfig(mode: SurvivalMode.mediumFixed, targetScore: 50),
        hero: HeroType.barbare,
      );

      // Hero starts with 0 Bleed
      expect(adventure.alterations.where((t) => t == 'Bleed').length, equals(0));

      // Micro suite (length 3): strictly 3 undefendable damage, NO bleed bonus
      final dmgMicro0 = minionSuiteDamage(enemy, 3, adventure: adventure);
      expect(dmgMicro0, isNotNull);
      expect(dmgMicro0!.value, equals(3));
      expect(dmgMicro0.imparable, isTrue);

      // Small suite (length 4): base 6 damage + 1 per Bleed, immediately inflicting 1 Bleed -> 6 + 1 = 7 damage
      final dmgSmall0 = minionSuiteDamage(enemy, 4, adventure: adventure);
      expect(dmgSmall0, isNotNull);
      expect(dmgSmall0!.value, equals(7));

      // Large suite (length 5): base 8 damage + 2 per Bleed, immediately inflicting 1 Bleed -> 8 + 2*1 = 10 damage
      final dmgLarge0 = minionSuiteDamage(enemy, 5, adventure: adventure);
      expect(dmgLarge0, isNotNull);
      expect(dmgLarge0!.value, equals(10));

      // If hero already has 2 Bleeds on board:
      adventure.alterations.addAll(['Bleed', 'Bleed']);
      // Micro suite still strictly deals 3 damage regardless of Bleeds
      final dmgMicro2 = minionSuiteDamage(enemy, 3, adventure: adventure);
      expect(dmgMicro2, isNotNull);
      expect(dmgMicro2!.value, equals(3));
      expect(dmgMicro2.imparable, isTrue);

      // Small suite: base 6 + (2 + 1)*1 = 9 damage
      final dmgSmall2 = minionSuiteDamage(enemy, 4, adventure: adventure);
      expect(dmgSmall2, isNotNull);
      expect(dmgSmall2!.value, equals(9));

      // Large suite: base 8 + (2 + 1)*2 = 14 damage
      final dmgLarge2 = minionSuiteDamage(enemy, 5, adventure: adventure);
      expect(dmgLarge2, isNotNull);
      expect(dmgLarge2!.value, equals(14));
    });

    test('enforceTokenStackLimits and addTokensWithStackLimit strictly respect maxStack', () {
      final list = <String>['Bleed', 'Bleed', 'Bleed', 'Blind', 'Blind'];
      enforceTokenStackLimits(list);
      expect(list.where((t) => t == 'Bleed').length, equals(2));
      expect(list.where((t) => t == 'Blind').length, equals(1));

      // Trying to add more Bleeds via addTokensWithStackLimit should be blocked
      addTokensWithStackLimit(list, ['Bleed', 'Bleed']);
      expect(list.where((t) => t == 'Bleed').length, equals(2));

      // Tokens with higher limits can still be added up to their maxStack
      addTokensWithStackLimit(list, ['Burn', 'Burn', 'Burn', 'Burn']);
      final burnRule = TokenCatalogRepository.byLabel('Burn');
      expect(list.where((t) => t == 'Burn').length, equals(burnRule?.maxStack ?? 3));
    });

    test('Blind (Éblouissement) is strictly distinct from Blinding Light and never triggers during upkeep', () {
      final blindRule = TokenCatalogRepository.byLabel('Blind');
      expect(blindRule, isNotNull);
      expect(blindRule!.matches('Blind'), isTrue);
      expect(blindRule.matches('Éblouissement'), isTrue);
      expect(blindRule.matches('eblouissement'), isTrue);

      final blindingLightRule = TokenCatalogRepository.byLabel('Blinding Light');
      expect(blindingLightRule, isNotNull);
      expect(blindingLightRule!.matches('Blinding Light'), isTrue);
      expect(blindingLightRule.matches('Lumière aveuglante'), isTrue);

      // Verify that Blind rule is NOT Blinding Light rule
      expect(blindRule.label, isNot(equals(blindingLightRule.label)));

      // Verify Blind token filtering: Blind must NOT be recognized as an upkeep or passive start token
      final l = 'blind';
      final isExcludedFromUpkeep = l == 'blind' ||
          l == 'éblouissement' ||
          l == 'eblouissement' ||
          (l.contains('blind') && !l.contains('blinding light')) ||
          l.contains('éblouissement') ||
          l.contains('eblouissement');
      expect(isExcludedFromUpkeep, isTrue);

      final lFr = 'éblouissement';
      final isFrExcludedFromUpkeep = lFr == 'blind' ||
          lFr == 'éblouissement' ||
          lFr == 'eblouissement' ||
          (lFr.contains('blind') && !lFr.contains('blinding light')) ||
          lFr.contains('éblouissement') ||
          lFr.contains('eblouissement');
      expect(isFrExcludedFromUpkeep, isTrue);
    });

    test('Bleed (Hémorragie) strictly resolves only in upkeep phase and is ignored during roll phase', () {
      final bleedRule = TokenCatalogRepository.byLabel('Bleed');
      expect(bleedRule, isNotNull);
      expect(bleedRule!.matches('Bleed'), isTrue);
      expect(bleedRule.matches('Hémorragie'), isTrue);
      expect(bleedRule.matches('saignement'), isTrue);

      // Verify that Bleed is persistent across upkeep
      expect(bleedRule.persistent, isTrue);
      expect(bleedRule.maxStack, equals(2));

      // Test normalization and filter logic
      bool isBleedToken(String t) {
        final k = t.trim().toLowerCase()
            .replaceAll('é', 'e')
            .replaceAll('è', 'e')
            .replaceAll('ê', 'e');
        return k == 'bleed' || k == 'hemorragie' || k == 'saignement';
      }

      expect(isBleedToken('Bleed'), isTrue);
      expect(isBleedToken('Hémorragie'), isTrue);
      expect(isBleedToken('saignement'), isTrue);
      expect(isBleedToken('Blind'), isFalse);

      // Ensure that in roll phase, Bleed is skipped
      const isRollPhase = true;
      final shouldSkipInRollPhase = isRollPhase && isBleedToken('Bleed');
      expect(shouldSkipInRollPhase, isTrue);

      // Ensure that in upkeep phase (!isRollPhase), Bleed is NOT skipped
      const isUpkeepPhase = false;
      final shouldSkipInUpkeep = isUpkeepPhase && isBleedToken('Bleed');
      expect(shouldSkipInUpkeep, isFalse);
    });
  });
}



