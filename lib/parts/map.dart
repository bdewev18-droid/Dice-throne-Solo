part of '../main.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    required this.adventure,
    required this.historyRecords,
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
  final List<GameRecord> historyRecords;
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
    required this.historyRecords,
    required this.onRecord,
    required this.onOpenHistory,
    super.key,
  });

  final HeroType hero;
  final List<GameRecord> historyRecords;
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
      cp: naraxusProfile.cp,
      attacks: naraxusProfile.attacks,
      defense: naraxusProfile.defense,
      defenseDice: naraxusProfile.defenseDice,
      attackPlan: naraxusProfile.attackPlan,
      cardAsset: naraxusProfile.cardAsset,
      profileKey: naraxusProfile.key,
      initialTokens: naraxusProfile.initialTokens,
      rewardChests: naraxusProfile.rewardChests,
      rewardRank: naraxusProfile.rewardRank,
      rewardRanks: naraxusProfile.rewardRanks,
      passives: naraxusProfile.passives,
      defenseDisplayRows: naraxusProfile.defenseDisplayRows,
      passiveDisplayRows: naraxusProfile.passiveDisplayRows,
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
      historyRecords: widget.historyRecords,
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
  static const double _mapVisualOffsetX = -1400;
  static const double _mapVisualOffsetY = -2000;
  static const double _latePathFocusOffsetX = 0;
  static const double _latePathFocusOffsetY = 0;
  static const double _mapVisualBleedX = 760;
  static const double _mapVisualBleedY = 1080;
  static double _savedMapScale = 1.0;
  static const double _focusedMapScale = 1.0;
  static const double _branchChoiceMapScale = _focusedMapScale;
  late final TransformationController _mapController =
      TransformationController();
  int? _selectedEnemyId;
  Size? _latestMapSize;
  Size? _latestMapViewportSize;

  @override
  void initState() {
    super.initState();
    _mapController.value = _mapController.value.clone()
      ..scaleByDouble(_savedMapScale, _savedMapScale, 1, 1);
    _mapController.addListener(() {
      _savedMapScale = _mapController.value.getMaxScaleOnAxis();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnEnemy(_currentTarget(), immediate: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adventure = widget.adventure;
    final availableTargets = _availableTargets();
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
                    showRewards: false,
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
                              final renderSize = Size(
                                mapSize.width + _mapVisualBleedX * 2,
                                mapSize.height + _mapVisualBleedY * 2,
                              );
                              _latestMapSize = mapSize;
                              _latestMapViewportSize = constraints.biggest;
                              return InteractiveViewer(
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(4000),
                                minScale: 0.45,
                                maxScale: 2.4,
                                transformationController: _mapController,
                                child: SizedBox(
                                  width: renderSize.width,
                                  height: renderSize.height,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ..._buildMapNodes(context, mapSize),
                                    ],
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
                              onDetails: () => Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst),
                            ),
                          ),
                        if (adventure.defeatedEnemies.isEmpty)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 126,
                            child: MapObjectiveCard(adventure: adventure),
                          ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: CurrentTargetCard(
                            enemy: currentTarget,
                            choices: availableTargets,
                            onSelectChoice: _selectEnemy,
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
    final currentEnemies = _availableTargets();
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

  List<EnemyNode> _availableTargets() {
    return widget.adventure.enemies
        .where((enemy) => widget.adventure.canSelectEnemy(enemy))
        .toList();
  }

  List<Widget> _buildMapNodes(BuildContext context, Size size) {
    final positions = _positionsFor(
      size,
      includeBleed: true,
      visualOffset: true,
    );
    return [
      Positioned.fill(
        child: CustomPaint(
          painter: MapLinePainter(widget.adventure.enemies, positions),
        ),
      ),
      ...widget.adventure.enemies.map((enemy) {
        final offset = positions[enemy.id]!;
        final available = widget.adventure.canSelectEnemy(enemy);
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
            available: available,
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
    if (!widget.adventure.canSelectEnemy(enemy)) {
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

  Map<int, Offset> _positionsFor(
    Size size, {
    bool includeBleed = false,
    bool visualOffset = false,
  }) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final bottom = height - 180;
    final rowGap = max(150.0, (height - 360) / 7);
    Offset position(Offset offset) {
      var translated = offset;
      if (includeBleed) {
        translated += const Offset(_mapVisualBleedX, _mapVisualBleedY);
      }
      if (visualOffset) {
        translated += const Offset(_mapVisualOffsetX, _mapVisualOffsetY);
      }
      return translated;
    }

    final positions = <int, Offset>{0: position(Offset(centerX, bottom))};
    for (final branch in BranchSide.values) {
      final branchEnemies =
          widget.adventure.enemies
              .where((enemy) => enemy.branch == branch)
              .toList()
            ..sort((a, b) => a.step.compareTo(b.step));
      final sign = branch == BranchSide.left ? -1.0 : 1.0;
      final choiceSteps = _choiceStepsBeforeBoss(branchEnemies);
      for (final enemy in branchEnemies) {
        final visualBossStep = _visualBossStep(branchEnemies);
        final isAttachedViseer =
            enemy.rank == EnemyRank.viseer && enemy.step == visualBossStep + 1;
        final isBossWithAttachedViseer =
            enemy.rank == EnemyRank.orange &&
            branchEnemies.any(
              (candidate) =>
                  candidate.rank == EnemyRank.viseer &&
                  candidate.step == enemy.step + 1,
            );
        final pairOffset = enemy.step == choiceSteps.$1
            ? -0.1
            : enemy.step == choiceSteps.$2
            ? 0.1
            : isBossWithAttachedViseer
            ? -0.055 * sign
            : isAttachedViseer
            ? 0.055 * sign
            : 0.0;
        final x =
            centerX +
            sign * width * (0.075 + enemy.step * 0.032) +
            width * pairOffset * 0.72;
        final visualStep =
            enemy.step == choiceSteps.$1 || enemy.step == choiceSteps.$2
            ? (choiceSteps.$1 + choiceSteps.$2) / 2
            : isAttachedViseer
            ? visualBossStep.toDouble()
            : enemy.step.toDouble();
        final y = bottom - rowGap * visualStep;
        positions[enemy.id] = position(Offset(x, y));
      }
    }
    return positions;
  }

  (int, int) _choiceStepsBeforeBoss(List<EnemyNode> branchEnemies) {
    final bossStep = _visualBossStep(branchEnemies);
    return (bossStep - 2, bossStep - 1);
  }

  int _visualBossStep(List<EnemyNode> branchEnemies) {
    if (branchEnemies.length >= 2 &&
        branchEnemies.last.rank == EnemyRank.viseer &&
        branchEnemies[branchEnemies.length - 2].rank == EnemyRank.orange) {
      return branchEnemies[branchEnemies.length - 2].step;
    }
    return branchEnemies.isEmpty ? 0 : branchEnemies.last.step;
  }

  Future<void> _openFight(EnemyNode enemy) async {
    if (!widget.adventure.canSelectEnemy(enemy)) {
      return;
    }
    final secondaryEnemy = _attachedViseerFor(enemy);
    if (AppSettings.instance.developerMode) {
      final selectedProfile = await Navigator.of(context).push<EnemyProfile>(
        MaterialPageRoute<EnemyProfile>(
          builder: (_) => RecipeEnemySelectionPage(enemy: enemy),
        ),
      );
      if (!mounted || selectedProfile == null) {
        return;
      }
      enemy.applyProfile(selectedProfile);
    }
    if (secondaryEnemy != null) {
      final viseerProfile =
          _profileByKey('viseer') ?? _profilesForRank(EnemyRank.viseer).first;
      secondaryEnemy.applyProfile(viseerProfile);
      secondaryEnemy
        ..label = 'Viseer'
        ..rank = EnemyRank.viseer
        ..cardAsset = 'assets/enemy_viseer.jpg'
        ..health = viseerProfile.maxHealth
        ..combatPoints = viseerProfile.cp;
    }
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
                      historyRecords: widget.historyRecords,
                      enemyId: enemy.id,
                      secondaryEnemyId: secondaryEnemy?.id,
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

  EnemyNode? _attachedViseerFor(EnemyNode enemy) {
    if (enemy.rank != EnemyRank.orange || enemy.branch == null) {
      return null;
    }
    final branchEnemies =
        widget.adventure.enemies
            .where((candidate) => candidate.branch == enemy.branch)
            .toList()
          ..sort((a, b) => a.step.compareTo(b.step));
    if (branchEnemies.length < 2) {
      return null;
    }
    final last = branchEnemies.last;
    final beforeLast = branchEnemies[branchEnemies.length - 2];
    if (last.rank == EnemyRank.viseer &&
        beforeLast.id == enemy.id &&
        !last.defeated) {
      return last;
    }
    return null;
  }

  void _centerOnEnemy(EnemyNode? enemy, {bool immediate = false}) {
    final mapSize = _latestMapSize;
    final viewportSize = _latestMapViewportSize;
    if (enemy == null || mapSize == null || viewportSize == null) {
      return;
    }
    final positions = _positionsFor(
      mapSize,
      includeBleed: true,
      visualOffset: true,
    );
    final focus = _mapFocusFor(enemy, positions);
    if (focus == null) {
      return;
    }
    final cameraOffset = _focusOffsetFor(enemy);
    final scale = _isBranchChoiceFocus()
        ? _branchChoiceMapScale
        : _focusedMapScale;
    final safeScale = scale.clamp(0.45, 2.4).toDouble();
    _savedMapScale = safeScale;
    final target = Offset(
      viewportSize.width / 2 + cameraOffset.dx,
      viewportSize.height / 2 + cameraOffset.dy,
    );
    _mapController.value = Matrix4.identity()
      ..translateByDouble(
        target.dx - focus.dx * safeScale,
        target.dy - focus.dy * safeScale,
        0,
        1,
      )
      ..scaleByDouble(safeScale, safeScale, 1, 1);
  }

  Offset? _mapFocusFor(EnemyNode fallback, Map<int, Offset> positions) {
    final currentEnemies = widget.adventure.enemies
        .where((enemy) => widget.adventure.canSelectEnemy(enemy))
        .toList();
    if (currentEnemies.length >= 2) {
      final currentPositions = currentEnemies
          .map((enemy) => positions[enemy.id])
          .whereType<Offset>()
          .toList();
      if (currentPositions.length >= 2) {
        final sum = currentPositions.fold<Offset>(
          Offset.zero,
          (total, offset) => total + offset,
        );
        return sum / currentPositions.length.toDouble();
      }
    }
    final fallbackPosition = positions[fallback.id];
    if (fallbackPosition == null) {
      return null;
    }
    return fallbackPosition;
  }

  Offset _focusOffsetFor(EnemyNode enemy) {
    if (enemy.branch != null && enemy.step >= 2) {
      return const Offset(_latePathFocusOffsetX, _latePathFocusOffsetY);
    }
    return Offset.zero;
  }

  bool _isBranchChoiceFocus() {
    final currentEnemies = widget.adventure.enemies
        .where((enemy) => widget.adventure.canSelectEnemy(enemy))
        .toList();
    return currentEnemies.length >= 2;
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
        border: Border(bottom: BorderSide(color: panelBorderGrey)),
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
              if (!adventure.config.isNaraxusMode && adventure.targetScore > 0)
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
                  width: 62,
                  child: _MapCombatBadgeButton(
                    tooltip: 'HP: ${adventure.health}',
                    onTap: () => _openStatEditor('HP', adventure.health),
                    child: _HpHeartBadge(
                      value: adventure.health,
                      style: _CombatHpStyle.hero,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 62,
                  child: _MapCombatBadgeButton(
                    tooltip: 'CP: ${adventure.combatPoints}',
                    onTap: () => _openStatEditor('CP', adventure.combatPoints),
                    child: _PcTriangleBadge(value: adventure.combatPoints),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: HeroTokenStrip(
                    tokens: adventure.alterations,
                    onEdit: () async {
                      final values = await showAlterationDialog(
                        context,
                        adventure.alterations,
                        duelTokens: TokenCatalogRepository.heroTokens(adventure.hero),
                        isMapPage: true,
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
              border: panelBorderGrey,
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
                          icon: Icons.add,
                          tooltip: 'Add',
                          onPressed: () => setState(() => _draftValue++),
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
                          icon: Icons.remove,
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _draftValue--),
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

class _MapCombatBadgeButton extends StatelessWidget {
  const _MapCombatBadgeButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 58,
                height: 42,
                child: FittedBox(fit: BoxFit.contain, child: child),
              ),
            ),
          ),
        ),
      ),
    );
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
    this.borderColor,
    super.key,
  });

  final IconData? icon;
  final String label;
  final String value;
  final Color color;
  final Color? accent;
  final Color? borderColor;
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
          border: Border.all(
            color: borderColor ?? accent ?? const Color(0xff3d4a3e),
          ),
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
    required this.choices,
    required this.onSelectChoice,
    required this.onFight,
    super.key,
  });

  final EnemyNode? enemy;
  final List<EnemyNode> choices;
  final ValueChanged<EnemyNode> onSelectChoice;
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
        border: Border.all(color: panelBorderGrey, width: 2),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (choices.length > 1) ...[
                  Row(
                    children: [
                      for (var index = 0; index < choices.length; index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: FilledButton(
                              onPressed: () => onSelectChoice(choices[index]),
                              style: FilledButton.styleFrom(
                                backgroundColor: choices[index].id == target?.id
                                    ? choices[index].rank.color
                                    : const Color(0xff202020),
                                foregroundColor: choices[index].id == target?.id
                                    ? Colors.black
                                    : choices[index].rank.color,
                                side: BorderSide(
                                  color: choices[index].rank.color,
                                  width: choices[index].id == target?.id
                                      ? 2
                                      : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: Text(_rankLevelRoman(choices[index].rank)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
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
          ),
        ],
      ),
    );
  }
}

String _rankLevelRoman(EnemyRank rank) {
  return switch (rank) {
    EnemyRank.green => 'I',
    EnemyRank.blue => 'II',
    EnemyRank.violet => 'III',
    EnemyRank.orange || EnemyRank.viseer => 'IV',
    EnemyRank.naraxus => '',
  };
}

class MapObjectiveCard extends StatelessWidget {
  const MapObjectiveCard({required this.adventure, super.key});

  final AdventureState adventure;

  @override
  Widget build(BuildContext context) {
    final enemyCount = adventure.enemies.length;
    final pointCount = adventure.targetScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xf2121212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)],
      ),
      child: Text(
        "The hero's objective is to defeat $enemyCount enemies and score $pointCount points.",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
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
              FilledButton(onPressed: onReplay, child: const Text('Replay')),
              OutlinedButton(
                onPressed: onChangeHero,
                child: const Text('Change hero'),
              ),
              OutlinedButton(
                onPressed: onDetails,
                child: const Text('Homepage'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecipeEnemySelectionPage extends StatefulWidget {
  const RecipeEnemySelectionPage({required this.enemy, this.rank, super.key});

  final EnemyNode enemy;
  final EnemyRank? rank;

  @override
  State<RecipeEnemySelectionPage> createState() =>
      _RecipeEnemySelectionPageState();
}

class _RecipeEnemySelectionPageState extends State<RecipeEnemySelectionPage> {
  static final Map<EnemyRank, int> _lastSelectedIndices = {};

  late final List<EnemyProfile> _profiles = _recipeProfilesFor(
    widget.rank ?? widget.enemy.rank,
  );
  late EnemyProfile _selected = _computeInitialSelection();

  EnemyProfile _computeInitialSelection() {
    final rank = widget.rank ?? widget.enemy.rank;
    final lastIndex = _lastSelectedIndices[rank];
    if (lastIndex == null) {
      return _profiles.first;
    } else {
      return _profiles[(lastIndex + 1) % _profiles.length];
    }
  }

  Future<void> _pickProfile() async {
    final selected = await showModalBottomSheet<EnemyProfile>(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          itemCount: _profiles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final profile = _profiles[index];
            final selected = profile.key == _selected.key;
            return ListTile(
              selected: selected,
              leading: Text(
                _recipeProfileCode(profile),
                style: TextStyle(
                  color: profile.rank.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              title: Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(profile),
            );
          },
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selected = selected);
    }
  }

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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  side: BorderSide(color: _selected.rank.color, width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pickProfile,
                icon: const Icon(Icons.expand_more),
                label: Text(
                  _recipeProfileLabel(_selected),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
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
                onPressed: () {
                  final rank = widget.rank ?? widget.enemy.rank;
                  final index = _profiles.indexWhere((p) => p.key == _selected.key);
                  if (index >= 0) {
                    _lastSelectedIndices[rank] = index;
                  }
                  Navigator.of(context).pop(_selected);
                },
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
  static bool _isFirstStrike(String token) {
    final norm = _normalizeTokenKey(token);
    return norm == 'firststrike' ||
        norm == 'premierefrappe' ||
        norm == '1stfrappe' ||
        norm == '1erfrappe';
  }

  late bool _keepFirstStrike = widget.enemy.alterations.any(_isFirstStrike);

  @override
  Widget build(BuildContext context) {
    final enemy = widget.enemy;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            enemy.previewAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(color: Colors.black.withValues(alpha: 0.15)),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      enemy.label.isEmpty ? 'Opponent name' : enemy.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: enemy.rank.color,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (widget.showNext &&
                      enemy.alterations.any(_isFirstStrike))
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 116),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: enemy.rank.color),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                  ButtonSegment(
                                    value: true,
                                    label: Text('Yes'),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    label: Text('No'),
                                  ),
                                ],
                                selected: {_keepFirstStrike},
                                onSelectionChanged: (values) => setState(
                                  () => _keepFirstStrike = values.first,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 114,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: enemy.rank.color),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      RewardChestBadge(
                                        rank: enemy.rewardRank,
                                        count: enemy.rewardChests,
                                        ranks: enemy.rewardRanks,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  EnemyObjectivePreview(enemy: enemy),
                                ],
                              ),
                            ),
                          ),
                          if (widget.showNext) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 58,
                              child: _IntroPulse(
                                active: true,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xff8f43ff),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  tooltip: 'Start fight',
                                  onPressed: _continueToFight,
                                  icon: const Icon(Icons.arrow_forward),
                                ),
                              ),
                            ),
                          ],
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

  void _continueToFight() {
    final enemy = widget.enemy;
    if (_keepFirstStrike) {
      if (!enemy.alterations.any(_isFirstStrike)) {
        enemy.alterations.add('Première Frappe');
      }
    } else {
      enemy.alterations.removeWhere(_isFirstStrike);
    }
    widget.onNext();
  }
}

enum _PauseAction { resumeLater, abandon }

class PauseRunDialog extends StatelessWidget {
  const PauseRunDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 18, 8, 0),
      title: Row(
        children: [
          const Expanded(child: Text('Pause run')),
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: const Text(
        'Do you want to leave this run and resume it later, or abandon it now? '
        'Abandoning keeps your current score for statistics.',
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_PauseAction.resumeLater),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8f43ff),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save),
                label: const Text('Resume later'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_PauseAction.abandon),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.flag),
                label: const Text('Abandon'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EnemyMapTile extends StatelessWidget {
  const EnemyMapTile({
    required this.enemy,
    required this.available,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final EnemyNode enemy;
  final bool available;
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
              width: selected || available || isStart ? 4 : 2,
            ),
            color: const Color(0xdd131313),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: available ? 0.8 : 0.55),
                blurRadius: available ? 20 : 12,
                spreadRadius: available ? 2 : 0,
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
      child: Image.asset(enemy.previewAsset, fit: BoxFit.cover),
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
      final attachedViseer = terminalViseer ? branchEnemies.last : null;
      final splitFrom = enemyAt(boss.step - 3);
      final choiceA = enemyAt(boss.step - 2);
      final choiceB = enemyAt(boss.step - 1);
      line(start, branchEnemies.first);
      for (var index = 0; index < branchEnemies.length - 1; index++) {
        final current = branchEnemies[index];
        final next = branchEnemies[index + 1];
        if (splitFrom != null &&
            choiceA != null &&
            choiceB != null &&
            current.id == splitFrom.id) {
          line(current, choiceA);
          line(current, choiceB);
          line(choiceA, choiceB);
          final union = Offset(
            (positions[choiceA.id]!.dx + positions[choiceB.id]!.dx) / 2,
            (positions[choiceA.id]!.dy + positions[choiceB.id]!.dy) / 2,
          );
          canvas.drawLine(union, positions[boss.id]!, paint);
          if (attachedViseer != null) {
            line(boss, attachedViseer);
          }
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
                    duelTokens: TokenCatalogRepository.heroTokens(adventure.hero),
                    isMapPage: true,
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
