import 'package:flutter/material.dart';

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

class AdventureState {
  AdventureState({
    required this.hero,
    required this.targetScore,
    this.health = 30,
    this.combatPoints = 2,
    this.selectedNode = 0,
  });

  final HeroType hero;
  final int targetScore;
  int health;
  int combatPoints;
  int selectedNode;
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

  AdventureState? _adventure;

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
      MaterialPageRoute<void>(builder: (_) => HistoryPage(records: _history)),
    );
  }

  void _openHeroChoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          onStart: (hero, targetScore) {
            setState(() {
              _adventure = AdventureState(hero: hero, targetScore: targetScore);
            });
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => MapPage(
                  adventure: _adventure!,
                  onRecordScore: (score) {
                    setState(() {
                      _history.insert(
                        0,
                        GameRecord(
                          hero: _adventure!.hero,
                          date: DateTime.now(),
                          score: score,
                        ),
                      );
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.onHistory,
    required this.onSurvival,
    super.key,
  });

  final VoidCallback onHistory;
  final VoidCallback onSurvival;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/dice-throne-logo.webp', height: 150),
              const SizedBox(height: 18),
              Text(
                'Mode survie solo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prototype personnel en francais',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history),
                label: const Text('Historique'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onSurvival,
                icon: const Icon(Icons.shield),
                label: const Text('Mode survie'),
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

  bool _matchesHero(GameRecord record) {
    return _heroFilter == null || record.hero == _heroFilter;
  }

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
  const HeroChoicePage({required this.onStart, super.key});

  final void Function(HeroType hero, int targetScore) onStart;

  @override
  State<HeroChoicePage> createState() => _HeroChoicePageState();
}

class _HeroChoicePageState extends State<HeroChoicePage> {
  HeroType _selectedHero = HeroType.barbare;
  final TextEditingController _targetController = TextEditingController(
    text: '33',
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
    super.key,
  });

  final AdventureState adventure;
  final ValueChanged<int> onRecordScore;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${adventure.hero.label} - objectif ${adventure.targetScore}',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            StatBar(
              health: adventure.health,
              combatPoints: adventure.combatPoints,
              onHealthChanged: (value) {
                setState(() => adventure.health = value.clamp(0, 99));
              },
              onCombatPointsChanged: (value) {
                setState(() => adventure.combatPoints = value.clamp(0, 20));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMapNodes(BuildContext context, Size size) {
    final width = size.width;
    final height = size.height;
    final nodes = <MapNode>[
      MapNode(index: 0, label: 'Etage 1', x: width / 2, y: 58),
    ];

    for (var step = 1; step <= 6; step++) {
      final y = 58 + step * ((height - 130) / 6);
      nodes.add(
        MapNode(
          index: step,
          label: 'Gauche $step',
          x: width / 2 - step * (width * 0.055),
          y: y,
        ),
      );
      nodes.add(
        MapNode(
          index: step + 6,
          label: 'Droite $step',
          x: width / 2 + step * (width * 0.055),
          y: y,
        ),
      );
    }

    return [
      Positioned.fill(child: CustomPaint(painter: _MapLinePainter(nodes))),
      ...nodes.map(
        (node) => Positioned(
          left: node.x - 45,
          top: node.y - 42,
          width: 90,
          height: 84,
          child: MonsterNode(
            node: node,
            selected: widget.adventure.selectedNode == node.index,
            onTap: () => _openFight(node),
          ),
        ),
      ),
    ];
  }

  void _openFight(MapNode node) {
    setState(() => widget.adventure.selectedNode = node.index);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FightPage(
          nodeLabel: node.label,
          hero: widget.adventure.hero,
          onSave: (score) {
            widget.onRecordScore(score);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}

class MapNode {
  const MapNode({
    required this.index,
    required this.label,
    required this.x,
    required this.y,
  });

  final int index;
  final String label;
  final double x;
  final double y;
}

class MonsterNode extends StatelessWidget {
  const MonsterNode({
    required this.node,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final MapNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.white : const Color(0xff42f58a),
            width: selected ? 4 : 2,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0x8842f58a),
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
              Image.asset('assets/fond-niv1.jpg', fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.18)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.68),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    node.index == 0 ? 'Etage 1' : 'Vert',
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
    );
  }
}

class _MapLinePainter extends CustomPainter {
  const _MapLinePainter(this.nodes);

  final List<MapNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = nodes.first;
    final leftNodes = nodes.where((node) => node.index >= 1 && node.index <= 6);
    final rightNodes = nodes.where((node) => node.index >= 7);
    _drawBranch(canvas, paint, [start, ...leftNodes]);
    _drawBranch(canvas, paint, [start, ...rightNodes]);
  }

  void _drawBranch(Canvas canvas, Paint paint, List<MapNode> branch) {
    for (var i = 0; i < branch.length - 1; i++) {
      canvas.drawLine(
        Offset(branch[i].x, branch[i].y),
        Offset(branch[i + 1].x, branch[i + 1].y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MapLinePainter oldDelegate) => false;
}

class StatBar extends StatelessWidget {
  const StatBar({
    required this.health,
    required this.combatPoints,
    required this.onHealthChanged,
    required this.onCombatPointsChanged,
    super.key,
  });

  final int health;
  final int combatPoints;
  final ValueChanged<int> onHealthChanged;
  final ValueChanged<int> onCombatPointsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xff1d1d1d),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: StepperStat(
              icon: Icons.favorite,
              label: 'PV',
              value: health,
              color: Colors.redAccent,
              onChanged: onHealthChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StepperStat(
              icon: Icons.bolt,
              label: 'PC',
              value: combatPoints,
              color: Colors.amber,
              onChanged: onCombatPointsChanged,
            ),
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
  const FightPage({
    required this.nodeLabel,
    required this.hero,
    required this.onSave,
    super.key,
  });

  final String nodeLabel;
  final HeroType hero;
  final ValueChanged<int> onSave;

  @override
  State<FightPage> createState() => _FightPageState();
}

class _FightPageState extends State<FightPage> {
  final TextEditingController _scoreController = TextEditingController();

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Affrontement')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.nodeLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ecran provisoire. On branchera ici le combat du monstre vert.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Score final a enregistrer',
                  suffixText: 'pts',
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  final score = int.tryParse(_scoreController.text.trim()) ?? 0;
                  widget.onSave(score);
                },
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer la partie'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
