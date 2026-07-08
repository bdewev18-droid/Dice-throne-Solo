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

  static RewardOutcome rewardForD20(int d20, {String chest = 'green'}) {
    final table = _rewardTables[chest] ?? _rewardTables['green']!;
    final code = table[(d20.clamp(1, 20)) - 1];
    return _rewardFromCode(code);
  }

  static const Map<String, List<String>> _rewardTables = {
    'green': [
      '1d',
      '1d',
      '2d',
      '2d',
      '1cp',
      '1cp',
      '2cp',
      '1vol',
      '1p',
      '1p',
      '2hp',
      '2hp',
      '3hp',
      '3hp',
      '1v',
      '1v',
      '1v',
      '1v',
      '1b',
      '1b',
    ],
    'blue': [
      '2d',
      '2d',
      '3d',
      '1cp',
      '2cp',
      '2cp',
      '1vol',
      '1vol',
      '1p',
      '2p',
      '3hp',
      '3hp',
      '4hp',
      '4hp',
      '1v',
      '1v',
      '1b',
      '1b',
      '1b',
      '1vi',
    ],
    'violet': [
      '3d',
      '3d',
      '4d',
      '2cp',
      '3cp',
      '1vol',
      '1vol',
      '1vol',
      '2p',
      '3p',
      '4hp',
      '4hp',
      '5hp',
      '5hp',
      '1b',
      '1b',
      '1b',
      '1vi',
      '1vi',
      '1o',
    ],
    'orange': [
      '1v',
      '1v',
      '1v',
      '1v',
      '1v',
      '1v',
      '1b',
      '1b',
      '1b',
      '1b',
      '1b',
      '1b',
      '1vi',
      '1vi',
      '1vi',
      '1vi',
      '1vi',
      '1o',
      '1o',
      '1o',
    ],
  };

  static RewardOutcome _rewardFromCode(String code) {
    return switch (code) {
      '1d' => const RewardOutcome(
        label: 'Dégat Bonus 1',
        healthDelta: 0,
        cpDelta: 0,
        token: 'Dégat Bonus',
      ),
      '2d' => const RewardOutcome(
        label: 'Dégat Bonus 2',
        healthDelta: 0,
        cpDelta: 0,
        token: 'Dégat Bonus',
      ),
      '3d' => const RewardOutcome(
        label: 'Dégat Bonus 3',
        healthDelta: 0,
        cpDelta: 0,
        token: 'Dégat Bonus',
      ),
      '4d' => const RewardOutcome(
        label: 'Dégat Bonus 4',
        healthDelta: 0,
        cpDelta: 0,
        token: 'Dégat Bonus',
      ),
      '1cp' => const RewardOutcome(label: '+1 CP', healthDelta: 0, cpDelta: 1),
      '2cp' => const RewardOutcome(label: '+2 CP', healthDelta: 0, cpDelta: 2),
      '3cp' => const RewardOutcome(label: '+3 CP', healthDelta: 0, cpDelta: 3),
      '1vol' => const RewardOutcome(
        label: 'Vol',
        healthDelta: 0,
        cpDelta: 0,
        token: 'Vol',
      ),
      '1p' => const RewardOutcome(
        label: 'Pioche 1 carte',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '2p' => const RewardOutcome(
        label: 'Pioche 2 cartes',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '3p' => const RewardOutcome(
        label: 'Pioche 3 cartes',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '2hp' => const RewardOutcome(label: '+2 HP', healthDelta: 2, cpDelta: 0),
      '3hp' => const RewardOutcome(label: '+3 HP', healthDelta: 3, cpDelta: 0),
      '4hp' => const RewardOutcome(label: '+4 HP', healthDelta: 4, cpDelta: 0),
      '5hp' => const RewardOutcome(label: '+5 HP', healthDelta: 5, cpDelta: 0),
      '1v' => const RewardOutcome(
        label: 'Carte verte',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '1b' => const RewardOutcome(
        label: 'Carte bleue',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '1vi' => const RewardOutcome(
        label: 'Carte violette',
        healthDelta: 0,
        cpDelta: 0,
      ),
      '1o' => const RewardOutcome(
        label: 'Carte orange',
        healthDelta: 0,
        cpDelta: 0,
      ),
      _ => RewardOutcome(label: code, healthDelta: 0, cpDelta: 0),
    };
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
