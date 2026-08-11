import 'package:dice_throne_survie/main.dart';
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
  });
}
