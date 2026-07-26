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
    required this.pc,
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
  final int pc;
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
  const SymbolGoal({this.white = 0, this.yellow = 0, this.red = 0});

  final int white;
  final int yellow;
  final int red;
}

class MinionAttackPlan {
  const MinionAttackPlan.symbols(this.goals)
    : style = MinionAttackStyle.symbols;

  const MinionAttackPlan.suite()
    : style = MinionAttackStyle.suite,
      goals = const [];

  const MinionAttackPlan.none()
    : style = MinionAttackStyle.none,
      goals = const [];

  final MinionAttackStyle style;
  final List<SymbolGoal> goals;
}
