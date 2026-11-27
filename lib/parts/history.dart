part of '../main.dart';

enum HistoryCategory {
  minionRush('Minion Rush', Icons.shield_rounded),
  bosses('Boss', Icons.local_fire_department_rounded);

  const HistoryCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class HistoryHubPage extends StatelessWidget {
  const HistoryHubPage({
    required this.records,
    required this.onAddRecord,
    required this.onDeleteRecord,
    super.key,
  });

  final List<GameRecord> records;
  final ValueChanged<GameRecord> onAddRecord;
  final ValueChanged<GameRecord> onDeleteRecord;

  void _openTab(BuildContext context, HistoryMainTab tab) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          records: records,
          initialTab: tab,
          onAddRecord: onAddRecord,
          onDeleteRecord: onDeleteRecord,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameDesign.obsidianBg,
      appBar: AppBar(
        title: const Text('History & Rankings'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: PlayerProfileChipButton(onUpdated: () {}),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a section',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 16),
              _HistoryHubCard(
                icon: Icons.history_rounded,
                title: 'My History',
                subtitle:
                    'Personal hero rankings, average scores, and run history.',
                accentColor: const Color(0xffffe22d),
                onTap: () => _openTab(context, HistoryMainTab.myHistory),
              ),
              const SizedBox(height: 14),
              _HistoryHubCard(
                icon: Icons.groups_rounded,
                title: 'Clans',
                subtitle:
                    'Private leaderboards and shared runs with your clan.',
                accentColor: const Color(0xff5eead4),
                onTap: () => _openTab(context, HistoryMainTab.clans),
              ),
              const SizedBox(height: 14),
              _HistoryHubCard(
                icon: Icons.public_rounded,
                title: 'Community',
                subtitle:
                    'Global Top 3 & Top 10 rankings across all Solo Quest players.',
                accentColor: const Color(0xffe2e8f0),
                onTap: () => _openTab(context, HistoryMainTab.community),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHubCard extends StatelessWidget {
  const _HistoryHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff1b1f2e),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withValues(alpha: 0.8),
                size: 26,
              ),
            ],
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
    this.initialTab = HistoryMainTab.myHistory,
    super.key,
  });

  final List<GameRecord> records;
  final ValueChanged<GameRecord> onAddRecord;
  final ValueChanged<GameRecord> onDeleteRecord;
  final RunDifficulty? initialDifficulty;
  final HistoryMainTab initialTab;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late HistoryMainTab _mainTab = widget.initialTab;
  HistorySort _sort = HistorySort.average;
  late CommunityLeaderboardMode _selectedMode = switch (widget.initialDifficulty) {
    RunDifficulty.naraxus => CommunityLeaderboardMode.naxarus,
    RunDifficulty.free => CommunityLeaderboardMode.free,
    RunDifficulty.hard => CommunityLeaderboardMode.difficult,
    _ => CommunityLeaderboardMode.medium,
  };
  bool _showTop3Only = true;
  bool _deleteMode = false;
  bool _isGridView = false;
  HeroType? _selectedGridHero;
  final Set<GameRecord> _selectedForDelete = {};
  final Set<HeroType> _expandedHeroes = {};

  bool get _isBossMode => _selectedMode.isBoss;
  RunDifficulty get _effectiveDifficulty => switch (_selectedMode) {
    CommunityLeaderboardMode.free => RunDifficulty.free,
    CommunityLeaderboardMode.medium => RunDifficulty.medium,
    CommunityLeaderboardMode.difficult => RunDifficulty.hard,
    CommunityLeaderboardMode.naxarus ||
    CommunityLeaderboardMode.ourokhor => RunDifficulty.naraxus,
  };

  bool _loadingCommunity = false;
  Map<String, PlayerProfileInfo> _communityProfiles = {};
  List<GameRecord> _communityRecords = [];
  List<ClanData> _clans = [];

  @override
  void initState() {
    super.initState();
    _refreshCommunityData();
  }

  Future<void> _refreshCommunityData() async {
    if (!mounted) return;
    setState(() => _loadingCommunity = true);
    try {
      final data = await CommunityClanRepository.instance
          .loadCommunityAndClansData(widget.records);
      if (!mounted) return;
      setState(() {
        _communityProfiles = data.profiles;
        _communityRecords = data.records;
        _clans = data.clans;
        _loadingCommunity = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCommunity = false);
      }
    }
  }

  bool _isRecordForSelectedMode(GameRecord record) =>
      LeaderboardCalculator.matchesLeaderboardMode(record, _selectedMode);

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
        title: Text(_mainTab.label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PlayerProfileChipButton(
              onUpdated: () {
                setState(() {});
                _refreshCommunityData();
              },
            ),
          ),
          if (_mainTab == HistoryMainTab.myHistory)
            IconButton(
              tooltip: _deleteMode ? 'Cancel delete' : 'Delete runs',
              onPressed: () {
                setState(() {
                  _deleteMode = !_deleteMode;
                  _selectedForDelete.clear();
                });
              },
              icon: Icon(_deleteMode ? Icons.close : Icons.delete_outline),
            )
          else
            IconButton(
              tooltip: 'Refresh rankings',
              onPressed: _refreshCommunityData,
              icon: _loadingCommunity
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mainTab == HistoryMainTab.community)
                Expanded(
                  child: CommunityLeaderboardView(
                    profilesByUserId: _communityProfiles,
                    allRecords: _communityRecords,
                    currentUserId: CommunityClanRepository.instance
                        .currentEffectiveUserId(),
                    onOpenProfile: () async {
                      final updated = await showPlayerProfileDialog(context);
                      if (updated == true) {
                        setState(() {});
                        _refreshCommunityData();
                      }
                    },
                  ),
                )
              else if (_mainTab == HistoryMainTab.clans)
                Expanded(
                  child: ClansTabView(
                    profilesByUserId: _communityProfiles,
                    allRecords: _communityRecords,
                    clans: _clans,
                    currentUserId: CommunityClanRepository.instance
                        .currentEffectiveUserId(),
                    onRefresh: () {
                      setState(() {});
                      _refreshCommunityData();
                    },
                  ),
                )
              else ...[
                // 5 Modes on 1 single row: Free | Medium | Difficult | Naxarus | Ourokhor
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xff1b1d29),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: CommunityLeaderboardMode.values.map((m) {
                      final selected = _selectedMode == m;
                      final accent = m.accentColor;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedMode = m;
                            _selectedForDelete.clear();
                            _selectedGridHero = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent
                                  : m.isBoss
                                  ? const Color(0xffff6b4a)
                                      .withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m.icon,
                                    size: 13,
                                    color: selected
                                        ? Colors.black
                                        : m.isBoss
                                        ? const Color(0xffff8a65)
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    m.label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: selected
                                          ? Colors.black
                                          : m.isBoss
                                          ? const Color(0xffffab91)
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Inline Sort by (icon + dropdown) + Top 3/10 + List/Grid toggle
                Row(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff1b1d29),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: GameDesign.actionPrimary,
                          ),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<HistorySort>(
                              value: _sort,
                              isDense: true,
                              dropdownColor: const Color(0xff1b1f2e),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              items: HistorySort.values
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _sort = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!_isGridView) ...[
                      _TopLimitToggle(
                        showTop3Only: _showTop3Only,
                        onChanged: (v) => setState(() => _showTop3Only = v),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                if (_sort == HistorySort.best)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Best score uses points first, then remaining HP when available.',
                      style: TextStyle(color: Color(0xffbbcbbb), fontSize: 11.5),
                    ),
                  ),
                const SizedBox(height: 10),
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
                          isBossMode: _isBossMode,
                          difficulty: _effectiveDifficulty,
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
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesFilters(GameRecord record) {
    return _isRecordForSelectedMode(record);
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
    final aQualified = a.value.length >= LeaderboardCalculator.minQualifiedRuns;
    final bQualified = b.value.length >= LeaderboardCalculator.minQualifiedRuns;
    if (aQualified != bQualified) {
      return aQualified ? -1 : 1;
    }

    if (!_isBossMode) {
      final avgScoreA = _averageScore(a.value);
      final avgScoreB = _averageScore(b.value);
      final scoreDiff = avgScoreB.compareTo(avgScoreA);
      if (scoreDiff != 0) return scoreDiff;

      final avgHpA = _averageHp(a.value);
      final avgHpB = _averageHp(b.value);
      final hpDiff = avgHpB.compareTo(avgHpA);
      if (hpDiff != 0) return hpDiff;

      final avgTimeA = _averageDurationSeconds(a.value);
      final avgTimeB = _averageDurationSeconds(b.value);
      final timeDiff = avgTimeA.compareTo(avgTimeB);
      if (timeDiff != 0) return timeDiff;

      final countDiff = b.value.length.compareTo(a.value.length);
      if (countDiff != 0) return countDiff;

      return a.key.label.toLowerCase().compareTo(b.key.label.toLowerCase());
    }

    final winsA = a.value.where(LeaderboardCalculator.isRunVictory).length;
    final winsB = b.value.where(LeaderboardCalculator.isRunVictory).length;
    final wilsonA = LeaderboardCalculator.computeWilsonScore(
      winsA,
      a.value.length,
    );
    final wilsonB = LeaderboardCalculator.computeWilsonScore(
      winsB,
      b.value.length,
    );
    final wilsonDiff = wilsonB.compareTo(wilsonA);
    if (wilsonDiff != 0) return wilsonDiff;

    final streakA = LeaderboardCalculator.computeActiveWinStreak(a.value);
    final streakB = LeaderboardCalculator.computeActiveWinStreak(b.value);
    final streakDiff = streakB.compareTo(streakA);
    if (streakDiff != 0) return streakDiff;

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
      var list = (items as List<MapEntry<HeroType, List<GameRecord>>>)
          .where((e) => e.value.length >= LeaderboardCalculator.minQualifiedRuns)
          .toList()
        ..sort(_compareHeroStats);

      if (!_showTop3Only) {
        final topList = list.take(10).toList();
        if (topList.isEmpty) {
          return _PodiumWidget(entries: entries);
        }
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff171a26),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: 15,
                    color: _selectedMode.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Top ${topList.length} Heroes • ${_selectedMode.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(topList.length, (i) {
                final hero = topList[i].key;
                final runs = topList[i].value;
                final wins = runs.where(LeaderboardCalculator.isRunVictory).length;
                final wilson = LeaderboardCalculator.computeWilsonScore(
                  wins,
                  runs.length,
                );
                final streak = LeaderboardCalculator.computeActiveWinStreak(runs);
                final avgScore = _averageScore(runs);
                final avgHp = _averageHp(runs);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: i < 3
                                ? GameDesign.actionPrimary
                                : Colors.white54,
                          ),
                        ),
                      ),
                      HeroAvatar(hero: hero, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hero.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        streak > 0
                            ? '$wins/${runs.length} • 🔥$streak'
                            : '$wins/${runs.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isBossMode)
                        GestureDetector(
                          onTap: () => showWilsonScoreDetailsDialog(
                            context,
                            title: 'My Stats',
                            hero: hero,
                            wins: wins,
                            total: runs.length,
                            wilsonScore: wilson,
                            activeStreak: streak,
                            avgScore: avgScore,
                            avgHp: avgHp,
                            modeLabel: _selectedMode.label,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GameDesign.actionPrimary
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: GameDesign.actionPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              '${(wilson * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: GameDesign.actionPrimary,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffffe22d)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xffffe22d)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            '${_formatNumber(avgScore)} avg',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xffffe22d),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }

      final pseudo = AppSettings.instance.playerPseudo.trim().isNotEmpty
          ? AppSettings.instance.playerPseudo.trim()
          : 'You';

      for (var i = 0; i < 3 && i < list.length; i++) {
        final r = list[i];
        final wins = r.value.where(LeaderboardCalculator.isRunVictory).length;
        final wilson = LeaderboardCalculator.computeWilsonScore(
          wins,
          r.value.length,
        );
        final avgScore = _averageScore(r.value);
        final bestScore = _bestScore(r.value);
        final streak = LeaderboardCalculator.computeActiveWinStreak(r.value);
        final String p = _isBossMode
            ? '${(wilson * 100).round()}% • $bestScore pts'
            : '${_formatNumber(avgScore)} avg pts';
        String s = _isBossMode
            ? '$pseudo • $wins/${r.value.length}'
            : (streak > 0
                ? '${r.value.length} runs • 🔥$streak'
                : '${r.value.length} runs');

        if (!_isBossMode && _sort == HistorySort.best) {
          s += ' • Max: $bestScore';
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
    final isBoss = _isBossMode;
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
        final wins = runs.where(LeaderboardCalculator.isRunVictory).length;
        final wilson = LeaderboardCalculator.computeWilsonScore(
          wins,
          runs.length,
        );
        final activeStreak = LeaderboardCalculator.computeActiveWinStreak(runs);
        final avgScore = _averageScore(runs);
        final avgHp = _averageHp(runs);
        final qualified = runs.length >= LeaderboardCalculator.minQualifiedRuns;
        return Opacity(
          opacity: qualified ? 1.0 : 0.48,
          child: Column(
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
                                  value:
                                      runs.any(_canDeleteRecord) &&
                                      runs
                                          .where(_canDeleteRecord)
                                          .every(_selectedForDelete.contains),
                                  onChanged: runs.any(_canDeleteRecord)
                                      ? (value) => _toggleRuns(runs, value)
                                      : null,
                                )
                              : HeroAvatar(hero: hero, size: 36),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hero.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activeStreak > 0
                                      ? '$wins/${runs.length} • 🔥$activeStreak'
                                      : '$wins/${runs.length}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                        _bestScore(runs).toString(),
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: isBoss
                            ? GestureDetector(
                                onTap: () => showWilsonScoreDetailsDialog(
                                  context,
                                  title: 'My Stats',
                                  hero: hero,
                                  wins: wins,
                                  total: runs.length,
                                  wilsonScore: wilson,
                                  activeStreak: activeStreak,
                                  avgScore: avgScore,
                                  avgHp: avgHp,
                                  modeLabel: _selectedMode.label,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: qualified
                                        ? GameDesign.actionPrimary
                                            .withValues(alpha: 0.16)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: qualified
                                          ? GameDesign.actionPrimary
                                              .withValues(alpha: 0.65)
                                          : Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${(wilson * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: qualified
                                          ? GameDesign.actionPrimary
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: qualified
                                      ? const Color(0xffffe22d)
                                          .withValues(alpha: 0.16)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: qualified
                                        ? const Color(0xffffe22d)
                                            .withValues(alpha: 0.65)
                                        : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatNumber(avgScore),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: qualified
                                        ? const Color(0xffffe22d)
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
          ),
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
    final isBoss = _isBossMode;
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
              _buildDetailChip(
                icon: Icons.verified_rounded,
                label: 'Wilson Score',
                value:
                    '${(LeaderboardCalculator.computeWilsonScore(runs.where(LeaderboardCalculator.isRunVictory).length, runs.length) * 100).round()}%',
                color: GameDesign.actionPrimary,
              ),
              _buildDetailChip(
                icon: Icons.local_fire_department_rounded,
                label: 'Active Streak',
                value:
                    '${LeaderboardCalculator.computeActiveWinStreak(runs)}',
                color: Colors.orangeAccent,
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

  bool _canDeleteRecord(GameRecord record) => true;

  void _toggleRuns(List<GameRecord> runs, bool? value) {
    final deletable = runs.where(_canDeleteRecord).toList();
    setState(() {
      if (value ?? false) {
        _selectedForDelete.addAll(deletable);
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
        title: const Text('Delete selected runs'),
        content: Text(
          'Are you sure you want to delete ${_selectedForDelete.length} selected run(s)?\n\nEverything selected will be permanently deleted (including hero stats, rankings, and active streaks for these runs). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
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
          // 6. Average Score (Minion Rush) or Wilson Score % (Bosses)
          Expanded(
            child: _HistoryHeaderItem(
              tooltip: isBossMode
                  ? 'Wilson Score % (tap a score for details)'
                  : 'Average Score (primary ranking stat)',
              onTap: () {
                _openMultiStatSheet(
                  context,
                  title: isBossMode
                      ? 'Wilson Score & Streak'
                      : 'Average Score & Qualification',
                  iconWidget: isBossMode
                      ? const Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: GameDesign.actionPrimary,
                        )
                      : const Text(
                          'AVG',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xffffe22d),
                          ),
                        ),
                  description: isBossMode
                      ? '95% Wilson lower-bound score balances win rate and run volume (minimum 3 runs to qualify for Top 3 / Top 10). Tap any hero\'s Wilson % pill to inspect their detailed stats.'
                      : 'Minion Rush heroes are ranked by Average Score (min 3 runs to qualify), then Average Remaining HP, then Fastest Average Time.',
                  lines: [
                    _StatLineData(
                      label: 'Min runs for Top 3 / Top 10',
                      value: '${LeaderboardCalculator.minQualifiedRuns} runs',
                    ),
                    _StatLineData(
                      label: 'Active Streak',
                      value: 'Current consecutive wins (🔥)',
                    ),
                  ],
                );
              },
              child: isBossMode
                  ? const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: GameDesign.actionPrimary,
                    )
                  : const Text(
                      'AVG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xffffe22d),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
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
    final isBoss = LeaderboardCalculator.isBossRunRecord(record);
    final enemiesLabel = isBoss ? '-' : record.enemiesDefeated.toString();
    final pointsLabel = record.score.toString();
    final isWin = LeaderboardCalculator.isRunVictory(record);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              if (deleteMode)
                Checkbox(value: selected, onChanged: onSelected)
              else if (showHero)
                HeroAvatar(hero: record.hero, size: 30)
              else
                const SizedBox(width: 12),
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
        if (!isBoss) Expanded(child: _HistoryMetricText(enemiesLabel)),
        Expanded(
          child: _HistoryMetricText(
            record.healthRemaining == null
                ? 'N/A'
                : record.healthRemaining.toString(),
          ),
        ),
        Expanded(
          flex: isBoss ? 2 : 1,
          child: _HistoryMetricText(_formatSmartDuration(record.duration)),
        ),
        Expanded(child: _HistoryMetricText(pointsLabel)),
        Expanded(
          child: Center(
            child: isWin
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Color(0xff4ade80),
                  )
                : const _HistoryMetricText('-', color: Colors.white24),
          ),
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
