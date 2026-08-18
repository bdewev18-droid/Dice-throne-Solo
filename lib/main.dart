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
import 'history_repository.dart';
import 'models/enemy_profile.dart';
import 'supabase_service.dart';

part 'parts/app_shell.dart';
part 'parts/history.dart';
part 'parts/hero_setup.dart';
part 'parts/map.dart';
part 'parts/fight.dart';
part 'parts/rewards_details.dart';
part 'parts/run_generation.dart';

const String appVersionLabel = 'Version 1.3.116';
const String _activeAdventureKey = 'active_adventure_v1';
const Color heroAccent = Color(0xffffe22d);
const Color panelBorderGrey = Color(0xff3d4a3e);
const String defaultEnemyChatPortrait = 'assets/enemy_previews/bleu-001.webp';
const int mediumTarget = 33;
const int hardTarget = 52;
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase doit s'initialiser AVANT runApp pour que le flux PKCE web
  // puisse échanger le `code` du redirect OAuth au chargement de la page.
  // Si l'init est différée, la session OAuth n'est jamais restaurée.
  await _initializeOptionalServices();
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppBootstrapState>()?.restartApp();
  }

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late Future<void> _requiredData = _loadRequiredData();
  Key _appKey = UniqueKey();

  void restartApp() {
    setState(() {
      _appKey = UniqueKey();
      _requiredData = _loadRequiredData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _requiredData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return DiceThroneSurvieApp(key: _appKey);
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

Future<void> _loadRequiredData() async {
  try {
    await Future.wait<void>([
      EnemyProfileRepository.load(),
      TokenCatalogRepository.load(),
      AppSettings.instance.load(),
    ]).timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint('Required local data initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeOptionalServices() async {
  try {
    await SupabaseService.instance.initialize().timeout(
      const Duration(seconds: 8),
    );
  } catch (error, stackTrace) {
    debugPrint('Optional service initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

enum HeroSegment {
  season1('Season 1'),
  season2('Season 2'),
  avengers('Avengers'),
  xmen('X-Men'),
  outcast('Outcasts'),
  santaKrampus('Santa & Krampus'),
  other('Single');

  const HeroSegment(this.label);

  final String label;
}

enum HeroType {
  alchemist(
    'Alchemist',
    'assets/personnages/Alchemist.png',
    Alignment.center,
    Color(0xff35c7a0),
    [HeroSegment.other],
    5,
  ),
  benjamin(
    'Benjamin',
    'assets/personnages/benji.webp',
    Alignment(0.0, -0.6),
    Colors.blue,
    HeroSegment.values,
    6,
  ),
  artificer(
    'Artificer',
    'assets/personnages/artificer.jpg',
    Alignment.center,
    Color(0xff37b8ff),
    [HeroSegment.season2],
    6,
  ),
  barbare(
    'Barbarian',
    'assets/personnages/Barbarian.png',
    Alignment.center,
    Color(0xffd94a24),
    [HeroSegment.season1],
    1,
  ),
  blackPanther(
    'Black Panther',
    'assets/personnages/BlackPanther.png',
    Alignment.center,
    Color(0xff7a65ff),
    [HeroSegment.avengers],
    2,
  ),
  blackWidow(
    'Black Widow',
    'assets/personnages/BlackWidow.png',
    Alignment.center,
    Color(0xffdb3d48),
    [HeroSegment.avengers],
    4,
  ),
  captainMarvel(
    'Captain Marvel',
    'assets/personnages/CaptMarvel.png',
    Alignment.center,
    Color(0xffffc64d),
    [HeroSegment.avengers],
    2,
  ),
  deadpool(
    'Deadpool',
    'assets/personnages/Deadpool.webp',
    Alignment.center,
    Color(0xffd9232e),
    [HeroSegment.other],
    3,
  ),
  cyclops(
    'Cyclops',
    'assets/personnages/Cyclops.png',
    Alignment.center,
    Color(0xfff0c044),
    [HeroSegment.xmen],
    4,
  ),
  cursedPirate(
    'Cursed Pirate',
    'assets/personnages/cursed-pirate.jpg',
    Alignment.center,
    Color(0xff20c7b8),
    [HeroSegment.season2],
    4,
  ),
  doctorStrange(
    'Doctor Strange',
    'assets/personnages/DrStrange.png',
    Alignment.center,
    Color(0xffe14646),
    [HeroSegment.avengers],
    5,
  ),
  druid(
    'Druid',
    'assets/personnages/Druid.png',
    Alignment.center,
    Color(0xff7ac66a),
    [HeroSegment.other],
    4,
  ),
  duelist(
    'Duelist',
    'assets/personnages/Duelist.png',
    Alignment.center,
    Color(0xffd6a052),
    [HeroSegment.other],
    3,
  ),
  elfeLunaire(
    'Moon Elf',
    'assets/personnages/moon-elf-hp.jpg',
    Alignment.center,
    Color(0xff64b7e8),
    [HeroSegment.season1],
    2,
  ),
  forgemaster(
    'Forgemaster',
    'assets/personnages/Forgemaster.png',
    Alignment.center,
    Color(0xfff09a43),
    [HeroSegment.other],
    4,
  ),
  gambit(
    'Gambit',
    'assets/personnages/Gambit.png',
    Alignment.center,
    Color(0xffbb67ff),
    [HeroSegment.xmen],
    6,
  ),
  gunslinger(
    'Gunslinger',
    'assets/personnages/gunslinger.jpg',
    Alignment.center,
    Color(0xffc57a35),
    [HeroSegment.season2],
    2,
  ),
  headlessHorseman(
    'Headless Horseman',
    'assets/personnages/HeadlessHorseman.png',
    Alignment.center,
    Color(0xfff06a2b),
    [HeroSegment.outcast],
    4,
  ),
  huntress(
    'Huntress',
    'assets/personnages/Huntress.png',
    Alignment.center,
    Color(0xff4fa95b),
    [HeroSegment.season2],
    5,
  ),
  iceman(
    'Iceman',
    'assets/personnages/Iceman.png',
    Alignment.center,
    Color(0xff8de9ff),
    [HeroSegment.xmen],
    4,
  ),
  jeanGrey(
    'Jean Grey',
    'assets/personnages/JeanGrey.png',
    Alignment.center,
    Color(0xffff8b45),
    [HeroSegment.xmen],
    6,
  ),
  krampus(
    'Krampus',
    'assets/personnages/Krampus.png',
    Alignment.center,
    Color(0xffb44335),
    [HeroSegment.santaKrampus],
    4,
  ),
  loki(
    'Loki',
    'assets/personnages/Loki.png',
    Alignment.center,
    Color(0xff57b966),
    [HeroSegment.avengers],
    4,
  ),
  monk(
    'Monk',
    'assets/personnages/monk.jpg',
    Alignment.center,
    Color(0xffd7a55a),
    [HeroSegment.season1],
    4,
  ),
  mysticBrawler(
    'Mystic Brawler',
    'assets/personnages/MysticBrawler.png',
    Alignment.center,
    Color(0xff7cc5ff),
    [HeroSegment.other],
    3,
  ),
  necromancer(
    'Necromancer',
    'assets/personnages/Necromancer.png',
    Alignment.center,
    Color(0xff75d16b),
    [HeroSegment.outcast],
    6,
  ),
  ninja(
    'Ninja',
    'assets/personnages/Ninja.png',
    Alignment.center,
    Color(0xff2cc6a8),
    [HeroSegment.season1],
    2,
  ),
  paladin(
    'Paladin',
    'assets/personnages/Paladin.png',
    Alignment.center,
    Color(0xfff4c95a),
    [HeroSegment.season1],
    5,
  ),
  paleLady(
    'Pale Lady',
    'assets/personnages/PaleLady.png',
    Alignment.center,
    Color(0xffcfd6ff),
    [HeroSegment.outcast],
    3,
  ),
  psylocke(
    'Psylocke',
    'assets/personnages/Psylocke.png',
    Alignment.center,
    Color(0xffd15cff),
    [HeroSegment.xmen],
    3,
  ),
  pyromancer(
    'Pyromancer',
    'assets/personnages/pyromancer.png',
    Alignment.center,
    Color(0xffff6a21),
    [HeroSegment.season1],
    3,
  ),
  raveness(
    'Raveness',
    'assets/personnages/Raveness.png',
    Alignment.center,
    Color(0xff7f5cff),
    [HeroSegment.outcast],
    3,
  ),
  rogue(
    'Rogue',
    'assets/personnages/Rouge.png',
    Alignment.center,
    Color(0xff6dcc5d),
    [HeroSegment.xmen],
    3,
  ),
  samurai(
    'Samurai',
    'assets/personnages/Samurai.jpg',
    Alignment.center,
    Color(0xffa82828),
    [HeroSegment.season2],
    3,
  ),
  santa(
    'Santa',
    'assets/personnages/Santa.png',
    Alignment.center,
    Color(0xffde2f3f),
    [HeroSegment.santaKrampus],
    2,
  ),
  scarletWitch(
    'Scarlet Witch',
    'assets/personnages/ScarletWich.png',
    Alignment.center,
    Color(0xffd8233f),
    [HeroSegment.avengers],
    4,
  ),
  seraph(
    'Seraph',
    'assets/personnages/Seraph.png',
    Alignment.center,
    Color(0xffffd35c),
    [HeroSegment.season2],
    3,
  ),
  shadowThief(
    'Shadow Thief',
    'assets/personnages/ShadowThief.png',
    Alignment.center,
    Color(0xff8f4dff),
    [HeroSegment.season1],
    5,
  ),
  spiderman(
    'Miles Morales Spider-Man',
    'assets/personnages/Spiderman.png',
    Alignment.center,
    Color(0xffe02c35),
    [HeroSegment.avengers],
    2,
  ),
  storm(
    'Storm',
    'assets/personnages/Storm.png',
    Alignment.center,
    Color(0xffc8d9ff),
    [HeroSegment.xmen],
    4,
  ),
  sunElf(
    'Sun Elf',
    'assets/personnages/SunElf.png',
    Alignment.center,
    Color(0xffffc857),
    [HeroSegment.other],
    3,
  ),
  tacticien(
    'Tactician',
    'assets/personnages/Tactician.png',
    Alignment.center,
    Color(0xffd92f2f),
    [HeroSegment.season2],
    5,
  ),
  thor(
    'Thor',
    'assets/personnages/Thor.png',
    Alignment.center,
    Color(0xff5ca7ff),
    [HeroSegment.avengers],
    3,
  ),
  treant(
    'Treant',
    'assets/personnages/Treeant.png',
    Alignment.center,
    Color(0xff70b85a),
    [HeroSegment.season1],
    5,
  ),
  vampireLord(
    'Vampire Lord',
    'assets/personnages/VampireLord.png',
    Alignment.center,
    Color(0xff9f2035),
    [HeroSegment.season2],
    4,
  ),
  wolverine(
    'Wolverine',
    'assets/personnages/Wolverine.png',
    Alignment.center,
    Color(0xffffc134),
    [HeroSegment.xmen],
    2,
  );

  const HeroType(
    this.label,
    this.asset,
    this.imageAlignment,
    this.color,
    this.segments, [
    this.complexity = 1,
  ]);

  final String label;
  final String asset;
  final Alignment imageAlignment;
  final Color color;
  final List<HeroSegment> segments;
  final int complexity;

  String get complexityAsset => 'assets/complexity/complexity-$complexity.png';
  double get imageScale => 1;
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
      enemy.alterations.any((a) {
        final norm = _normalizeTokenKey(a);
        return norm == 'firststrike' ||
            norm == 'premierefrappe' ||
            norm == '1stfrappe' ||
            norm == '1erfrappe';
      })) {
    return CombatPhase.minionUpkeep;
  }
  return CombatPhase.heroUpkeep;
}

CombatPhase firstCombatPhaseFor(EnemyNode enemy) => _firstCombatPhaseFor(enemy);

enum StatusTokenKind { positive, negative, unique }

enum TokenPersistence {
  persistent('persistent'),
  semiPersistent('semi_persistent'),
  nonPersistent('non_persistent');

  const TokenPersistence(this.code);
  final String code;
}

class StatusTokenRule {
  const StatusTokenRule({
    required this.label,
    required this.kind,
    required this.maxStack,
    required this.persistent,
    this.persistence = TokenPersistence.persistent,
    required this.removable,
    required this.appSupported,
    this.appAnimation = false,
    required this.description,
    this.appDetails = '',
    this.frLabel = '',
    this.imageAsset,
    this.aliases = const [],
    this.minionAllowed = true,
    this.editorVisible = true,
  });

  final String label;
  final String frLabel;
  final StatusTokenKind kind;
  final int maxStack;
  final bool persistent;
  final TokenPersistence persistence;
  final bool removable;
  final bool appSupported;
  final bool appAnimation;
  final String description;
  final String appDetails;
  final String? imageAsset;
  final List<String> aliases;
  final bool minionAllowed;
  final bool editorVisible;

  bool matches(String value) {
    final key = _normalizeTokenKey(value);
    return _normalizeTokenKey(label) == key ||
        _normalizeTokenKey(frLabel) == key ||
        aliases.any((alias) => _normalizeTokenKey(alias) == key);
  }
}

class TokenCatalogRepository {
  const TokenCatalogRepository._();

  static List<StatusTokenRule> _rules = const [];
  static Map<String, List<String>> _heroTokens = const {};

  static Future<void> load() async {
    final source = await rootBundle.loadString(
      'assets/data/token_catalog.json',
    );
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rawTokens = json['tokens'] as List<dynamic>? ?? const [];
    _rules =
        rawTokens
            .whereType<Map<String, dynamic>>()
            .map(_tokenFromJson)
            .where((rule) => rule.label.isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) => a.label.compareTo(b.label));

    final rawHeroTokens = json['heroTokens'];
    if (rawHeroTokens is Map<String, dynamic>) {
      _heroTokens = rawHeroTokens.map(
        (key, value) => MapEntry(
          key,
          value is List
              ? value.whereType<String>().toList(growable: false)
              : const <String>[],
        ),
      );
    } else {
      _heroTokens = const {};
    }
  }

  static List<StatusTokenRule> get rules => _rules;

  static List<String> heroTokens(HeroType hero) {
    return _heroTokens[hero.label] ?? const [];
  }

  static StatusTokenRule? byLabel(String value) {
    for (final rule in _rules) {
      if (rule.matches(value)) {
        return rule;
      }
    }
    return null;
  }

  static StatusTokenRule _tokenFromJson(Map<String, dynamic> json) {
    final image = (json['imageAsset'] as String?)?.trim();
    return StatusTokenRule(
      label: json['label'] as String? ?? '',
      frLabel: json['frLabel'] as String? ?? '',
      kind: _kindFromName(json['kind'] as String?),
      maxStack: _intValue(json['maxStack'], fallback: 99),
      persistent: json['persistent'] as bool? ?? true,
      persistence: _persistenceFromName(
        json['persistence'] as String?,
        fallbackPersistent: json['persistent'] as bool? ?? true,
      ),
      removable: json['removable'] as bool? ?? true,
      appSupported: json['appSupported'] as bool? ?? false,
      appAnimation: json['appAnimation'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      appDetails: json['appDetails'] as String? ?? '',
      imageAsset: image == null || image.isEmpty ? null : image,
      aliases: _stringList(json['aliases']),
      minionAllowed: json['minionAllowed'] as bool? ?? true,
      editorVisible: json['editorVisible'] as bool? ?? true,
    );
  }

  static TokenPersistence _persistenceFromName(
    String? value, {
    required bool fallbackPersistent,
  }) {
    final v = (value ?? '').toLowerCase().replaceAll('-', '_');
    if (v == 'semi_persistent' || v == 'semipersistent') {
      return TokenPersistence.semiPersistent;
    }
    if (v == 'non_persistent' || v == 'nonpersistent') {
      return TokenPersistence.nonPersistent;
    }
    if (v == 'persistent') {
      return TokenPersistence.persistent;
    }
    return fallbackPersistent
        ? TokenPersistence.persistent
        : TokenPersistence.nonPersistent;
  }

  static StatusTokenKind _kindFromName(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'positive' => StatusTokenKind.positive,
      'unique' => StatusTokenKind.unique,
      _ => StatusTokenKind.negative,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

List<StatusTokenRule> get statusTokenRules => TokenCatalogRepository.rules;

List<String> get knownStatusTokens => [
  for (final rule in statusTokenRules) rule.label,
];

StatusTokenRule _tokenRule(String label) {
  final rule = TokenCatalogRepository.byLabel(label);
  if (rule == null) {
    throw StateError(
      'Token "$label" is missing from assets/data/token_catalog.json',
    );
  }
  return rule;
}

String _normalizeTokenKey(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäåā]'), 'a')
      .replaceAll(RegExp(r'[çć]'), 'c')
      .replaceAll(RegExp(r'[èéêëēė]'), 'e')
      .replaceAll(RegExp(r'[ìíîïī]'), 'i')
      .replaceAll(RegExp(r'ñ'), 'n')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'œ'), 'oe')
      .replaceAll(RegExp(r'æ'), 'ae')
      .replaceAll(RegExp(r'[ùúûüū]'), 'u')
      .replaceAll(RegExp(r'[ÿý]'), 'y')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

StatusTokenRule _tokenRuleFromTag(String value) {
  return _tokenRule(value);
}

String _tokenShortLabel(String label) {
  final rule = TokenCatalogRepository.byLabel(label);
  final source = rule?.label ?? label;
  return switch (_normalizeTokenKey(source)) {
    'firststrike' || 'premierefrappe' => '1ST',
    'knockdown' || 'aterre' => 'DOWN',
    'burn' || 'brulure' => 'BRN',
    'chaos' => 'CH',
    'concussion' || 'commotion' => 'COM',
    'blindinglight' || 'lumiereaveuglante' => 'LUA',
    'blind' || 'eblouissement' => 'EBL',
    'entangle' || 'enchevetrement' => 'ROOT',
    'evasive' || 'evitement' => 'EVA',
    'bleed' || 'hemorragie' => 'HEM',
    'kingshand' || 'mainduroi' => 'KH',
    'shadows' || 'ombre' => 'SHD',
    'parasite' => 'PAR',
    'poison' => 'PO',
    'targeted' || 'prispourcible' => 'TGT',
    'barbedvine' || 'ronces' => 'THR',
    'salvo' || 'salve' => 'SAL',
    'silence' => 'SIL',
    'spellbound' || 'sort6' => 'SPL',
    'hex' || 'malefice' => 'HEX',
    'hoarding' => 'HLD',
    _ =>
      source.length <= 4
          ? source.toUpperCase()
          : source.substring(0, 4).toUpperCase(),
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
  medium('Rush - Medium'),
  hard('Rush - Difficult'),
  free('Rush - Free'),
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

class AppSettings extends ChangeNotifier {
  AppSettings._() : _storage = createActiveAdventureStorage();

  static final AppSettings instance = AppSettings._();
  static const String _key = 'app_settings_v1';

  final ActiveAdventureStorage _storage;
  bool _developerMode = false;
  Set<String> _ownedHeroNames = {};
  bool _loaded = false;

  bool get developerMode => _developerMode;

  bool ownsHero(HeroType hero) =>
      _ownedHeroNames.isEmpty || _ownedHeroNames.contains(hero.name);

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final raw = await _storage.read(_key);
      if (raw == null || raw.isEmpty) {
        _ownedHeroNames = HeroType.values.map((hero) => hero.name).toSet();
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _developerMode = json['developerMode'] as bool? ?? false;
      final owned = json['ownedHeroes'] as List<dynamic>?;
      _ownedHeroNames = owned == null
          ? HeroType.values.map((hero) => hero.name).toSet()
          : owned.map((value) => value.toString()).toSet();
      if (_ownedHeroNames.isEmpty) {
        _ownedHeroNames = HeroType.values.map((hero) => hero.name).toSet();
      }
    } catch (error) {
      debugPrint('App settings load skipped: $error');
      _ownedHeroNames = HeroType.values.map((hero) => hero.name).toSet();
    }
  }

  Future<void> setDeveloperMode(bool value) async {
    if (_developerMode == value) {
      return;
    }
    _developerMode = value;
    notifyListeners();
    await _save();
  }

  Future<void> toggleHeroOwnership(HeroType hero) async {
    if (_ownedHeroNames.isEmpty) {
      _ownedHeroNames = HeroType.values.map((item) => item.name).toSet();
    }
    if (_ownedHeroNames.contains(hero.name)) {
      _ownedHeroNames.remove(hero.name);
    } else {
      _ownedHeroNames.add(hero.name);
    }
    notifyListeners();
    await _save(syncProfile: true);
  }

  Future<void> _save({bool syncProfile = false}) async {
    final payload = {
      'developerMode': _developerMode,
      'ownedHeroes': _ownedHeroNames.toList()..sort(),
    };
    await _storage.write(_key, jsonEncode(payload));
    if (syncProfile) {
      unawaited(
        SupabaseService.instance
            .updateHeroCollection(_ownedHeroNames)
            .catchError((error) {
              debugPrint('Hero collection Supabase sync skipped: $error');
            }),
      );
    }
  }
}

String _survivalModeTitle(SurvivalMode mode) {
  return mode.label;
}

class GameRecord {
  const GameRecord({
    required this.hero,
    required this.date,
    required this.score,
    this.id,
    this.mode = SurvivalMode.mediumFixed,
    this.healthRemaining,
    this.bossHealthRemaining,
    this.enemiesDefeated = 0,
    this.duration = Duration.zero,
    this.isVictory = false,
  });

  /// Identifiant Supabase (UUID) quand le record est issu de la base.
  /// Null pour un record créé localement non encore synchronisé.
  final String? id;
  final HeroType hero;
  final DateTime date;
  final int score;
  final SurvivalMode mode;
  final int? healthRemaining;
  final int? bossHealthRemaining;
  final int enemiesDefeated;
  final Duration duration;
  final bool isVictory;

  /// Sérialisation pour Supabase (table game_records).
  /// Ne contient pas user_id (ajouté côté service via la session).
  Map<String, dynamic> toSupabase() => {
    'hero': hero.name,
    'mode': mode.name,
    'score': score,
    'enemies_defeated': enemiesDefeated,
    'health_remaining': healthRemaining,
    'boss_health_remaining': bossHealthRemaining,
    'duration_ms': duration.inMilliseconds,
    'is_victory': isVictory,
    'played_at': date.toUtc().toIso8601String(),
  };

  /// Désérialisation depuis une ligne Supabase (game_records).
  factory GameRecord.fromSupabase(Map<String, dynamic> row) {
    final heroName = row['hero'] as String?;
    final modeName = row['mode'] as String?;
    final playedAt = row['played_at'];
    final durationMs = (row['duration_ms'] as num?)?.toInt() ?? 0;
    return GameRecord(
      id: row['id'] as String?,
      hero: _enumByName(HeroType.values, heroName) ?? HeroType.alchemist,
      date: _parseDateTime(playedAt) ?? DateTime.now(),
      score: (row['score'] as num?)?.toInt() ?? 0,
      mode:
          _enumByName(SurvivalMode.values, modeName) ??
          SurvivalMode.mediumFixed,
      healthRemaining: (row['health_remaining'] as num?)?.toInt(),
      bossHealthRemaining: (row['boss_health_remaining'] as num?)?.toInt(),
      enemiesDefeated: (row['enemies_defeated'] as num?)?.toInt() ?? 0,
      duration: Duration(milliseconds: durationMs),
      isVictory: (row['is_victory'] as bool?) ?? false,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
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

  bool get isNaraxusMode => mode == SurvivalMode.naraxus;

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
    required this.cp,
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
    List<MinionPassive> passives = const [],
    List<DisplayRow> defenseDisplayRows = const [],
    List<DisplayRow> passiveDisplayRows = const [],
    this.branch,
    this.step = 0,
  }) : health = maxHealth,
       combatPoints = cp,
       rewardRank = rewardRank ?? rank,
       rewardRanks = rewardRanks.isEmpty
           ? List<EnemyRank>.filled(
               rewardChests.clamp(1, 4).toInt(),
               rewardRank ?? rank,
             )
           : List<EnemyRank>.from(rewardRanks),
       passives = List<MinionPassive>.unmodifiable(passives),
       defenseDisplayRows = List<DisplayRow>.unmodifiable(defenseDisplayRows),
       passiveDisplayRows = List<DisplayRow>.unmodifiable(passiveDisplayRows) {
    alterations.addAll(initialTokens);
  }

  final int id;
  String label;
  EnemyRank rank;
  int maxHealth;
  int cp;
  List<String> attacks;
  String defense;
  int defenseDice;
  MinionAttackPlan attackPlan;
  String cardAsset;
  String? profileKey;
  int rewardChests;
  EnemyRank rewardRank;
  List<EnemyRank> rewardRanks;
  final List<MinionPassive> passives;
  List<DisplayRow> defenseDisplayRows;
  List<DisplayRow> passiveDisplayRows;
  final BranchSide? branch;
  final int step;
  int health;
  int combatPoints;
  final List<String> alterations = [];
  final Set<String> maskedPopinTokens = <String>{};
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
      cp = restoredProfile.cp;
      attacks = restoredProfile.attacks;
      defense = restoredProfile.defense;
      defenseDice = restoredProfile.defenseDice;
      attackPlan = restoredProfile.attackPlan;
      defenseDisplayRows = restoredProfile.defenseDisplayRows;
      passiveDisplayRows = restoredProfile.passiveDisplayRows;
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
    cp = profile.cp;
    attacks = profile.attacks;
    defense = profile.defense;
    defenseDice = profile.defenseDice;
    attackPlan = profile.attackPlan;
    defenseDisplayRows = profile.defenseDisplayRows;
    passiveDisplayRows = profile.passiveDisplayRows;
    cardAsset = profile.cardAsset;
    profileKey = profile.key;
    rewardChests = profile.rewardChests;
    rewardRank = profile.rewardRank ?? profile.rank;
    rewardRanks = profile.rewardRanks.isEmpty
        ? List<EnemyRank>.filled(rewardChests, rewardRank)
        : List<EnemyRank>.from(profile.rewardRanks);
    health = maxHealth;
    combatPoints = cp;
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
  final Set<String> maskedPopinTokens = <String>{};
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
    logs.insert(0, '[${_formatTimeOnly(DateTime.now())}] $message');
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

  void setHeroHealth(int value, {String? source}) {
    final oldHealth = health;
    health = value.clamp(0, 99);
    if (oldHealth != health && source != 'silent') {
      log('[HP] Hero HP: $oldHealth ➔ $health${source != null ? ' ($source)' : ' (Manual Adjustment)'}');
    }
    if (health == 0) {
      _endAdventure(false);
    }
  }

  void setHeroPc(int value, {String? source}) {
    final oldCp = combatPoints;
    combatPoints = value.clamp(0, 99);
    if (oldCp != combatPoints && source != 'silent') {
      log('[CP] Hero CP: $oldCp ➔ $combatPoints${source != null ? ' ($source)' : ' (Manual Adjustment)'}');
    }
  }

  void applyHeroUpkeep() {
    combatPoints = (combatPoints + 1).clamp(0, 99);
    log('Hero upkeep: gained 1 CP (Total: $combatPoints)');
  }

  void addAlteration(String value) {
    alterations.insert(0, value);
    log('Hero gained token: $value');
  }

  void setAlterations(List<String> values) {
    alterations
      ..clear()
      ..addAll(values);
    final currentKeys = values.map(_normalizeTokenKey).toSet();
    maskedPopinTokens.removeWhere((key) => !currentKeys.contains(key));
    log('Hero status tokens updated.');
  }

  void completeCombat(EnemyNode enemy) {
    if (!enemy.defeated && enemy.health <= 0) {
      enemy.defeated = true;
      score += enemy.rank.points;
      log('${enemy.label} defeated: +${enemy.rank.points} points.');
      
      // Naraxus tie logic
      if (health <= 0 && enemy.profileKey == 'naraxus') {
        score += 50;
        log('Tie against Naraxus: +50 points.');
      }
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
      for (final branch in BranchSide.values) {
        for (final enemy in _availableInBranch(branch)) {
          enemy.current = true;
        }
      }
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

  bool canSelectEnemy(EnemyNode enemy) {
    if (finished || enemy.defeated) {
      return false;
    }
    final start = enemyById(0);
    if (enemy.id == start.id) {
      return !start.defeated;
    }
    if (!start.defeated || enemy.branch == null) {
      return false;
    }

    var activeBranch = lockedBranch;
    if (activeBranch != null && _branchComplete(activeBranch)) {
      activeBranch = null;
    }
    if (activeBranch != null && enemy.branch != activeBranch) {
      return false;
    }
    if (activeBranch == null && _branchComplete(enemy.branch!)) {
      return false;
    }

    return _availableInBranch(
      enemy.branch!,
    ).any((candidate) => candidate.id == enemy.id);
  }

  bool _branchComplete(BranchSide branch) {
    return enemies
        .where((enemy) => enemy.branch == branch)
        .every((enemy) => enemy.defeated);
  }

  List<EnemyNode> _availableInBranch(BranchSide branch) {
    final branchEnemies =
        enemies.where((enemy) => enemy.branch == branch).toList()
          ..sort((a, b) => a.step.compareTo(b.step));
    if (branchEnemies.isEmpty) {
      return [];
    }

    EnemyNode? enemyAt(int step) {
      for (final enemy in branchEnemies) {
        if (enemy.step == step) {
          return enemy;
        }
      }
      return null;
    }

    final terminalViseer =
        branchEnemies.length >= 2 &&
        branchEnemies.last.rank == EnemyRank.viseer &&
        branchEnemies[branchEnemies.length - 2].rank == EnemyRank.orange;
    final boss = terminalViseer
        ? branchEnemies[branchEnemies.length - 2]
        : branchEnemies.last;
    final bossStep = boss.step;
    final sequentialLimit = bossStep - 3;
    for (var step = 1; step <= sequentialLimit; step++) {
      final enemy = enemyAt(step);
      if (enemy != null && !enemy.defeated) {
        return [enemy];
      }
    }

    final unlockedSteps = {bossStep - 2, bossStep - 1};
    final unlocked = branchEnemies
        .where((enemy) => unlockedSteps.contains(enemy.step) && !enemy.defeated)
        .toList();
    if (unlocked.isNotEmpty) {
      return unlocked;
    }

    if (!boss.defeated) {
      return [boss];
    }
    if (terminalViseer && !branchEnemies.last.defeated) {
      return [branchEnemies.last];
    }
    return [];
  }
}
