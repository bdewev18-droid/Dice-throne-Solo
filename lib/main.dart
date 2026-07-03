import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'active_adventure_storage.dart';

const String appVersionLabel = 'Version 1.2.5';
const String _activeAdventureKey = 'active_adventure_v1';
const Color heroAccent = Color(0xffffe22d);
const int mediumTarget = 33;
const int hardTarget = 52;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const DiceThroneSurvieApp());
}

enum HeroSegment {
  season1('Season 1'),
  season2('Season 2'),
  marvel('Marvel'),
  xmen('X-Men'),
  outcast('Outcast'),
  other('Other');

  const HeroSegment(this.label);

  final String label;
}

enum HeroType {
  barbare(
    'Barbarian',
    'assets/barbarian_hero.jpg',
    Alignment.center,
    Color(0xffd94a24),
    [HeroSegment.season1],
  ),
  elfeLunaire(
    'Moon Elf',
    'assets/moon_elf_hero.png',
    Alignment.center,
    Color(0xff64b7e8),
    [HeroSegment.season1],
  ),
  tacticien(
    'Tactician',
    'assets/tactician_hero.png',
    Alignment.center,
    Color(0xffd92f2f),
    [HeroSegment.season2],
  ),
  monk('Monk', 'assets/monk_hero.png', Alignment.topCenter, Color(0xffd7a55a), [
    HeroSegment.season1,
  ]),
  paladin(
    'Paladin',
    'assets/paladin_hero.png',
    Alignment.topCenter,
    Color(0xfff4c95a),
    [HeroSegment.season1],
  ),
  pyromancer(
    'Pyromancer',
    'assets/pyromancer_hero.png',
    Alignment(0, -0.65),
    Color(0xffff6a21),
    [HeroSegment.season1],
    1.22,
  ),
  shadowThief(
    'Shadow Thief',
    'assets/shadow_thief_hero.png',
    Alignment.topCenter,
    Color(0xff8f4dff),
    [HeroSegment.season1],
  ),
  deadpool(
    'Deadpool',
    'assets/deadpool_hero.jpg',
    Alignment.center,
    Color(0xffc91922),
    [HeroSegment.marvel, HeroSegment.xmen],
  );

  const HeroType(
    this.label,
    this.asset,
    this.imageAlignment,
    this.color,
    this.segments, [
    this.imageScale = 1,
  ]);

  final String label;
  final String asset;
  final Alignment imageAlignment;
  final Color color;
  final List<HeroSegment> segments;
  final double imageScale;
}

enum EnemyRank {
  green('Level 1', 1, Color(0xff34d36d), 'assets/map_green.jpg'),
  blue('Level 2', 2, Color(0xff3bb9ff), 'assets/map_blue.png'),
  violet('Level 3', 3, Color(0xff9b58ff), 'assets/map_violet.png'),
  viseer('Viseer', 4, Color(0xff8a5a2c), 'assets/enemy_viseer.jpg'),
  orange('Level 4', 6, Color(0xffff8a2b), 'assets/map_orange.png');

  const EnemyRank(this.label, this.points, this.color, this.asset);

  final String label;
  final int points;
  final Color color;
  final String asset;
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

enum CombatPhase {
  hero('Hero turn'),
  minionUpkeep('Minion upkeep'),
  minionAttack('Minion attack');

  const CombatPhase(this.label);

  final String label;
}

enum StatusTokenKind { positive, negative, unique }

class StatusTokenRule {
  const StatusTokenRule({
    required this.label,
    required this.kind,
    required this.maxStack,
    required this.persistent,
    this.minionAllowed = true,
  });

  final String label;
  final StatusTokenKind kind;
  final int maxStack;
  final bool persistent;
  final bool minionAllowed;
}

const List<StatusTokenRule> statusTokenRules = [
  StatusTokenRule(
    label: 'Poison',
    kind: StatusTokenKind.negative,
    maxStack: 3,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Riposte',
    kind: StatusTokenKind.positive,
    maxStack: 1,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Première Frappe',
    kind: StatusTokenKind.unique,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Silence',
    kind: StatusTokenKind.unique,
    maxStack: 1,
    persistent: false,
    minionAllowed: false,
  ),
  StatusTokenRule(
    label: 'Ronces',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Hémorragie',
    kind: StatusTokenKind.negative,
    maxStack: 2,
    persistent: true,
  ),
];

const List<String> knownStatusTokens = [
  'Poison',
  'Riposte',
  'Première Frappe',
  'Silence',
  'Ronces',
  'Hémorragie',
];

StatusTokenRule _tokenRule(String label) {
  return statusTokenRules.firstWhere(
    (rule) => rule.label == label,
    orElse: () => StatusTokenRule(
      label: label,
      kind: StatusTokenKind.negative,
      maxStack: 99,
      persistent: true,
    ),
  );
}

const List<EnemyProfile> greenEnemyProfiles = [
  EnemyProfile(
    key: 'fee',
    name: 'Fée',
    rank: EnemyRank.green,
    maxHealth: 9,
    pc: 2,
    cardAsset: 'assets/enemy_green_fairy.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Agacement',
      'Micro suite: inflige 2 dégâts imparables.',
      'Petite suite: inflige 5 dégâts.',
      'Grande suite: vole 1 CP et inflige 6 dégâts.',
    ],
    defense: 'Jet défensif 4 dés: sur 2 symboles jaunes, prévient 3 dégâts.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'ronin-vagabond',
    name: 'Ronin Vagabond',
    rank: EnemyRank.green,
    maxHealth: 8,
    pc: 2,
    cardAsset: 'assets/enemy_green_ronin.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Coupe & Découpe',
      '3 symboles blancs: inflige 5 dégâts.',
      '4 symboles blancs: inflige 6 dégâts.',
      '5 symboles blancs: inflige 7 dégâts.',
      'Si vous obtenez 4 symboles identiques, gagne le token Riposte.',
    ],
    defense:
        'Jet défensif 1 dé: inflige la moitié de la valeur du dé en dégâts, arrondie au chiffre supérieur.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'enchanteur-gobelin',
    name: 'Enchanteur Gobelin',
    rank: EnemyRank.green,
    maxHealth: 10,
    pc: 1,
    cardAsset: 'assets/enemy_green_goblin_enchanter.png',
    attacks: [
      'Ensorcellule',
      'Objectif: 1 symbole blanc, 2 symboles jaunes, 1 symbole rouge.',
      'Inflige 4 dégâts imparables.',
      'Votre adversaire défausse 1 carte au hasard.',
    ],
    defense:
        'Jet défensif 3 dés: sur 1 ou plusieurs symboles jaunes, inflige 1 dégât. Sur 1 ou plusieurs symboles rouges, inflige Poison.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'archer-de-lombre',
    name: "Archer de l'Ombre",
    rank: EnemyRank.green,
    maxHealth: 10,
    pc: 3,
    cardAsset: 'assets/enemy_green_shadow_archer.png',
    attacks: [
      "Volée de l'Ombre",
      '2 symboles jaunes: inflige 5 dégâts.',
      '3 symboles jaunes: inflige 6 dégâts.',
      '4 symboles jaunes: inflige 7 dégâts.',
      '5 symboles jaunes: inflige 8 dégâts.',
      'Si vous obtenez 3 chiffres identiques, inflige Silence.',
    ],
    defense:
        'Jet défensif 3 dés: sur 1 ou plusieurs symboles jaunes, prévient 3 dégâts.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 2),
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'ombre-feline',
    name: 'Ombre Féline',
    rank: EnemyRank.green,
    maxHealth: 9,
    pc: 2,
    cardAsset: 'assets/enemy_green_feline_shadow.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Griffure',
      '3 symboles blancs: inflige 4 dégâts.',
      '4 symboles blancs: inflige 5 dégâts.',
      '5 symboles blancs: inflige 6 dégâts.',
      'Si vous obtenez 3 chiffres identiques, inflige Hémorragie.',
    ],
    defense: 'Jet défensif 1 dé: sur symbole blanc, inflige Hémorragie.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'epeiste-egare',
    name: 'Épéiste Égaré',
    rank: EnemyRank.green,
    maxHealth: 11,
    pc: 0,
    cardAsset: 'assets/enemy_green_lost_fencer.png',
    attacks: [
      'En Garde',
      '3 symboles blancs: inflige 5 dégâts.',
      '4 symboles blancs: inflige 6 dégâts.',
      '5 symboles blancs: inflige 7 dégâts.',
    ],
    defense:
        'Jet défensif 3 dés: inflige 1 dégât par symbole blanc + 1 dégât par symbole rouge. Prévient 1 dégât par symbole jaune.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'elfe-du-chaos',
    name: 'Elfe du Chaos',
    rank: EnemyRank.green,
    maxHealth: 10,
    pc: 1,
    cardAsset: 'assets/enemy_green_chaos_elf.png',
    attacks: [
      'Fil de Lame',
      'Micro suite: inflige 4 dégâts.',
      'Petite suite: inflige 7 dégâts.',
      'Grande suite: inflige Ronces et inflige 8 dégâts.',
    ],
    defense:
        'Jet défensif 4 dés: sur 2 symboles jaunes, prévient la moitié des dégâts, arrondie au chiffre supérieur.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'oni-delirant',
    name: 'Oni Délirant',
    rank: EnemyRank.green,
    maxHealth: 11,
    pc: 0,
    cardAsset: 'assets/enemy_green_raving_oni.png',
    attacks: [
      'Onisima',
      '4 symboles jaunes, puis lancez 1 dé.',
      'Sur symbole blanc: inflige 5 dégâts imparables.',
      'Sur symbole jaune: inflige 6 dégâts imparables.',
      'Sur symbole rouge: vole 4 points de Santé.',
    ],
    defense: 'Jet défensif 2 dés: vole 1 point de Santé par symbole jaune.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 4)]),
  ),
];

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

EnemyProfile? _profileByKey(String? key) {
  if (key == null) {
    return null;
  }
  for (final profile in [...greenEnemyProfiles, fallbackGreenProfile]) {
    if (profile.key == key) {
      return profile;
    }
  }
  return switch (key) {
    'blue-generic' => _defaultProfileFor(EnemyRank.blue),
    'violet-generic' => _defaultProfileFor(EnemyRank.violet),
    'viseer' => _defaultProfileFor(EnemyRank.viseer),
    'orange-generic' => _defaultProfileFor(EnemyRank.orange),
    _ => null,
  };
}

enum BranchSide {
  left('Left'),
  right('Right');

  const BranchSide(this.label);

  final String label;
}

enum HistorySort {
  average('Average score'),
  best('Best score'),
  date('Game date'),
  time('Time played');

  const HistorySort(this.label);

  final String label;
}

enum SurvivalMode {
  mediumFixed('Medium fixed route', mediumTarget, RunDifficulty.medium, false),
  mediumRandom('Medium random route', mediumTarget, RunDifficulty.medium, true),
  hardFixed('Hard fixed route', hardTarget, RunDifficulty.hard, false),
  hardRandom('Hard random route', hardTarget, RunDifficulty.hard, true),
  free('Free mode', mediumTarget, RunDifficulty.free, true);

  const SurvivalMode(
    this.label,
    this.defaultTarget,
    this.difficulty,
    this.random,
  );

  final String label;
  final int defaultTarget;
  final RunDifficulty difficulty;
  final bool random;
}

enum RunDifficulty {
  medium('Medium'),
  hard('Hard'),
  free('Free');

  const RunDifficulty(this.label);

  final String label;
}

enum RandomFilter {
  both('Both routes'),
  fixed('Fixed only'),
  random('Random only');

  const RandomFilter(this.label);

  final String label;
}

T? _enumByName<T extends Enum>(Iterable<T> values, String? name) {
  if (name == null) {
    return null;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

class ActiveAdventureStore {
  ActiveAdventureStore() : _storage = createActiveAdventureStorage();

  final ActiveAdventureStorage _storage;

  Future<String?> read() => _storage.read(_activeAdventureKey);

  Future<void> write(String value) =>
      _storage.write(_activeAdventureKey, value);

  Future<void> clear() => _storage.clear(_activeAdventureKey);
}

String _survivalModeTitle(SurvivalMode mode) {
  return mode.label;
}

class GameRecord {
  const GameRecord({
    required this.hero,
    required this.date,
    required this.score,
    this.mode = SurvivalMode.mediumFixed,
    this.healthRemaining,
    this.enemiesDefeated = 0,
    this.duration = Duration.zero,
  });

  final HeroType hero;
  final DateTime date;
  final int score;
  final SurvivalMode mode;
  final int? healthRemaining;
  final int enemiesDefeated;
  final Duration duration;
}

class SurvivalConfig {
  const SurvivalConfig({
    required this.mode,
    required this.targetScore,
    this.freeCounts = const {},
  });

  final SurvivalMode mode;
  final int targetScore;
  final Map<EnemyRank, int> freeCounts;

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'targetScore': targetScore,
    'freeCounts': freeCounts.map((rank, count) => MapEntry(rank.name, count)),
  };

  factory SurvivalConfig.fromJson(Map<String, dynamic> json) {
    final mode = _enumByName(SurvivalMode.values, json['mode'] as String?);
    final rawCounts = (json['freeCounts'] as Map?) ?? {};
    return SurvivalConfig(
      mode: mode ?? SurvivalMode.mediumFixed,
      targetScore: (json['targetScore'] as num?)?.toInt() ?? mediumTarget,
      freeCounts: rawCounts.map(
        (key, value) => MapEntry(
          _enumByName(EnemyRank.values, key.toString()) ?? EnemyRank.green,
          (value as num).toInt(),
        ),
      ),
    );
  }

  String get label => switch (mode) {
    SurvivalMode.mediumFixed || SurvivalMode.mediumRandom => 'Medium mode',
    SurvivalMode.hardFixed || SurvivalMode.hardRandom => 'Hard mode',
    SurvivalMode.free => 'Free mode',
  };
}

class EnemyNode {
  EnemyNode({
    required this.id,
    required this.label,
    required this.rank,
    required this.maxHealth,
    required this.pc,
    required this.attacks,
    required this.defense,
    required this.defenseDice,
    required this.attackPlan,
    required this.cardAsset,
    this.profileKey,
    List<String> initialTokens = const [],
    this.branch,
    this.step = 0,
  }) : health = maxHealth,
       combatPoints = pc {
    alterations.addAll(initialTokens);
  }

  final int id;
  String label;
  final EnemyRank rank;
  int maxHealth;
  int pc;
  List<String> attacks;
  String defense;
  int defenseDice;
  MinionAttackPlan attackPlan;
  String cardAsset;
  String? profileKey;
  final BranchSide? branch;
  final int step;
  int health;
  int combatPoints;
  final List<String> alterations = [];
  bool defeated = false;
  bool current = false;

  Map<String, dynamic> toJson() => {
    'id': id,
    'health': health,
    'combatPoints': combatPoints,
    'alterations': alterations,
    'defeated': defeated,
    'profileKey': profileKey,
  };

  void applyJson(Map<String, dynamic> json) {
    final restoredProfile = _profileByKey(json['profileKey']?.toString());
    if (restoredProfile != null && restoredProfile.rank == rank) {
      label = restoredProfile.name;
      maxHealth = restoredProfile.maxHealth;
      pc = restoredProfile.pc;
      attacks = restoredProfile.attacks;
      defense = restoredProfile.defense;
      defenseDice = restoredProfile.defenseDice;
      attackPlan = restoredProfile.attackPlan;
      cardAsset = restoredProfile.cardAsset;
      profileKey = restoredProfile.key;
    }
    health = ((json['health'] as num?)?.toInt() ?? health).clamp(0, maxHealth);
    combatPoints = ((json['combatPoints'] as num?)?.toInt() ?? combatPoints)
        .clamp(0, 99);
    defeated = json['defeated'] as bool? ?? defeated;
    alterations
      ..clear()
      ..addAll((json['alterations'] as List? ?? const []).cast<String>());
  }
}

class AdventureState {
  AdventureState({required this.hero, required this.config})
    : targetScore = config.targetScore,
      startedAt = DateTime.now(),
      enemies = _generateEnemies(config) {
    _refreshAvailability();
    log('Run created: ${config.label}, target $targetScore points.');
  }

  AdventureState._restored({
    required this.hero,
    required this.config,
    required this.startedAt,
  }) : targetScore = config.targetScore,
       enemies = _generateEnemies(config);

  final HeroType hero;
  final SurvivalConfig config;
  final int targetScore;
  final List<EnemyNode> enemies;
  final List<String> logs = [];
  final List<String> alterations = [];
  final List<String> bonuses = [];
  final DateTime startedAt;
  int health = 30;
  int combatPoints = 2;
  int score = 0;
  BranchSide? lockedBranch;
  bool finished = false;
  bool victory = false;
  bool recorded = false;

  void log(String message) {
    logs.insert(0, '${_formatDateTime(DateTime.now())} - $message');
  }

  List<EnemyNode> get defeatedEnemies =>
      enemies.where((enemy) => enemy.defeated).toList();

  EnemyNode enemyById(int id) => enemies.firstWhere((enemy) => enemy.id == id);

  Duration get elapsed => DateTime.now().difference(startedAt);

  Map<String, dynamic> toJson() => {
    'hero': hero.name,
    'config': config.toJson(),
    'startedAt': startedAt.toIso8601String(),
    'health': health,
    'combatPoints': combatPoints,
    'score': score,
    'lockedBranch': lockedBranch?.name,
    'finished': finished,
    'victory': victory,
    'recorded': recorded,
    'logs': logs,
    'alterations': alterations,
    'bonuses': bonuses,
    'enemies': enemies.map((enemy) => enemy.toJson()).toList(),
  };

  factory AdventureState.fromJson(Map<String, dynamic> json) {
    final hero = _enumByName(HeroType.values, json['hero'] as String?);
    final configJson = json['config'] as Map?;
    final state = AdventureState._restored(
      hero: hero ?? HeroType.barbare,
      config: configJson == null
          ? const SurvivalConfig(
              mode: SurvivalMode.mediumFixed,
              targetScore: mediumTarget,
            )
          : SurvivalConfig.fromJson(Map<String, dynamic>.from(configJson)),
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
    );

    state
      ..health = ((json['health'] as num?)?.toInt() ?? 30).clamp(0, 99)
      ..combatPoints = ((json['combatPoints'] as num?)?.toInt() ?? 2).clamp(
        0,
        99,
      )
      ..score = (json['score'] as num?)?.toInt() ?? 0
      ..lockedBranch = _enumByName(
        BranchSide.values,
        json['lockedBranch'] as String?,
      )
      ..finished = json['finished'] as bool? ?? false
      ..victory = json['victory'] as bool? ?? false
      ..recorded = json['recorded'] as bool? ?? false;

    state.logs
      ..clear()
      ..addAll((json['logs'] as List? ?? const []).cast<String>());
    state.alterations
      ..clear()
      ..addAll((json['alterations'] as List? ?? const []).cast<String>());
    state.bonuses
      ..clear()
      ..addAll((json['bonuses'] as List? ?? const []).cast<String>());

    final enemySnapshots = {
      for (final raw in (json['enemies'] as List? ?? const []))
        if (raw is Map && raw['id'] != null)
          (raw['id'] as num).toInt(): Map<String, dynamic>.from(raw),
    };
    for (final enemy in state.enemies) {
      final snapshot = enemySnapshots[enemy.id];
      if (snapshot != null) {
        enemy.applyJson(snapshot);
      }
    }
    state._refreshAvailability();
    return state;
  }

  void setHeroHealth(int value) {
    health = value.clamp(0, 99);
    log('Hero HP set to $health.');
    if (health == 0) {
      _endAdventure(false);
    }
  }

  void setHeroPc(int value) {
    combatPoints = value.clamp(0, 99);
    log('Hero CP set to $combatPoints.');
  }

  void addAlteration(String value) {
    alterations.add(value);
    log('Hero status added: $value.');
  }

  void setAlterations(List<String> values) {
    alterations
      ..clear()
      ..addAll(values);
    log('Hero status tokens updated.');
  }

  void completeCombat(EnemyNode enemy) {
    if (!enemy.defeated && enemy.health <= 0) {
      enemy.defeated = true;
      score += enemy.rank.points;
      log('${enemy.label} defeated: +${enemy.rank.points} points.');
    }

    if (health <= 0) {
      _endAdventure(false);
    } else if (enemies.every((enemy) => enemy.defeated)) {
      _endAdventure(true);
    }
    _refreshAvailability();
  }

  void applyReward(int d20) {
    if (d20 <= 10) {
      health = (health + 1).clamp(0, 99);
      bonuses.add('+1 HP');
      log('Reward confirmed: D20 $d20, +1 HP.');
    } else {
      combatPoints = (combatPoints + 1).clamp(0, 99);
      bonuses.add('+1 CP');
      log('Reward confirmed: D20 $d20, +1 CP.');
    }
  }

  void _endAdventure(bool won) {
    if (finished) {
      return;
    }
    finished = true;
    victory = won;
    log(
      won
          ? 'Aventure terminee: victoire.'
          : 'Aventure terminee: survie arretee.',
    );
  }

  void _refreshAvailability() {
    for (final enemy in enemies) {
      enemy.current = false;
    }
    if (finished) {
      return;
    }

    final start = enemyById(0);
    if (!start.defeated) {
      start.current = true;
      return;
    }

    if (lockedBranch != null && _branchComplete(lockedBranch!)) {
      lockedBranch = null;
    }

    if (lockedBranch == null) {
      final leftComplete = _branchComplete(BranchSide.left);
      final rightComplete = _branchComplete(BranchSide.right);
      if (!leftComplete && rightComplete) {
        lockedBranch = BranchSide.left;
      } else if (!rightComplete && leftComplete) {
        lockedBranch = BranchSide.right;
      }
    }

    if (lockedBranch == null) {
      _firstAvailableInBranch(BranchSide.left)?.current = true;
      _firstAvailableInBranch(BranchSide.right)?.current = true;
      return;
    }

    for (final enemy in _availableInBranch(lockedBranch!)) {
      enemy.current = true;
    }
  }

  void lockBranch(BranchSide branch) {
    lockedBranch ??= branch;
    _refreshAvailability();
    log('${branch.label} path engaged.');
  }

  bool _branchComplete(BranchSide branch) {
    return enemies
        .where((enemy) => enemy.branch == branch)
        .every((enemy) => enemy.defeated);
  }

  EnemyNode? _firstAvailableInBranch(BranchSide branch) {
    final available = _availableInBranch(branch);
    return available.isEmpty ? null : available.first;
  }

  List<EnemyNode> _availableInBranch(BranchSide branch) {
    final branchEnemies =
        enemies.where((enemy) => enemy.branch == branch).toList()
          ..sort((a, b) => a.step.compareTo(b.step));

    final sequentialLimit = branchEnemies.length > 6 ? 5 : 3;
    for (var step = 1; step <= sequentialLimit; step++) {
      final enemy = branchEnemies.firstWhere((enemy) => enemy.step == step);
      if (!enemy.defeated) {
        return [enemy];
      }
    }

    final unlockedSteps = branchEnemies.length > 6 ? [6, 7] : [4, 5];
    final unlocked = branchEnemies
        .where((enemy) => unlockedSteps.contains(enemy.step) && !enemy.defeated)
        .toList();
    if (unlocked.isNotEmpty) {
      return unlocked;
    }

    if (branchEnemies.length <= 6) {
      final boss = branchEnemies.firstWhere((enemy) => enemy.step == 6);
      if (!boss.defeated) {
        return [boss];
      }
    }
    return [];
  }
}

class DiceThroneSurvieApp extends StatefulWidget {
  const DiceThroneSurvieApp({super.key});

  @override
  State<DiceThroneSurvieApp> createState() => _DiceThroneSurvieAppState();
}

class _DiceThroneSurvieAppState extends State<DiceThroneSurvieApp> {
  final List<GameRecord> _history = [];
  final _store = ActiveAdventureStore();
  AdventureState? _activeAdventure;
  bool _storageReady = false;

  @override
  void initState() {
    super.initState();
    _loadActiveAdventure();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      title: 'D.T Solo Quest',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd6512a),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff121212),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) {
          return content;
        }
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRect(child: content),
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) {
          if (!_storageReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomePage(
            activeAdventure: _activeAdventure,
            onHistory: () => _openHistory(context),
            onSurvival: () => _openHeroChoice(context),
            onResume: () {
              final adventure = _activeAdventure;
              if (adventure != null) {
                _replaceWithMap(
                  context,
                  adventure,
                  adventure.hero,
                  adventure.config,
                );
              }
            },
            onStopCampaign: _stopActiveCampaign,
            onNaraxus: () => _showNaraxusComingSoon(context),
          );
        },
      ),
    );
  }

  Future<void> _loadActiveAdventure() async {
    final raw = await _store.read();
    AdventureState? restored;
    if (raw != null) {
      try {
        restored = AdventureState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        if (restored.finished) {
          restored = null;
          await _store.clear();
        }
      } catch (_) {
        await _store.clear();
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAdventure = restored;
      _storageReady = true;
    });
  }

  Future<void> _saveActiveAdventure() async {
    final adventure = _activeAdventure;
    if (adventure == null || adventure.finished) {
      await _store.clear();
      return;
    }
    await _store.write(jsonEncode(adventure.toJson()));
  }

  Future<void> _clearActiveAdventure() async {
    _activeAdventure = null;
    await _store.clear();
    if (mounted) {
      setState(() {});
    }
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          records: _history,
          onAddRecord: (record) => setState(() => _history.insert(0, record)),
          onDeleteRecord: (record) => setState(() => _history.remove(record)),
        ),
      ),
    );
  }

  void _openHeroChoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          onNext: (hero) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SurvivalSetupPage(
                  hero: hero,
                  onStart: (config) {
                    final adventure = AdventureState(
                      hero: hero,
                      config: config,
                    );
                    _activeAdventure = adventure;
                    _saveActiveAdventure();
                    _replaceWithMap(context, adventure, hero, config);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _replaceWithMap(
    BuildContext context,
    AdventureState adventure,
    HeroType hero,
    SurvivalConfig config,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MapPage(
          adventure: adventure,
          onRecordScore: _recordAdventure,
          onChanged: () {
            _activeAdventure = adventure;
            _saveActiveAdventure();
          },
          onPauseExit: () {
            _activeAdventure = adventure;
            _saveActiveAdventure();
            appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
          onAbandon: () {
            _recordAdventure(adventure);
            _activeAdventure = null;
            _store.clear();
            setState(() {});
            appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
          onChangeHero: () => _openHeroChoice(context),
          onReplay: () {
            final next = AdventureState(hero: hero, config: config);
            _activeAdventure = next;
            _saveActiveAdventure();
            _replaceWithMap(context, next, hero, config);
          },
        ),
      ),
    );
  }

  void _recordAdventure(AdventureState adventure) {
    if (adventure.recorded) {
      return;
    }
    adventure.recorded = true;
    setState(() {
      _history.insert(
        0,
        GameRecord(
          hero: adventure.hero,
          date: DateTime.now(),
          score: adventure.score,
          mode: adventure.config.mode,
          healthRemaining: adventure.health,
          enemiesDefeated: adventure.defeatedEnemies.length,
          duration: adventure.elapsed,
        ),
      );
      if (identical(_activeAdventure, adventure)) {
        _activeAdventure = null;
        _store.clear();
      }
    });
  }

  Future<void> _stopActiveCampaign() async {
    final adventure = _activeAdventure;
    if (adventure != null) {
      _recordAdventure(adventure);
    }
    await _clearActiveAdventure();
  }

  void _showNaraxusComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Naraxus Battle'),
        content: const Text('This mode will arrive in a next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.activeAdventure,
    required this.onHistory,
    required this.onSurvival,
    required this.onResume,
    required this.onStopCampaign,
    required this.onNaraxus,
    super.key,
  });

  final AdventureState? activeAdventure;
  final VoidCallback onHistory;
  final VoidCallback onSurvival;
  final VoidCallback onResume;
  final VoidCallback onStopCampaign;
  final VoidCallback onNaraxus;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showActions = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: MediaQuery.paddingOf(context).top + 18,
            child: Image.asset(
              'assets/home_background_v4.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 18,
            child: const ColoredBox(color: Colors.black),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 650),
                      opacity: _showActions ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_showActions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ImageActionButton(
                              label: 'History',
                              icon: Icons.history,
                              onPressed: widget.onHistory,
                            ),
                            const SizedBox(height: 20),
                            if (widget.activeAdventure == null)
                              ImageActionButton(
                                label: 'Minion rush',
                                icon: Icons.shield,
                                onPressed: widget.onSurvival,
                              )
                            else
                              ActiveCampaignHomeCard(
                                adventure: widget.activeAdventure!,
                                onResume: widget.onResume,
                                onStop: widget.onStopCampaign,
                              ),
                            const SizedBox(height: 20),
                            ImageActionButton(
                              label: 'Naraxus Battle',
                              icon: Icons.local_fire_department,
                              onPressed: widget.onNaraxus,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const VersionPill(label: appVersionLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveCampaignHomeCard extends StatelessWidget {
  const ActiveCampaignHomeCard({
    required this.adventure,
    required this.onResume,
    required this.onStop,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/button_background.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume current run'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HeroAvatar(hero: adventure.hero, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${adventure.hero.label} - ${adventure.score}/${adventure.targetScore} pts\n'
                  '${adventure.config.label} - ${_formatDateTime(adventure.startedAt)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onStop,
            icon: const Icon(Icons.stop_circle),
            label: const Text('Stop campaign'),
          ),
        ],
      ),
    );
  }
}

class VersionPill extends StatelessWidget {
  const VersionPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class ImageActionButton extends StatelessWidget {
  const ImageActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('assets/button_background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Opacity(
            opacity: onPressed == null ? 0.48 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    required this.records,
    required this.onAddRecord,
    required this.onDeleteRecord,
    super.key,
  });

  final List<GameRecord> records;
  final ValueChanged<GameRecord> onAddRecord;
  final ValueChanged<GameRecord> onDeleteRecord;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistorySort _sort = HistorySort.average;
  RunDifficulty _difficulty = RunDifficulty.medium;
  RandomFilter _randomFilter = RandomFilter.both;
  bool _deleteMode = false;
  final Set<GameRecord> _selectedForDelete = {};
  final Set<HeroType> _expandedHeroes = {};

  @override
  Widget build(BuildContext context) {
    final records = [...widget.records.where(_matchesFilters)];
    final flatMode = _sort == HistorySort.date || _sort == HistorySort.time;
    if (flatMode) {
      records.sort(_sortRecords);
    }
    final grouped = _groupRecords(records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Add run',
            onPressed: _addManualRun,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: _deleteMode ? 'Cancel delete' : 'Delete runs',
            onPressed: () {
              setState(() {
                _deleteMode = !_deleteMode;
                _selectedForDelete.clear();
              });
            },
            icon: Icon(_deleteMode ? Icons.close : Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: RunDifficulty.values.length,
          initialIndex: RunDifficulty.values.indexOf(_difficulty),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  isScrollable: true,
                  onTap: (index) {
                    setState(() {
                      _difficulty = RunDifficulty.values[index];
                      _selectedForDelete.clear();
                    });
                  },
                  tabs: RunDifficulty.values
                      .map((difficulty) => Tab(text: difficulty.label))
                      .toList(),
                ),
                const SizedBox(height: 12),
                SegmentedButton<RandomFilter>(
                  segments: RandomFilter.values
                      .map(
                        (filter) => ButtonSegment(
                          value: filter,
                          label: Text(filter.label),
                        ),
                      )
                      .toList(),
                  selected: {_randomFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _randomFilter = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HistorySort>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                  ),
                  items: HistorySort.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child: Text(sort.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sort = value);
                    }
                  },
                ),
                if (_sort == HistorySort.best)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Best score uses points first, then remaining HP when available.',
                      style: TextStyle(color: Color(0xffbbcbbb), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Hero')),
                      Expanded(
                        child: Text('Runs', textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Enemies', textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Avg pts', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: records.isEmpty
                      ? const Center(child: Text('No game for this filter.'))
                      : flatMode
                      ? _buildFlatList(records)
                      : _buildGroupedList(grouped),
                ),
                if (_deleteMode)
                  FilledButton.icon(
                    onPressed: _selectedForDelete.isEmpty
                        ? null
                        : _confirmDeleteSelected,
                    icon: const Icon(Icons.delete),
                    label: Text('Delete ${_selectedForDelete.length} run(s)'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesFilters(GameRecord record) {
    if (record.mode.difficulty != _difficulty) {
      return false;
    }
    return switch (_randomFilter) {
      RandomFilter.both => true,
      RandomFilter.fixed => !record.mode.random,
      RandomFilter.random => record.mode.random,
    };
  }

  int _sortRecords(GameRecord a, GameRecord b) {
    return switch (_sort) {
      HistorySort.average => b.score.compareTo(a.score),
      HistorySort.best => _compareBestRecords(a, b),
      HistorySort.date => b.date.compareTo(a.date),
      HistorySort.time => b.duration.compareTo(a.duration),
    };
  }

  int _compareBestRecords(GameRecord a, GameRecord b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) {
      return score;
    }
    return (b.healthRemaining ?? -1).compareTo(a.healthRemaining ?? -1);
  }

  Map<HeroType, List<GameRecord>> _groupRecords(List<GameRecord> records) {
    final grouped = <HeroType, List<GameRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.hero, () => []).add(record);
    }
    for (final runs in grouped.values) {
      runs.sort(_sortRecords);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final avgA = _averageScore(a.value);
        final avgB = _averageScore(b.value);
        if (_sort == HistorySort.best) {
          return _compareBestRecords(a.value.first, b.value.first);
        }
        return avgB.compareTo(avgA);
      });
    return Map.fromEntries(entries);
  }

  Widget _buildGroupedList(Map<HeroType, List<GameRecord>> grouped) {
    return ListView(
      children: grouped.entries.map((entry) {
        final hero = entry.key;
        final runs = entry.value;
        final expanded = _expandedHeroes.contains(hero);
        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedHeroes.remove(hero);
                  } else {
                    _expandedHeroes.add(hero);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _deleteMode
                        ? Checkbox(
                            value: runs.every(_selectedForDelete.contains),
                            onChanged: (value) => _toggleRuns(runs, value),
                          )
                        : HeroAvatar(hero: hero, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        hero.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        runs.length.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        runs.map((run) => run.enemiesDefeated).join('/'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_averageScore(runs).toStringAsFixed(1)} pts',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              ...runs.map(
                (run) => Padding(
                  padding: const EdgeInsets.only(left: 52, bottom: 8),
                  child: _RunDetailRow(
                    record: run,
                    deleteMode: _deleteMode,
                    selected: _selectedForDelete.contains(run),
                    onSelected: (value) => _toggleRun(run, value),
                  ),
                ),
              ),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFlatList(List<GameRecord> records) {
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return _RunDetailRow(
          record: record,
          deleteMode: _deleteMode,
          selected: _selectedForDelete.contains(record),
          onSelected: (value) => _toggleRun(record, value),
          showHero: true,
        );
      },
    );
  }

  double _averageScore(List<GameRecord> runs) =>
      runs.fold<int>(0, (total, run) => total + run.score) / runs.length;

  void _toggleRun(GameRecord run, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedForDelete.add(run);
      } else {
        _selectedForDelete.remove(run);
      }
    });
  }

  void _toggleRuns(List<GameRecord> runs, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedForDelete.addAll(runs);
      } else {
        _selectedForDelete.removeAll(runs);
      }
    });
  }

  Future<void> _addManualRun() async {
    final record = await showDialog<GameRecord>(
      context: context,
      builder: (context) => const ManualRunDialog(),
    );
    if (record == null) {
      return;
    }
    widget.onAddRecord(record);
    setState(() {});
  }

  Future<void> _confirmDeleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected runs?'),
        content: Text('${_selectedForDelete.length} run(s) will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      for (final record in _selectedForDelete) {
        widget.onDeleteRecord(record);
      }
      setState(() {
        _selectedForDelete.clear();
        _deleteMode = false;
      });
    }
  }
}

class _RunDetailRow extends StatelessWidget {
  const _RunDetailRow({
    required this.record,
    required this.deleteMode,
    required this.selected,
    required this.onSelected,
    this.showHero = false,
  });

  final GameRecord record;
  final bool deleteMode;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (deleteMode)
          Checkbox(value: selected, onChanged: onSelected)
        else if (showHero)
          HeroAvatar(hero: record.hero, size: 34),
        if (showHero || deleteMode) const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(showHero ? record.hero.label : _formatDate(record.date)),
        ),
        Expanded(
          child: Text(
            record.enemiesDefeated.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text('${record.score} pts', textAlign: TextAlign.center),
        ),
        Expanded(
          child: Text(
            record.healthRemaining == null
                ? 'HP n/a'
                : '${record.healthRemaining} HP',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            _formatDuration(record.duration),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class ManualRunDialog extends StatefulWidget {
  const ManualRunDialog({super.key});

  @override
  State<ManualRunDialog> createState() => _ManualRunDialogState();
}

class _ManualRunDialogState extends State<ManualRunDialog> {
  HeroType _hero = HeroType.barbare;
  SurvivalMode _mode = SurvivalMode.mediumFixed;
  late final TextEditingController _scoreController = TextEditingController(
    text: _suggestedScore.toString(),
  );
  final TextEditingController _enemiesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _healthController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  int get _enemyCount => int.tryParse(_enemiesController.text.trim()) ?? 0;

  int get _suggestedScore => _scoreForDefeated(_mode, _enemyCount);

  bool get _ambiguousScore => _enemyCount == 5 || _enemyCount == 11;

  int get _scoreCap => _mode.defaultTarget;

  bool get _hasScoreCap => _mode != SurvivalMode.free;

  void _refreshSuggestedScore() {
    final suggested = _suggestedScore.clamp(0, _scoreCap);
    _scoreController.text = suggested.toString();
    _scoreController.selection = TextSelection.fromPosition(
      TextPosition(offset: _scoreController.text.length),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _enemiesController.dispose();
    _healthController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a run'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<HeroType>(
              initialValue: _hero,
              decoration: const InputDecoration(labelText: 'Hero'),
              items: HeroType.values
                  .map(
                    (hero) =>
                        DropdownMenuItem(value: hero, child: Text(hero.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _hero = value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<SurvivalMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Scenario'),
              items: SurvivalMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_modeLabel(mode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _mode = value;
                  _refreshSuggestedScore();
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _enemiesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enemies defeated',
                helperText: 'Used to suggest a score for fixed routes',
              ),
              onChanged: (_) => setState(_refreshSuggestedScore),
            ),
            if (_ambiguousScore)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'For 5 or 11 enemies, the score assumes the weakest of the two side monsters. You can still edit the score.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Score',
                suffixText: 'pts',
              ),
            ),
            if (_hasScoreCap)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Maximum for this mode: $_scoreCap pts',
                  style: const TextStyle(
                    color: Color(0xffbbcbbb),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _healthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Remaining HP',
                hintText: 'Not recorded',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time played',
                helperText: 'Minutes, optional',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            var score = int.tryParse(_scoreController.text.trim());
            if (score == null || score < 0) {
              return;
            }
            if (_hasScoreCap && score > _scoreCap) {
              score = _scoreCap;
            }
            final health = int.tryParse(_healthController.text.trim());
            final minutes = int.tryParse(_durationController.text.trim()) ?? 0;
            Navigator.of(context).pop(
              GameRecord(
                hero: _hero,
                date: DateTime.now(),
                score: score,
                mode: _mode,
                healthRemaining: health,
                enemiesDefeated: _enemyCount,
                duration: Duration(minutes: minutes),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class HeroChoicePage extends StatefulWidget {
  const HeroChoicePage({required this.onNext, super.key});

  final ValueChanged<HeroType> onNext;

  @override
  State<HeroChoicePage> createState() => _HeroChoicePageState();
}

class _HeroChoicePageState extends State<HeroChoicePage> {
  HeroType _selectedHero = HeroType.barbare;
  final Set<HeroSegment> _selectedSegments = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _holdTimer;
  HeroType? _holdingHero;
  double _holdProgress = 0;
  static const Duration _holdToValidateDuration = Duration(milliseconds: 1500);

  @override
  void dispose() {
    _holdTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final heroes = HeroType.values
        .where((hero) => hero.label.toLowerCase().contains(query))
        .where(
          (hero) =>
              _selectedSegments.isEmpty ||
              hero.segments.any(_selectedSegments.contains),
        )
        .toList();
    if (!heroes.contains(_selectedHero) && heroes.isNotEmpty) {
      _selectedHero = heroes.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your hero')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                labelText: 'Search hero',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            HeroSegmentFilters(
              selectedSegments: _selectedSegments,
              onChanged: (segment, selected) {
                setState(() {
                  if (segment == null) {
                    _selectedSegments.clear();
                  } else if (selected) {
                    _selectedSegments
                      ..clear()
                      ..add(segment);
                  } else {
                    _selectedSegments.remove(segment);
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            if (heroes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No hero found',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: heroes.length,
                itemBuilder: (context, index) {
                  final hero = heroes[index];
                  return HeroCard(
                    hero: hero,
                    selected: _selectedHero == hero,
                    holdProgress: _holdingHero == hero ? _holdProgress : 0,
                    onTap: () => setState(() => _selectedHero = hero),
                    onHoldStart: () => _startHeroHold(hero),
                    onHoldEnd: _cancelHeroHold,
                  );
                },
              ),
            const SizedBox(height: 18),
            ImageActionButton(
              label: 'Next',
              icon: Icons.arrow_forward,
              onPressed: heroes.isEmpty
                  ? null
                  : () => widget.onNext(_selectedHero),
            ),
          ],
        ),
      ),
    );
  }

  void _startHeroHold(HeroType hero) {
    _holdTimer?.cancel();
    setState(() {
      _selectedHero = hero;
      _holdingHero = hero;
      _holdProgress = 0;
    });

    final startedAt = DateTime.now();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      final elapsed = DateTime.now().difference(startedAt);
      final progress =
          elapsed.inMilliseconds / _holdToValidateDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        if (!mounted || _holdingHero != hero) {
          return;
        }
        setState(() {
          _holdProgress = 1;
          _holdingHero = null;
        });
        widget.onNext(hero);
        return;
      }
      if (mounted) {
        setState(() => _holdProgress = progress.clamp(0, 1));
      }
    });
  }

  void _cancelHeroHold() {
    if (_holdProgress >= 1) {
      return;
    }
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _holdingHero = null;
        _holdProgress = 0;
      });
    }
  }
}

class HeroSegmentFilters extends StatelessWidget {
  const HeroSegmentFilters({
    required this.selectedSegments,
    required this.onChanged,
    super.key,
  });

  final Set<HeroSegment> selectedSegments;
  final void Function(HeroSegment? segment, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selectedSegments.isEmpty,
          onSelected: (_) => onChanged(null, true),
        ),
        ...HeroSegment.values.map(
          (segment) => FilterChip(
            label: Text(segment.label),
            selected: selectedSegments.contains(segment),
            onSelected: (selected) => onChanged(segment, selected),
          ),
        ),
      ],
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.hero,
    required this.selected,
    required this.holdProgress,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
    super.key,
  });

  final HeroType hero;
  final bool selected;
  final double holdProgress;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? hero.color : Colors.white24,
            width: selected ? 4 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: hero.imageScale,
                child: Image.asset(
                  hero.asset,
                  fit: BoxFit.cover,
                  alignment: hero.imageAlignment,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              if (holdProgress > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 3,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: holdProgress,
                        backgroundColor: Colors.black54,
                        color: hero.color,
                      ),
                    ),
                  ),
                ),
              if (holdProgress > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: hero.color),
                    ),
                    child: const Text(
                      'Hold to confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    hero.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroAvatar extends StatelessWidget {
  const HeroAvatar({required this.hero, this.size = 42, super.key});

  final HeroType hero;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hero.color,
        border: Border.all(color: hero.color.withValues(alpha: 0.9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Transform.scale(
        scale: hero.imageScale * 1.35,
        child: Image.asset(
          hero.asset,
          fit: BoxFit.cover,
          alignment: hero.imageAlignment,
        ),
      ),
    );
  }
}

class SurvivalSetupPage extends StatefulWidget {
  const SurvivalSetupPage({
    required this.hero,
    required this.onStart,
    super.key,
  });

  final HeroType hero;
  final ValueChanged<SurvivalConfig> onStart;

  @override
  State<SurvivalSetupPage> createState() => _SurvivalSetupPageState();
}

class _SurvivalSetupPageState extends State<SurvivalSetupPage> {
  SurvivalMode _mode = SurvivalMode.mediumFixed;
  bool _randomRoute = false;
  bool _expertFreeMode = false;
  final Map<EnemyRank, int> _freeCounts = {
    EnemyRank.green: 1,
    EnemyRank.blue: 0,
    EnemyRank.violet: 0,
    EnemyRank.orange: 2,
  };

  int get _freeTotal =>
      _freeCounts.values.fold(0, (total, value) => total + value);

  int get _freeScore => _freeCounts.entries.fold(
    0,
    (total, entry) => total + entry.key.points * entry.value,
  );

  bool get _freeValid =>
      _freeTotal == 13 &&
      (_freeCounts[EnemyRank.green] ?? 0) >= 1 &&
      (_freeCounts[EnemyRank.orange] ?? 0) >= 2 &&
      _freeScore >= 20;

  Map<EnemyRank, int> get _displayCounts =>
      _mode == SurvivalMode.free ? _freeCounts : _rankCountsForMode(_mode);

  int get _targetScore => _mode == SurvivalMode.free
      ? _freeScore
      : (_randomRoute ? _randomModeFor(_mode) : _mode).defaultTarget;

  List<EnemyRank> get _setupRanksToDisplay => [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    if (_mode == SurvivalMode.hardFixed) EnemyRank.viseer,
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveMode = _mode == SurvivalMode.free
        ? SurvivalMode.free
        : _randomRoute
        ? _randomModeFor(_mode)
        : _mode;
    final config = effectiveMode == SurvivalMode.free
        ? SurvivalConfig(
            mode: SurvivalMode.free,
            targetScore: _freeScore,
            freeCounts: Map<EnemyRank, int>.from(_freeCounts),
          )
        : SurvivalConfig(
            mode: effectiveMode,
            targetScore: effectiveMode.defaultTarget,
          );
    final canStart = effectiveMode != SurvivalMode.free || _freeValid;

    return Scaffold(
      appBar: AppBar(title: const Text('Survival setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoCard(
              child: Row(
                children: [
                  HeroAvatar(hero: widget.hero, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.hero.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SurvivalMode>(
              segments: const [
                ButtonSegment(value: SurvivalMode.free, label: Text('Free')),
                ButtonSegment(
                  value: SurvivalMode.mediumFixed,
                  label: Text('Medium'),
                ),
                ButtonSegment(
                  value: SurvivalMode.hardFixed,
                  label: Text('Difficult'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _randomRoute = _mode == SurvivalMode.free;
                });
              },
            ),
            const SizedBox(height: 12),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$_targetScore pts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff54e98a),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Random route'),
                    value: _mode == SurvivalMode.free || _randomRoute,
                    onChanged: _mode == SurvivalMode.free
                        ? null
                        : (value) => setState(() => _randomRoute = value),
                  ),
                  if (!(_mode != SurvivalMode.free && _randomRoute)) ...[
                    const SizedBox(height: 8),
                    ..._setupRanksToDisplay.map(
                      (rank) => _buildRankCounter(
                        rank,
                        valueOverride: _displayCounts[rank] ?? 0,
                        enabled: _mode == SurvivalMode.free,
                      ),
                    ),
                  ],
                  if (_mode == SurvivalMode.free) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Enemies: $_freeTotal / 13',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Enemies left to add: ${max(0, 13 - _freeTotal)}',
                      style: const TextStyle(color: Color(0xff54e98a)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expert mode'),
                      subtitle: const Text('Allow Level 4 changes'),
                      value: _expertFreeMode,
                      onChanged: (value) =>
                          setState(() => _expertFreeMode = value),
                    ),
                    if (!_freeValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Adjust the enemy count before starting.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ImageActionButton(
              label: 'Start run',
              icon: Icons.play_arrow,
              onPressed: canStart ? () => widget.onStart(config) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCounter(
    EnemyRank rank, {
    int? valueOverride,
    bool enabled = true,
  }) {
    final value = valueOverride ?? _freeCounts[rank] ?? 0;
    final min = rank == EnemyRank.green
        ? 1
        : rank == EnemyRank.orange
        ? 2
        : 0;
    final orangeLocked =
        enabled && rank == EnemyRank.orange && !_expertFreeMode;
    final canEdit = enabled && !orangeLocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: AssetImage(rank.asset),
                fit: BoxFit.cover,
                colorFilter: rank == EnemyRank.viseer
                    ? ColorFilter.mode(
                        rank.color.withValues(alpha: 0.6),
                        BlendMode.multiply,
                      )
                    : null,
              ),
              border: Border.all(color: rank.color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('${rank.label} (${rank.points} pts)')),
          RoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            onPressed: !canEdit || value <= min
                ? null
                : () => setState(() => _freeCounts[rank] = value - 1),
          ),
          SizedBox(
            width: 42,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          RoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            onPressed: !canEdit || _freeTotal >= 13
                ? null
                : () => setState(() => _freeCounts[rank] = value + 1),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = const Color(0xff54e98a),
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        side: BorderSide(color: onPressed == null ? Colors.white12 : color),
      ),
      icon: Icon(icon),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({
    required this.adventure,
    required this.onRecordScore,
    required this.onChanged,
    required this.onPauseExit,
    required this.onAbandon,
    required this.onChangeHero,
    required this.onReplay,
    super.key,
  });

  final AdventureState adventure;
  final ValueChanged<AdventureState> onRecordScore;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;
  final VoidCallback onChangeHero;
  final VoidCallback onReplay;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static double _savedMapScale = 0.52;
  late final TransformationController _mapController =
      TransformationController()
        ..value = Matrix4.diagonal3Values(_savedMapScale, _savedMapScale, 1);
  final ScrollController _mapScrollController = ScrollController();
  final ScrollController _mapHorizontalController = ScrollController();
  int? _selectedEnemyId;
  Size? _latestMapSize;

  @override
  void initState() {
    super.initState();
    _mapController.addListener(() {
      _savedMapScale = _mapController.value.getMaxScaleOnAxis();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWholeMap(immediate: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _mapScrollController.dispose();
    _mapHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    final currentTarget = _currentTarget();
    if (adventure.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRecordScore(adventure);
      });
    }

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _openPauseDialog();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/fond-map.webp', fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            SafeArea(
              child: Column(
                children: [
                  MapHeader(
                    adventure: adventure,
                    onDetails: () => _openDetails(context),
                    onChanged: () {
                      widget.onChanged();
                      setState(() {});
                    },
                    onPause: _openPauseDialog,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final mapSize = Size(
                                max(1160, constraints.maxWidth + 720),
                                max(1320, constraints.maxHeight + 520),
                              );
                              _latestMapSize = mapSize;
                              return InteractiveViewer(
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(360),
                                minScale: 0.45,
                                maxScale: 2.4,
                                transformationController: _mapController,
                                child: SingleChildScrollView(
                                  controller: _mapScrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    260,
                                    100,
                                    260,
                                    180,
                                  ),
                                  child: SingleChildScrollView(
                                    controller: _mapHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: mapSize.width,
                                      height: mapSize.height,
                                      child: Stack(
                                        children: [
                                          ..._buildMapNodes(context, mapSize),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (adventure.finished)
                          Positioned(
                            left: 16,
                            right: 16,
                            top: 12,
                            child: EndAdventureBanner(
                              adventure: adventure,
                              onReplay: widget.onReplay,
                              onChangeHero: widget.onChangeHero,
                              onDetails: () => _openDetails(context),
                            ),
                          ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: CurrentTargetCard(
                            enemy: currentTarget,
                            onFight: currentTarget == null
                                ? null
                                : () => _openFight(currentTarget),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  EnemyNode? _currentTarget() {
    final currentEnemies = widget.adventure.enemies
        .where((enemy) => enemy.current && !enemy.defeated)
        .toList();
    if (currentEnemies.isEmpty) {
      _selectedEnemyId = null;
      return null;
    }
    EnemyNode? selected;
    for (final enemy in currentEnemies) {
      if (enemy.id == _selectedEnemyId) {
        selected = enemy;
        break;
      }
    }
    final target = selected ?? currentEnemies.first;
    _selectedEnemyId = target.id;
    return target;
  }

  List<Widget> _buildMapNodes(BuildContext context, Size size) {
    final positions = _positionsFor(size);
    return [
      Positioned.fill(
        child: CustomPaint(
          painter: MapLinePainter(widget.adventure.enemies, positions),
        ),
      ),
      ...widget.adventure.enemies.map((enemy) {
        final offset = positions[enemy.id]!;
        final width = enemy.id == 0 || enemy.rank == EnemyRank.orange
            ? 132.0
            : 112.0;
        final height = enemy.id == 0 || enemy.rank == EnemyRank.orange
            ? 86.0
            : 72.0;
        return Positioned(
          left: offset.dx - width / 2,
          top: offset.dy - height / 2,
          width: width,
          height: height,
          child: EnemyMapTile(
            enemy: enemy,
            selected: _selectedEnemyId == enemy.id,
            onTap: () => _selectEnemy(enemy),
          ),
        );
      }),
    ];
  }

  void _selectEnemy(EnemyNode enemy) {
    if (!enemy.current || enemy.defeated || widget.adventure.finished) {
      return;
    }
    setState(() => _selectedEnemyId = enemy.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnEnemy(enemy);
    });
  }

  Map<int, Offset> _positionsFor(Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final bottom = height - 180;
    final rowGap = max(150.0, (height - 360) / 7);
    final positions = <int, Offset>{0: Offset(centerX, bottom)};
    for (final branch in BranchSide.values) {
      final branchEnemies =
          widget.adventure.enemies
              .where((enemy) => enemy.branch == branch)
              .toList()
            ..sort((a, b) => a.step.compareTo(b.step));
      final sign = branch == BranchSide.left ? -1.0 : 1.0;
      for (final enemy in branchEnemies) {
        final pairOffset = switch (enemy.step) {
          4 || 6 => -0.1,
          5 || 7 => 0.1,
          _ => 0,
        };
        final x =
            centerX +
            sign * width * (0.075 + enemy.step * 0.032) +
            width * pairOffset * 0.72;
        final y = bottom - rowGap * enemy.step;
        positions[enemy.id] = Offset(x, y);
      }
    }
    return positions;
  }

  void _openFight(EnemyNode enemy) {
    if (!enemy.current || enemy.defeated || widget.adventure.finished) {
      return;
    }
    if (enemy.branch != null) {
      widget.adventure.lockBranch(enemy.branch!);
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => EnemyIntroPage(
              adventure: widget.adventure,
              enemy: enemy,
              onNext: () async {
                final navigator = Navigator.of(context);
                final rewardDue = await navigator.push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => FightPage(
                      adventure: widget.adventure,
                      enemyId: enemy.id,
                      onChanged: widget.onChanged,
                      onPauseExit: widget.onPauseExit,
                      onAbandon: widget.onAbandon,
                    ),
                  ),
                );
                if (mounted) {
                  navigator.pop();
                }
                if (rewardDue == true && mounted) {
                  await navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          RewardPage(adventure: widget.adventure, enemy: enemy),
                    ),
                  );
                }
              },
            ),
          ),
        )
        .then((_) {
          widget.onChanged();
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnEnemy(_currentTarget());
          });
        });
  }

  void _centerOnEnemy(EnemyNode? enemy, {bool immediate = false}) {
    final mapSize = _latestMapSize;
    if (enemy == null ||
        mapSize == null ||
        !_mapScrollController.hasClients ||
        !_mapHorizontalController.hasClients) {
      return;
    }
    final offset = _positionsFor(mapSize)[enemy.id];
    if (offset == null) {
      return;
    }
    final verticalTarget =
        (offset.dy + 100) -
        _mapScrollController.position.viewportDimension * 0.62;
    final horizontalTarget =
        offset.dx - _mapHorizontalController.position.viewportDimension / 2;

    final v = verticalTarget.clamp(
      _mapScrollController.position.minScrollExtent,
      _mapScrollController.position.maxScrollExtent,
    );
    final h = horizontalTarget.clamp(
      _mapHorizontalController.position.minScrollExtent,
      _mapHorizontalController.position.maxScrollExtent,
    );

    if (immediate) {
      _mapScrollController.jumpTo(v);
      _mapHorizontalController.jumpTo(h);
    } else {
      _mapScrollController.animateTo(
        v,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      _mapHorizontalController.animateTo(
        h,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showWholeMap({bool immediate = false}) {
    if (!_mapScrollController.hasClients ||
        !_mapHorizontalController.hasClients) {
      return;
    }
    final v = (_mapScrollController.position.maxScrollExtent * 0.48)
        .clamp(
          _mapScrollController.position.minScrollExtent,
          _mapScrollController.position.maxScrollExtent,
        )
        .toDouble();
    final h = (_mapHorizontalController.position.maxScrollExtent * 0.5)
        .clamp(
          _mapHorizontalController.position.minScrollExtent,
          _mapHorizontalController.position.maxScrollExtent,
        )
        .toDouble();
    if (immediate) {
      _mapScrollController.jumpTo(v);
      _mapHorizontalController.jumpTo(h);
      return;
    }
    _mapScrollController.animateTo(
      v,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _mapHorizontalController.animateTo(
      h,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdventureDetailsPage(adventure: widget.adventure),
      ),
    );
  }

  Future<void> _openPauseDialog() async {
    final action = await showDialog<_PauseAction>(
      context: context,
      builder: (context) => const PauseRunDialog(),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == _PauseAction.resumeLater) {
      widget.onPauseExit();
    } else {
      widget.onAbandon();
    }
  }
}

class MapHeader extends StatefulWidget {
  const MapHeader({
    required this.adventure,
    required this.onDetails,
    required this.onChanged,
    required this.onPause,
    this.showRewards = true,
    this.showVitals = true,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onDetails;
  final VoidCallback onChanged;
  final VoidCallback onPause;
  final bool showRewards;
  final bool showVitals;

  @override
  State<MapHeader> createState() => _MapHeaderState();
}

class _MapHeaderState extends State<MapHeader> {
  String? _editing;
  int _draftValue = 0;

  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xee131313),
        border: Border(bottom: BorderSide(color: Color(0xff3d4a3e))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              HeroAvatar(hero: adventure.hero, size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  adventure.hero.label,
                  style: const TextStyle(
                    color: heroAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Pause',
                onPressed: widget.onPause,
                icon: const Icon(Icons.pause_circle, color: heroAccent),
              ),
              IconButton(
                tooltip: 'Run log',
                onPressed: widget.onDetails,
                icon: const Icon(Icons.receipt_long, color: heroAccent),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: heroAccent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: heroAccent),
                ),
                child: Text(
                  '${adventure.score}/${adventure.targetScore} pts',
                  style: const TextStyle(
                    color: heroAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (widget.showVitals) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 74,
                  child: MapStatChip(
                    icon: Icons.favorite,
                    label: '',
                    value: adventure.health.toString(),
                    color: heroAccent,
                    accent: heroAccent,
                    onTap: () => _openStatEditor('HP', adventure.health),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  child: MapStatChip(
                    label: 'CP',
                    value: adventure.combatPoints.toString(),
                    color: heroAccent,
                    accent: heroAccent,
                    onTap: () => _openStatEditor('CP', adventure.combatPoints),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HeroTokenStrip(
                    tokens: adventure.alterations,
                    onEdit: () async {
                      final values = await showAlterationDialog(
                        context,
                        adventure.alterations,
                      );
                      if (values != null) {
                        adventure.setAlterations(values);
                        widget.onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          if (widget.showRewards) ...[
            const SizedBox(height: 8),
            CompactItemStrip(
              label: 'Rewards',
              emptyText: 'No reward yet',
              items: adventure.bonuses,
              accent: heroAccent,
              background: Colors.black.withValues(alpha: 0.32),
              border: heroAccent,
            ),
          ],
          if (_editing != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff54e98a)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _editing == 'HP' ? Icons.favorite : Icons.circle,
                          color: heroAccent,
                          size: _editing == 'HP' ? 18 : 0,
                        ),
                        if (_editing == 'HP') const SizedBox(width: 8),
                        Text(
                          _editing == 'HP' ? '' : 'CP',
                          style: const TextStyle(
                            color: heroAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        RoundIconButton(
                          icon: Icons.remove,
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _draftValue--),
                        ),
                        SizedBox(
                          width: 58,
                          child: Text(
                            _draftValue.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.add,
                          tooltip: 'Add',
                          onPressed: () => setState(() => _draftValue++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 112,
                    child: FilledButton(
                      onPressed: _saveStat,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openStatEditor(String label, int value) {
    setState(() {
      _editing = label;
      _draftValue = value;
    });
  }

  void _saveStat() {
    if (_editing == 'HP') {
      widget.adventure.setHeroHealth(_draftValue);
    } else if (_editing == 'CP') {
      widget.adventure.setHeroPc(_draftValue);
    }
    setState(() => _editing = null);
    widget.onChanged();
  }
}

class MapStatChip extends StatelessWidget {
  const MapStatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.icon,
    this.accent,
    super.key,
  });

  final IconData? icon;
  final String label;
  final String value;
  final Color color;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: (accent ?? const Color(0xff2a2a2a)).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent ?? const Color(0xff3d4a3e)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
            ],
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentTargetCard extends StatelessWidget {
  const CurrentTargetCard({
    required this.enemy,
    required this.onFight,
    super.key,
  });

  final EnemyNode? enemy;
  final VoidCallback? onFight;

  @override
  Widget build(BuildContext context) {
    final target = enemy;
    final accent = target?.rank.color ?? const Color(0xff54e98a);
    final targetTitle = target == null
        ? 'No target available'
        : '${target.rank.label} Minion';
    final targetPoints = target == null
        ? ''
        : '${target.rank.points} ${target.rank.points == 1 ? 'point' : 'points'}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff2a2a2a), Color(0xff101010)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff3d4a3e), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff9b59b6).withValues(alpha: 0.55),
            blurRadius: 22,
          ),
          const BoxShadow(color: Colors.black87, blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT TARGET',
                  style: TextStyle(
                    color: Color(0xffbbcbbb),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  targetTitle,
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (targetPoints.isNotEmpty)
                  Text(
                    targetPoints,
                    style: TextStyle(
                      color: accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 132,
            height: 58,
            child: FilledButton(
              onPressed: onFight,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('FIGHT'),
            ),
          ),
        ],
      ),
    );
  }
}

class EndAdventureBanner extends StatelessWidget {
  const EndAdventureBanner({
    required this.adventure,
    required this.onReplay,
    required this.onChangeHero,
    required this.onDetails,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onReplay;
  final VoidCallback onChangeHero;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: adventure.victory
          ? Colors.green.withValues(alpha: 0.28)
          : Colors.orange.withValues(alpha: 0.28),
      child: Column(
        children: [
          Text(
            adventure.victory ? 'Victory: run complete' : 'Survival ended',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            '${adventure.score} points - ${adventure.defeatedEnemies.length} enemies defeated',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: onReplay, child: const Text('Rejouer')),
              OutlinedButton(
                onPressed: onChangeHero,
                child: const Text('Change hero'),
              ),
              OutlinedButton(
                onPressed: onDetails,
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EnemyIntroPage extends StatefulWidget {
  const EnemyIntroPage({
    required this.adventure,
    required this.enemy,
    required this.onNext,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final Future<void> Function() onNext;

  @override
  State<EnemyIntroPage> createState() => _EnemyIntroPageState();
}

class _EnemyIntroPageState extends State<EnemyIntroPage> {
  late bool _keepFirstStrike = widget.enemy.alterations.contains(
    'Première Frappe',
  );

  @override
  Widget build(BuildContext context) {
    final enemy = widget.enemy;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            enemy.cardAsset,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
          Container(color: Colors.black.withValues(alpha: 0.58)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(child: EnemyRankAvatar(enemy: enemy, size: 132)),
                  const SizedBox(height: 18),
                  Text(
                    enemy.label.isEmpty ? 'Opponent name' : enemy.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enemy.rank.color,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${enemy.rank.label} Minion',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (enemy.alterations.contains('Première Frappe')) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: enemy.rank.color),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'First Strike token detected',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Does the minion keep this token for the start of combat?',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Yes')),
                              ButtonSegment(value: false, label: Text('No')),
                            ],
                            selected: {_keepFirstStrike},
                            onSelectionChanged: (values) =>
                                setState(() => _keepFirstStrike = values.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  ImageActionButton(
                    label: 'Next',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      if (_keepFirstStrike) {
                        if (!enemy.alterations.contains('Première Frappe')) {
                          enemy.alterations.add('Première Frappe');
                        }
                      } else {
                        enemy.alterations.removeWhere(
                          (token) => token == 'Première Frappe',
                        );
                      }
                      widget.onNext();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PauseAction { resumeLater, abandon }

class PauseRunDialog extends StatelessWidget {
  const PauseRunDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pause run'),
      content: const Text(
        'Do you want to leave this run and resume it later, or abandon it now? '
        'Abandoning keeps your current score for statistics.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_PauseAction.resumeLater),
          icon: const Icon(Icons.save),
          label: const Text('Resume later'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_PauseAction.abandon),
          icon: const Icon(Icons.flag),
          label: const Text('Abandon'),
        ),
      ],
    );
  }
}

class EnemyMapTile extends StatelessWidget {
  const EnemyMapTile({
    required this.enemy,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final EnemyNode enemy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = enemy.defeated ? 0.38 : 1.0;
    final accent = enemy.rank.color;
    final isStart = enemy.id == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accent,
              width: selected || enemy.current || isStart ? 4 : 2,
            ),
            color: const Color(0xdd131313),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: enemy.current ? 0.8 : 0.55),
                blurRadius: enemy.current ? 20 : 12,
                spreadRadius: enemy.current ? 2 : 0,
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(enemy.rank.asset, fit: BoxFit.cover),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.1)),
              if (isStart)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: -30,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xff54e98a),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'START',
                      style: TextStyle(
                        color: Color(0xff003919),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (!isStart && selected && !enemy.defeated)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: -28,
                  child: _MapTileLabel(
                    text: 'START',
                    background: accent,
                    foreground: Colors.black,
                  ),
                ),
              if (enemy.defeated)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: -28,
                  child: _MapTileLabel(
                    text: 'COMPLETED',
                    background: Colors.black87,
                    foreground: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapTileLabel extends StatelessWidget {
  const _MapTileLabel({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class EnemyRankAvatar extends StatelessWidget {
  const EnemyRankAvatar({required this.enemy, this.size = 54, super.key});

  final EnemyNode enemy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: enemy.rank.color, width: 3),
        boxShadow: [
          BoxShadow(
            color: enemy.rank.color.withValues(alpha: 0.45),
            blurRadius: 14,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(enemy.cardAsset, fit: BoxFit.cover),
    );
  }
}

class MapLinePainter extends CustomPainter {
  const MapLinePainter(this.enemies, this.positions);

  final List<EnemyNode> enemies;
  final Map<int, Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x88fcd34d)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void line(EnemyNode a, EnemyNode b) =>
        canvas.drawLine(positions[a.id]!, positions[b.id]!, paint);
    final start = enemies.firstWhere((enemy) => enemy.id == 0);
    for (final branch in BranchSide.values) {
      final branchEnemies =
          enemies.where((enemy) => enemy.branch == branch).toList()
            ..sort((a, b) => a.step.compareTo(b.step));
      if (branchEnemies.isEmpty) {
        continue;
      }
      line(start, branchEnemies.first);
      for (var index = 0; index < branchEnemies.length - 1; index++) {
        final current = branchEnemies[index];
        final next = branchEnemies[index + 1];
        if (branchEnemies.length == 6 && current.step == 3) {
          final choiceA = branchEnemies.firstWhere((enemy) => enemy.step == 4);
          final choiceB = branchEnemies.firstWhere((enemy) => enemy.step == 5);
          final boss = branchEnemies.last;
          line(current, choiceA);
          line(current, choiceB);
          line(choiceA, choiceB);
          final union = Offset(
            (positions[choiceA.id]!.dx + positions[choiceB.id]!.dx) / 2,
            (positions[choiceA.id]!.dy + positions[choiceB.id]!.dy) / 2,
          );
          canvas.drawLine(union, positions[boss.id]!, paint);
          break;
        }
        line(current, next);
      }
    }
  }

  @override
  bool shouldRepaint(MapLinePainter oldDelegate) => false;
}

class HeroStatusBar extends StatelessWidget {
  const HeroStatusBar({
    required this.adventure,
    required this.onChanged,
    required this.onDetails,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onChanged;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xff1d1d1d),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              HeroAvatar(hero: adventure.hero, size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${adventure.hero.label} - ${adventure.score} pts',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Detail',
                onPressed: onDetails,
                icon: const Icon(Icons.receipt_long),
              ),
              IconButton(
                tooltip: 'Status tokens',
                onPressed: () async {
                  final values = await showAlterationDialog(
                    context,
                    adventure.alterations,
                  );
                  if (values != null) {
                    adventure.setAlterations(values);
                    onChanged();
                  }
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StepperStat(
                  icon: Icons.favorite,
                  label: 'HP',
                  value: adventure.health,
                  color: Colors.redAccent,
                  onChanged: (value) {
                    adventure.setHeroHealth(value);
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StepperStat(
                  icon: Icons.bolt,
                  label: 'CP',
                  value: adventure.combatPoints,
                  color: Colors.amber,
                  onChanged: (value) {
                    adventure.setHeroPc(value);
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StepperStat extends StatelessWidget {
  const StepperStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(icon, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Spacer(),
          RoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            onPressed: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          RoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class FightPage extends StatefulWidget {
  const FightPage({
    required this.adventure,
    required this.enemyId,
    required this.onChanged,
    required this.onPauseExit,
    required this.onAbandon,
    super.key,
  });

  final AdventureState adventure;
  final int enemyId;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;

  @override
  State<FightPage> createState() => _FightPageState();
}

class _FightPageState extends State<FightPage> {
  final Random _random = Random();
  final List<GameDie> _dice = [];
  int _diceToRoll = 6;
  int _rollCount = 0;
  bool _editMode = false;
  bool _rerollOneMode = false;
  int? _editingDieId;
  late CombatPhase _phase;
  bool _upkeepApplied = false;
  bool _specialAttackReady = false;
  bool _specialAttackMode = false;

  EnemyNode get enemy => widget.adventure.enemyById(widget.enemyId);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _dice.add(GameDie(id: i));
    }
    _phase = enemy.alterations.contains('Première Frappe')
        ? CombatPhase.minionAttack
        : CombatPhase.hero;
    _configureDiceForPhase(autoRollAttack: _phase == CombatPhase.minionAttack);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _openPauseDialog();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              MapHeader(
                adventure: widget.adventure,
                onDetails: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AdventureDetailsPage(adventure: widget.adventure),
                  ),
                ),
                onChanged: () {
                  widget.onChanged();
                  setState(() {});
                },
                onPause: _openPauseDialog,
                showRewards: false,
                showVitals: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TurnPhasePanel(
                      phase: _phase,
                      adventure: widget.adventure,
                      enemy: enemy,
                      upkeepApplied: _upkeepApplied,
                      onPhaseChanged: _setPhase,
                      onNext: _advancePhase,
                      onApplyUpkeep: _applyUpkeep,
                    ),
                    const SizedBox(height: 12),
                    EnemyRulesPanel(enemy: enemy),
                    const SizedBox(height: 12),
                    DicePanel(
                      dice: _dice,
                      diceToRoll: _diceToRoll,
                      rollCount: _rollCount,
                      editMode: _editMode,
                      rerollOneMode: _rerollOneMode,
                      editingDieId: _editingDieId,
                      specialAttackMode: _specialAttackMode,
                      onDiceToRollChanged: (value) =>
                          setState(() => _diceToRoll = value),
                      onRoll: _rollDice,
                      onTapDie: _tapDie,
                      onSelectFace: _selectFace,
                      onValidateEdit: () =>
                          setState(() => _editingDieId = null),
                      onToggleEdit: () => setState(() {
                        _editMode = !_editMode;
                        _rerollOneMode = false;
                        _editingDieId = null;
                      }),
                      onToggleRerollOne: () => setState(() {
                        _rerollOneMode = !_rerollOneMode;
                        _editMode = false;
                        _editingDieId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (_specialAttackReady) ...[
                      ImageActionButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: _resolveSpecialAttack,
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: enemy.health <= 0 ? _finishCombat : null,
                      icon: const Icon(Icons.flag),
                      label: const Text('Finish combat'),
                    ),
                  ],
                ),
              ),
              FightStatusPanel(
                adventure: widget.adventure,
                enemy: enemy,
                phase: _phase,
                onChanged: () {
                  widget.onChanged();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rollDice() {
    if (_rollCount >= 3) {
      return;
    }
    if (_phase == CombatPhase.minionAttack &&
        _rollCount > 0 &&
        !_specialAttackMode &&
        enemy.alterations.contains('Ronces')) {
      if (enemy.health <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ronces would defeat the minion: reroll blocked.'),
          ),
        );
        return;
      }
      enemy.health = (enemy.health - 1).clamp(0, 99);
      widget.adventure.log('Ronces: minion loses 1 HP for reroll.');
    }
    setState(() {
      final rollable = _dice
          .where((die) => !die.reserved)
          .take(_diceToRoll)
          .toList();
      for (final die in rollable) {
        die.value = _random.nextInt(6) + 1;
      }
      _rollCount++;
      widget.adventure.log(
        'Roll $_rollCount: ${rollable.map((die) => die.value).join(', ')}.',
      );
      if (_phase == CombatPhase.minionAttack) {
        _applyMinionDiceStrategy();
      }
      widget.onChanged();
      if (_rollCount == 3) {
        for (final die in _dice) {
          die.reserved = true;
        }
        _specialAttackReady = _shouldResolveSpecialAttack();
      }
    });
  }

  void _tapDie(GameDie die) {
    setState(() {
      if (_editMode) {
        _editingDieId = die.id;
        return;
      }
      if (_rerollOneMode) {
        die.value = _random.nextInt(6) + 1;
        _rerollOneMode = false;
        widget.adventure.log(
          'Special reroll for die ${die.id + 1}: ${die.value}.',
        );
        widget.onChanged();
        return;
      }
      if (_rollCount > 0) {
        die.reserved = !die.reserved;
      }
    });
  }

  void _selectFace(GameDie die, int face) {
    setState(() {
      die.value = face;
      widget.adventure.log('Die ${die.id + 1} changed to $face.');
      widget.onChanged();
    });
  }

  void _setPhase(CombatPhase phase) {
    setState(() {
      _phase = phase;
      _upkeepApplied = false;
      _specialAttackReady = false;
      _specialAttackMode = false;
      _configureDiceForPhase(autoRollAttack: phase == CombatPhase.minionAttack);
    });
  }

  void _advancePhase() {
    final next = switch (_phase) {
      CombatPhase.hero => CombatPhase.minionUpkeep,
      CombatPhase.minionUpkeep => CombatPhase.minionAttack,
      CombatPhase.minionAttack => CombatPhase.hero,
    };
    _setPhase(next);
  }

  void _configureDiceForPhase({required bool autoRollAttack}) {
    _resetDice();
    if (_phase == CombatPhase.hero) {
      _diceToRoll = enemy.defenseDice.clamp(1, 6);
    } else if (_phase == CombatPhase.minionAttack) {
      _diceToRoll = 6;
      if (autoRollAttack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _phase == CombatPhase.minionAttack &&
              _rollCount == 0) {
            _rollDice();
          }
        });
      }
    }
  }

  void _resetDice() {
    _rollCount = 0;
    _editingDieId = null;
    _editMode = false;
    _rerollOneMode = false;
    _specialAttackReady = false;
    _specialAttackMode = false;
    for (final die in _dice) {
      die
        ..value = null
        ..reserved = false;
    }
  }

  void _applyUpkeep() {
    if (_upkeepApplied) {
      return;
    }
    setState(() {
      final poisonCount = enemy.alterations
          .where((token) => token == 'Poison')
          .length;
      final hemorrhageCount = enemy.alterations
          .where((token) => token == 'Hémorragie')
          .length;
      enemy.combatPoints = (enemy.combatPoints + 1).clamp(0, 99);
      if (poisonCount > 0) {
        enemy.health = (enemy.health - poisonCount).clamp(0, 99);
      }
      var hemorrhageDamage = 0;
      var hemorrhageRemoved = 0;
      for (var i = 0; i < hemorrhageCount; i++) {
        final roll = _random.nextInt(6) + 1;
        if (roll <= 4) {
          hemorrhageDamage++;
        } else {
          hemorrhageRemoved++;
        }
      }
      if (hemorrhageDamage > 0) {
        enemy.health = (enemy.health - hemorrhageDamage).clamp(0, 99);
      }
      for (var i = 0; i < hemorrhageRemoved; i++) {
        enemy.alterations.remove('Hémorragie');
      }
      _upkeepApplied = true;
      widget.adventure.log(
        'Minion upkeep: +1 CP${poisonCount > 0 ? ', -$poisonCount HP from Poison' : ''}${hemorrhageCount > 0 ? ', Hemorrhage -$hemorrhageDamage HP / $hemorrhageRemoved removed' : ''}.',
      );
      widget.onChanged();
    });
  }

  void _applyMinionDiceStrategy() {
    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.suite:
        _reserveBestSuite();
      case MinionAttackStyle.symbols:
        _reserveSymbolGoal();
      case MinionAttackStyle.none:
        return;
    }
  }

  void _reserveBestSuite() {
    const candidates = [
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
      [1, 2, 3, 4],
      [2, 3, 4, 5],
      [3, 4, 5, 6],
      [1, 2, 3],
      [2, 3, 4],
      [3, 4, 5],
      [4, 5, 6],
    ];
    final values = _dice.where((die) => die.value != null).toList();
    final rolledValues = values.map((die) => die.value!).toSet();
    List<int> best = const [];
    for (final candidate in candidates) {
      if (candidate.every(rolledValues.contains)) {
        best = candidate;
        break;
      }
    }
    if (best.isEmpty && rolledValues.contains(3) && rolledValues.contains(4)) {
      best = const [3, 4];
    }
    final needed = <int, int>{for (final value in best) value: 1};
    for (final die in _dice) {
      final value = die.value;
      if (value == null || (needed[value] ?? 0) <= 0) {
        die.reserved = false;
      } else {
        die.reserved = true;
        needed[value] = needed[value]! - 1;
      }
    }
  }

  void _reserveSymbolGoal() {
    final goals = enemy.attackPlan.goals;
    if (goals.isEmpty) {
      return;
    }
    var goal = goals.first;
    for (final candidate in goals) {
      if (!_symbolGoalMet(candidate)) {
        goal = candidate;
        break;
      }
      goal = candidate;
    }
    var white = goal.white;
    var yellow = goal.yellow;
    var red = goal.red;
    for (final die in _dice) {
      final symbol = die.symbol;
      if (symbol == DieSymbol.white && white > 0) {
        die.reserved = true;
        white--;
      } else if (symbol == DieSymbol.yellow && yellow > 0) {
        die.reserved = true;
        yellow--;
      } else if (symbol == DieSymbol.red && red > 0) {
        die.reserved = true;
        red--;
      } else {
        die.reserved = false;
      }
    }
  }

  bool _symbolGoalMet(SymbolGoal goal) {
    final counts = _symbolCounts();
    return (counts[DieSymbol.white] ?? 0) >= goal.white &&
        (counts[DieSymbol.yellow] ?? 0) >= goal.yellow &&
        (counts[DieSymbol.red] ?? 0) >= goal.red;
  }

  Map<DieSymbol, int> _symbolCounts() {
    final counts = <DieSymbol, int>{};
    for (final die in _dice) {
      final symbol = die.symbol;
      if (symbol != null) {
        counts[symbol] = (counts[symbol] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool _shouldResolveSpecialAttack() {
    return enemy.profileKey == 'oni-delirant' &&
        _phase == CombatPhase.minionAttack &&
        _symbolGoalMet(const SymbolGoal(yellow: 4));
  }

  Future<void> _resolveSpecialAttack() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attack choice'),
        content: const Text(
          'The minion attack succeeded. Continue to the single die roll?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Roll'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) {
      return;
    }

    final roll = _random.nextInt(6) + 1;
    final symbol = _symbolForFace(roll);
    final effect = switch (symbol) {
      DieSymbol.white => '5 imparable damage to the hero',
      DieSymbol.yellow => '6 imparable damage to the hero',
      DieSymbol.red => 'steal 4 HP',
    };
    setState(() {
      _specialAttackMode = true;
      _specialAttackReady = false;
      _rollCount = 1;
      _diceToRoll = 1;
      for (final die in _dice) {
        die
          ..value = null
          ..reserved = true;
      }
      _dice.first
        ..value = roll
        ..reserved = false;
    });

    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('D6 $roll'),
        content: Text(effect),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) {
      return;
    }
    setState(() {
      if (symbol == DieSymbol.white) {
        widget.adventure.setHeroHealth(widget.adventure.health - 5);
      } else if (symbol == DieSymbol.yellow) {
        widget.adventure.setHeroHealth(widget.adventure.health - 6);
      } else {
        widget.adventure.setHeroHealth(widget.adventure.health - 4);
        enemy.health = (enemy.health + 4).clamp(0, enemy.maxHealth);
      }
      widget.adventure.log('Oni attack choice: D6 $roll, $effect.');
      widget.onChanged();
    });
  }

  void _finishCombat() {
    widget.adventure.completeCombat(enemy);
    widget.onChanged();
    if (enemy.defeated && widget.adventure.health > 0) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pop(false);
  }

  Future<void> _openPauseDialog() async {
    final action = await showDialog<_PauseAction>(
      context: context,
      builder: (context) => const PauseRunDialog(),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == _PauseAction.resumeLater) {
      widget.onPauseExit();
    } else {
      widget.onAbandon();
    }
  }
}

class CompactItemStrip extends StatelessWidget {
  const CompactItemStrip({
    required this.label,
    required this.emptyText,
    required this.items,
    required this.accent,
    required this.background,
    required this.border,
    this.trailing,
    super.key,
  });

  final String label;
  final String emptyText;
  final List<String> items;
  final Color accent;
  final Color background;
  final Color border;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayItems = _compactItemModels(items);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabel = constraints.maxWidth >= 190;

          return Row(
            children: [
              if (showLabel) ...[
                Text(
                  items.isEmpty ? emptyText : label,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: displayItems.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...displayItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Tooltip(
                                  message: item.tooltip,
                                  child: CompactItemBadge(
                                    value: item.label,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              ?trailing,
            ],
          );
        },
      ),
    );
  }
}

class HeroTokenStrip extends StatelessWidget {
  const HeroTokenStrip({required this.tokens, required this.onEdit, super.key});

  final List<String> tokens;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return CompactItemStrip(
      label: 'Tokens',
      emptyText: 'Tokens',
      items: tokens,
      accent: heroAccent,
      background: Colors.black.withValues(alpha: 0.32),
      border: heroAccent,
      trailing: IconButton(
        tooltip: 'Edit tokens',
        visualDensity: VisualDensity.compact,
        onPressed: onEdit,
        icon: const Icon(Icons.edit, size: 18),
      ),
    );
  }
}

class CompactItemModel {
  const CompactItemModel({required this.label, required this.tooltip});

  final String label;
  final String tooltip;
}

class CompactItemBadge extends StatelessWidget {
  const CompactItemBadge({required this.value, required this.color, super.key});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        value,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<CompactItemModel> _compactItemModels(List<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts.entries
      .map(
        (entry) => CompactItemModel(
          label: _compactItemCode(entry.key, entry.value),
          tooltip: entry.value == 1
              ? entry.key
              : '${entry.key} x${entry.value}',
        ),
      )
      .toList();
}

String _compactItemCode(String value, [int count = 1]) {
  final upper = value.toUpperCase();
  String base;
  if (upper.contains('HP')) {
    base = 'HP';
  } else if (upper.contains('CP')) {
    base = 'CP';
  } else {
    final letters = RegExp(
      r'[A-Z0-9]+',
    ).allMatches(upper).map((match) => match.group(0)!).join();
    if (letters.isEmpty) {
      base = '--';
    } else {
      base = letters.length <= 2 ? letters : letters.substring(0, 2);
    }
  }
  return count <= 1 ? base : '${base}x$count';
}

class HeroCombatPanel extends StatelessWidget {
  const HeroCombatPanel({
    required this.adventure,
    required this.onChanged,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeroAvatar(hero: adventure.hero, size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${adventure.hero.label} - ${adventure.score} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final values = await showAlterationDialog(
                    context,
                    adventure.alterations,
                  );
                  if (values != null) {
                    adventure.setAlterations(values);
                    onChanged();
                  }
                },
                icon: const Icon(Icons.auto_fix_high),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StepperStat(
                  icon: Icons.favorite,
                  label: 'HP',
                  value: adventure.health,
                  color: Colors.redAccent,
                  onChanged: (value) {
                    adventure.setHeroHealth(value);
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StepperStat(
                  icon: Icons.bolt,
                  label: 'CP',
                  value: adventure.combatPoints,
                  color: Colors.amber,
                  onChanged: (value) {
                    adventure.setHeroPc(value);
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EnemyRulesPanel extends StatefulWidget {
  const EnemyRulesPanel({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  State<EnemyRulesPanel> createState() => _EnemyRulesPanelState();
}

class _EnemyRulesPanelState extends State<EnemyRulesPanel> {
  bool _showAttack = true;

  EnemyNode get enemy => widget.enemy;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => _openEnemyCard(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 58,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: enemy.rank.color),
                    image: DecorationImage(
                      image: AssetImage(enemy.cardAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enemy.label,
                  style: TextStyle(
                    color: enemy.rank.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.gps_fixed, size: 18),
                label: Text('Attack'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.shield, size: 18),
                label: Text('Defense'),
              ),
            ],
            selected: {_showAttack},
            onSelectionChanged: (values) =>
                setState(() => _showAttack = values.first),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showAttack
                ? MinionAttackSummary(enemy: enemy, key: const ValueKey('atk'))
                : MinionDefenseSummary(
                    enemy: enemy,
                    key: const ValueKey('def'),
                  ),
          ),
        ],
      ),
    );
  }

  void _openEnemyCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(child: Image.asset(enemy.cardAsset)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MinionAttackSummary extends StatelessWidget {
  const MinionAttackSummary({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    if (enemy.profileKey == 'oni-delirant') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ObjectiveRow(
            label: 'Roll target',
            symbols: [
              DieSymbol.yellow,
              DieSymbol.yellow,
              DieSymbol.yellow,
              DieSymbol.yellow,
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'If successful, roll 1 die',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const _ResultLine(
            symbol: DieSymbol.white,
            children: [DamageBadge(value: 5, imparable: true)],
          ),
          const _ResultLine(
            symbol: DieSymbol.yellow,
            children: [DamageBadge(value: 6, imparable: true)],
          ),
          _ResultLine(
            symbol: DieSymbol.red,
            children: [LifeStealBadge(value: 4, color: enemy.rank.color)],
          ),
        ],
      );
    }

    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Roll target',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            ...enemy.attackPlan.goals.map((goal) {
              final damage = _damageForSymbolGoal(enemy, goal);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: SymbolGoalView(goal: goal)),
                    if (damage != null)
                      DamageBadge(
                        value: damage.value,
                        imparable: damage.imparable,
                      ),
                  ],
                ),
              );
            }),
            ..._shortTokenHints(enemy),
          ],
        );
      case MinionAttackStyle.suite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suite targets',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            _SuiteLine(
              label: 'Micro',
              length: 3,
              damage: _suiteDamage(enemy, 3),
            ),
            _SuiteLine(
              label: 'Small',
              length: 4,
              damage: _suiteDamage(enemy, 4),
            ),
            _SuiteLine(
              label: 'Large',
              length: 5,
              damage: _suiteDamage(enemy, 5),
            ),
            ..._shortTokenHints(enemy),
          ],
        );
      case MinionAttackStyle.none:
        return Text(enemy.attacks.skip(1).join('\n'));
    }
  }

  List<Widget> _shortTokenHints(EnemyNode enemy) {
    final hints = <Widget>[];
    final text = enemy.attacks.join(' ').toLowerCase();
    if (text.contains('riposte')) {
      hints.add(const Text('Bonus: Riposte on 4 identical symbols.'));
    }
    if (text.contains('silence')) {
      hints.add(const Text('Bonus: Silence on 3 identical values.'));
    }
    if (text.contains('hémorragie')) {
      hints.add(const Text('Bonus: Hémorragie on 3 identical values.'));
    }
    if (text.contains('ronces')) {
      hints.add(const Text('Large suite also applies Ronces.'));
    }
    return hints;
  }
}

class MinionDefenseSummary extends StatelessWidget {
  const MinionDefenseSummary({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield, color: enemy.rank.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${enemy.defenseDice} defense dice\n${_compactDefenseText(enemy.defense)}',
            style: const TextStyle(height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({required this.label, required this.symbols});

  final String label;
  final List<DieSymbol> symbols;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        ...symbols.map((symbol) => DieSymbolMark(symbol: symbol)),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.symbol, required this.children});

  final DieSymbol symbol;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          DieSymbolMark(symbol: symbol),
          const SizedBox(width: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SuiteLine extends StatelessWidget {
  const _SuiteLine({
    required this.label,
    required this.length,
    required this.damage,
  });

  final String label;
  final int length;
  final _AttackDamage? damage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text('$length consecutive values')),
          if (damage != null)
            DamageBadge(value: damage!.value, imparable: damage!.imparable),
        ],
      ),
    );
  }
}

class SymbolGoalView extends StatelessWidget {
  const SymbolGoalView({required this.goal, super.key});

  final SymbolGoal goal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < goal.white; i++)
          const DieSymbolMark(symbol: DieSymbol.white),
        for (var i = 0; i < goal.yellow; i++)
          const DieSymbolMark(symbol: DieSymbol.yellow),
        for (var i = 0; i < goal.red; i++)
          const DieSymbolMark(symbol: DieSymbol.red),
      ],
    );
  }
}

class DieSymbolMark extends StatelessWidget {
  const DieSymbolMark({required this.symbol, super.key});

  final DieSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final color = switch (symbol) {
      DieSymbol.white => Colors.white,
      DieSymbol.yellow => Colors.orangeAccent,
      DieSymbol.red => Colors.redAccent,
    };
    final foreground = symbol == DieSymbol.white ? Colors.black : Colors.white;
    return Container(
      width: 25,
      height: 25,
      margin: const EdgeInsets.only(right: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black54),
      ),
      child: Icon(Icons.casino, size: 15, color: foreground),
    );
  }
}

class DamageBadge extends StatelessWidget {
  const DamageBadge({required this.value, required this.imparable, super.key});

  final int value;
  final bool imparable;

  @override
  Widget build(BuildContext context) {
    final color = imparable ? Colors.redAccent : Colors.white;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: imparable
            ? Colors.redAccent.withValues(alpha: 0.9)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: imparable ? Colors.white : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LifeStealBadge extends StatelessWidget {
  const LifeStealBadge({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        '-$value / +$value',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _AttackDamage {
  const _AttackDamage(this.value, {this.imparable = false});

  final int value;
  final bool imparable;
}

_AttackDamage? _damageForSymbolGoal(EnemyNode enemy, SymbolGoal goal) {
  final key = enemy.profileKey;
  if (key == 'ronin-vagabond') {
    return _AttackDamage(goal.white + 2);
  }
  if (key == 'enchanteur-gobelin') {
    return const _AttackDamage(4, imparable: true);
  }
  if (key == 'archer-de-lombre') {
    return _AttackDamage(goal.yellow + 3);
  }
  if (key == 'ombre-feline') {
    return _AttackDamage(goal.white + 1);
  }
  if (key == 'epeiste-egare') {
    return _AttackDamage(goal.white + 2);
  }
  return null;
}

_AttackDamage? _suiteDamage(EnemyNode enemy, int length) {
  final key = enemy.profileKey;
  if (key == 'fee') {
    return switch (length) {
      3 => const _AttackDamage(2, imparable: true),
      4 => const _AttackDamage(5),
      5 => const _AttackDamage(6),
      _ => null,
    };
  }
  if (key == 'elfe-du-chaos') {
    return switch (length) {
      3 => const _AttackDamage(4),
      4 => const _AttackDamage(7),
      5 => const _AttackDamage(8),
      _ => null,
    };
  }
  return null;
}

String _compactDefenseText(String value) {
  return value
      .replaceAll('symboles', 'symbols')
      .replaceAll('symbole', 'symbol')
      .replaceAll('dés', 'dice')
      .replaceAll('dé', 'die')
      .replaceAll('dégâts', 'damage')
      .replaceAll('dégât', 'damage')
      .replaceAll('Jet défensif ', '')
      .replaceAll('Jet defensif ', '');
}

class FightStatusPanel extends StatefulWidget {
  const FightStatusPanel({
    required this.adventure,
    required this.enemy,
    required this.phase,
    required this.onChanged,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final CombatPhase phase;
  final VoidCallback onChanged;

  @override
  State<FightStatusPanel> createState() => _FightStatusPanelState();
}

class _FightStatusPanelState extends State<FightStatusPanel> {
  final Set<String> _editing = {};
  final Map<String, int> _draftValues = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xee121212),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editing.contains('enemyHp')) ...[
            _buildEditorRow('enemyHp'),
            const SizedBox(height: 6),
          ],
          if (_editing.contains('enemyCp')) ...[
            _buildEditorRow('enemyCp'),
            const SizedBox(height: 6),
          ],
          CombatantStatusRow.enemy(
            enemy: widget.enemy,
            onHp: () => _openEditor('enemyHp', widget.enemy.health),
            onCp: () => _openEditor('enemyCp', widget.enemy.combatPoints),
            onEditTokens: _editEnemyTokens,
          ),
          const SizedBox(height: 8),
          CombatantStatusRow.hero(
            adventure: widget.adventure,
            onHp: () => _openEditor('heroHp', widget.adventure.health),
            onCp: () => _openEditor('heroCp', widget.adventure.combatPoints),
            onEditTokens: _editHeroTokens,
          ),
          if (_editing.contains('heroHp')) ...[
            const SizedBox(height: 6),
            _buildEditorRow('heroHp'),
          ],
          if (_editing.contains('heroCp')) ...[
            const SizedBox(height: 6),
            _buildEditorRow('heroCp'),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorRow(String key) {
    final isHero = key.startsWith('hero');
    final isHp = key.endsWith('Hp');
    final accent = isHero ? heroAccent : widget.enemy.rank.color;
    final value = _draftValues[key] ?? 0;
    return Row(
      children: [
        if (isHero)
          HeroAvatar(hero: widget.adventure.hero, size: 38)
        else
          EnemyRankAvatar(enemy: widget.enemy, size: 38),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Center(
            child: isHp
                ? Icon(Icons.favorite, color: accent, size: 18)
                : Text(
                    'CP',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          icon: Icons.remove,
          tooltip: 'Remove',
          color: accent,
          onPressed: () => setState(() => _draftValues[key] = value - 1),
        ),
        SizedBox(
          width: 54,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        RoundIconButton(
          icon: Icons.add,
          tooltip: 'Add',
          color: accent,
          onPressed: () => setState(() => _draftValues[key] = value + 1),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          child: FilledButton(
            onPressed: () => _saveStat(key),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  void _openEditor(String key, int value) {
    setState(() {
      if (_editing.contains(key)) {
        _editing.remove(key);
      } else {
        _editing.add(key);
        _draftValues[key] = value;
      }
    });
  }

  Future<void> _saveStat(String key) async {
    final value = _draftValues[key] ?? 0;
    switch (key) {
      case 'heroHp':
        widget.adventure.setHeroHealth(value);
      case 'heroCp':
        widget.adventure.setHeroPc(value);
      case 'enemyHp':
        final oldHealth = widget.enemy.health;
        widget.enemy.health = value.clamp(0, 99);
        if (widget.phase == CombatPhase.hero &&
            widget.enemy.health < oldHealth &&
            widget.enemy.alterations.contains('Riposte')) {
          await _offerRiposte();
        }
      case 'enemyCp':
        widget.enemy.combatPoints = value.clamp(0, 99);
    }
    setState(() => _editing.remove(key));
    widget.onChanged();
  }

  Future<void> _offerRiposte() async {
    final spend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Riposte'),
        content: const Text(
          'The minion lost HP during the hero turn. Spend Riposte now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (spend != true) {
      return;
    }
    final roll = Random().nextInt(6) + 1;
    final damage = (roll / 2).ceil();
    widget.enemy.alterations.remove('Riposte');
    widget.adventure.setHeroHealth(widget.adventure.health - damage);
    widget.adventure.log('Riposte spent: D6 $roll, hero loses $damage HP.');
  }

  Future<void> _editHeroTokens() async {
    final values = await showAlterationDialog(
      context,
      widget.adventure.alterations,
    );
    if (values != null) {
      widget.adventure.setAlterations(values);
      widget.onChanged();
      setState(() {});
    }
  }

  Future<void> _editEnemyTokens() async {
    final values = await showAlterationDialog(
      context,
      widget.enemy.alterations,
      forMinion: true,
    );
    if (values != null) {
      widget.enemy.alterations
        ..clear()
        ..addAll(values);
      widget.onChanged();
      setState(() {});
    }
  }
}

class CombatantStatusRow extends StatelessWidget {
  CombatantStatusRow.hero({
    required AdventureState adventure,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    super.key,
  }) : hero = adventure.hero,
       enemy = null,
       title = 'Hero',
       hp = adventure.health,
       cp = adventure.combatPoints,
       tokens = adventure.alterations,
       accent = heroAccent;

  CombatantStatusRow.enemy({
    required EnemyNode enemy,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    super.key,
  }) : enemy = enemy,
       hero = null,
       title = 'Enemy',
       hp = enemy.health,
       cp = enemy.combatPoints,
       tokens = enemy.alterations,
       accent = enemy.rank.color;

  final HeroType? hero;
  final EnemyNode? enemy;
  final String title;
  final int hp;
  final int cp;
  final List<String> tokens;
  final Color accent;
  final VoidCallback onHp;
  final VoidCallback onCp;
  final VoidCallback onEditTokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: MapStatChip(
            icon: Icons.favorite,
            label: '',
            value: hp.toString(),
            color: accent,
            accent: accent,
            onTap: onHp,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 74,
          child: MapStatChip(
            label: 'CP',
            value: cp.toString(),
            color: accent,
            accent: accent,
            onTap: onCp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CompactItemStrip(
            label: 'Tokens',
            emptyText: 'Tokens',
            items: tokens,
            accent: accent,
            background: Colors.black.withValues(alpha: 0.32),
            border: accent,
            trailing: IconButton(
              tooltip: 'Edit tokens',
              visualDensity: VisualDensity.compact,
              onPressed: onEditTokens,
              icon: const Icon(Icons.edit, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class EnemyCombatPanel extends StatefulWidget {
  const EnemyCombatPanel({
    required this.enemy,
    required this.onChanged,
    super.key,
  });

  final EnemyNode enemy;
  final VoidCallback onChanged;

  @override
  State<EnemyCombatPanel> createState() => _EnemyCombatPanelState();
}

class _EnemyCombatPanelState extends State<EnemyCombatPanel> {
  String? _editing;
  int _draftValue = 0;

  EnemyNode get enemy => widget.enemy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff301d1d),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: enemy.rank.color.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(enemy.rank.asset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${enemy.label} - ${enemy.rank.label} (+${enemy.rank.points})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MapStatChip(
                  icon: Icons.favorite,
                  label: 'HP',
                  value: enemy.health.toString(),
                  color: enemy.rank.color,
                  onTap: () => _openEditor('HP', enemy.health),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MapStatChip(
                  icon: Icons.bolt,
                  label: 'CP',
                  value: enemy.combatPoints.toString(),
                  color: Colors.amber,
                  onTap: () => _openEditor('CP', enemy.combatPoints),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff44272f),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: enemy.rank.color),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          enemy.alterations.isEmpty
                              ? 'Tokens'
                              : enemy.alterations.join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add token',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final values = await showAlterationDialog(
                            context,
                            enemy.alterations,
                            forMinion: true,
                          );
                          if (values != null) {
                            setState(() {
                              enemy.alterations
                                ..clear()
                                ..addAll(values);
                            });
                            widget.onChanged();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_editing != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: enemy.rank.color),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _editing == 'HP' ? Icons.favorite : Icons.bolt,
                          color: _editing == 'HP'
                              ? enemy.rank.color
                              : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editing!,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        RoundIconButton(
                          icon: Icons.remove,
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _draftValue--),
                        ),
                        SizedBox(
                          width: 58,
                          child: Text(
                            _draftValue.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.add,
                          tooltip: 'Add',
                          onPressed: () => setState(() => _draftValue++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 88,
                    child: FilledButton(
                      onPressed: _saveEnemyStat,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text('Attacks', style: TextStyle(fontWeight: FontWeight.w900)),
          ...enemy.attacks.map((attack) => Text('- $attack')),
          const SizedBox(height: 8),
          Text('Defense: ${enemy.defense}'),
        ],
      ),
    );
  }

  void _openEditor(String label, int value) {
    setState(() {
      _editing = label;
      _draftValue = value;
    });
  }

  void _saveEnemyStat() {
    if (_editing == 'HP') {
      enemy.health = _draftValue.clamp(0, 99);
    } else if (_editing == 'CP') {
      enemy.combatPoints = _draftValue.clamp(0, 99);
    }
    setState(() => _editing = null);
    widget.onChanged();
  }
}

class TurnPhasePanel extends StatelessWidget {
  const TurnPhasePanel({
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.upkeepApplied,
    required this.onPhaseChanged,
    required this.onNext,
    required this.onApplyUpkeep,
    super.key,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final bool upkeepApplied;
  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final VoidCallback onApplyUpkeep;

  @override
  Widget build(BuildContext context) {
    final poisonCount = enemy.alterations
        .where((token) => token == 'Poison')
        .length;
    final heroHasSilence = adventure.alterations.contains('Silence');
    final heroHasHemorrhage = adventure.alterations.contains('Hémorragie');
    final heroHasRonces = adventure.alterations.contains('Ronces');
    final enemyHasRiposte = enemy.alterations.contains('Riposte');
    final reminder = switch (phase) {
      CombatPhase.hero => [
        if (enemyHasRiposte) 'Riposte',
        if (heroHasSilence) 'Silence',
        if (heroHasHemorrhage) 'Hémorragie',
        if (heroHasRonces) 'Ronces',
      ].join(' | '),
      CombatPhase.minionUpkeep => poisonCount > 0 ? 'Poison x$poisonCount' : '',
      CombatPhase.minionAttack => '',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactPhaseSelector(
                  phase: phase,
                  onPhaseChanged: onPhaseChanged,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 44,
                child: IconButton.filled(
                  tooltip: phase == CombatPhase.minionUpkeep && !upkeepApplied
                      ? 'Apply upkeep and continue'
                      : 'Next phase',
                  onPressed: () {
                    if (phase == CombatPhase.minionUpkeep && !upkeepApplied) {
                      onApplyUpkeep();
                    }
                    onNext();
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
          if (reminder.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reminder,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: heroAccent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactPhaseSelector extends StatelessWidget {
  const _CompactPhaseSelector({
    required this.phase,
    required this.onPhaseChanged,
  });

  final CombatPhase phase;
  final ValueChanged<CombatPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CombatPhase.values.map((value) {
        final selected = value == phase;
        return Expanded(
          child: InkWell(
            onTap: () => onPhaseChanged(value),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 30 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: selected ? heroAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? heroAccent.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? heroAccent : Colors.white24,
                      ),
                    ),
                    child: Icon(
                      switch (value) {
                        CombatPhase.hero => Icons.person,
                        CombatPhase.minionUpkeep => Icons.autorenew,
                        CombatPhase.minionAttack => Icons.gps_fixed,
                      },
                      color: selected ? heroAccent : Colors.white70,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum DieSymbol { white, yellow, red }

DieSymbol _symbolForFace(int face) {
  if (face == 6) {
    return DieSymbol.red;
  }
  if (face >= 4) {
    return DieSymbol.yellow;
  }
  return DieSymbol.white;
}

class GameDie {
  GameDie({required this.id});

  final int id;
  int? value;
  bool reserved = false;

  DieSymbol? get symbol {
    final face = value;
    if (face == null) {
      return null;
    }
    return _symbolForFace(face);
  }
}

class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.dice,
    required this.diceToRoll,
    required this.rollCount,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.specialAttackMode,
    required this.onDiceToRollChanged,
    required this.onRoll,
    required this.onTapDie,
    required this.onSelectFace,
    required this.onValidateEdit,
    required this.onToggleEdit,
    required this.onToggleRerollOne,
    super.key,
  });

  final List<GameDie> dice;
  final int diceToRoll;
  final int rollCount;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final bool specialAttackMode;
  final ValueChanged<int> onDiceToRollChanged;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;

  @override
  Widget build(BuildContext context) {
    final visibleDice = specialAttackMode ? dice.take(1).toList() : dice;
    final rollDice = visibleDice.where((die) => !die.reserved).toList()
      ..sort(_compareDice);
    final reserveDice = visibleDice.where((die) => die.reserved).toList()
      ..sort(_compareDice);
    final editingDie = editingDieId == null
        ? null
        : dice.firstWhere((die) => die.id == editingDieId);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dice zone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              DropdownButton<int>(
                value: diceToRoll,
                items: [1, 2, 3, 4, 5, 6]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count dice'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onDiceToRollChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onToggleEdit,
                icon: const Icon(Icons.tune),
                label: Text(editMode ? 'Stop edit' : 'Edit a die'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleRerollOne,
                icon: const Icon(Icons.refresh),
                label: Text(rerollOneMode ? 'Choose a die' : 'Reroll one die'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DiceZone(title: 'Dice to roll', dice: rollDice, onTapDie: onTapDie),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$rollCount / 3',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ImageActionButton(
                  label: rollCount == 0 ? 'Roll' : 'Reroll',
                  icon: Icons.casino,
                  onPressed: rollCount < 3 ? onRoll : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DiceZone(title: 'Reserve', dice: reserveDice, onTapDie: onTapDie),
          if (editingDie != null) ...[
            const SizedBox(height: 12),
            Text(
              'Edit die ${editingDie.id + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5, 6]
                  .where((face) => face != editingDie.value)
                  .map(
                    (face) => ActionChip(
                      label: Text(face.toString()),
                      onPressed: () => onSelectFace(editingDie, face),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onValidateEdit,
              child: const Text('Confirm die'),
            ),
          ],
        ],
      ),
    );
  }
}

int _compareDice(GameDie a, GameDie b) {
  final av = a.value ?? 99;
  final bv = b.value ?? 99;
  final byValue = av.compareTo(bv);
  return byValue == 0 ? a.id.compareTo(b.id) : byValue;
}

class DiceZone extends StatelessWidget {
  const DiceZone({
    required this.title,
    required this.dice,
    required this.onTapDie,
    super.key,
  });

  final String title;
  final List<GameDie> dice;
  final ValueChanged<GameDie> onTapDie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            children: [
              for (final die in dice) ...[
                DieTile(die: die, onTap: () => onTapDie(die)),
                const SizedBox(width: 5),
              ],
              if (dice.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '--',
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class DieTile extends StatelessWidget {
  const DieTile({required this.die, required this.onTap, super.key});

  final GameDie die;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = die.value;
    final color = switch (value) {
      6 => Colors.redAccent,
      4 || 5 => Colors.orangeAccent,
      _ => Colors.white,
    };
    final textColor = value == null || value <= 3 ? Colors.black : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        constraints: const BoxConstraints(maxWidth: 42),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value == null ? Colors.white24 : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value?.toString() ?? '-',
          style: TextStyle(
            color: value == null ? Colors.white : textColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class RewardPage extends StatefulWidget {
  const RewardPage({required this.adventure, required this.enemy, super.key});

  final AdventureState adventure;
  final EnemyNode enemy;

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final Random _random = Random();
  int? _d20;

  @override
  Widget build(BuildContext context) {
    final d20 = _d20;
    return Scaffold(
      appBar: AppBar(title: const Text('Reward')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.enemy.label} defeated',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              InfoCard(
                child: Column(
                  children: [
                    const Text(
                      'Reward D20',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      d20?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      d20 == null
                          ? 'Lance le de'
                          : d20 <= 10
                          ? '+1 HP'
                          : '+1 CP',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              setState(() => _d20 = _random.nextInt(20) + 1),
                          icon: const Icon(Icons.casino),
                          label: Text(d20 == null ? 'Roll' : 'Reroll'),
                        ),
                        OutlinedButton.icon(
                          onPressed: d20 == null ? null : _modifyD20,
                          icon: const Icon(Icons.tune),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: d20 == null
                    ? null
                    : () {
                        widget.adventure.applyReward(d20);
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.check),
                label: const Text('Confirm reward'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _modifyD20() async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose the result'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                20,
                (index) => ActionChip(
                  label: Text('${index + 1}'),
                  onPressed: () => Navigator.of(context).pop(index + 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (value != null) {
      setState(() => _d20 = value);
    }
  }
}

class AdventureDetailsPage extends StatelessWidget {
  const AdventureDetailsPage({required this.adventure, super.key});

  final AdventureState adventure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${adventure.hero.label} - ${adventure.score} points',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text('Time played: ${_formatDuration(adventure.elapsed)}'),
            const SizedBox(height: 12),
            DetailSection(title: 'Rewards', items: adventure.bonuses),
            DetailSection(title: 'Status tokens', items: adventure.alterations),
            DetailSection(title: 'Log', items: adventure.logs),
          ],
        ),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  const DetailSection({required this.title, required this.items, super.key});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty) const Text('No entry.'),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $item'),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff202020),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

Future<List<String>?> showAlterationDialog(
  BuildContext context,
  List<String> current, {
  bool forMinion = false,
}) {
  final alterations = statusTokenRules
      .where((rule) => !forMinion || rule.minionAllowed)
      .map((rule) => rule.label)
      .toList();
  final counts = <String, int>{for (final value in alterations) value: 0};
  for (final value in current) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final selected = <String>[];
        for (final entry in counts.entries) {
          selected.addAll(List.filled(entry.value, entry.key));
        }
        return AlertDialog(
          title: const Text('Edit status tokens'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: alterations.map((value) {
                final count = counts[value] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(value)),
                      RoundIconButton(
                        icon: Icons.remove,
                        tooltip: 'Remove',
                        onPressed: count <= 0
                            ? null
                            : () => setDialogState(() {
                                counts[value] = count - 1;
                              }),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          count.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      RoundIconButton(
                        icon: Icons.add,
                        tooltip: 'Add',
                        onPressed: count >= _tokenRule(value).maxStack
                            ? null
                            : () => setDialogState(() {
                                counts[value] = count + 1;
                              }),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

List<EnemyNode> _generateEnemies(SurvivalConfig config) {
  final ranks = _ranksForMode(config);
  final random = Random();
  final greenProfiles = [...greenEnemyProfiles]..shuffle(random);
  EnemyProfile? nextGreenProfile() {
    if (greenProfiles.isEmpty) {
      return null;
    }
    return greenProfiles.removeLast();
  }

  final nodes = <EnemyNode>[
    _enemy(0, 'Start minion', ranks.first, null, 0, nextGreenProfile()),
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
          rank == EnemyRank.green ? nextGreenProfile() : null,
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
  };
}

SurvivalMode _randomModeFor(SurvivalMode mode) {
  return switch (mode) {
    SurvivalMode.mediumFixed ||
    SurvivalMode.mediumRandom => SurvivalMode.mediumRandom,
    SurvivalMode.hardFixed ||
    SurvivalMode.hardRandom => SurvivalMode.hardRandom,
    SurvivalMode.free => SurvivalMode.free,
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
  final selectedProfile = profile ?? _defaultProfileFor(rank);
  return EnemyNode(
    id: id,
    label: rank == EnemyRank.green ? selectedProfile.name : label,
    rank: rank,
    branch: branch,
    step: step,
    maxHealth: selectedProfile.maxHealth,
    pc: selectedProfile.pc,
    attacks: selectedProfile.attacks,
    defense: selectedProfile.defense,
    defenseDice: selectedProfile.defenseDice,
    attackPlan: selectedProfile.attackPlan,
    cardAsset: selectedProfile.cardAsset,
    profileKey: selectedProfile.key,
    initialTokens: selectedProfile.initialTokens,
  );
}

EnemyProfile _defaultProfileFor(EnemyRank rank) {
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
  };
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
