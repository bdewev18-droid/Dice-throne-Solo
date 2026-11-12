part of '../../main.dart';

/// Business logic for the final snake boss (Ourokhor).
///
/// Venom Gauge:
/// - Gauge from 0 to 24, tracking total poison/venom damage suffered by the hero.
/// - When the gauge reaches each threshold for the first time, the hero is immediately
///   afflicted with the corresponding negative status token:
///   * 0: Targeted
///   * 3: Knockdown
///   * 6: Wither
///   * 9: Prey
///   * 12: Blind
///   * 15: Bleed
///   * 18: Blinding Light
///   * 21: Hex
///   * 24: Stun
///
/// Upkeep / Passives:
/// - No recurring upkeep buffs to Ourokhor.
/// - No offensive failure heal (Venom Leech suppressed).
class OurokhorLogic {
  static const int maxPoisonGauge = 24;

  static const List<({int threshold, String token, String label, String asset, String description})> milestones = [
    (
      threshold: 0,
      token: 'Targeted',
      label: 'Targeted',
      asset: 'assets/token/Targeted.png',
      description: 'Hero is afflicted with Targeted',
    ),
    (
      threshold: 3,
      token: 'Knockdown',
      label: 'Knockdown',
      asset: 'assets/token/A-terre.png',
      description: 'Hero is afflicted with Knockdown',
    ),
    (
      threshold: 6,
      token: 'Wither',
      label: 'Wither',
      asset: 'assets/token/Wither.png',
      description: 'Hero is afflicted with Wither',
    ),
    (
      threshold: 9,
      token: 'Prey',
      label: 'Prey',
      asset: 'assets/token/Prey.png',
      description: 'Hero is afflicted with Prey',
    ),
    (
      threshold: 12,
      token: 'Blind',
      label: 'Blind',
      asset: 'assets/token/Blind.png',
      description: 'Hero is afflicted with Blind',
    ),
    (
      threshold: 15,
      token: 'Bleed',
      label: 'Bleed',
      asset: 'assets/token/Bleed.png',
      description: 'Hero is afflicted with Bleed',
    ),
    (
      threshold: 18,
      token: 'Blinding Light',
      label: 'Blind Light',
      asset: 'assets/token/Blinding-Light.png',
      description: 'Hero is afflicted with Blinding Light',
    ),
    (
      threshold: 21,
      token: 'Hex',
      label: 'Hex',
      asset: 'assets/token/hex.png',
      description: 'Hero is afflicted with Hex',
    ),
    (
      threshold: 24,
      token: 'Stun',
      label: 'Stun',
      asset: 'assets/token/stun.png',
      description: 'Hero is afflicted with Stun',
    ),
  ];

  /// Returns all milestone tokens that should trigger when the gauge reaches
  /// or exceeds thresholds that have not been triggered yet.
  static List<({int threshold, String token})> evaluateMilestonesToTrigger({
    required int gauge,
    required Set<int> alreadyTriggered,
  }) {
    final list = <({int threshold, String token})>[];
    for (final m in milestones) {
      if (gauge >= m.threshold && !alreadyTriggered.contains(m.threshold)) {
        list.add((threshold: m.threshold, token: m.token));
      }
    }
    return list;
  }

  /// Advances the gauge without healing.
  static int advanceGauge({
    required int currentGauge,
    required int poisonDamage,
  }) {
    if (poisonDamage <= 0) return currentGauge;
    return (currentGauge + poisonDamage).clamp(0, maxPoisonGauge);
  }

  /// Compatibility stub: heal on roll failure is suppressed.
  static int failureRollHeal(int gauge) => 0;

  /// Checks if a token label represents a Damage bonus token.
  static bool isDamageBonusToken(String token) {
    final k = _normalizeTokenKey(token);
    return k.contains('damagebonus') ||
        k.contains('bonusdamage') ||
        k.contains('degatbonus') ||
        k.contains('dégâtbonus');
  }

  /// Counts matching tokens in an alterations list using normalized keys.
  static int countToken(Iterable<String> alterations, String tokenLabel) {
    final targetKey = _normalizeTokenKey(tokenLabel);
    return alterations.where((t) => _normalizeTokenKey(t) == targetKey).length;
  }

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
