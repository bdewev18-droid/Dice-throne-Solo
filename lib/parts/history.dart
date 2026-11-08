part of '../main.dart';

enum HistoryCategory {
  minionRush('Minion Rush', Icons.shield_rounded),
  bosses('Boss', Icons.local_fire_department_rounded);

  const HistoryCategory(this.label, this.icon);
  final String label;
  final IconData icon;
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
  late HistoryCategory _category =
      (widget.initialDifficulty == RunDifficulty.naraxus)
      ? HistoryCategory.bosses
      : HistoryCategory.minionRush;
  String _selectedBossKey = 'all';
  String _selectedBossDifficulty = 'all';
  late RunDifficulty _difficulty =
      (widget.initialDifficulty == RunDifficulty.naraxus)
      ? RunDifficulty.medium
      : (widget.initialDifficulty ?? RunDifficulty.medium);
  RandomFilter _randomFilter = RandomFilter.both;
  bool _deleteMode = false;
  bool _isGridView = false;
  HeroType? _selectedGridHero;
  final Set<GameRecord> _selectedForDelete = {};
  final Set<HeroType> _expandedHeroes = {};

  bool get _showRouteFilter =>
      _category == HistoryCategory.minionRush &&
      (_difficulty == RunDifficulty.medium ||
          _difficulty == RunDifficulty.hard);

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HistoryCategorySlider(
                    category: _category,
                    onChanged: (cat) {
                      setState(() {
                        _category = cat;
                        _selectedForDelete.clear();
                        _selectedGridHero = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _HistoryViewToggle(
                    isGrid: _isGridView,
                    onChanged: (val) {
                      setState(() {
                        _isGridView = val;
                        _selectedGridHero = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_category == HistoryCategory.bosses) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Boss',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBossKey,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'naraxus',
                                child: Text(
                                  'Naxarus',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'ourokhor',
                                child: Text(
                                  'Ourokhor',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBossKey = val;
                                  _selectedForDelete.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBossDifficulty,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'normal',
                                child: Text(
                                  'Normal',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'difficult',
                                child: Text(
                                  'Difficult',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBossDifficulty = val;
                                  _selectedForDelete.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<RunDifficulty>(
                            initialValue: _difficulty,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: RunDifficulty.values
                                .where((d) => d != RunDifficulty.naraxus)
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d.label,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() {
                                  _difficulty = val;
                                  _selectedForDelete.clear();
                                });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_showRouteFilter) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Route',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<RandomFilter>(
                              initialValue: _randomFilter,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              items: RandomFilter.values
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d.label,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _randomFilter = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sort by',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<HistorySort>(
                          initialValue: _sort,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: HistorySort.values
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _sort = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_sort == HistorySort.best)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Best score uses points first, then remaining HP when available.',
                    style: TextStyle(color: Color(0xffbbcbbb), fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    if (!_isGridView) ...[
                      _buildPodiumSection(
                        flatMode ? records : grouped.entries.toList(),
                        flatMode,
                      ),
                      const SizedBox(height: 16),
                      _HistoryHeaderRow(
                        isBossMode: _category == HistoryCategory.bosses,
                        difficulty: _difficulty,
                        allRecords: widget.records,
                      ),
                      const Divider(),
                      if (flatMode)
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No game for this filter.'),
                            ),
                          )
                        else
                          ...records.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _RunDetailRow(
                                record: r,
                                deleteMode: _deleteMode,
                                selected: _selectedForDelete.contains(r),
                                onSelected: (value) => _toggleRecord(r, value),
                                showHero: true,
                              ),
                            ),
                          )
                      else
                        ..._buildGroupedChildren(grouped),
                    ] else ...[
                      if (grouped.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No game for this filter.'),
                          ),
                        )
                      else ...[
                        _buildGridSection(grouped),
                        if (_selectedGridHero != null &&
                            grouped.containsKey(_selectedGridHero))
                          _buildHeroDetailSection(
                            _selectedGridHero!,
                            grouped[_selectedGridHero]!,
                          ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
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
    );
  }

  bool _matchesFilters(GameRecord record) {
    if (record.hero == HeroType.benjamin) {
      return false;
    }
    if (_category == HistoryCategory.bosses) {
      final isBoss =
          record.mode.difficulty == RunDifficulty.naraxus ||
          record.bossKey != null ||
          record.mode.name.toLowerCase().contains('boss') ||
          record.mode.name.toLowerCase().contains('naxarus') ||
          record.mode.name.toLowerCase().contains('ourokhor') ||
          record.mode.name.toLowerCase().contains('kaelen');
      if (!isBoss) return false;
      if (_selectedBossKey != 'all') {
        if (_selectedBossKey == 'naraxus') {
          final isNaraxus = (record.bossKey == 'naraxus') ||
              (record.bossKey == null &&
                  (record.mode.difficulty == RunDifficulty.naraxus ||
                      record.mode.name.toLowerCase().contains('naxarus')));
          if (!isNaraxus) return false;
        } else {
          final isTargetBoss = (record.bossKey == _selectedBossKey) ||
              record.mode.name.toLowerCase().contains(_selectedBossKey);
          if (!isTargetBoss) return false;
        }
      }
      if (_selectedBossDifficulty != 'all') {
        final isHard = record.mode == SurvivalMode.naraxusHard ||
            record.mode.name.toLowerCase().contains('hard') ||
            record.mode.name.toLowerCase().contains('difficult');
        if (_selectedBossDifficulty == 'difficult' && !isHard) return false;
        if (_selectedBossDifficulty == 'normal' && isHard) return false;
      }
      return true;
    }

    final isBoss =
        record.mode.difficulty == RunDifficulty.naraxus ||
        record.bossKey != null ||
        record.mode.name.toLowerCase().contains('boss') ||
        record.mode.name.toLowerCase().contains('naxarus') ||
        record.mode.name.toLowerCase().contains('ourokhor') ||
        record.mode.name.toLowerCase().contains('kaelen');
    if (isBoss) return false;

    if (record.mode.difficulty != _difficulty) {
      return false;
    }
    if (!_showRouteFilter) {
      return true;
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

  int _compareHeroStats(
    MapEntry<HeroType, List<GameRecord>> a,
    MapEntry<HeroType, List<GameRecord>> b,
  ) {
    final avgScoreA = _averageScore(a.value);
    final avgScoreB = _averageScore(b.value);
    final scoreDiff = avgScoreB.compareTo(avgScoreA);
    if (scoreDiff != 0) return scoreDiff;

    final countDiff = b.value.length.compareTo(a.value.length);
    if (countDiff != 0) return countDiff;

    final avgHpA = _averageHp(a.value);
    final avgHpB = _averageHp(b.value);
    final hpDiff = avgHpB.compareTo(avgHpA);
    if (hpDiff != 0) return hpDiff;

    final avgTimeA = _averageDurationSeconds(a.value);
    final avgTimeB = _averageDurationSeconds(b.value);
    final timeDiff = avgTimeA.compareTo(avgTimeB);
    if (timeDiff != 0) return timeDiff;

    return a.key.label.toLowerCase().compareTo(b.key.label.toLowerCase());
  }

  Map<HeroType, List<GameRecord>> _groupRecords(List<GameRecord> records) {
    final grouped = <HeroType, List<GameRecord>>{};
    for (final record in records) {
      if (record.hero == HeroType.benjamin) continue;
      grouped.putIfAbsent(record.hero, () => []).add(record);
    }
    for (final runs in grouped.values) {
      runs.sort(_sortRecords);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        if (_sort == HistorySort.best) {
          return _compareBestRecords(a.value.first, b.value.first);
        }
        return _compareHeroStats(a, b);
      });
    return Map.fromEntries(entries);
  }

  Widget _buildPodium(dynamic items, bool flatMode) {
    final entries = <_PodiumEntry>[];
    if (flatMode) {
      final list = items as List<GameRecord>;
      for (var i = 0; i < 3 && i < list.length; i++) {
        final r = list[i];
        String p = '';
        String s = '';
        if (_sort == HistorySort.time) {
          p = _formatDuration(r.duration);
          s = '${r.score} pts';
        } else if (_sort == HistorySort.date) {
          p = '${r.score} pts';
          s = '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year}';
        } else {
          p = '${r.score} pts';
          s = '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year}';
        }
        entries.add(_PodiumEntry(r.hero, p, s));
      }
    } else {
      var list = items as List<MapEntry<HeroType, List<GameRecord>>>;
      // Always sort the podium using the 5 tie-breaking criteria
      list = list.toList()..sort(_compareHeroStats);

      for (var i = 0; i < 3 && i < list.length; i++) {
        final r = list[i];
        final avgStr = _formatNumber(_averageScore(r.value));
        String p = '$avgStr avg';
        String s = '${r.value.length} game${r.value.length > 1 ? 's' : ''}';

        // Also show the best score in the secondary if sort is 'best', just for info
        if (_sort == HistorySort.best) {
          s += ' - Max: ${r.value.first.score}';
        }

        entries.add(_PodiumEntry(r.key, p, s));
      }
    }
    return _PodiumWidget(entries: entries);
  }

  Widget _buildPodiumSection(dynamic items, bool flatMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _buildPodium(items, flatMode),
    );
  }

  List<Widget> _buildGroupedChildren(Map<HeroType, List<GameRecord>> grouped) {
    final isBoss = _category == HistoryCategory.bosses;
    final unplayedHeroes =
        HeroType.values
            .where((h) => h != HeroType.benjamin && !grouped.containsKey(h))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    return [
      ...grouped.entries.map((entry) {
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
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          _deleteMode
                              ? Checkbox(
                                  value: runs.every(
                                    _selectedForDelete.contains,
                                  ),
                                  onChanged: (value) =>
                                      _toggleRuns(runs, value),
                                )
                              : HeroAvatar(hero: hero, size: 36),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hero.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetricText(runs.length.toString()),
                    ),
                    if (!isBoss)
                      Expanded(
                        child: _HistoryMetricText(
                          _roundedAverageLabel(_averageEnemies(runs)),
                        ),
                      ),
                    Expanded(
                      child: _HistoryMetricText(
                        _roundedAverageLabel(_averageHp(runs)),
                      ),
                    ),
                    Expanded(
                      flex: isBoss ? 2 : 1,
                      child: _HistoryMetricText(
                        _formatSmartDuration(
                          Duration(
                            seconds: _averageDurationSeconds(runs).round(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetricText(
                        _formatNumber(_averageScore(runs)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Column(
                  children: runs
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _RunDetailRow(
                            record: r,
                            deleteMode: _deleteMode,
                            selected: _selectedForDelete.contains(r),
                            onSelected: (value) => _toggleRecord(r, value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const Divider(height: 1),
          ],
        );
      }),
      if (unplayedHeroes.isNotEmpty) ...[
        ...unplayedHeroes.map((hero) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Opacity(
                            opacity: 0.38,
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                              child: HeroAvatar(hero: hero, size: 36),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hero.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: _HistoryMetricText('-', color: Colors.white24),
                    ),
                    if (!isBoss)
                      const Expanded(
                        child: _HistoryMetricText('-', color: Colors.white24),
                      ),
                    const Expanded(
                      child: _HistoryMetricText('-', color: Colors.white24),
                    ),
                    Expanded(
                      flex: isBoss ? 2 : 1,
                      child: const _HistoryMetricText(
                        '-',
                        color: Colors.white24,
                      ),
                    ),
                    const Expanded(
                      child: _HistoryMetricText('-', color: Colors.white24),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          );
        }),
      ],
    ];
  }

  Widget _buildGroupedList(Map<HeroType, List<GameRecord>> grouped) {
    return ListView(children: _buildGroupedChildren(grouped));
  }

  int _bestScore(List<GameRecord> runs) {
    if (runs.isEmpty) return 0;
    return runs.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildGridSection(Map<HeroType, List<GameRecord>> grouped) {
    final entries = grouped.entries.toList();
    final unplayedHeroes = HeroType.values
        .where((h) => h != HeroType.benjamin && !grouped.containsKey(h))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final hero = entry.key;
            final runs = entry.value;
            final score = _sort == HistorySort.best
                ? _bestScore(runs).toDouble()
                : _averageScore(runs);
            return _HeroGridCard(
              hero: hero,
              rank: index + 1,
              score: score,
              runsCount: runs.length,
              isSelected: _selectedGridHero == hero,
              onTap: () {
                setState(() {
                  _selectedGridHero =
                      (_selectedGridHero == hero ? null : hero);
                });
              },
            );
          },
        ),
        if (unplayedHeroes.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Unplayed heroes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unplayedHeroes.map((hero) {
              return Tooltip(
                message: '${hero.label} (No runs)',
                child: Opacity(
                  opacity: 0.35,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: HeroAvatar(hero: hero, size: 36),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroDetailSection(HeroType hero, List<GameRecord> runs) {
    final isBoss = _category == HistoryCategory.bosses;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff181a26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hero.color.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hero.color.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeroAvatar(hero: hero, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: hero.color,
                      ),
                    ),
                    Text(
                      '${runs.length} played run(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedGridHero = null),
                tooltip: 'Close details',
              ),
            ],
          ),
          const Divider(height: 18),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDetailChip(
                icon: Icons.games_rounded,
                label: 'Runs',
                value: runs.length.toString(),
              ),
              if (!isBoss)
                _buildDetailChip(
                  icon: Icons.shield_rounded,
                  label: 'Avg Enemies',
                  value: _roundedAverageLabel(_averageEnemies(runs)),
                ),
              _buildDetailChip(
                icon: Icons.favorite_rounded,
                label: 'Avg HP',
                value: _roundedAverageLabel(_averageHp(runs)),
                color: Colors.redAccent,
              ),
              _buildDetailChip(
                icon: Icons.timer_rounded,
                label: 'Avg Time',
                value: _formatSmartDuration(
                  Duration(seconds: _averageDurationSeconds(runs).round()),
                ),
                color: Colors.amberAccent,
              ),
              _buildDetailChip(
                icon: Icons.stars_rounded,
                label: 'Avg Score',
                value: '${_formatNumber(_averageScore(runs))} pts',
                color: const Color(0xff57b966),
              ),
              _buildDetailChip(
                icon: Icons.emoji_events_rounded,
                label: 'Best Score',
                value: '${_bestScore(runs)} pts',
                color: const Color(0xffFFD700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Individual Runs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${runs.length} total',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: runs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final r = runs[index];
                return _HeroUnitRunCard(
                  record: r,
                  index: runs.length - index,
                  deleteMode: _deleteMode,
                  selected: _selectedForDelete.contains(r),
                  onToggleSelect: (val) => _toggleRecord(r, val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final c = color ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xff12131d),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatList(List<GameRecord> records) {
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = records[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _RunDetailRow(
            record: r,
            deleteMode: _deleteMode,
            selected: _selectedForDelete.contains(r),
            onSelected: (value) => _toggleRecord(r, value),
            showHero: true,
          ),
        );
      },
    );
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

  void _toggleRecord(GameRecord record, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedForDelete.add(record);
      } else {
        _selectedForDelete.remove(record);
      }
    });
  }

  void _addManualRun() async {
    final record = await showDialog<GameRecord>(
      context: context,
      builder: (_) => const ManualRunDialog(),
    );
    if (record != null) {
      widget.onAddRecord(record);
      if (!widget.records.contains(record)) {
        widget.records.insert(0, record);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete runs'),
        content: Text(
          'Delete ${_selectedForDelete.length} selected run(s) from history?',
        ),
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

  double _averageScore(List<GameRecord> runs) =>
      runs.fold<int>(0, (total, run) => total + run.score) /
      (runs.isEmpty ? 1 : runs.length);

  double _averageEnemies(List<GameRecord> runs) =>
      runs.fold<int>(0, (total, run) => total + run.enemiesDefeated) /
      (runs.isEmpty ? 1 : runs.length);

  double _averageHp(List<GameRecord> runs) {
    final values = runs
        .map((run) => run.healthRemaining)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return 0;
    return values.fold<int>(0, (total, val) => total + val) / values.length;
  }

  double _averageDurationSeconds(List<GameRecord> runs) {
    final values = runs
        .map((run) => run.duration)
        .where((d) => d.inSeconds > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.fold<int>(0, (total, d) => total + d.inSeconds) /
        values.length;
  }

  String _roundedAverageLabel(num value) {
    return _formatNumber(value.toDouble());
  }
}

String _formatNumber(double val) {
  if (val.isNaN || val.isInfinite) return '0';
  if (val == val.roundToDouble()) {
    return val.toInt().toString();
  }
  return val.toStringAsFixed(1);
}

String _formatSmartDuration(Duration duration) {
  if (duration == Duration.zero) return 'N/A';
  final seconds = duration.inSeconds;
  if (seconds < 60) return '${seconds}s';
  final minutes = duration.inMinutes;
  if (minutes < 60) {
    final remSec = seconds % 60;
    return remSec > 0 ? '${minutes}m ${remSec}s' : '${minutes}m';
  }
  final hours = duration.inHours;
  final remMin = minutes % 60;
  if (hours < 24) {
    return remMin > 0 ? '${hours}h ${remMin}m' : '${hours}h';
  }
  final days = duration.inDays;
  final remHours = hours % 24;
  return remHours > 0 ? '${days}d ${remHours}h' : '${days}d';
}

class _StatLineData {
  const _StatLineData({required this.label, required this.value});
  final String label;
  final String value;
}

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow({
    required this.difficulty,
    required this.allRecords,
    this.isBossMode = false,
  });

  final RunDifficulty difficulty;
  final List<GameRecord> allRecords;
  final bool isBossMode;

  @override
  Widget build(BuildContext context) {
    final validRecords = allRecords
        .where((r) => r.hero != HeroType.benjamin)
        .toList();
    final minionRuns = validRecords
        .where((r) => r.mode.difficulty != RunDifficulty.naraxus)
        .toList();
    final naxarusRuns = validRecords
        .where((r) => r.mode.difficulty == RunDifficulty.naraxus)
        .toList();

    // 1. NB Runs
    final minionRunsCount = minionRuns.length;
    final naxarusRunsCount = naxarusRuns.length;
    final totalRunsCount = validRecords.length;

    // 2. Enemies
    final minionEnemiesTotal = minionRuns.fold(
      0,
      (sum, r) => sum + r.enemiesDefeated,
    );
    final minionEnemiesAvg = minionRuns.isEmpty
        ? 0.0
        : minionEnemiesTotal / minionRuns.length;
    final naxarusVictories = naxarusRuns
        .where((r) => r.isVictory || r.score >= 100)
        .length;
    final naxarusVictoriesAvg = naxarusRuns.isEmpty
        ? 0.0
        : naxarusVictories / naxarusRuns.length;

    // 3. HP
    final minionHpRuns = minionRuns.where(
      (r) => r.healthRemaining != null && r.healthRemaining! > 0,
    );
    final minionHpAvg = minionHpRuns.isEmpty
        ? 0.0
        : minionHpRuns.fold(0, (sum, r) => sum + r.healthRemaining!) /
              minionHpRuns.length;
    final naxarusHpRuns = naxarusRuns.where(
      (r) => r.healthRemaining != null && r.healthRemaining! > 0,
    );
    final naxarusHpAvg = naxarusHpRuns.isEmpty
        ? 0.0
        : naxarusHpRuns.fold(0, (sum, r) => sum + r.healthRemaining!) /
              naxarusHpRuns.length;

    // 4. Time
    final minionTimeTotal = minionRuns.fold(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    final minionTimeAvg = minionRuns.isEmpty
        ? Duration.zero
        : Duration(seconds: minionTimeTotal.inSeconds ~/ minionRuns.length);
    final naxarusTimeTotal = naxarusRuns.fold(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    final naxarusTimeAvg = naxarusRuns.isEmpty
        ? Duration.zero
        : Duration(seconds: naxarusTimeTotal.inSeconds ~/ naxarusRuns.length);
    final totalTime = minionTimeTotal + naxarusTimeTotal;

    // 5. Score
    final minionAvgScore = minionRuns.isEmpty
        ? 0.0
        : minionRuns.fold(0, (sum, r) => sum + r.score) / minionRuns.length;
    final mediumRuns = minionRuns.where(
      (r) => r.mode.difficulty == RunDifficulty.medium,
    );
    final hardRuns = minionRuns.where(
      (r) => r.mode.difficulty == RunDifficulty.hard,
    );
    final freeRuns = minionRuns.where(
      (r) => r.mode.difficulty == RunDifficulty.free,
    );

    final mediumMaxScore = mediumRuns.isEmpty
        ? 0
        : mediumRuns.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final hardMaxScore = hardRuns.isEmpty
        ? 0
        : hardRuns.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final freeMaxScore = freeRuns.isEmpty
        ? 0
        : freeRuns.map((r) => r.score).reduce((a, b) => a > b ? a : b);

    final naxarusMaxScore = naxarusRuns.isEmpty
        ? 0
        : naxarusRuns.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final naxarusAvgScore = naxarusRuns.isEmpty
        ? 0.0
        : naxarusRuns.fold(0, (sum, r) => sum + r.score) / naxarusRuns.length;

    final minionVictories = minionRuns
        .where((r) => r.isVictory || r.score >= r.mode.defaultTarget)
        .length;
    final minionSuccessRate = minionRuns.isEmpty
        ? 0
        : ((minionVictories / minionRuns.length) * 100).round();
    final naxarusSuccessRate = naxarusRuns.isEmpty
        ? 0
        : ((naxarusVictories / naxarusRuns.length) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('Hero / run')),
          // 1. NB
          Expanded(
            child: _HistoryHeaderItem(
              tooltip: 'Runs count',
              onTap: () => _openMultiStatSheet(
                context,
                title: 'Runs Count',
                iconWidget: const Text(
                  'NB',
                  style: TextStyle(
                    color: Color(0xffffe22d),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                description: 'Total number of games played.',
                lines: [
                  _StatLineData(
                    label: 'Minion Rush runs',
                    value: '$minionRunsCount runs',
                  ),
                  _StatLineData(
                    label: 'Naxarus runs',
                    value: '$naxarusRunsCount runs',
                  ),
                ],
                totalLine: _StatLineData(
                  label: 'Total runs',
                  value: '$totalRunsCount runs',
                ),
              ),
              child: const Text(
                'NB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffffe22d),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // 2. Enemies
          if (!isBossMode)
            Expanded(
              child: _HistoryHeaderItem(
                tooltip: 'Enemies defeated',
                onTap: () => _openMultiStatSheet(
                  context,
                  title: 'Enemies Defeated',
                  iconWidget: Image.asset(
                    'assets/minion.webp',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  description:
                      'Total number of enemies eliminated across games.',
                  lines: [
                    _StatLineData(
                      label: 'Minions eliminated',
                      value: '$minionEnemiesTotal',
                    ),
                    _StatLineData(
                      label: 'Naxarus Victories',
                      value: '$naxarusVictories',
                    ),
                    _StatLineData(
                      label: 'Minions eliminated avg',
                      value: '${_formatNumber(minionEnemiesAvg)}/run',
                    ),
                    _StatLineData(
                      label: 'Naxarus Victories avg',
                      value: '${_formatNumber(naxarusVictoriesAvg)}/run',
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/minion.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          // 3. HP
          Expanded(
            child: _HistoryHeaderItem(
              tooltip: 'Remaining HP',
              onTap: () => _openMultiStatSheet(
                context,
                title: 'Remaining HP',
                iconWidget: const Icon(
                  Icons.favorite,
                  size: 22,
                  color: Color(0xffffe22d),
                ),
                description: 'Hero\'s remaining health points upon victory.',
                lines: [
                  _StatLineData(
                    label: 'Minion Rush avg health',
                    value: '${_formatNumber(minionHpAvg)} HP',
                  ),
                  _StatLineData(
                    label: 'Naxarus avg health',
                    value: '${_formatNumber(naxarusHpAvg)} HP',
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                size: 18,
                color: Color(0xffffe22d),
              ),
            ),
          ),
          // 4. Time
          Expanded(
            flex: difficulty == RunDifficulty.naraxus ? 2 : 1,
            child: _HistoryHeaderItem(
              tooltip: 'Play time',
              onTap: () => _openMultiStatSheet(
                context,
                title: 'Play Time',
                iconWidget: const Icon(
                  Icons.timer,
                  size: 22,
                  color: Color(0xffffe22d),
                ),
                description: 'Total time spent in combat.',
                lines: [
                  _StatLineData(
                    label: 'Minion Rush play time',
                    value: _formatSmartDuration(minionTimeTotal),
                  ),
                  _StatLineData(
                    label: 'Minion Rush avg time',
                    value: '${_formatSmartDuration(minionTimeAvg)}/run',
                  ),
                  _StatLineData(
                    label: 'Naxarus play time',
                    value: _formatSmartDuration(naxarusTimeTotal),
                  ),
                  _StatLineData(
                    label: 'Naxarus avg time',
                    value: '${_formatSmartDuration(naxarusTimeAvg)}/run',
                  ),
                ],
                totalLine: _StatLineData(
                  label: 'Total Solo Quest play time',
                  value: _formatSmartDuration(totalTime),
                ),
              ),
              child: const Icon(
                Icons.timer,
                size: 18,
                color: Color(0xffffe22d),
              ),
            ),
          ),
          // 5. Score
          Expanded(
            child: _HistoryHeaderItem(
              tooltip: 'Score & Success',
              onTap: () => _openMultiStatSheet(
                context,
                title: 'Score & Success',
                iconWidget: const Icon(
                  Icons.emoji_events,
                  size: 22,
                  color: Color(0xffffe22d),
                ),
                description: 'Score metrics and success rates per game mode.',
                lines: [
                  _StatLineData(
                    label: 'Minion Rush avg score',
                    value: _formatNumber(minionAvgScore),
                  ),
                  _StatLineData(
                    label: 'Minion Rush Medium max score',
                    value: '$mediumMaxScore',
                  ),
                  _StatLineData(
                    label: 'Minion Rush Hard max score',
                    value: '$hardMaxScore',
                  ),
                  _StatLineData(
                    label: 'Minion Rush Free max score',
                    value: '$freeMaxScore',
                  ),
                  _StatLineData(
                    label: 'Naxarus max score',
                    value: '$naxarusMaxScore',
                  ),
                  _StatLineData(
                    label: 'Naxarus avg score',
                    value: _formatNumber(naxarusAvgScore),
                  ),
                  _StatLineData(
                    label: 'Minion Rush success rate',
                    value: '$minionSuccessRate%',
                  ),
                  _StatLineData(
                    label: 'Naxarus success rate',
                    value: '$naxarusSuccessRate%',
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 18,
                color: Color(0xffffe22d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMultiStatSheet(
    BuildContext context, {
    required String title,
    required Widget iconWidget,
    required String description,
    required List<_StatLineData> lines,
    _StatLineData? totalLine,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff1c1c24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const Divider(height: 20, color: Colors.white24),
                for (final line in lines) ...[
                  _StatLine(label: line.label, value: line.value),
                  const SizedBox(height: 6),
                ],
                if (totalLine != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.shade700,
                        width: 1,
                      ),
                    ),
                    child: _StatLine(
                      label: totalLine.label,
                      value: totalLine.value,
                      isHighlight: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryHeaderItem extends StatelessWidget {
  const _HistoryHeaderItem({
    required this.child,
    required this.tooltip,
    required this.onTap,
  });

  final Widget child;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    this.isHighlight = false,
  }) : isCurrent = false;

  final String label;
  final String value;
  final bool isCurrent;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 13,
            fontWeight: isHighlight || isCurrent
                ? FontWeight.bold
                : FontWeight.normal,
            color: isHighlight
                ? Colors.amberAccent
                : (isCurrent ? Colors.purpleAccent : Colors.white70),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.amberAccent : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HistoryCategorySlider extends StatelessWidget {
  const _HistoryCategorySlider({
    required this.category,
    required this.onChanged,
  });

  final HistoryCategory category;
  final ValueChanged<HistoryCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xff16171f),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: HistoryCategory.values.map((cat) {
          final isSelected = cat == category;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xff7a33cc)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xff7a33cc).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryViewToggle extends StatelessWidget {
  const _HistoryViewToggle({
    required this.isGrid,
    required this.onChanged,
  });

  final bool isGrid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xff16171f),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            icon: Icons.table_rows_rounded,
            isSelected: !isGrid,
            tooltip: 'Table view',
            onTap: () => onChanged(false),
          ),
          _buildItem(
            icon: Icons.grid_view_rounded,
            isSelected: isGrid,
            tooltip: 'Grid view',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff7a33cc) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xff7a33cc).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _HeroGridCard extends StatelessWidget {
  const _HeroGridCard({
    required this.hero,
    required this.rank,
    required this.score,
    required this.runsCount,
    required this.isSelected,
    required this.onTap,
  });

  final HeroType hero;
  final int rank;
  final double score;
  final int runsCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? rankColor;
    String rankLabel = '#$rank';
    if (rank == 1) {
      rankColor = const Color(0xffFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xffC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xffCD7F32);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? hero.color
                  : (rankColor != null
                      ? rankColor.withValues(alpha: 0.8)
                      : Colors.white24),
              width: isSelected ? 3.0 : (rankColor != null ? 1.5 : 1),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: hero.color.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.5),
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
                      colors: [
                        Color.fromRGBO(0, 0, 0, 0.45),
                        Colors.transparent,
                        Color.fromRGBO(0, 0, 0, 0.90),
                      ],
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: rankColor ?? Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rank == 1) ...[
                          const Icon(
                            Icons.emoji_events,
                            size: 11,
                            color: Color(0xffFFD700),
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          rankLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: rankColor ?? Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hero.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (rankColor ?? const Color(0xff7cc5ff))
                                  .withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${score.round()} pts',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: rankColor ?? const Color(0xff7cc5ff),
                            ),
                          ),
                        ),
                      ],
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

class _HeroUnitRunCard extends StatelessWidget {
  const _HeroUnitRunCard({
    required this.record,
    required this.index,
    required this.deleteMode,
    required this.selected,
    required this.onToggleSelect,
  });

  final GameRecord record;
  final int index;
  final bool deleteMode;
  final bool selected;
  final ValueChanged<bool?> onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff12131c),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? Colors.redAccent : Colors.white12,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Run #$index',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
              if (deleteMode)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: selected,
                    onChanged: onToggleSelect,
                  ),
                )
              else
                Text(
                  '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 15,
                color: Color(0xffFFD700),
              ),
              const SizedBox(width: 4),
              Text(
                '${record.score} pts',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xffFFD700),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
              const SizedBox(width: 3),
              Text(
                '${record.healthRemaining ?? '-'} HP',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const Spacer(),
              const Icon(Icons.timer, size: 12, color: Colors.amberAccent),
              const SizedBox(width: 3),
              Text(
                '${record.duration.inMinutes}m',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          if (record.enemiesDefeated > 0)
            Row(
              children: [
                const Icon(Icons.shield, size: 11, color: Colors.white38),
                const SizedBox(width: 3),
                Text(
                  '${record.enemiesDefeated} defeated',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HistoryMetricText extends StatelessWidget {
  const _HistoryMetricText(this.value, {this.color});

  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: color),
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
    final isNaraxus = record.mode.difficulty == RunDifficulty.naraxus;
    final enemiesLabel = isNaraxus ? '-' : record.enemiesDefeated.toString();
    final pointsLabel = record.score.toString();

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              if (deleteMode)
                Checkbox(value: selected, onChanged: onSelected)
              else if (showHero)
                HeroAvatar(hero: record.hero, size: 30),
              if (showHero || deleteMode) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  showHero ? record.hero.label : _formatDate(record.date),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: _HistoryMetricText('1')),
        if (!isNaraxus) Expanded(child: _HistoryMetricText(enemiesLabel)),
        Expanded(
          child: _HistoryMetricText(
            record.healthRemaining == null
                ? 'N/A'
                : record.healthRemaining.toString(),
          ),
        ),
        Expanded(
          flex: isNaraxus ? 2 : 1,
          child: _HistoryMetricText(_formatSmartDuration(record.duration)),
        ),
        Expanded(child: _HistoryMetricText(pointsLabel)),
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Add a run'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<HeroType>(
              initialValue: _hero,
              decoration: const InputDecoration(
                labelText: 'Hero',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
              ),
              items: HeroType.values
                  .where((h) => h != HeroType.benjamin)
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
            const SizedBox(height: 16),
            DropdownButtonFormField<SurvivalMode>(
              initialValue: _mode,
              decoration: const InputDecoration(
                labelText: 'Scenario',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
              ),
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
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
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
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Score',
                suffixText: 'pts',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
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
            const SizedBox(height: 16),
            TextField(
              controller: _healthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Remaining HP',
                hintText: 'Not recorded',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time played',
                helperText: 'Minutes, optional',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black12,
              ),
            ),
          ],
        ),
      ),
      actions: [
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

class _PodiumEntry {
  _PodiumEntry(this.hero, this.primary, this.secondary);
  final HeroType hero;
  final String primary;
  final String secondary;
}

class _PodiumWidget extends StatelessWidget {
  const _PodiumWidget({required this.entries});
  final List<_PodiumEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (entries.length > 1)
            _buildPodiumItem(entries[1], 2, 80, const Color(0xffC0C0C0)),
          if (entries.length > 1) const SizedBox(width: 16),
          _buildPodiumItem(entries[0], 1, 110, const Color(0xffFFD700)),
          if (entries.length > 2) const SizedBox(width: 16),
          if (entries.length > 2)
            _buildPodiumItem(entries[2], 3, 60, const Color(0xffCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    _PodiumEntry entry,
    int rank,
    double height,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.primary,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (entry.secondary.isNotEmpty)
          Text(
            entry.secondary,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
          child: CircleAvatar(
            radius: rank == 1 ? 38 : 30,
            backgroundColor: Colors.black,
            backgroundImage: AssetImage(entry.hero.asset),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: rank == 1 ? 80 : 64,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
