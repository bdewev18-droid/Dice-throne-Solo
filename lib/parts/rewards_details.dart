part of '../main.dart';

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
  int _confirmed = 0;

  @override
  Widget build(BuildContext context) {
    final d20 = _d20;
    final total = widget.enemy.rewardChests.clamp(1, 4).toInt();
    final currentRewardRank = _rewardRankFor(_confirmed);
    final outcome = d20 == null
        ? null
        : GameEngine.rewardForD20(
            d20,
            chest: currentRewardRank.rewardChestKey,
          );
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
                    if (total > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_confirmed + 1}/$total',
                        style: TextStyle(
                          color: currentRewardRank.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
                        widget.adventure.applyReward(
                          d20,
                          currentRewardRank,
                        );
                        if (_confirmed + 1 >= total) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _confirmed++;
                            _d20 = null;
                          });
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8f43ff),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check),
                label: Text(
                  total > 1 && _confirmed + 1 < total
                      ? 'Confirm and next'
                      : 'Confirm reward',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EnemyRank _rewardRankFor(int index) {
    final ranks = widget.enemy.rewardRanks;
    if (index >= 0 && index < ranks.length) {
      return ranks[index];
    }
    return widget.enemy.rewardRank;
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
          titlePadding: const EdgeInsets.fromLTRB(24, 18, 8, 0),
          title: Row(
            children: [
              const Expanded(child: Text('Edit status tokens')),
              IconButton(
                tooltip: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
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

