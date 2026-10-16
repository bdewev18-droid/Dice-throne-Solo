part of '../../main.dart';

/// Checks if an enemy node is the Fierce Hydra ("Hydre Féroce", key: violet-violet-011).
bool isHydraEnemy(EnemyNode? enemy) {
  if (enemy == null) return false;
  final key = enemy.profileKey?.toLowerCase() ?? '';
  if (key == 'violet-violet-011' || key == 'hydre-feroce' || key == 'hydre_feroce') {
    return true;
  }
  final label = enemy.label.toLowerCase().trim();
  return label == 'hydre feroce' || label == 'hydre féroce';
}

/// Returns the current number of Chaos tokens (heads) in the Hydra's possession.
int getHydraChaosCount(EnemyNode? enemy) {
  if (enemy == null) return 0;
  return enemy.alterations
      .where((t) => t.trim().toLowerCase() == 'chaos')
      .length;
}

/// Computes the bonus damage from the Hydra's Chaos tokens (+3 damage per head).
int calculateHydraAttackBonus(EnemyNode enemy) {
  if (!isHydraEnemy(enemy)) return 0;
  return getHydraChaosCount(enemy) * 3;
}

/// Checks and applies the Fierce Hydra's Unique Defense:
/// If health drops to 0 while Chaos tokens (heads) remain, consumes 1 Chaos token
/// and immediately resets health to 8 HP.
/// Returns true if revived, false otherwise.
bool checkAndApplyHydraRevival(
  EnemyNode enemy, {
  void Function(String msg)? onLog,
}) {
  if (!isHydraEnemy(enemy) || enemy.health > 0) {
    return false;
  }

  final chaosIdx = enemy.alterations.indexWhere(
    (t) => t.trim().toLowerCase() == 'chaos',
  );

  if (chaosIdx != -1) {
    enemy.alterations.removeAt(chaosIdx);
    final remainingHeads = getHydraChaosCount(enemy);
    enemy.health = 8;
    final logMsg =
        '🐉 [FIERCE HYDRA] A head was severed! ($remainingHeads head(s) remaining). The Hydra immediately regenerates 8 HP!';
    onLog?.call(logMsg);
    return true;
  } else {
    onLog?.call('🐉 [FIERCE HYDRA] All heads have been severed! The Hydra collapses for good.');
    return false;
  }
}
