import '../models/enemy_profile.dart';

const EnemyProfile fallbackGreenProfile = EnemyProfile(
  key: 'green-fallback',
  name: 'Level 1 Minion',
  rank: EnemyRank.green,
  maxHealth: 8,
  pc: 1,
  cardAsset: 'assets/map_green.jpg',
  attacks: ['Quick hit: 3 damage'],
  defense: 'Blocks 1 damage',
  defenseDice: 1,
  attackPlan: MinionAttackPlan.none(),
);

const EnemyProfile naraxusProfile = EnemyProfile(
  key: 'naraxus',
  name: 'Naxarus',
  rank: EnemyRank.naraxus,
  maxHealth: 65,
  pc: 0,
  cardAsset: 'assets/enemy_previews/naraxus_card.webp',
  attacks: [
    'Swoop: 1 = remove 1 random Naxarus token, heal 4 HP, deal 3 undefendable damage.',
    'Ember Spark: 2 = hero moves top 3 deck cards to discard, then takes 8 damage.',
    'Gashing Bite: 3 = roll 4 dice, deal damage equal to the 2 highest dice.',
    'Hoarding: 4 = hero loses 1 die next battle phase, then takes 9 damage.',
    'Thundering Roar: 5 = hero discards 1 card and takes 8 undefendable damage.',
    "Dragon's Might: 6 = deal 10 damage and roll 1 extra die; on 5-6 also Swoop.",
  ],
  defense: 'Defense roll 1 die: 1 prevents 1, 2-5 prevents 3, 6 prevents 5.',
  defenseDice: 1,
  attackPlan: MinionAttackPlan.none(),
);

EnemyProfile defaultProfileFor(EnemyRank rank) {
  return switch (rank) {
    EnemyRank.green => fallbackGreenProfile,
    EnemyRank.blue => const EnemyProfile(
      key: 'blue-generic',
      name: 'Level 2 Minion',
      rank: EnemyRank.blue,
      maxHealth: 11,
      pc: 2,
      cardAsset: 'assets/map_blue.png',
      attacks: ['Precise strike: 4 damage', 'Pressure: -1 CP'],
      defense: 'Blocks 2 damage',
      defenseDice: 2,
      attackPlan: MinionAttackPlan.none(),
    ),
    EnemyRank.violet => const EnemyProfile(
      key: 'violet-generic',
      name: 'Level 3 Minion',
      rank: EnemyRank.violet,
      maxHealth: 14,
      pc: 3,
      cardAsset: 'assets/map_violet.png',
      attacks: ['Mystic slash: 5 damage', 'Weaken: status token'],
      defense: 'Blocks 3 damage',
      defenseDice: 3,
      attackPlan: MinionAttackPlan.none(),
    ),
    EnemyRank.viseer => const EnemyProfile(
      key: 'viseer',
      name: 'Viseer',
      rank: EnemyRank.viseer,
      maxHealth: 20,
      pc: 0,
      cardAsset: 'assets/enemy_viseer.jpg',
      attacks: [
        'Special rules',
        'When the Boss is attacked, the attacker may choose to target Viseer instead.',
        'Viseer is immune to status effects, CP loss, and everything else besides damage.',
        'Passive: during the Boss upkeep phase, roll 1 die.',
      ],
      defense: 'Defense roll 4 dice: on red symbol, activate Passive Ability.',
      defenseDice: 4,
      attackPlan: MinionAttackPlan.none(),
    ),
    EnemyRank.orange => const EnemyProfile(
      key: 'orange-generic',
      name: 'Level 4 Minion',
      rank: EnemyRank.orange,
      maxHealth: 20,
      pc: 5,
      cardAsset: 'assets/map_orange.png',
      attacks: ['Boss rage: 8 damage', 'Counter: reinforced defense'],
      defense: 'Blocks 4 damage and counters',
      defenseDice: 4,
      attackPlan: MinionAttackPlan.none(),
    ),
    EnemyRank.naraxus => naraxusProfile,
  };
}

List<EnemyProfile> fallbackProfilesForRank(EnemyRank rank) {
  return [defaultProfileFor(rank)];
}
