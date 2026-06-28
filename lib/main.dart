import 'dart:math';

import 'package:flutter/material.dart';

const String appVersionLabel = 'Version 1.1.0';

void main() {
  runApp(const DiceThroneSurvieApp());
}

enum HeroType {
  barbare('Barbare', Alignment.centerLeft, Color(0xffd94a24)),
  elfeLunaire('Elfe lunaire', Alignment.centerRight, Color(0xff64b7e8));

  const HeroType(this.label, this.imageAlignment, this.color);

  final String label;
  final Alignment imageAlignment;
  final Color color;
}

enum EnemyRank {
  green('Vert', 1, Color(0xff34d36d), 'assets/map_green.jpg'),
  blue('Bleu', 2, Color(0xff3bb9ff), 'assets/map_blue.png'),
  violet('Violet', 3, Color(0xff9b58ff), 'assets/map_violet.png'),
  orange('Orange', 6, Color(0xffff8a2b), 'assets/map_orange.png');

  const EnemyRank(this.label, this.points, this.color, this.asset);

  final String label;
  final int points;
  final Color color;
  final String asset;
}

enum BranchSide {
  left('Gauche'),
  right('Droite');

  const BranchSide(this.label);

  final String label;
}

enum HistorySort {
  recent('Derniere partie'),
  hero('Hero'),
  score('Meilleur score'),
  date('Date de partie');

  const HistorySort(this.label);

  final String label;
}

class GameRecord {
  const GameRecord({
    required this.hero,
    required this.date,
    required this.score,
  });

  final HeroType hero;
  final DateTime date;
  final int score;
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
  }) : health = maxHealth;

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
  bool defeated = false;
  bool current = false;
}

class AdventureState {
  AdventureState({required this.hero, required this.targetScore})
    : enemies = _generateEnemies(targetScore) {
    _refreshAvailability();
    log('Campagne creee: objectif $targetScore points.');
  }

  final HeroType hero;
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
    log('PV du hero ajustes a $health.');
    if (health == 0) {
      _endAdventure(false);
    }
  }

  void setHeroPc(int value) {
    combatPoints = value.clamp(0, 20);
    log('PC du hero ajustes a $combatPoints.');
  }

  void addAlteration(String value) {
    alterations.add(value);
    log('Alteration ajoutee au hero: $value.');
  }

  void completeCombat(EnemyNode enemy) {
    if (!enemy.defeated && enemy.health <= 0) {
      enemy.defeated = true;
      score += enemy.rank.points;
      log('${enemy.label} vaincu: +${enemy.rank.points} points.');
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
      bonuses.add('D20 $d20: +1 PV');
      log('Butin valide: D20 $d20, +1 PV.');
    } else {
      combatPoints = (combatPoints + 1).clamp(0, 20);
      bonuses.add('D20 $d20: +1 PC');
      log('Butin valide: D20 $d20, +1 PC.');
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
    log('Voie ${branch.label.toLowerCase()} engagee.');
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
    final branchEnemies = enemies.where((enemy) => enemy.branch == branch);
    final step1 = branchEnemies.firstWhere((enemy) => enemy.step == 1);
    final step2 = branchEnemies.firstWhere((enemy) => enemy.step == 2);
    final step3 = branchEnemies.firstWhere((enemy) => enemy.step == 3);
    final choiceA = branchEnemies.firstWhere((enemy) => enemy.step == 4);
    final choiceB = branchEnemies.firstWhere((enemy) => enemy.step == 5);
    final boss = branchEnemies.firstWhere((enemy) => enemy.step == 6);

    if (!step1.defeated) {
      return [step1];
    }
    if (!step2.defeated) {
      return [step2];
    }
    if (!step3.defeated) {
      return [step3];
    }
    final choices = [
      choiceA,
      choiceB,
    ].where((enemy) => !enemy.defeated).toList();
    if (choices.isNotEmpty) {
      return choices;
    }
    if (!boss.defeated) {
      return [boss];
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
          onSurvival: (targetScore) => _openHeroChoice(context, targetScore),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HistoryPage(records: _history)),
    );
  }

  void _openHeroChoice(BuildContext context, int targetScore) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          initialTargetScore: targetScore,
          onStart: (hero, target) {
            final adventure = AdventureState(hero: hero, targetScore: target);
            _replaceWithMap(context, adventure, hero, target);
          },
        ),
      ),
    );
  }

  void _replaceWithMap(
    BuildContext context,
    AdventureState adventure,
    HeroType hero,
    int target,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MapPage(
          adventure: adventure,
          onRecordScore: _recordAdventure,
          onChangeHero: () => _openHeroChoice(context, target),
          onReplay: () {
            final next = AdventureState(hero: hero, targetScore: target);
            _replaceWithMap(context, next, hero, target);
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
  final ValueChanged<int> onSurvival;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _targetController = TextEditingController(
    text: '33',
  );
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
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/home_background.png', fit: BoxFit.cover),
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
                  Align(
                    alignment: Alignment.topRight,
                    child: VersionPill(label: appVersionLabel),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 650),
                    opacity: _showActions ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_showActions,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _targetController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Objectif de campagne',
                              suffixText: 'pts',
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.62),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ImageActionButton(
                            label: 'Historique',
                            icon: Icons.history,
                            onPressed: widget.onHistory,
                          ),
                          const SizedBox(height: 12),
                          ImageActionButton(
                            label: 'Mode survie',
                            icon: Icons.shield,
                            onPressed: () {
                              final target =
                                  int.tryParse(_targetController.text.trim()) ??
                                  33;
                              widget.onSurvival(target);
                            },
                          ),
                        ],
                      ),
                    ),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('assets/button_background.png'),
              fit: BoxFit.fill,
            ),
          ),
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
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.records, super.key});

  final List<GameRecord> records;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistorySort _sort = HistorySort.recent;
  HeroType? _heroFilter;

  @override
  Widget build(BuildContext context) {
    final records = [...widget.records.where(_matchesHero)]..sort(_sortRecords);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<HeroType?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Tous')),
                  ButtonSegment(
                    value: HeroType.barbare,
                    label: Text('Barbare'),
                  ),
                  ButtonSegment(
                    value: HeroType.elfeLunaire,
                    label: Text('Elfe'),
                  ),
                ],
                selected: {_heroFilter},
                onSelectionChanged: (selection) {
                  setState(() => _heroFilter = selection.first);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HistorySort>(
                initialValue: _sort,
                decoration: const InputDecoration(
                  labelText: 'Trier par',
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
                    ? const Center(child: Text('Aucune partie pour ce filtre.'))
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: record.hero.color,
                              child: Text(record.score.toString()),
                            ),
                            title: Text(record.hero.label),
                            subtitle: Text(_formatDate(record.date)),
                            trailing: Text(
                              '${record.score} pts',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
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

  bool _matchesHero(GameRecord record) =>
      _heroFilter == null || record.hero == _heroFilter;

  int _sortRecords(GameRecord a, GameRecord b) {
    return switch (_sort) {
      HistorySort.recent => b.date.compareTo(a.date),
      HistorySort.hero => a.hero.label.compareTo(b.hero.label),
      HistorySort.score => b.score.compareTo(a.score),
      HistorySort.date => a.date.compareTo(b.date),
    };
  }
}

class HeroChoicePage extends StatefulWidget {
  const HeroChoicePage({
    required this.initialTargetScore,
    required this.onStart,
    super.key,
  });

  final int initialTargetScore;
  final void Function(HeroType hero, int targetScore) onStart;

  @override
  State<HeroChoicePage> createState() => _HeroChoicePageState();
}

class _HeroChoicePageState extends State<HeroChoicePage> {
  HeroType _selectedHero = HeroType.barbare;
  late final TextEditingController _targetController = TextEditingController(
    text: widget.initialTargetScore.toString(),
  );

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choix du hero')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: HeroType.values
                  .map(
                    (hero) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: hero == HeroType.barbare ? 8 : 0,
                          left: hero == HeroType.elfeLunaire ? 8 : 0,
                        ),
                        child: HeroCard(
                          hero: hero,
                          selected: _selectedHero == hero,
                          onTap: () => setState(() => _selectedHero = hero),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Objectif de points pour l aventure',
                suffixText: 'pts',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                final targetScore =
                    int.tryParse(_targetController.text.trim()) ?? 33;
                widget.onStart(_selectedHero, targetScore);
              },
              icon: const Icon(Icons.map),
              label: const Text('Commencer la map'),
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
          image: DecorationImage(
            image: const AssetImage('assets/heroes.jpg'),
            fit: BoxFit.cover,
            alignment: hero.imageAlignment,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Align(
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
        ),
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
    if (adventure.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRecordScore(adventure);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${adventure.hero.label} - ${adventure.score}/${adventure.targetScore} pts',
        ),
        actions: [
          IconButton(
            tooltip: 'Detail',
            onPressed: () => _openDetails(context),
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (adventure.finished)
              EndAdventureBanner(
                adventure: adventure,
                onReplay: widget.onReplay,
                onChangeHero: widget.onChangeHero,
                onDetails: () => _openDetails(context),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 2.2,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: _buildMapNodes(context, constraints.biggest),
                      ),
                    ),
                  );
                },
              ),
            ),
            HeroStatusBar(
              adventure: adventure,
              onChanged: () => setState(() {}),
              onDetails: () => _openDetails(context),
            ),
          ],
        ),
      ),
    );
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
        return Positioned(
          left: offset.dx - 48,
          top: offset.dy - 44,
          width: 96,
          height: 88,
          child: EnemyMapTile(enemy: enemy, onTap: () => _openFight(enemy)),
        );
      }),
    ];
  }

  Map<int, Offset> _positionsFor(Size size) {
    final width = size.width;
    final height = size.height;
    final rowGap = (height - 130) / 6;
    final map = <int, Offset>{0: Offset(width / 2, 58)};
    for (var step = 1; step <= 6; step++) {
      final y = 58 + step * rowGap;
      final spread = width * (0.09 + step * 0.035);
      map[step] = Offset(width / 2 - spread, y);
      map[step + 6] = Offset(width / 2 + spread, y);
    }
    return map;
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
            adventure.victory ? 'Victoire: aventure terminee' : 'Fin de survie',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            '${adventure.score} points - ${adventure.defeatedEnemies.length} ennemis vaincus',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: onReplay, child: const Text('Rejouer')),
              OutlinedButton(
                onPressed: onChangeHero,
                child: const Text('Changer de hero'),
              ),
              OutlinedButton(onPressed: onDetails, child: const Text('Detail')),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enemy.current ? Colors.white : enemy.rank.color,
              width: enemy.current ? 4 : 2,
            ),
            boxShadow: enemy.current
                ? [
                    BoxShadow(
                      color: enemy.rank.color.withValues(alpha: 0.62),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(enemy.rank.asset, fit: BoxFit.cover),
                Container(color: Colors.black.withValues(alpha: 0.16)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Text(
                      enemy.defeated
                          ? 'Battu'
                          : '${enemy.rank.label} +${enemy.rank.points}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
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

class MapLinePainter extends CustomPainter {
  const MapLinePainter(this.enemies, this.positions);

  final List<EnemyNode> enemies;
  final Map<int, Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void line(int a, int b) =>
        canvas.drawLine(positions[a]!, positions[b]!, paint);
    for (final start in [1, 7]) {
      line(0, start);
      line(start, start + 1);
      line(start + 1, start + 2);
      line(start + 2, start + 3);
      line(start + 2, start + 4);
      line(start + 3, start + 5);
      line(start + 4, start + 5);
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
                tooltip: 'Alterations',
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
                  label: 'PV',
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
                  label: 'PC',
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
            HeroCombatPanel(
              adventure: widget.adventure,
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
              onPressed: _finishCombat,
              icon: const Icon(Icons.flag),
              label: const Text('Terminer le combat'),
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
        'Lancer $_rollCount: ${rollable.map((die) => die.value).join(', ')}.',
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
          'Relance speciale du de ${die.id + 1}: ${die.value}.',
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
      widget.adventure.log('De ${die.id + 1} modifie en $face.');
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
                  label: 'PV',
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
                  label: 'PC',
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

class EnemyCombatPanel extends StatelessWidget {
  const EnemyCombatPanel({
    required this.enemy,
    required this.onChanged,
    super.key,
  });

  final EnemyNode enemy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
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
                child: StepperStat(
                  icon: Icons.favorite,
                  label: 'PV',
                  value: enemy.health,
                  color: enemy.rank.color,
                  onChanged: (value) {
                    enemy.health = value.clamp(0, enemy.maxHealth);
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StepperStat(
                  icon: Icons.bolt,
                  label: 'PC',
                  value: enemy.pc,
                  color: Colors.amber,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Attaques', style: TextStyle(fontWeight: FontWeight.w900)),
          ...enemy.attacks.map((attack) => Text('- $attack')),
          const SizedBox(height: 8),
          Text('Defense: ${enemy.defense}'),
        ],
      ),
    );
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
                  'Zone de des',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              DropdownButton<int>(
                value: diceToRoll,
                items: [1, 2, 3, 4, 5, 6]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count des'),
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
          Text('Lancers: $rollCount / 3'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: rollCount < 3 ? onRoll : null,
                icon: const Icon(Icons.casino),
                label: const Text('Lancer'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleEdit,
                icon: const Icon(Icons.tune),
                label: Text(editMode ? 'Stop modification' : 'Modifier un de'),
              ),
              OutlinedButton.icon(
                onPressed: onToggleRerollOne,
                icon: const Icon(Icons.refresh),
                label: Text(rerollOneMode ? 'Choisir un de' : 'Relancer un de'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DiceZone(title: 'Des a lancer', dice: rollDice, onTapDie: onTapDie),
          const SizedBox(height: 12),
          DiceZone(title: 'Reserve', dice: reserveDice, onTapDie: onTapDie),
          if (editingDie != null) ...[
            const SizedBox(height: 12),
            Text(
              'Modifier le de ${editingDie.id + 1}',
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
              child: const Text('Valider ce de'),
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
      appBar: AppBar(title: const Text('Butin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.enemy.label} vaincu',
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
                      'D20 de gain',
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
                          ? '+1 PV'
                          : '+1 PC',
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
                          label: Text(d20 == null ? 'Lancer' : 'Relancer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: d20 == null ? null : _modifyD20,
                          icon: const Icon(Icons.tune),
                          label: const Text('Modifier'),
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
                label: const Text('Valider le gain'),
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
        title: const Text('Choisir le resultat'),
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
      appBar: AppBar(title: const Text('Detail de la partie')),
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
            DetailSection(title: 'Alterations', items: adventure.alterations),
            DetailSection(title: 'Historique', items: adventure.logs),
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
          if (items.isEmpty) const Text('Aucun element.'),
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
    'Brulure',
    'Gel',
    'Sonne',
    'Beni',
    'Bouclier',
    'Malus attaque',
    'Bonus defense',
  ];
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Ajouter une alteration'),
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

List<EnemyNode> _generateEnemies(int targetScore) {
  final ranks = _ranksForTarget(targetScore);
  final nodes = <EnemyNode>[
    _enemy(0, 'Gardien vert', EnemyRank.green, null, 0),
  ];

  var rankIndex = 0;
  for (final branch in BranchSide.values) {
    final base = branch == BranchSide.left ? 1 : 7;
    for (var step = 1; step <= 6; step++) {
      final rank = step == 6 ? EnemyRank.orange : ranks[rankIndex++];
      nodes.add(
        _enemy(base + step - 1, '${branch.label} $step', rank, branch, step),
      );
    }
  }
  return nodes;
}

List<EnemyRank> _ranksForTarget(int targetScore) {
  final remainingTarget = (targetScore - 13).clamp(10, 60);
  final ranks = List<EnemyRank>.filled(10, EnemyRank.green);
  var total = 10;
  var index = 0;
  while (total < remainingTarget && index < ranks.length * 3) {
    final slot = index % ranks.length;
    final current = ranks[slot];
    if (current == EnemyRank.green && total + 1 <= remainingTarget) {
      ranks[slot] = EnemyRank.blue;
      total += 1;
    } else if (current == EnemyRank.blue && total + 1 <= remainingTarget) {
      ranks[slot] = EnemyRank.violet;
      total += 1;
    } else if (current == EnemyRank.violet && total + 3 <= remainingTarget) {
      ranks[slot] = EnemyRank.orange;
      total += 3;
    }
    index++;
  }
  return ranks;
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
      EnemyRank.orange => 20,
    },
    pc: switch (rank) {
      EnemyRank.green => 1,
      EnemyRank.blue => 2,
      EnemyRank.violet => 3,
      EnemyRank.orange => 5,
    },
    attacks: switch (rank) {
      EnemyRank.green => ['Coup rapide: 3 degats'],
      EnemyRank.blue => ['Frappe precise: 4 degats', 'Pression: -1 PC'],
      EnemyRank.violet => [
        'Entaille mystique: 5 degats',
        'Affaiblir: alteration',
      ],
      EnemyRank.orange => [
        'Rage du boss: 8 degats',
        'Riposte: defense renforcee',
      ],
    },
    defense: switch (rank) {
      EnemyRank.green => 'Bloque 1 degat',
      EnemyRank.blue => 'Bloque 2 degats',
      EnemyRank.violet => 'Bloque 3 degats',
      EnemyRank.orange => 'Bloque 4 degats et riposte',
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
