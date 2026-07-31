import 'package:flutter/material.dart';

enum EnemyRank {
  green('Level 1', 1, Color(0xff34d36d), 'assets/map_green.jpg'),
  blue('Level 2', 2, Color(0xff3bb9ff), 'assets/map_blue.png'),
  violet('Level 3', 3, Color(0xff9b58ff), 'assets/map_violet.png'),
  viseer('Viseer', 4, Color(0xffff8a2b), 'assets/viser.webp'),
  orange('Level 4', 6, Color(0xffff8a2b), 'assets/map_orange.png'),
  naraxus('Naraxus', 0, Color(0xffd51f2a), 'assets/home_background_v4.png');

  const EnemyRank(this.label, this.points, this.color, this.asset);

  final String label;
  final int points;
  final Color color;
  final String asset;

  String get rewardChestKey {
    return switch (this) {
      EnemyRank.green => 'green',
      EnemyRank.blue => 'blue',
      EnemyRank.violet => 'violet',
      EnemyRank.orange => 'orange',
      EnemyRank.viseer => 'orange',
      EnemyRank.naraxus => 'orange',
    };
  }
}

class EnemyProfile {
  const EnemyProfile({
    required this.key,
    required this.name,
    required this.rank,
    required this.maxHealth,
    required this.cp,
    required this.cardAsset,
    required this.attacks,
    required this.defense,
    required this.defenseDice,
    required this.attackPlan,
    this.initialTokens = const [],
    this.rewardChests = 1,
    this.rewardRank,
    this.rewardRanks = const [],
  });

  final String key;
  final String name;
  final EnemyRank rank;
  final int maxHealth;
  final int cp;
  final String cardAsset;
  final List<String> attacks;
  final String defense;
  final int defenseDice;
  final MinionAttackPlan attackPlan;
  final List<String> initialTokens;
  final int rewardChests;
  final EnemyRank? rewardRank;
  final List<EnemyRank> rewardRanks;
}

enum MinionAttackStyle { symbols, suite, none }

class SymbolGoal {
  const SymbolGoal({this.white = 0, this.yellow = 0, this.red = 0, this.effect});

  final int white;
  final int yellow;
  final int red;

  /// Effects associated with this goal when it is met, as declared in the
  /// JSON `attackPlan.actions` array. May be null when the JSON only provides
  /// a goals list without per-action effects (legacy/simple profiles).
  final SymbolGoalEffect? effect;

  /// Equality based on the symbol thresholds only, so that two goals with the
  /// same white/yellow/red counts are considered the same target regardless of
  /// their attached effect (used when matching a goal against attackPlan.goals).
  @override
  bool operator ==(Object other) {
    return other is SymbolGoal &&
        other.white == white &&
        other.yellow == yellow &&
        other.red == red;
  }

  @override
  int get hashCode => Object.hash(white, yellow, red);
}

/// Per-goal attack effects parsed from the JSON `attackPlan.actions` entry.
///
/// The JSON is the source of truth for damage and flags; reading these values
/// directly avoids fragile text parsing of the localized `attacks` strings.
class SymbolGoalEffect {
  const SymbolGoalEffect({
    this.damage = 0,
    this.undefendable = false,
    this.stealHp = 0,
    this.stealCp = 0,
    this.heal = 0,
    this.heroTokens = const [],
    this.minionTokens = const [],
    this.label,
  });

  final int damage;
  final bool undefendable;
  final int stealHp;
  final int stealCp;
  final int heal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final String? label;
}

class MinionAttackPlan {
  const MinionAttackPlan.symbols(this.goals)
    : style = MinionAttackStyle.symbols,
      suiteEffects = const {};

  const MinionAttackPlan.suite({this.suiteEffects = const {}})
    : style = MinionAttackStyle.suite,
      goals = const [];

  const MinionAttackPlan.none()
    : style = MinionAttackStyle.none,
      goals = const [],
      suiteEffects = const {};

  final MinionAttackStyle style;
  final List<SymbolGoal> goals;

  /// Effects per suite length (3/4/5) for suite-style plans, parsed from the
  /// JSON `attackPlan.actions` array. Empty for symbols/none plans.
  final Map<int, SymbolGoalEffect> suiteEffects;
}
