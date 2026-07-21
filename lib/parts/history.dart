part of '../main.dart';

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
                      child: _HistoryMetricText(runs.length.toString()),
                    ),
                    Expanded(
                      child: _HistoryMetricText(
                        _roundedAverageLabel(_averageEnemies(runs)),
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetricText(_averageHealthLabel(runs)),
                    ),
                    Expanded(
                      child: _HistoryMetricText(_averageDurationLabel(runs)),
                    ),
                    Expanded(
                      child: _HistoryMetricText(
                        _roundedAverageLabel(_averageScore(runs)),
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

  String _roundedAverageLabel(num value) {
    final floorValue = value.floor();
    final fraction = value - floorValue;
    return (fraction < 0.6 ? floorValue : floorValue + 1).toString();
  }

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
    return _roundedAverageLabel(average);
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
          Expanded(
            child: _HistoryHeaderIcon(Icons.sports_martial_arts, 'Enemies'),
          ),
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

class _HistoryMetricText extends StatelessWidget {
  const _HistoryMetricText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-4, 0),
      child: Text(value, textAlign: TextAlign.center),
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
        const Expanded(child: _HistoryMetricText('1')),
        Expanded(
          child: _HistoryMetricText(record.enemiesDefeated.toString()),
        ),
        Expanded(
          child: _HistoryMetricText(
            record.healthRemaining == null
                ? 'n/a'
                : record.healthRemaining.toString(),
          ),
        ),
        Expanded(
          child: _HistoryMetricText(_formatDuration(record.duration)),
        ),
        Expanded(
          child: _HistoryMetricText(record.score.toString()),
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

