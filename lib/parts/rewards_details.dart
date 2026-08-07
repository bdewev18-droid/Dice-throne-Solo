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
        : GameEngine.rewardForD20(d20, chest: currentRewardRank.rewardChestKey);
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
                    if (outcome == null)
                      const Text(
                        'Roll the die',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      )
                    else
                      _RewardOutcomeDisplay(outcome: outcome),
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
                        widget.adventure.applyReward(d20, currentRewardRank);
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

class _RewardOutcomeDisplay extends StatelessWidget {
  const _RewardOutcomeDisplay({required this.outcome});

  final RewardOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (outcome.healthDelta > 0)
        _EffectImageBadge(
          value: '+${outcome.healthDelta}',
          asset: 'assets/illustration/soin.webp',
          textColor: Colors.white,
          size: 42,
          fontSize: 15,
        ),
      if (outcome.cpDelta > 0)
        SizedBox(
          width: 46,
          height: 46,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _PcTriangleBadge(value: outcome.cpDelta),
          ),
        ),
    ];
    if (badges.isEmpty) {
      return Text(
        outcome.label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
      );
    }
    return Semantics(
      label: outcome.label,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: badges,
        ),
      ),
    );
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
  List<String> duelTokens = const [],
}) {
  final alterations = statusTokenRules
      .where((rule) => rule.editorVisible)
      .where((rule) => !forMinion || rule.minionAllowed)
      .toList(growable: false);
  final hiddenCurrent = <String>[];
  final counts = <String, int>{for (final rule in alterations) rule.label: 0};
  for (final value in current) {
    final rule = TokenCatalogRepository.byLabel(value);
    if (rule != null && !rule.editorVisible) {
      hiddenCurrent.add(value);
      continue;
    }
    final label = rule?.label ?? value;
    counts[label] = (counts[label] ?? 0) + 1;
  }
  var filter = 'duel';
  var query = '';
  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final selected = <String>[...hiddenCurrent];
        for (final entry in counts.entries) {
          selected.addAll(List.filled(entry.value, entry.key));
        }
        final duelKeys = {
          ...duelTokens.map(_normalizeTokenKey),
          ...current
              .where((token) => _isVisibleStatusTokenLabel(token))
              .map(_normalizeTokenKey),
        };
        List<StatusTokenRule> visibleRules;
        if (filter == 'positive') {
          visibleRules = alterations
              .where((rule) => rule.kind == StatusTokenKind.positive)
              .toList(growable: false);
        } else if (filter == 'negative') {
          visibleRules = alterations
              .where((rule) => rule.kind == StatusTokenKind.negative)
              .toList(growable: false);
        } else {
          visibleRules = alterations
              .where(
                (rule) =>
                    duelKeys.contains(_normalizeTokenKey(rule.label)) ||
                    rule.aliases.any(
                      (alias) => duelKeys.contains(_normalizeTokenKey(alias)),
                    ),
              )
              .toList(growable: false);
          if (visibleRules.isEmpty) {
            visibleRules = alterations.take(12).toList(growable: false);
          }
        }
        final normalizedQuery = query.trim().toLowerCase();
        if (normalizedQuery.isNotEmpty) {
          visibleRules = visibleRules
              .where((rule) {
                final searchable = [
                  rule.label,
                  rule.frLabel,
                  rule.description,
                  ...rule.aliases,
                ].join(' ').toLowerCase();
                return searchable.contains(normalizedQuery);
              })
              .toList(growable: false);
        }
        visibleRules.sort((a, b) => a.label.compareTo(b.label));
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Status tokens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'duel', label: Text('Current duel')),
                      ButtonSegment(value: 'positive', label: Text('Positive')),
                      ButtonSegment(value: 'negative', label: Text('Negative')),
                    ],
                    selected: {filter},
                    onSelectionChanged: (selection) =>
                        setDialogState(() => filter = selection.first),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search token',
                    ),
                    onChanged: (value) => setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: visibleRules.length,
                      itemBuilder: (context, index) {
                        final rule = visibleRules[index];
                        final count = counts[rule.label] ?? 0;
                        return TokenPickerCard(
                          rule: rule,
                          count: count,
                          onImageTap: () => showTokenDetails(context, rule),
                          onMinus: count <= 0
                              ? null
                              : () => setDialogState(
                                  () => counts[rule.label] = count - 1,
                                ),
                          onPlus: count >= rule.maxStack
                              ? null
                              : () => setDialogState(
                                  () => counts[rule.label] = count + 1,
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Not every token is listed here: character-only tokens or tokens that cannot affect an enemy are not included. The green or orange dot shows whether the app handles the token automatically or whether you must resolve it manually.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

bool _isVisibleStatusTokenLabel(String value) {
  final rule = TokenCatalogRepository.byLabel(_compactTokenBaseLabel(value));
  return rule?.editorVisible ?? true;
}

void showTokenDetails(BuildContext context, StatusTokenRule rule) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xff111111),
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusTokenImage(rule: rule, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (rule.frLabel.isNotEmpty && rule.frLabel != rule.label)
                      Text(
                        rule.frLabel,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Stack limit: ${rule.maxStack}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _TokenSupportDot(rule: rule),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rule.description.isEmpty ? 'No description yet.' : rule.description,
            style: const TextStyle(height: 1.35),
          ),
        ],
      ),
    ),
  );
}

class TokenPickerCard extends StatelessWidget {
  const TokenPickerCard({
    required this.rule,
    required this.count,
    required this.onImageTap,
    required this.onMinus,
    required this.onPlus,
    super.key,
  });

  final StatusTokenRule rule;
  final int count;
  final VoidCallback onImageTap;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onImageTap,
              child: Stack(
                children: [
                  Center(child: StatusTokenImage(rule: rule, size: 64)),
                  Positioned(top: 0, right: 0, child: _TokenSupportDot(rule: rule)),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${rule.maxStack}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            rule.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundIconButton(
                icon: Icons.add,
                tooltip: 'Add',
                onPressed: onPlus,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              RoundIconButton(
                icon: Icons.remove,
                tooltip: 'Remove',
                onPressed: onMinus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusTokenImage extends StatelessWidget {
  const StatusTokenImage({required this.rule, this.size = 34, super.key});

  final StatusTokenRule rule;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = rule.imageAsset;
    if (image != null) {
      return Image.asset(image, width: size, height: size, fit: BoxFit.contain);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rule.kind == StatusTokenKind.positive
            ? const Color(0xff246b39)
            : const Color(0xff6d1f28),
        border: Border.all(color: Colors.white70),
      ),
      child: Text(
        _tokenShortLabel(rule.label),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: max(8, size * 0.22),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TokenSupportDot extends StatelessWidget {
  const _TokenSupportDot({required this.rule});

  final StatusTokenRule rule;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: rule.appSupported ? 'Handled by app' : 'Manual resolution',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rule.appSupported
              ? const Color(0xff41dd74)
              : const Color(0xffff9f1c),
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
      ),
    );
  }
}
