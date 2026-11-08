part of '../../main.dart';

/// Business logic for the final snake boss (Ourokhor).
///
/// Gauge:
/// - Venom Gauge from 0 to 25, tracking total poison/venom damage suffered by the hero across the battle.
///
/// Passive:
/// - Ourokhor gains cumulative milestone tokens EVERY TURN at minion upkeep,
///   strictly respecting Dice Throne stack limits:
///   * >= 5: Damage bonus 2 (max 2 total damage bonus tokens)
///   * >= 10: Riposte (max 1 stack)
///   * >= 15: Evasive (max 3 stacks)
///   * >= 20: Damage bonus 3 (max 2 total damage bonus tokens)
///   * >= 25: Hex inflicted on hero every turn (max 1 stack)
///
/// Passive:
/// - In case of an Offensive Roll failure (échec du roll), Ourokhor heals HP equal
///   to the current Venom Gauge value.
class OurokhorLogic {
  static const int maxPoisonGauge = 25;
  static const int maxTotalDamageBonus = 2;
  static const int maxRiposte = 1;
  static const int maxEvasive = 3;
  static const int maxHex = 1;

  /// Checks if a token label represents a Damage bonus token.
  static bool isDamageBonusToken(String token) {
    final k = _normalizeTokenKey(token);
    return k.contains('damagebonus') ||
        k.contains('bonusdamage') ||
        k.contains('degatbonus') ||
        k.contains('dégâtbonus');
  }

  /// Counts total damage bonus tokens present in an alterations list.
  static int countDamageBonus(Iterable<String> alterations) {
    return alterations.where(isDamageBonusToken).length;
  }

  /// Counts matching tokens in an alterations list using normalized keys.
  static int countToken(Iterable<String> alterations, String tokenLabel) {
    final targetKey = _normalizeTokenKey(tokenLabel);
    return alterations.where((t) => _normalizeTokenKey(t) == targetKey).length;
  }

  /// Evaluates which tokens Ourokhor should receive at upkeep, strictly respecting
  /// the official Dice Throne max stack rules:
  /// - Damage bonus: max 2 total across all damage bonus tokens.
  /// - Riposte: max 1.
  /// - Evasive: max 3.
  static List<String> evaluateUpkeepTokens({
    required int gauge,
    required List<String> enemyAlterations,
  }) {
    final toAdd = <String>[];
    var currentDb = countDamageBonus(enemyAlterations);

    // Milestones 20 (+3 Dmg) and 5 (+2 Dmg): max 2 Damage bonus tokens total
    if (gauge >= 20 && currentDb < maxTotalDamageBonus) {
      toAdd.add('Damage bonus 3');
      currentDb++;
    }
    if (gauge >= 5 && currentDb < maxTotalDamageBonus) {
      toAdd.add('Damage bonus 2');
      currentDb++;
    }

    // Milestone 10: Riposte (max 1)
    if (gauge >= 10) {
      final riposteCount = countToken(enemyAlterations, 'Riposte') +
          countToken(enemyAlterations, 'Back Strike');
      if (riposteCount < maxRiposte) {
        toAdd.add('Riposte');
      }
    }

    // Milestone 15: Evasive (max 3)
    if (gauge >= 15) {
      final evasiveCount = countToken(enemyAlterations, 'Evasive') +
          countToken(enemyAlterations, 'Évitement') +
          countToken(enemyAlterations, 'Evitement');
      if (evasiveCount < maxEvasive) {
        toAdd.add('Evasive');
      }
    }

    return toAdd;
  }

  /// Checks if hero should receive Hex at upkeep (max 1 stack).
  static bool shouldInflictHexToHero({
    required int gauge,
    required List<String> heroAlterations,
  }) {
    if (gauge < 25) return false;
    final hexCount = countToken(heroAlterations, 'Hex') +
        countToken(heroAlterations, 'Maléfice') +
        countToken(heroAlterations, 'Malefice');
    return hexCount < maxHex;
  }

  /// Returns minion tokens to grant at upkeep based on the poison gauge (unfiltered).
  static List<String> minionTokensForGauge(int gauge) {
    final list = <String>[];
    if (gauge >= 5) list.add('Damage bonus 2');
    if (gauge >= 10) list.add('Riposte');
    if (gauge >= 15) list.add('Evasive');
    if (gauge >= 20) list.add('Damage bonus 3');
    return list;
  }

  /// Checks if the hero should receive Hex token at upkeep based purely on gauge.
  static bool shouldInflictHex(int gauge) => gauge >= 25;

  /// Advances the gauge without immediate healing.
  static int advanceGauge({
    required int currentGauge,
    required int poisonDamage,
  }) {
    if (poisonDamage <= 0) return currentGauge;
    return (currentGauge + poisonDamage).clamp(0, maxPoisonGauge);
  }

  /// Calculates healing when offensive roll fails (equal to current poison gauge).
  static int failureRollHeal(int gauge) => gauge.clamp(0, maxPoisonGauge);

  /// Compatibility wrapper for registering poison damage.
  static ({int newGauge, int healAmount}) registerPoisonDamage({
    required int currentGauge,
    required int poisonDamage,
  }) {
    final next = advanceGauge(
      currentGauge: currentGauge,
      poisonDamage: poisonDamage,
    );
    return (newGauge: next, healAmount: 0);
  }
}
