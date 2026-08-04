part of '../main.dart';

List<EnemyNode> _generateEnemies(SurvivalConfig config) {
  final ranks = _ranksForMode(config);
  final random = Random();
  final profilePools = {
    for (final rank in EnemyRank.values)
      rank: [..._profilesForRank(rank)]..shuffle(random),
  };

  EnemyProfile? nextProfile(EnemyRank rank) {
    final pool = profilePools[rank];
    if (pool == null || pool.isEmpty) {
      return null;
    }
    return pool.removeLast();
  }

  final nodes = <EnemyNode>[
    _enemy(0, 'Start minion', ranks.first, null, 0, nextProfile(ranks.first)),
  ];

  var id = 1;
  var rankIndex = 1;
  for (final branch in BranchSide.values) {
    final remaining = ranks.length - rankIndex;
    final otherBranchSlots = branch == BranchSide.left
        ? (_branchSlotsFor(config.mode) == 7 ? 7 : 6)
        : 0;
    final branchSlots = branch == BranchSide.left
        ? remaining - otherBranchSlots
        : remaining;
    for (var step = 1; step <= branchSlots; step++) {
      final rank = ranks[rankIndex++];
      nodes.add(
        _enemy(
          id++,
          '${branch.label} $step',
          rank,
          branch,
          step,
          nextProfile(rank),
        ),
      );
    }
  }
  return nodes;
}

int _branchSlotsFor(SurvivalMode mode) {
  return switch (mode) {
    SurvivalMode.hardFixed || SurvivalMode.hardRandom => 7,
    _ => 6,
  };
}

List<EnemyRank> _ranksForMode(SurvivalConfig config) {
  return switch (config.mode) {
    SurvivalMode.mediumFixed => _mediumRanks(),
    SurvivalMode.hardFixed => _hardRanks(),
    SurvivalMode.mediumRandom => _randomRanks(config.targetScore, hard: false),
    SurvivalMode.hardRandom => _randomRanks(config.targetScore, hard: true),
    SurvivalMode.free => _freeModeRanks(config.freeCounts),
    SurvivalMode.naraxus => [EnemyRank.naraxus],
  };
}

SurvivalMode _randomModeFor(SurvivalMode mode) {
  return switch (mode) {
    SurvivalMode.mediumFixed ||
    SurvivalMode.mediumRandom => SurvivalMode.mediumRandom,
    SurvivalMode.hardFixed ||
    SurvivalMode.hardRandom => SurvivalMode.hardRandom,
    SurvivalMode.free => SurvivalMode.free,
    SurvivalMode.naraxus => SurvivalMode.naraxus,
  };
}

Map<EnemyRank, int> _rankCountsForMode(SurvivalMode mode) {
  final ranks = _ranksForMode(
    SurvivalConfig(mode: mode, targetScore: mode.defaultTarget),
  );
  return {
    for (final rank in [
      EnemyRank.green,
      EnemyRank.blue,
      EnemyRank.violet,
      EnemyRank.orange,
      EnemyRank.viseer,
    ])
      rank: ranks.where((value) => value == rank).length,
  };
}

List<EnemyRank> _mediumRanks() {
  return const [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.green,
    EnemyRank.violet,
    EnemyRank.green,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.violet,
    EnemyRank.blue,
    EnemyRank.green,
    EnemyRank.green,
    EnemyRank.violet,
    EnemyRank.orange,
  ];
}

List<EnemyRank> _hardRanks() {
  return const [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.green,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.viseer,
    EnemyRank.blue,
    EnemyRank.orange,
    EnemyRank.violet,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.viseer,
  ];
}

List<EnemyRank> _randomRanks(int targetScore, {required bool hard}) {
  final random = Random();
  final mandatory = hard
      ? <EnemyRank>[
          EnemyRank.green,
          EnemyRank.orange,
          EnemyRank.viseer,
          EnemyRank.orange,
          EnemyRank.viseer,
        ]
      : <EnemyRank>[EnemyRank.green, EnemyRank.orange, EnemyRank.orange];
  final poolCount = hard ? 10 : 10;
  final target =
      targetScore - mandatory.fold(0, (sum, rank) => sum + rank.points);
  var best = <EnemyRank>[];
  var bestDelta = 999;
  for (var attempt = 0; attempt < 1200; attempt++) {
    final pool = List.generate(poolCount, (_) {
      final choices = hard
          ? [
              EnemyRank.green,
              EnemyRank.blue,
              EnemyRank.violet,
              EnemyRank.orange,
            ]
          : [EnemyRank.green, EnemyRank.blue, EnemyRank.violet];
      return choices[random.nextInt(choices.length)];
    });
    final score = pool.fold(0, (sum, rank) => sum + rank.points);
    final delta = (score - target).abs().toInt();
    if (delta < bestDelta) {
      best = pool;
      bestDelta = delta;
    }
    if (delta == 0) {
      break;
    }
  }
  best.shuffle(random);
  if (hard) {
    return [
      EnemyRank.green,
      ...best.take(5),
      EnemyRank.orange,
      EnemyRank.viseer,
      ...best.skip(5).take(5),
      EnemyRank.orange,
      EnemyRank.viseer,
    ];
  }
  return [
    EnemyRank.green,
    ...best.take(5),
    EnemyRank.orange,
    ...best.skip(5).take(5),
    EnemyRank.orange,
  ];
}

List<EnemyRank> _freeModeRanks(Map<EnemyRank, int> counts) {
  final pool = <EnemyRank>[];
  final remainingCounts = Map<EnemyRank, int>.from(counts);
  remainingCounts[EnemyRank.green] = max(
    0,
    (remainingCounts[EnemyRank.green] ?? 0) - 1,
  );
  remainingCounts[EnemyRank.orange] = max(
    0,
    (remainingCounts[EnemyRank.orange] ?? 0) - 2,
  );
  for (final rank in [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
  ]) {
    pool.addAll(List.filled(remainingCounts[rank] ?? 0, rank));
  }
  pool.shuffle(Random());
  final left = pool.take(5).toList();
  final right = pool.skip(5).take(5).toList();
  return [
    EnemyRank.green,
    ...left,
    EnemyRank.orange,
    ...right,
    EnemyRank.orange,
  ];
}

String _modeLabel(SurvivalMode mode) {
  return _survivalModeTitle(mode);
}

int _scoreForDefeated(SurvivalMode mode, int defeatedCount) {
  if (defeatedCount <= 0) {
    return 0;
  }
  final ranks = _ranksForMode(
    SurvivalConfig(mode: mode, targetScore: mode.defaultTarget),
  );
  final count = defeatedCount.clamp(0, ranks.length);
  if ((count == 5 || count == 11) && ranks.length >= count + 1) {
    final fixedBeforeChoice = count == 5 ? ranks.take(4) : ranks.take(10);
    final choiceA = ranks[count - 1].points;
    final choiceB = ranks[count].points;
    return fixedBeforeChoice.fold<int>(0, (sum, rank) => sum + rank.points) +
        min(choiceA, choiceB);
  }
  return ranks
      .take(count)
      .fold<int>(0, (sum, rank) => sum + rank.points)
      .clamp(0, mode.defaultTarget);
}

EnemyNode _enemy(
  int id,
  String label,
  EnemyRank rank,
  BranchSide? branch,
  int step,
  EnemyProfile? profile,
) {
  final selectedProfile = profile ?? defaultProfileFor(rank);
  return EnemyNode(
    id: id,
    label: rank == EnemyRank.green ? selectedProfile.name : label,
    rank: rank,
    branch: branch,
    step: step,
    maxHealth: selectedProfile.maxHealth,
    cp: selectedProfile.cp,
    attacks: selectedProfile.attacks,
    defense: selectedProfile.defense,
    defenseDice: selectedProfile.defenseDice,
    attackPlan: selectedProfile.attackPlan,
    cardAsset: selectedProfile.cardAsset,
    profileKey: selectedProfile.key,
    initialTokens: selectedProfile.initialTokens,
    rewardChests: selectedProfile.rewardChests,
    rewardRank: selectedProfile.rewardRank,
    rewardRanks: selectedProfile.rewardRanks,
    passives: selectedProfile.passives,
    defenseDisplayRows: selectedProfile.defenseDisplayRows,
    passiveDisplayRows: selectedProfile.passiveDisplayRows,
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)} $hour:$minute';
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes <= 0) {
    return 'Time n/a';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '${duration.inMinutes} min';
  }
  return '${hours}h ${minutes.toString().padLeft(2, '0')}';
}
