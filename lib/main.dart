import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'active_adventure_storage.dart';
import 'game_engine.dart';

const String appVersionLabel = 'Version 1.2.16';
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
  heroUpkeep('Hero upkeep'),
  hero('Hero attack'),
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
    label: 'Sort',
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

const List<EnemyProfile> generatedGreenEnemyProfiles = [
  EnemyProfile(
    key: 'vert-vert-011',
    name: 'Roi Vautour',
    rank: EnemyRank.green,
    maxHealth: 8,
    pc: 2,
    cardAsset: 'assets/vert/vert-011.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Descente en Pique: 3 jaunes = 4 degats imparables.',
      '4 jaunes = 5 degats imparables. 5 jaunes = 6 degats imparables.',
    ],
    defense:
        'Jet defensif 3 des: sur jaune, previent la moitie des degats arrondie au superieur.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'vert-vert-012',
    name: 'Roc',
    rank: EnemyRank.green,
    maxHealth: 15,
    pc: 2,
    cardAsset: 'assets/vert/vert-012.png',
    attacks: [
      'Rocalanche: lance 2 des et inflige la valeur totale du jet.',
      'Passif: si le lancer offensif echoue, inflige 1 degat imparable.',
    ],
    defense: 'Jet defensif 5 des: previent 1 degat par symbole jaune.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 4)]),
  ),
  EnemyProfile(
    key: 'vert-vert-013',
    name: 'Serpentyne',
    rank: EnemyRank.green,
    maxHealth: 9,
    pc: 2,
    cardAsset: 'assets/vert/vert-013.png',
    attacks: [
      'Baiser Venimeux: 3 blancs = 6 degats.',
      '3 blancs + 1 rouge = Poison et 6 degats.',
    ],
    defense: 'Jet defensif 3 des: sur rouge, inflige Poison.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 3, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'vert-vert-014',
    name: 'Druide Tenebreux',
    rank: EnemyRank.green,
    maxHealth: 11,
    pc: 3,
    cardAsset: 'assets/vert/vert-014.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Frappe Spirituelle: 3 jaunes.',
      'Forme Ours: A Terre et 6 degats. Forme Elan: Ronces et 6 degats.',
      'Passif: debut de tour, 1-3 Ours, 4-6 Elan.',
    ],
    defense:
        'Jet defensif 4 des: Ours inflige 1 par jaune + 2 par rouge; Elan previent 1 par jaune + 2 par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 3)]),
  ),
  EnemyProfile(
    key: 'vert-vert-015',
    name: 'Disciple',
    rank: EnemyRank.green,
    maxHealth: 12,
    pc: 2,
    cardAsset: 'assets/vert/vert-015.png',
    attacks: [
      'Abnegation: 2 blancs + 3 jaunes = 5 degats imparables et lance 1 de.',
      'Sur jaune, vole 1 CP. Sur rouge, retire ce minion et engage un minion niveau 3.',
    ],
    defense:
        'Jet defensif 2 des: sur rouge, renvoie la moitie des degats subis arrondie au superieur.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 2, yellow: 3)]),
  ),
  EnemyProfile(
    key: 'vert-vert-016',
    name: 'Valet Maraud',
    rank: EnemyRank.green,
    maxHealth: 12,
    pc: 0,
    cardAsset: 'assets/vert/vert-016.png',
    attacks: [
      'Volonte du Maitre: 1 blanc + 2 jaunes + 1 rouge = 5 degats imparables.',
    ],
    defense:
        'Jet defensif 3 des: previent 1 par jaune; sur rouge les heros perdent 1 or.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'vert-vert-017',
    name: 'Homme Lezard',
    rank: EnemyRank.green,
    maxHealth: 15,
    pc: 2,
    cardAsset: 'assets/vert/vert-017.png',
    attacks: [
      'Claquement de Crocs: 2 blancs + 1 rouge, lance 1 de, inflige sa valeur en degats et A Terre.',
    ],
    defense: 'Jet defensif 1 de: sur blanc, inflige 2 degats.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 2, red: 1)]),
  ),
  EnemyProfile(
    key: 'vert-vert-018',
    name: 'Satyre',
    rank: EnemyRank.green,
    maxHealth: 9,
    pc: 1,
    cardAsset: 'assets/vert/vert-018.png',
    attacks: [
      'Belier: 2 blancs + 1 jaune = 4 degats.',
      '2 blancs + 2 jaunes = 5 degats. Avec rouge = 6 degats et Enchevetrement.',
    ],
    defense: 'Jet defensif 2 des: sur jaune A Terre; sur rouge previent 2.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 2, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'vert-vert-019',
    name: 'Jeune Fille Melodieuse',
    rank: EnemyRank.green,
    maxHealth: 12,
    pc: 2,
    cardAsset: 'assets/vert/vert-019.png',
    attacks: [
      'Transe: 2 rouges = 4 degats imparables.',
      'Le joueur actif choisit un coequipier pour 2 degats collateraux, sinon defausse 1 carte au hasard.',
    ],
    defense: 'Jet defensif 2 des: sur rouge, previent 3 degats.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(red: 2)]),
  ),
  EnemyProfile(
    key: 'vert-vert-020',
    name: 'Guerrier Ogrun',
    rank: EnemyRank.green,
    maxHealth: 11,
    pc: 0,
    cardAsset: 'assets/vert/vert-020.png',
    attacks: [
      'Fleau: micro suite = 4 degats.',
      'Petite suite = 7 degats. Grande suite = 7 degats et A Terre.',
    ],
    defense:
        'Jet defensif 4 des: sur blanc inflige 1; previent 1 par jaune + 1 par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'vert-vert-021',
    name: 'Mage Lezard',
    rank: EnemyRank.green,
    maxHealth: 10,
    pc: 2,
    cardAsset: 'assets/vert/vert-021.png',
    attacks: [
      'Sorcellerie Ophique: 2 jaunes + 1 rouge, lance 1 de.',
      'Blanc: gagne 2 Chaos. Jaune: inflige Eboulissement. Puis inflige 6 + 1 par Chaos.',
    ],
    defense:
        'Jet defensif 3 des: gagne 1 Chaos par jaune puis inflige 1 degat par Chaos.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 2, red: 1)]),
  ),
  EnemyProfile(
    key: 'bleu-vert-022',
    name: 'Plague Bearer',
    rank: EnemyRank.green,
    maxHealth: 10,
    pc: 2,
    cardAsset: 'assets/bleu/vert-022.png',
    attacks: [
      'Scurry: 2 blancs + jaune = 4 degats.',
      '2 blancs + 2 jaunes = Parasite et 5 degats. Avec rouge = Poison et 6 degats.',
    ],
    defense:
        'Defense roll 2 dice: on yellow prevent 2; on red inflict Parasite.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 2, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-vert-023',
    name: 'Corrupted Ghoul',
    rank: EnemyRank.green,
    maxHealth: 7,
    pc: 2,
    cardAsset: 'assets/bleu/vert-023.png',
    initialTokens: ['Première Frappe'],
    attacks: ['Gnaw: 2 blancs + jaune + rouge = vole 2 points de vie.'],
    defense: 'Defense roll 3 dice: on red, steal 1 health.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1, red: 1),
    ]),
  ),
];

const List<EnemyProfile> blueEnemyProfiles = [
  EnemyProfile(
    key: 'bleu-bleu-001',
    name: 'Maraud Bestial',
    rank: EnemyRank.blue,
    maxHealth: 15,
    pc: 1,
    cardAsset: 'assets/bleu/bleu-001.png',
    attacks: [
      'Sauvagerie de l Ame: 2 blancs + 2 jaunes + rouge = 6 degats imparables.',
    ],
    defense:
        'Jet defensif 4 des: previent 1 par jaune; sur rouge les heros perdent 1 or.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-002',
    name: 'Archer Aveugle',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-002.png',
    attacks: [
      'Vraie Vision: 3/4/5 jaunes = 4/5/6 degats imparables.',
      'Si 3 chiffres identiques, inflige Eboulissement.',
    ],
    defense: 'Jet defensif 4 des: sur 2 jaunes, previent 4 degats.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-003',
    name: 'Mage de l Entropie',
    rank: EnemyRank.blue,
    maxHealth: 13,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-003.png',
    attacks: [
      'Sorcellerie Chaotique: 2 jaunes + rouge, lance 1 de puis inflige 7 + 1 par Chaos.',
      'Blanc: gagne 2 Chaos. Jaune: inflige Sort.',
    ],
    defense:
        'Jet defensif 4 des: gagne 1 Chaos par jaune puis inflige 1 degat par Chaos.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 2, red: 1)]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-004',
    name: 'Mage de Sang',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-004.png',
    attacks: [
      'Hemo-Siphon: 3/4/5 jaunes = vole 3/4/5 points de vie.',
      'Passif: debut de tour gagne Chaos; a 3 Chaos, les depense pour voler 3 PV.',
    ],
    defense: 'Jet defensif 3 des: vole 1 PV par jaune; sur rouge gagne Chaos.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-005',
    name: 'Sorciere d Os',
    rank: EnemyRank.blue,
    maxHealth: 10,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-005.png',
    attacks: [
      'Magie Noire: blanc + 2 jaunes + rouge = Deperissement, Silence, Parasite et 3 degats imparables.',
      'Passif upkeep: gagne Siphon Vital.',
    ],
    defense:
        'Jet defensif 4 des: vole 1 PV par jaune; inflige Hemorragie par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-006',
    name: 'Cyclope Brutal',
    rank: EnemyRank.blue,
    maxHealth: 14,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-006.png',
    attacks: [
      'Ecrasement: 4 blancs + rouge = 6 degats et lance 1 de; ajoute sa valeur en degats.',
      'Passif: si echec offensif, inflige 2 degats imparables.',
    ],
    defense: 'Jet defensif 1 de: sur blanc inflige 3; sur jaune soigne 2.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 4, red: 1)]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-007',
    name: 'The Hermit',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 5,
    cardAsset: 'assets/bleu/bleu-007.png',
    attacks: [
      'Deep Magic: blanc + 3 jaunes = 3 degats imparables et lance 1 de.',
      'Blanc: +2 degats. Jaune: Deperissement. Rouge: Brulure.',
    ],
    defense: 'Defense roll 5 dice: on 2 yellow, prevent 3.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 1, yellow: 3)]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-008',
    name: 'Dark Specter',
    rank: EnemyRank.blue,
    maxHealth: 13,
    pc: 1,
    cardAsset: 'assets/bleu/bleu-008.png',
    attacks: [
      'Bane: micro suite = Enchevetrement + 4 degats.',
      'Petite suite = Silence + 6. Grande suite = Sort + 8.',
    ],
    defense: 'Jet defensif 3 des: previent 2 degats par jaune.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'bleu-bleu-009',
    name: 'The Butcher',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-009.png',
    attacks: [
      'Carve: blanc + 2 jaunes + rouge = 3 degats imparables et lance 1 de.',
      'Sur jaune, inflige Commotion. Passif echec: soigne 2.',
    ],
    defense: 'Defense roll 1 die: on yellow, deal 3.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-010',
    name: 'Vipere Vicieuse',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-010.png',
    attacks: [
      'Envenimation: 3 blancs = 7 degats; 3 blancs + rouge = Poison et 7 degats.',
    ],
    defense: 'Jet defensif 4 des: sur rouge, inflige Poison.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 3, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-011',
    name: 'Vaurien',
    rank: EnemyRank.blue,
    maxHealth: 14,
    pc: 5,
    cardAsset: 'assets/bleu/bleu-011.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Ruelle Dangereuse: petite suite = moitie des PC en degats.',
      'Grande suite = PC en degats. Debut de tour gagne 2 PC.',
    ],
    defense:
        'Jet defensif 4 des: sur 2 jaunes vole 1 PC; sur 2 rouges ignore tous les degats.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'bleu-bleu-012',
    name: 'Epee Fantome',
    rank: EnemyRank.blue,
    maxHealth: 14,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-012.png',
    attacks: [
      'Feinte de l Ombre: 3/4/5 blancs = 5/6/7 degats.',
      'Si 3 chiffres identiques, inflige Parasite.',
    ],
    defense:
        'Jet defensif 1 de: inflige la moitie de la valeur en degats arrondie au superieur.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-013',
    name: 'Elfe Fletri',
    rank: EnemyRank.blue,
    maxHealth: 13,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-013.png',
    attacks: [
      'Racine Fletrie: micro suite = 5 degats.',
      'Petite suite = Parasite + 7. Grande suite = Deperissement + 9.',
    ],
    defense:
        'Jet defensif 5 des: sur 2 jaunes, previent la moitie des degats arrondie au superieur.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'bleu-bleu-014',
    name: 'Banshie Hurlante',
    rank: EnemyRank.blue,
    maxHealth: 12,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-014.png',
    attacks: [
      'Hurlement Sonique: 2/3/4/5 rouges = 2/3/4/5 degats collateraux a tous les adversaires.',
      'Si un seul adversaire, inflige Silence.',
    ],
    defense: 'Jet defensif 2 des: sur rouge, ignore tous les degats.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(red: 2),
      SymbolGoal(red: 3),
      SymbolGoal(red: 4),
      SymbolGoal(red: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-015',
    name: 'Centaure Enrage',
    rank: EnemyRank.blue,
    maxHealth: 15,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-015.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Charge: 2 blancs + 1/2 jaunes = 4/5 degats; avec rouge = 6 degats.',
      'Le joueur actif defausse un token positif au hasard.',
    ],
    defense: 'Jet defensif 3 des: sur jaune, inflige A Terre.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 2, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-016',
    name: 'Chevalier a la Hache',
    rank: EnemyRank.blue,
    maxHealth: 13,
    pc: 1,
    cardAsset: 'assets/bleu/bleu-016.png',
    attacks: [
      'Decoupage: petite suite = soigne 2 et 6 degats.',
      'Grande suite = soigne 2 et 9 degats. Echec: gagne 3 Degats Bonus.',
    ],
    defense:
        'Jet defensif 4 des: blanc inflige 1; previent 2 par jaune + 1 par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'bleu-bleu-017',
    name: 'Panthere Tenebreuse',
    rank: EnemyRank.blue,
    maxHealth: 9,
    pc: 4,
    cardAsset: 'assets/bleu/bleu-017.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Dechiquetage: 3/4/5 blancs = 6/7/8 degats.',
      'Si 3 chiffres identiques, inflige Hemorragie.',
    ],
    defense:
        'Jet defensif 1 de: blanc inflige Hemorragie; rouge inflige 2 Hemorragie.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-018',
    name: 'Harpie Cornue',
    rank: EnemyRank.blue,
    maxHealth: 10,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-018.png',
    initialTokens: ['Première Frappe'],
    attacks: ['Frappe en Pique: 2/3/4/5 jaunes = 3/4/5/6 degats imparables.'],
    defense:
        'Jet defensif 3 des: sur jaune previent la moitie; sur 2 jaunes ignore tous les degats.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 2),
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-019',
    name: 'Elfe Agile',
    rank: EnemyRank.blue,
    maxHealth: 13,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-019.png',
    attacks: [
      'Velocite Magique: 3 blancs + 2 jaunes = Eboulissement et 6 degats.',
      'Debut de tour: retire toutes les alterations positives du joueur actif.',
    ],
    defense:
        'Jet defensif 1 de: soigne selon la valeur du de et le nombre de minions en jeu.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 3, yellow: 2)]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-020',
    name: 'Farceur',
    rank: EnemyRank.blue,
    maxHealth: 8,
    pc: 4,
    cardAsset: 'assets/bleu/bleu-020.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Recreation: blanc + 2 jaunes + rouge = 4 degats imparables et lance 1 de.',
      'Blanc: vole 2 CP. Jaune: defausse 1 carte. Rouge: les deux.',
    ],
    defense: 'Jet defensif 5 des: sur 2 jaunes, previent 3.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-021',
    name: 'Bandit sans Ame',
    rank: EnemyRank.blue,
    maxHealth: 10,
    pc: 2,
    cardAsset: 'assets/bleu/bleu-021.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Lame de l Esprit: 3/4/5 blancs = 5/6/7 degats.',
      'Si 3 chiffres identiques, tous les adversaires engages perdent 1 CP.',
    ],
    defense: 'Jet defensif 3 des: inflige 1 par blanc + 1 par rouge.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-022',
    name: 'Vibra l Esoterique',
    rank: EnemyRank.blue,
    maxHealth: 14,
    pc: 3,
    cardAsset: 'assets/bleu/bleu-022.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Sanguinolame: 2 blancs + 1/2/3 jaunes = 4/5/6 degats.',
      'Debut de tour gagne Chaos; avec 3 Chaos, les depense pour se soigner du montant des degats.',
    ],
    defense: 'Jet defensif 4 des: vole 1 PV par jaune.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 2, yellow: 3),
    ]),
  ),
  EnemyProfile(
    key: 'bleu-bleu-023',
    name: 'Yokai',
    rank: EnemyRank.blue,
    maxHealth: 11,
    pc: 1,
    cardAsset: 'assets/bleu/bleu-023.png',
    attacks: [
      'Attraction: 4 jaunes, lance 1 de.',
      'Blanc: 4 degats imparables. Jaune: vole 3 PV. Rouge: vole 4 PV.',
      'Echec offensif: inflige Silence et Sort.',
    ],
    defense: 'Jet defensif 3 des: vole 1 PV par jaune.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 4)]),
  ),
];

const List<EnemyProfile> violetEnemyProfiles = [
  EnemyProfile(
    key: 'violet-violet-001',
    name: 'Guivre Noire',
    rank: EnemyRank.violet,
    maxHealth: 20,
    pc: 10,
    cardAsset: 'assets/violet/violet-001.png',
    attacks: [
      'Souffle Acide: 2 rouges = Poison, Brulure et 3 degats imparables.',
      'Passif: si moins de 5 PV au debut du tour, fuit.',
    ],
    defense: 'Jet defensif 1 de: blanc perd 1 PV; jaune ou rouge soigne 1.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(red: 2)]),
  ),
  EnemyProfile(
    key: 'violet-violet-002',
    name: 'Wyverne',
    rank: EnemyRank.violet,
    maxHealth: 16,
    pc: 10,
    cardAsset: 'assets/violet/violet-002.png',
    attacks: [
      'Brasier: 2 rouges = 7 degats et lance 1 de.',
      'Blanc: Brulure. Jaune: Brulure a 2 adversaires. Rouge: Brulure a tous.',
    ],
    defense:
        'Defense unique: si attaquee, lance 1 de; sur 5-6 l attaque adverse echoue.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(red: 2)]),
  ),
  EnemyProfile(
    key: 'violet-violet-003',
    name: 'Diablotin',
    rank: EnemyRank.violet,
    maxHealth: 13,
    pc: 4,
    cardAsset: 'assets/violet/violet-003.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Malice: micro suite = 5 degats.',
      'Petite suite = Enchevetrement + 7. Grande suite = Enchevetrement + vole 2 CP + 8.',
    ],
    defense: 'Jet defensif 5 des: sur 2 jaunes, previent 3 degats.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'violet-violet-004',
    name: 'Elfe Sombresource',
    rank: EnemyRank.violet,
    maxHealth: 15,
    pc: 2,
    cardAsset: 'assets/violet/violet-004.png',
    attacks: [
      'Ardillon Mystique: micro suite = 6 degats.',
      'Petite suite = Ronces + 8. Grande suite = Deperissement + 10.',
    ],
    defense:
        'Jet defensif 5 des: sur 2 jaunes, previent la moitie des degats arrondie au superieur.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'violet-violet-005',
    name: 'Iron Maiden',
    rank: EnemyRank.violet,
    maxHealth: 20,
    pc: 1,
    cardAsset: 'assets/violet/violet-005.png',
    attacks: [
      'Heavy Metal: micro suite = 6 degats.',
      'Petite suite = Ronces + 7. Grande suite = Ronces + Hemorragie + 9.',
    ],
    defense: 'Jet defensif 3 des: previent 2 degats par jaune.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.suite(),
  ),
  EnemyProfile(
    key: 'violet-violet-006',
    name: 'Carrion Golem',
    rank: EnemyRank.violet,
    maxHealth: 18,
    pc: 2,
    cardAsset: 'assets/violet/violet-006.png',
    attacks: [
      'Corpse Wave: 3 jaunes, lance 2 des et inflige la valeur totale.',
      'Si total inferieur a 6, inflige Parasite. Echec offensif: Poison.',
    ],
    defense: 'Jet defensif 5 des: previent 1 degat par jaune.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 3)]),
  ),
  EnemyProfile(
    key: 'violet-violet-007',
    name: 'Fell Summoner',
    rank: EnemyRank.violet,
    maxHealth: 20,
    pc: 2,
    cardAsset: 'assets/violet/violet-007.png',
    attacks: [
      'Ritual: 1/2/3 blancs + 2 jaunes = 3/4/5 degats imparables et gagne Chaos.',
      'Avec 3 Chaos fin de tour: se retire et engage un niveau 3 avec Premiere Frappe.',
    ],
    defense: 'Defense roll 2 dice: on yellow, gain Chaos.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 3, yellow: 2),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-008',
    name: 'Devin de Mort',
    rank: EnemyRank.violet,
    maxHealth: 15,
    pc: 2,
    cardAsset: 'assets/violet/violet-008.png',
    attacks: [
      'Baiser de la Mort: blanc + jaune + rouge, lance 2 des.',
      'Blanc gagne 2 Chaos; jaune Silence; rouge Sort; puis 7 + 1 par Chaos.',
    ],
    defense:
        'Jet defensif 5 des: gagne 1 Chaos par jaune puis inflige 1 degat par Chaos.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 1, red: 1),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-009',
    name: 'Basilic',
    rank: EnemyRank.violet,
    maxHealth: 14,
    pc: 2,
    cardAsset: 'assets/violet/violet-009.png',
    attacks: [
      'Morsure Venimeuse: 3 blancs = 7 degats.',
      '3 blancs + rouge = Poison + 8. 3 blancs + 2 rouges = Poison + 9.',
    ],
    defense: 'Jet defensif 4 des: inflige Poison par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 3, red: 1),
      SymbolGoal(white: 3, red: 2),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-010',
    name: 'Golem Concasseur',
    rank: EnemyRank.violet,
    maxHealth: 16,
    pc: 4,
    cardAsset: 'assets/violet/violet-010.png',
    attacks: [
      'Castagne: 3 jaunes, lance 2 des et inflige la valeur totale.',
      'Si total inferieur a 7, inflige Commotion. Echec offensif: Commotion.',
    ],
    defense: 'Jet defensif 5 des: previent 1 par jaune + 1 par rouge.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 3)]),
  ),
  EnemyProfile(
    key: 'violet-violet-011',
    name: 'Hydre Feroce',
    rank: EnemyRank.violet,
    maxHealth: 8,
    pc: 10,
    cardAsset: 'assets/violet/violet-011.png',
    attacks: [
      'Plurimorsure: 2 rouges = 6 degats + 3 par tete.',
      'Fin de lancer offensif: lance 1 de; sur rouge gagne 1 tete.',
    ],
    defense:
        'Defense unique: si les PV tombent a 0 et qu il reste des tetes, retire 1 tete et remet les PV.',
    defenseDice: 0,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(red: 2)]),
  ),
  EnemyProfile(
    key: 'violet-violet-012',
    name: 'Pillard Gobelin',
    rank: EnemyRank.violet,
    maxHealth: 25,
    pc: 4,
    cardAsset: 'assets/violet/violet-012.png',
    attacks: [
      'La Rixe ou la Fuite: 5 jaunes, lance 1 de.',
      '1-3: 4 degats imparables. 4-6: fuit. Echec offensif: les heros perdent 1 or.',
    ],
    defense: 'Jet defensif 1 de: 1-5 vole 1 CP et inflige 1; rouge fuit.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 5)]),
  ),
  EnemyProfile(
    key: 'violet-violet-013',
    name: 'Onibaba',
    rank: EnemyRank.violet,
    maxHealth: 14,
    pc: 2,
    cardAsset: 'assets/violet/violet-013.png',
    attacks: [
      'Malice: 4 jaunes, lance 1 de.',
      'Blanc: 6 imparables. Jaune: vole 4 PV. Rouge: vole 5 PV. Echec: Sort + vole 1 PV.',
    ],
    defense: 'Jet defensif 3 des: vole 1 PV par jaune.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 4)]),
  ),
  EnemyProfile(
    key: 'violet-violet-014',
    name: 'Chimere',
    rank: EnemyRank.violet,
    maxHealth: 20,
    pc: 4,
    cardAsset: 'assets/violet/violet-014.png',
    attacks: [
      'Triple Attaque: 3 rouges = 3 degats imparables et lance 1 de.',
      '1-2 Brulure, 3-4 A Terre, 5-6 deux Hemorragie.',
    ],
    defense: 'Jet defensif 1 de: blanc 1 degat; jaune 3 degats; rouge Poison.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(red: 3)]),
  ),
  EnemyProfile(
    key: 'violet-violet-015',
    name: 'Chaman Orque',
    rank: EnemyRank.violet,
    maxHealth: 15,
    pc: 3,
    cardAsset: 'assets/violet/violet-015.png',
    attacks: [
      'Terre Feu Tempetes: 2 blancs + 2 rouges = Poison, defausse 1 carte aleatoire et 4 degats imparables.',
      'Echec: Parasite + Sort.',
    ],
    defense:
        'Jet defensif 5 des: soigne 2 par jaune; sur rouge inflige Parasite.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 2, red: 2)]),
  ),
  EnemyProfile(
    key: 'violet-violet-016',
    name: 'Fanatique Sacre',
    rank: EnemyRank.violet,
    maxHealth: 16,
    pc: 4,
    cardAsset: 'assets/violet/violet-016.png',
    attacks: [
      'Combat Fervent: 2 blancs + 3 jaunes = 7 degats et lance 3 des.',
      'Ajoute 1 par blanc + 2 par jaune; soigne 2 par rouge. Echec: 2 imparables et soigne 1.',
    ],
    defense:
        'Jet defensif 4 des: blanc inflige 1; previent 2 par jaune + 2 par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 2, yellow: 3)]),
  ),
  EnemyProfile(
    key: 'violet-violet-017',
    name: 'Lame Maudite',
    rank: EnemyRank.violet,
    maxHealth: 13,
    pc: 4,
    cardAsset: 'assets/violet/violet-017.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Lame Corrompue: 3/4/5 blancs = 6/7/8 degats.',
      'Si 3 chiffres identiques, gagne Riposte.',
    ],
    defense:
        'Jet defensif 1 de: inflige et previent la moitie de la valeur du de arrondie au superieur.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-018',
    name: 'Succube',
    rank: EnemyRank.violet,
    maxHealth: 13,
    pc: 4,
    cardAsset: 'assets/violet/violet-018.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Seduction: 2 blancs + 1/2/3 jaunes = 4/5/6 degats.',
      'Avec 2 Chaos, les depense pour se soigner du montant des degats. Debut de tour gagne Chaos.',
    ],
    defense:
        'Jet defensif 4 des: vole 1 PV par jaune; sur 2 blancs inflige Parasite.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 1),
      SymbolGoal(white: 2, yellow: 2),
      SymbolGoal(white: 2, yellow: 3),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-019',
    name: 'Archer Pourpre',
    rank: EnemyRank.violet,
    maxHealth: 14,
    pc: 3,
    cardAsset: 'assets/violet/violet-019.png',
    attacks: [
      'Tir Diabolique: 2/3/4/5 jaunes = 6/7/8/9 degats.',
      'Si 3 chiffres identiques, inflige Ronces a tous les adversaires.',
    ],
    defense:
        'Jet defensif 4 des: inflige 1 par blanc + 1 par jaune; sur rouge a tous les adversaires engages.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 2),
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
      SymbolGoal(yellow: 5),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-020',
    name: 'Lion Obscur',
    rank: EnemyRank.violet,
    maxHealth: 14,
    pc: 4,
    cardAsset: 'assets/violet/violet-020.png',
    initialTokens: ['Première Frappe'],
    attacks: [
      'Evisceration: 3/4/5 blancs = 6/7/8 degats.',
      'Si 3 chiffres identiques, inflige Hemorragie + Silence.',
    ],
    defense:
        'Jet defensif 1 de: blanc ou jaune inflige Hemorragie; rouge inflige 2 Hemorragie.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 3),
      SymbolGoal(white: 4),
      SymbolGoal(white: 5),
    ]),
  ),
  EnemyProfile(
    key: 'violet-violet-021',
    name: 'Chevalier du Chaos',
    rank: EnemyRank.violet,
    maxHealth: 16,
    pc: 2,
    cardAsset: 'assets/violet/violet-021.png',
    attacks: [
      'Assaut Impie: petite suite = soigne 1 et 8 degats.',
      'Grande suite = soigne 2 et 10 degats. Echec: gagne 3 Degats Bonus.',
    ],
    defense:
        'Jet defensif 4 des: blanc inflige 1; previent 2 par jaune + 2 par rouge.',
    defenseDice: 4,
    attackPlan: MinionAttackPlan.suite(),
  ),
];

const List<EnemyProfile> orangeEnemyProfiles = [
  EnemyProfile(
    key: 'orange-orange-001',
    name: 'Renegate Vereuse',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 8,
    cardAsset: 'assets/orange/orange-001.png',
    attacks: [
      'Frappe Fourbe: petite suite = degats egaux a la moitie des PC du minion, arrondie au superieur.',
      'Frappe Fourbe: grande suite = degats egaux aux PC du minion.',
      'Passif: au debut de son tour, gagne 2 PC.',
      'Passif: si le lancer offensif echoue, gagne 3 Degats Bonus et Ombre.',
    ],
    defense:
        'Jet defensif 5 des: sur 2 rouges, ignore tous les degats; sinon vole 2 PC.',
    defenseDice: 5,
    attackPlan: MinionAttackPlan.suite(),
    initialTokens: ['Première Frappe', 'Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-002',
    name: 'Mort Murmurante',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 2,
    cardAsset: 'assets/orange/orange-002.png',
    attacks: [
      'Chant Mortuaire: 2 rouges = 3 degats collateraux.',
      'Chant Mortuaire: 3 rouges = 4 degats collateraux.',
      'Chant Mortuaire: 4 rouges = 5 degats collateraux.',
      'Chant Mortuaire: 5 rouges = 6 degats collateraux.',
      'Si un seul adversaire est engage, inflige aussi Deperissement et Silence.',
    ],
    defense: 'Jet defensif 2 des: sur rouge, ignore tous les degats.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(red: 2),
      SymbolGoal(red: 3),
      SymbolGoal(red: 4),
      SymbolGoal(red: 5),
    ]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-003',
    name: 'Atlas',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 8,
    cardAsset: 'assets/orange/orange-003.png',
    attacks: [
      'Frappe Titanique: micro suite = 2 degats collateraux a tous les adversaires engages.',
      'Frappe Titanique: petite suite = A Terre et 4 degats collateraux.',
      'Frappe Titanique: grande suite = Commotion et 7 degats collateraux.',
    ],
    defense:
        'Jet defensif unique 1 de: previent un nombre de degats egal a la valeur du de.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.suite(),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-004',
    name: 'Umbra',
    rank: EnemyRank.orange,
    maxHealth: 25,
    pc: 10,
    cardAsset: 'assets/orange/orange-004.png',
    attacks: [
      'Silhouette: 3 jaunes = 3 degats imparables.',
      'Silhouette: 4 jaunes = 5 degats imparables.',
      'Si Umbra possede Ombre, toutes ses attaques infligent 4 degats supplementaires.',
      'Passif: si le lancer offensif echoue, gagne Ombre.',
    ],
    defense: 'Jet defensif 3 des: sur rouge, gagne Ombre.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(yellow: 3),
      SymbolGoal(yellow: 4),
    ]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-005',
    name: 'Horde de Gobelins',
    rank: EnemyRank.orange,
    maxHealth: 25,
    pc: 6,
    cardAsset: 'assets/orange/orange-005.png',
    attacks: [
      'Nuee: inflige autant de degats que la moitie de ses points de vie, arrondie au superieur.',
      'Si les degats sont inferieurs ou egaux a 5, cette attaque devient imparable.',
      'Passif: si le lancer offensif echoue, soigne 3 PV et retire toutes les alterations positives du joueur actif.',
    ],
    defense:
        'Defense unique: les degats subis lors de l attaque d un adversaire sont reduits a un maximum de 5.',
    defenseDice: 0,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 5)]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-006',
    name: 'Empereur Cobra',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 8,
    cardAsset: 'assets/orange/orange-006.png',
    attacks: [
      'Frappe Venimeuse: inflige Poison, Enchevetrement et 2 Hemorragie.',
      'Passif: a la fin de son tour, l adversaire subit 1 degat par alteration negative qui l affecte.',
    ],
    defense: 'Jet defensif 1 de: sur blanc, inflige Hemorragie.',
    defenseDice: 1,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(yellow: 3)]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-007',
    name: 'Berserker Enrage',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 4,
    cardAsset: 'assets/orange/orange-007.png',
    attacks: [
      'Colere Dechainee: lance 2 des, plus 1 de par Chaos, jusqu a 5 des maximum.',
      'Inflige autant de degats que la valeur totale du jet.',
      'Passif: si le lancer offensif echoue, gagne Chaos.',
    ],
    defense:
        'Defense unique: si le Berserker subit des degats pendant un lancer offensif adverse, il gagne Chaos.',
    defenseDice: 0,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 3, red: 1)]),
    initialTokens: ['Première Frappe', 'Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-008',
    name: 'Swamp Dweller',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 6,
    cardAsset: 'assets/orange/orange-008.png',
    attacks: [
      'Toxic Touch: inflige Poison, puis inflige un Poison supplementaire.',
      'Passif: quand un adversaire engage devrait recevoir Poison, inflige aussi 2 degats imparables.',
    ],
    defense: 'Defense roll 2 dice: on yellow, inflict Poison.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([SymbolGoal(white: 1, yellow: 3)]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-009',
    name: 'Bloodseeker',
    rank: EnemyRank.orange,
    maxHealth: 30,
    pc: 5,
    cardAsset: 'assets/orange/orange-009.png',
    attacks: [
      'Leeching Strike: micro straight = inflict 2 Bleed and deal 3 undefendable damage.',
      'Leeching Strike: small straight = inflict Bleed, deal 6 damage, plus 1 per Bleed on the hero board.',
      'Leeching Strike: large straight = inflict Bleed, deal 8 damage, plus 2 per Bleed on the hero board.',
    ],
    defense: 'Defense roll 3 dice: on 2 white symbols, inflict Bleed.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.suite(),
    initialTokens: ['Première Frappe', 'Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-010',
    name: 'The Ashen King',
    rank: EnemyRank.orange,
    maxHealth: 35,
    pc: 6,
    cardAsset: 'assets/orange/orange-010.png',
    attacks: [
      'Profane Command: 1 blanc + 2 jaunes = 7 degats.',
      'Profane Command: 1 blanc + 2 jaunes + 1 rouge = Domination et 9 degats.',
      'Profane Command: 1 blanc + 3 jaunes + 1 rouge = Domination et 13 degats.',
    ],
    defense:
        'Defense roll 2 dice: on yellow, inflict Burn. If already at stack limit, deal 2 damage instead.',
    defenseDice: 2,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 1, yellow: 2),
      SymbolGoal(white: 1, yellow: 2, red: 1),
      SymbolGoal(white: 1, yellow: 3, red: 1),
    ]),
    initialTokens: ['Main du roi'],
  ),
  EnemyProfile(
    key: 'orange-orange-011',
    name: 'Fallen Pharaoh',
    rank: EnemyRank.orange,
    maxHealth: 25,
    pc: 5,
    cardAsset: 'assets/orange/orange-011.png',
    attacks: [
      'Ancient Curse: inflige 5 degats imparables et lance 1 de.',
      'Sur blanc: inflige Silence. Sur jaune: inflige Sort. Sur rouge: inflige Sort et Silence.',
      'Passif: au debut de son tour, gagne Siphon Vital; si deja a la limite, soigne 3 PV.',
    ],
    defense: 'Defense roll 3 dice: on red, steal 2 health.',
    defenseDice: 3,
    attackPlan: MinionAttackPlan.symbols([
      SymbolGoal(white: 2, yellow: 2, red: 1),
    ]),
    initialTokens: ['Main du roi'],
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

const EnemyProfile naraxusProfile = EnemyProfile(
  key: 'naraxus',
  name: 'Naxarus',
  rank: EnemyRank.naraxus,
  maxHealth: 65,
  pc: 0,
  cardAsset: 'assets/home_background_v4.png',
  initialTokens: ['Première Frappe'],
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

List<EnemyProfile> _recipeProfilesFor(EnemyRank rank) {
  final profiles = _profilesForRank(rank);
  profiles.sort(
    (a, b) => _recipeProfileCode(a).compareTo(_recipeProfileCode(b)),
  );
  return profiles;
}

List<EnemyProfile> _profilesForRank(EnemyRank rank) {
  return switch (rank) {
    EnemyRank.green => [...greenEnemyProfiles, ...generatedGreenEnemyProfiles],
    EnemyRank.blue => [...blueEnemyProfiles],
    EnemyRank.violet => [...violetEnemyProfiles],
    EnemyRank.viseer => [_defaultProfileFor(EnemyRank.viseer)],
    EnemyRank.orange => [...orangeEnemyProfiles],
    EnemyRank.naraxus => [naraxusProfile],
  };
}

String _recipeProfileLabel(EnemyProfile profile) {
  return '${_recipeProfileCode(profile)} - ${profile.name}';
}

String _recipeProfileCode(EnemyProfile profile) {
  return switch (profile.key) {
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
  for (final profile in [
    ...greenEnemyProfiles,
    ...generatedGreenEnemyProfiles,
    ...blueEnemyProfiles,
    ...violetEnemyProfiles,
    ...orangeEnemyProfiles,
    naraxusProfile,
    fallbackGreenProfile,
  ]) {
    if (profile.key == key) {
      return profile;
    }
  }
  return switch (key) {
    'blue-generic' => _defaultProfileFor(EnemyRank.blue),
    'violet-generic' => _defaultProfileFor(EnemyRank.violet),
    'viseer' => _defaultProfileFor(EnemyRank.viseer),
    'naraxus' => naraxusProfile,
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
  hard('Hard'),
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
    SurvivalMode.hardFixed || SurvivalMode.hardRandom => 'Hard mode',
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

  void applyProfile(EnemyProfile profile) {
    if (profile.rank != rank) {
      return;
    }
    label = profile.name;
    maxHealth = profile.maxHealth;
    pc = profile.pc;
    attacks = profile.attacks;
    defense = profile.defense;
    defenseDice = profile.defenseDice;
    attackPlan = profile.attackPlan;
    cardAsset = profile.cardAsset;
    profileKey = profile.key;
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
            onNaraxus: () => _openNaraxusHeroChoice(context),
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

  void _openHistory(BuildContext context, {RunDifficulty? initialDifficulty}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          records: _history,
          initialDifficulty: initialDifficulty,
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

  void _openNaraxusHeroChoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          onNext: (hero) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => NaraxusBattlePage(
                  hero: hero,
                  onRecord: (record) =>
                      setState(() => _history.insert(0, record)),
                  onOpenHistory: () => _openHistory(
                    appNavigatorKey.currentContext ?? context,
                    initialDifficulty: RunDifficulty.naraxus,
                  ),
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
          onAbandon: () => _abandonAdventure(adventure),
          onOpenHistory: () => _openHistory(
            appNavigatorKey.currentContext ?? context,
            initialDifficulty: adventure.config.mode.difficulty,
          ),
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

  Future<void> _abandonAdventure(AdventureState adventure) async {
    _recordAdventure(adventure);
    _activeAdventure = null;
    await _store.clear();
    if (!mounted) {
      return;
    }
    setState(() {});
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _stopActiveCampaign() async {
    final adventure = _activeAdventure;
    if (adventure != null) {
      _recordAdventure(adventure);
    }
    await _clearActiveAdventure();
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
    this.initialDifficulty,
    super.key,
  });

  final List<GameRecord> records;
  final ValueChanged<GameRecord> onAddRecord;
  final ValueChanged<GameRecord> onDeleteRecord;
  final RunDifficulty? initialDifficulty;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistorySort _sort = HistorySort.average;
  late RunDifficulty _difficulty =
      widget.initialDifficulty ?? RunDifficulty.medium;
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
                const _HistoryHeaderRow(),
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
                      flex: 4,
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
                      child: Text(
                        _averageEnemies(runs).toStringAsFixed(1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _averageHealthLabel(runs),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _averageDurationLabel(runs),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _averageScore(runs).toStringAsFixed(1),
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

  double _averageEnemies(List<GameRecord> runs) =>
      runs.fold<int>(0, (total, run) => total + run.enemiesDefeated) /
      runs.length;

  String _averageHealthLabel(List<GameRecord> runs) {
    final values = runs
        .map((run) => run.healthRemaining)
        .whereType<int>()
        .toList();
    if (values.isEmpty) {
      return 'n/a';
    }
    final average =
        values.fold<int>(0, (total, value) => total + value) / values.length;
    return average.toStringAsFixed(1);
  }

  String _averageDurationLabel(List<GameRecord> runs) {
    final values = runs
        .map((run) => run.duration)
        .where((duration) => duration.inSeconds > 0)
        .toList();
    if (values.isEmpty) {
      return 'n/a';
    }
    final seconds =
        values.fold<int>(0, (total, duration) => total + duration.inSeconds) ~/
        values.length;
    return _formatDuration(Duration(seconds: seconds));
  }

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

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Hero / run')),
          Expanded(child: _HistoryHeaderIcon(Icons.flag, 'Runs')),
          Expanded(child: _HistoryHeaderIcon(Icons.casino, 'Enemies')),
          Expanded(child: _HistoryHeaderIcon(Icons.favorite, 'HP')),
          Expanded(child: _HistoryHeaderIcon(Icons.timer, 'Time')),
          Expanded(child: _HistoryHeaderIcon(Icons.emoji_events, 'Points')),
        ],
      ),
    );
  }
}

class _HistoryHeaderIcon extends StatelessWidget {
  const _HistoryHeaderIcon(this.icon, this.tooltip);

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: Color(0xffffe22d)),
    );
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
          flex: 4,
          child: Text(showHero ? record.hero.label : _formatDate(record.date)),
        ),
        Expanded(child: Text('1', textAlign: TextAlign.center)),
        Expanded(
          child: Text(
            record.enemiesDefeated.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            record.healthRemaining == null
                ? 'n/a'
                : record.healthRemaining.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            _formatDuration(record.duration),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: Text(record.score.toString(), textAlign: TextAlign.right),
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
    required this.onOpenHistory,
    required this.onChangeHero,
    required this.onReplay,
    super.key,
  });

  final AdventureState adventure;
  final ValueChanged<AdventureState> onRecordScore;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;
  final VoidCallback onOpenHistory;
  final VoidCallback onChangeHero;
  final VoidCallback onReplay;

  @override
  State<MapPage> createState() => _MapPageState();
}

class NaraxusBattlePage extends StatefulWidget {
  const NaraxusBattlePage({
    required this.hero,
    required this.onRecord,
    required this.onOpenHistory,
    super.key,
  });

  final HeroType hero;
  final ValueChanged<GameRecord> onRecord;
  final VoidCallback onOpenHistory;

  @override
  State<NaraxusBattlePage> createState() => _NaraxusBattlePageState();
}

class _NaraxusBattlePageState extends State<NaraxusBattlePage> {
  late final AdventureState _adventure = _createAdventure();
  bool _recorded = false;

  AdventureState _createAdventure() {
    final adventure = AdventureState(
      hero: widget.hero,
      config: const SurvivalConfig(
        mode: SurvivalMode.naraxus,
        targetScore: 100,
      ),
    );
    final naraxus = EnemyNode(
      id: 0,
      label: naraxusProfile.name,
      rank: EnemyRank.naraxus,
      maxHealth: naraxusProfile.maxHealth,
      pc: naraxusProfile.pc,
      attacks: naraxusProfile.attacks,
      defense: naraxusProfile.defense,
      defenseDice: naraxusProfile.defenseDice,
      attackPlan: naraxusProfile.attackPlan,
      cardAsset: naraxusProfile.cardAsset,
      profileKey: naraxusProfile.key,
      initialTokens: naraxusProfile.initialTokens,
    );
    adventure
      ..health = 50
      ..combatPoints = 2;
    adventure.enemies
      ..clear()
      ..add(naraxus);
    adventure.log('Naxarus battle started.');
    return adventure;
  }

  @override
  Widget build(BuildContext context) {
    return FightPage(
      adventure: _adventure,
      enemyId: 0,
      onChanged: () => setState(() {}),
      onPauseExit: () =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      onAbandon: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onFinished: _finishBattle,
      onGameOverHome: _finishBattle,
      onGameOverHistory: () {
        _recordBattle();
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onOpenHistory();
      },
    );
  }

  void _recordBattle() {
    if (!_recorded) {
      final naraxus = _adventure.enemyById(0);
      final success = naraxus.health <= 0;
      widget.onRecord(
        GameRecord(
          hero: widget.hero,
          date: DateTime.now(),
          score: success ? 100 : 0,
          mode: SurvivalMode.naraxus,
          healthRemaining: _adventure.health,
          bossHealthRemaining: naraxus.health,
          enemiesDefeated: success ? 1 : 0,
          duration: _adventure.elapsed,
        ),
      );
      _recorded = true;
    }
  }

  void _finishBattle() {
    _recordBattle();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _MapPageState extends State<MapPage> {
  static double _savedMapScale = 0.52;
  late final TransformationController _mapController =
      TransformationController();
  final ScrollController _mapScrollController = ScrollController();
  final ScrollController _mapHorizontalController = ScrollController();
  int? _selectedEnemyId;
  Size? _latestMapSize;

  @override
  void initState() {
    super.initState();
    _mapController.value = _mapController.value.clone()
      ..scaleByDouble(_savedMapScale, _savedMapScale, 1, 1);
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
    if (enemy.defeated) {
      _openDefeatedEnemyPreview(enemy);
      return;
    }
    if (!enemy.current || widget.adventure.finished) {
      return;
    }
    setState(() => _selectedEnemyId = enemy.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnEnemy(enemy);
    });
  }

  Future<void> _openDefeatedEnemyPreview(EnemyNode enemy) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EnemyIntroPage(
          adventure: widget.adventure,
          enemy: enemy,
          showNext: false,
          onNext: () async {},
        ),
      ),
    );
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

  Future<void> _openFight(EnemyNode enemy) async {
    if (!enemy.current || enemy.defeated || widget.adventure.finished) {
      return;
    }
    final selectedProfile = await Navigator.of(context).push<EnemyProfile>(
      MaterialPageRoute<EnemyProfile>(
        builder: (_) => RecipeEnemySelectionPage(enemy: enemy),
      ),
    );
    if (!mounted || selectedProfile == null) {
      return;
    }
    enemy.applyProfile(selectedProfile);
    widget.onChanged();
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
                      onGameOverHome: () {
                        widget.onRecordScore(widget.adventure);
                        widget.onChanged();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      onGameOverHistory: () {
                        widget.onRecordScore(widget.adventure);
                        widget.onChanged();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        widget.onOpenHistory();
                      },
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
                  widget.onChanged();
                  setState(() {});
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
              emptyText: 'Rewards',
              items: adventure.bonuses,
              accent: heroAccent,
              background: Colors.black.withValues(alpha: 0.32),
              border: heroAccent,
              compactDuplicates: false,
              leading: Icon(Icons.emoji_events, color: heroAccent, size: 18),
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

class RecipeEnemySelectionPage extends StatefulWidget {
  const RecipeEnemySelectionPage({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  State<RecipeEnemySelectionPage> createState() =>
      _RecipeEnemySelectionPageState();
}

class _RecipeEnemySelectionPageState extends State<RecipeEnemySelectionPage> {
  late final List<EnemyProfile> _profiles = _recipeProfilesFor(
    widget.enemy.rank,
  );
  late EnemyProfile _selected = _profiles.firstWhere(
    (profile) => profile.key == widget.enemy.profileKey,
    orElse: () => _profiles[Random().nextInt(_profiles.length)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe minion selection')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose the minion for this slot',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EnemyProfile>(
                initialValue: _selected,
                isExpanded: true,
                menuMaxHeight: 420,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Minion',
                ),
                items: _profiles
                    .map(
                      (profile) => DropdownMenuItem(
                        value: profile,
                        child: Text(
                          _recipeProfileLabel(profile),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (profile) {
                  if (profile != null) {
                    setState(() => _selected = profile);
                  }
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _selected.cardAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ImageActionButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnemyIntroPage extends StatefulWidget {
  const EnemyIntroPage({
    required this.adventure,
    required this.enemy,
    required this.onNext,
    this.showNext = true,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final Future<void> Function() onNext;
  final bool showNext;

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
          if (!widget.showNext)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
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
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: enemy.rank.color),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: enemy.rank.color,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${enemy.maxHealth} HP',
                              style: TextStyle(
                                color: enemy.rank.color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 18),
                            RewardChestBadge(rank: enemy.rank, count: 1),
                          ],
                        ),
                        const SizedBox(height: 10),
                        EnemyObjectivePreview(enemy: enemy),
                      ],
                    ),
                  ),
                  if (widget.showNext &&
                      enemy.alterations.contains('Première Frappe')) ...[
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
                  if (widget.showNext)
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
                  child: Image.asset(
                    enemy.defeated ? enemy.cardAsset : enemy.rank.asset,
                    fit: BoxFit.cover,
                  ),
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
    if (enemy.profileKey == 'naraxus') {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xffb91622),
          border: Border.all(color: heroAccent, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffd51f2a).withValues(alpha: 0.55),
              blurRadius: 14,
            ),
          ],
        ),
        child: Text(
          'NX',
          style: TextStyle(
            color: heroAccent,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
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
    this.onFinished,
    this.onGameOverHome,
    this.onGameOverHistory,
    super.key,
  });

  final AdventureState adventure;
  final int enemyId;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;
  final VoidCallback? onFinished;
  final VoidCallback? onGameOverHome;
  final VoidCallback? onGameOverHistory;

  @override
  State<FightPage> createState() => _FightPageState();
}

class _FightPageState extends State<FightPage> {
  final Random _random = Random();
  final ScrollController _combatScrollController = ScrollController();
  final GlobalKey _defenseRulesKey = GlobalKey();
  final List<GameDie> _dice = [];
  int _diceToRoll = 6;
  int _rollCount = 0;
  bool _editMode = false;
  bool _rerollOneMode = false;
  int? _editingDieId;
  late CombatPhase _phase;
  bool _upkeepApplied = false;
  bool _heroUpkeepApplied = false;
  bool _specialAttackReady = false;
  bool _specialAttackMode = false;
  bool _aiMode = true;
  bool _showManualExtraDicePhase = false;
  bool _gameOverDialogShown = false;
  int _battleAttackValue = 0;
  int _battleDefenseValue = 0;
  int _battleReturnDamage = 0;
  int _battleLifeSteal = 0;
  int _battleEnemyHeal = 0;
  int _battleCpSteal = 0;
  int _heroAttackCount = 0;
  int _heroAttackTotal = 0;
  int _lastHeroAttack = 0;
  String _lastBattleOutcomeMessage = '';
  final List<String> _battleHeroTokens = [];
  final List<String> _battleMinionTokens = [];
  final List<String> _battleNotes = [];
  final List<String> _naraxusRollHistory = [];

  EnemyNode get enemy => widget.adventure.enemyById(widget.enemyId);

  bool get _isNaraxus => enemy.profileKey == 'naraxus';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _dice.add(GameDie(id: i));
    }
    _phase = enemy.alterations.contains('Première Frappe')
        ? CombatPhase.minionUpkeep
        : CombatPhase.heroUpkeep;
    _configureDiceForPhase(
      autoRollAttack: _aiMode && _phase == CombatPhase.minionAttack,
    );
    if (_phase == CombatPhase.heroUpkeep) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyHeroUpkeep());
    }
  }

  @override
  void dispose() {
    _combatScrollController.dispose();
    super.dispose();
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
              Expanded(
                child: ListView(
                  controller: _combatScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 300),
                  children: [
                    FightStatusPanel(
                      adventure: widget.adventure,
                      enemy: enemy,
                      phase: _phase,
                      naraxusRollHistory: _naraxusRollHistory,
                      onFinish:
                          enemy.health <= 0 ||
                              (_isNaraxus && widget.adventure.health <= 0)
                          ? _finishCombat
                          : null,
                      onChanged: () {
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    EnemyRulesPanel(
                      enemy: enemy,
                      phase: _phase,
                      aiMode: _aiMode,
                      defenseKey: _defenseRulesKey,
                      onAiModeChanged: (value) {
                        setState(() {
                          _aiMode = value;
                          _configureDiceForPhase(
                            autoRollAttack:
                                _aiMode && _phase == CombatPhase.minionAttack,
                          );
                        });
                      },
                    ),
                    if (_aiMode) ...[
                      const SizedBox(height: 12),
                      MinionAiPanel(
                        enemy: enemy,
                        phase: _phase,
                        dice: _dice,
                        adventure: widget.adventure,
                        rollCount: _rollCount,
                        onDetails: _openAdventureDetails,
                        diceToRoll: _diceToRoll,
                        visibleDiceCount: _visibleDiceCount,
                        maxRolls: _maxRolls,
                        editMode: _editMode,
                        rerollOneMode: _rerollOneMode,
                        editingDieId: _editingDieId,
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
                    ] else ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _showManualExtraDicePhase =
                              !_showManualExtraDicePhase,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                          _showManualExtraDicePhase
                              ? 'Hide extra dice phase'
                              : 'Add dice phase',
                        ),
                      ),
                      if (_showManualExtraDicePhase) ...[
                        const SizedBox(height: 8),
                        const ManualExtraDicePhasePanel(),
                      ],
                    ],
                    if (!_aiMode) ...[
                      const SizedBox(height: 12),
                      DicePanel(
                        dice: _dice,
                        diceToRoll: _diceToRoll,
                        visibleDiceCount: _visibleDiceCount,
                        maxDiceCount: _diceMenuMax,
                        rollCount: _rollCount,
                        maxRolls: _maxRolls,
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
                        rollLabel: _phase == CombatPhase.hero
                            ? 'Roll defense'
                            : (_rollCount == 0 ? 'Roll' : 'Reroll'),
                        rollColor: _phase == CombatPhase.hero
                            ? enemy.rank.color
                            : const Color(0xff8f43ff),
                      ),
                    ],
                    if (_specialAttackReady) ...[
                      const SizedBox(height: 12),
                      ImageActionButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: _resolveSpecialAttack,
                      ),
                    ],
                  ],
                ),
              ),
              CombatBottomDock(
                aiMode: _aiMode,
                showResolution: _isBattlePhase,
                aiMessage: _aiMode
                    ? _aiMessageFor(
                        enemy,
                        _phase,
                        _dice,
                        _rollCount,
                        widget.adventure,
                        _lastBattleOutcomeMessage,
                        _heroAttackCount,
                        _lastHeroAttack,
                        _heroAttackTotal,
                      )
                    : '',
                phase: _phase,
                adventure: widget.adventure,
                enemy: enemy,
                upkeepApplied: _upkeepApplied,
                heroUpkeepApplied: _heroUpkeepApplied,
                canAdvancePhase:
                    _phase != CombatPhase.minionAttack &&
                    (_phase != CombatPhase.hero || _battleAttackValue == 0),
                attackValue: _battleAttackValue,
                defenseValue: _battleDefenseValue,
                returnDamage: _battleReturnDamage,
                lifeSteal: _battleLifeSteal,
                enemyHeal: _battleEnemyHeal,
                cpSteal: _battleCpSteal,
                heroTokens: _battleHeroTokens,
                minionTokens: _battleMinionTokens,
                notes: _battleNotes,
                onPhaseChanged: _setPhase,
                onNext: _advancePhase,
                onApplyUpkeep: _applyUpkeep,
                onApplyHeroUpkeep: _applyHeroUpkeep,
                onAttackChanged: (delta) => setState(() {
                  _battleAttackValue = (_battleAttackValue + delta).clamp(
                    0,
                    99,
                  );
                }),
                onDefenseChanged: (delta) => setState(() {
                  _battleDefenseValue = (_battleDefenseValue + delta).clamp(
                    0,
                    99,
                  );
                }),
                onApply: _applyBattleResolution,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rollDice() {
    if (_rollCount >= _maxRolls) {
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
      if (_isNaraxus) {
        final values = rollable
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .join('/');
        if (values.isNotEmpty) {
          _naraxusRollHistory.add(values);
        }
      }
      _rollCount++;
      widget.adventure.log(
        'Roll $_rollCount: ${rollable.map((die) => die.value).join(', ')}.',
      );
      if (_phase == CombatPhase.minionAttack && _aiMode) {
        _applyMinionDiceStrategy();
      }
      _refreshBattleResolutionFromDice();
      widget.onChanged();
      if (_rollCount == _maxRolls) {
        _specialAttackReady = _shouldResolveSpecialAttack();
      }
    });
  }

  void _openAdventureDetails() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdventureDetailsPage(
          adventure: widget.adventure,
          combatEnemy: enemy,
          combatPhase: _phase,
          combatDice: _dice,
          aiMode: _aiMode,
          rollCount: _rollCount,
        ),
      ),
    );
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
        _refreshBattleResolutionFromDice();
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
      _refreshBattleResolutionFromDice();
      widget.adventure.log('Die ${die.id + 1} changed to $face.');
      widget.onChanged();
    });
  }

  void _setPhase(CombatPhase phase) {
    setState(() {
      if (_phase != phase && phase != CombatPhase.heroUpkeep) {
        _heroUpkeepApplied = false;
      }
      _phase = phase;
      _upkeepApplied = false;
      _specialAttackReady = false;
      _specialAttackMode = false;
      _resetBattleResolution();
      _configureDiceForPhase(
        autoRollAttack: _aiMode && phase == CombatPhase.minionAttack,
      );
    });
    if (phase == CombatPhase.heroUpkeep) {
      _applyHeroUpkeep();
    }
    if (phase == CombatPhase.hero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _defenseRulesKey.currentContext;
        if (context == null) {
          return;
        }
        Scrollable.ensureVisible(
          context,
          alignment: 0.02,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _advancePhase() {
    final next = switch (_phase) {
      CombatPhase.heroUpkeep => CombatPhase.hero,
      CombatPhase.hero => CombatPhase.minionUpkeep,
      CombatPhase.minionUpkeep => CombatPhase.minionAttack,
      CombatPhase.minionAttack => CombatPhase.heroUpkeep,
    };
    _setPhase(next);
  }

  void _configureDiceForPhase({required bool autoRollAttack}) {
    _resetDice();
    if (_phase == CombatPhase.hero) {
      _diceToRoll = enemy.defenseDice.clamp(0, 5);
    } else if (_phase == CombatPhase.heroUpkeep ||
        _phase == CombatPhase.minionUpkeep) {
      _diceToRoll = 0;
    } else if (_phase == CombatPhase.minionAttack) {
      _diceToRoll = _isNaraxus ? 1 : 5;
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

  int get _visibleDiceCount {
    if (_specialAttackMode) {
      return 1;
    }
    if (_phase == CombatPhase.minionAttack) {
      return _isNaraxus ? 1 : 5;
    }
    return _diceToRoll.clamp(0, 5);
  }

  int get _diceMenuMax {
    if (_phase == CombatPhase.hero) {
      return 5;
    }
    return _visibleDiceCount.clamp(0, 5);
  }

  int get _maxRolls => _phase == CombatPhase.hero || _isNaraxus ? 1 : 3;

  bool get _isBattlePhase =>
      _phase == CombatPhase.hero || _phase == CombatPhase.minionAttack;

  void _resetBattleResolution() {
    _battleAttackValue = 0;
    _battleDefenseValue = 0;
    _battleReturnDamage = 0;
    _battleLifeSteal = 0;
    _battleEnemyHeal = 0;
    _battleCpSteal = 0;
    _battleHeroTokens.clear();
    _battleMinionTokens.clear();
    _battleNotes.clear();
  }

  void _refreshBattleResolutionFromDice() {
    if (_phase == CombatPhase.hero) {
      _resolveMinionDefenseFromDice();
    } else if (_phase == CombatPhase.minionAttack) {
      _resolveMinionAttackFromDice();
    }
  }

  void _resolveMinionDefenseFromDice() {
    final rolled = _dice.where((die) => die.value != null).toList();
    if (rolled.isEmpty) {
      return;
    }
    final counts = _symbolCounts();
    final white = counts[DieSymbol.white] ?? 0;
    final yellow = counts[DieSymbol.yellow] ?? 0;
    final red = counts[DieSymbol.red] ?? 0;
    var prevented = 0;
    var returnDamage = 0;
    var lifeSteal = 0;
    final notes = <String>[];
    final heroTokens = <String>[];

    switch (enemy.profileKey) {
      case 'naraxus':
        final value = rolled.first.value ?? 0;
        prevented = switch (value) {
          1 => 1,
          6 => 5,
          _ => 3,
        };
        notes.add('Naxarus defense: D6 $value prevents $prevented damage.');
      case 'fee':
        if (yellow >= 2) {
          prevented = 3;
          notes.add('Defense: 2 yellow symbols prevent 3 damage.');
        }
      case 'ronin-vagabond':
        final value = rolled.first.value ?? 0;
        returnDamage = (value / 2).ceil();
        notes.add('Defense: returns $returnDamage damage.');
      case 'enchanteur-gobelin':
        if (yellow > 0) {
          returnDamage = 1;
          notes.add('Defense: yellow symbol returns 1 damage.');
        }
        if (red > 0) {
          heroTokens.add('Poison');
          notes.add('Defense: red symbol gives Poison to the hero.');
        }
      case 'archer-de-lombre':
        if (yellow > 0) {
          prevented = 3;
          notes.add('Defense: yellow symbol prevents 3 damage.');
        }
      case 'ombre-feline':
        if (white > 0) {
          heroTokens.add('Hémorragie');
          notes.add('Defense: white symbol gives Hemorragie to the hero.');
        }
      case 'epeiste-egare':
        prevented = yellow;
        returnDamage = white + red;
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
        if (returnDamage > 0) {
          notes.add('Defense: returns $returnDamage damage.');
        }
      case 'elfe-du-chaos':
        if (yellow >= 2) {
          prevented = (_battleAttackValue / 2).ceil();
          notes.add('Defense: 2 yellow symbols prevent half the damage.');
        }
      case 'oni-delirant':
        lifeSteal = yellow;
        if (lifeSteal > 0) {
          notes.add('Defense: steals $lifeSteal HP.');
        }
      default:
        notes.add('Defense rolled. Check the minion card for exact effects.');
    }

    _battleDefenseValue = prevented.clamp(0, 99);
    _battleReturnDamage = returnDamage.clamp(0, 99);
    _battleLifeSteal = lifeSteal.clamp(0, 99);
    _battleEnemyHeal = 0;
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleNotes
      ..clear()
      ..addAll(notes);
  }

  void _resolveMinionAttackFromDice() {
    if (_isNaraxus) {
      _resolveNaraxusAttackFromDice();
      return;
    }
    final result = _currentMinionAttackResult();
    final notes = <String>[];
    final heroTokens = <String>[];
    final minionTokens = <String>[];
    var attack = result?.value ?? 0;
    var lifeSteal = 0;
    var cpSteal = 0;

    if (enemy.profileKey == 'oni-delirant' &&
        _symbolGoalMet(const SymbolGoal(yellow: 4))) {
      notes.add('Attack ready: roll 1 die to choose the Oni effect.');
    } else if (result != null) {
      notes.add(
        result.imparable
            ? 'Attack result: ${result.value} imparable damage.'
            : 'Attack result: ${result.value} damage.',
      );
    } else if (_rollCount > 0) {
      notes.add('No valid attack yet.');
    }

    final values = _dice
        .where((die) => die.value != null)
        .map((die) => die.value!)
        .toList();
    final symbols = _dice
        .where((die) => die.symbol != null)
        .map((die) => die.symbol!)
        .toList();
    final hasThreeSameValue = _hasRepeatedValue(values, 3);
    final hasFourSameSymbol = _hasRepeatedSymbol(symbols, 4);

    switch (enemy.profileKey) {
      case 'fee':
        if (_bestSuiteLength(values) >= 5) {
          cpSteal = 1;
          notes.add('Large suite: steal 1 CP.');
        }
      case 'elfe-du-chaos':
        if (_bestSuiteLength(values) >= 5) {
          heroTokens.add('Ronces');
          notes.add('Large suite: hero receives Ronces.');
        }
      case 'archer-de-lombre':
        if (hasThreeSameValue) {
          heroTokens.add('Silence');
          notes.add('3 identical values: hero receives Silence.');
        }
      case 'ombre-feline':
        if (hasThreeSameValue) {
          heroTokens.add('Hémorragie');
          notes.add('3 identical values: hero receives Hemorragie.');
        }
      case 'ronin-vagabond':
        if (hasFourSameSymbol) {
          minionTokens.add('Riposte');
          notes.add('4 identical symbols: minion gains Riposte.');
        }
      case 'oni-delirant':
        if (_symbolGoalMet(const SymbolGoal(yellow: 4))) {
          attack = 0;
          lifeSteal = 0;
        }
    }

    _battleAttackValue = attack.clamp(0, 99);
    _battleLifeSteal = lifeSteal.clamp(0, 99);
    _battleEnemyHeal = 0;
    _battleCpSteal = cpSteal.clamp(0, 99);
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleMinionTokens
      ..clear()
      ..addAll(minionTokens);
    _battleNotes
      ..clear()
      ..addAll(notes);
  }

  void _resolveNaraxusAttackFromDice() {
    final first = _dice.first.value;
    if (first == null) {
      return;
    }
    final notes = <String>['Naxarus rolls $first.'];
    var attack = 0;
    var enemyHeal = 0;
    final heroTokens = <String>[];

    switch (first) {
      case 1:
        attack = 3;
        enemyHeal = 4;
        _removeRandomEnemyToken();
        notes.add('Swoop: Naxarus removes 1 random token and heals 4 HP.');
        notes.add('Swoop: 3 undefendable damage.');
      case 2:
        attack = 8;
        notes.add('Ember Spark: hero moves top 3 deck cards to discard.');
        notes.add('Ember Spark: 8 damage.');
      case 3:
        final rolls = List.generate(4, (_) => _random.nextInt(6) + 1)..sort();
        attack = rolls.reversed.take(2).fold(0, (sum, value) => sum + value);
        notes.add('Gashing Bite: 4 dice ${rolls.join('/')}.');
        notes.add('Damage equals the 2 highest dice: $attack.');
      case 4:
        attack = 9;
        heroTokens.add('Hoarding');
        notes.add('Hoarding: hero loses 1 die on the next battle roll.');
        notes.add('Hoarding: 9 damage.');
      case 5:
        attack = 8;
        notes.add('Thundering Roar: hero discards 1 card.');
        notes.add('Thundering Roar: 8 undefendable damage.');
      case 6:
        attack = 10;
        final extra = _random.nextInt(6) + 1;
        notes.add("Dragon's Might: 10 damage.");
        notes.add("Dragon's Might extra die: $extra.");
        if (extra >= 5) {
          attack += 3;
          enemyHeal = 4;
          _removeRandomEnemyToken();
          notes.add('Extra 5-6: Swoop also triggers.');
          notes.add(
            'Naxarus removes 1 random token, heals 4 HP, and adds 3 undefendable damage.',
          );
        }
    }

    _battleAttackValue = attack.clamp(0, 99);
    _battleLifeSteal = 0;
    _battleEnemyHeal = enemyHeal.clamp(0, 99);
    _battleCpSteal = 0;
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleMinionTokens.clear();
    _battleNotes
      ..clear()
      ..addAll(notes);
  }

  void _removeRandomEnemyToken() {
    if (enemy.alterations.isEmpty) {
      return;
    }
    enemy.alterations.removeAt(_random.nextInt(enemy.alterations.length));
  }

  _AttackDamage? _currentMinionAttackResult() {
    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        _AttackDamage? result;
        for (final goal in enemy.attackPlan.goals) {
          if (_symbolGoalMet(goal)) {
            result = _damageForSymbolGoal(enemy, goal);
          }
        }
        return result;
      case MinionAttackStyle.suite:
        final values = _dice
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .toList();
        return _suiteDamage(enemy, _bestSuiteLength(values));
      case MinionAttackStyle.none:
        return null;
    }
  }

  bool _hasRepeatedValue(List<int> values, int count) {
    final counts = <int, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.values.any((value) => value >= count);
  }

  bool _hasRepeatedSymbol(List<DieSymbol> symbols, int count) {
    final counts = <DieSymbol, int>{};
    for (final symbol in symbols) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
    return counts.values.any((value) => value >= count);
  }

  void _applyBattleResolution() {
    if (!_isBattlePhase) {
      return;
    }
    late final CombatPhase nextPhase;
    setState(() {
      final netDamage = max(0, _battleAttackValue - _battleDefenseValue);
      if (_phase == CombatPhase.hero) {
        enemy.health = (enemy.health - netDamage).clamp(0, 99);
        if (_battleReturnDamage > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleReturnDamage,
          );
        }
        if (_battleLifeSteal > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleLifeSteal,
          );
          enemy.health = (enemy.health + _battleLifeSteal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleEnemyHeal > 0) {
          enemy.health = (enemy.health + _battleEnemyHeal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        enemy.alterations.addAll(_battleMinionTokens);
        widget.adventure.alterations.addAll(_battleHeroTokens);
        widget.adventure.log(
          'Hero battle applied: $netDamage damage to ${enemy.label}.',
        );
        if (_battleAttackValue == 0) {
          _lastBattleOutcomeMessage =
              '${widget.adventure.hero.label} attack failed.';
        } else {
          _lastBattleOutcomeMessage =
              '${widget.adventure.hero.label} dealt $_battleAttackValue damage. '
              '${enemy.label} prevented $_battleDefenseValue damage. '
              'Net damage: $netDamage.'
              '${_battleReturnDamage > 0 ? ' Return damage: $_battleReturnDamage.' : ''}'
              '${_battleLifeSteal > 0 ? ' Life steal: $_battleLifeSteal.' : ''}'
              '${_battleHeroTokens.isNotEmpty ? ' Hero receives ${_battleHeroTokens.join(', ')}.' : ''}'
              '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}';
        }
        _heroAttackCount++;
        _heroAttackTotal += _battleAttackValue;
        _lastHeroAttack = _battleAttackValue;
        nextPhase = CombatPhase.minionUpkeep;
      } else {
        widget.adventure.setHeroHealth(widget.adventure.health - netDamage);
        if (_battleLifeSteal > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleLifeSteal,
          );
          enemy.health = (enemy.health + _battleLifeSteal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleEnemyHeal > 0) {
          enemy.health = (enemy.health + _battleEnemyHeal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleCpSteal > 0) {
          widget.adventure.setHeroPc(
            widget.adventure.combatPoints - _battleCpSteal,
          );
          enemy.combatPoints = (enemy.combatPoints + _battleCpSteal).clamp(
            0,
            99,
          );
        }
        widget.adventure.alterations.addAll(_battleHeroTokens);
        enemy.alterations.addAll(_battleMinionTokens);
        widget.adventure.log(
          'Minion battle applied: $netDamage damage to hero.',
        );
        _lastBattleOutcomeMessage =
            '${enemy.label} dealt $_battleAttackValue damage. '
            '${widget.adventure.hero.label} prevented $_battleDefenseValue damage. '
            'Net damage: $netDamage.'
            '${_battleHeroTokens.isNotEmpty ? ' ${widget.adventure.hero.label} receives ${_battleHeroTokens.join(', ')}.' : ''}'
            '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}'
            '${_battleEnemyHeal > 0 ? ' ${enemy.label} heals $_battleEnemyHeal HP.' : ''}'
            '${_battleCpSteal > 0 ? ' ${enemy.label} steals $_battleCpSteal CP.' : ''}';
        nextPhase = CombatPhase.heroUpkeep;
      }
      widget.onChanged();
    });
    _maybeShowGameOverDialog();
    if (widget.adventure.health <= 0 || (_isNaraxus && enemy.health <= 0)) {
      return;
    }
    _setPhase(nextPhase);
  }

  void _applyHeroUpkeep() {
    if (!mounted || _heroUpkeepApplied || _phase != CombatPhase.heroUpkeep) {
      return;
    }
    setState(() {
      _heroUpkeepApplied = true;
      widget.adventure.setHeroPc(
        widget.adventure.combatPoints + GameEngine.combatPointStartGain(),
      );
      widget.adventure.log('Hero upkeep: +1 CP.');
      widget.onChanged();
    });
  }

  void _applyUpkeep() {
    if (_upkeepApplied) {
      return;
    }
    setState(() {
      final outcome = GameEngine.minionUpkeep(
        tokens: enemy.alterations,
        rollD6: () => _random.nextInt(6) + 1,
      );
      final cpDelta = _isNaraxus ? 0 : outcome.cpDelta;
      enemy.combatPoints = (enemy.combatPoints + cpDelta).clamp(0, 99);
      enemy.health = (enemy.health + outcome.healthDelta).clamp(0, 99);
      for (final token in outcome.removedTokens) {
        enemy.alterations.remove(token);
      }
      _upkeepApplied = true;
      widget.adventure.log(
        _isNaraxus
            ? 'Naxarus upkeep: ${outcome.log.replaceFirst('+1 CP', 'no CP gain')}.'
            : 'Minion upkeep: ${outcome.log}.',
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
    final decision = MinionDiceEngine.chooseSuiteHold(_dice);
    final needed = <int, int>{for (final value in decision.values) value: 1};
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
    _maybeShowGameOverDialog();
  }

  void _finishCombat() {
    if (_isNaraxus) {
      widget.onFinished?.call();
      return;
    }
    widget.adventure.completeCombat(enemy);
    widget.onChanged();
    if (enemy.defeated && widget.adventure.health > 0) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pop(false);
  }

  void _maybeShowGameOverDialog() {
    if (_gameOverDialogShown || !mounted) {
      return;
    }
    final isGameOver =
        widget.adventure.health <= 0 || (_isNaraxus && enemy.health <= 0);
    if (!isGameOver) {
      return;
    }
    _gameOverDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final action = await showDialog<_GameOverAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(_isNaraxus ? 'Battle finished' : 'Run finished'),
          content: Text(
            widget.adventure.health <= 0
                ? '${widget.adventure.hero.label} has no HP left.'
                : '${enemy.label} has no HP left.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_GameOverAction.newGame),
              child: const Text('New game'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_GameOverAction.history),
              child: const Text('History'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_GameOverAction.quit),
              child: const Text('Quit'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) {
        return;
      }
      switch (action) {
        case _GameOverAction.newGame:
          if (_isNaraxus) {
            widget.onFinished?.call();
          } else {
            widget.onGameOverHome?.call();
          }
        case _GameOverAction.history:
          if (_isNaraxus) {
            widget.onGameOverHistory?.call();
          } else {
            widget.onGameOverHistory?.call();
          }
        case _GameOverAction.quit:
          if (_isNaraxus) {
            widget.onFinished?.call();
          } else {
            widget.onGameOverHome?.call();
          }
          SystemNavigator.pop();
      }
    });
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

enum _GameOverAction { newGame, history, quit }

class CompactItemStrip extends StatelessWidget {
  const CompactItemStrip({
    required this.label,
    required this.emptyText,
    required this.items,
    required this.accent,
    required this.background,
    required this.border,
    this.compactDuplicates = true,
    this.leading,
    this.trailing,
    super.key,
  });

  final String label;
  final String emptyText;
  final List<String> items;
  final Color accent;
  final Color background;
  final Color border;
  final bool compactDuplicates;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayItems = compactDuplicates
        ? _compactItemModels(items)
        : items
              .map(
                (value) => CompactItemModel(
                  label: value,
                  tooltip: value,
                  rewardCardColor: _rewardCardColor(value),
                ),
              )
              .toList();
    final displayLabel = items.isEmpty ? emptyText : '';
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
          final showLabel = items.isEmpty || constraints.maxWidth >= 190;

          return Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              if (showLabel && displayLabel.isNotEmpty) ...[
                Text(
                  displayLabel,
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(item.tooltip)),
                                    );
                                  },
                                  child: Tooltip(
                                    message: item.tooltip,
                                    child: item.rewardCardColor == null
                                        ? CompactItemBadge(
                                            value: item.label,
                                            color: accent,
                                          )
                                        : RewardCardBadge(
                                            color: item.rewardCardColor!,
                                            tooltip: item.tooltip,
                                          ),
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
  const CompactItemModel({
    required this.label,
    required this.tooltip,
    this.rewardCardColor,
  });

  final String label;
  final String tooltip;
  final Color? rewardCardColor;
}

class RewardCardBadge extends StatelessWidget {
  const RewardCardBadge({
    required this.color,
    required this.tooltip,
    super.key,
  });

  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.style, color: color, size: 20),
          const Positioned(
            right: 3,
            bottom: 2,
            child: Icon(Icons.add_circle, color: Colors.white, size: 10),
          ),
        ],
      ),
    );
  }
}

class CompactItemBadge extends StatelessWidget {
  const CompactItemBadge({required this.value, required this.color, super.key});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 30 + max(0, value.length - 2) * 8),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 5),
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
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
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
          rewardCardColor: _rewardCardColor(entry.key),
        ),
      )
      .toList();
}

Color? _rewardCardColor(String value) {
  final normalized = value.toLowerCase();
  if (!normalized.contains('carte')) {
    return null;
  }
  if (normalized.contains('verte')) {
    return EnemyRank.green.color;
  }
  if (normalized.contains('bleue')) {
    return EnemyRank.blue.color;
  }
  if (normalized.contains('violette')) {
    return EnemyRank.violet.color;
  }
  if (normalized.contains('orange')) {
    return EnemyRank.orange.color;
  }
  return Colors.white;
}

String _compactItemCode(String value, [int count = 1]) {
  if (value == 'Première Frappe') {
    return count <= 1 ? '1ST' : '1STx$count';
  }
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
  const EnemyRulesPanel({
    required this.enemy,
    required this.phase,
    required this.aiMode,
    required this.onAiModeChanged,
    this.defenseKey,
    super.key,
  });

  final EnemyNode enemy;
  final CombatPhase phase;
  final bool aiMode;
  final ValueChanged<bool> onAiModeChanged;
  final Key? defenseKey;

  @override
  State<EnemyRulesPanel> createState() => _EnemyRulesPanelState();
}

class _EnemyRulesPanelState extends State<EnemyRulesPanel> {
  bool _showAttack = false;
  bool _showDefense = false;

  EnemyNode get enemy => widget.enemy;

  @override
  void initState() {
    super.initState();
    _showDefense = widget.phase == CombatPhase.hero;
  }

  @override
  void didUpdateWidget(covariant EnemyRulesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase && widget.phase == CombatPhase.hero) {
      _showDefense = true;
    }
  }

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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    enemy.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: enemy.rank.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AiModeSwitch(
                enabled: widget.aiMode,
                color: enemy.rank.color,
                onChanged: widget.onAiModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.aiMode)
            Column(
              children: [
                _CollapsibleRulesLine(
                  label: 'Attack',
                  icon: Icons.gps_fixed,
                  color: enemy.rank.color,
                  trailing: AttackObjectiveInline(enemy: enemy),
                  expanded: _showAttack,
                  onTap: () => setState(() => _showAttack = !_showAttack),
                  child: MinionAttackSummary(enemy: enemy),
                ),
                const SizedBox(height: 8),
                _CollapsibleRulesLine(
                  key: widget.defenseKey,
                  label: 'Defense',
                  icon: Icons.shield,
                  color: enemy.rank.color,
                  trailing: DefenseDiceInline(count: enemy.defenseDice),
                  expanded: _showDefense,
                  onTap: () => setState(() => _showDefense = !_showDefense),
                  child: MinionDefenseSummary(enemy: enemy),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Attack',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                MinionAttackSummary(enemy: enemy),
                const SizedBox(height: 10),
                const Text(
                  'Defense',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                MinionDefenseSummary(enemy: enemy),
              ],
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

class _AiModeSwitch extends StatelessWidget {
  const _AiModeSwitch({
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStatePropertyAll(BorderSide(color: color)),
      ),
      segments: const [
        ButtonSegment(value: true, label: Text('AI')),
        ButtonSegment(value: false, label: Text('Manual')),
      ],
      selected: {enabled},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _CollapsibleRulesLine extends StatelessWidget {
  const _CollapsibleRulesLine({
    required this.label,
    required this.icon,
    required this.color,
    required this.trailing,
    required this.expanded,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Widget trailing;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: expanded ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Flexible(child: trailing),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: child,
            ),
        ],
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

class EnemyObjectivePreview extends StatelessWidget {
  const EnemyObjectivePreview({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Roll target',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: switch (enemy.attackPlan.style) {
            MinionAttackStyle.suite => const SuiteGoalView(length: 4),
            MinionAttackStyle.symbols => SymbolGoalView(
              goal: enemy.attackPlan.goals.isEmpty
                  ? const SymbolGoal()
                  : enemy.attackPlan.goals.first,
            ),
            MinionAttackStyle.none => const Text('--'),
          },
        ),
      ],
    );
  }
}

class AttackObjectiveInline extends StatelessWidget {
  const AttackObjectiveInline({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: switch (enemy.attackPlan.style) {
          MinionAttackStyle.suite => const SuiteGoalView(length: 3),
          MinionAttackStyle.symbols => SymbolGoalView(
            goal: enemy.attackPlan.goals.isEmpty
                ? const SymbolGoal()
                : enemy.attackPlan.goals.first,
          ),
          MinionAttackStyle.none => const Text('--'),
        },
      ),
    );
  }
}

class DefenseDiceInline extends StatelessWidget {
  const DefenseDiceInline({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 3,
        children: [
          for (var i = 0; i < count.clamp(0, 6); i++)
            const SuiteGoalPip(size: 24),
        ],
      ),
    );
  }
}

class SuiteGoalPip extends StatelessWidget {
  const SuiteGoalPip({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class RewardChestBadge extends StatelessWidget {
  const RewardChestBadge({required this.rank, required this.count, super.key});

  final EnemyRank rank;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count > 1) {
      return Wrap(
        spacing: 4,
        children: [
          for (var i = 0; i < count; i++)
            RewardChestBadge(rank: rank, count: 1),
        ],
      );
    }
    return Container(
      width: 34,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: rank.color, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.inventory_2, color: rank.color, size: 24),
          if (count > 1)
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
        ],
      ),
    );
  }
}

class MinionDefenseSummary extends StatelessWidget {
  const MinionDefenseSummary({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    final lines = _defenseEffectLines(enemy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.isEmpty
          ? [
              Text(
                _compactDefenseText(enemy.defense),
                style: const TextStyle(height: 1.25),
              ),
            ]
          : lines,
    );
  }
}

List<Widget> _defenseEffectLines(EnemyNode enemy) {
  final text = enemy.defense.toLowerCase();
  final lines = <Widget>[];

  void symbol(SymbolGoal goal, List<Widget> result) {
    lines.add(
      _DefenseEffectLine(
        left: SymbolGoalView(goal: goal),
        right: result,
      ),
    );
  }

  void dieValueLine(int dieValue, List<Widget> result) {
    lines.add(
      _DefenseEffectLine(
        left: DieValueBadge(value: dieValue),
        right: result,
      ),
    );
  }

  switch (enemy.profileKey) {
    case 'naraxus':
      dieValueLine(1, const [PreventBadge(value: 1)]);
      for (final dieValue in [2, 3, 4, 5]) {
        dieValueLine(dieValue, const [PreventBadge(value: 3)]);
      }
      dieValueLine(6, const [PreventBadge(value: 5)]);
      return lines;
    case 'fee':
      symbol(const SymbolGoal(yellow: 2), const [PreventBadge(value: 3)]);
      return lines;
    case 'ronin-vagabond':
      dieValueLine(1, const [DamageBadge(value: 1, imparable: false)]);
      dieValueLine(2, const [DamageBadge(value: 1, imparable: false)]);
      dieValueLine(3, const [DamageBadge(value: 2, imparable: false)]);
      dieValueLine(4, const [DamageBadge(value: 2, imparable: false)]);
      dieValueLine(5, const [DamageBadge(value: 3, imparable: false)]);
      dieValueLine(6, const [DamageBadge(value: 3, imparable: false)]);
      return lines;
    case 'enchanteur-gobelin':
      symbol(const SymbolGoal(yellow: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'PO', color: enemy.rank.color),
      ]);
      return lines;
    case 'archer-de-lombre':
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 3)]);
      return lines;
    case 'ombre-feline':
      symbol(const SymbolGoal(white: 1), [
        TokenBadge(label: 'HEM', color: enemy.rank.color),
      ]);
      return lines;
    case 'epeiste-egare':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(red: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 1)]);
      return lines;
    case 'elfe-du-chaos':
      symbol(const SymbolGoal(yellow: 2), const [PreventBadge(value: 1)]);
      lines.add(
        const Text(
          'Prevents half the incoming damage, rounded up.',
          style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
        ),
      );
      return lines;
    case 'oni-delirant':
      symbol(const SymbolGoal(yellow: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
      ]);
      return lines;
  }

  final preventMatch = RegExp(
    r'previent ([0-9]+)|prevent ([0-9]+)',
  ).firstMatch(text);
  final damageMatch = RegExp(
    r'inflige ([0-9]+)|deal ([0-9]+)',
  ).firstMatch(text);
  final number =
      preventMatch?.group(1) ??
      preventMatch?.group(2) ??
      damageMatch?.group(1) ??
      damageMatch?.group(2);
  final value = int.tryParse(number ?? '');
  if (text.contains('jaune') || text.contains('yellow')) {
    symbol(
      SymbolGoal(
        yellow: text.contains('2 yellow') || text.contains('2 jaunes') ? 2 : 1,
      ),
      [
        if (value != null && preventMatch != null)
          PreventBadge(value: value)
        else if (value != null)
          DamageBadge(value: value, imparable: false)
        else
          Text(_compactDefenseText(enemy.defense)),
      ],
    );
  } else if (text.contains('rouge') || text.contains('red')) {
    symbol(const SymbolGoal(red: 1), [
      if (value != null && preventMatch != null)
        PreventBadge(value: value)
      else if (value != null)
        DamageBadge(value: value, imparable: false)
      else
        Text(_compactDefenseText(enemy.defense)),
    ]);
  }
  return lines;
}

class _DefenseEffectLine extends StatelessWidget {
  const _DefenseEffectLine({required this.left, required this.right});

  final Widget left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(width: 116, child: left),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: right,
            ),
          ),
        ],
      ),
    );
  }
}

class CombatBottomDock extends StatelessWidget {
  const CombatBottomDock({
    required this.aiMode,
    required this.showResolution,
    required this.aiMessage,
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.upkeepApplied,
    required this.heroUpkeepApplied,
    required this.canAdvancePhase,
    required this.attackValue,
    required this.defenseValue,
    required this.returnDamage,
    required this.lifeSteal,
    required this.enemyHeal,
    required this.cpSteal,
    required this.heroTokens,
    required this.minionTokens,
    required this.notes,
    required this.onPhaseChanged,
    required this.onNext,
    required this.onApplyUpkeep,
    required this.onApplyHeroUpkeep,
    required this.onAttackChanged,
    required this.onDefenseChanged,
    required this.onApply,
    super.key,
  });

  final bool aiMode;
  final bool showResolution;
  final String aiMessage;
  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;
  final bool canAdvancePhase;
  final int attackValue;
  final int defenseValue;
  final int returnDamage;
  final int lifeSteal;
  final int enemyHeal;
  final int cpSteal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final List<String> notes;
  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;
  final ValueChanged<int> onAttackChanged;
  final ValueChanged<int> onDefenseChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final isHeroBattle = phase == CombatPhase.hero;
    final attackColor = isHeroBattle ? heroAccent : enemy.rank.color;
    final defenseColor = isHeroBattle ? enemy.rank.color : heroAccent;
    final chatAccent =
        phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
        ? heroAccent
        : enemy.rank.color;
    final tokenText = [
      if (heroTokens.isNotEmpty) 'Hero: ${heroTokens.join(', ')}',
      if (minionTokens.isNotEmpty) 'Minion: ${minionTokens.join(', ')}',
      if (returnDamage > 0) 'Return damage: $returnDamage',
      if (lifeSteal > 0) 'Life steal: $lifeSteal',
      if (enemyHeal > 0) 'Enemy heals: $enemyHeal',
      if (cpSteal > 0) 'CP steal: $cpSteal',
      ...notes,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xf2121212),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aiMode) ...[
            Container(
              constraints: const BoxConstraints(minHeight: 54, maxHeight: 260),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: chatAccent.withValues(alpha: 0.7)),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _battleChatText(aiMessage, tokenText),
                  style: const TextStyle(height: 1.25),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (showResolution) ...[
            Row(
              children: [
                Expanded(
                  child: _BattleCounter(
                    label: 'ATK',
                    value: attackValue,
                    color: attackColor,
                    onChanged: onAttackChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BattleCounter(
                    label: 'DEF',
                    value: defenseValue,
                    color: defenseColor,
                    onChanged: onDefenseChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 52,
                  child: FilledButton(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          TurnPhasePanel(
            phase: phase,
            adventure: adventure,
            enemy: enemy,
            upkeepApplied: upkeepApplied,
            heroUpkeepApplied: heroUpkeepApplied,
            canAdvance: canAdvancePhase,
            onPhaseChanged: onPhaseChanged,
            onNext: onNext,
            onApplyUpkeep: onApplyUpkeep,
            onApplyHeroUpkeep: onApplyHeroUpkeep,
          ),
        ],
      ),
    );
  }
}

String _battleChatText(String aiMessage, List<String> effects) {
  final lines = [
    if (aiMessage.trim().isNotEmpty) aiMessage.trim(),
    if (effects.isNotEmpty) effects.join('\n'),
  ];
  return lines.isEmpty ? 'Manual battle resolution.' : lines.join('\n');
}

class _BattleCounter extends StatelessWidget {
  const _BattleCounter({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            color: color,
            onPressed: () => onChanged(-1),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            color: color,
            onPressed: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class MinionAiPanel extends StatelessWidget {
  const MinionAiPanel({
    required this.enemy,
    required this.phase,
    required this.dice,
    required this.adventure,
    required this.rollCount,
    required this.onDetails,
    required this.diceToRoll,
    required this.visibleDiceCount,
    required this.maxRolls,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.onRoll,
    required this.onTapDie,
    required this.onSelectFace,
    required this.onValidateEdit,
    required this.onToggleEdit,
    required this.onToggleRerollOne,
    super.key,
  });

  final EnemyNode enemy;
  final CombatPhase phase;
  final List<GameDie> dice;
  final AdventureState adventure;
  final int rollCount;
  final VoidCallback onDetails;
  final int diceToRoll;
  final int visibleDiceCount;
  final int maxRolls;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;

  @override
  Widget build(BuildContext context) {
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 5)).toList()
      ..sort(_compareDice);
    final editingDie = editingDieId == null
        ? null
        : dice.firstWhere((die) => die.id == editingDieId);
    final isDefensePhase = phase == CombatPhase.hero;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.casino, color: enemy.rank.color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              if (enemy.profileKey != 'naraxus') ...[
                Text(
                  '$rollCount/$maxRolls',
                  style: TextStyle(
                    color: enemy.rank.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: 'Run log',
                onPressed: onDetails,
                icon: const Icon(Icons.receipt_long),
                color: heroAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleDice.isNotEmpty || isDefensePhase) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final die in visibleDice)
                  DieTile(
                    die: die,
                    onTap: () => onTapDie(die),
                    highlight: die.reserved || editingDieId == die.id,
                    highlightColor: editingDieId == die.id
                        ? heroAccent
                        : enemy.rank.color,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (visibleDice.isNotEmpty || isDefensePhase) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: enemy.rank.color,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: rollCount < maxRolls && diceToRoll > 0 ? onRoll : null,
              icon: Icon(isDefensePhase ? Icons.shield : Icons.casino),
              label: Text(
                isDefensePhase
                    ? 'Roll defense'
                    : (rollCount == 0 ? 'Roll' : 'Reroll'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: heroAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: onToggleEdit,
                    icon: const Icon(Icons.tune),
                    label: Text(editMode ? 'Stop edit' : 'Edit a die'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: heroAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: onToggleRerollOne,
                    icon: const Icon(Icons.refresh),
                    label: Text(rerollOneMode ? 'Choose' : 'Reroll a die'),
                  ),
                ),
              ],
            ),
            if (editingDie != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Edit die ${editingDie.id + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  for (final face in [1, 2, 3, 4, 5, 6])
                    if (face != editingDie.value)
                      ActionChip(
                        label: Text(face.toString()),
                        onPressed: () => onSelectFace(editingDie, face),
                      ),
                  FilledButton(
                    onPressed: onValidateEdit,
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String _aiMessageFor(
  EnemyNode enemy,
  CombatPhase phase,
  List<GameDie> dice,
  int rollCount,
  AdventureState adventure,
  String lastBattleOutcome,
  int heroAttackCount,
  int lastHeroAttack,
  int heroAttackTotal,
) {
  return switch (phase) {
    CombatPhase.heroUpkeep => _heroUpkeepAiMessage(
      adventure,
      lastBattleOutcome,
    ),
    CombatPhase.hero => _heroBattleAiMessage(
      enemy,
      adventure,
      heroAttackCount,
      lastHeroAttack,
      heroAttackTotal,
    ),
    CombatPhase.minionUpkeep => _minionUpkeepAiMessage(
      enemy,
      lastBattleOutcome,
    ),
    CombatPhase.minionAttack => _minionAttackAiMessage(
      enemy,
      dice,
      rollCount,
      adventure,
    ),
  };
}

String _combatIntroLine(AdventureState adventure, EnemyNode enemy) {
  return 'Battle: ${adventure.hero.label} versus ${enemy.label}.';
}

String _heroUpkeepAiMessage(
  AdventureState adventure,
  String lastBattleOutcome,
) {
  final lines = <String>[
    if (lastBattleOutcome.isNotEmpty) lastBattleOutcome,
    'Start of turn for ${adventure.hero.label}.',
    '${adventure.hero.label} gains 1 CP and is now at ${adventure.combatPoints} CP.',
    _tokenUpkeepSummary(
      owner: adventure.hero.label,
      tokens: adventure.alterations,
      isHero: true,
    ),
    if (!adventure.alterations.contains('Commotion'))
      '${adventure.hero.label} should draw 1 card before the battle phase.',
  ];
  return lines.join('\n');
}

String _minionUpkeepAiMessage(EnemyNode enemy, String lastBattleOutcome) {
  final lines = <String>[
    if (lastBattleOutcome.isNotEmpty) lastBattleOutcome,
    'Start of turn for ${enemy.label}.',
    enemy.profileKey == 'naraxus'
        ? 'Naxarus does not gain CP; the dragon has unlimited CP.'
        : '${enemy.label} gains 1 CP and is now at ${enemy.combatPoints} CP.',
    _tokenUpkeepSummary(
      owner: enemy.label,
      tokens: enemy.alterations,
      isHero: false,
    ),
  ];
  return lines.join('\n');
}

String _heroBattleAiMessage(
  EnemyNode enemy,
  AdventureState adventure,
  int heroAttackCount,
  int lastHeroAttack,
  int heroAttackTotal,
) {
  final intro = heroAttackCount == 0
      ? '${adventure.hero.label} enters the fight. How much damage will the first attack deal?'
      : heroAttackCount == 1
      ? 'The first attack dealt $lastHeroAttack damage. Can ${adventure.hero.label} do better?'
      : '${adventure.hero.label} averages ${(heroAttackTotal / heroAttackCount).toStringAsFixed(1)} damage per attack. Can this turn beat that?';
  return [
    _combatIntroLine(adventure, enemy),
    intro,
    '${enemy.label} is waiting for the hero attack result.',
    'If the attack is defendable, roll ${enemy.label} defense.',
    'Maximum prevention: ${_maxDefensePrevention(enemy)} damage. Maximum return damage: ${_maxDefenseReturnDamage(enemy)} damage.',
    if (adventure.alterations.contains('Silence'))
      'Silence is active: ${adventure.hero.label} cannot validate a suite this turn.',
  ].join('\n');
}

String _tokenUpkeepSummary({
  required String owner,
  required List<String> tokens,
  required bool isHero,
}) {
  if (tokens.isEmpty) {
    return 'No upkeep token found. The game continues.';
  }
  final counts = _tokenCounts(tokens);
  final lines = <String>[];
  var poisonDamage = 0;
  for (final entry in counts.entries) {
    final token = entry.key;
    final count = entry.value;
    final lower = token.toLowerCase();
    if (lower.contains('poison')) {
      poisonDamage += count;
      lines.add('$count Poison token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        '$owner will receive ${List.filled(count, '1 poison damage').join(' and ')}. Total: $count HP will be removed at the end of upkeep.',
      );
    } else if (lower.contains('hémorragie') || lower.contains('hemorragie')) {
      lines.add('$count Bleed token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        isHero
            ? '$owner must roll for Bleed during upkeep, then update HP and tokens.'
            : 'I have Bleed. I am ready to roll to see if the token stays; confirm with OK when this token is resolved.',
      );
    } else if (lower.contains('brûlure') || lower.contains('brulure')) {
      lines.add('$count Burn token${count > 1 ? 's' : ''} found on $owner.');
      lines.add('Resolve Burn damage before moving to battle.');
    }
  }
  if (lines.isEmpty) {
    return 'Tokens are present, but none are automated for upkeep yet.';
  }
  if (poisonDamage > 0) {
    lines.add('The upkeep damage may defeat $owner if HP is too low.');
  }
  return lines.join('\n');
}

Map<String, int> _tokenCounts(List<String> tokens) {
  final counts = <String, int>{};
  for (final token in tokens) {
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return counts;
}

String _minionAttackAiMessage(
  EnemyNode enemy,
  List<GameDie> dice,
  int rollCount,
  AdventureState adventure,
) {
  final rolled = dice.where((die) => die.value != null).toList();
  if (enemy.profileKey == 'naraxus') {
    return _naraxusAiMessage(enemy, rolled, adventure);
  }
  if (rollCount == 0 || rolled.isEmpty) {
    if (enemy.attackPlan.style == MinionAttackStyle.suite) {
      return '${enemy.label} battle phase.\n'
          '${enemy.label} has ${enemy.health} HP, ${enemy.combatPoints} CP and ${enemy.alterations.length} token(s).\n'
          'I use ${enemy.attacks.first}.\n'
          'First target: micro suite. If it succeeds, I will try to improve.';
    }
    return '${enemy.label} battle phase.\n'
        '${enemy.label} has ${enemy.health} HP, ${enemy.combatPoints} CP and ${enemy.alterations.length} token(s).\n'
        'I use ${enemy.attacks.first}.\n'
        'First target: the smallest valid symbol attack.';
  }

  final values = rolled.map((die) => die.value!).toList()..sort();
  final kept =
      rolled.where((die) => die.reserved).map((die) => die.value!).toList()
        ..sort();

  if (enemy.attackPlan.style == MinionAttackStyle.suite) {
    final decision = MinionDiceEngine.chooseSuiteHold(dice);
    final best = _bestSuiteLength(values);
    final damage = _suiteDamage(enemy, best);
    final rollLabel = _rollLabel(rollCount);
    final damageText = damage == null
        ? ''
        : '\nI deal ${damage.value}${damage.imparable ? ' undefendable' : ''} damage with this roll.';
    if (best >= 5) {
      return rollCount >= 3
          ? 'After my 3 attack rolls, I deal ${damage?.value ?? 0} damage with the large suite ${_bestSuiteValues(values, 5).join('/')}.\n'
                '${adventure.hero.label} may still try to make my attack fail before pressing OK.'
          : 'On my $rollLabel roll, large suite validated with ${_bestSuiteValues(values, 5).join('/')}.$damageText';
    }
    if (best == 4) {
      return rollCount >= 3
          ? 'After my 3 attack rolls, I deal ${damage?.value ?? 0} damage with the small suite ${_bestSuiteValues(values, 4).join('/')}.\n'
                '${adventure.hero.label} must perform a defensive phase if the attack is defendable.'
          : 'On my $rollLabel roll, small suite validated with ${_bestSuiteValues(values, 4).join('/')}.$damageText\n'
                'I can hit, then try to improve if one roll remains.';
    }
    if (best == 3) {
      return rollCount >= 3
          ? 'After my 3 attack rolls, I deal ${damage?.value ?? 0} damage with the micro suite ${_bestSuiteValues(values, 3).join('/')}.\n'
                '${adventure.hero.label} must perform a defensive phase if the attack is defendable.'
          : 'On my $rollLabel roll, micro suite validated.\n'
                'I keep ${kept.join('/')} and can keep rolling to improve.$damageText';
    }
    return 'On my $rollLabel roll, I deal no damage yet.\n'
        '${decision.reason}\n'
        'Kept dice: ${kept.isEmpty ? 'nothing' : kept.join('/')}.';
  }

  final symbolDamage = _bestSymbolAttackDamage(enemy, dice);
  final rollLabel = _rollLabel(rollCount);
  final symbolDamageText = symbolDamage == null
      ? ''
      : '\nI deal ${symbolDamage.value}${symbolDamage.imparable ? ' undefendable' : ''} damage with the validated dice.';
  if (rollCount >= 3) {
    return symbolDamage == null
        ? 'After my 3 attack rolls, no valid attack combination was made.'
        : 'After my 3 attack rolls, I deal ${symbolDamage.value} damage with ${_reservedDiceText(dice)}.\n'
              '${adventure.hero.label} must perform a defensive phase if the attack is defendable.';
  }
  return kept.isEmpty
      ? 'On my $rollLabel roll, I deal no damage yet.\nI reroll toward the first attack.'
      : 'On my $rollLabel roll, I keep ${kept.join('/')}.\nI try to improve the attack.$symbolDamageText';
}

String _rollLabel(int rollCount) {
  return switch (rollCount) {
    1 => 'first',
    2 => 'second',
    3 => 'third and final',
    _ => '${rollCount}th',
  };
}

List<int> _bestSuiteValues(List<int> values, int length) {
  final unique = values.toSet();
  final suites = switch (length) {
    5 => const [
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
    ],
    4 => const [
      [1, 2, 3, 4],
      [2, 3, 4, 5],
      [3, 4, 5, 6],
    ],
    _ => const [
      [1, 2, 3],
      [2, 3, 4],
      [3, 4, 5],
      [4, 5, 6],
    ],
  };
  return suites.firstWhere(
    (suite) => suite.every(unique.contains),
    orElse: () => const [],
  );
}

String _reservedDiceText(List<GameDie> dice) {
  final values =
      dice
          .where((die) => die.reserved && die.value != null)
          .map((die) => die.value!)
          .toList()
        ..sort();
  return values.isEmpty ? 'none' : values.join('/');
}

String _naraxusAiMessage(
  EnemyNode enemy,
  List<GameDie> rolled,
  AdventureState adventure,
) {
  if (rolled.isEmpty || rolled.first.value == null) {
    return 'Naxarus battle phase.\n'
        'Roll 1 die to choose the dragon attack.\n'
        'The result will feed the sword counter.';
  }
  final value = rolled.first.value!;
  return switch (value) {
    1 =>
      'I use Swoop with die result 1.\n'
          'I deal 3 undefendable damage.\n'
          'Naxarus removes 1 random token.\n'
          'Naxarus heals 4 HP.\n'
          '${adventure.hero.label} has no defense unless a card changes the attack.',
    2 =>
      'I use Ember Spark with die result 2.\n'
          'I deal 8 damage.\n'
          'Hero moves the top 3 deck cards to discard.\n'
          '${adventure.hero.label} must perform a defensive phase.',
    3 =>
      'I use Gashing Bite with die result 3.\n'
          'Naxarus rolls 4 dice.\n'
          'Damage equals the 2 highest dice.\n'
          '${adventure.hero.label} must perform a defensive phase.',
    4 =>
      'I use Hoarding with die result 4.\n'
          'I deal 9 damage.\n'
          'Hero loses 1 die on the next battle phase.\n'
          '${adventure.hero.label} must perform a defensive phase.',
    5 =>
      'I use Thundering Roar with die result 5.\n'
          'I deal 8 undefendable damage.\n'
          'Hero discards 1 card.\n'
          '${adventure.hero.label} has no defense unless a card changes the attack.',
    6 =>
      "I use Dragon's Might with die result 6.\n"
          'I deal 10 damage.\n'
          'Naxarus rolls 1 extra die; on 5-6, Swoop also triggers.',
    _ => 'Naxarus waits.',
  };
}

_AttackDamage? _bestSymbolAttackDamage(EnemyNode enemy, List<GameDie> dice) {
  if (enemy.attackPlan.style != MinionAttackStyle.symbols) {
    return null;
  }
  _AttackDamage? result;
  for (final goal in enemy.attackPlan.goals) {
    if (_symbolGoalMetDice(dice, goal)) {
      result = _damageForSymbolGoal(enemy, goal);
    }
  }
  return result;
}

bool _symbolGoalMetDice(List<GameDie> dice, SymbolGoal goal) {
  final counts = <DieSymbol, int>{};
  for (final die in dice) {
    final symbol = die.symbol;
    if (symbol != null) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
  }
  return (counts[DieSymbol.white] ?? 0) >= goal.white &&
      (counts[DieSymbol.yellow] ?? 0) >= goal.yellow &&
      (counts[DieSymbol.red] ?? 0) >= goal.red;
}

int _maxDefensePrevention(EnemyNode enemy) {
  return switch (enemy.profileKey) {
    'naraxus' => 5,
    'fee' => 3,
    'archer-de-lombre' => 3,
    'epeiste-egare' => enemy.defenseDice.clamp(0, 5),
    'elfe-du-chaos' => 99,
    _ => _numberAfter(enemy.defense, ['previent', 'prevent']) ?? 0,
  };
}

int _maxDefenseReturnDamage(EnemyNode enemy) {
  return switch (enemy.profileKey) {
    'ronin-vagabond' => 3,
    'enchanteur-gobelin' => 1,
    'epeiste-egare' => 2,
    _ => _numberAfter(enemy.defense, ['inflige', 'deal']) ?? 0,
  };
}

int? _numberAfter(String text, List<String> words) {
  final lower = text.toLowerCase();
  for (final word in words) {
    final match = RegExp('$word ([0-9]+)').firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
  }
  return null;
}

int _bestSuiteLength(List<int> values) {
  final unique = values.toSet();
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
    if (suite.every(unique.contains)) {
      return suite.length;
    }
  }
  return 0;
}

class ManualExtraDicePhasePanel extends StatefulWidget {
  const ManualExtraDicePhasePanel({super.key});

  @override
  State<ManualExtraDicePhasePanel> createState() =>
      _ManualExtraDicePhasePanelState();
}

class _ManualExtraDicePhasePanelState extends State<ManualExtraDicePhasePanel> {
  final _random = Random();
  late final List<GameDie> _dice = List.generate(
    6,
    (index) => GameDie(id: index),
  );
  int _diceToRoll = 1;
  int _rollCount = 0;

  @override
  Widget build(BuildContext context) {
    final visibleDice = _dice.take(_diceToRoll.clamp(0, 6)).toList();
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Extra dice phase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              DropdownButton<int>(
                value: _diceToRoll,
                items: [0, 1, 2, 3, 4, 5, 6]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count dice'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _diceToRoll = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final die in visibleDice)
                DieTile(die: die, onTap: () {}, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          ImageActionButton(
            label: _rollCount == 0 ? 'Roll' : 'Reroll',
            icon: Icons.casino,
            onPressed: _diceToRoll <= 0
                ? null
                : () => setState(() {
                    for (final die in visibleDice) {
                      die.value = _random.nextInt(6) + 1;
                    }
                    _rollCount++;
                  }),
          ),
        ],
      ),
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
          Expanded(child: SuiteGoalView(length: length)),
          if (damage != null)
            DamageBadge(value: damage!.value, imparable: damage!.imparable),
        ],
      ),
    );
  }
}

class SuiteGoalView extends StatelessWidget {
  const SuiteGoalView({required this.length, super.key});

  final int length;

  @override
  Widget build(BuildContext context) {
    final count = length.clamp(1, 5);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Container(
            width: 18 + index * 4,
            height: 18 + index * 4,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
      ],
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
    return Container(
      width: 25,
      height: 25,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black54),
      ),
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

class PreventBadge extends StatelessWidget {
  const PreventBadge({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.lightBlueAccent, width: 2),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DieValueBadge extends StatelessWidget {
  const DieValueBadge({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class TokenBadge extends StatelessWidget {
  const TokenBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
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
  final goalIndex = _goalIndex(enemy.attackPlan.goals, goal);
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
  return _damageFromAttackText(enemy, goalIndex);
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
  return _suiteDamageFromAttackText(enemy, length);
}

int _goalIndex(List<SymbolGoal> goals, SymbolGoal goal) {
  return goals.indexWhere(
    (candidate) =>
        candidate.white == goal.white &&
        candidate.yellow == goal.yellow &&
        candidate.red == goal.red,
  );
}

_AttackDamage? _damageFromAttackText(EnemyNode enemy, int goalIndex) {
  if (goalIndex < 0) {
    return null;
  }
  final damageValues = _attackDamageValues(enemy.attacks);
  if (goalIndex >= damageValues.length) {
    return null;
  }
  final value = damageValues[goalIndex];
  return _AttackDamage(value, imparable: _attackTextIsImparable(enemy.attacks));
}

_AttackDamage? _suiteDamageFromAttackText(EnemyNode enemy, int length) {
  final index = switch (length) {
    3 => 0,
    4 => 1,
    5 => 2,
    _ => -1,
  };
  if (index < 0) {
    return null;
  }
  final damageValues = _attackDamageValues(enemy.attacks);
  if (index >= damageValues.length) {
    return null;
  }
  return _AttackDamage(
    damageValues[index],
    imparable: _attackTextIsImparable(enemy.attacks),
  );
}

List<int> _attackDamageValues(List<String> attacks) {
  final values = <int>[];
  for (final line in attacks.skip(1)) {
    final normalized = _normalizeAttackText(line);
    for (final match in RegExp(
      r'(\d+(?:\s*/\s*\d+)*)\s*(?:degats|damage)',
    ).allMatches(normalized)) {
      final raw = match.group(1);
      if (raw == null) {
        continue;
      }
      values.addAll(
        raw
            .split('/')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>(),
      );
    }
    if (!normalized.contains('degats') && !normalized.contains('damage')) {
      final afterEquals = normalized.split('=').last;
      final fallbackValues = RegExp(r'\d+')
          .allMatches(afterEquals)
          .map((match) => int.tryParse(match.group(0) ?? ''))
          .whereType<int>()
          .toList();
      if (fallbackValues.isNotEmpty) {
        values.add(fallbackValues.last);
      }
    }
  }
  return values;
}

bool _attackTextIsImparable(List<String> attacks) {
  final text = _normalizeAttackText(attacks.join(' '));
  return text.contains('imparable') || text.contains('undefendable');
}

String _normalizeAttackText(String value) {
  return value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ï', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ô', 'o');
}

String _compactDefenseText(String value) {
  return value
      .replaceAll('jaunes', 'orange')
      .replaceAll('jaune', 'orange')
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
    required this.naraxusRollHistory,
    required this.onFinish,
    required this.onChanged,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final CombatPhase phase;
  final List<String> naraxusRollHistory;
  final VoidCallback? onFinish;
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
          CombatantStatusRow.hero(
            adventure: widget.adventure,
            hideCp: false,
            rollHistory: const [],
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
          const SizedBox(height: 8),
          CombatantStatusRow.enemy(
            enemy: widget.enemy,
            hideCp: widget.enemy.profileKey == 'naraxus',
            rollHistory: widget.enemy.profileKey == 'naraxus'
                ? widget.naraxusRollHistory
                : const [],
            onHp: () => _openEditor('enemyHp', widget.enemy.health),
            onCp: () => _openEditor('enemyCp', widget.enemy.combatPoints),
            onEditTokens: _editEnemyTokens,
          ),
          if (_editing.contains('enemyHp')) ...[
            const SizedBox(height: 6),
            _buildEditorRow('enemyHp'),
          ],
          if (_editing.contains('enemyCp')) ...[
            const SizedBox(height: 6),
            _buildEditorRow('enemyCp'),
          ],
          if (widget.onFinish != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: FilledButton.icon(
                    onPressed: widget.onFinish,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
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
        Expanded(
          child: Center(
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
    this.hideCp = false,
    this.rollHistory = const [],
    super.key,
  }) : hero = adventure.hero,
       enemy = null,
       title = 'Hero',
       hp = adventure.health,
       cp = adventure.combatPoints,
       tokens = adventure.alterations,
       accent = heroAccent;

  CombatantStatusRow.enemy({
    required this.enemy,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    this.hideCp = false,
    this.rollHistory = const [],
    super.key,
  }) : hero = null,
       title = 'Enemy',
       hp = enemy!.health,
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
  final bool hideCp;
  final List<String> rollHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hero != null)
          HeroAvatar(hero: hero!, size: 36)
        else if (enemy != null)
          EnemyRankAvatar(enemy: enemy!, size: 36),
        const SizedBox(width: 7),
        SizedBox(
          width: 68,
          child: MapStatChip(
            icon: Icons.favorite,
            label: '',
            value: hp.toString(),
            color: accent,
            accent: accent,
            onTap: onHp,
          ),
        ),
        const SizedBox(width: 6),
        if (!hideCp) ...[
          SizedBox(
            width: 68,
            child: MapStatChip(
              label: 'CP',
              value: cp.toString(),
              color: accent,
              accent: accent,
              onTap: onCp,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          flex: hideCp ? 1 : 2,
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
        if (hideCp) ...[
          const SizedBox(width: 6),
          Expanded(
            child: _RollHistoryStrip(values: rollHistory, accent: accent),
          ),
        ],
      ],
    );
  }
}

class _RollHistoryStrip extends StatelessWidget {
  const _RollHistoryStrip({required this.values, required this.accent});

  final List<String> values;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final recent = values.length <= 4
        ? values
        : values.sublist(values.length - 4);
    return InkWell(
      onTap: values.isEmpty
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Naxarus rolls'),
                content: Text(values.join(' / ')),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent),
        ),
        child: Row(
          children: [
            Icon(Icons.history, color: accent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                recent.isEmpty ? 'Rolls' : recent.join(' / '),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
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
    required this.heroUpkeepApplied,
    this.canAdvance = true,
    required this.onPhaseChanged,
    required this.onNext,
    required this.onApplyUpkeep,
    required this.onApplyHeroUpkeep,
    super.key,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;
  final bool canAdvance;
  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;

  @override
  Widget build(BuildContext context) {
    final poisonCount = enemy.alterations
        .where((token) => token == 'Poison')
        .length;
    final heroHasSilence = adventure.alterations.contains('Silence');
    final heroHasHemorrhage = adventure.alterations.contains('Hémorragie');
    final heroHasRonces = adventure.alterations.contains('Ronces');
    final enemyHasRiposte = enemy.alterations.contains('Riposte');
    final nextPhase = _nextCombatPhase(phase);
    final nextColor = _phaseColor(nextPhase, enemy);
    final reminder = switch (phase) {
      CombatPhase.heroUpkeep => [
        if (heroHasHemorrhage) 'Hémorragie',
        if (heroHasRonces) 'Ronces',
      ].join(' | '),
      CombatPhase.hero => [
        if (enemyHasRiposte) 'Riposte',
        if (heroHasSilence) 'Silence',
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
                  adventure: adventure,
                  enemy: enemy,
                  onPhaseChanged: onPhaseChanged,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 44,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: nextColor,
                    foregroundColor: Colors.black,
                  ),
                  tooltip:
                      (phase == CombatPhase.minionUpkeep && !upkeepApplied) ||
                          (phase == CombatPhase.heroUpkeep &&
                              !heroUpkeepApplied)
                      ? 'Apply upkeep and continue'
                      : 'Next phase',
                  onPressed: canAdvance
                      ? () {
                          if (phase == CombatPhase.heroUpkeep &&
                              !heroUpkeepApplied) {
                            onApplyHeroUpkeep();
                          }
                          if (phase == CombatPhase.minionUpkeep &&
                              !upkeepApplied) {
                            onApplyUpkeep();
                          }
                          onNext();
                        }
                      : null,
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
    required this.adventure,
    required this.enemy,
    required this.onPhaseChanged,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final ValueChanged<CombatPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CombatPhase.values.map((value) {
        final selected = value == phase;
        final accent = _phaseColor(value, enemy);
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
                      color: selected ? accent : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent),
                    ),
                    child: switch (value) {
                      CombatPhase.heroUpkeep => HeroAvatar(
                        hero: adventure.hero,
                        size: 28,
                      ),
                      CombatPhase.minionUpkeep => EnemyRankAvatar(
                        enemy: enemy,
                        size: 28,
                      ),
                      _ => const Icon(
                        Icons.casino,
                        color: Colors.white,
                        size: 19,
                      ),
                    },
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

CombatPhase _nextCombatPhase(CombatPhase phase) {
  return switch (phase) {
    CombatPhase.heroUpkeep => CombatPhase.hero,
    CombatPhase.hero => CombatPhase.minionUpkeep,
    CombatPhase.minionUpkeep => CombatPhase.minionAttack,
    CombatPhase.minionAttack => CombatPhase.heroUpkeep,
  };
}

Color _phaseColor(CombatPhase phase, EnemyNode enemy) {
  return switch (phase) {
    CombatPhase.heroUpkeep || CombatPhase.hero => heroAccent,
    CombatPhase.minionUpkeep || CombatPhase.minionAttack => enemy.rank.color,
  };
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
    required this.visibleDiceCount,
    required this.maxDiceCount,
    required this.rollCount,
    required this.maxRolls,
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
    required this.rollLabel,
    required this.rollColor,
    super.key,
  });

  final List<GameDie> dice;
  final int diceToRoll;
  final int visibleDiceCount;
  final int maxDiceCount;
  final int rollCount;
  final int maxRolls;
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
  final String rollLabel;
  final Color rollColor;

  @override
  Widget build(BuildContext context) {
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 6)).toList();
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
                items: List.generate(maxDiceCount.clamp(0, 5) + 1, (i) => i)
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
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: onToggleEdit,
                icon: const Icon(Icons.tune),
                label: Text(editMode ? 'Stop edit' : 'Edit a die'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
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
              if (maxRolls > 1) ...[
                Text(
                  '$rollCount / $maxRolls',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: rollColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: rollCount < maxRolls && diceToRoll > 0
                      ? onRoll
                      : null,
                  icon: const Icon(Icons.casino),
                  label: Text(rollLabel),
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
  const DieTile({
    required this.die,
    required this.onTap,
    this.compact = false,
    this.highlight = false,
    this.highlightColor,
    super.key,
  });

  final GameDie die;
  final VoidCallback onTap;
  final bool compact;
  final bool highlight;
  final Color? highlightColor;

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: compact ? 40 : 50,
            height: compact ? 40 : 50,
            constraints: BoxConstraints(maxWidth: compact ? 40 : 50),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value == null ? Colors.white24 : color,
              borderRadius: BorderRadius.circular(8),
              border: highlight
                  ? Border.all(color: highlightColor ?? heroAccent, width: 3)
                  : null,
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: (highlightColor ?? heroAccent).withValues(
                          alpha: 0.72,
                        ),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(
                color: value == null ? Colors.white : textColor,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (highlight)
            Positioned(
              right: -4,
              top: -5,
              child: Icon(
                Icons.check_circle,
                color: highlightColor ?? heroAccent,
                size: compact ? 16 : 18,
              ),
            ),
        ],
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
    final outcome = d20 == null
        ? null
        : GameEngine.rewardForD20(d20, chest: widget.enemy.rank.rewardChestKey);
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
                      d20 == null ? 'Roll the die' : outcome!.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ImageActionButton(
                          label: d20 == null ? 'Roll' : 'Reroll',
                          icon: Icons.casino,
                          onPressed: () =>
                              setState(() => _d20 = _random.nextInt(20) + 1),
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
                        widget.adventure.applyReward(d20, widget.enemy.rank);
                        Navigator.of(context).pop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8f43ff),
                  foregroundColor: Colors.white,
                ),
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
  const AdventureDetailsPage({
    required this.adventure,
    this.combatEnemy,
    this.combatPhase,
    this.combatDice = const [],
    this.aiMode,
    this.rollCount,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode? combatEnemy;
  final CombatPhase? combatPhase;
  final List<GameDie> combatDice;
  final bool? aiMode;
  final int? rollCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run details'),
        actions: [
          IconButton(
            tooltip: 'Export JSON',
            onPressed: () => _openExport(context),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
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

  void _openExport(BuildContext context) {
    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(_combatExportPayload());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Combat export'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonText));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('JSON copied.')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy JSON'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _combatExportPayload() {
    final enemy = combatEnemy;
    return {
      'exportVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'run': {
        'hero': adventure.hero.label,
        'mode': adventure.config.label,
        'score': adventure.score,
        'targetScore': adventure.targetScore,
        'elapsed': adventure.elapsed.inSeconds,
        'rewards': adventure.bonuses,
        'logs': adventure.logs,
      },
      'heroState': {
        'hp': adventure.health,
        'cp': adventure.combatPoints,
        'tokens': adventure.alterations,
      },
      if (enemy != null)
        'combat': {
          'phase': combatPhase?.name,
          'aiMode': aiMode,
          'rollCount': rollCount,
          'enemy': {
            'id': enemy.id,
            'profileKey': enemy.profileKey,
            'name': enemy.label,
            'rank': enemy.rank.name,
            'hp': enemy.health,
            'maxHp': enemy.maxHealth,
            'cp': enemy.combatPoints,
            'tokens': enemy.alterations,
            'attacks': enemy.attacks,
            'defense': enemy.defense,
            'defenseDice': enemy.defenseDice,
            'attackPlan': {
              'style': enemy.attackPlan.style.name,
              'goals': enemy.attackPlan.goals
                  .map(
                    (goal) => {
                      'white': goal.white,
                      'orange': goal.yellow,
                      'red': goal.red,
                    },
                  )
                  .toList(),
            },
          },
          'dice': combatDice
              .map(
                (die) => {
                  'id': die.id,
                  'value': die.value,
                  'symbol': die.symbol?.name,
                  'reserved': die.reserved,
                },
              )
              .toList(),
          if (enemy.attackPlan.style == MinionAttackStyle.suite)
            'aiDecision': {
              'type': 'suiteHold',
              'values': MinionDiceEngine.chooseSuiteHold(combatDice).values,
              'reason': MinionDiceEngine.chooseSuiteHold(combatDice).reason,
            },
        },
    };
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
    EnemyRank.naraxus => naraxusProfile,
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
