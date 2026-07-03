class RewardOutcome {
  const RewardOutcome({
    required this.label,
    required this.healthDelta,
    required this.cpDelta,
    this.token,
  });

  final String label;
  final int healthDelta;
  final int cpDelta;
  final String? token;
}

class UpkeepOutcome {
  const UpkeepOutcome({
    required this.cpDelta,
    required this.healthDelta,
    required this.removedTokens,
    required this.log,
  });

  final int cpDelta;
  final int healthDelta;
  final List<String> removedTokens;
  final String log;
}

class GameEngine {
  const GameEngine._();

  static RewardOutcome rewardForD20(int d20) {
    if (d20 <= 10) {
      return const RewardOutcome(label: '+1 HP', healthDelta: 1, cpDelta: 0);
    }
    return const RewardOutcome(label: '+1 CP', healthDelta: 0, cpDelta: 1);
  }

  static int combatPointStartGain() => 1;

  static UpkeepOutcome minionUpkeep({
    required List<String> tokens,
    required int Function() rollD6,
  }) {
    final poisonCount = tokens.where((token) => token == 'Poison').length;
    final hemorrhageCount = tokens
        .where((token) => token == 'Hémorragie')
        .length;
    var healthDelta = -poisonCount;
    var hemorrhageDamage = 0;
    final removed = <String>[];

    for (var i = 0; i < hemorrhageCount; i++) {
      final roll = rollD6();
      if (roll <= 4) {
        hemorrhageDamage++;
        healthDelta--;
      } else {
        removed.add('Hémorragie');
      }
    }

    final parts = <String>['+1 CP'];
    if (poisonCount > 0) {
      parts.add('-$poisonCount HP from Poison');
    }
    if (hemorrhageCount > 0) {
      parts.add('Hemorrhage -$hemorrhageDamage HP / ${removed.length} removed');
    }

    return UpkeepOutcome(
      cpDelta: 1,
      healthDelta: healthDelta,
      removedTokens: removed,
      log: parts.join(', '),
    );
  }
}
