import 'dart:math';

import 'package:flutter/material.dart';

const String appVersionLabel = 'Version 1.1.4';
const int levelOneTarget = 33;
const int levelTwoTarget = 52;

void main() {
  runApp(const DiceThroneSurvieApp());
}

enum HeroType {
  barbare(
    'Barbarian',
    'assets/barbarian_hero.jpg',
    Alignment.center,
    Color(0xffd94a24),
  ),
  elfeLunaire(
    'Moon Elf',
    'assets/moon_elf_hero.png',
    Alignment.center,
    Color(0xff64b7e8),
  ),
  tacticien(
    'Tactician',
    'assets/tactician_hero.png',
    Alignment.center,
    Color(0xffd92f2f),
  ),
  monk('Monk', 'assets/monk_hero.png', Alignment.topCenter, Color(0xffd7a55a)),
  paladin(
    'Paladin',
    'assets/paladin_hero.png',
    Alignment.topCenter,
    Color(0xfff4c95a),
  ),
  pyromancer(
    'Pyromancer',
    'assets/pyromancer_hero.png',
    Alignment(0, -0.65),
    Color(0xffff6a21),
    1.22,
  ),
  shadowThief(
    'Shadow Thief',
    'assets/shadow_thief_hero.png',
    Alignment.topCenter,
    Color(0xff8f4dff),
  ),
  deadpool(
    'Deadpool',
    'assets/deadpool_hero.jpg',
    Alignment.center,
    Color(0xffc91922),
  );

  const HeroType(
    this.label,
    this.asset,
    this.imageAlignment,
    this.color, [
    this.imageScale = 1,
  ]);

  final String label;
  final String asset;
  final Alignment imageAlignment;
  final Color color;
  final double imageScale;
}

enum EnemyRank {
  green('Level 1', 1, Color(0xff34d36d), 'assets/map_green.jpg'),
  blue('Level 2', 2, Color(0xff3bb9ff), 'assets/map_blue.png'),
  violet('Level 3', 3, Color(0xff9b58ff), 'assets/map_violet.png'),
  brown('Brown', 4, Color(0xff8a5a2c), 'assets/map_orange.png'),
  orange('Level 4', 6, Color(0xffff8a2b), 'assets/map_orange.png');

  const EnemyRank(this.label, this.points, this.color, this.asset);

  final String label;
  final int points;
  final Color color;
  final String asset;
}

enum BranchSide {
  left('Left'),
  right('Right');

  const BranchSide(this.label);

  final String label;
}

enum HistorySort {
  recent('Latest game'),
  hero('Hero'),
  score('Best score'),
  date('Game date');

  const HistorySort(this.label);

  final String label;
}

enum SurvivalMode {
  levelOne('Medium mode', levelOneTarget),
  levelTwo('Difficult mode', levelTwoTarget),
  free('Free mode', 33);

  const SurvivalMode(this.label, this.defaultTarget);

  final String label;
  final int defaultTarget;
}

String _survivalModeTitle(SurvivalMode mode) {
  return switch (mode) {
    SurvivalMode.levelOne => 'Medium mode',
    SurvivalMode.levelTwo => 'Difficult mode',
    SurvivalMode.free => 'Free mode',
  };
}

String _survivalModeDescription(SurvivalMode mode) {
  return switch (mode) {
    SurvivalMode.levelOne => 'Fixed 33-point route',
    SurvivalMode.levelTwo => 'Fixed 52-point expert route',
    SurvivalMode.free => 'Build your own 13-enemy run',
  };
}

class GameRecord {
  const GameRecord({
    required this.hero,
    required this.date,
    required this.score,
    this.mode = SurvivalMode.levelOne,
  });

  final HeroType hero;
  final DateTime date;
  final int score;
  final SurvivalMode mode;
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

  String get label => switch (mode) {
    SurvivalMode.levelOne => 'Medium mode',
    SurvivalMode.levelTwo => 'Difficult mode',
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
    this.branch,
    this.step = 0,
  }) : health = maxHealth,
       combatPoints = pc;

  final int id;
  final String label;
  final EnemyRank rank;
  final int maxHealth;
  final int pc;
  final List<String> attacks;
  final String defense;
  final BranchSide? branch;
  final int step;
  int health;
  int combatPoints;
  final List<String> alterations = [];
  bool defeated = false;
  bool current = false;
}

class AdventureState {
  AdventureState({required this.hero, required this.config})
    : targetScore = config.targetScore,
      enemies = _generateEnemies(config) {
    _refreshAvailability();
    log('Run created: ${config.label}, target $targetScore points.');
  }

  final HeroType hero;
  final SurvivalConfig config;
  final int targetScore;
  final List<EnemyNode> enemies;
  final List<String> logs = [];
  final List<String> alterations = [];
  final List<String> bonuses = [];
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

  void setHeroHealth(int value) {
    health = value.clamp(0, 99);
    log('Hero HP set to $health.');
    if (health == 0) {
      _endAdventure(false);
    }
  }

  void setHeroPc(int value) {
    combatPoints = value.clamp(0, 20);
    log('Hero CP set to $combatPoints.');
  }

  void addAlteration(String value) {
    alterations.add(value);
    log('Hero status added: $value.');
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
      bonuses.add('D20 $d20: +1 HP');
      log('Reward confirmed: D20 $d20, +1 HP.');
    } else {
      combatPoints = (combatPoints + 1).clamp(0, 20);
      bonuses.add('D20 $d20: +1 CP');
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
  final List<GameRecord> _history = [
    GameRecord(hero: HeroType.barbare, date: DateTime(2026, 6, 26), score: 8),
    GameRecord(
      hero: HeroType.elfeLunaire,
      date: DateTime(2026, 6, 24),
      score: 13,
    ),
    GameRecord(hero: HeroType.barbare, date: DateTime(2026, 6, 20), score: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dice Throne Survie',
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
      home: Builder(
        builder: (context) => HomePage(
          onHistory: () => _openHistory(context),
          onSurvival: () => _openHeroChoice(context),
        ),
      ),
    );
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
          onChangeHero: () => _openHeroChoice(context),
          onReplay: () {
            final next = AdventureState(hero: hero, config: config);
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
        ),
      );
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onHistory,
    required this.onSurvival,
    super.key,
  });

  final VoidCallback onHistory;
  final VoidCallback onSurvival;

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
            child: Image.asset('assets/home_background.png', fit: BoxFit.cover),
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
                  AnimatedOpacity(
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
                          const SizedBox(height: 42),
                          ImageActionButton(
                            label: 'Survival mode',
                            icon: Icons.shield,
                            onPressed: widget.onSurvival,
                          ),
                        ],
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
  HistorySort _sort = HistorySort.recent;
  final Set<HeroType> _heroFilters = {...HeroType.values};

  @override
  Widget build(BuildContext context) {
    final records = [...widget.records.where(_matchesHero)]..sort(_sortRecords);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Add run',
            onPressed: _addManualRun,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: HeroType.values.map((hero) {
                  final selected = _heroFilters.contains(hero);
                  return FilterChip(
                    selected: selected,
                    avatar: CircleAvatar(
                      backgroundImage: AssetImage(hero.asset),
                      backgroundColor: hero.color,
                    ),
                    label: Text(hero.label),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _heroFilters.add(hero);
                        } else if (_heroFilters.length > 1) {
                          _heroFilters.remove(hero);
                        }
                      });
                    },
                  );
                }).toList(),
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
              const SizedBox(height: 16),
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('No game for this filter.'))
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: record.hero.color,
                              backgroundImage: AssetImage(record.hero.asset),
                            ),
                            title: Text(record.hero.label),
                            subtitle: Text(
                              '${_modeLabel(record.mode)} - ${_formatDate(record.date)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${record.score} pts',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete run',
                                  onPressed: () => _deleteRun(record),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesHero(GameRecord record) => _heroFilters.contains(record.hero);

  int _sortRecords(GameRecord a, GameRecord b) {
    return switch (_sort) {
      HistorySort.recent => b.date.compareTo(a.date),
      HistorySort.hero => a.hero.label.compareTo(b.hero.label),
      HistorySort.score => b.score.compareTo(a.score),
      HistorySort.date => a.date.compareTo(b.date),
    };
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

  Future<void> _deleteRun(GameRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete run?'),
        content: Text('${record.hero.label} - ${record.score} pts'),
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
      widget.onDeleteRecord(record);
      setState(() {});
    }
  }
}

class ManualRunDialog extends StatefulWidget {
  const ManualRunDialog({super.key});

  @override
  State<ManualRunDialog> createState() => _ManualRunDialogState();
}

class _ManualRunDialogState extends State<ManualRunDialog> {
  HeroType _hero = HeroType.barbare;
  SurvivalMode _mode = SurvivalMode.levelOne;
  late final TextEditingController _scoreController = TextEditingController(
    text: levelOneTarget.toString(),
  );

  @override
  void dispose() {
    _scoreController.dispose();
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
                  _scoreController.text = value.defaultTarget.toString();
                });
              },
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
            final score = int.tryParse(_scoreController.text.trim());
            if (score == null || score < 0) {
              return;
            }
            Navigator.of(context).pop(
              GameRecord(
                hero: _hero,
                date: DateTime.now(),
                score: score,
                mode: _mode,
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final heroes = HeroType.values
        .where((hero) => hero.label.toLowerCase().contains(query))
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
            const SizedBox(height: 14),
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
                  onTap: () => setState(() => _selectedHero = hero),
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
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.hero,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final HeroType hero;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
  SurvivalMode _mode = SurvivalMode.levelOne;
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

  @override
  Widget build(BuildContext context) {
    final config = switch (_mode) {
      SurvivalMode.levelOne => const SurvivalConfig(
        mode: SurvivalMode.levelOne,
        targetScore: levelOneTarget,
      ),
      SurvivalMode.levelTwo => const SurvivalConfig(
        mode: SurvivalMode.levelTwo,
        targetScore: levelTwoTarget,
      ),
      SurvivalMode.free => SurvivalConfig(
        mode: SurvivalMode.free,
        targetScore: _freeScore,
        freeCounts: Map<EnemyRank, int>.from(_freeCounts),
      ),
    };
    final canStart = _mode != SurvivalMode.free || _freeValid;

    return Scaffold(
      appBar: AppBar(title: const Text('Survival setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(widget.hero.asset),
                    backgroundColor: widget.hero.color,
                  ),
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
            ...SurvivalMode.values.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _mode = mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mode == mode
                          ? const Color(0xff4f2a86)
                          : const Color(0xff202020),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mode == mode
                            ? const Color(0xffc084fc)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _mode == mode
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: const Color(0xffc084fc),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _survivalModeTitle(mode),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(_survivalModeDescription(mode)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_mode == SurvivalMode.free) ...[
              const SizedBox(height: 8),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Free run',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minimum: 1 Level 1, 2 Level 4, 20 points.\nMaximum: 13 enemies.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current score: $_freeScore points',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
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
                    const SizedBox(height: 12),
                    ...[
                      EnemyRank.green,
                      EnemyRank.blue,
                      EnemyRank.violet,
                      EnemyRank.orange,
                    ].map(_buildRankCounter),
                    if (!_freeValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Adjust the enemy count before starting.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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

  Widget _buildRankCounter(EnemyRank rank) {
    final value = _freeCounts[rank] ?? 0;
    final min = rank == EnemyRank.green
        ? 1
        : rank == EnemyRank.orange
        ? 2
        : 0;
    final orangeLocked = rank == EnemyRank.orange && !_expertFreeMode;
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
                colorFilter: rank == EnemyRank.brown
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
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: value <= min || orangeLocked
                ? null
                : () => setState(() => _freeCounts[rank] = value - 1),
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            onPressed: _freeTotal >= 13 || orangeLocked
                ? null
                : () => setState(() => _freeCounts[rank] = value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({
    required this.adventure,
    required this.onRecordScore,
    required this.onChangeHero,
    required this.onReplay,
    super.key,
  });

  final AdventureState adventure;
  final ValueChanged<AdventureState> onRecordScore;
  final VoidCallback onChangeHero;
  final VoidCallback onReplay;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    final currentTarget = _currentTarget();
    if (adventure.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRecordScore(adventure);
      });
    }

    return Scaffold(
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
                  onChanged: () => setState(() {}),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mapSize = Size(
                              max(560, constraints.maxWidth),
                              max(1320, constraints.maxHeight + 520),
                            );
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                top: 80,
                                bottom: 170,
                              ),
                              child: SingleChildScrollView(
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
    );
  }

  EnemyNode? _currentTarget() {
    final currentEnemies = widget.adventure.enemies
        .where((enemy) => enemy.current && !enemy.defeated)
        .toList();
    if (currentEnemies.isEmpty) {
      return null;
    }
    return currentEnemies.first;
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
          child: EnemyMapTile(enemy: enemy, onTap: () => _openFight(enemy)),
        );
      }),
    ];
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
            sign * width * (0.12 + enemy.step * 0.045) +
            width * pairOffset;
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
            builder: (_) =>
                FightPage(adventure: widget.adventure, enemyId: enemy.id),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdventureDetailsPage(adventure: widget.adventure),
      ),
    );
  }
}

class MapHeader extends StatefulWidget {
  const MapHeader({
    required this.adventure,
    required this.onDetails,
    required this.onChanged,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onDetails;
  final VoidCallback onChanged;

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
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(adventure.hero.asset),
                backgroundColor: adventure.hero.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  adventure.hero.label,
                  style: const TextStyle(
                    color: Color(0xff54e98a),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff203528),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff54e98a)),
                ),
                child: Text(
                  '${adventure.score}/${adventure.targetScore} pts',
                  style: const TextStyle(
                    color: Color(0xff54e98a),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: MapStatChip(
                        icon: Icons.favorite,
                        label: 'HP',
                        value: adventure.health.toString(),
                        color: Colors.redAccent,
                        onTap: () => _openStatEditor('HP', adventure.health),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MapStatChip(
                        icon: Icons.bolt,
                        label: 'CP',
                        value: adventure.combatPoints.toString(),
                        color: Colors.amber,
                        onTap: () =>
                            _openStatEditor('CP', adventure.combatPoints),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff312449).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff9b58ff)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_fix_high,
                        color: Color(0xffc084fc),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          adventure.alterations.isEmpty
                              ? 'Tokens'
                              : adventure.alterations.join(', '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add token',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final value = await showAlterationDialog(context);
                          if (value != null) {
                            adventure.addAlteration(value);
                            widget.onChanged();
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xff1f2f24).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xff3d4a3e)),
            ),
            child: Row(
              children: [
                const Text(
                  'Bonuses',
                  style: TextStyle(
                    color: Color(0xff54e98a),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adventure.bonuses.isEmpty
                        ? 'No bonus yet'
                        : adventure.bonuses.join(', '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Run log',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDetails,
                  icon: const Icon(Icons.receipt_long),
                ),
              ],
            ),
          ),
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
                  Icon(
                    _editing == 'HP' ? Icons.favorite : Icons.bolt,
                    color: _editing == 'HP' ? Colors.redAccent : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editing!,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _draftValue--),
                    icon: const Icon(Icons.remove),
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
                  IconButton(
                    onPressed: () => setState(() => _draftValue++),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saveStat,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
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
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
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
          color: const Color(0xff2a2a2a).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xff3d4a3e)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xffbbcbbb),
                fontSize: 11,
                fontWeight: FontWeight.w800,
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
                  'CURRENT TARGET',
                  style: TextStyle(
                    color: Color(0xffbbcbbb),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  target == null ? 'No target' : target.label,
                  style: const TextStyle(
                    color: Color(0xff54e98a),
                    fontSize: 24,
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
                backgroundColor: const Color(0xff54e98a),
                foregroundColor: const Color(0xff003919),
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

class EnemyMapTile extends StatelessWidget {
  const EnemyMapTile({required this.enemy, required this.onTap, super.key});

  final EnemyNode enemy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = enemy.defeated ? 0.38 : 1.0;
    final accent = enemy.current ? const Color(0xff54e98a) : enemy.rank.color;
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
              width: enemy.current || isStart ? 4 : 2,
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
              if (enemy.current && !isStart)
                Positioned(
                  left: 0,
                  right: 0,
                  top: -16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ELITE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
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
            ],
          ),
        ),
      ),
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
          line(current, branchEnemies.firstWhere((enemy) => enemy.step == 4));
          line(current, branchEnemies.firstWhere((enemy) => enemy.step == 5));
          line(
            branchEnemies.firstWhere((enemy) => enemy.step == 4),
            branchEnemies.last,
          );
          line(
            branchEnemies.firstWhere((enemy) => enemy.step == 5),
            branchEnemies.last,
          );
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
              CircleAvatar(
                backgroundColor: adventure.hero.color,
                child: Text(adventure.hero.label[0]),
              ),
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
                  final value = await showAlterationDialog(context);
                  if (value != null) {
                    adventure.addAlteration(value);
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
          IconButton(
            tooltip: 'Retirer',
            onPressed: () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Ajouter',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class FightPage extends StatefulWidget {
  const FightPage({required this.adventure, required this.enemyId, super.key});

  final AdventureState adventure;
  final int enemyId;

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

  EnemyNode get enemy => widget.adventure.enemyById(widget.enemyId);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _dice.add(GameDie(id: i));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(enemy.label)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MapHeader(
              adventure: widget.adventure,
              onDetails: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AdventureDetailsPage(adventure: widget.adventure),
                ),
              ),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            EnemyCombatPanel(enemy: enemy, onChanged: () => setState(() {})),
            const SizedBox(height: 12),
            DicePanel(
              dice: _dice,
              diceToRoll: _diceToRoll,
              rollCount: _rollCount,
              editMode: _editMode,
              rerollOneMode: _rerollOneMode,
              editingDieId: _editingDieId,
              onDiceToRollChanged: (value) =>
                  setState(() => _diceToRoll = value),
              onRoll: _rollDice,
              onTapDie: _tapDie,
              onSelectFace: _selectFace,
              onValidateEdit: () => setState(() => _editingDieId = null),
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
            FilledButton.icon(
              onPressed: enemy.health <= 0 ? _finishCombat : null,
              icon: const Icon(Icons.flag),
              label: const Text('Finish combat'),
            ),
          ],
        ),
      ),
    );
  }

  void _rollDice() {
    if (_rollCount >= 3) {
      return;
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
      if (_rollCount == 3) {
        for (final die in _dice) {
          die.reserved = true;
        }
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
    });
  }

  void _finishCombat() {
    widget.adventure.completeCombat(enemy);
    if (enemy.defeated &&
        widget.adventure.health > 0 &&
        !widget.adventure.victory) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RewardPage(adventure: widget.adventure, enemy: enemy),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }
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
              CircleAvatar(
                backgroundColor: adventure.hero.color,
                child: Text(adventure.hero.label[0]),
              ),
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
                  final value = await showAlterationDialog(context);
                  if (value != null) {
                    adventure.addAlteration(value);
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
                          final value = await showAlterationDialog(context);
                          if (value != null) {
                            setState(() => enemy.alterations.add(value));
                            widget.onChanged();
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
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
                  Icon(
                    _editing == 'HP' ? Icons.favorite : Icons.bolt,
                    color: _editing == 'HP' ? enemy.rank.color : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editing!,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _draftValue--),
                    icon: const Icon(Icons.remove),
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
                  IconButton(
                    onPressed: () => setState(() => _draftValue++),
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saveEnemyStat,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
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
      enemy.health = _draftValue.clamp(0, enemy.maxHealth);
    } else if (_editing == 'CP') {
      enemy.combatPoints = _draftValue.clamp(0, 20);
    }
    setState(() => _editing = null);
    widget.onChanged();
  }
}

class GameDie {
  GameDie({required this.id});

  final int id;
  int? value;
  bool reserved = false;
}

class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.dice,
    required this.diceToRoll,
    required this.rollCount,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
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
  final ValueChanged<int> onDiceToRollChanged;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;

  @override
  Widget build(BuildContext context) {
    final rollDice = dice.where((die) => !die.reserved).toList();
    final reserveDice = dice.where((die) => die.reserved).toList();
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
          Text('Rolls: $rollCount / 3'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: rollCount < 3 ? onRoll : null,
                icon: const Icon(Icons.casino),
                label: const Text('Roll'),
              ),
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
          const SizedBox(height: 12),
          DiceZone(title: 'Dice to roll', dice: rollDice, onTapDie: onTapDie),
          const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dice
                .map((die) => DieTile(die: die, onTap: () => onTapDie(die)))
                .toList(),
          ),
        ],
      ),
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
        width: 48,
        height: 48,
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
            const SizedBox(height: 12),
            DetailSection(title: 'Bonus', items: adventure.bonuses),
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

Future<String?> showAlterationDialog(BuildContext context) {
  const alterations = [
    'Poison',
    'Burn',
    'Freeze',
    'Stun',
    'Blessed',
    'Shield',
    'Attack down',
    'Defense up',
  ];
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Add a status token'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: alterations
                .map(
                  (value) => ActionChip(
                    label: Text(value),
                    onPressed: () => Navigator.of(context).pop(value),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

List<EnemyNode> _generateEnemies(SurvivalConfig config) {
  final ranks = switch (config.mode) {
    SurvivalMode.levelOne => _levelOneRanks(),
    SurvivalMode.levelTwo => _levelTwoRanks(),
    SurvivalMode.free => _freeModeRanks(config.freeCounts),
  };
  final nodes = <EnemyNode>[_enemy(0, 'Start minion', ranks.first, null, 0)];

  var id = 1;
  var rankIndex = 1;
  for (final branch in BranchSide.values) {
    final remaining = ranks.length - rankIndex;
    final otherBranchSlots = branch == BranchSide.left
        ? (config.mode == SurvivalMode.levelTwo ? 7 : 6)
        : 0;
    final branchSlots = branch == BranchSide.left
        ? remaining - otherBranchSlots
        : remaining;
    for (var step = 1; step <= branchSlots; step++) {
      final rank = ranks[rankIndex++];
      nodes.add(_enemy(id++, '${branch.label} $step', rank, branch, step));
    }
  }
  return nodes;
}

List<EnemyRank> _levelOneRanks() {
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

List<EnemyRank> _levelTwoRanks() {
  return const [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.green,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.brown,
    EnemyRank.blue,
    EnemyRank.orange,
    EnemyRank.violet,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    EnemyRank.brown,
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

EnemyNode _enemy(
  int id,
  String label,
  EnemyRank rank,
  BranchSide? branch,
  int step,
) {
  return EnemyNode(
    id: id,
    label: label,
    rank: rank,
    branch: branch,
    step: step,
    maxHealth: switch (rank) {
      EnemyRank.green => 8,
      EnemyRank.blue => 11,
      EnemyRank.violet => 14,
      EnemyRank.brown => 16,
      EnemyRank.orange => 20,
    },
    pc: switch (rank) {
      EnemyRank.green => 1,
      EnemyRank.blue => 2,
      EnemyRank.violet => 3,
      EnemyRank.brown => 4,
      EnemyRank.orange => 5,
    },
    attacks: switch (rank) {
      EnemyRank.green => ['Quick hit: 3 damage'],
      EnemyRank.blue => ['Precise strike: 4 damage', 'Pressure: -1 CP'],
      EnemyRank.violet => ['Mystic slash: 5 damage', 'Weaken: status token'],
      EnemyRank.brown => ['Brutal charge: 6 damage', 'Guard break: -1 CP'],
      EnemyRank.orange => [
        'Boss rage: 8 damage',
        'Counter: reinforced defense',
      ],
    },
    defense: switch (rank) {
      EnemyRank.green => 'Blocks 1 damage',
      EnemyRank.blue => 'Blocks 2 damage',
      EnemyRank.violet => 'Blocks 3 damage',
      EnemyRank.brown => 'Blocks 3 damage and counters',
      EnemyRank.orange => 'Blocks 4 damage and counters',
    },
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
