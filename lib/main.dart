import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'active_adventure_storage.dart';
import 'data/enemy_profile_repository.dart';
import 'data/fallback_enemy_profiles.dart';
import 'game_engine.dart';
import 'models/enemy_profile.dart';

part 'parts/app_shell.dart';
part 'parts/history.dart';
part 'parts/hero_setup.dart';
part 'parts/map.dart';
part 'parts/fight.dart';
part 'parts/rewards_details.dart';
part 'parts/run_generation.dart';

const String appVersionLabel = 'Version 1.3.15';
const String _activeAdventureKey = 'active_adventure_v1';
const Color heroAccent = Color(0xffffe22d);
const Color panelBorderGrey = Color(0xff3d4a3e);
const String defaultEnemyChatPortrait = 'assets/enemy_previews/bleu-001.webp';
const int mediumTarget = 33;
const int hardTarget = 52;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnemyProfileRepository.load();
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

class MinionDiceDecision {
  const MinionDiceDecision({required this.values, required this.reason});

  final List<int> values;
  final String reason;
}

class MinionDiceEngine {
  const MinionDiceEngine._();

  static MinionDiceDecision chooseSuiteHold(List<GameDie> dice) {
    final values =
        dice.where((die) => die.value != null).map((die) => die.value!).toList()
          ..sort();
    final unique = values.toSet();

    final complete = _bestCompleteSuite(unique);
    if (complete.isNotEmpty) {
      return MinionDiceDecision(
        values: complete,
        reason: '${complete.length}-value suite already validated.',
      );
    }

    final pair = _bestAdjacentPair(unique);
    if (pair.isNotEmpty) {
      return MinionDiceDecision(
        values: pair,
        reason:
            'Keeping ${pair.join('/')} because it is the best micro-suite start.',
      );
    }

    if (unique.contains(3)) {
      return const MinionDiceDecision(
        values: [3],
        reason: 'Keeping 3 as a central suite pivot.',
      );
    }
    if (unique.contains(4)) {
      return const MinionDiceDecision(
        values: [4],
        reason: 'Keeping 4 as a central suite pivot.',
      );
    }

    return const MinionDiceDecision(
      values: [],
      reason: 'No connected values or central pivot found.',
    );
  }

  static List<int> _bestCompleteSuite(Set<int> values) {
    for (final suite in const [
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
      [1, 2, 3, 4],
      [2, 3, 4, 5],
      [3, 4, 5, 6],
      [1, 2, 3],
      [2, 3, 4],
      [3, 4, 5],
      [4, 5, 6],
    ]) {
      if (suite.every(values.contains)) {
        return suite;
      }
    }
    return const [];
  }

  static List<int> _bestAdjacentPair(Set<int> values) {
    const pairs = [
      [2, 3],
      [3, 4],
      [4, 5],
      [1, 2],
      [5, 6],
    ];
    for (final pair in pairs) {
      if (pair.every(values.contains)) {
        return pair;
      }
    }
    return const [];
  }
}

enum CombatPhase {
  intro('Intro'),
  heroUpkeep('Hero upkeep'),
  hero('Hero attack'),
  minionUpkeep('Minion upkeep'),
  minionAttack('Minion attack');

  const CombatPhase(this.label);

  final String label;
}

CombatPhase _firstCombatPhaseFor(EnemyNode enemy) {
  if (enemy.profileKey == 'naraxus' ||
      enemy.alterations.contains('Première Frappe')) {
    return CombatPhase.minionUpkeep;
  }
  return CombatPhase.heroUpkeep;
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
    label: 'A terre',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Brulure',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Chaos',
    kind: StatusTokenKind.negative,
    maxStack: 6,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Commotion',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Dégat Bonus',
    kind: StatusTokenKind.positive,
    maxStack: 2,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Dépérissement',
    kind: StatusTokenKind.negative,
    maxStack: 2,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Domination',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Eboulissement',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Enchevêtrement',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Evitement',
    kind: StatusTokenKind.positive,
    maxStack: 3,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Hémorragie',
    kind: StatusTokenKind.negative,
    maxStack: 2,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Main du roi',
    kind: StatusTokenKind.positive,
    maxStack: 99,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Ombre',
    kind: StatusTokenKind.positive,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Parasite',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Poison',
    kind: StatusTokenKind.negative,
    maxStack: 3,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Première Frappe',
    kind: StatusTokenKind.unique,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Prime',
    kind: StatusTokenKind.positive,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Pris pour cible',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Riposte',
    kind: StatusTokenKind.positive,
    maxStack: 1,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Ronces',
    kind: StatusTokenKind.negative,
    maxStack: 1,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Salve',
    kind: StatusTokenKind.positive,
    maxStack: 99,
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
    label: 'Siphon vital',
    kind: StatusTokenKind.positive,
    maxStack: 2,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Sort 6',
    kind: StatusTokenKind.positive,
    maxStack: 1,
    persistent: true,
  ),
  StatusTokenRule(
    label: 'Vol',
    kind: StatusTokenKind.positive,
    maxStack: 3,
    persistent: false,
  ),
  StatusTokenRule(
    label: 'Hoarding',
    kind: StatusTokenKind.negative,
    maxStack: 99,
    persistent: false,
  ),
];

final List<String> knownStatusTokens = [
  for (final rule in statusTokenRules) rule.label,
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

String _normalizeTokenKey(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

StatusTokenRule _tokenRuleFromTag(String value) {
  final key = _normalizeTokenKey(value);
  return statusTokenRules.firstWhere(
    (rule) => _normalizeTokenKey(rule.label) == key,
    orElse: () => _tokenRule(value),
  );
}

String _tokenShortLabel(String label) {
  return switch (_normalizeTokenKey(label)) {
    'premierefrappe' => '1ST',
    'aterre' => 'DOWN',
    'brulure' => 'BRN',
    'chaos' => 'CH',
    'commotion' => 'COM',
    'degatbonus' => 'DMG+',
    'deperissement' => 'DEC',
    'domination' => 'DOM',
    'eboulissement' => 'EBO',
    'enchevetrement' => 'ROOT',
    'evitement' => 'EVA',
    'hemorragie' => 'HEM',
    'mainduroi' => 'KH',
    'ombre' => 'SHD',
    'parasite' => 'PAR',
    'poison' => 'PO',
    'prime' => 'PRI',
    'prispourcible' => 'TGT',
    'riposte' => 'RIP',
    'ronces' => 'THR',
    'salve' => 'SAL',
    'silence' => 'SIL',
    'siphonvital' => 'SIP',
    'sort' => 'SPL',
    'vol' => 'VOL',
    'hoarding' => 'HLD',
    _ =>
      label.length <= 4
          ? label.toUpperCase()
          : label.substring(0, 4).toUpperCase(),
  };
}

List<EnemyProfile> _recipeProfilesFor(EnemyRank rank) {
  final profiles = _profilesForRank(rank);
  profiles.sort(
    (a, b) => _recipeProfileCode(a).compareTo(_recipeProfileCode(b)),
  );
  return profiles;
}

List<EnemyProfile> _profilesForRank(EnemyRank rank) {
  final jsonProfiles = EnemyProfileRepository.byRank(rank);
  if (jsonProfiles.isNotEmpty) {
    return jsonProfiles;
  }
  return fallbackProfilesForRank(rank);
}

String _recipeProfileLabel(EnemyProfile profile) {
  return '${_recipeProfileCode(profile)} - ${profile.name}';
}

String _recipeProfileCode(EnemyProfile profile) {
  return switch (profile.key) {
    'rat-de-la-rue' => 'Vert001',
    'fee' => 'Vert002',
    'ronin-vagabond' => 'Vert003',
    'enchanteur-gobelin' => 'Vert004',
    'archer-de-lombre' => 'Vert005',
    'ombre-feline' => 'Vert007',
    'epeiste-egare' => 'Vert008',
    'elfe-du-chaos' => 'Vert009',
    'oni-delirant' => 'Vert010',
    _ => _genericProfileCode(profile),
  };
}

String _genericProfileCode(EnemyProfile profile) {
  final assetName = profile.cardAsset.split('/').last.split('.').first;
  final parts = assetName.split('-');
  if (parts.length >= 2) {
    final prefix = parts.first;
    final number = parts.last;
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}$number';
  }
  return '${profile.rank.name.toUpperCase()}000';
}

EnemyProfile? _profileByKey(String? key) {
  if (key == null) {
    return null;
  }
  final jsonProfile = EnemyProfileRepository.byKey(key);
  if (jsonProfile != null) {
    return jsonProfile;
  }
  for (final rank in EnemyRank.values) {
    final fallback = defaultProfileFor(rank);
    if (fallback.key == key) {
      return fallback;
    }
  }
  return null;
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
  hardFixed('Difficult fixed route', hardTarget, RunDifficulty.hard, false),
  hardRandom('Difficult random route', hardTarget, RunDifficulty.hard, true),
  free('Free mode', mediumTarget, RunDifficulty.free, true),
  naraxus('Naxarus Battle', 100, RunDifficulty.naraxus, false);

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
  hard('Difficult'),
  free('Free'),
  naraxus('Naxarus');

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
    this.bossHealthRemaining,
    this.enemiesDefeated = 0,
    this.duration = Duration.zero,
  });

  final HeroType hero;
  final DateTime date;
  final int score;
  final SurvivalMode mode;
  final int? healthRemaining;
  final int? bossHealthRemaining;
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
    SurvivalMode.hardFixed || SurvivalMode.hardRandom => 'Difficult mode',
    SurvivalMode.free => 'Free mode',
    SurvivalMode.naraxus => 'Naxarus Battle',
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
    this.rewardChests = 1,
    EnemyRank? rewardRank,
    List<EnemyRank> rewardRanks = const [],
    this.branch,
    this.step = 0,
  }) : health = maxHealth,
       combatPoints = pc,
       rewardRank = rewardRank ?? rank,
       rewardRanks = rewardRanks.isEmpty
           ? List<EnemyRank>.filled(
               rewardChests.clamp(1, 4).toInt(),
               rewardRank ?? rank,
             )
           : List<EnemyRank>.from(rewardRanks) {
    alterations.addAll(initialTokens);
  }

  final int id;
  String label;
  EnemyRank rank;
  int maxHealth;
  int pc;
  List<String> attacks;
  String defense;
  int defenseDice;
  MinionAttackPlan attackPlan;
  String cardAsset;
  String? profileKey;
  int rewardChests;
  EnemyRank rewardRank;
  List<EnemyRank> rewardRanks;
  final BranchSide? branch;
  final int step;
  int health;
  int combatPoints;
  final List<String> alterations = [];
  bool defeated = false;
  bool current = false;

  String get previewAsset {
    if (profileKey == 'naraxus') {
      return 'assets/enemy_previews/naraxus.webp';
    }
    if (profileKey == 'rat-de-la-rue') {
      return 'assets/enemy_previews/rat-de-la-rue.webp';
    }
    final filename = cardAsset.split('/').last;
    final base = filename.split('.').first.toLowerCase();
    if (cardAsset.contains('/bleu/vert-022')) {
      return 'assets/enemy_previews/bleu-022.webp';
    }
    if (cardAsset.contains('/bleu/vert-023')) {
      return 'assets/enemy_previews/bleu-023.webp';
    }
    final greenLegacyPreview = switch (base) {
      'enemy_green_fairy' => 'vert-001',
      'enemy_green_ronin' => 'vert-002',
      'enemy_green_goblin_enchanter' => 'vert-003',
      'enemy_green_shadow_archer' => 'vert-004',
      'enemy_green_feline_shadow' => 'vert-005',
      'enemy_green_lost_fencer' => 'vert-006',
      'enemy_green_chaos_elf' => 'vert-007',
      'enemy_green_raving_oni' => 'vert-008',
      _ => null,
    };
    if (greenLegacyPreview != null) {
      return 'assets/enemy_previews/$greenLegacyPreview.webp';
    }
    if (base.startsWith('bleu-') ||
        base.startsWith('vert-') ||
        base.startsWith('violet-') ||
        base.startsWith('orange-')) {
      return 'assets/enemy_previews/$base.webp';
    }
    return cardAsset;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'health': health,
    'combatPoints': combatPoints,
    'alterations': alterations,
    'defeated': defeated,
    'profileKey': profileKey,
    'rewardChests': rewardChests,
    'rewardRank': rewardRank.name,
    'rewardRanks': rewardRanks.map((rank) => rank.name).toList(),
  };

  void applyJson(Map<String, dynamic> json) {
    final restoredProfile = _profileByKey(json['profileKey']?.toString());
    if (restoredProfile != null) {
      label = restoredProfile.name;
      rank = restoredProfile.rank;
      maxHealth = restoredProfile.maxHealth;
      pc = restoredProfile.pc;
      attacks = restoredProfile.attacks;
      defense = restoredProfile.defense;
      defenseDice = restoredProfile.defenseDice;
      attackPlan = restoredProfile.attackPlan;
      cardAsset = restoredProfile.cardAsset;
      profileKey = restoredProfile.key;
      rewardChests = restoredProfile.rewardChests;
      rewardRank = restoredProfile.rewardRank ?? restoredProfile.rank;
      rewardRanks = restoredProfile.rewardRanks.isEmpty
          ? List<EnemyRank>.filled(rewardChests, rewardRank)
          : List<EnemyRank>.from(restoredProfile.rewardRanks);
    }
    rewardChests = ((json['rewardChests'] as num?)?.toInt() ?? rewardChests)
        .clamp(1, 4);
    rewardRank =
        _enumByName(EnemyRank.values, json['rewardRank'] as String?) ??
        rewardRank;
    final restoredRewardRanks = (json['rewardRanks'] as List? ?? const [])
        .map((value) => _enumByName(EnemyRank.values, value.toString()))
        .whereType<EnemyRank>()
        .toList();
    rewardRanks = restoredRewardRanks.isEmpty
        ? List<EnemyRank>.filled(rewardChests, rewardRank)
        : restoredRewardRanks;
    health = ((json['health'] as num?)?.toInt() ?? health).clamp(0, maxHealth);
    combatPoints = ((json['combatPoints'] as num?)?.toInt() ?? combatPoints)
        .clamp(0, 99);
    defeated = json['defeated'] as bool? ?? defeated;
    alterations
      ..clear()
      ..addAll((json['alterations'] as List? ?? const []).cast<String>());
  }

  void applyProfile(EnemyProfile profile) {
    label = profile.name;
    rank = profile.rank;
    maxHealth = profile.maxHealth;
    pc = profile.pc;
    attacks = profile.attacks;
    defense = profile.defense;
    defenseDice = profile.defenseDice;
    attackPlan = profile.attackPlan;
    cardAsset = profile.cardAsset;
    profileKey = profile.key;
    rewardChests = profile.rewardChests;
    rewardRank = profile.rewardRank ?? profile.rank;
    rewardRanks = profile.rewardRanks.isEmpty
        ? List<EnemyRank>.filled(rewardChests, rewardRank)
        : List<EnemyRank>.from(profile.rewardRanks);
    health = maxHealth;
    combatPoints = pc;
    alterations
      ..clear()
      ..addAll(profile.initialTokens);
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

  void applyReward(int d20, EnemyRank rank) {
    final outcome = GameEngine.rewardForD20(d20, chest: rank.rewardChestKey);
    if (outcome.healthDelta != 0) {
      health = (health + outcome.healthDelta).clamp(0, 99);
    }
    if (outcome.cpDelta != 0) {
      combatPoints = (combatPoints + outcome.cpDelta).clamp(0, 99);
    }
    if (outcome.token != null) {
      alterations.add(outcome.token!);
    }
    bonuses.add(outcome.label);
    log('Reward confirmed: D20 $d20, ${outcome.label}.');
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
