part of '../main.dart';

int combatDiceAnimationSeconds = 0;

class FightPage extends StatefulWidget {
  const FightPage({
    required this.adventure,
    required this.historyRecords,
    required this.enemyId,
    required this.onChanged,
    required this.onPauseExit,
    required this.onAbandon,
    this.secondaryEnemyId,
    this.onFinished,
    this.onGameOverHome,
    this.onGameOverHistory,
    super.key,
  });

  final AdventureState adventure;
  final List<GameRecord> historyRecords;
  final int enemyId;
  final int? secondaryEnemyId;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;
  final VoidCallback? onFinished;
  final VoidCallback? onGameOverHome;
  final VoidCallback? onGameOverHistory;

  @override
  State<FightPage> createState() => _FightPageState();
}

class _FightStepSnapshot {
  const _FightStepSnapshot({
    required this.phase,
    required this.upkeepApplied,
    required this.heroUpkeepApplied,
    required this.heroHp,
    required this.heroCp,
    required this.heroTokens,
    required this.enemyHp,
    required this.enemyCp,
    required this.enemyTokens,
    required this.attackValue,
    required this.defenseValue,
    required this.attackUndefendable,
    required this.returnDamage,
    required this.returnDamageUndefendable,
    required this.lifeSteal,
    required this.enemyHeal,
    required this.cpSteal,
    required this.heroAttackCount,
    required this.heroAttackTotal,
    required this.lastHeroAttack,
    required this.lastBattleOutcomeMessage,
    required this.extraDiceOutcomeMessage,
    required this.battleHeroTokens,
    required this.battleMinionTokens,
    required this.battleNotes,
    required this.dice,
    required this.diceToRoll,
    required this.rollCount,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.specialAttackMode,
    required this.druidFormRolledThisUpkeep,
  });

  final CombatPhase phase;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;
  final int heroHp;
  final int heroCp;
  final List<String> heroTokens;
  final int enemyHp;
  final int enemyCp;
  final List<String> enemyTokens;
  final int attackValue;
  final int defenseValue;
  final bool attackUndefendable;
  final int returnDamage;
  final bool returnDamageUndefendable;
  final int lifeSteal;
  final int enemyHeal;
  final int cpSteal;
  final int heroAttackCount;
  final int heroAttackTotal;
  final int lastHeroAttack;
  final String lastBattleOutcomeMessage;
  final String extraDiceOutcomeMessage;
  final List<String> battleHeroTokens;
  final List<String> battleMinionTokens;
  final List<String> battleNotes;
  final List<_DieSnapshot> dice;
  final int diceToRoll;
  final int rollCount;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final bool specialAttackMode;
  final bool druidFormRolledThisUpkeep;
}

class _DieSnapshot {
  const _DieSnapshot({
    required this.id,
    required this.value,
    required this.reserved,
    required this.settled,
    required this.rollTick,
  });

  final int id;
  final int? value;
  final bool reserved;
  final bool settled;
  final int rollTick;
}

class _FightPageState extends State<FightPage> {
  final Random _random = Random();
  final ScrollController _combatScrollController = ScrollController();
  final GlobalKey _attackRulesKey = GlobalKey();
  final GlobalKey _defenseRulesKey = GlobalKey();
  final GlobalKey _extraDicePhaseKey = GlobalKey();
  final List<GameDie> _dice = [];
  int _diceToRoll = 6;
  int _rollCount = 0;
  bool _editMode = false;
  bool _rerollOneMode = false;
  int? _editingDieId;
  late CombatPhase _phase;
  bool _upkeepApplied = false;
  bool _heroUpkeepApplied = false;
  bool _specialAttackReady = false;
  bool _specialAttackMode = false;
  final bool _aiMode = true;
  bool _showManualExtraDicePhase = false;
  bool _developerMode = AppSettings.instance.developerMode;
  bool _reviewingLog = false;
  int _battleAttackValue = 0;
  int _battleDefenseValue = 0;
  bool _battleAttackUndefendable = false;
  int _battleReturnDamage = 0;
  bool _battleReturnDamageUndefendable = false;
  int _battleLifeSteal = 0;
  int _battleEnemyHeal = 0;
  int _battleCpSteal = 0;
  bool _discipleSummonLevel3 = false;
  int _heroAttackCount = 0;
  int _heroAttackTotal = 0;
  int _lastHeroAttack = 0;
  String _lastBattleOutcomeMessage = '';
  String _extraDiceOutcomeMessage = '';
  final List<String> _battleHeroTokens = [];
  final List<String> _battleMinionTokens = [];
  final List<String> _battleNotes = [];
  final List<String> _naraxusRollHistory = [];
  bool _diceAnimationPending = false;
  bool _druidFormRolledThisUpkeep = false;
  bool _viseerDefensePassivePending = false;
  bool _viseerRewardGranted = false;
  late int _activeEnemyId;
  _FightStepSnapshot? _stepUndo;

  EnemyNode get _primaryEnemy => widget.adventure.enemyById(widget.enemyId);

  EnemyNode? get _secondaryEnemy => widget.secondaryEnemyId == null
      ? null
      : widget.adventure.enemyById(widget.secondaryEnemyId!);

  bool get _hasDualEnemies {
    final secondary = _secondaryEnemy;
    return secondary != null &&
        _primaryEnemy.health > 0 &&
        secondary.health > 0;
  }

  EnemyNode get enemy {
    final secondary = _secondaryEnemy;
    if (secondary != null &&
        _activeEnemyId == secondary.id &&
        secondary.health > 0) {
      return secondary;
    }
    if (_primaryEnemy.health <= 0 &&
        secondary != null &&
        secondary.health > 0) {
      return secondary;
    }
    return _primaryEnemy;
  }

  bool get _canSwitchHeroTarget =>
      _hasDualEnemies && _phase == CombatPhase.heroUpkeep;

  bool get _allFightEnemiesDefeated {
    final secondary = _secondaryEnemy;
    return _primaryEnemy.health <= 0 &&
        (secondary == null || secondary.health <= 0);
  }

  bool get _isResolutionMode =>
      widget.adventure.health <= 0 ||
      (_isNaraxus && enemy.health <= 0) ||
      _allFightEnemiesDefeated;

  bool get _isNaraxus => enemy.profileKey == 'naraxus';

  bool _isViseerNode(EnemyNode node) => node.profileKey == 'viseer';

  bool _enemyHasInfiniteCp(EnemyNode node) =>
      node.profileKey == 'naraxus' || _isViseerNode(node);

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_handleAppSettingsChanged);
    for (var i = 0; i < 6; i++) {
      _dice.add(GameDie(id: i));
    }
    _activeEnemyId = widget.enemyId;
    if (_isNaraxus) {
      enemy.alterations.removeWhere((token) => token == 'Première Frappe');
    }
    _phase = CombatPhase.intro;
    _configureDiceForPhase(
      autoRollAttack: _aiMode && _phase == CombatPhase.minionAttack,
    );
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_handleAppSettingsChanged);
    _combatScrollController.dispose();
    super.dispose();
  }

  void _handleAppSettingsChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _developerMode = AppSettings.instance.developerMode);
  }

  @override
  Widget build(BuildContext context) {
    final aiMessage = _aiMode
        ? _aiMessageFor(
            enemy,
            _phase,
            _dice,
            _rollCount,
            widget.adventure,
            widget.historyRecords,
            _lastBattleOutcomeMessage,
            _extraDiceOutcomeMessage,
            _heroAttackCount,
            _lastHeroAttack,
            _heroAttackTotal,
          )
        : '';
    final canAdvancePhase =
        _phase != CombatPhase.minionAttack &&
        (_phase != CombatPhase.hero || _battleAttackValue == 0) &&
        !_needsDruidFormRoll;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _openPauseDialog();
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -420) {
              _handleNextStep();
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                CombatBottomDock(
                  phase: _phase,
                  adventure: widget.adventure,
                  enemy: enemy,
                  primaryEnemy: _primaryEnemy,
                  secondaryEnemy: _secondaryEnemy,
                  upkeepApplied: _upkeepApplied,
                  heroUpkeepApplied: _heroUpkeepApplied,
                  canAdvancePhase: canAdvancePhase,
                  onPhaseChanged: _setPhase,
                  onNext: _handleNextStep,
                  onApplyUpkeep: () => _applyUpkeep(),
                  onApplyHeroUpkeep: () => _applyHeroUpkeep(),
                ),
                Expanded(
                  child: ListView(
                    controller: _combatScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
                    children: [
                      FightStatusPanel(
                        adventure: widget.adventure,
                        enemy: enemy,
                        phase: _phase,
                        naraxusRollHistory: _naraxusRollHistory,
                        onFinish: null,
                        onChanged: () {
                          widget.onChanged();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_isResolutionMode && !_reviewingLog)
                        _CombatResolutionPanel(
                          adventure: widget.adventure,
                          enemy: _primaryEnemy,
                          allFightEnemiesDefeated: _allFightEnemiesDefeated,
                          onHistory: () {
                            widget.onGameOverHistory?.call();
                          },
                          onHomepage: () {
                            if (_isNaraxus) {
                              widget.onFinished?.call();
                            } else {
                              widget.onGameOverHome?.call();
                            }
                          },
                          onRewardFinished: () {
                            widget.adventure.completeCombat(_primaryEnemy);
                            if (_secondaryEnemy != null) {
                              widget.adventure.completeCombat(_secondaryEnemy!);
                            }
                            widget.onChanged();
                            Navigator.of(context).pop(true);
                          },
                          onReview: () => setState(() => _reviewingLog = true),
                        )
                      else ...[
                        if (_reviewingLog) ...[
                          OutlinedButton(
                            onPressed: () => setState(() => _reviewingLog = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xff8f43ff)),
                            ),
                            child: const Text('Revenir à l\'écran de fin'),
                          ),
                          const SizedBox(height: 12),
                        ],
                        EnemyRulesPanel(
                          enemy: enemy,
                          phase: _phase,
                          aiMode: _aiMode,
                          developerMode: _developerMode,
                          onDetails: _openAdventureDetails,
                          onAbandon: _openPauseDialog,
                          onExport: _openCombatExport,
                          onRestartCombat: _restartCombatFromSettings,
                          showUndo: _stepUndo != null,
                          onUndo: _undoStep,
                          attackKey: _attackRulesKey,
                          defenseKey: _defenseRulesKey,
                        ),
                        if (_aiMode) ...[
                          const SizedBox(height: 12),
                          MinionAiPanel(
                            enemy: enemy,
                            phase: _phase,
                            dice: _dice,
                            adventure: widget.adventure,
                            rollCount: _rollCount,
                            diceToRoll: _diceToRoll,
                            visibleDiceCount: _visibleDiceCount,
                            maxRolls: _maxRolls,
                            editMode: _editMode,
                            rerollOneMode: _rerollOneMode,
                            editingDieId: _editingDieId,
                            onRoll: _rollDice,
                            onTapDie: _tapDie,
                            onSelectFace: _selectFace,
                            onValidateEdit: () =>
                                setState(() => _editingDieId = null),
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
                          if (_showDruidFormRollPanel) ...[
                            const SizedBox(height: 12),
                            ManualExtraDicePhasePanel(
                              key: _extraDicePhaseKey,
                              title: 'Druid form roll',
                              initialDiceCount: 1,
                              accent: enemy.rank.color,
                              autoRoll: false,
                              onChanged: _resolveDruidFormRoll,
                            ),
                          ],
                          if (_showAiExtraDicePhase) ...[
                            const SizedBox(height: 12),
                            ManualExtraDicePhasePanel(
                              key: _extraDicePhaseKey,
                              title: _extraDicePhaseTitle,
                              initialDiceCount: _extraDiceCount,
                              accent: enemy.rank.color,
                              autoRoll: false,
                              onChanged: _resolveExtraDicePhase,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () => _showManualExtraDicePhase =
                                  !_showManualExtraDicePhase,
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(
                              _showManualExtraDicePhase
                                  ? 'Hide extra dice phase'
                                  : 'Add dice phase',
                            ),
                          ),
                          if (_showManualExtraDicePhase) ...[
                            const SizedBox(height: 8),
                            const ManualExtraDicePhasePanel(),
                          ],
                        ],
                        if (!_aiMode) ...[
                          const SizedBox(height: 12),
                          DicePanel(
                            dice: _dice,
                            diceToRoll: _diceToRoll,
                            visibleDiceCount: _visibleDiceCount,
                            maxDiceCount: _diceMenuMax,
                            rollCount: _rollCount,
                            maxRolls: _maxRolls,
                            editMode: _editMode,
                            rerollOneMode: _rerollOneMode,
                            editingDieId: _editingDieId,
                            specialAttackMode: _specialAttackMode,
                            onDiceToRollChanged: (value) =>
                                setState(() => _diceToRoll = value),
                            onRoll: _rollDice,
                            onTapDie: _tapDie,
                            onSelectFace: _selectFace,
                            onValidateEdit: () =>
                                setState(() => _editingDieId = null),
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
                            rollLabel: _phase == CombatPhase.hero
                                ? 'Roll defense'
                                : (_rollCount == 0 ? 'Roll' : 'Reroll'),
                            rollColor: _phase == CombatPhase.hero
                                ? enemy.rank.color
                                : const Color(0xff8f43ff),
                          ),
                        ],
                        if (_specialAttackReady && !_aiMode) ...[
                          const SizedBox(height: 12),
                          ImageActionButton(
                            label: 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: _resolveSpecialAttack,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (!_isResolutionMode || _reviewingLog)
                  CombatAiChatDock(
                    aiMode: _aiMode,
                    aiMessage: aiMessage,
                    phase: _phase,
                    adventure: widget.adventure,
                    enemy: enemy,
                    primaryEnemy: _primaryEnemy,
                    secondaryEnemy: _secondaryEnemy,
                    canSwitchTarget: _canSwitchHeroTarget,
                    onSelectTarget: _selectDualEnemyTarget,
                    returnDamage: _battleReturnDamage,
                    returnDamageUndefendable: _battleReturnDamageUndefendable,
                    lifeSteal: _battleLifeSteal,
                    enemyHeal: _battleEnemyHeal,
                    cpSteal: _battleCpSteal,
                    heroTokens: _battleHeroTokens,
                    minionTokens: _battleMinionTokens,
                    notes: _battleNotes,
                    showResolution: _isBattlePhase,
                    attackValue: _battleAttackValue,
                    defenseValue: _battleDefenseValue,
                    onAttackChanged: (delta) => setState(() {
                      _battleAttackValue = (_battleAttackValue + delta).clamp(
                        0,
                        99,
                      );
                    }),
                    onDefenseChanged: (delta) => setState(() {
                      _battleDefenseValue = (_battleDefenseValue + delta).clamp(
                        0,
                        99,
                      );
                    }),
                    onApply: _applyBattleResolution,
                    onFinish: null,
                    onChanged: () {
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _rollDice() {
    if (_rollCount >= _maxRolls) {
      return;
    }
    if (_phase == CombatPhase.minionAttack &&
        _rollCount > 0 &&
        !_specialAttackMode &&
        enemy.alterations.contains('Ronces')) {
      if (enemy.health <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ronces would defeat the minion: reroll blocked.'),
          ),
        );
        return;
      }
      enemy.health = (enemy.health - 1).clamp(0, 99);
      widget.adventure.log('Ronces: minion loses 1 HP for reroll.');
    }
    final rolledIds = <int>[];
    setState(() {
      final rollable = _dice
          .where((die) => !die.reserved)
          .take(_diceToRoll)
          .toList();
      _diceAnimationPending =
          combatDiceAnimationSeconds > 0 && rollable.isNotEmpty;
      for (final die in rollable) {
        die.value = _random.nextInt(6) + 1;
        die.settled = !_diceAnimationPending;
        die.rollTick++;
        rolledIds.add(die.id);
      }
      if (_isNaraxus) {
        final values = rollable
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .join('/');
        if (values.isNotEmpty) {
          _naraxusRollHistory.add(values);
        }
      }
      _rollCount++;
      widget.adventure.log(
        'Roll $_rollCount: ${rollable.map((die) => die.value).join(', ')}.',
      );
      if (!_diceAnimationPending) {
        _finalizeRolledDice();
      }
      widget.onChanged();
    });
    if (_diceAnimationPending) {
      Future<void>.delayed(
        Duration(seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt()),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            for (final die in _dice.where(
              (die) => rolledIds.contains(die.id),
            )) {
              die.settled = true;
            }
            _diceAnimationPending = _dice.any((die) => !die.settled);
            if (!_diceAnimationPending) {
              _finalizeRolledDice();
              widget.onChanged();
            }
          });
          if (_showAiExtraDicePhase) {
            _scrollToRulesKey(_extraDicePhaseKey);
          }
        },
      );
    }
    if (_showAiExtraDicePhase) {
      _scrollToRulesKey(_extraDicePhaseKey);
    }
  }

  void _finalizeRolledDice() {
    if (_phase == CombatPhase.minionAttack && _aiMode) {
      _applyMinionDiceStrategy();
    }
    _refreshBattleResolutionFromDice();
    if (_rollCount == _maxRolls) {
      _specialAttackReady = _shouldResolveSpecialAttack();
      if (_phase == CombatPhase.minionAttack &&
          !_specialAttackReady &&
          !_currentAttackGoalMet() &&
          _currentMinionAttackResult() == null) {
        final hadReserved = _dice.any((die) => die.reserved);
        for (final die in _dice) {
          die.reserved = false;
        }
        if (hadReserved) {
          widget.adventure.log(
            'After $_rollCount attack rolls, no valid attack combination: dice deselected.',
          );
        }
      }
    }
  }

  void _openAdventureDetails() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdventureDetailsPage(
          adventure: widget.adventure,
          combatEnemy: enemy,
          combatPhase: _phase,
          combatDice: _dice,
          aiMode: _aiMode,
          rollCount: _rollCount,
        ),
      ),
    );
  }

  void _openCombatExport() {
    final jsonText = const JsonEncoder.withIndent('  ').convert({
      'exportVersion': 2,
      'createdAt': DateTime.now().toIso8601String(),
      'run': {
        'hero': widget.adventure.hero.label,
        'mode': widget.adventure.config.mode.label,
        'score': widget.adventure.score,
        'targetScore': widget.adventure.targetScore,
        'elapsed': widget.adventure.elapsed.inSeconds,
        'rewards': widget.adventure.bonuses,
        'logs': widget.adventure.logs,
      },
      'heroState': {
        'hp': widget.adventure.health,
        'cp': widget.adventure.combatPoints,
        'tokens': widget.adventure.alterations,
      },
      'combat': {
        'phase': _phase.name,
        'aiMode': _aiMode,
        'rollCount': _rollCount,
        'enemy': {
          'id': enemy.id,
          'profileKey': enemy.profileKey,
          'name': enemy.label,
          'rank': enemy.rank.name,
          'hp': enemy.health,
          'cp': enemy.combatPoints,
          'tokens': enemy.alterations,
        },
        'dice': [
          for (final die in _dice)
            {'id': die.id, 'value': die.value, 'reserved': die.reserved},
        ],
      },
    });
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
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _tapDie(GameDie die) {
    setState(() {
      if (_editMode) {
        _editingDieId = die.id;
        return;
      }
      if (_rerollOneMode) {
        die.value = _random.nextInt(6) + 1;
        die.settled = true;
        die.rollTick++;
        _rerollOneMode = false;
        _refreshBattleResolutionFromDice();
        widget.adventure.log(
          'Special reroll for die ${die.id + 1}: ${die.value}.',
        );
        widget.onChanged();
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
      die.settled = true;
      _refreshBattleResolutionFromDice();
      widget.adventure.log('Die ${die.id + 1} changed to $face.');
      widget.onChanged();
    });
  }

  void _setPhase(CombatPhase phase) {
    setState(() {
      if (_phase != phase && phase != CombatPhase.heroUpkeep) {
        _heroUpkeepApplied = false;
      }
      _phase = phase;
      _upkeepApplied = false;
      if (phase == CombatPhase.minionUpkeep &&
          enemy.profileKey == 'vert-vert-014') {
        _druidFormRolledThisUpkeep = false;
      }
      _specialAttackReady = false;
      _specialAttackMode = false;
      _resetBattleResolution();
      _configureDiceForPhase(
        autoRollAttack: _aiMode && phase == CombatPhase.minionAttack,
      );
    });
    if (phase == CombatPhase.heroUpkeep) {
      _applyHeroUpkeep();
    }
    if (phase == CombatPhase.heroUpkeep || phase == CombatPhase.minionUpkeep) {
      _scrollToTop();
    } else if (phase == CombatPhase.hero) {
      _scrollToRulesKey(_defenseRulesKey);
    } else if (phase == CombatPhase.minionAttack) {
      _scrollToRulesKey(_attackRulesKey);
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_combatScrollController.hasClients) {
        return;
      }
      _combatScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToRulesKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.02,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleNextStep() {
    if (_phase == CombatPhase.hero || _phase == CombatPhase.minionAttack) {
      return;
    }
    if (_needsDruidFormRoll) {
      _scrollToRulesKey(_extraDicePhaseKey);
      return;
    }
    _captureStepUndo();
    if (_phase == CombatPhase.heroUpkeep && !_heroUpkeepApplied) {
      _applyHeroUpkeep(captureUndo: false);
    }
    if (_phase == CombatPhase.minionUpkeep && !_upkeepApplied) {
      _applyUpkeep(captureUndo: false);
    }
    if (_phase != CombatPhase.hero && _phase != CombatPhase.minionAttack) {
      _advancePhase(captureUndo: false);
    }
  }

  void _advancePhase({bool captureUndo = true}) {
    if (captureUndo) {
      _captureStepUndo();
    }
    final next = switch (_phase) {
      CombatPhase.intro => _firstCombatPhaseFor(enemy),
      CombatPhase.heroUpkeep => CombatPhase.hero,
      CombatPhase.hero => CombatPhase.minionUpkeep,
      CombatPhase.minionUpkeep => CombatPhase.minionAttack,
      CombatPhase.minionAttack => CombatPhase.heroUpkeep,
    };
    if (_phase == CombatPhase.hero) {
      _activeEnemyId = _firstEnemyTurnId();
    } else if (_phase == CombatPhase.minionUpkeep && _isViseerNode(enemy)) {
      final nextEnemy = _nextEnemyTurnIdAfter(enemy.id);
      if (nextEnemy != null) {
        _activeEnemyId = nextEnemy;
        _setPhase(CombatPhase.minionUpkeep);
        return;
      }
      _activeEnemyId = _nextLivingEnemyId();
      _setPhase(CombatPhase.heroUpkeep);
      return;
    } else if (_phase == CombatPhase.minionAttack) {
      final nextEnemy = _nextEnemyTurnIdAfter(enemy.id);
      if (nextEnemy != null) {
        _activeEnemyId = nextEnemy;
        _setPhase(CombatPhase.minionUpkeep);
        return;
      }
      _activeEnemyId = _nextLivingEnemyId();
    }
    _setPhase(next);
  }

  int _firstEnemyTurnId() {
    final secondary = _secondaryEnemy;
    if (secondary != null && secondary.health > 0) {
      return secondary.id;
    }
    return _primaryEnemy.id;
  }

  int? _nextEnemyTurnIdAfter(int currentId) {
    final secondary = _secondaryEnemy;
    if (secondary != null &&
        currentId == secondary.id &&
        _primaryEnemy.health > 0) {
      return _primaryEnemy.id;
    }
    return null;
  }

  int _nextLivingEnemyId() {
    final secondary = _secondaryEnemy;
    if (_primaryEnemy.health > 0) {
      return _primaryEnemy.id;
    }
    if (secondary != null && secondary.health > 0) {
      return secondary.id;
    }
    return _primaryEnemy.id;
  }

  void _selectDualEnemyTarget(EnemyNode target) {
    if (!_canSwitchHeroTarget || target.health <= 0) {
      return;
    }
    setState(() {
      _activeEnemyId = target.id;
      _resetBattleResolution();
      _configureDiceForPhase(autoRollAttack: false);
    });
  }

  void _captureStepUndo() {
    _stepUndo = _FightStepSnapshot(
      phase: _phase,
      upkeepApplied: _upkeepApplied,
      heroUpkeepApplied: _heroUpkeepApplied,
      heroHp: widget.adventure.health,
      heroCp: widget.adventure.combatPoints,
      heroTokens: List<String>.from(widget.adventure.alterations),
      enemyHp: enemy.health,
      enemyCp: enemy.combatPoints,
      enemyTokens: List<String>.from(enemy.alterations),
      attackValue: _battleAttackValue,
      defenseValue: _battleDefenseValue,
      attackUndefendable: _battleAttackUndefendable,
      returnDamage: _battleReturnDamage,
      returnDamageUndefendable: _battleReturnDamageUndefendable,
      lifeSteal: _battleLifeSteal,
      enemyHeal: _battleEnemyHeal,
      cpSteal: _battleCpSteal,
      heroAttackCount: _heroAttackCount,
      heroAttackTotal: _heroAttackTotal,
      lastHeroAttack: _lastHeroAttack,
      lastBattleOutcomeMessage: _lastBattleOutcomeMessage,
      extraDiceOutcomeMessage: _extraDiceOutcomeMessage,
      battleHeroTokens: List<String>.from(_battleHeroTokens),
      battleMinionTokens: List<String>.from(_battleMinionTokens),
      battleNotes: List<String>.from(_battleNotes),
      dice: _dice
          .map(
            (die) => _DieSnapshot(
              id: die.id,
              value: die.value,
              reserved: die.reserved,
              settled: die.settled,
              rollTick: die.rollTick,
            ),
          )
          .toList(),
      diceToRoll: _diceToRoll,
      rollCount: _rollCount,
      editMode: _editMode,
      rerollOneMode: _rerollOneMode,
      editingDieId: _editingDieId,
      specialAttackMode: _specialAttackMode,
      druidFormRolledThisUpkeep: _druidFormRolledThisUpkeep,
    );
  }

  void _undoStep() {
    final snapshot = _stepUndo;
    if (snapshot == null) {
      return;
    }
    setState(() {
      _phase = snapshot.phase;
      _upkeepApplied = snapshot.upkeepApplied;
      _heroUpkeepApplied = snapshot.heroUpkeepApplied;
      widget.adventure.setHeroHealth(snapshot.heroHp);
      widget.adventure.setHeroPc(snapshot.heroCp);
      widget.adventure.alterations
        ..clear()
        ..addAll(snapshot.heroTokens);
      enemy.health = snapshot.enemyHp;
      enemy.combatPoints = snapshot.enemyCp;
      enemy.alterations
        ..clear()
        ..addAll(snapshot.enemyTokens);
      _battleAttackValue = snapshot.attackValue;
      _battleDefenseValue = snapshot.defenseValue;
      _battleAttackUndefendable = snapshot.attackUndefendable;
      _battleReturnDamage = snapshot.returnDamage;
      _battleReturnDamageUndefendable = snapshot.returnDamageUndefendable;
      _battleLifeSteal = snapshot.lifeSteal;
      _battleEnemyHeal = snapshot.enemyHeal;
      _battleCpSteal = snapshot.cpSteal;
      _heroAttackCount = snapshot.heroAttackCount;
      _heroAttackTotal = snapshot.heroAttackTotal;
      _lastHeroAttack = snapshot.lastHeroAttack;
      _lastBattleOutcomeMessage = snapshot.lastBattleOutcomeMessage;
      _extraDiceOutcomeMessage = snapshot.extraDiceOutcomeMessage;
      _battleHeroTokens
        ..clear()
        ..addAll(snapshot.battleHeroTokens);
      _battleMinionTokens
        ..clear()
        ..addAll(snapshot.battleMinionTokens);
      _battleNotes
        ..clear()
        ..addAll(snapshot.battleNotes);
      _dice
        ..clear()
        ..addAll(
          snapshot.dice.map(
            (saved) => GameDie(id: saved.id)
              ..value = saved.value
              ..reserved = saved.reserved
              ..settled = saved.settled
              ..rollTick = saved.rollTick,
          ),
        );
      _diceToRoll = snapshot.diceToRoll;
      _rollCount = snapshot.rollCount;
      _editMode = snapshot.editMode;
      _rerollOneMode = snapshot.rerollOneMode;
      _editingDieId = snapshot.editingDieId;
      _specialAttackMode = snapshot.specialAttackMode;
      _druidFormRolledThisUpkeep = snapshot.druidFormRolledThisUpkeep;
      _stepUndo = null;
    });
    widget.onChanged();
  }

  Future<void> _restartCombatFromSettings(EnemyRank rank) async {
    final selectedProfile = await Navigator.of(context).push<EnemyProfile>(
      MaterialPageRoute<EnemyProfile>(
        builder: (_) => RecipeEnemySelectionPage(enemy: enemy, rank: rank),
      ),
    );
    if (!mounted || selectedProfile == null) {
      return;
    }
    setState(() {
      enemy.applyProfile(selectedProfile);
      _phase = CombatPhase.intro;
      _upkeepApplied = false;
      _heroUpkeepApplied = false;
      _specialAttackReady = false;
      _specialAttackMode = false;
      _showManualExtraDicePhase = false;
      _heroAttackCount = 0;
      _heroAttackTotal = 0;
      _lastHeroAttack = 0;
      _lastBattleOutcomeMessage = '';
      _extraDiceOutcomeMessage = '';
      _druidFormRolledThisUpkeep = false;
      _stepUndo = null;
      _resetBattleResolution();
      _configureDiceForPhase(autoRollAttack: false);
    });
    widget.onChanged();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EnemyIntroPage(
          adventure: widget.adventure,
          enemy: enemy,
          onNext: () async => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) {
      _scrollToTop();
    }
  }

  void _configureDiceForPhase({required bool autoRollAttack}) {
    _resetDice();
    if (_phase == CombatPhase.hero) {
      _diceToRoll = enemy.defenseDice.clamp(0, 5);
    } else if (_phase == CombatPhase.intro ||
        _phase == CombatPhase.heroUpkeep ||
        _phase == CombatPhase.minionUpkeep) {
      _diceToRoll = 0;
    } else if (_phase == CombatPhase.minionAttack) {
      _diceToRoll = _isNaraxus ? 1 : 5;
      if (autoRollAttack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _phase == CombatPhase.minionAttack &&
              _rollCount == 0) {
            _rollDice();
          }
        });
      }
    }
  }

  void _resetDice() {
    _rollCount = 0;
    _diceAnimationPending = false;
    _editingDieId = null;
    _editMode = false;
    _rerollOneMode = false;
    _specialAttackReady = false;
    _specialAttackMode = false;
    for (final die in _dice) {
      die
        ..value = null
        ..settled = true
        ..reserved = false;
    }
  }

  int get _visibleDiceCount {
    if (_specialAttackMode) {
      return 1;
    }
    if (_phase == CombatPhase.minionAttack) {
      return _isNaraxus ? 1 : 5;
    }
    return _diceToRoll.clamp(0, 5);
  }

  bool get _showAiExtraDicePhase {
    if (_diceAnimationPending) {
      return false;
    }
    if (!_aiMode || _rollCount == 0) {
      return false;
    }
    if (_phase == CombatPhase.hero) {
      return _isViseerNode(enemy) && _viseerDefensePassivePending;
    }
    if (_phase != CombatPhase.minionAttack) {
      return false;
    }
    if (_specialAttackReady) {
      return true;
    }
    if (_isNaraxus) {
      final value = _dice.first.value;
      return value == 3 || value == 6;
    }
    if (enemy.profileKey == 'vert-vert-012') {
      return _symbolGoalMet(const SymbolGoal(yellow: 4));
    }
    if (enemy.profileKey == 'vert-vert-015') {
      return _symbolGoalMet(const SymbolGoal(white: 2, yellow: 3));
    }
    if (enemy.profileKey == 'vert-vert-017') {
      return _symbolGoalMet(const SymbolGoal(white: 2, red: 1));
    }
    if (enemy.profileKey == 'vert-vert-021') {
      return _symbolGoalMet(const SymbolGoal(yellow: 2, red: 1));
    }
    if (enemy.profileKey == 'bleu-bleu-003') {
      return _symbolGoalMet(const SymbolGoal(yellow: 2, red: 1));
    }
    return _attackNeedsExtraDice(enemy) && _currentAttackGoalMet();
  }

  bool get _showDruidFormRollPanel => _needsDruidFormRoll;

  bool get _needsDruidFormRoll =>
      _aiMode &&
      enemy.profileKey == 'vert-vert-014' &&
      _phase == CombatPhase.minionUpkeep &&
      !_upkeepApplied &&
      !_druidFormRolledThisUpkeep;

  void _resolveDruidFormRoll(List<GameDie> dice) {
    final rolled = dice.where((die) => die.value != null).toList();
    if (rolled.isEmpty) {
      return;
    }
    _markExtraDiceSelection(dice, [rolled.first.id]);
    final roll = rolled.first.value!;
    final form = roll <= 3 ? 'Forme Ours' : 'Forme Elan';
    setState(() {
      enemy.alterations.removeWhere(
        (token) => token == 'Forme Ours' || token == 'Forme Elan',
      );
      enemy.alterations.add(form);
      _druidFormRolledThisUpkeep = true;
      _extraDiceOutcomeMessage =
          'Druid form roll: $roll.\n'
          '${form == 'Forme Ours' ? 'Bear Form' : 'Elk Form'} is active until the next Druid upkeep.';
      widget.adventure.log(
        '${enemy.label} form roll $roll: ${form == 'Forme Ours' ? 'Bear Form' : 'Elk Form'}.',
      );
      widget.onChanged();
    });
  }

  int get _extraDiceCount {
    if (_phase == CombatPhase.hero &&
        _isViseerNode(enemy) &&
        _viseerDefensePassivePending) {
      return 1;
    }
    if (_isNaraxus && _dice.first.value == 3) {
      return 4;
    }
    if (_isNaraxus && _dice.first.value == 6) {
      return 1;
    }
    if (enemy.profileKey == 'vert-vert-012') {
      return 2;
    }
    if (enemy.profileKey == 'vert-vert-015') {
      return 1;
    }
    if (enemy.profileKey == 'vert-vert-017') {
      return 1;
    }
    if (enemy.profileKey == 'vert-vert-021') {
      return 1;
    }
    if (enemy.profileKey == 'bleu-bleu-003') {
      return 1;
    }
    return _extraDiceCountFor(enemy);
  }

  String get _extraDicePhaseTitle {
    if (_phase == CombatPhase.hero &&
        _isViseerNode(enemy) &&
        _viseerDefensePassivePending) {
      return 'Viseer passive extra roll';
    }
    if (_isNaraxus && _dice.first.value == 3) {
      return 'Gashing Bite extra roll';
    }
    if (_isNaraxus && _dice.first.value == 6) {
      return "Dragon's Might extra roll";
    }
    if (enemy.profileKey == 'vert-vert-012') {
      return 'Rocalanche extra roll';
    }
    if (enemy.profileKey == 'vert-vert-015') {
      return 'Abnegation extra roll';
    }
    if (enemy.profileKey == 'vert-vert-017') {
      return 'Claquement de Crocs extra roll';
    }
    if (enemy.profileKey == 'vert-vert-021') {
      return 'Sorcellerie Ophique extra roll';
    }
    if (enemy.profileKey == 'bleu-bleu-003') {
      return 'Sorcellerie Chaotique extra roll';
    }
    return '${enemy.label} extra roll';
  }

  int get _diceMenuMax {
    if (_phase == CombatPhase.hero) {
      return 5;
    }
    return _visibleDiceCount.clamp(0, 5);
  }

  int get _maxRolls => _phase == CombatPhase.hero || _isNaraxus ? 1 : 3;

  bool get _isBattlePhase =>
      _phase == CombatPhase.hero || _phase == CombatPhase.minionAttack;

  void _resetBattleResolution() {
    _battleAttackValue = 0;
    _battleDefenseValue = 0;
    _battleAttackUndefendable = false;
    _battleReturnDamage = 0;
    _battleReturnDamageUndefendable = false;
    _battleLifeSteal = 0;
    _battleEnemyHeal = 0;
    _battleCpSteal = 0;
    _discipleSummonLevel3 = false;
    _battleHeroTokens.clear();
    _battleMinionTokens.clear();
    _battleNotes.clear();
    _extraDiceOutcomeMessage = '';
    _viseerDefensePassivePending = false;
  }

  void _refreshBattleResolutionFromDice() {
    if (_phase == CombatPhase.hero) {
      _resolveMinionDefenseFromDice();
    } else if (_phase == CombatPhase.minionAttack) {
      _resolveMinionAttackFromDice();
    }
  }

  void _resolveMinionDefenseFromDice() {
    final rolled = _dice.where((die) => die.value != null).toList();
    if (rolled.isEmpty) {
      return;
    }
    final counts = _symbolCounts();
    final white = counts[DieSymbol.white] ?? 0;
    final yellow = counts[DieSymbol.yellow] ?? 0;
    final red = counts[DieSymbol.red] ?? 0;
    var prevented = 0;
    var returnDamage = 0;
    var returnDamageUndefendable = false;
    var lifeSteal = 0;
    var cpSteal = 0;
    final notes = <String>[];
    final heroTokens = <String>[];
    final minionTokens = <String>[];

    switch (enemy.profileKey) {
      case 'naraxus':
        final value = rolled.first.value ?? 0;
        prevented = switch (value) {
          1 => 1,
          6 => 5,
          _ => 3,
        };
        notes.add('Naxarus defense: D6 $value prevents $prevented damage.');
      case 'fee':
        if (yellow >= 2) {
          prevented = 3;
          notes.add('Defense: 2 orange symbols prevent 3 damage.');
        }
      case 'ronin-vagabond':
        final value = rolled.first.value ?? 0;
        returnDamage = (value / 2).ceil();
        returnDamageUndefendable = returnDamage > 0;
        notes.add('Defense: returns $returnDamage undefendable damage.');
      case 'enchanteur-gobelin':
        if (yellow > 0) {
          returnDamage = 1;
          returnDamageUndefendable = true;
          notes.add('Defense: orange symbol returns 1 undefendable damage.');
        }
        if (red > 0) {
          heroTokens.add('Poison');
          notes.add('Defense: red symbol gives Poison to the hero.');
        }
      case 'archer-de-lombre':
        if (yellow > 0) {
          prevented = 3;
          notes.add('Defense: orange symbol prevents 3 damage.');
        }
      case 'ombre-feline':
        if (white > 0) {
          heroTokens.add('Hémorragie');
          notes.add('Defense: white symbol gives Hemorragie to the hero.');
        }
      case 'epeiste-egare':
        prevented = yellow;
        returnDamage = white + red;
        returnDamageUndefendable = returnDamage > 0;
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
        if (returnDamage > 0) {
          notes.add('Defense: returns $returnDamage undefendable damage.');
        }
      case 'elfe-du-chaos':
        if (yellow >= 2) {
          prevented = (_battleAttackValue / 2).ceil();
          notes.add('Defense: 2 orange symbols prevent half the damage.');
        }
      case 'oni-delirant':
        lifeSteal = yellow;
        if (lifeSteal > 0) {
          notes.add('Defense: steals $lifeSteal HP.');
        }
      case 'vert-vert-011':
        if (yellow > 0) {
          prevented = (_battleAttackValue / 2).ceil();
          notes.add('Defense: orange prevents half the damage.');
        }
      case 'vert-vert-012':
      case 'vert-vert-016':
        prevented = yellow;
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
      case 'vert-vert-013':
        if (red > 0) {
          heroTokens.add('Poison');
          notes.add('Defense: red gives Poison to the hero.');
        }
      case 'vert-vert-014':
        if (_isDruidBearForm(enemy)) {
          returnDamage = yellow + red * 2;
          returnDamageUndefendable = returnDamage > 0;
          if (returnDamage > 0) {
            notes.add(
              'Bear Form defense: returns $returnDamage undefendable damage.',
            );
          }
        } else {
          prevented = yellow + red * 2;
          if (prevented > 0) {
            notes.add('Elk Form defense: prevents $prevented damage.');
          }
        }
      case 'vert-vert-015':
        if (red > 0) {
          returnDamage = (_battleAttackValue / 2).ceil();
          notes.add('Defense: red returns half the damage.');
        }
      case 'vert-vert-017':
        if (white > 0) {
          returnDamage = 2;
          returnDamageUndefendable = true;
          notes.add('Defense: white returns 2 imparable damage.');
        }
      case 'vert-vert-018':
        if (yellow > 0) {
          heroTokens.add('À Terre');
          notes.add('Defense: orange gives À Terre to the hero.');
        }
        if (red > 0) {
          prevented = 2;
          notes.add('Defense: red prevents 2 damage.');
        }
      case 'vert-vert-019':
        if (red > 0) {
          prevented = 3;
          notes.add('Defense: red prevents 3 damage.');
        }
      case 'vert-vert-020':
        returnDamage = white > 0 ? 1 : 0;
        returnDamageUndefendable = returnDamage > 0;
        prevented = yellow + red;
        if (returnDamage > 0) {
          notes.add('Defense: white returns 1 imparable damage.');
        }
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
      case 'vert-vert-021':
        final currentChaos = _tokenCount(enemy.alterations, 'Chaos');
        final gainedChaos = yellow;
        returnDamage = currentChaos + gainedChaos;
        returnDamageUndefendable = returnDamage > 0;
        if (gainedChaos > 0) {
          notes.add('Defense: gains $gainedChaos Chaos during the roll.');
        }
        if (returnDamage > 0) {
          notes.add(
            'Defense: $currentChaos existing Chaos + $gainedChaos new Chaos returns $returnDamage undefendable damage.',
          );
        }
        minionTokens.addAll(List.filled(gainedChaos, 'Chaos'));
      case 'rat-de-la-rue':
        if (yellow >= 2) {
          cpSteal = 1;
          notes.add('Defense: 2 orange symbols steal 1 CP.');
        }
        if (red >= 2) {
          prevented = _battleAttackValue;
          _battleAttackUndefendable = false;
          notes.add('Defense: 2 red symbols ignore all incoming damage.');
        }
      case 'bleu-vert-022':
        if (yellow > 0) {
          prevented = 2;
          notes.add('Defense: orange prevents 2 damage.');
        }
        if (red > 0) {
          heroTokens.add('Parasite');
          notes.add('Defense: red gives Parasite to the hero.');
        }
      case 'bleu-vert-023':
        lifeSteal = red > 0 ? 1 : 0;
        if (lifeSteal > 0) {
          notes.add('Defense: steals $lifeSteal HP.');
        }
      case 'bleu-bleu-001':
        prevented = yellow;
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
      case 'bleu-bleu-002':
        if (yellow >= 2) {
          prevented = 4;
          notes.add('Defense: 2 orange symbols prevent 4 damage.');
        }
      case 'bleu-bleu-003':
        final currentChaos = _tokenCount(enemy.alterations, 'Chaos');
        final gainedChaos = yellow;
        returnDamage = currentChaos + gainedChaos;
        returnDamageUndefendable = returnDamage > 0;
        if (gainedChaos > 0) {
          minionTokens.addAll(List.filled(gainedChaos, 'Chaos'));
          notes.add('Defense: gains $gainedChaos Chaos during the roll.');
        }
        if (returnDamage > 0) {
          notes.add(
            'Defense: $currentChaos existing Chaos + $gainedChaos new Chaos returns $returnDamage undefendable damage.',
          );
        }
      case 'bleu-bleu-004':
        lifeSteal = yellow;
        if (lifeSteal > 0) {
          notes.add('Defense: steals $lifeSteal HP.');
        }
        if (red > 0) {
          minionTokens.add('Chaos');
          notes.add('Defense: red symbol gives Blood Mage 1 Chaos.');
        }
      case 'viseer':
        _viseerDefensePassivePending = red > 0;
        if (red > 0) {
          notes.add(
            'Viseer defense: red symbol activates passive ability. Roll 1 extra die.',
          );
        }
      default:
        notes.add('Defense rolled. Check the minion card for exact effects.');
    }

    if (prevented == 0 &&
        returnDamage == 0 &&
        lifeSteal == 0 &&
        heroTokens.isEmpty &&
        minionTokens.isEmpty &&
        !(enemy.profileKey == 'viseer' && red > 0)) {
      notes.add('Defense roll failed.');
    }

    _markExtraDiceSelection(
      _dice,
      _defenseSelectionIds(
        enemy: enemy,
        rolled: rolled,
        prevented: prevented,
        returnDamage: returnDamage,
        lifeSteal: lifeSteal,
        cpSteal: cpSteal,
        heroTokens: heroTokens,
        minionTokens: minionTokens,
      ),
    );

    _battleDefenseValue = prevented.clamp(0, 99);
    _battleReturnDamage = returnDamage.clamp(0, 99);
    _battleReturnDamageUndefendable =
        _battleReturnDamage > 0 && returnDamageUndefendable;
    _battleLifeSteal = lifeSteal.clamp(0, 99);
    _battleEnemyHeal = 0;
    _battleCpSteal = cpSteal.clamp(0, 99);
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleMinionTokens
      ..clear()
      ..addAll(minionTokens);
    _battleNotes
      ..clear()
      ..addAll(notes);
  }

  Iterable<int> _defenseSelectionIds({
    required EnemyNode enemy,
    required List<GameDie> rolled,
    required int prevented,
    required int returnDamage,
    required int lifeSteal,
    required int cpSteal,
    required List<String> heroTokens,
    required List<String> minionTokens,
  }) {
    final hasEffect =
        prevented > 0 ||
        returnDamage > 0 ||
        lifeSteal > 0 ||
        cpSteal > 0 ||
        heroTokens.isNotEmpty ||
        minionTokens.isNotEmpty ||
        (enemy.profileKey == 'viseer' &&
            rolled.any((die) => die.symbol == DieSymbol.red));
    if (!hasEffect) {
      return const <int>[];
    }

    Iterable<int> firstSymbols(DieSymbol symbol, [int count = 1]) => rolled
        .where((die) => die.symbol == symbol)
        .take(count)
        .map((die) => die.id);

    Iterable<int> allSymbols(DieSymbol symbol) =>
        rolled.where((die) => die.symbol == symbol).map((die) => die.id);

    switch (enemy.profileKey) {
      case 'naraxus':
      case 'ronin-vagabond':
        return rolled.take(1).map((die) => die.id);
      case 'fee':
      case 'elfe-du-chaos':
      case 'bleu-bleu-002':
        return firstSymbols(DieSymbol.yellow, 2);
      case 'enchanteur-gobelin':
        return [
          ...firstSymbols(DieSymbol.yellow),
          ...firstSymbols(DieSymbol.red),
        ];
      case 'archer-de-lombre':
      case 'oni-delirant':
      case 'vert-vert-011':
      case 'vert-vert-012':
      case 'vert-vert-016':
      case 'bleu-bleu-001':
      case 'bleu-bleu-004':
        return allSymbols(DieSymbol.yellow);
      case 'ombre-feline':
      case 'vert-vert-017':
        return firstSymbols(DieSymbol.white);
      case 'epeiste-egare':
      case 'vert-vert-014':
      case 'vert-vert-020':
        return [
          ...allSymbols(DieSymbol.white),
          ...allSymbols(DieSymbol.yellow),
          ...allSymbols(DieSymbol.red),
        ];
      case 'vert-vert-013':
      case 'vert-vert-019':
      case 'bleu-vert-023':
        return allSymbols(DieSymbol.red);
      case 'vert-vert-015':
        return firstSymbols(DieSymbol.red);
      case 'vert-vert-018':
      case 'bleu-vert-022':
      case 'bleu-bleu-003':
        return [...allSymbols(DieSymbol.yellow), ...allSymbols(DieSymbol.red)];
      case 'vert-vert-021':
        return allSymbols(DieSymbol.yellow);
      case 'rat-de-la-rue':
        return [
          ...firstSymbols(DieSymbol.yellow, 2),
          ...firstSymbols(DieSymbol.red, 2),
        ];
      case 'viseer':
        return allSymbols(DieSymbol.red);
      default:
        return rolled.map((die) => die.id);
    }
  }

  void _resolveMinionAttackFromDice() {
    if (_isNaraxus) {
      _resolveNaraxusAttackFromDice();
      return;
    }
    final result = _currentMinionAttackResult();
    final notes = <String>[];
    final heroTokens = <String>[];
    final minionTokens = <String>[];
    var attack = result?.value ?? 0;
    var attackUndefendable = result?.imparable ?? false;
    var lifeSteal = 0;
    var cpSteal = 0;

    if (enemy.profileKey == 'vert-vert-012' &&
        _symbolGoalMet(const SymbolGoal(yellow: 4))) {
      attack = 0;
      notes.add('Rocalanche: roll 2 {die:any} and deal their total value.');
    } else if (enemy.profileKey == 'vert-vert-015' &&
        _symbolGoalMet(const SymbolGoal(white: 2, yellow: 3))) {
      attack = 5;
      attackUndefendable = true;
      notes.add('Abnegation: 5 undefendable damage.');
      notes.add('Abnegation: roll 1 {die:any} to resolve the extra effect.');
    } else if (enemy.profileKey == 'vert-vert-017' &&
        _symbolGoalMet(const SymbolGoal(white: 2, red: 1))) {
      attack = 0;
      notes.add(
        'Claquement de Crocs: roll 1 {die:any}; the value becomes damage and hero receives À Terre.',
      );
    } else if (enemy.profileKey == 'vert-vert-021' &&
        _symbolGoalMet(const SymbolGoal(yellow: 2, red: 1))) {
      attack = 0;
      notes.add(
        'Sorcellerie Ophique: roll 1 {die:any}; then deal 6 damage plus current Chaos.',
      );
    } else if (enemy.profileKey == 'bleu-bleu-003' &&
        _symbolGoalMet(const SymbolGoal(yellow: 2, red: 1))) {
      attack = 0;
      notes.add(
        'Sorcellerie Chaotique: roll 1 {die:any}; then deal 7 damage plus current Chaos.',
      );
    } else if (_attackNeedsExtraDice(enemy) && _currentAttackGoalMet()) {
      notes.add('Attack ready: resolve the extra dice phase before applying.');
    } else if (enemy.profileKey == 'oni-delirant' &&
        _symbolGoalMet(const SymbolGoal(yellow: 4))) {
      notes.add('Attack ready: roll 1 {die:any} to choose the Oni effect.');
    } else if (enemy.profileKey == 'rat-de-la-rue') {
      final suite = _bestSuiteLength(
        _dice
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .toList(),
      );
      if (suite >= 3) {
        notes.add('Chapardage: suite validated.');
      } else if (_rollCount > 0) {
        notes.add('No valid attack yet.');
      }
    } else if (result != null) {
      notes.add(
        result.imparable
            ? 'Attack result: deals ${result.value} undefendable damage.'
            : 'Attack result: deals ${result.value} damage.',
      );
    } else if (_rollCount > 0) {
      notes.add('No valid attack yet.');
    }

    final values = _dice
        .where((die) => die.value != null)
        .map((die) => die.value!)
        .toList();
    final symbols = _dice
        .where((die) => die.symbol != null)
        .map((die) => die.symbol!)
        .toList();
    final hasThreeSameValue = _hasRepeatedValue(values, 3);
    final hasFourSameSymbol = _hasRepeatedSymbol(symbols, 4);

    final acc = _ConditionalAccumulators(
      result: result,
      values: values,
      symbols: symbols,
      attack: attack,
      attackUndefendable: attackUndefendable,
      lifeSteal: lifeSteal,
      cpSteal: cpSteal,
      heroTokens: heroTokens,
      minionTokens: minionTokens,
      notes: notes,
    );

    // Generic data-driven conditional rules take precedence when authored;
    // otherwise fall back to the legacy per-profile switch below.
    if (enemy.attackPlan.conditionalRules.isNotEmpty) {
      _applyConditionalRules(acc);
    } else {
      _applyLegacyConditionalSwitch(acc, hasThreeSameValue, hasFourSameSymbol);
    }

    _battleAttackValue = acc.attack.clamp(0, 99);
    _battleAttackUndefendable = acc.attackUndefendable;
    _battleLifeSteal = acc.lifeSteal.clamp(0, 99);
    _battleEnemyHeal = 0;
    _battleCpSteal = acc.cpSteal.clamp(0, 99);
    _battleHeroTokens
      ..clear()
      ..addAll(acc.heroTokens);
    _battleMinionTokens
      ..clear()
      ..addAll(acc.minionTokens);
    _battleNotes
      ..clear()
      ..addAll(acc.notes);
  }

  /// Legacy per-profile conditional switch, preserved as a fallback when no
  /// authored `conditionalRules` are declared. Kept verbatim so behavior is
  /// identical to the pre-generic-runtime implementation for any enemy not
  /// yet migrated to the data-driven rules.
  void _applyLegacyConditionalSwitch(
    _ConditionalAccumulators acc,
    bool hasThreeSameValue,
    bool hasFourSameSymbol,
  ) {
    final values = acc.values;
    switch (enemy.profileKey) {
      case 'fee':
        if (_bestSuiteLength(values) >= 5) {
          acc.cpSteal = 1;
          acc.notes.add('Large suite: steal 1 CP.');
        }
      case 'elfe-du-chaos':
        if (_bestSuiteLength(values) >= 5) {
          acc.heroTokens.add('Ronces');
          acc.notes.add('Large suite: hero receives Ronces.');
        }
      case 'archer-de-lombre':
        if (hasThreeSameValue) {
          acc.heroTokens.add('Silence');
          acc.notes.add('3 identical values: hero receives Silence.');
        }
      case 'bleu-bleu-002':
        if (acc.result != null && hasThreeSameValue) {
          acc.heroTokens.add('Eboulissement');
          acc.notes.add(
            'Successful attack and 3 identical values: hero receives Eboulissement.',
          );
        }
      case 'ombre-feline':
        if (hasThreeSameValue) {
          acc.heroTokens.add('Hémorragie');
          acc.notes.add('3 identical values: hero receives Hemorragie.');
        }
      case 'ronin-vagabond':
        if (hasFourSameSymbol) {
          acc.minionTokens.add('Riposte');
          acc.notes.add('4 identical symbols: minion gains Riposte.');
        }
      case 'enchanteur-gobelin':
        if (_symbolGoalMet(const SymbolGoal(white: 1, yellow: 2, red: 1))) {
          acc.notes.add('Validated attack: hero discards 1 random card.');
        }
      case 'oni-delirant':
        if (_symbolGoalMet(const SymbolGoal(yellow: 4))) {
          acc.attack = 0;
          acc.lifeSteal = 0;
        }
      case 'vert-vert-012':
        if (!_symbolGoalMet(const SymbolGoal(yellow: 4)) && _rollCount >= 3) {
          acc.attack = 1;
          acc.attackUndefendable = true;
          acc.notes.add(
            'Passive: failed offensive roll, Roc deals 1 undefendable damage.',
          );
        }
      case 'vert-vert-013':
        if (_symbolGoalMet(const SymbolGoal(white: 3, red: 1))) {
          acc.heroTokens.add('Poison');
          acc.notes.add('Validated attack: hero receives Poison.');
        }
      case 'vert-vert-014':
        if (_symbolGoalMet(const SymbolGoal(yellow: 3))) {
          if (_isDruidBearForm(enemy)) {
            acc.heroTokens.add('À Terre');
            acc.notes.add('Bear Form: hero receives À Terre.');
          } else {
            acc.heroTokens.add('Ronces');
            acc.notes.add('Elk Form: hero receives Ronces.');
          }
        }
      case 'vert-vert-018':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 1))) {
          acc.heroTokens.add('Enchevêtrement');
          acc.notes.add('Validated attack: hero receives Enchevêtrement.');
        }
      case 'vert-vert-019':
        if (_symbolGoalMet(const SymbolGoal(red: 2))) {
          acc.notes.add('Validated attack: hero discards 1 random card.');
        }
      case 'vert-vert-020':
        if (_bestSuiteLength(values) >= 5) {
          acc.heroTokens.add('À Terre');
          acc.notes.add('Large suite: hero receives À Terre.');
        }
      case 'bleu-vert-022':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 2, red: 1))) {
          acc.heroTokens.add('Poison');
          acc.notes.add('Validated attack: hero receives Poison.');
        } else if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 2))) {
          acc.heroTokens.add('Parasite');
          acc.notes.add('Validated attack: hero receives Parasite.');
        }
      case 'bleu-vert-023':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 1, red: 1))) {
          acc.attack = 0;
          acc.lifeSteal = 2;
          acc.notes.add('Validated attack: steals 2 HP.');
        }
      case 'bleu-bleu-003':
        if (_symbolGoalMet(const SymbolGoal(yellow: 2, red: 1))) {
          acc.attack = 0;
          acc.notes.add(
            'Sorcellerie Chaotique: roll 1 {die:any}; then deal 7 damage plus current Chaos.',
          );
        }
      case 'bleu-bleu-004':
        if (_symbolGoalMet(const SymbolGoal(yellow: 5))) {
          acc.attack = 0;
          acc.lifeSteal = 5;
          acc.notes.add('Hemo-Siphon: steals 5 health.');
        } else if (_symbolGoalMet(const SymbolGoal(yellow: 4))) {
          acc.attack = 0;
          acc.lifeSteal = 4;
          acc.notes.add('Hemo-Siphon: steals 4 health.');
        } else if (_symbolGoalMet(const SymbolGoal(yellow: 3))) {
          acc.attack = 0;
          acc.lifeSteal = 3;
          acc.notes.add('Hemo-Siphon: steals 3 health.');
        }
      case 'rat-de-la-rue':
        final suite = _bestSuiteLength(values);
        if (suite >= 5) {
          acc.cpSteal = 2;
          acc.attack = (enemy.combatPoints + acc.cpSteal).clamp(0, 99);
          acc.attackUndefendable = false;
          acc.notes.add(
            'Large suite: Rat steals 2 CP, then deals damage equal to its CP (${acc.attack}).',
          );
        } else if (suite >= 4) {
          acc.cpSteal = 1;
          acc.attack = (enemy.combatPoints + acc.cpSteal).clamp(0, 99);
          acc.attackUndefendable = false;
          acc.notes.add(
            'Small suite: Rat steals 1 CP, then deals damage equal to its CP (${acc.attack}).',
          );
        } else if (suite >= 3) {
          acc.cpSteal = 1;
          acc.attack = 0;
          acc.attackUndefendable = false;
          acc.notes.add('Micro suite: Rat steals 1 CP.');
        }
    }
  }

  /// Applies the authored [ConditionalRule]s from the attack plan, replacing
  /// the legacy per-profile switch when rules are declared. Rules are
  /// evaluated in order; the first matching [ConditionalRule.exclusive]
  /// rule wins (the rest are skipped) — this models `if / else if`
  /// cascades (Rat de la Rue, Hemo-Siphon, Plague Bearer). Non-exclusive
  /// rules all fire. `text` rules are display-only and never auto-apply.
  void _applyConditionalRules(_ConditionalAccumulators acc) {
    final rules = enemy.attackPlan.conditionalRules;
    if (rules.isEmpty) return;
    for (final rule in rules) {
      if (rule.minRollCount > 0 && _rollCount < rule.minRollCount) {
        continue;
      }
      if (!_conditionalRuleMatches(rule, acc)) continue;
      _applyConditionalEffect(rule.effect, acc);
      if (rule.exclusive) break;
    }
  }

  /// Returns true when [rule]'s condition matches the current roll state,
  /// honoring `negate` and `and` conjunctions.
  bool _conditionalRuleMatches(
    ConditionalRule rule,
    _ConditionalAccumulators acc,
  ) {
    final primary = _conditionMatches(rule.condition, acc);
    if (!primary) return false;
    for (final extra in rule.condition.and) {
      if (!_conditionMatches(extra, acc)) return false;
    }
    return true;
  }

  /// Evaluates a single [ConditionalCondition] predicate against the roll
  /// state, applying `negate`. `text` conditions never match (display-only).
  bool _conditionMatches(
    ConditionalCondition condition,
    _ConditionalAccumulators acc,
  ) {
    bool matched;
    switch (condition.type) {
      case ConditionalConditionType.sameValue:
        matched = _hasRepeatedValue(acc.values, condition.count);
      case ConditionalConditionType.sameSymbol:
        matched = _hasRepeatedSymbol(acc.symbols, condition.count);
      case ConditionalConditionType.suite:
        matched = _bestSuiteLength(acc.values) >= condition.minLength;
      case ConditionalConditionType.symbols:
        matched = _symbolGoalMet(
          SymbolGoal(
            white: condition.white,
            yellow: condition.orange,
            red: condition.red,
          ),
        );
      case ConditionalConditionType.attackSucceededAnd:
        final inner = condition.inner;
        matched = acc.result != null &&
            (inner == null || _conditionMatches(inner, acc));
      case ConditionalConditionType.alteration:
        final alterations = enemy.alterations;
        matched = condition.present.every(alterations.contains) &&
            !condition.absent.any(alterations.contains);
      case ConditionalConditionType.text:
        matched = false;
    }
    return condition.negate ? !matched : matched;
  }

  /// Applies a [ConditionalEffect] to the accumulators: tokens, damage
  /// override (literal or formula), undefendable flag, lifeSteal, cpSteal,
  /// and note.
  void _applyConditionalEffect(
    ConditionalEffect effect,
    _ConditionalAccumulators acc,
  ) {
    acc.heroTokens.addAll(effect.heroTokens);
    acc.minionTokens.addAll(effect.minionTokens);
    if (effect.damage != null) {
      acc.attack = effect.damage!;
    } else if (effect.damageFormula != null) {
      acc.attack = _resolveDamageFormula(effect.damageFormula!, acc);
    }
    if (effect.undefendable) {
      acc.attackUndefendable = true;
    }
    if (effect.lifeSteal != 0) {
      acc.lifeSteal = effect.lifeSteal;
    }
    if (effect.cpSteal != 0) {
      acc.cpSteal = effect.cpSteal;
    }
    if (effect.note != null && effect.note!.isNotEmpty) {
      acc.notes.add(effect.note!);
    }
  }

  /// Resolves a state-dependent damage formula. Supports `cp` (minion's
  /// current CP) and `cp+cpSteal` (CP plus the cpSteal applied by this
  /// rule), mirroring the legacy Rat de la Rue computation. Unknown
  /// formulas leave the existing attack value untouched.
  int _resolveDamageFormula(String formula, _ConditionalAccumulators acc) {
    switch (formula) {
      case 'cp':
        return enemy.combatPoints.clamp(0, 99).toInt();
      case 'cp+cpSteal':
        return (enemy.combatPoints + acc.cpSteal).clamp(0, 99).toInt();
      default:
        return acc.attack;
    }
  }

  void _resolveNaraxusAttackFromDice() {
    final first = _dice.first.value;
    if (first == null) {
      return;
    }
    _extraDiceOutcomeMessage = '';
    final notes = <String>[];
    var attack = 0;
    var enemyHeal = 0;
    final heroTokens = <String>[];

    switch (first) {
      case 1:
        attack = 3;
        _battleAttackUndefendable = true;
        enemyHeal = 4;
        _removeRandomEnemyToken();
        notes.add('Swoop: Naxarus removes 1 random token and heals 4 HP.');
        notes.add('Swoop: 3 undefendable damage.');
      case 2:
        attack = 8;
        _battleAttackUndefendable = false;
        notes.add('Ember Spark: hero moves top 3 deck cards to discard.');
        notes.add('Ember Spark: 8 damage.');
      case 3:
        attack = 0;
        _battleAttackUndefendable = false;
        notes.add(
          'Gashing Bite: the player rolls 4 dice in the extra dice phase.',
        );
        notes.add(
          'Damage will equal the 2 highest dice after hero interactions.',
        );
      case 4:
        attack = 9;
        _battleAttackUndefendable = false;
        heroTokens.add('Hoarding');
        notes.add('Hoarding: hero loses 1 die on the next battle roll.');
        notes.add('Hoarding: 9 damage.');
      case 5:
        attack = 8;
        _battleAttackUndefendable = true;
        notes.add('Thundering Roar: hero discards 1 card.');
        notes.add('Thundering Roar: 8 undefendable damage.');
      case 6:
        attack = 10;
        _battleAttackUndefendable = false;
        notes.add("Dragon's Might: 10 damage.");
        notes.add(
          "Dragon's Might: the player rolls 1 die in the extra dice phase; on 5-6, Swoop also triggers.",
        );
    }

    _battleAttackValue = attack.clamp(0, 99);
    _battleLifeSteal = 0;
    _battleEnemyHeal = enemyHeal.clamp(0, 99);
    _battleCpSteal = 0;
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleMinionTokens.clear();
    _battleNotes
      ..clear()
      ..addAll(notes);
  }

  void _resolveExtraDicePhase(List<GameDie> extraDice) {
    if (_phase == CombatPhase.hero &&
        _isViseerNode(enemy) &&
        _viseerDefensePassivePending) {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final message = _resolveViseerPassiveRoll(
        rolled.first.value!,
        source: 'Viseer defense passive',
      );
      setState(() {
        _viseerDefensePassivePending = false;
        _extraDiceOutcomeMessage = message;
        _battleNotes.add(message);
      });
      widget.adventure.log(message);
      widget.onChanged();
      return;
    }
    if (_phase != CombatPhase.minionAttack) {
      return;
    }
    if (enemy.profileKey == 'vert-vert-012') {
      final values = extraDice
          .where((die) => die.value != null)
          .map((die) => die.value!)
          .toList();
      if (values.isEmpty) {
        return;
      }
      _markExtraDiceSelection(
        extraDice,
        extraDice.where((die) => die.value != null).map((die) => die.id),
      );
      final damage = values.fold<int>(0, (sum, value) => sum + value);
      setState(() {
        _battleAttackValue = damage.clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleLifeSteal = 0;
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _battleHeroTokens.clear();
        _battleMinionTokens.clear();
        _battleNotes
          ..clear()
          ..add('Rocalanche: ${values.join(' + ')} deals $damage damage.');
        _extraDiceOutcomeMessage =
            'Rocalanche extra roll: ${values.join('/')}.\n'
            'Roc inflicts $damage damage, equal to the total roll value.';
      });
      return;
    }
    if (enemy.profileKey == 'vert-vert-015') {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final roll = rolled.first.value!;
      final symbol = _symbolForFace(roll);
      setState(() {
        _battleAttackValue = 5;
        _battleAttackUndefendable = true;
        _battleLifeSteal = 0;
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _discipleSummonLevel3 = false;
        _battleHeroTokens.clear();
        _battleMinionTokens.clear();
        _battleNotes.clear();
        if (symbol == DieSymbol.white) {
          _battleNotes.add('Abnegation extra die $roll: no extra effect.');
          _extraDiceOutcomeMessage =
              'Abnegation extra die: $roll.\n'
              'White symbol: no extra effect.';
        } else if (symbol == DieSymbol.yellow) {
          _battleCpSteal = 1;
          _battleNotes.add('Abnegation extra die $roll: steals 1 CP.');
          _extraDiceOutcomeMessage =
              'Abnegation extra die: $roll.\n'
              'Orange symbol: Disciple steals 1 CP.';
        } else {
          _discipleSummonLevel3 = true;
          _battleNotes.add(
            'Abnegation extra die $roll: after OK, this combat ends and a random level 3 minion engages.',
          );
          _extraDiceOutcomeMessage =
              'Abnegation extra die: $roll.\n'
              'Red symbol: after OK, Disciple leaves and a random level 3 minion engages.';
        }
      });
      return;
    }
    if (enemy.profileKey == 'vert-vert-017') {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final roll = rolled.first.value!;
      setState(() {
        _battleAttackValue = roll.clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleLifeSteal = 0;
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _battleHeroTokens
          ..clear()
          ..add('À Terre');
        _battleMinionTokens.clear();
        _battleNotes
          ..clear()
          ..add(
            'Claquement de Crocs extra die $roll: deals $roll damage and gives À Terre.',
          );
        _extraDiceOutcomeMessage =
            'Claquement de Crocs extra die: $roll.\n'
            'Homme Lezard inflicts $roll damage and gives À Terre.';
      });
      return;
    }
    if (enemy.profileKey == 'vert-vert-021') {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final roll = rolled.first.value!;
      final symbol = _symbolForFace(roll);
      final currentChaos = _tokenCount(enemy.alterations, 'Chaos');
      final gainedChaos = symbol == DieSymbol.white ? 2 : 0;
      final totalChaos = currentChaos + gainedChaos;
      setState(() {
        _battleAttackValue = (6 + totalChaos).clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleLifeSteal = 0;
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _battleHeroTokens.clear();
        _battleMinionTokens.clear();
        _battleNotes.clear();
        if (symbol == DieSymbol.white) {
          _battleMinionTokens.addAll(const ['Chaos', 'Chaos']);
          _battleNotes.add(
            'Sorcellerie Ophique extra die $roll: Mage Lezard gains 2 Chaos during the roll.',
          );
        } else if (symbol == DieSymbol.yellow) {
          _battleHeroTokens.add('Eboulissement');
          _battleNotes.add(
            'Sorcellerie Ophique extra die $roll: hero receives Eboulissement after OK.',
          );
        } else {
          _battleNotes.add(
            'Sorcellerie Ophique extra die $roll: red symbol adds no extra effect.',
          );
        }
        _battleNotes.add(
          'Sorcellerie Ophique: 6 base damage + $totalChaos Chaos = $_battleAttackValue damage.',
        );
        _extraDiceOutcomeMessage =
            'Sorcellerie Ophique extra die: $roll.\n'
            '${symbol == DieSymbol.white
                ? 'White symbol: Mage Lezard gains 2 Chaos immediately for this attack.\n'
                : symbol == DieSymbol.yellow
                ? 'Orange symbol: hero receives Eboulissement after OK.\n'
                : 'Red symbol: no extra effect.\n'}'
            'Mage Lezard inflicts 6 + $totalChaos Chaos = $_battleAttackValue damage.';
      });
      return;
    }
    if (enemy.profileKey == 'bleu-bleu-003') {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final roll = rolled.first.value!;
      final symbol = _symbolForFace(roll);
      final currentChaos = _tokenCount(enemy.alterations, 'Chaos');
      final gainedChaos = symbol == DieSymbol.white ? 2 : 0;
      final totalChaos = currentChaos + gainedChaos;
      setState(() {
        _battleAttackValue = (7 + totalChaos).clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleLifeSteal = 0;
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _battleHeroTokens.clear();
        _battleMinionTokens.clear();
        _battleNotes.clear();
        if (symbol == DieSymbol.white) {
          _battleMinionTokens.addAll(const ['Chaos', 'Chaos']);
          _battleNotes.add(
            'Sorcellerie Chaotique extra die $roll: Mage de l Entropie gains 2 Chaos during the roll.',
          );
        } else if (symbol == DieSymbol.yellow) {
          _battleHeroTokens.add('Sort 6');
          _battleNotes.add(
            'Sorcellerie Chaotique extra die $roll: hero receives Sort 6 after OK.',
          );
        }
        _battleNotes.add(
          'Sorcellerie Chaotique: 7 base damage + $totalChaos Chaos = $_battleAttackValue damage.',
        );
        _extraDiceOutcomeMessage =
            'Sorcellerie Chaotique extra die: $roll.\n'
            '${symbol == DieSymbol.white
                ? 'White symbol: Mage de l Entropie gains 2 Chaos immediately for this attack.\n'
                : symbol == DieSymbol.yellow
                ? 'Orange symbol: hero receives Sort 6 after OK.\n'
                : 'Red symbol: no extra effect.\n'}'
            'Mage de l Entropie inflicts 7 + $totalChaos Chaos = $_battleAttackValue damage.';
      });
      return;
    }
    if (enemy.profileKey == 'oni-delirant') {
      final rolled = extraDice.where((die) => die.value != null).toList();
      if (rolled.isEmpty) {
        return;
      }
      _markExtraDiceSelection(extraDice, [rolled.first.id]);
      final roll = rolled.first.value!;
      final symbol = _symbolForFace(roll);
      setState(() {
        _battleEnemyHeal = 0;
        _battleCpSteal = 0;
        _battleHeroTokens.clear();
        _battleMinionTokens.clear();
        _battleNotes.clear();
        if (symbol == DieSymbol.white) {
          _battleAttackValue = 5;
          _battleAttackUndefendable = true;
          _battleLifeSteal = 0;
          _battleNotes.add(
            'Onisima extra die $roll: deals 5 undefendable damage.',
          );
          _extraDiceOutcomeMessage =
              'Onisima extra die: $roll.\n'
              'White symbol: Oni inflicts 5 undefendable damage.';
        } else if (symbol == DieSymbol.yellow) {
          _battleAttackValue = 6;
          _battleAttackUndefendable = true;
          _battleLifeSteal = 0;
          _battleNotes.add(
            'Onisima extra die $roll: deals 6 undefendable damage.',
          );
          _extraDiceOutcomeMessage =
              'Onisima extra die: $roll.\n'
              'Orange symbol: Oni inflicts 6 undefendable damage.';
        } else {
          _battleAttackValue = 0;
          _battleAttackUndefendable = false;
          _battleLifeSteal = 4;
          _battleNotes.add('Onisima extra die $roll: steals 4 health.');
          _extraDiceOutcomeMessage =
              'Onisima extra die: $roll.\n'
              'Red symbol: Oni steals 4 health.';
        }
      });
      return;
    }
    if (!_isNaraxus) {
      return;
    }
    final baseAttack = _dice.first.value;
    final rolledDice = extraDice.where((die) => die.value != null).toList()
      ..sort((a, b) => b.value!.compareTo(a.value!));
    if (rolledDice.isEmpty) {
      return;
    }
    setState(() {
      if (baseAttack == 3) {
        final topTwoDice = rolledDice.take(2).toList();
        final topTwo = topTwoDice.map((die) => die.value!).toList();
        _markExtraDiceSelection(extraDice, topTwoDice.map((die) => die.id));
        final damage = topTwo.fold<int>(0, (sum, value) => sum + value);
        _battleAttackValue = damage.clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleEnemyHeal = 0;
        _battleHeroTokens.clear();
        _battleNotes
          ..clear()
          ..add(
            'Gashing Bite: top dice ${topTwo.join(' + ')} deal $damage damage.',
          );
        _extraDiceOutcomeMessage =
            'Gashing Bite extra roll: ${rolledDice.map((die) => die.value!).toList().reversed.join('/')}.\n'
            'Naxarus inflicts $damage damage with the 2 highest dice (${topTwo.join(' + ')}).';
      } else if (baseAttack == 6) {
        final extraDie = rolledDice.first;
        _markExtraDiceSelection(extraDice, [extraDie.id]);
        final extra = extraDie.value!;
        var damage = 10;
        var heal = 0;
        final notes = <String>["Dragon's Might: 10 damage."];
        if (extra >= 5) {
          damage += 3;
          heal = 4;
          notes.add('Extra die $extra: Swoop is added.');
          notes.add(
            'Swoop: Naxarus heals 4 HP and deals 3 undefendable damage.',
          );
        } else {
          notes.add('Extra die $extra: no Swoop added.');
        }
        _battleAttackValue = damage.clamp(0, 99);
        _battleAttackUndefendable = false;
        _battleEnemyHeal = heal;
        _battleHeroTokens.clear();
        _battleNotes
          ..clear()
          ..addAll(notes);
        _extraDiceOutcomeMessage = extra >= 5
            ? "Dragon's Might extra die: $extra.\n"
                  'Swoop is added: Naxarus inflicts 13 damage and heals 4 HP.'
            : "Dragon's Might extra die: $extra.\n"
                  'No Swoop: Naxarus inflicts 10 defendable damage.';
      }
    });
  }

  void _markExtraDiceSelection(
    Iterable<GameDie> dice,
    Iterable<int> selectedIds,
  ) {
    final selected = selectedIds.toSet();
    for (final die in dice) {
      die.reserved = selected.contains(die.id);
    }
  }

  void _removeRandomEnemyToken() {
    if (enemy.alterations.isEmpty) {
      return;
    }
    enemy.alterations.removeAt(_random.nextInt(enemy.alterations.length));
  }

  _AttackDamage? _currentMinionAttackResult() {
    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        _AttackDamage? result;
        for (final goal in enemy.attackPlan.goals) {
          if (_symbolGoalMet(goal)) {
            result = _damageForSymbolGoal(enemy, goal);
          }
        }
        return result;
      case MinionAttackStyle.suite:
        final values = _dice
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .toList();
        return _suiteDamage(enemy, _bestSuiteLength(values));
      case MinionAttackStyle.none:
        return null;
    }
  }

  bool _currentAttackGoalMet() {
    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        return enemy.attackPlan.goals.any(_symbolGoalMet);
      case MinionAttackStyle.suite:
        final values = _dice
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .toList();
        return _bestSuiteLength(values) >= 3;
      case MinionAttackStyle.none:
        return false;
    }
  }

  bool _hasRepeatedValue(List<int> values, int count) {
    final counts = <int, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.values.any((value) => value >= count);
  }

  bool _hasRepeatedSymbol(List<DieSymbol> symbols, int count) {
    final counts = <DieSymbol, int>{};
    for (final symbol in symbols) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
    return counts.values.any((value) => value >= count);
  }

  int _tokenCount(List<String> tokens, String label) {
    return tokens.where((token) => token == label).length;
  }

  void _applyBattleResolution() {
    if (!_isBattlePhase) {
      return;
    }
    _captureStepUndo();
    late final CombatPhase nextPhase;
    setState(() {
      final effectiveDefense = _battleAttackUndefendable
          ? 0
          : _battleDefenseValue;
      final netDamage = max(0, _battleAttackValue - effectiveDefense);
      if (_phase == CombatPhase.hero) {
        enemy.health = (enemy.health - netDamage).clamp(0, 99);
        if (_battleCpSteal > 0) {
          widget.adventure.setHeroPc(
            widget.adventure.combatPoints - _battleCpSteal,
          );
          enemy.combatPoints = (enemy.combatPoints + _battleCpSteal).clamp(
            0,
            99,
          );
        }
        if (_battleReturnDamage > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleReturnDamage,
          );
        }
        if (_battleLifeSteal > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleLifeSteal,
          );
          enemy.health = (enemy.health + _battleLifeSteal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleEnemyHeal > 0) {
          enemy.health = (enemy.health + _battleEnemyHeal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        enemy.alterations.addAll(_battleMinionTokens);
        widget.adventure.alterations.addAll(_battleHeroTokens);
        widget.adventure.log(
          'Hero battle applied: $netDamage damage to ${enemy.label}.',
        );
        if (_battleAttackValue == 0) {
          _lastBattleOutcomeMessage =
              '${widget.adventure.hero.label} attack failed.';
        } else {
          _lastBattleOutcomeMessage =
              '${widget.adventure.hero.label} dealt $_battleAttackValue damage. '
              '${_battleAttackUndefendable ? 'This attack is undefendable.' : '${enemy.label} prevented $_battleDefenseValue damage.'}\n'
              'Net damage: deals $netDamage damage.'
              '${_battleReturnDamage > 0 ? ' Return damage: $_battleReturnDamage.' : ''}'
              '${_battleLifeSteal > 0 ? ' Steals $_battleLifeSteal health.' : ''}'
              '${_battleHeroTokens.isNotEmpty ? ' Hero receives ${_battleHeroTokens.join(', ')}.' : ''}'
              '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}'
              '${_battleCpSteal > 0 ? ' ${enemy.label} steals $_battleCpSteal CP.' : ''}';
        }
        _heroAttackCount++;
        _heroAttackTotal += _battleAttackValue;
        _lastHeroAttack = _battleAttackValue;
        if (enemy.health <= 0) {
          _grantViseerRewardIfNeeded(enemy);
        }
        if (widget.adventure.alterations.remove('Hoarding')) {
          widget.adventure.log('Hoarding expired after hero battle phase.');
          _lastBattleOutcomeMessage =
              '$_lastBattleOutcomeMessage Hoarding expires.';
        }
        _activeEnemyId = _firstEnemyTurnId();
        nextPhase = CombatPhase.minionUpkeep;
      } else {
        final shouldSummonLevel3 = _discipleSummonLevel3;
        widget.adventure.setHeroHealth(widget.adventure.health - netDamage);
        if (_battleLifeSteal > 0) {
          widget.adventure.setHeroHealth(
            widget.adventure.health - _battleLifeSteal,
          );
          enemy.health = (enemy.health + _battleLifeSteal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleEnemyHeal > 0) {
          enemy.health = (enemy.health + _battleEnemyHeal).clamp(
            0,
            enemy.maxHealth,
          );
        }
        if (_battleCpSteal > 0) {
          widget.adventure.setHeroPc(
            widget.adventure.combatPoints - _battleCpSteal,
          );
          enemy.combatPoints = (enemy.combatPoints + _battleCpSteal).clamp(
            0,
            99,
          );
        }
        widget.adventure.alterations.addAll(_battleHeroTokens);
        enemy.alterations.addAll(_battleMinionTokens);
        widget.adventure.log(
          'Minion battle applied: $netDamage damage to hero.',
        );
        _lastBattleOutcomeMessage =
            '${enemy.label} dealt $_battleAttackValue damage. '
            '${_battleAttackUndefendable ? 'This attack is undefendable.' : '${widget.adventure.hero.label} prevented $_battleDefenseValue damage.'}\n'
            'Net damage: deals $netDamage damage.'
            '${_battleHeroTokens.isNotEmpty ? ' ${widget.adventure.hero.label} receives ${_battleHeroTokens.join(', ')}.' : ''}'
            '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}'
            '${_battleEnemyHeal > 0 ? ' ${enemy.label} heals $_battleEnemyHeal HP.' : ''}'
            '${_battleLifeSteal > 0 ? ' ${enemy.label} steals $_battleLifeSteal health.' : ''}'
            '${_battleCpSteal > 0 ? ' ${enemy.label} steals $_battleCpSteal CP.' : ''}'
            '${shouldSummonLevel3 ? ' Disciple leaves: a random level 3 minion engages.' : ''}';
        if (enemy.health <= 0) {
          _grantViseerRewardIfNeeded(enemy);
        }
        if (shouldSummonLevel3) {
          _replaceCurrentEnemyWithRandomLevel3();
          nextPhase = CombatPhase.intro;
        } else {
          final nextEnemy = _nextEnemyTurnIdAfter(enemy.id);
          if (nextEnemy != null) {
            _activeEnemyId = nextEnemy;
            nextPhase = CombatPhase.minionUpkeep;
          } else {
            _activeEnemyId = _nextLivingEnemyId();
            nextPhase = CombatPhase.heroUpkeep;
          }
        }
      }
      widget.onChanged();
    });
    if (_isResolutionMode) {
      return;
    }
    _setPhase(nextPhase);
  }

  void _replaceCurrentEnemyWithRandomLevel3() {
    final profiles = _profilesForRank(EnemyRank.violet);
    if (profiles.isEmpty) {
      widget.adventure.log(
        'Disciple red effect failed: no level 3 profiles available.',
      );
      return;
    }
    final previous = enemy;
    final profile = profiles[_random.nextInt(profiles.length)];
    final replacement = EnemyNode(
      id: previous.id,
      label: profile.name,
      rank: EnemyRank.violet,
      maxHealth: profile.maxHealth,
      cp: profile.cp,
      attacks: profile.attacks,
      defense: profile.defense,
      defenseDice: profile.defenseDice,
      attackPlan: profile.attackPlan,
      cardAsset: profile.cardAsset,
      profileKey: profile.key,
      initialTokens: profile.initialTokens,
      rewardChests: profile.rewardChests,
      rewardRank: profile.rewardRank ?? profile.rank,
      rewardRanks: profile.rewardRanks,
      passives: profile.passives,
      defenseDisplayRows: profile.defenseDisplayRows,
      passiveDisplayRows: profile.passiveDisplayRows,
      branch: previous.branch,
      step: previous.step,
    )..current = true;
    final index = widget.adventure.enemies.indexWhere(
      (node) => node.id == previous.id,
    );
    if (index >= 0) {
      widget.adventure.enemies[index] = replacement;
    }
    widget.adventure.log(
      'Disciple red effect: ${previous.label} leaves, ${profile.name} engages.',
    );
    _resetBattleResolution();
    _resetDice();
  }

  void _applyHeroUpkeep({bool captureUndo = true}) {
    if (!mounted || _heroUpkeepApplied || _phase != CombatPhase.heroUpkeep) {
      return;
    }
    if (captureUndo) {
      _captureStepUndo();
    }
    UpkeepOutcome? heroOutcome;
    setState(() {
      _heroUpkeepApplied = true;
      heroOutcome = GameEngine.heroUpkeep(
        tokens: widget.adventure.alterations,
        rollD6: () => _random.nextInt(6) + 1,
      );
      widget.adventure.setHeroPc(
        widget.adventure.combatPoints + heroOutcome!.cpDelta,
      );
      widget.adventure.setHeroHealth(
        widget.adventure.health + heroOutcome!.healthDelta,
      );
      for (final t in heroOutcome!.removedTokens) {
        widget.adventure.alterations.remove(t);
      }
      widget.adventure.log(
        '${widget.adventure.hero.label} upkeep: ${heroOutcome!.log}.',
      );
      widget.onChanged();
    });
    if (heroOutcome != null && heroOutcome!.notes.isNotEmpty) {
      for (final note in heroOutcome!.notes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(note), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _applyUpkeep({bool captureUndo = true}) {
    if (_upkeepApplied) {
      return;
    }
    if (captureUndo) {
      _captureStepUndo();
    }
    setState(() {
      var passiveLog = '';
      if (enemy.profileKey == 'vert-vert-014') {
        passiveLog = _isDruidBearForm(enemy)
            ? 'Druid form: Bear Form is active'
            : 'Druid form: Elk Form is active';
      }
      if (enemy.profileKey == 'bleu-bleu-004') {
        enemy.alterations.add('Chaos');
        final chaosCount = _tokenCount(enemy.alterations, 'Chaos');
        passiveLog = 'Blood Mage gains 1 Chaos and now has $chaosCount Chaos';
        if (chaosCount >= 3) {
          for (var i = 0; i < 3; i++) {
            enemy.alterations.remove('Chaos');
          }
          widget.adventure.setHeroHealth(widget.adventure.health - 3);
          enemy.health = (enemy.health + 3).clamp(0, enemy.maxHealth);
          passiveLog += ', spends 3 Chaos and steals 3 health';
        }
      }
      if (_isViseerNode(enemy)) {
        passiveLog = _resolveViseerPassive(source: 'Viseer upkeep');
      }
      final outcome = GameEngine.minionUpkeep(
        tokens: enemy.alterations,
        rollD6: () => _random.nextInt(6) + 1,
      );
      final cpDelta = _enemyHasInfiniteCp(enemy) ? 0 : outcome.cpDelta;
      enemy.combatPoints = (enemy.combatPoints + cpDelta).clamp(0, 99);
      enemy.health = (enemy.health + outcome.healthDelta).clamp(0, 99);
      for (final token in outcome.removedTokens) {
        enemy.alterations.remove(token);
      }
      _upkeepApplied = true;
      final upkeepLog = _enemyHasInfiniteCp(enemy)
          ? _naxarusUpkeepLog(outcome)
          : outcome.log;
      final combinedLog = [
        if (passiveLog.isNotEmpty) passiveLog,
        if (upkeepLog.isNotEmpty) upkeepLog,
      ].join(', ');
      if (combinedLog.isNotEmpty) {
        widget.adventure.log('${enemy.label} upkeep: $combinedLog.');
      }
      _lastBattleOutcomeMessage = _isViseerNode(enemy) ? passiveLog : '';
      widget.onChanged();
    });
    if (enemy.health <= 0) {
      if (!_isNaraxus) {
        
      } else {
          }
    }
  }

  String _naxarusUpkeepLog(UpkeepOutcome outcome) {
    final parts = <String>[];
    if (outcome.healthDelta != 0) {
      parts.add('${outcome.healthDelta} HP');
    }
    if (outcome.removedTokens.isNotEmpty) {
      parts.add('removed ${outcome.removedTokens.join(', ')}');
    }
    return parts.join(', ');
  }

  String _resolveViseerPassive({required String source}) {
    final roll = _random.nextInt(6) + 1;
    return _resolveViseerPassiveRoll(roll, source: source);
  }

  String _resolveViseerPassiveRoll(int roll, {required String source}) {
    final symbol = _symbolForFace(roll);
    final boss = _primaryEnemy;
    switch (symbol) {
      case DieSymbol.white:
        return '$source: Viseer rolls $roll (white). No effect.';
      case DieSymbol.yellow:
        boss.combatPoints = (boss.combatPoints + 1).clamp(0, 99);
        final negativeTokens = boss.alterations
            .where(
              (token) =>
                  _tokenRuleFromTag(token).kind == StatusTokenKind.negative,
            )
            .toList();
        String removedText;
        if (negativeTokens.isEmpty) {
          removedText = 'no negative token to remove';
        } else {
          final removed =
              negativeTokens[_random.nextInt(negativeTokens.length)];
          boss.alterations.remove(removed);
          removedText = 'removes $removed';
        }
        return '$source: Viseer rolls $roll (orange). ${boss.label} gains 1 CP and $removedText.';
      case DieSymbol.red:
        boss.alterations.add('Main du roi');
        return '$source: Viseer rolls $roll (red). ${boss.label} gains Main du roi.';
    }
  }

  void _grantViseerRewardIfNeeded(EnemyNode defeated) {
    if (!_isViseerNode(defeated) || _viseerRewardGranted) {
      return;
    }
    _viseerRewardGranted = true;
    widget.adventure.bonuses.add('Draw 3 cards');
    widget.adventure.alterations.add('Salve');
    final message =
        '${widget.adventure.hero.label} defeated Viseer: draw 3 cards and gain Salve.';
    widget.adventure.log(message);
    _lastBattleOutcomeMessage = _lastBattleOutcomeMessage.isEmpty
        ? message
        : '$_lastBattleOutcomeMessage\n$message';
  }

  void _applyMinionDiceStrategy() {
    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.suite:
        _reserveBestSuite();
      case MinionAttackStyle.symbols:
        _reserveSymbolGoal();
      case MinionAttackStyle.none:
        return;
    }
  }

  void _reserveBestSuite() {
    final decision = MinionDiceEngine.chooseSuiteHold(_dice);
    final needed = <int, int>{for (final value in decision.values) value: 1};
    for (final die in _dice) {
      final value = die.value;
      if (value == null || (needed[value] ?? 0) <= 0) {
        die.reserved = false;
      } else {
        die.reserved = true;
        needed[value] = needed[value]! - 1;
      }
    }
  }

  void _reserveSymbolGoal() {
    final goals = enemy.attackPlan.goals;
    if (goals.isEmpty) {
      return;
    }
    var goal = goals.first;
    for (final candidate in goals) {
      if (!_symbolGoalMet(candidate)) {
        goal = candidate;
        break;
      }
      goal = candidate;
    }
    var white = goal.white;
    var yellow = goal.yellow;
    var red = goal.red;
    for (final die in _dice) {
      final symbol = die.symbol;
      if (symbol == DieSymbol.white && white > 0) {
        die.reserved = true;
        white--;
      } else if (symbol == DieSymbol.yellow && yellow > 0) {
        die.reserved = true;
        yellow--;
      } else if (symbol == DieSymbol.red && red > 0) {
        die.reserved = true;
        red--;
      } else {
        die.reserved = false;
      }
    }
  }

  bool _symbolGoalMet(SymbolGoal goal) {
    final counts = _symbolCounts();
    return (counts[DieSymbol.white] ?? 0) >= goal.white &&
        (counts[DieSymbol.yellow] ?? 0) >= goal.yellow &&
        (counts[DieSymbol.red] ?? 0) >= goal.red;
  }

  Map<DieSymbol, int> _symbolCounts() {
    final counts = <DieSymbol, int>{};
    for (final die in _dice) {
      final symbol = die.symbol;
      if (symbol != null) {
        counts[symbol] = (counts[symbol] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool _shouldResolveSpecialAttack() {
    return enemy.profileKey == 'oni-delirant' &&
        _phase == CombatPhase.minionAttack &&
        _symbolGoalMet(const SymbolGoal(yellow: 4));
  }

  Future<void> _resolveSpecialAttack() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attack choice'),
        content: const Text(
          'The minion attack succeeded. Continue to the single die roll?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Roll'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) {
      return;
    }

    final roll = _random.nextInt(6) + 1;
    final symbol = _symbolForFace(roll);
    final effect = switch (symbol) {
      DieSymbol.white => '5 imparable damage to the hero',
      DieSymbol.yellow => '6 imparable damage to the hero',
      DieSymbol.red => 'steal 4 HP',
    };
    setState(() {
      _specialAttackMode = true;
      _specialAttackReady = false;
      _rollCount = 1;
      _diceToRoll = 1;
      for (final die in _dice) {
        die
          ..value = null
          ..settled = true
          ..reserved = true;
      }
      _dice.first
        ..value = roll
        ..settled = true
        ..reserved = false;
    });

    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('D6 $roll'),
        content: Text(effect),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) {
      return;
    }
    setState(() {
      if (symbol == DieSymbol.white) {
        widget.adventure.setHeroHealth(widget.adventure.health - 5);
      } else if (symbol == DieSymbol.yellow) {
        widget.adventure.setHeroHealth(widget.adventure.health - 6);
      } else {
        widget.adventure.setHeroHealth(widget.adventure.health - 4);
        enemy.health = (enemy.health + 4).clamp(0, enemy.maxHealth);
      }
      widget.adventure.log('Oni attack choice: D6 $roll, $effect.');
      widget.onChanged();
    });
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

enum _GameOverAction { history, homepage }

class CompactItemStrip extends StatefulWidget {
  const CompactItemStrip({
    required this.label,
    required this.emptyText,
    required this.items,
    required this.accent,
    required this.background,
    required this.border,
    this.compactDuplicates = true,
    this.leading,
    this.trailing,
    this.onTokensChanged,
    super.key,
  });

  final String label;
  final String emptyText;
  final List<String> items;
  final Color accent;
  final Color background;
  final Color border;
  final bool compactDuplicates;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTokensChanged;

  @override
  State<CompactItemStrip> createState() => _CompactItemStripState();
}

class _CompactItemStripState extends State<CompactItemStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items
        .where((value) => _isVisibleStatusTokenLabel(value))
        .toList(growable: false);
    final displayItems = widget.compactDuplicates
        ? _compactItemModels(visibleItems)
        : visibleItems
              .map(
                (value) => CompactItemModel(
                  label: value,
                  tooltip: value,
                  rewardCardColor: _rewardCardColor(value),
                ),
              )
              .toList();
    final displayLabel = visibleItems.isEmpty ? widget.emptyText : '';
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabel = visibleItems.isEmpty || constraints.maxWidth >= 190;

          return Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 6),
              ],
              if (showLabel && displayLabel.isNotEmpty) ...[
                Text(
                  displayLabel,
                  style: TextStyle(
                    color: widget.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: displayItems.isEmpty
                    ? const SizedBox.shrink()
                    : Scrollbar(
                        controller: _scrollController,
                        interactive: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: Row(
                            children: [
                              ...displayItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      final rule =
                                          TokenCatalogRepository.byLabel(
                                            _compactTokenBaseLabel(
                                              item.tooltip,
                                            ),
                                          );
                                      if (rule != null) {
                                        showTokenDetails(
                                          context,
                                          rule,
                                          getCount: widget.onTokensChanged != null ? () => widget.items.where((t) => t == rule.label).length : null,
                                          onMinus: widget.onTokensChanged != null ? () {
                                            widget.items.remove(rule.label);
                                            widget.onTokensChanged!();
                                          } : null,
                                          onPlus: widget.onTokensChanged != null ? () {
                                            widget.items.add(rule.label);
                                            widget.onTokensChanged!();
                                          } : null,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(item.tooltip)),
                                        );
                                      }
                                    },
                                    child: Tooltip(
                                      message: item.tooltip,
                                      child: _CompactItemVisual(
                                        item: item,
                                        color: widget.accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              ?widget.trailing,
            ],
          );
        },
      ),
    );
  }
}

class _CompactItemVisual extends StatelessWidget {
  const _CompactItemVisual({required this.item, required this.color});

  static final RegExp _healthRewardPattern = RegExp(r'^\+(\d+) HP$');
  static final RegExp _cpRewardPattern = RegExp(r'^\+(\d+) CP$');

  final CompactItemModel item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final healthMatch = _healthRewardPattern.firstMatch(item.label);
    if (healthMatch != null) {
      return _EffectImageBadge(
        value: '+${healthMatch.group(1)!}',
        asset: 'assets/illustration/soin.webp',
        textColor: Colors.white,
        size: 34,
        fontSize: 12,
      );
    }
    final cpMatch = _cpRewardPattern.firstMatch(item.label);
    if (cpMatch != null) {
      final value = int.tryParse(cpMatch.group(1)!);
      if (value != null) {
        return SizedBox(
          width: 36,
          height: 36,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _PcTriangleBadge(value: value),
          ),
        );
      }
    }
    final rewardCardColor = item.rewardCardColor;
    if (rewardCardColor != null) {
      return RewardCardBadge(color: rewardCardColor, tooltip: item.tooltip);
    }
    return CompactItemBadge(
      value: item.label,
      tooltip: item.tooltip,
      color: color,
    );
  }
}

class HeroTokenStrip extends StatelessWidget {
  const HeroTokenStrip({required this.tokens, required this.onEdit, super.key});

  final List<String> tokens;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return CompactItemStrip(
      label: 'Tokens',
      emptyText: 'Tokens',
      items: tokens,
      accent: heroAccent,
      background: Colors.black.withValues(alpha: 0.32),
      border: panelBorderGrey,
      trailing: IconButton(
        tooltip: 'Edit tokens',
        visualDensity: VisualDensity.compact,
        onPressed: onEdit,
        icon: const Icon(Icons.edit, size: 18),
      ),
    );
  }
}

class CompactItemModel {
  const CompactItemModel({
    required this.label,
    required this.tooltip,
    this.rewardCardColor,
  });

  final String label;
  final String tooltip;
  final Color? rewardCardColor;
}

class RewardCardBadge extends StatelessWidget {
  const RewardCardBadge({
    required this.color,
    required this.tooltip,
    super.key,
  });

  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final asset = _rewardCardAsset(tooltip);
    if (asset != null) {
      return Image.asset(asset, width: 34, height: 34, fit: BoxFit.contain);
    }
    return Container(
      width: 32,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.style, color: color, size: 20),
          const Positioned(
            right: 3,
            bottom: 2,
            child: Icon(Icons.add_circle, color: Colors.white, size: 10),
          ),
        ],
      ),
    );
  }
}

String? _rewardCardAsset(String value) {
  final normalized = value.toLowerCase();
  if (!normalized.contains('carte')) {
    return null;
  }
  if (normalized.contains('verte')) {
    return 'assets/token/carte-verte.webp';
  }
  if (normalized.contains('bleue')) {
    return 'assets/token/carte-bleue.webp';
  }
  if (normalized.contains('violette')) {
    return 'assets/token/carte-violette.webp';
  }
  if (normalized.contains('orange')) {
    return 'assets/token/carte-Orange.webp';
  }
  return null;
}

class CompactItemBadge extends StatelessWidget {
  const CompactItemBadge({
    required this.value,
    required this.tooltip,
    required this.color,
    super.key,
  });

  final String value;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rule = TokenCatalogRepository.byLabel(
      _compactTokenBaseLabel(tooltip),
    );
    if (rule != null) {
      final countMatch = RegExp(r' x(\d+)').firstMatch(tooltip);
      final count = countMatch?.group(1);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          StatusTokenImage(rule: rule, size: 30),
          if (count != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  count,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      constraints: BoxConstraints(minWidth: 30 + max(0, value.length - 2) * 8),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        value,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
    );
  }
}

String _compactTokenBaseLabel(String value) {
  return value.replaceFirst(RegExp(r' x\d+$'), '').trim();
}

List<CompactItemModel> _compactItemModels(List<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts.entries
      .map(
        (entry) => CompactItemModel(
          label: _compactItemCode(entry.key, entry.value),
          tooltip: entry.value == 1
              ? entry.key
              : '${entry.key} x${entry.value}',
          rewardCardColor: _rewardCardColor(entry.key),
        ),
      )
      .toList();
}

Color? _rewardCardColor(String value) {
  final normalized = value.toLowerCase();
  if (!normalized.contains('carte')) {
    return null;
  }
  if (normalized.contains('verte')) {
    return EnemyRank.green.color;
  }
  if (normalized.contains('bleue')) {
    return EnemyRank.blue.color;
  }
  if (normalized.contains('violette')) {
    return EnemyRank.violet.color;
  }
  if (normalized.contains('orange')) {
    return EnemyRank.orange.color;
  }
  return Colors.white;
}

String _compactItemCode(String value, [int count = 1]) {
  if (value == 'Première Frappe') {
    return count <= 1 ? '1ST' : '1STx$count';
  }
  final upper = value.toUpperCase();
  String base;
  if (upper.contains('HP')) {
    base = 'HP';
  } else if (upper.contains('CP')) {
    base = 'CP';
  } else {
    final letters = RegExp(
      r'[A-Z0-9]+',
    ).allMatches(upper).map((match) => match.group(0)!).join();
    if (letters.isEmpty) {
      base = '--';
    } else {
      base = letters.length <= 2 ? letters : letters.substring(0, 2);
    }
  }
  return count <= 1 ? base : '${base}x$count';
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
              HeroAvatar(hero: adventure.hero, size: 40),
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
                  final values = await showAlterationDialog(
                    context,
                    adventure.alterations,
                    duelTokens: TokenCatalogRepository.heroTokens(
                      adventure.hero,
                    ),
                  );
                  if (values != null) {
                    adventure.setAlterations(values);
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

class EnemyRulesPanel extends StatefulWidget {
  const EnemyRulesPanel({
    required this.enemy,
    required this.phase,
    required this.aiMode,
    required this.developerMode,
    required this.onDetails,
    required this.onAbandon,
    required this.onExport,
    required this.onRestartCombat,
    required this.showUndo,
    required this.onUndo,
    this.attackKey,
    this.defenseKey,
    super.key,
  });

  final EnemyNode enemy;
  final CombatPhase phase;
  final bool aiMode;
  final bool developerMode;
  final VoidCallback onDetails;
  final VoidCallback onAbandon;
  final VoidCallback onExport;
  final ValueChanged<EnemyRank> onRestartCombat;
  final bool showUndo;
  final VoidCallback onUndo;
  final Key? attackKey;
  final Key? defenseKey;

  @override
  State<EnemyRulesPanel> createState() => _EnemyRulesPanelState();
}

class _EnemyRulesPanelState extends State<EnemyRulesPanel> {
  bool _showAttack = false;
  bool _showDefense = false;
  bool _showPassive = false;

  /// Preview override for the Druid forms. null = use the real active form.
  /// Tapping a form chip flips this so the attack/defense text shows the other
  /// form for inspection, without changing the actual active form.
  bool? _druidFormPreview;

  EnemyNode get enemy => widget.enemy;

  bool get _isDruid => enemy.profileKey == 'vert-vert-014';
  bool get _druidRealBearForm => _isDruidBearForm(enemy);
  bool get _druidPreviewBearForm => _druidFormPreview ?? _druidRealBearForm;

  @override
  void initState() {
    super.initState();
    _showAttack = widget.phase == CombatPhase.minionAttack;
    _showDefense = widget.phase == CombatPhase.hero;
  }

  @override
  void didUpdateWidget(covariant EnemyRulesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) {
      if (widget.phase == CombatPhase.hero) {
        _showAttack = false;
        _showDefense = true;
      } else if (widget.phase == CombatPhase.minionAttack) {
        _showAttack = true;
        _showDefense = false;
      } else {
        _showAttack = false;
        _showDefense = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attackContent = _CollapsibleRulesLine(
      key: widget.attackKey,
      label: 'Attack',
      icon: Icons.gps_fixed,
      color: enemy.rank.color,
      trailing: AttackObjectiveInline(enemy: enemy),
      expanded: widget.aiMode ? _showAttack : true,
      onTap: () => setState(() {
        if (!widget.aiMode) {
          return;
        }
        _showAttack = !_showAttack;
        if (_showAttack) {
          _showDefense = false;
        }
      }),
      child: _isDruid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DruidFormSwitcher(
                  isPreviewBear: _druidPreviewBearForm,
                  isRealBear: _druidRealBearForm,
                  onSelectBear: () => setState(() {
                    _druidFormPreview = true;
                  }),
                  onSelectElk: () => setState(() {
                    _druidFormPreview = false;
                  }),
                ),
                MinionAttackSummary(
                  enemy: enemy,
                  previewBearForm: _druidPreviewBearForm,
                ),
              ],
            )
          : MinionAttackSummary(enemy: enemy),
    );
    final defenseContent = _CollapsibleRulesLine(
      key: widget.defenseKey,
      label: 'Defense',
      icon: Icons.shield,
      color: enemy.rank.color,
      trailing: DefenseDiceInline(count: enemy.defenseDice),
      expanded: widget.aiMode ? _showDefense : true,
      onTap: () => setState(() {
        if (!widget.aiMode) {
          return;
        }
        _showDefense = !_showDefense;
        if (_showDefense) {
          _showAttack = false;
        }
      }),
      child: _isDruid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DruidFormSwitcher(
                  isPreviewBear: _druidPreviewBearForm,
                  isRealBear: _druidRealBearForm,
                  onSelectBear: () => setState(() {
                    _druidFormPreview = true;
                  }),
                  onSelectElk: () => setState(() {
                    _druidFormPreview = false;
                  }),
                ),
                MinionDefenseSummary(
                  enemy: enemy,
                  previewBearForm: _druidPreviewBearForm,
                ),
              ],
            )
          : MinionDefenseSummary(enemy: enemy, previewBearForm: null),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RulesBackgroundBand(
          asset: 'assets/attack_background_feline_shadow.png',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _openEnemyCard(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 64,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: panelBorderGrey),
                        image: DecorationImage(
                          image: AssetImage(enemy.cardAsset),
                          fit: BoxFit.cover,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.developerMode)
                            Text(
                              enemy.profileKey ?? 'Unknown',
                              style: TextStyle(
                                color: enemy.rank.color.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            enemy.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: enemy.rank.color,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.showUndo) ...[
                    IconButton.filledTonal(
                      tooltip: 'Undo step',
                      onPressed: widget.onUndo,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        foregroundColor: const Color(0xff8f43ff),
                        side: const BorderSide(color: Color(0xff8f43ff)),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton.filledTonal(
                    tooltip: 'Combat settings',
                    onPressed: () => _openSettings(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.22),
                      foregroundColor: widget.developerMode
                          ? Colors.orangeAccent
                          : Colors.white,
                      side: BorderSide(
                        color: widget.developerMode
                            ? Colors.orangeAccent
                            : panelBorderGrey,
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              attackContent,
            ],
          ),
        ),
        _RulesBackgroundBand(
          asset: 'assets/defense_background_feline_shadow.png',
          child: defenseContent,
        ),
        if (_hasPassiveContent)
          _RulesBackgroundBand(
            asset: 'assets/passive_background_umbra.png',
            child: _CollapsibleRulesLine(
              label: 'Passive',
              icon: Icons.auto_awesome,
              color: enemy.rank.color,
              trailing: const SizedBox(width: 4),
              expanded: widget.aiMode ? _showPassive : true,
              onTap: () => setState(() {
                if (!widget.aiMode) {
                  return;
                }
                _showPassive = !_showPassive;
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (enemy.passiveDisplayRows.isNotEmpty)
                    ...enemy.passiveDisplayRows.map(
                      (row) => _ExtraRollDisplayRow(
                        row: row,
                        color: enemy.rank.color,
                      ),
                    )
                  else
                    for (final passive in _displayedPassives)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _PassiveNote(
                          child: _PassiveLine(passive: passive),
                        ),
                      ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool get _hasPassiveContent =>
      enemy.passiveDisplayRows.isNotEmpty || _displayedPassives.isNotEmpty;

  /// Passives rendered by the generic zone. Profiles that already have a
  /// dedicated hard-coded passive view inside [MinionAttackSummary] are
  /// excluded so the passive is not shown twice.
  List<MinionPassive> get _displayedPassives {
    const covered = <String>{
      'vert-vert-012', // Roc — dedicated view
      'vert-vert-014', // Druide Tenebreux — dedicated view
      'bleu-bleu-004', // Mage de Sang — dedicated view
      'viseer', // Viseer — dedicated view
    };
    final key = enemy.profileKey;
    if (key != null && covered.contains(key)) {
      return const [];
    }
    return enemy.passives;
  }

  void _openSettings(BuildContext context) {
    var restartRank = enemy.rank;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Combat settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SettingsActionTile(
                  icon: Icons.receipt_long,
                  label: 'Run log',
                  color: heroAccent,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onDetails();
                  },
                ),
                if (widget.developerMode)
                  _SettingsActionTile(
                    icon: Icons.ios_share,
                    label: 'Export log',
                    color: Colors.white,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onExport();
                    },
                  ),
                _SettingsActionTile(
                  icon: Icons.power_settings_new,
                  label: 'Quit / abandon run',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onAbandon();
                  },
                ),
                if (widget.developerMode && enemy.profileKey != 'naraxus') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Restart recipe combat',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 380;
                      final picker = _RecipeRankPicker(
                        selected: restartRank,
                        onChanged: (value) =>
                            setSheetState(() => restartRank = value),
                      );
                      final okButton = SizedBox(
                        height: 48,
                        width: compact ? double.infinity : 62,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onRestartCombat(restartRank);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            picker,
                            const SizedBox(height: 8),
                            okButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: picker),
                          const SizedBox(width: 10),
                          okButton,
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () async {
                          await AppSettings.instance.setDeveloperMode(
                            !AppSettings.instance.developerMode,
                          );
                          if (context.mounted) {
                            setSheetState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.developerMode
                                  ? Colors.orangeAccent
                                  : Colors.white24,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$appVersionLabel${widget.developerMode ? ' - Developer mode' : ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.developerMode
                                  ? Colors.orangeAccent
                                  : Colors.white70,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.developerMode) ...[
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        icon: const Icon(Icons.power_settings_new),
                        onPressed: () async {
                          await AppSettings.instance.setDeveloperMode(false);
                          Navigator.of(context).pop();
                          widget.onAbandon();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEnemyCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(child: Image.asset(enemy.cardAsset)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeRankPicker extends StatelessWidget {
  const _RecipeRankPicker({required this.selected, required this.onChanged});

  final EnemyRank selected;
  final ValueChanged<EnemyRank> onChanged;

  @override
  Widget build(BuildContext context) {
    const ranks = [
      (EnemyRank.green, 'Green'),
      (EnemyRank.blue, 'Blue'),
      (EnemyRank.violet, 'Purple'),
      (EnemyRank.orange, 'Orange'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xff1b1b1b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey),
      ),
      child: Row(
        children: [
          for (final rank in ranks)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _RecipeRankButton(
                  rank: rank.$1,
                  label: rank.$2,
                  selected: selected == rank.$1,
                  onTap: () => onChanged(rank.$1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecipeRankButton extends StatelessWidget {
  const _RecipeRankButton({
    required this.rank,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final EnemyRank rank;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.black : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? rank.color : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? rank.color : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: onTap,
    );
  }
}

class _RulesBackgroundBand extends StatelessWidget {
  const _RulesBackgroundBand({required this.asset, required this.child});

  final String asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xff202020),
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.22),
            BlendMode.darken,
          ),
        ),
        border: Border.all(color: panelBorderGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _CollapsibleRulesLine extends StatelessWidget {
  const _CollapsibleRulesLine({
    required this.label,
    required this.icon,
    required this.color,
    required this.trailing,
    required this.expanded,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Widget trailing;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: expanded
            ? Colors.black.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Flexible(child: trailing),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Form selector shown for the Druid minion (vert-vert-014). Tapping a chip
/// selects that form's preview so the corresponding attack/defense text becomes
/// visible for inspection, without changing the actual active form. The real
/// active form (determined by the upkeep roll) stays marked with a dot and is
/// the one actually applied in combat.
///
/// Rendered as a dedicated row above the attack/defense body (not inside the
/// collapsible header) so the chips never compete with the expand chevron for
/// horizontal space, and a tap on a chip cannot be swallowed by the header
/// InkWell that would otherwise fold the text away.
class _DruidFormSwitcher extends StatelessWidget {
  const _DruidFormSwitcher({
    required this.isPreviewBear,
    required this.isRealBear,
    required this.onSelectBear,
    required this.onSelectElk,
  });

  final bool isPreviewBear;
  final bool isRealBear;

  /// Selects the Bear form preview.
  final VoidCallback onSelectBear;

  /// Selects the Elk form preview.
  final VoidCallback onSelectElk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _formChip(
            label: 'Bear',
            isSelected: isPreviewBear,
            isReal: isRealBear,
            onTap: isPreviewBear ? null : onSelectBear,
          ),
          const SizedBox(width: 6),
          _formChip(
            label: 'Elk',
            isSelected: !isPreviewBear,
            isReal: !isRealBear,
            onTap: !isPreviewBear ? null : onSelectElk,
          ),
        ],
      ),
    );
  }

  Widget _formChip({
    required String label,
    required bool isSelected,
    required bool isReal,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff3d4a3e).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? heroAccent
                : panelBorderGrey.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReal)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: heroAccent,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xffcbd8cc),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MinionAttackSummary extends StatelessWidget {
  const MinionAttackSummary({
    required this.enemy,
    this.previewBearForm,
    super.key,
  });

  final EnemyNode enemy;

  /// When non-null, forces the Druid attack display to this form regardless of
  /// the active alterations. Only meaningful for the Druid (vert-vert-014).
  final bool? previewBearForm;

  bool get _druidBear =>
      previewBearForm ??
      (enemy.profileKey == 'vert-vert-014' ? _isDruidBearForm(enemy) : false);

  List<Widget> _buildSuiteResult(int length, EnemyNode enemy) {
    final effect = enemy.attackPlan.suiteEffects[length];
    final color = enemy.rank.color;
    
    if (effect != null) {
      final badges = <Widget>[];
      for (final token in effect.minionTokens) {
        badges.add(TokenBadge(label: token, color: color));
      }
      for (final token in effect.heroTokens) {
        badges.add(TokenBadge(label: token, color: Colors.deepOrangeAccent)); // Usually debuffs have a different color or just use enemy color, let's stick to enemy color for now. Wait, I'll just use color.
      }
      if (effect.stealCp > 0 && effect.label2 == null) {
        badges.add(CpStealBadge(value: effect.stealCp, color: color));
      }
      if (effect.stealHp > 0) {
        badges.add(LifeStealBadge(value: effect.stealHp, color: color));
      }
      if (effect.heal > 0) {
        badges.add(_HealBadge(value: effect.heal));
      }
      if (effect.damage > 0) {
        badges.add(DamageBadge(value: effect.damage, imparable: effect.undefendable));
      }
      if (effect.label != null && effect.label!.isNotEmpty) {
        badges.add(const SizedBox(width: 4));
        badges.add(InlineTokenText(effect.label!, color: color, style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc))));
      }
      final label2 = effect.label2;
      final label3 = effect.label3;
      if ((label2 != null && label2.isNotEmpty) || (label3 != null && label3.isNotEmpty)) {
        badges.add(const SizedBox(width: 4));
        if (label2 != null && label2.isNotEmpty && label3 != null && label3.isNotEmpty) {
          badges.add(Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              InlineTokenText(label2, color: color, style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc))),
              InlineTokenText(label3, color: color, style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc))),
            ],
          ));
        } else {
          final label = (label2 != null && label2.isNotEmpty) ? label2 : label3!;
          badges.add(InlineTokenText(label, color: color, style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc))));
        }
      }
      return badges;
    }
    
    // Legacy fallback
    final badges = <Widget>[];
    final Widget? legacyLeading = switch (enemy.profileKey) {
      'bleu-bleu-008' when length == 3 => TokenBadge(label: 'Entangle', color: color),
      'bleu-bleu-008' when length == 4 => TokenBadge(label: 'Silence', color: color),
      'fee' when length == 5 => CpStealBadge(value: 1, color: color),
      'elfe-du-chaos' when length == 5 => TokenBadge(label: 'Barbed Vine', color: color),
      'vert-vert-020' when length == 5 => TokenBadge(label: 'Knockdown', color: color),
      _ => null,
    };
    final legacyDamage = _suiteDamage(enemy, length);
    
    if (legacyLeading != null) {
      badges.add(legacyLeading);
      badges.add(const SizedBox(width: 5));
    }
    if (legacyDamage != null) {
      badges.add(DamageBadge(value: legacyDamage.value, imparable: legacyDamage.imparable));
    }
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final ruleRows = <DisplayRow>[];
    for (final rule in enemy.attackPlan.conditionalRules) {
      if (rule.displayRows.isNotEmpty) {
        ruleRows.addAll(rule.displayRows);
      }
    }

    final Widget mainBody = Builder(builder: (context) {
      if (enemy.attackPlan.displayRows.isNotEmpty) {
        return _DisplayRowsColumn(
          rows: enemy.attackPlan.displayRows,
          color: enemy.rank.color,
        );
      }
      if (enemy.profileKey == 'viseer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Upkeep support roll: 1 x ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              _CubeIcon(size: 28),
            ],
          ),
          const SizedBox(height: 6),
          _ResultLine(
            symbol: DieSymbol.yellow,
            children: [
              Text(
                'orange boss gains 1 CP and removes 1 negative token',
                style: TextStyle(color: enemy.rank.color),
              ),
            ],
          ),
          _ResultLine(
            symbol: DieSymbol.red,
            children: [
              TokenBadge(label: 'Main du roi', color: enemy.rank.color),
            ],
          ),
          const SizedBox(height: 6),
          const _PassiveNote(
            child: Text(
              'Viseer supports the orange boss. He has no battle phase and is immune to status effects.',
              style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
            ),
          ),
        ],
      );
    }
    if (enemy.profileKey == 'naraxus') {
      return _NaxarusAttackSummary(enemy: enemy);
    }
    if (enemy.profileKey == 'enchanteur-gobelin') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: SymbolGoal(white: 1, yellow: 2, red: 1),
            result: [DamageBadge(value: 4, imparable: true)],
          ),
          SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [_DiscardCardBadge(value: 1), Text('at random')],
            ),
          ),
        ],
      );
    }
    if (enemy.profileKey == 'vert-vert-011') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: SymbolGoal(yellow: 3),
            result: [DamageBadge(value: 4, imparable: true)],
          ),
          _AttackResultLine(
            goal: SymbolGoal(yellow: 4),
            result: [DamageBadge(value: 5, imparable: true)],
          ),
          _AttackResultLine(
            goal: SymbolGoal(yellow: 5),
            result: [DamageBadge(value: 6, imparable: true)],
          ),
        ],
      );
    }
    if (enemy.profileKey == 'oni-delirant') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'bleu-vert-022') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 1),
            result: const [DamageBadge(value: 4, imparable: false)],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 2),
            result: [
              TokenBadge(label: 'Parasite', color: enemy.rank.color),
              const DamageBadge(value: 5, imparable: false),
            ],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 2, red: 1),
            result: [
              TokenBadge(label: 'Poison', color: enemy.rank.color),
              const DamageBadge(value: 6, imparable: false),
            ],
          ),
        ],
      );
    }
    if (enemy.profileKey == 'bleu-vert-023') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 1, red: 1),
            result: [LifeStealBadge(value: 2, color: enemy.rank.color)],
          ),
        ],
      );
    }
    if (enemy.profileKey == 'bleu-bleu-001') {
      return const _AttackResultLine(
        goal: SymbolGoal(white: 2, yellow: 2, red: 1),
        result: [DamageBadge(value: 6, imparable: true)],
      );
    }
    if (enemy.profileKey == 'bleu-bleu-002') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttackResultLine(
            goal: SymbolGoal(yellow: 3),
            result: [DamageBadge(value: 4, imparable: true)],
          ),
          const _AttackResultLine(
            goal: SymbolGoal(yellow: 4),
            result: [DamageBadge(value: 5, imparable: true)],
          ),
          const _AttackResultLine(
            goal: SymbolGoal(yellow: 5),
            result: [DamageBadge(value: 6, imparable: true)],
          ),
          const InlineTokenText(
            'If the attack succeeds and 3 values are identical: Eboulissement.',
            color: Color(0xffcbd8cc),
            style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
          ),
        ],
      );
    }
    if (enemy.profileKey == 'bleu-bleu-003') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'bleu-bleu-004') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: const SymbolGoal(yellow: 3),
            result: [LifeStealBadge(value: 3, color: enemy.rank.color)],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(yellow: 4),
            result: [LifeStealBadge(value: 4, color: enemy.rank.color)],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(yellow: 5),
            result: [LifeStealBadge(value: 5, color: enemy.rank.color)],
          ),
          const SizedBox(height: 6),
          const _PassiveNote(
            child: InlineTokenText(
              'Passive: at upkeep, gains 1 Chaos. At 3 Chaos, spends them to steal 3 health.',
              color: Color(0xffcbd8cc),
              style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
            ),
          ),
        ],
      );
    }
    if (enemy.profileKey == 'vert-vert-012') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
          passiveNote: _PassiveNote(
            child: Row(
              children: [
                const Text(
                  'Passive: ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Text('if the offensive roll fails, '),
                DamageBadge(value: 1, imparable: true),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'vert-vert-013') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AttackResultLine(
            goal: SymbolGoal(white: 3),
            result: [DamageBadge(value: 6, imparable: false)],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 3, red: 1),
            result: [
              TokenBadge(label: 'Poison', color: enemy.rank.color),
              const DamageBadge(value: 6, imparable: false),
            ],
          ),
        ],
      );
    }
    if (enemy.profileKey == 'vert-vert-014') {
      final bear = _druidBear;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: const SymbolGoal(yellow: 3),
            result: [
              TokenBadge(
                label: bear ? 'Knockdown' : 'Barbed Vine',
                color: enemy.rank.color,
              ),
              const DamageBadge(value: 6, imparable: false),
            ],
          ),
          const SizedBox(height: 6),
          const _PassiveNote(
            child: Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Passive: at each Druid upkeep, roll 1',
                  style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
                ),
                _CubeIcon(size: 18),
                Text(
                  '. On 1-3: Bear Form. On 4-6: Elk Form.',
                  style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (enemy.profileKey == 'vert-vert-015') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
          directDamage: const _AttackDamage(5, imparable: true),
          directUndefendable: true,
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'vert-vert-017') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'vert-vert-021') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'bleu-bleu-023') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'bleu-bleu-020' ||
        enemy.profileKey == 'bleu-bleu-009' ||
        enemy.profileKey == 'bleu-bleu-007' ||
        enemy.profileKey == 'bleu-bleu-006') {
      final goal = _extraRollGoalFor(enemy);
      final extraRoll = _extraRollFor(enemy);
      if (goal != null && extraRoll != null) {
        return _ExtraRollAttackSummary(
          enemy: enemy,
          goal: goal,
          extraRoll: extraRoll,
          color: enemy.rank.color,
          actionAlign: goal.effect?.align ?? 'left',
          directDamage: _extraRollDirectDamageFor(enemy),
          directUndefendable:
              _extraRollDirectDamageFor(enemy)?.imparable ?? false,
        );
      }
      return const SizedBox.shrink();
    }
    if (enemy.profileKey == 'vert-vert-018') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 1),
            result: [
              TokenBadge(label: 'Entangle', color: enemy.rank.color),
              const DamageBadge(value: 5, imparable: false),
            ],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 2),
            result: [
              TokenBadge(label: 'Entangle', color: enemy.rank.color),
              const DamageBadge(value: 6, imparable: false),
            ],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 2, red: 1),
            result: [
              TokenBadge(label: 'Entangle', color: enemy.rank.color),
              const DamageBadge(value: 7, imparable: false),
            ],
          ),
        ],
      );
    }
    if (enemy.profileKey == 'vert-vert-019') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttackResultLine(
            goal: SymbolGoal(red: 2),
            result: [
              _DiscardCardBadge(value: 1),
              DamageBadge(value: 4, imparable: true),
            ],
          ),
        ],
      );
    }

    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...enemy.attackPlan.goals.map((goal) {
              final effect = goal.effect;
              final align = effect?.align ?? 'left';
              final damage = _damageForSymbolGoal(enemy, goal);
              final result = <Widget>[];
              if (damage != null) {
                result.add(DamageBadge(value: damage.value, imparable: damage.imparable));
              }
              return _AttackResultLine(
                goal: goal,
                result: result,
                align: align,
              );
            }),
            ..._shortTokenHints(enemy),
          ],
        );
      case MinionAttackStyle.suite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SuiteLine(
              label: 'Micro',
              length: 3,
              result: _buildSuiteResult(3, enemy),
            ),
            _SuiteLine(
              label: 'Small',
              length: 4,
              result: _buildSuiteResult(4, enemy),
            ),
            _SuiteLine(
              label: 'Large',
              length: 5,
              result: _buildSuiteResult(5, enemy),
            ),
            ..._shortTokenHints(enemy),
          ],
        );
      case MinionAttackStyle.none:
        return InlineTokenText(
          enemy.attacks.skip(1).join('\n'),
          color: enemy.rank.color,
          style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
        );
    }
    });

    if (ruleRows.isEmpty) {
      return mainBody;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainBody,
        const SizedBox(height: 8),
        _DisplayRowsColumn(
          rows: ruleRows,
          color: enemy.rank.color,
        ),
      ],
    );
  }

  List<Widget> _shortTokenHints(EnemyNode enemy) {
    final hints = <Widget>[];
    final text = enemy.attacks.join(' ').toLowerCase();
    if (text.contains('riposte')) {
      hints.add(
        _hintTokenLine(
          'If 4 identical symbols:',
          'Back Strike',
          enemy.rank.color,
        ),
      );
    }
    if (text.contains('silence')) {
      hints.add(
        _hintTokenLine('If 3 identical values:', 'Silence', enemy.rank.color),
      );
    }
    if (text.contains('hémorragie')) {
      hints.add(
        _hintTokenLine('If 3 identical values:', 'Bleed', enemy.rank.color),
      );
    }
    if (text.contains('ronces') && enemy.profileKey != 'elfe-du-chaos') {
      hints.add(
        _hintTokenLine('If large suite:', 'Barbed Vine', enemy.rank.color),
      );
    }
    if (text.contains('poison')) {
      hints.add(
        _hintTokenLine('If condition met:', 'Poison', enemy.rank.color),
      );
    }
    if (text.contains('parasite')) {
      hints.add(
        _hintTokenLine('If condition met:', 'Parasite', enemy.rank.color),
      );
    }
    if ((text.contains('a terre') || text.contains('à terre')) &&
        enemy.profileKey != 'vert-vert-020') {
      hints.add(
        _hintTokenLine('If condition met:', 'Knockdown', enemy.rank.color),
      );
    }
    if ((text.contains('enchevetrement') || text.contains('enchevêtrement')) &&
        enemy.profileKey != 'vert-vert-018') {
      hints.add(
        _hintTokenLine('If condition met:', 'Entangle', enemy.rank.color),
      );
    }
    return hints;
  }
}

Widget _hintTokenLine(String prefix, String tokenLabel, Color color) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            prefix,
            style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
          ),
          TokenBadge(label: tokenLabel, color: color),
        ],
      ),
    ),
  );
}

SymbolGoal _strongestSymbolGoal(EnemyNode enemy) {
  return enemy.attackPlan.goals.isEmpty
      ? const SymbolGoal()
      : enemy.attackPlan.goals.last;
}

class _NaxarusAttackSummary extends StatelessWidget {
  const _NaxarusAttackSummary({required this.enemy});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NaxarusAttackLine(
          value: 1,
          name: 'Swoop',
          detail: _naraxusAttackDetails[1]!,
          result: [
            TokenBadge(label: '-TOK', color: enemy.rank.color),
            const _HealBadge(value: 4),
            const DamageBadge(value: 3, imparable: true),
          ],
        ),
        _NaxarusAttackLine(
          value: 2,
          name: 'Ember Spark',
          detail: _naraxusAttackDetails[2]!,
          result: [
            _DiscardCardBadge(value: 3),
            DamageBadge(value: 8, imparable: false),
          ],
        ),
        _NaxarusAttackLine(
          value: 3,
          name: 'Gashing Bite',
          detail: _naraxusAttackDetails[3]!,
          result: [_FourDiceToTopTwoBadge()],
        ),
        _NaxarusAttackLine(
          value: 4,
          name: 'Hoarding',
          detail: _naraxusAttackDetails[4]!,
          result: [_DiePenaltyBadge(), DamageBadge(value: 9, imparable: false)],
        ),
        _NaxarusAttackLine(
          value: 5,
          name: 'Thundering Roar',
          detail: _naraxusAttackDetails[5]!,
          result: [
            _DiscardCardBadge(value: 1),
            DamageBadge(value: 8, imparable: true),
          ],
        ),
        _NaxarusAttackLine(
          value: 6,
          name: "Dragon's Might",
          detail: _naraxusAttackDetails[6]!,
          result: const [_DragonMightResultBadge()],
        ),
      ],
    );
  }
}

const Map<int, String> _naraxusAttackDetails = {
  1: 'Swoop\n\nRemove 1 random status effect token from Naxarus.\nHeal 4 HP.\nDeal 3 undefendable damage.',
  2: 'Ember Spark\n\nThe active hero must place the top 3 cards of their deck into their discard pile.\nDeal 8 damage.',
  3: 'Gashing Bite\n\nRoll 4 dice.\nThen deal damage equal to the total roll value of the two highest value dice that were rolled.',
  4: 'Hoarding\n\nTake one of the active hero dice. They cannot use this die until the end of their turn.\nDeal 9 damage.',
  5: 'Thundering Roar\n\nThe active hero must discard 1 card of their choice.\nDeal 8 undefendable damage.',
  6: "Dragon's Might\n\nDeal 10 damage and roll 1 die.\nOn 5-6, at the end of the roll phase, activate Swoop.",
};

class _NaxarusAttackLine extends StatelessWidget {
  const _NaxarusAttackLine({
    required this.value,
    required this.name,
    required this.detail,
    required this.result,
  });

  final int value;
  final String name;
  final String detail;
  final List<Widget> result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(width: 32, child: _NaxarusDieValueBadge(value: value)),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => _showDetails(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 5,
              runSpacing: 4,
              children: result,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class EnemyObjectivePreview extends StatelessWidget {
  const EnemyObjectivePreview({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Roll target',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: enemy.profileKey == 'naraxus'
                ? const DieValueBadge(value: 6, showValue: false)
                : switch (enemy.attackPlan.style) {
                    MinionAttackStyle.suite => const SuiteGoalView(length: 5),
                    MinionAttackStyle.symbols => SymbolGoalView(
                      goal: _strongestSymbolGoal(enemy),
                    ),
                    MinionAttackStyle.none => const Text('--'),
                  },
          ),
        ),
      ],
    );
  }
}

class AttackObjectiveInline extends StatelessWidget {
  const AttackObjectiveInline({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: enemy.profileKey == 'naraxus'
            ? const SizedBox.shrink()
            : switch (enemy.attackPlan.style) {
                MinionAttackStyle.suite => const SuiteGoalView(length: 5),
                MinionAttackStyle.symbols => SymbolGoalView(
                  goal: _strongestSymbolGoal(enemy),
                ),
                MinionAttackStyle.none => const Text('--'),
              },
      ),
    );
  }
}

class DefenseDiceInline extends StatelessWidget {
  const DefenseDiceInline({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(0, 6);
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (safeCount > 1)
              Text(
                '$safeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            if (safeCount > 1) const SizedBox(width: 4),
            if (safeCount > 0) const _CubeIcon(size: 30),
          ],
        ),
      ),
    );
  }
}

class SuiteGoalPip extends StatelessWidget {
  const SuiteGoalPip({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class RewardChestBadge extends StatelessWidget {
  const RewardChestBadge({
    required this.rank,
    required this.count,
    this.ranks = const [],
    super.key,
  });

  final EnemyRank rank;
  final int count;
  final List<EnemyRank> ranks;

  @override
  Widget build(BuildContext context) {
    if (ranks.isNotEmpty) {
      return Wrap(
        spacing: 4,
        children: [
          for (final rewardRank in ranks)
            RewardChestBadge(rank: rewardRank, count: 1),
        ],
      );
    }
    if (count > 1) {
      return Wrap(
        spacing: 4,
        children: [
          for (var i = 0; i < count; i++)
            RewardChestBadge(rank: rank, count: 1),
        ],
      );
    }
    return Container(
      width: 34,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: rank.color, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.inventory_2, color: rank.color, size: 24),
          if (count > 1)
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
        ],
      ),
    );
  }
}

class MinionDefenseSummary extends StatelessWidget {
  const MinionDefenseSummary({
    required this.enemy,
    this.previewBearForm,
    super.key,
  });

  final EnemyNode enemy;

  /// When non-null, forces the Druid defense display to this form regardless of
  /// the active alterations. Only meaningful for the Druid (vert-vert-014).
  final bool? previewBearForm;

  @override
  Widget build(BuildContext context) {
    if (enemy.defenseDisplayRows.isNotEmpty) {
      return _DisplayRowsColumn(
        rows: enemy.defenseDisplayRows,
        color: enemy.rank.color,
      );
    }
    if (enemy.profileKey == 'naraxus') {
      return const _NaxarusDefenseGrid();
    }
    final lines = _defenseEffectLines(enemy, previewBearForm: previewBearForm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.isEmpty
          ? [
              Text(
                _compactDefenseText(enemy.defense),
                style: const TextStyle(height: 1.25),
              ),
            ]
          : lines,
    );
  }
}

class _NaxarusDefenseGrid extends StatelessWidget {
  const _NaxarusDefenseGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Expanded(child: _NaxarusDefenseCell(value: 1, prevention: 1)),
        SizedBox(width: 8),
        Expanded(flex: 2, child: _NaxarusDefenseRange()),
        SizedBox(width: 8),
        Expanded(child: _NaxarusDefenseCell(value: 6, prevention: 5)),
      ],
    );
  }
}

class _NaxarusDefenseRange extends StatelessWidget {
  const _NaxarusDefenseRange();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _NaxarusDieValueBadge(value: 2),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text('-', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        _NaxarusDieValueBadge(value: 5),
        SizedBox(width: 6),
        PreventBadge(value: 3),
      ],
    );
  }
}

class _NaxarusDefenseCell extends StatelessWidget {
  const _NaxarusDefenseCell({required this.value, required this.prevention});

  final int value;
  final int prevention;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NaxarusDieValueBadge(value: value),
        const SizedBox(width: 6),
        PreventBadge(value: prevention),
      ],
    );
  }
}

List<Widget> _defenseEffectLines(EnemyNode enemy, {bool? previewBearForm}) {
  final text = enemy.defense.toLowerCase();
  final lines = <Widget>[];

  void symbol(SymbolGoal goal, List<Widget> result, {bool repeat = false}) {
    lines.add(
      _DefenseEffectLine(
        left: repeat
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _MultiplierBadge(),
                  const SizedBox(width: 4),
                  Flexible(child: SymbolGoalView(goal: goal)),
                ],
              )
            : SymbolGoalView(goal: goal),
        right: result,
      ),
    );
  }

  void dieValueLine(int dieValue, List<Widget> result) {
    lines.add(
      _DefenseEffectLine(
        left: DieValueBadge(value: dieValue),
        right: result,
      ),
    );
  }

  void dieValueGroupLine(List<int> dieValues, List<Widget> result) {
    lines.add(
      _DefenseEffectLine(
        left: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < dieValues.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              DieValueBadge(value: dieValues[i]),
            ],
          ],
        ),
        right: result,
      ),
    );
  }

  switch (enemy.profileKey) {
    case 'naraxus':
      dieValueLine(1, const [PreventBadge(value: 1)]);
      for (final dieValue in [2, 3, 4, 5]) {
        dieValueLine(dieValue, const [PreventBadge(value: 3)]);
      }
      dieValueLine(6, const [PreventBadge(value: 5)]);
      return lines;
    case 'fee':
      symbol(const SymbolGoal(yellow: 2), const [PreventBadge(value: 3)]);
      return lines;
    case 'ronin-vagabond':
      dieValueGroupLine([1, 2], const [DamageBadge(value: 1, imparable: true)]);
      dieValueGroupLine([3, 4], const [DamageBadge(value: 2, imparable: true)]);
      dieValueGroupLine([5, 6], const [DamageBadge(value: 3, imparable: true)]);
      return lines;
    case 'enchanteur-gobelin':
      symbol(const SymbolGoal(yellow: 1), const [
        DamageBadge(value: 1, imparable: true),
      ]);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'Poison', color: enemy.rank.color),
      ]);
      return lines;
    case 'archer-de-lombre':
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 3)]);
      return lines;
    case 'ombre-feline':
      symbol(const SymbolGoal(white: 1), [
        TokenBadge(label: 'Bleed', color: enemy.rank.color),
      ]);
      return lines;
    case 'epeiste-egare':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 1, imparable: true),
      ], repeat: true);
      symbol(const SymbolGoal(red: 1), const [
        DamageBadge(value: 1, imparable: true),
      ], repeat: true);
      symbol(const SymbolGoal(yellow: 1), const [
        PreventBadge(value: 1),
      ], repeat: true);
      return lines;
    case 'elfe-du-chaos':
      symbol(const SymbolGoal(yellow: 2), const [_HalfPreventBadge()]);
      return lines;
    case 'oni-delirant':
      symbol(const SymbolGoal(yellow: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
      ], repeat: true);
      return lines;
    case 'vert-vert-011':
      symbol(const SymbolGoal(yellow: 1), const [_HalfPreventBadge()]);
      return lines;
    case 'vert-vert-012':
    case 'vert-vert-016':
      symbol(const SymbolGoal(yellow: 1), const [
        PreventBadge(value: 1),
      ], repeat: true);
      return lines;
    case 'vert-vert-013':
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'Poison', color: enemy.rank.color),
      ]);
      return lines;
    case 'vert-vert-014':
      final druidBear = previewBearForm ?? _isDruidBearForm(enemy);
      if (druidBear) {
        symbol(const SymbolGoal(yellow: 1), const [
          DamageBadge(value: 1, imparable: true),
        ], repeat: true);
        symbol(const SymbolGoal(red: 1), const [
          DamageBadge(value: 2, imparable: true),
        ], repeat: true);
      } else {
        symbol(const SymbolGoal(yellow: 1), const [
          PreventBadge(value: 1),
        ], repeat: true);
        symbol(const SymbolGoal(red: 1), const [
          PreventBadge(value: 2),
        ], repeat: true);
      }
      return lines;
    case 'vert-vert-015':
      symbol(const SymbolGoal(red: 1), const [
        Text('return half incoming damage', textAlign: TextAlign.right),
      ]);
      return lines;
    case 'vert-vert-017':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 2, imparable: true),
      ]);
      return lines;
    case 'vert-vert-018':
      symbol(const SymbolGoal(yellow: 1), [
        TokenBadge(label: 'Knockdown', color: enemy.rank.color),
      ]);
      symbol(const SymbolGoal(red: 1), const [PreventBadge(value: 2)]);
      return lines;
    case 'vert-vert-019':
      symbol(const SymbolGoal(red: 1), const [PreventBadge(value: 3)]);
      return lines;
    case 'vert-vert-020':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 1, imparable: true),
      ]);
      symbol(const SymbolGoal(yellow: 1), const [
        PreventBadge(value: 1),
      ], repeat: true);
      symbol(const SymbolGoal(red: 1), const [
        PreventBadge(value: 1),
      ], repeat: true);
      return lines;
    case 'vert-vert-021':
      symbol(const SymbolGoal(yellow: 1), [
        TokenBadge(label: 'Chaos', color: enemy.rank.color),
      ], repeat: true);
      lines.add(
        const _DefenseEffectLine(
          left: Text(
            'After roll',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          right: [
            Text('inflict'),
            DamageBadge(value: 1, imparable: true),
            Text('x nb Chaos'),
          ],
        ),
      );
      return lines;
    case 'rat-de-la-rue':
      symbol(const SymbolGoal(yellow: 2), [
        Text(
          'steal 1 CP',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: enemy.rank.color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ]);
      symbol(const SymbolGoal(red: 2), const [
        Text('ignore all damage', textAlign: TextAlign.right),
      ]);
      return lines;
    case 'bleu-vert-022':
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 2)]);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'Parasite', color: enemy.rank.color),
      ]);
      return lines;
    case 'bleu-vert-023':
      symbol(const SymbolGoal(red: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
      ]);
      return lines;
    case 'bleu-bleu-001':
      symbol(const SymbolGoal(yellow: 1), const [
        PreventBadge(value: 1),
      ], repeat: true);
      return lines;
    case 'bleu-bleu-002':
      symbol(const SymbolGoal(yellow: 2), const [PreventBadge(value: 4)]);
      return lines;
    case 'bleu-bleu-003':
      symbol(const SymbolGoal(yellow: 1), [
        TokenBadge(label: 'Chaos', color: enemy.rank.color),
        const DamageBadge(value: 1, imparable: true),
        const Text('per Chaos'),
      ], repeat: true);
      return lines;
    case 'bleu-bleu-004':
      symbol(const SymbolGoal(yellow: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
      ], repeat: true);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'Chaos', color: enemy.rank.color),
      ]);
      return lines;
    case 'viseer':
      symbol(const SymbolGoal(red: 1), const [
        Text('Activate passive ability', textAlign: TextAlign.right),
        SizedBox(width: 4),
        Text('1 x', style: TextStyle(fontWeight: FontWeight.w900)),
        _CubeIcon(size: 24),
      ]);
      return lines;
  }

  final preventMatch = RegExp(
    r'previent ([0-9]+)|prevent ([0-9]+)',
  ).firstMatch(text);
  final damageMatch = RegExp(
    r'inflige ([0-9]+)|deal ([0-9]+)',
  ).firstMatch(text);
  final number =
      preventMatch?.group(1) ??
      preventMatch?.group(2) ??
      damageMatch?.group(1) ??
      damageMatch?.group(2);
  final value = int.tryParse(number ?? '');
  if (text.contains('jaune') || text.contains('yellow')) {
    symbol(
      SymbolGoal(
        yellow: text.contains('2 yellow') || text.contains('2 jaunes') ? 2 : 1,
      ),
      [
        if (value != null && preventMatch != null)
          PreventBadge(value: value)
        else if (value != null)
          DamageBadge(value: value, imparable: false)
        else
          Text(_compactDefenseText(enemy.defense)),
      ],
    );
  } else if (text.contains('rouge') || text.contains('red')) {
    symbol(const SymbolGoal(red: 1), [
      if (value != null && preventMatch != null)
        PreventBadge(value: value)
      else if (value != null)
        DamageBadge(value: value, imparable: false)
      else
        Text(_compactDefenseText(enemy.defense)),
    ]);
  }
  return lines;
}

class _DefenseEffectLine extends StatelessWidget {
  const _DefenseEffectLine({required this.left, required this.right});

  final Widget left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(width: 116, child: left),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: right,
            ),
          ),
        ],
      ),
    );
  }
}

class CombatBottomDock extends StatelessWidget {
  const CombatBottomDock({
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.primaryEnemy,
    this.secondaryEnemy,
    required this.upkeepApplied,
    required this.heroUpkeepApplied,
    required this.canAdvancePhase,
    required this.onPhaseChanged,
    required this.onNext,
    required this.onApplyUpkeep,
    required this.onApplyHeroUpkeep,
    super.key,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final EnemyNode primaryEnemy;
  final EnemyNode? secondaryEnemy;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;
  final bool canAdvancePhase;
  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xf2121212),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TurnPhasePanel(
        phase: phase,
        adventure: adventure,
        enemy: enemy,
        primaryEnemy: primaryEnemy,
        secondaryEnemy: secondaryEnemy,
        upkeepApplied: upkeepApplied,
        heroUpkeepApplied: heroUpkeepApplied,
        canAdvance: canAdvancePhase,
        onPhaseChanged: onPhaseChanged,
        onNext: onNext,
        onApplyUpkeep: onApplyUpkeep,
        onApplyHeroUpkeep: onApplyHeroUpkeep,
      ),
    );
  }
}

class CombatAiChatDock extends StatelessWidget {
  const CombatAiChatDock({
    required this.aiMode,
    required this.aiMessage,
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.primaryEnemy,
    this.secondaryEnemy,
    required this.canSwitchTarget,
    required this.onSelectTarget,
    required this.returnDamage,
    required this.returnDamageUndefendable,
    required this.lifeSteal,
    required this.enemyHeal,
    required this.cpSteal,
    required this.heroTokens,
    required this.minionTokens,
    required this.notes,
    required this.showResolution,
    required this.attackValue,
    required this.defenseValue,
    required this.onAttackChanged,
    required this.onDefenseChanged,
    required this.onApply,
    required this.onFinish,
    required this.onChanged,
    super.key,
  });

  final bool aiMode;
  final String aiMessage;
  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final EnemyNode primaryEnemy;
  final EnemyNode? secondaryEnemy;
  final bool canSwitchTarget;
  final ValueChanged<EnemyNode> onSelectTarget;
  final int returnDamage;
  final bool returnDamageUndefendable;
  final int lifeSteal;
  final int enemyHeal;
  final int cpSteal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final List<String> notes;
  final bool showResolution;
  final int attackValue;
  final int defenseValue;
  final ValueChanged<int> onAttackChanged;
  final ValueChanged<int> onDefenseChanged;
  final VoidCallback onApply;
  final VoidCallback? onFinish;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (!aiMode && !showResolution && onFinish == null) {
      return const SizedBox.shrink();
    }
    final chatAccent =
        phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
        ? heroAccent
        : enemy.rank.color;
    final enemyCpInfinity =
        enemy.profileKey == 'naraxus' || enemy.profileKey == 'viseer';
    final tokenText = [
      if (heroTokens.isNotEmpty) 'Hero: ${heroTokens.join(', ')}',
      if (minionTokens.isNotEmpty) 'Minion: ${minionTokens.join(', ')}',
      if (returnDamage > 0)
        returnDamageUndefendable
            ? 'Returns $returnDamage undefendable damage'
            : 'Returns $returnDamage damage',
      if (lifeSteal > 0) 'Steals $lifeSteal health',
      if (enemyHeal > 0 && !enemyCpInfinity) 'Enemy heals: $enemyHeal',
      if (cpSteal > 0) 'CP steal: $cpSteal',
      if (enemy.profileKey != 'naraxus') ...notes,
    ];
    final isHeroBattle = phase == CombatPhase.hero;
    final attackColor = isHeroBattle ? heroAccent : enemy.rank.color;
    final defenseColor = isHeroBattle ? enemy.rank.color : heroAccent;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xf2121212),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aiMode && canSwitchTarget && secondaryEnemy != null) ...[
            _DualEnemyTargetButtons(
              primaryEnemy: primaryEnemy,
              secondaryEnemy: secondaryEnemy!,
              activeEnemy: enemy,
              onSelect: onSelectTarget,
            ),
            const SizedBox(height: 8),
          ],
          if (aiMode)
            _AiChatWithHealth(
              message: _battleChatText(aiMessage, tokenText),
              accent: chatAccent,
              heroHp: adventure.health,
              heroCp: adventure.combatPoints,
              enemyHp: enemy.health,
              enemyCp: enemy.combatPoints,
              enemyCpInfinity: enemyCpInfinity,
              enemyColor: enemy.rank.color,
              heroName: adventure.hero.label,
              enemyName: enemy.label,
              portraitAsset:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.asset
                  : enemy.previewAsset,
              portraitAlignment:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? _topCropAlignment(adventure.hero.imageAlignment)
                  : enemy.profileKey == 'naraxus'
                  ? Alignment.topCenter
                  : _topCropAlignment(Alignment.centerLeft),
              portraitScale:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.imageScale
                  : 1,
              portraitFit: BoxFit.cover,
              showPortraitVitals:
                  phase == CombatPhase.hero ||
                  phase == CombatPhase.minionAttack,
              showHealthControls: false,
              onHeroHpSaved: (value) {
                adventure.setHeroHealth(value);
                onChanged();
              },
              onHeroCpSaved: (value) {
                adventure.setHeroPc(value);
                onChanged();
              },
              onEnemyHpSaved: (value) {
                enemy.health = value.clamp(0, 99);
                onChanged();
              },
              onEnemyCpSaved: (value) {
                enemy.combatPoints = value.clamp(0, 99);
                onChanged();
              },
            ),
          if (showResolution) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BattleCounter(
                    label: 'ATK',
                    value: attackValue,
                    color: attackColor,
                    onChanged: onAttackChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BattleCounter(
                    label: 'DEF',
                    value: defenseValue,
                    color: defenseColor,
                    onChanged: onDefenseChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 52,
                  child: FilledButton(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onFinish != null) ...[
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 210,
                child: ImageActionButton(
                  label: 'Finish',
                  icon: Icons.flag,
                  onPressed: onFinish!,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _battleChatText(String aiMessage, List<String> effects) {
  final lines = [
    if (aiMessage.trim().isNotEmpty) aiMessage.trim(),
    if (effects.isNotEmpty) effects.join('\n'),
  ];
  return lines.isEmpty ? 'Manual battle resolution.' : lines.join('\n');
}

class _DualEnemyTargetButtons extends StatelessWidget {
  const _DualEnemyTargetButtons({
    required this.primaryEnemy,
    required this.secondaryEnemy,
    required this.activeEnemy,
    required this.onSelect,
  });

  final EnemyNode primaryEnemy;
  final EnemyNode secondaryEnemy;
  final EnemyNode activeEnemy;
  final ValueChanged<EnemyNode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _targetButton(secondaryEnemy)),
          const SizedBox(width: 8),
          Expanded(child: _targetButton(primaryEnemy)),
        ],
      ),
    );
  }

  Widget _targetButton(EnemyNode target) {
    final selected = target.id == activeEnemy.id;
    final disabled = target.health <= 0;
    return FilledButton(
      onPressed: disabled ? null : () => onSelect(target),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? target.rank.color
            : Colors.black.withValues(alpha: 0.55),
        foregroundColor: selected ? Colors.black : Colors.white,
        disabledBackgroundColor: Colors.black26,
        disabledForegroundColor: Colors.white38,
        side: BorderSide(color: target.rank.color, width: selected ? 2 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${target.label}  ${target.health} HP',
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

enum _QuickVitalTarget { heroHp, heroCp, enemyHp, enemyCp }

class _AiChatWithHealth extends StatefulWidget {
  const _AiChatWithHealth({
    required this.message,
    required this.accent,
    required this.heroHp,
    required this.heroCp,
    required this.enemyHp,
    required this.enemyCp,
    required this.enemyCpInfinity,
    required this.enemyColor,
    required this.heroName,
    required this.enemyName,
    required this.portraitAsset,
    required this.portraitAlignment,
    this.portraitScale = 1,
    this.portraitFit = BoxFit.cover,
    this.showPortraitVitals = true,
    this.showHealthControls = true,
    required this.onHeroHpSaved,
    required this.onHeroCpSaved,
    required this.onEnemyHpSaved,
    required this.onEnemyCpSaved,
  });

  final String message;
  final Color accent;
  final int heroHp;
  final int heroCp;
  final int enemyHp;
  final int enemyCp;
  final bool enemyCpInfinity;
  final Color enemyColor;
  final String heroName;
  final String enemyName;
  final String portraitAsset;
  final Alignment portraitAlignment;
  final double portraitScale;
  final BoxFit portraitFit;
  final bool showPortraitVitals;
  final bool showHealthControls;
  final ValueChanged<int> onHeroHpSaved;
  final ValueChanged<int> onHeroCpSaved;
  final ValueChanged<int> onEnemyHpSaved;
  final ValueChanged<int> onEnemyCpSaved;

  @override
  State<_AiChatWithHealth> createState() => _AiChatWithHealthState();
}

class _AiChatWithHealthState extends State<_AiChatWithHealth> {
  _QuickVitalTarget? _target;
  late int _draftValue;

  @override
  void didUpdateWidget(covariant _AiChatWithHealth oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _target;
    if (target != null) {
      final current = _valueFor(target);
      if (_draftValue != current) {
        _draftValue = current;
      }
    }
  }

  int _valueFor(_QuickVitalTarget target) {
    return switch (target) {
      _QuickVitalTarget.heroHp => widget.heroHp,
      _QuickVitalTarget.heroCp => widget.heroCp,
      _QuickVitalTarget.enemyHp => widget.enemyHp,
      _QuickVitalTarget.enemyCp => widget.enemyCp,
    };
  }

  bool _isHpTarget(_QuickVitalTarget target) {
    return target == _QuickVitalTarget.heroHp ||
        target == _QuickVitalTarget.enemyHp;
  }

  bool _isHeroTarget(_QuickVitalTarget target) {
    return target == _QuickVitalTarget.heroHp ||
        target == _QuickVitalTarget.heroCp;
  }

  void _openEditor(_QuickVitalTarget target) {
    setState(() {
      _target = target;
      _draftValue = _valueFor(target);
    });
  }

  void _save() {
    final target = _target;
    if (target == null) {
      return;
    }
    final value = _draftValue.clamp(0, 99).toInt();
    if (target == _QuickVitalTarget.heroHp) {
      widget.onHeroHpSaved(value);
    } else if (target == _QuickVitalTarget.heroCp) {
      widget.onHeroCpSaved(value);
    } else if (target == _QuickVitalTarget.enemyHp) {
      widget.onEnemyHpSaved(value);
    } else {
      widget.onEnemyCpSaved(value);
    }
    setState(() => _target = null);
  }

  @override
  Widget build(BuildContext context) {
    const hpWidth = 56.0;
    const editorWidth = 78.0;
    final target = _target;
    final editorColor = target == null
        ? widget.accent
        : _isHeroTarget(target)
        ? heroAccent
        : widget.enemyColor;
    final chat = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35)),
      child: SingleChildScrollView(
        reverse: true,
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(height: 1.25, color: Colors.white),
            children: _chatSpans(
              widget.message,
              heroName: widget.heroName,
              enemyName: widget.enemyName,
              enemyColor: widget.enemyColor,
            ),
          ),
        ),
      ),
    );
    if (!widget.showHealthControls) {
      final lineCount = widget.message.trim().isEmpty
          ? 1
          : widget.message.trim().split('\n').length;
      final chatHeight = (56.0 + lineCount * 18.0).clamp(86.0, 210.0);
      final portraitIsHero = widget.accent == heroAccent;
      final portrait = SizedBox(
        width: 112,
        child: _AiChatPortraitVitals(
          asset: widget.portraitAsset,
          alignment: widget.portraitAlignment,
          scale: widget.portraitScale,
          fit: widget.portraitFit,
          hp: portraitIsHero ? widget.heroHp : widget.enemyHp,
          cp: portraitIsHero ? widget.heroCp : widget.enemyCp,
          cpInfinity: !portraitIsHero && widget.enemyCpInfinity,
          showHp: widget.showPortraitVitals,
          showCp:
              widget.showPortraitVitals &&
              (portraitIsHero || !widget.enemyCpInfinity),
          hpStyle: portraitIsHero ? _CombatHpStyle.hero : _CombatHpStyle.enemy,
          onHpTap: () => _openEditor(
            portraitIsHero
                ? _QuickVitalTarget.heroHp
                : _QuickVitalTarget.enemyHp,
          ),
          onCpTap: () => _openEditor(
            portraitIsHero
                ? _QuickVitalTarget.heroCp
                : _QuickVitalTarget.enemyCp,
          ),
        ),
      );
      final chatRow = SizedBox(
        height: chatHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.accent == heroAccent
              ? [Expanded(child: chat), portrait]
              : [portrait, Expanded(child: chat)],
        ),
      );
      if (target == null) {
        return chatRow;
      }
      final alignRight = _isHeroTarget(target);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: alignRight
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: _AiChatVitalEditor(
                label: _isHpTarget(target) ? 'HP' : 'CP',
                value: _draftValue,
                color: editorColor,
                onChanged: (delta) => setState(
                  () =>
                      _draftValue = (_draftValue + delta).clamp(0, 99).toInt(),
                ),
                onSave: _save,
              ),
            ),
          ),
          const SizedBox(height: 6),
          chatRow,
        ],
      );
    }
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: chat),
          if (_target != null) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: editorWidth,
              child: _HpQuickEditor(
                value: _draftValue,
                color: editorColor,
                onChanged: (delta) => setState(
                  () =>
                      _draftValue = (_draftValue + delta).clamp(0, 99).toInt(),
                ),
                onSave: _save,
              ),
            ),
          ],
          const SizedBox(width: 8),
          SizedBox(
            width: hpWidth,
            child: _HpSidePanel(
              heroHp: widget.heroHp,
              enemyHp: widget.enemyHp,
              enemyColor: widget.enemyColor,
              onHeroTap: () => _openEditor(_QuickVitalTarget.heroHp),
              onEnemyTap: () => _openEditor(_QuickVitalTarget.enemyHp),
            ),
          ),
        ],
      ),
    );
  }
}

class _HpSidePanel extends StatelessWidget {
  const _HpSidePanel({
    required this.heroHp,
    required this.enemyHp,
    required this.enemyColor,
    required this.onHeroTap,
    required this.onEnemyTap,
  });

  final int heroHp;
  final int enemyHp;
  final Color enemyColor;
  final VoidCallback onHeroTap;
  final VoidCallback onEnemyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _HpHeartButton(
            value: heroHp,
            color: heroAccent,
            tooltip: 'Edit hero HP',
            onTap: onHeroTap,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _HpHeartButton(
            value: enemyHp,
            color: enemyColor,
            tooltip: 'Edit enemy HP',
            onTap: onEnemyTap,
          ),
        ),
      ],
    );
  }
}

class _AiChatPortraitVitals extends StatelessWidget {
  const _AiChatPortraitVitals({
    required this.asset,
    required this.alignment,
    required this.scale,
    required this.fit,
    required this.hp,
    required this.cp,
    required this.cpInfinity,
    required this.showHp,
    required this.showCp,
    required this.hpStyle,
    required this.onHpTap,
    required this.onCpTap,
  });

  final String asset;
  final Alignment alignment;
  final double scale;
  final BoxFit fit;
  final int hp;
  final int cp;
  final bool cpInfinity;
  final bool showHp;
  final bool showCp;
  final _CombatHpStyle hpStyle;
  final VoidCallback onHpTap;
  final VoidCallback onCpTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Image.asset(asset, fit: fit, alignment: alignment),
          ),
        ),
        if (showHp)
          Positioned(
            top: 3,
            left: 3,
            child: InkWell(
              onTap: onHpTap,
              borderRadius: BorderRadius.circular(18),
              child: Transform.scale(
                scale: 0.58,
                alignment: Alignment.topLeft,
                child: _HpHeartBadge(value: hp, style: hpStyle),
              ),
            ),
          ),
        if (showCp)
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onCpTap,
              borderRadius: BorderRadius.circular(18),
              child: Transform.scale(
                scale: 0.52,
                alignment: Alignment.topRight,
                child: _PcTriangleBadge(value: cp, infinity: cpInfinity),
              ),
            ),
          ),
      ],
    );
  }
}

class _AiChatVitalEditor extends StatelessWidget {
  const _AiChatVitalEditor({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.onSave,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey, width: 1.4),
      ),
      child: Row(
        children: [
          _CompactRoundIconButton(
            icon: Icons.add,
            tooltip: 'Add $label',
            color: color,
            onPressed: () => onChanged(1),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value.clamp(0, 99).toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _CompactRoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove $label',
            color: color,
            onPressed: () => onChanged(-1),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            height: 34,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.check, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _HpHeartButton extends StatelessWidget {
  const _HpHeartButton({
    required this.value,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final int value;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.75)),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.favorite, color: color, size: 42),
                Text(
                  value.clamp(0, 99).toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
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

class _HpQuickEditor extends StatelessWidget {
  const _HpQuickEditor({
    required this.value,
    required this.color,
    required this.onChanged,
    required this.onSave,
  });

  final int value;
  final Color color;
  final ValueChanged<int> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CompactRoundIconButton(
            icon: Icons.add,
            tooltip: 'Add HP',
            color: color,
            onPressed: () => onChanged(1),
          ),
          Text(
            value.clamp(0, 99).toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          _CompactRoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove HP',
            color: color,
            onPressed: () => onChanged(-1),
          ),
          SizedBox(
            height: 28,
            width: 54,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.check, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRoundIconButton extends StatelessWidget {
  const _CompactRoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

List<InlineSpan> _chatSpans(
  String value, {
  required String heroName,
  required String enemyName,
  required Color enemyColor,
}) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(
    '(${RegExp.escape(heroName)}|${RegExp.escape(enemyName)}|\\{[a-zA-Z]+:[^}]+\\}|\\*\\*[^*]+\\*\\*|_[^_]+_|prevents? \\d+ damage|prevented \\d+ damage|prévents? \\d+ damage|prévient \\d+ damage|returns? \\d+ undefendable damage|returned \\d+ undefendable damage|deals? \\d+ undefendable damage|dealt \\d+ undefendable damage|inflicts? \\d+ undefendable damage|inflige \\d+ undefendable damage|returns? \\d+ damage|returned \\d+ damage|deals? \\d+ defendable damage|dealt \\d+ defendable damage|inflicts? \\d+ defendable damage|inflige \\d+ defendable damage|deals? \\d+ damage|dealt \\d+ damage|inflicts? \\d+ damage|inflige \\d+ damage|heals? \\d+ HP|healed \\d+ HP|\\d+ HP)',
    caseSensitive: false,
  );
  var index = 0;
  for (final match in pattern.allMatches(value)) {
    if (match.start > index) {
      spans.add(TextSpan(text: value.substring(index, match.start)));
    }
    final token = match.group(0)!;
    if (token.startsWith('**')) {
      spans.add(
        TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    } else {
      final visual = _chatVisualSpan(token, enemyColor: enemyColor);
      if (visual != null) {
        spans.add(visual);
      } else if (token.toLowerCase() == heroName.toLowerCase()) {
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              color: heroAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      } else if (token.toLowerCase() == enemyName.toLowerCase()) {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(color: enemyColor, fontWeight: FontWeight.w900),
          ),
        );
      } else if (token.startsWith('_') && token.endsWith('_')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }
    }
    index = match.end;
  }
  if (index < value.length) {
    spans.add(TextSpan(text: value.substring(index)));
  }
  return spans;
}

InlineSpan? _chatVisualSpan(String token, {required Color enemyColor}) {
  if (token.startsWith('_')) {
    return null;
  }
  final tagMatch = RegExp(r'^\{([a-zA-Z]+):([^}]+)\}$').firstMatch(token);
  if (tagMatch != null) {
    return _chatTagVisualSpan(
      tagMatch.group(1)!.toLowerCase(),
      tagMatch.group(2)!.trim(),
      enemyColor: enemyColor,
    );
  }
  final number = RegExp(r'\d+').firstMatch(token)?.group(0);
  if (number == null) {
    return null;
  }
  final lower = token.toLowerCase();
  if (lower.contains('prevent') || lower.contains('prévient')) {
    return TextSpan(
      children: [
        TextSpan(text: lower.contains('prévient') ? 'prévient ' : 'prevents '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineChatBadge(label: number, color: Colors.blueAccent),
        ),
      ],
    );
  }
  if (lower.contains('undefendable')) {
    final verb = lower.contains('inflige')
        ? 'inflige '
        : lower.contains('inflict')
        ? 'inflicts '
        : lower.contains('dealt')
        ? 'dealt '
        : lower.contains('return')
        ? 'returns '
        : 'deals ';
    return TextSpan(
      children: [
        TextSpan(text: verb),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineChatBadge(label: number, color: Colors.redAccent),
        ),
      ],
    );
  }
  if (lower.contains('steal') && lower.contains('health')) {
    return TextSpan(
      children: [
        const TextSpan(text: 'steals '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineChatBadge(label: number, color: Colors.greenAccent),
        ),
      ],
    );
  }
  if (lower.contains('damage') || lower.contains('dégât')) {
    final verb = lower.contains('inflige')
        ? 'inflige '
        : lower.contains('inflict')
        ? 'inflicts '
        : lower.contains('dealt')
        ? 'dealt '
        : lower.contains('return')
        ? 'returns '
        : 'deals ';
    return TextSpan(
      children: [
        TextSpan(text: verb),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineChatBadge(label: number, color: Colors.white),
        ),
      ],
    );
  }
  if (lower.contains('hp')) {
    if (!lower.contains('heal')) {
      return null;
    }
    final verb = lower.contains('heal')
        ? lower.contains('healed')
              ? 'healed '
              : 'heals '
        : '';
    return TextSpan(
      children: [
        if (verb.isNotEmpty) TextSpan(text: verb),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _InlineChatBadge(
            label: number,
            color: lower.contains('heal')
                ? Colors.greenAccent
                : Colors.redAccent,
          ),
        ),
      ],
    );
  }
  return null;
}

InlineSpan? _chatTagVisualSpan(
  String tag,
  String value, {
  required Color enemyColor,
}) {
  final normalized = value.toLowerCase().trim();
  if (tag == 'die' || tag == 'dice') {
    if (normalized == 'any' || normalized == 'd6') {
      return const WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: _CubeIcon(size: 24),
        ),
      );
    }
    final symbol = switch (normalized) {
      'white' || 'blanc' => DieSymbol.white,
      'orange' || 'yellow' || 'jaune' => DieSymbol.yellow,
      'red' || 'rouge' => DieSymbol.red,
      _ => null,
    };
    if (symbol == null) {
      return null;
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Transform.scale(
          scale: 0.72,
          child: DieSymbolMark(symbol: symbol),
        ),
      ),
    );
  }
  if (tag == 'token') {
    final rule = _tokenRuleFromTag(value);
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message: rule.label,
          child: TokenBadge(label: rule.label, color: enemyColor),
        ),
      ),
    );
  }
  final amount = int.tryParse(value);
  if (amount == null) {
    return null;
  }
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: switch (tag) {
        'damage' || 'dmg' => _InlineChatBadge(
          label: amount.toString(),
          color: Colors.white,
        ),
        'undef' || 'imparable' => _InlineChatBadge(
          label: amount.toString(),
          color: Colors.redAccent,
        ),
        'prevent' || 'block' => _InlineChatBadge(
          label: amount.toString(),
          color: Colors.blueAccent,
        ),
        'heal' => _InlineChatBadge(
          label: amount.toString(),
          color: Colors.greenAccent,
        ),
        _ => _InlineChatBadge(label: amount.toString(), color: Colors.white),
      },
    ),
  );
}

class _InlineChatBadge extends StatelessWidget {
  const _InlineChatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: _EffectImageBadge(
        value: label,
        asset: _effectAssetForColor(color),
        textColor: Colors.white,
        size: 25,
        fontSize: 10,
      ),
    );
  }
}

String _effectAssetForColor(Color color) {
  if (color == Colors.blueAccent) {
    return 'assets/illustration/bouclier.webp';
  }
  if (color == Colors.redAccent) {
    return 'assets/illustration/degat-imp.webp';
  }
  if (color == Colors.greenAccent) {
    return 'assets/illustration/soin.webp';
  }
  return 'assets/illustration/degat.webp';
}

class _BattleCounter extends StatelessWidget {
  const _BattleCounter({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CompactRoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            color: color,
            onPressed: () => onChanged(1),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _CompactRoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            color: color,
            onPressed: () => onChanged(-1),
          ),
        ],
      ),
    );
  }
}

class _HeroQuickVitalsLine extends StatefulWidget {
  const _HeroQuickVitalsLine({
    required this.adventure,
    required this.onChanged,
  });

  final AdventureState adventure;
  final VoidCallback onChanged;

  @override
  State<_HeroQuickVitalsLine> createState() => _HeroQuickVitalsLineState();
}

class _HeroQuickVitalsLineState extends State<_HeroQuickVitalsLine> {
  late int _hp = widget.adventure.health;
  late int _cp = widget.adventure.combatPoints;

  @override
  void didUpdateWidget(covariant _HeroQuickVitalsLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adventure.health != widget.adventure.health) {
      _hp = widget.adventure.health;
    }
    if (oldWidget.adventure.combatPoints != widget.adventure.combatPoints) {
      _cp = widget.adventure.combatPoints;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BattleCounter(
            label: 'HP',
            value: _hp,
            color: heroAccent,
            onChanged: (delta) =>
                setState(() => _hp = (_hp + delta).clamp(0, 99)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BattleCounter(
            label: 'CP',
            value: _cp,
            color: heroAccent,
            onChanged: (delta) =>
                setState(() => _cp = (_cp + delta).clamp(0, 99)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          height: 52,
          child: FilledButton(
            onPressed: () {
              widget.adventure.setHeroHealth(_hp);
              widget.adventure.setHeroPc(_cp);
              widget.onChanged();
            },
            style: FilledButton.styleFrom(
              backgroundColor: heroAccent,
              foregroundColor: Colors.black,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiceBackgroundBand extends StatelessWidget {
  const _DiceBackgroundBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xff202020),
        border: Border.all(color: panelBorderGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class MinionAiPanel extends StatelessWidget {
  const MinionAiPanel({
    required this.enemy,
    required this.phase,
    required this.dice,
    required this.adventure,
    required this.rollCount,
    required this.diceToRoll,
    required this.visibleDiceCount,
    required this.maxRolls,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.onRoll,
    required this.onTapDie,
    required this.onSelectFace,
    required this.onValidateEdit,
    required this.onToggleEdit,
    required this.onToggleRerollOne,
    super.key,
  });

  final EnemyNode enemy;
  final CombatPhase phase;
  final List<GameDie> dice;
  final AdventureState adventure;
  final int rollCount;
  final int diceToRoll;
  final int visibleDiceCount;
  final int maxRolls;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;

  @override
  Widget build(BuildContext context) {
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 5)).toList();
    final hasRollingDice = visibleDice.any((die) => !die.settled);
    if (!hasRollingDice) {
      visibleDice.sort(_compareDice);
    }
    final editingDie = editingDieId == null
        ? null
        : dice.firstWhere((die) => die.id == editingDieId);
    final isDefensePhase = phase == CombatPhase.hero;
    return _DiceBackgroundBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.casino, color: enemy.rank.color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              if (enemy.profileKey != 'naraxus') ...[
                Text(
                  '$rollCount/$maxRolls',
                  style: TextStyle(
                    color: enemy.rank.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (visibleDice.isNotEmpty || isDefensePhase) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final die in visibleDice)
                  DieTile(
                    die: die,
                    onTap: !die.settled
                        ? null
                        : editMode || rerollOneMode
                        ? () => onTapDie(die)
                        : null,
                    highlight:
                        die.settled && (die.reserved || editingDieId == die.id),
                    highlightColor: editingDieId == die.id
                        ? heroAccent
                        : enemy.rank.color,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (visibleDice.isNotEmpty || isDefensePhase) ...[
            _SolidRollButton(
              onPressed:
                  !hasRollingDice && rollCount < maxRolls && diceToRoll > 0
                  ? onRoll
                  : null,
              color: enemy.rank.color,
              child: Text(
                isDefensePhase
                    ? 'Roll defense'
                    : (rollCount == 0 ? 'Roll' : 'Reroll'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: heroAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: onToggleEdit,
                    icon: const Icon(Icons.tune),
                    label: Text(editMode ? 'Stop edit' : 'Edit a die'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: heroAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: onToggleRerollOne,
                    icon: const Icon(Icons.refresh),
                    label: Text(rerollOneMode ? 'Choose' : 'Reroll a die'),
                  ),
                ),
              ],
            ),
            if (editingDie != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Edit die ${editingDie.id + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  for (final face in [1, 2, 3, 4, 5, 6])
                    if (face != editingDie.value)
                      ActionChip(
                        label: Text(face.toString()),
                        onPressed: () => onSelectFace(editingDie, face),
                      ),
                  FilledButton(
                    onPressed: onValidateEdit,
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String _aiMessageFor(
  EnemyNode enemy,
  CombatPhase phase,
  List<GameDie> dice,
  int rollCount,
  AdventureState adventure,
  List<GameRecord> historyRecords,
  String lastBattleOutcome,
  String extraDiceOutcome,
  int heroAttackCount,
  int lastHeroAttack,
  int heroAttackTotal,
) {
  return switch (phase) {
    CombatPhase.intro => _introAiMessage(adventure, enemy, historyRecords),
    CombatPhase.heroUpkeep => _heroUpkeepAiMessage(
      adventure,
      enemy,
      historyRecords,
      lastBattleOutcome,
    ),
    CombatPhase.hero => _heroBattleAiMessage(
      enemy,
      adventure,
      historyRecords,
      heroAttackCount,
      lastHeroAttack,
      heroAttackTotal,
    ),
    CombatPhase.minionUpkeep => _minionUpkeepAiMessage(
      adventure,
      enemy,
      historyRecords,
      lastBattleOutcome,
      extraDiceOutcome,
    ),
    CombatPhase.minionAttack => _minionAttackAiMessage(
      enemy,
      dice,
      rollCount,
      adventure,
      extraDiceOutcome,
    ),
  };
}

String _introAiMessage(
  AdventureState adventure,
  EnemyNode enemy,
  List<GameRecord> historyRecords,
) {
  return [
    _openingAiLines(adventure, enemy, historyRecords),
    '_Press the flashing arrow to start the first upkeep phase._',
  ].join('\n');
}

String _combatIntroLine(AdventureState adventure, EnemyNode enemy) {
  return '**Battle: ${adventure.hero.label} vs ${enemy.label}.**';
}

String _openingAiLines(
  AdventureState adventure,
  EnemyNode enemy,
  List<GameRecord> historyRecords,
) {
  final lines = <String>[_combatIntroLine(adventure, enemy)];
  final runs =
      historyRecords
          .where(
            (record) =>
                record.hero == adventure.hero &&
                record.mode.difficulty == adventure.config.mode.difficulty,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  if (adventure.config.mode == SurvivalMode.naraxus) {
    if (runs.isEmpty) {
      lines.add(
        '_${adventure.hero.label} enters Naxarus mode for the first time. Can this hero defeat the dragon?_',
      );
    } else if (runs.length == 1) {
      final won = (runs.first.bossHealthRemaining ?? 1) <= 0;
      lines.add(
        won
            ? '_${adventure.hero.label} is challenging Naxarus for the second time. Can the dragon be defeated twice?_'
            : '_${adventure.hero.label} is challenging Naxarus for the second time. Can the dragon fall this time?_',
      );
    } else {
      final wins = runs
          .where((record) => (record.bossHealthRemaining ?? 1) <= 0)
          .length;
      final losses = runs.length - wins;
      final winRate = (wins / runs.length * 100).round();
      lines.add(
        '_${adventure.hero.label} has a $winRate% win rate in Naxarus mode: $wins win(s), $losses defeat(s). Can these stats improve?_',
      );
    }
    return lines.join('\n');
  }

  final encounter = adventure.defeatedEnemies.length + 1;
  if (runs.isEmpty) {
    if (encounter == 1 && enemy.rank == EnemyRank.green) {
      lines.add(
        '_${adventure.hero.label} starts Minion Rush for the first time. Can this hero beat every enemy on the path?_',
      );
    }
  } else if (runs.length == 1) {
    final last = runs.first;
    lines.add(
      '_In ${adventure.config.label}, ${adventure.hero.label} scored ${last.score} points in the last run and defeated ${last.enemiesDefeated} enemy/enemies. Can you do better this time?_',
    );
  } else {
    final averageScore =
        runs.fold<int>(0, (sum, record) => sum + record.score) / runs.length;
    final averageEnemies =
        runs.fold<int>(0, (sum, record) => sum + record.enemiesDefeated) /
        runs.length;
    lines.add(
      '_In ${adventure.config.label}, ${adventure.hero.label} averages ${averageScore.toStringAsFixed(1)} points and ${averageEnemies.toStringAsFixed(1)} defeated enemies. Can you improve the run?_',
    );
  }
  lines.add('This is the ${_ordinal(encounter)} Minion Rush encounter.');
  lines.add(
    '${enemy.label} starts with ${enemy.health} HP, ${enemy.combatPoints} CP and ${enemy.alterations.length} token(s).',
  );
  return lines.join('\n');
}

String _ordinal(int value) {
  if (value % 100 >= 11 && value % 100 <= 13) {
    return '${value}th';
  }
  return switch (value % 10) {
    1 => '${value}st',
    2 => '${value}nd',
    3 => '${value}rd',
    _ => '${value}th',
  };
}

String _heroUpkeepAiMessage(
  AdventureState adventure,
  EnemyNode enemy,
  List<GameRecord> historyRecords,
  String lastBattleOutcome,
) {
  final tokenSummary = _tokenUpkeepSummary(
    owner: adventure.hero.label,
    tokens: adventure.alterations,
    isHero: true,
  );
  final lines = <String>[
    if (lastBattleOutcome.isNotEmpty) lastBattleOutcome,
    '**Upkeep of ${adventure.hero.label}.**',
    '${adventure.hero.label} gains 1 CP and is now at ${adventure.combatPoints} CP.',
    if (tokenSummary.isNotEmpty) tokenSummary,
    if (!adventure.alterations.contains('Commotion'))
      '${adventure.hero.label} should draw 1 card before the battle phase.',
  ];
  return lines.join('\n');
}

String _minionUpkeepAiMessage(
  AdventureState adventure,
  EnemyNode enemy,
  List<GameRecord> historyRecords,
  String lastBattleOutcome,
  String extraDiceOutcome,
) {
  final tokenSummary = _tokenUpkeepSummary(
    owner: enemy.label,
    tokens: enemy.alterations,
    isHero: false,
  );
  final lines = <String>[
    if (lastBattleOutcome.isNotEmpty) lastBattleOutcome,
    '**Upkeep of ${enemy.label}.**',
    if (enemy.profileKey == 'vert-vert-014')
      extraDiceOutcome.isEmpty
          ? 'Druid passive: roll 1 {die:any} to discover the active form. The next phase is locked until this roll is done.'
          : extraDiceOutcome,
    if (enemy.profileKey != 'naraxus' && enemy.profileKey != 'viseer')
      '${enemy.label} gains 1 CP and is now at ${enemy.combatPoints} CP.',
    if (tokenSummary.isNotEmpty) tokenSummary,
  ];
  return lines.join('\n');
}

String _heroBattleAiMessage(
  EnemyNode enemy,
  AdventureState adventure,
  List<GameRecord> historyRecords,
  int heroAttackCount,
  int lastHeroAttack,
  int heroAttackTotal,
) {
  final intro = heroAttackCount == 0
      ? '_${adventure.hero.label} enters the fight. How much damage will the first attack deal?_'
      : heroAttackCount == 1
      ? 'The first attack dealt $lastHeroAttack damage. Can ${adventure.hero.label} do better?'
      : '${adventure.hero.label} averages ${(heroAttackTotal / heroAttackCount).toStringAsFixed(1)} damage per attack. Can this turn beat that?';
  return [
    '**Battle phase.**',
    intro,
    '${enemy.label} is waiting for the hero attack result.',
    'If the attack is defendable, roll ${enemy.label} defense.',
    if (adventure.alterations.contains('Silence'))
      'Silence is active: ${adventure.hero.label} cannot validate a suite this turn.',
  ].join('\n');
}

String _tokenUpkeepSummary({
  required String owner,
  required List<String> tokens,
  required bool isHero,
}) {
  if (tokens.isEmpty) {
    return '';
  }
  final counts = _tokenCounts(tokens);
  final lines = <String>[];
  var poisonDamage = 0;
  for (final entry in counts.entries) {
    final token = entry.key;
    final count = entry.value;
    final lower = token.toLowerCase();
    if (lower.contains('poison')) {
      poisonDamage += count;
      lines.add('$count Poison token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        '$owner will receive ${List.filled(count, '1 poison damage').join(' and ')}. Total: $count HP will be removed at the end of upkeep.',
      );
    } else if (lower.contains('hémorragie') || lower.contains('hemorragie')) {
      lines.add('$count Bleed token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        isHero
            ? '$owner must roll for Bleed during upkeep, then update HP and tokens.'
            : 'I have Bleed. I am ready to roll to see if the token stays; confirm with OK when this token is resolved.',
      );
    } else if (lower.contains('brûlure') || lower.contains('brulure')) {
      lines.add('$count Burn token${count > 1 ? 's' : ''} found on $owner.');
      lines.add('Resolve Burn damage before moving to battle.');
    }
  }
  if (lines.isEmpty) {
    return '';
  }
  if (poisonDamage > 0) {
    lines.add('The upkeep damage may defeat $owner if HP is too low.');
  }
  return lines.join('\n');
}

Map<String, int> _tokenCounts(List<String> tokens) {
  final counts = <String, int>{};
  for (final token in tokens) {
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return counts;
}

String _minionAttackAiMessage(
  EnemyNode enemy,
  List<GameDie> dice,
  int rollCount,
  AdventureState adventure,
  String extraDiceOutcome,
) {
  final rolled = dice.where((die) => die.value != null).toList();
  if (enemy.profileKey == 'naraxus') {
    return _naraxusAiMessage(enemy, rolled, adventure, extraDiceOutcome);
  }
  if (rollCount == 0 || rolled.isEmpty) {
    if (enemy.attackPlan.style == MinionAttackStyle.suite) {
      return '**Battle phase.**\n'
          'I use ${enemy.attacks.first}.\n'
          'First target: micro suite. If it succeeds, I will try to improve.';
    }
    return '**Battle phase.**\n'
        'I use ${enemy.attacks.first}.\n'
        'First target: the smallest valid symbol attack.';
  }

  final values = rolled.map((die) => die.value!).toList()..sort();
  final kept =
      rolled.where((die) => die.reserved).map((die) => die.value!).toList()
        ..sort();

  if (enemy.attackPlan.style == MinionAttackStyle.suite) {
    final decision = MinionDiceEngine.chooseSuiteHold(dice);
    final best = _bestSuiteLength(values);
    final rollLabel = _rollLabel(rollCount);
    if (best >= 5) {
      final damage = _suiteDamage(enemy, 5);
      return rollCount >= 3
          ? 'After my 3 attack rolls, large suite validated with ${_bestSuiteValues(values, 5).join('/')}.\n'
                '${_defenseInstruction(adventure, damage)}'
          : 'On my $rollLabel roll, large suite validated with ${_bestSuiteValues(values, 5).join('/')}.\n'
                'The resolution line is ready; I can still try to improve if one roll remains.';
    }
    if (best == 4) {
      final damage = _suiteDamage(enemy, 4);
      return rollCount >= 3
          ? 'After my 3 attack rolls, small suite validated with ${_bestSuiteValues(values, 4).join('/')}.\n'
                '${_defenseInstruction(adventure, damage)}'
          : 'On my $rollLabel roll, small suite validated with ${_bestSuiteValues(values, 4).join('/')}.\n'
                'I can hit, then try to improve if one roll remains.';
    }
    if (best == 3) {
      final damage = _suiteDamage(enemy, 3);
      return rollCount >= 3
          ? 'After my 3 attack rolls, micro suite validated with ${_bestSuiteValues(values, 3).join('/')}.\n'
                '${_defenseInstruction(adventure, damage)}'
          : 'On my $rollLabel roll, micro suite validated.\n'
                'I keep ${kept.join('/')} and can keep rolling to improve.';
    }
    return 'On my $rollLabel roll, I deal no damage yet.\n'
        '${decision.reason}\n'
        'Kept dice: ${kept.isEmpty ? 'nothing' : kept.join('/')}.';
  }

  final symbolDamage = _bestSymbolAttackDamage(enemy, dice);
  final rollLabel = _rollLabel(rollCount);
  if (rollCount >= 3) {
    return symbolDamage == null
        ? 'After my 3 attack rolls, no valid attack combination was made.'
        : 'After my 3 attack rolls, the attack is validated with ${_reservedDiceText(dice)}.\n'
              '${_defenseInstruction(adventure, symbolDamage)}';
  }
  return kept.isEmpty
      ? 'On my $rollLabel roll, I deal no damage yet.\nI reroll toward the first attack.'
      : 'On my $rollLabel roll, I keep ${kept.join('/')}.\nI try to improve the attack.';
}

String _defenseInstruction(AdventureState adventure, _AttackDamage? damage) {
  if (damage == null || damage.value <= 0) {
    return 'No damage is dealt.';
  }
  if (damage.imparable) {
    return 'No defense roll: this attack is undefendable. Defensive cards may still reduce the damage.';
  }
  return '${adventure.hero.label} should perform a defense roll.';
}

String _rollLabel(int rollCount) {
  return switch (rollCount) {
    1 => 'first',
    2 => 'second',
    3 => 'third and final',
    _ => '${rollCount}th',
  };
}

List<int> _bestSuiteValues(List<int> values, int length) {
  final unique = values.toSet();
  final suites = switch (length) {
    5 => const [
      [1, 2, 3, 4, 5],
      [2, 3, 4, 5, 6],
    ],
    4 => const [
      [1, 2, 3, 4],
      [2, 3, 4, 5],
      [3, 4, 5, 6],
    ],
    _ => const [
      [1, 2, 3],
      [2, 3, 4],
      [3, 4, 5],
      [4, 5, 6],
    ],
  };
  return suites.firstWhere(
    (suite) => suite.every(unique.contains),
    orElse: () => const [],
  );
}

String _reservedDiceText(List<GameDie> dice) {
  final values =
      dice
          .where((die) => die.reserved && die.value != null)
          .map((die) => die.value!)
          .toList()
        ..sort();
  return values.isEmpty ? 'none' : values.join('/');
}

String _naraxusAiMessage(
  EnemyNode enemy,
  List<GameDie> rolled,
  AdventureState adventure,
  String extraDiceOutcome,
) {
  if (rolled.isEmpty || rolled.first.value == null) {
    return '**Battle phase.**\n'
        'Naxarus battle phase.\n'
        'Roll 1 die to choose the dragon attack.\n'
        'The result will feed the sword counter.';
  }
  final value = rolled.first.value!;
  final result = switch (value) {
    1 =>
      'Naxarus rolled 1 on his attack die and performs Swoop.\n'
          'Swoop removes 1 random status token from Naxarus, heals 4 HP, then inflicts 3 undefendable damage.\n'
          '${adventure.hero.label} has no defense unless a card changes the attack.',
    2 =>
      'Naxarus rolled 2 on his attack die and performs Ember Spark.\n'
          'The active hero places the top 3 cards of their deck into the discard pile.\n'
          'Naxarus inflicts 8 damage.\n'
          '${adventure.hero.label} must perform a defensive phase.',
    3 =>
      'Naxarus rolled 3 on his attack die and performs Gashing Bite.\n'
          'The player must roll 4 dice in the extra dice phase.\n'
          'Damage equals the 2 highest dice.\n'
          '${extraDiceOutcome.isEmpty ? '' : '$extraDiceOutcome\n'}'
          '${adventure.hero.label} must perform a defensive phase.',
    4 =>
      'Naxarus rolled 4 on his attack die and performs Hoarding.\n'
          'The hero loses 1 die for the next battle roll.\n'
          'Naxarus inflicts 9 damage.\n'
          '${adventure.hero.label} must perform a defensive phase.',
    5 =>
      'Naxarus rolled 5 on his attack die and performs Thundering Roar.\n'
          'The hero discards 1 card.\n'
          'Naxarus inflicts 8 undefendable damage.\n'
          '${adventure.hero.label} has no defense unless a card changes the attack.',
    6 =>
      "Naxarus rolled 6 on his attack die and performs Dragon's Might.\n"
          'Dragon\'s Might inflicts 10 damage.\n'
          'The player must roll 1 extra die.\n'
          'On 5 or 6, Swoop is added to the attack.\n'
          '${extraDiceOutcome.isEmpty ? '' : extraDiceOutcome}',
    _ => 'Naxarus waits.',
  };
  return '**Battle phase.**\n$result';
}

_AttackDamage? _bestSymbolAttackDamage(EnemyNode enemy, List<GameDie> dice) {
  if (enemy.attackPlan.style != MinionAttackStyle.symbols) {
    return null;
  }
  _AttackDamage? result;
  for (final goal in enemy.attackPlan.goals) {
    if (_symbolGoalMetDice(dice, goal)) {
      result = _damageForSymbolGoal(enemy, goal);
    }
  }
  return result;
}

bool _symbolGoalMetDice(List<GameDie> dice, SymbolGoal goal) {
  final counts = <DieSymbol, int>{};
  for (final die in dice) {
    final symbol = die.symbol;
    if (symbol != null) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
  }
  return (counts[DieSymbol.white] ?? 0) >= goal.white &&
      (counts[DieSymbol.yellow] ?? 0) >= goal.yellow &&
      (counts[DieSymbol.red] ?? 0) >= goal.red;
}

int _bestSuiteLength(List<int> values) {
  final unique = values.toSet();
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
    if (suite.every(unique.contains)) {
      return suite.length;
    }
  }
  return 0;
}

class ManualExtraDicePhasePanel extends StatefulWidget {
  const ManualExtraDicePhasePanel({
    this.title = 'Extra dice phase',
    this.initialDiceCount = 1,
    this.accent = const Color(0xff8f43ff),
    this.autoRoll = false,
    this.onChanged,
    super.key,
  });

  final String title;
  final int initialDiceCount;
  final Color accent;
  final bool autoRoll;
  final ValueChanged<List<GameDie>>? onChanged;

  @override
  State<ManualExtraDicePhasePanel> createState() =>
      _ManualExtraDicePhasePanelState();
}

class _ManualExtraDicePhasePanelState extends State<ManualExtraDicePhasePanel> {
  final _random = Random();
  late final List<GameDie> _dice = List.generate(
    6,
    (index) => GameDie(id: index),
  );
  late int _diceToRoll;
  int _rollCount = 0;
  bool _editMode = false;
  bool _rerollMode = false;
  bool _animationPending = false;
  int? _editingDieId;

  @override
  void initState() {
    super.initState();
    _diceToRoll = widget.initialDiceCount.clamp(0, 5);
    if (widget.autoRoll && _diceToRoll > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rollVisibleDice());
    }
  }

  @override
  void didUpdateWidget(covariant ManualExtraDicePhasePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDiceCount != widget.initialDiceCount ||
        oldWidget.title != widget.title) {
      _diceToRoll = widget.initialDiceCount.clamp(0, 5);
      _rollCount = 0;
      _editMode = false;
      _rerollMode = false;
      _animationPending = false;
      _editingDieId = null;
      for (final die in _dice) {
        die
          ..value = null
          ..settled = true
          ..reserved = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleDice = _dice.take(_diceToRoll.clamp(0, 5)).toList();
    final hasRollingDice = visibleDice.any((die) => !die.settled);
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: _diceToRoll,
                items: [0, 1, 2, 3, 4, 5]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count dice'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _diceToRoll = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (final die in visibleDice)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DieTile(
                    die: die,
                    onTap: die.settled ? () => _tapDie(die) : null,
                    compact: true,
                    highlight: die.reserved || _editingDieId == die.id,
                    highlightColor: _editingDieId == die.id
                        ? heroAccent
                        : die.reserved
                        ? widget.accent
                        : null,
                  ),
                ),
            ],
          ),
          if (_editingDieId != null) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: [
                for (var face = 1; face <= 6; face++)
                  ChoiceChip(
                    label: Text(face.toString()),
                    selected: false,
                    onSelected: (_) {
                      setState(() {
                        _dice.firstWhere((die) => die.id == _editingDieId)
                          ..value = face
                          ..settled = true;
                        _editingDieId = null;
                        _editMode = false;
                      });
                      widget.onChanged?.call(
                        _dice.take(_diceToRoll.clamp(0, 5)).toList(),
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _SolidRollButton(
            color: widget.accent,
            onPressed: _diceToRoll <= 0 || hasRollingDice
                ? null
                : _rollVisibleDice,
            child: Text(_rollCount == 0 ? 'Roll' : 'Reroll'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => setState(() {
                    _editMode = !_editMode;
                    _rerollMode = false;
                    _editingDieId = null;
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: heroAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.tune),
                  label: Text(_editMode ? 'Stop edit' : 'Edit die'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => setState(() {
                    _rerollMode = !_rerollMode;
                    _editMode = false;
                    _editingDieId = null;
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: heroAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(_rerollMode ? 'Cancel' : 'Reroll die'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rollVisibleDice() {
    final rolledIds = <int>[];
    setState(() {
      final visibleDice = _dice.take(_diceToRoll.clamp(0, 5)).toList();
      _animationPending =
          combatDiceAnimationSeconds > 0 && visibleDice.isNotEmpty;
      for (final die in visibleDice) {
        die.value = _random.nextInt(6) + 1;
        die.settled = !_animationPending;
        die.rollTick++;
        rolledIds.add(die.id);
      }
      _rollCount++;
    });
    _notifyAfterAnimation(rolledIds);
  }

  void _notifyAfterAnimation(List<int> rolledIds) {
    if (!_animationPending) {
      widget.onChanged?.call(_dice.take(_diceToRoll.clamp(0, 5)).toList());
      return;
    }
    Future<void>.delayed(
      Duration(seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt()),
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          for (final die in _dice.where((die) => rolledIds.contains(die.id))) {
            die.settled = true;
          }
          _animationPending = _dice.any((die) => !die.settled);
        });
        if (!_animationPending) {
          widget.onChanged?.call(_dice.take(_diceToRoll.clamp(0, 5)).toList());
        }
      },
    );
  }

  void _tapDie(GameDie die) {
    setState(() {
      if (_editMode) {
        _editingDieId = die.id;
        return;
      }
      if (_rerollMode) {
        die.value = _random.nextInt(6) + 1;
        die.settled = combatDiceAnimationSeconds <= 0;
        die.rollTick++;
        _rerollMode = false;
        _animationPending = !die.settled;
        _notifyAfterAnimation([die.id]);
        return;
      }
      if (_rollCount > 0) {
        die.reserved = !die.reserved;
      }
    });
  }
}

/// Harmonized summary for an attack that triggers an additional dice roll.
///
/// Layout (lines that apply are shown in order; absent lines are skipped):
/// - L1: triggering attack's success dice ([SymbolGoalView]) + the attack's
///   direct result (damage) when the action itself deals damage before the
///   roll (e.g. Disciple "Abnégation" 5 undefendable).
/// - L2: the roll instruction ([MinionExtraRoll.rollText]) + a cube icon.
/// - L3-5: one [_ResultLine] per [ExtraRollOutcome] (face symbol on the left,
///   badges/label on the right). `face: any` uses a cube icon as the marker.
/// - L6: optional final effect ([MinionExtraRoll.finalText]) inside a
///   [_PassiveNote], rendered via [InlineTokenText] so token names become
///   images.
///
/// Replaces the previous hard-coded per-`profileKey` branches (Roc, Oni,
/// Mage de l'Entropie, Mage Lezard, Homme Lezard, Disciple, Yokai) with a
/// single data-driven renderer. The runtime resolution
/// (`_resolveExtraDicePhase`, keyed on `profileKey`) is untouched.
class _ExtraRollAttackSummary extends StatelessWidget {
  const _ExtraRollAttackSummary({
    required this.enemy,
    required this.goal,
    required this.extraRoll,
    required this.color,
    this.actionAlign = 'left',
    this.directDamage,
    this.directUndefendable = false,
    this.passiveNote,
  });

  final EnemyNode enemy;
  final SymbolGoal goal;
  final MinionExtraRoll extraRoll;
  final Color color;
  final String actionAlign;

  /// Direct damage dealt by the triggering attack itself (before the extra
  /// roll), shown on L1. Null when the attack's only effect is the roll.
  final _AttackDamage? directDamage;

  /// Whether [directDamage] is undefendable.
  final bool directUndefendable;

  /// Optional passive note appended after the summary (e.g. Roc's "if the
  /// offensive roll fails, deal 1 undefendable damage").
  final Widget? passiveNote;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // L1: success dice + direct result.
    final result = <Widget>[];
    if (directDamage != null) {
      result.add(
        DamageBadge(value: directDamage!.value, imparable: directUndefendable),
      );
    }
    children.add(_AttackResultLine(goal: goal, result: result, align: actionAlign));

    if (extraRoll.displayRows.isNotEmpty) {
      for (final row in extraRoll.displayRows) {
        children.add(_ExtraRollDisplayRow(row: row, color: color));
      }
    } else {
      // L2: roll instruction with the die image inlined where `{die}` appears.
      if (extraRoll.rollText.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RollTextWithDie(text: extraRoll.rollText, align: extraRoll.align),
          ),
        );
      }

      // L3-5: one line per outcome.
      for (final outcome in extraRoll.outcomes) {
        children.add(_buildOutcomeLine(outcome));
      }

      // L6: final effect note.
      final finalText = extraRoll.finalText;
      if (finalText != null && finalText.isNotEmpty) {
        children.add(const SizedBox(height: 6));
        children.add(
          _PassiveNote(
            child: InlineTokenText(
              finalText,
              color: color,
              style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
            ),
          ),
        );
      }
    }

    // Appended passive note (kept from the legacy branch, e.g. Roc).
    if (passiveNote != null) {
      children.add(const SizedBox(height: 6));
      children.add(passiveNote!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildOutcomeLine(ExtraRollOutcome outcome) {
    final badges = <Widget>[];

    // Label text (may contain token names → InlineTokenText).
    final label = outcome.label;
    if (label != null && label.isNotEmpty) {
      badges.add(
        InlineTokenText(
          label,
          color: color,
          style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
        ),
      );
    }
    if (outcome.damage > 0) {
      badges.add(
        DamageBadge(value: outcome.damage, imparable: outcome.undefendable),
      );
    }
    if (outcome.stealHp > 0) {
      badges.add(LifeStealBadge(value: outcome.stealHp, color: color));
    }
    if (outcome.stealCp > 0) {
      badges.add(CpStealBadge(value: outcome.stealCp, color: color));
    }
    for (final token in outcome.tokens) {
      badges.add(TokenBadge(label: token, color: color));
    }

    final align = outcome.align ?? extraRoll.align;
    if (outcome.face == ExtraRollFace.any) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Wrap(
          spacing: 5,
          alignment: align == 'center' ? WrapAlignment.center : WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: badges,
        ),
      );
    }
    final symbol = switch (outcome.face) {
      ExtraRollFace.white => DieSymbol.white,
      ExtraRollFace.yellow => DieSymbol.yellow,
      ExtraRollFace.red => DieSymbol.red,
      ExtraRollFace.any => DieSymbol.white,
    };
    return _ResultLine(symbol: symbol, children: badges, align: align);
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.symbol, required this.children, this.align = 'left'});

  final DieSymbol symbol;
  final List<Widget> children;
  final String align;

  @override
  Widget build(BuildContext context) {
    if (align == 'center') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DieSymbolMark(symbol: symbol),
            Wrap(
              spacing: 5,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          DieSymbolMark(symbol: symbol),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 5,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the extra-roll instruction ([MinionExtraRoll.rollText]) as a
/// rich text where the `{die}` marker is replaced by an inline [_CubeIcon],
/// so the die image appears in place of the word "die" instead of being a
/// separate icon duplicated at the end of the line. When the text contains
/// no `{die}` marker (legacy), a trailing cube icon is appended so the line
/// still shows the roll icon.
class _RollTextWithDie extends StatelessWidget {
  const _RollTextWithDie({required this.text, this.align = 'left'});

  final String text;
  final String align;

  static final RegExp _dieMarker = RegExp(r'\{die\}', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 13,
      color: Color(0xffcbd8cc),
    );
    final iconSpan = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _CubeIcon(size: 22),
      ),
    );

    if (!_dieMarker.hasMatch(text)) {
      // Legacy text without the marker: append the icon after the text.
      return Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: text),
            const WidgetSpan(child: SizedBox(width: 6)),
            iconSpan,
          ],
        ),
        textAlign: align == 'center' ? TextAlign.center : TextAlign.left,
      );
    }

    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _dieMarker.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(iconSpan);
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: align == 'center' ? TextAlign.center : TextAlign.left,
    );
  }
}

class _SuiteLine extends StatelessWidget {
  const _SuiteLine({
    required this.label,
    required this.length,
    required this.result,
  });

  final String label;
  final int length;
  final List<Widget> result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: SuiteGoalView(length: length)),
          ...result,
        ],
      ),
    );
  }
}

class _SuiteEffectLine extends StatelessWidget {
  const _SuiteEffectLine({
    required this.label,
    required this.length,
    required this.result,
  });

  final String label;
  final int length;
  final List<Widget> result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: SuiteGoalView(length: length)),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 5,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: result,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayRowsColumn extends StatelessWidget {
  const _DisplayRowsColumn({required this.rows, required this.color});

  final List<DisplayRow> rows;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) _ExtraRollDisplayRow(row: row, color: color),
      ],
    );
  }
}

class _ExtraRollDisplayRow extends StatelessWidget {
  const _ExtraRollDisplayRow({required this.row, required this.color});

  final DisplayRow row;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (row.align) {
      'center' || 'centre' => WrapAlignment.center,
      'right' => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: row.items
            .map(
              (item) => InlineTokenText(
                item,
                color: color,
                style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AttackResultLine extends StatelessWidget {
  const _AttackResultLine({required this.goal, required this.result, this.align = 'left'});

  final SymbolGoal goal;
  final List<Widget> result;
  final String align;

  @override
  Widget build(BuildContext context) {
    if (align == 'center') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SymbolGoalView(goal: goal),
            if (result.isNotEmpty)
              Wrap(
                spacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: result,
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: SymbolGoalView(goal: goal)),
          const SizedBox(width: 8),
          Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: result,
          ),
        ],
      ),
    );
  }
}

/// Builds a rich-text widget that replaces token names found inside [text]
/// with inline [TokenBadge] images. A token name is replaced only when the
/// matching [StatusTokenRule] has a non-null [StatusTokenRule.imageAsset],
/// so labels without an artwork stay as plain text.
///
/// Two forms are recognized:
///   - Explicit shortcodes: `{token:Chaos}`, `{token:Sort 6}` ...
///   - Bare localized labels declared in `assets/data/token_catalog.json`
///     (label, frLabel and aliases), e.g. "Chaos", "Sort 6", "Silence",
///     "Eboulissement", "Ronces", "Hémorragie", "Poison", "À Terre",
///     "Enchevêtrement", "Parasite", "Riposte", "Première Frappe", "Salve",
///     "Domination", "Siphon vital", "Prime", "Forme Ours", "Forme Elan",
///     "Hoarding" and their English aliases.
///
/// Matching is case-insensitive and word-boundary aware so "Ronce" never
/// matches inside "Ronces" and "Sort" never matches inside "Sortie".
class InlineTokenText extends StatelessWidget {
  const InlineTokenText(
    this.text, {
    required this.color,
    this.style,
    super.key,
  });

  final String text;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(text, color, style);
    return Text.rich(
      TextSpan(children: spans),
      style: style ?? const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
    );
  }
}

/// Regex for visual effect shortcodes inside authored text.
final RegExp _visualShortcodeRegex = RegExp(
  r'\{(damage|dmg|undef|imparable|prevent|block|heal|die|dice):([^}]+)\}',
  caseSensitive: false,
);

/// Regex for the explicit `{token:Name}` shortcode. The capture group holds
/// the raw token name as authored in JSON (it may include spaces, accents or
/// digits, e.g. "Sort 6", "Première Frappe").
final RegExp _tokenShortcodeRegex = RegExp(
  r'\{token:([^}]+)\}',
  caseSensitive: false,
);

/// Tokens, sorted by descending label length so that the longest name wins
/// when two candidates overlap (e.g. "Dégat Bonus 2" before "Dégat Bonus").
List<StatusTokenRule> get _inlineTokenRules =>
    TokenCatalogRepository.rules
        .where((rule) => rule.imageAsset != null && rule.editorVisible)
        .toList()
      ..sort((a, b) => b.label.length.compareTo(a.label.length));

/// Builds the inline span list for [text]. Returns a single [TextSpan] when
/// no token is found, otherwise alternates [TextSpan] and [WidgetSpan].
List<InlineSpan> _buildSpans(String text, Color color, TextStyle? style) {
  final effective =
      style ?? const TextStyle(fontSize: 12, color: Color(0xffcbd8cc));
  if (text.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: effective)];
  }

  // Gather every replacement as (start, end, label). Shortcodes are scanned
  // first (they take precedence), then bare labels are scanned on the text
  // that is NOT already covered by a shortcode.
  final matches = <_TokenMatch>[];

  bool overlaps(int start, int end) {
    for (final m in matches) {
      if (start < m.end && end > m.start) {
        return true;
      }
    }
    return false;
  }

  void scanVisualShortcodes() {
    for (final match in _visualShortcodeRegex.allMatches(text)) {
      final tag = match.group(1)!.toLowerCase();
      final rawValue = match.group(2)!.trim();
      if (tag == 'die' || tag == 'dice') {
        final normalized = rawValue.toLowerCase();
        final Widget widget = switch (normalized) {
          'any' || 'd6' => const _CubeIcon(size: 24),
          'white' || 'blanc' => Transform.scale(
            scale: 0.72,
            child: DieSymbolMark(symbol: DieSymbol.white),
          ),
          'orange' || 'yellow' || 'jaune' => Transform.scale(
            scale: 0.72,
            child: DieSymbolMark(symbol: DieSymbol.yellow),
          ),
          'red' || 'rouge' => Transform.scale(
            scale: 0.72,
            child: DieSymbolMark(symbol: DieSymbol.red),
          ),
          _ => Text(rawValue),
        };
        matches.add(_TokenMatch(match.start, match.end, null, null, widget));
        continue;
      }
      final amount = int.tryParse(rawValue);
      if (amount == null) {
        matches.add(_TokenMatch(match.start, match.end, null, rawValue));
        continue;
      }
      matches.add(
        _TokenMatch(
          match.start,
          match.end,
          null,
          null,
          _InlineChatBadge(
            label: amount.toString(),
            color: switch (tag) {
              'undef' || 'imparable' => Colors.redAccent,
              'prevent' || 'block' => Colors.blueAccent,
              'heal' => Colors.greenAccent,
              _ => Colors.white,
            },
          ),
        ),
      );
    }
  }

  void scanShortcodes() {
    for (final match in _tokenShortcodeRegex.allMatches(text)) {
      if (overlaps(match.start, match.end)) continue;
      final raw = match.group(1)!.trim();
      final rule = TokenCatalogRepository.byLabel(raw);
      if (rule == null || rule.imageAsset == null || !rule.editorVisible) {
        // Unknown token shortcode: render the inner name as plain text so the
        // author can spot the typo in the UI.
        matches.add(_TokenMatch(match.start, match.end, null, raw));
        continue;
      }
      matches.add(_TokenMatch(match.start, match.end, rule, rule.label));
    }
  }

  void scanBareLabels() {
    final lower = text.toLowerCase();
    for (final rule in _inlineTokenRules) {
      final candidates = <String>{
        rule.label,
        rule.frLabel,
        ...rule.aliases,
      }.where((value) => value.isNotEmpty);
      for (final candidate in candidates) {
        if (candidate.length < 3) {
          // Avoid trivial collisions on short tokens like "Vol".
          continue;
        }
        final needle = candidate.toLowerCase();
        var from = 0;
        while (true) {
          final idx = lower.indexOf(needle, from);
          if (idx < 0) break;
          final end = idx + needle.length;
          // Word-boundary: previous char must not be a letter/digit and the
          // next char must not be a letter (digit is allowed so "Sort 6" can
          // be followed by punctuation, but "Sort" alone stops at "Sortie").
          final prevOk = idx == 0 || !_isWordChar(lower.codeUnitAt(idx - 1));
          final nextOk =
              end == text.length || !_isLetterChar(lower.codeUnitAt(end));
          if (prevOk && nextOk && !overlaps(idx, end)) {
            matches.add(_TokenMatch(idx, end, rule, rule.label));
          }
          from = end;
        }
      }
    }
  }

  scanVisualShortcodes();
  scanShortcodes();
  scanBareLabels();
  matches.sort((a, b) => a.start.compareTo(b.start));

  if (matches.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: effective)];
  }

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final m in matches) {
    if (m.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, m.start), style: effective),
      );
    }
    if (m.widget != null) {
      spans.add(
        WidgetSpan(alignment: PlaceholderAlignment.middle, child: m.widget!),
      );
    } else if (m.rule != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: TokenBadge(label: m.rule!.label, color: color),
        ),
      );
    } else {
      // Unknown shortcode fallback: keep the authored name visible.
      spans.add(TextSpan(text: m.fallback ?? '', style: effective));
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: effective));
  }
  return spans;
}

bool _isWordChar(int codeUnit) {
  return _isLetterChar(codeUnit) || _isDigitChar(codeUnit);
}

bool _isLetterChar(int codeUnit) {
  // Covers ASCII letters and accented Latin-1 letters used in French token
  // names (é, è, à, ç, û, etc.). Digits are handled separately so "Sort 6"
  // matches while "Sortie" does not.
  final c = codeUnit;
  return (c >= 0x41 && c <= 0x5A) || // A-Z
      (c >= 0x61 && c <= 0x7A) || // a-z
      c >= 0xC0; // À-ÿ and beyond (Latin-1 supplement letters)
}

bool _isDigitChar(int codeUnit) {
  final c = codeUnit;
  return c >= 0x30 && c <= 0x39; // 0-9
}

class _TokenMatch {
  const _TokenMatch(
    this.start,
    this.end,
    this.rule,
    this.fallback, [
    this.widget,
  ]);

  final int start;
  final int end;
  final StatusTokenRule? rule;
  final String? fallback;
  final Widget? widget;
}

class _PassiveNote extends StatelessWidget {
  const _PassiveNote({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/passive_background_umbra.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.18),
            BlendMode.darken,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: panelBorderGrey.withValues(alpha: 0.75)),
      ),
      child: child,
    );
  }
}

/// Renders one passive ability as a text line plus, when the JSON provides
/// structured effects, the corresponding badges (damage, lifesteal, heal,
/// tokens). This is the generic passive zone used for profiles that do not
/// have a dedicated hard-coded view.
class _PassiveLine extends StatelessWidget {
  const _PassiveLine({required this.passive});

  final MinionPassive passive;

  @override
  Widget build(BuildContext context) {
    final effect = passive.effect;
    final children = <Widget>[
      InlineTokenText(
        passive.text,
        color: const Color(0xffcbd8cc),
        style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
      ),
    ];
    if (effect != null) {
      final badges = <Widget>[];
      if (effect.damage > 0) {
        badges.add(
          DamageBadge(value: effect.damage, imparable: effect.undefendable),
        );
      }
      if (effect.stealHp > 0) {
        badges.add(
          LifeStealBadge(value: effect.stealHp, color: Colors.redAccent),
        );
      }
      if (effect.heal > 0) {
        badges.add(
          TokenBadge(label: '+$effect.heal PV', color: Colors.greenAccent),
        );
      }
      for (final token in effect.heroTokens) {
        badges.add(TokenBadge(label: token, color: Colors.deepOrangeAccent));
      }
      if (badges.isNotEmpty) {
        children
          ..add(const SizedBox(height: 4))
          ..add(
            Wrap(
              spacing: 5,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: badges,
            ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class SuiteGoalView extends StatelessWidget {
  const SuiteGoalView({required this.length, super.key});

  final int length;

  @override
  Widget build(BuildContext context) {
    final count = length.clamp(1, 5);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Container(
            width: 18 + index * 4,
            height: 18 + index * 4,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
      ],
    );
  }
}

class _CubeIcon extends StatelessWidget {
  const _CubeIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const _CubeIconPainter()),
    );
  }
}

class _UpkeepCubeIcon extends StatelessWidget {
  const _UpkeepCubeIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _CubeIconPainter(
          faceColor: Color(0xffd94c1f),
          lineColor: Colors.white,
        ),
      ),
    );
  }
}

class _CubeIconPainter extends CustomPainter {
  const _CubeIconPainter({
    this.faceColor = Colors.white,
    this.lineColor = const Color(0xff252724),
  });

  final Color faceColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);

    final fill = Paint()..color = faceColor;
    final stroke = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pip = Paint()..color = lineColor;

    final top = Path()
      ..moveTo(50, 6)
      ..lineTo(88, 28)
      ..lineTo(50, 50)
      ..lineTo(12, 28)
      ..close();
    final left = Path()
      ..moveTo(12, 28)
      ..lineTo(50, 50)
      ..lineTo(50, 94)
      ..lineTo(12, 72)
      ..close();
    final right = Path()
      ..moveTo(88, 28)
      ..lineTo(50, 50)
      ..lineTo(50, 94)
      ..lineTo(88, 72)
      ..close();

    canvas.drawPath(top, fill);
    canvas.drawPath(left, fill);
    canvas.drawPath(right, fill);
    canvas.drawPath(top, stroke);
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 27), width: 12, height: 9),
      pip,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 45), width: 9, height: 13),
      pip,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(35, 61), width: 9, height: 13),
      pip,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(44, 78), width: 9, height: 13),
      pip,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(65, 59), width: 9, height: 13),
      pip,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(78, 72), width: 9, height: 13),
      pip,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CubeIconPainter oldDelegate) {
    return oldDelegate.faceColor != faceColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class SymbolGoalView extends StatelessWidget {
  const SymbolGoalView({required this.goal, super.key});

  final SymbolGoal goal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < goal.white; i++)
          const DieSymbolMark(symbol: DieSymbol.white),
        for (var i = 0; i < goal.yellow; i++)
          const DieSymbolMark(symbol: DieSymbol.yellow),
        for (var i = 0; i < goal.red; i++)
          const DieSymbolMark(symbol: DieSymbol.red),
      ],
    );
  }
}

class DieSymbolMark extends StatelessWidget {
  const DieSymbolMark({required this.symbol, super.key});

  final DieSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final asset = switch (symbol) {
      DieSymbol.white => 'assets/dice_faces/symbol_white.webp',
      DieSymbol.yellow => 'assets/dice_faces/symbol_orange.webp',
      DieSymbol.red => 'assets/dice_faces/symbol_red.webp',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Image.asset(asset, width: 34, height: 34, fit: BoxFit.contain),
    );
  }
}

class DamageBadge extends StatelessWidget {
  const DamageBadge({required this.value, required this.imparable, super.key});

  final int value;
  final bool imparable;

  @override
  Widget build(BuildContext context) {
    return _EffectImageBadge(
      value: value.toString(),
      asset: imparable
          ? 'assets/illustration/degat-imp.webp'
          : 'assets/illustration/degat.webp',
      textColor: Colors.white,
      size: 30,
    );
  }
}

class PreventBadge extends StatelessWidget {
  const PreventBadge({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return _EffectImageBadge(
      value: value.toString(),
      asset: 'assets/illustration/bouclier.webp',
      textColor: Colors.white,
      size: 32,
    );
  }
}

class _HalfPreventBadge extends StatelessWidget {
  const _HalfPreventBadge();

  @override
  Widget build(BuildContext context) {
    return const _EffectImageBadge(
      value: '1/2',
      asset: 'assets/illustration/bouclier.webp',
      textColor: Colors.white,
      size: 34,
      fontSize: 10,
    );
  }
}

class _EffectImageBadge extends StatelessWidget {
  const _EffectImageBadge({
    required this.value,
    required this.asset,
    required this.textColor,
    this.size = 28,
    this.fontSize = 11,
  });

  final String value;
  final String asset;
  final Color textColor;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  const _MultiplierBadge();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'x',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class DieValueBadge extends StatelessWidget {
  const DieValueBadge({
    required this.value,
    this.showValue = true,
    this.size = 26,
    super.key,
  });

  final int value;
  final bool showValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: Image.asset(
        'assets/dice_faces/face_$value.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _NaxarusDieValueBadge extends StatelessWidget {
  const _NaxarusDieValueBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return DieValueBadge(value: value, size: 30);
  }
}

class TokenBadge extends StatelessWidget {
  const TokenBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rule = TokenCatalogRepository.byLabel(label);
    if (rule != null) {
      if (!rule.editorVisible) {
        return const SizedBox.shrink();
      }
      return Tooltip(
        message: rule.label,
        child: GestureDetector(
          onTap: () => showTokenDetails(context, rule),
          child: StatusTokenImage(rule: rule, size: 30),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class LifeStealBadge extends StatelessWidget {
  const LifeStealBadge({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'steal',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        _EffectImageBadge(
          value: value.toString(),
          asset: 'assets/illustration/soin.webp',
          textColor: Colors.white,
          size: 28,
          fontSize: 12,
        ),
      ],
    );
  }
}

class CpStealBadge extends StatelessWidget {
  const CpStealBadge({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        'Steal $value CP',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HealBadge extends StatelessWidget {
  const _HealBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return _EffectImageBadge(
      value: '+$value',
      asset: 'assets/illustration/soin.webp',
      textColor: Colors.white,
      size: 30,
    );
  }
}

class _DiscardCardBadge extends StatelessWidget {
  const _DiscardCardBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 1,
            top: 1,
            child: Icon(Icons.south_east, color: Colors.black, size: 10),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FourDiceToTopTwoBadge extends StatelessWidget {
  const _FourDiceToTopTwoBadge();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('4x', style: TextStyle(fontWeight: FontWeight.w900)),
        _CubeIcon(size: 22),
        const Text('='),
        const _TopDieBadge(),
        const Text('+'),
        const _TopDieBadge(),
      ],
    );
  }
}

class _DiePenaltyBadge extends StatelessWidget {
  const _DiePenaltyBadge();

  @override
  Widget build(BuildContext context) {
    return const _EmptyDieBadge(
      size: 30,
      label: '-1',
      borderColor: heroAccent,
      textColor: heroAccent,
    );
  }
}

class _OneDieBadge extends StatelessWidget {
  const _OneDieBadge();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('1x', style: TextStyle(fontWeight: FontWeight.w900)),
        _CubeIcon(size: 24),
      ],
    );
  }
}

class _TopDieBadge extends StatelessWidget {
  const _TopDieBadge();

  @override
  Widget build(BuildContext context) {
    return const _EmptyDieBadge(
      size: 22,
      label: '^',
      borderColor: Colors.white,
      textColor: Colors.white,
    );
  }
}

class _SwoopOnFiveSixBadge extends StatelessWidget {
  const _SwoopOnFiveSixBadge();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '5/6 -> Swoop',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
    );
  }
}

class _DragonMightResultBadge extends StatelessWidget {
  const _DragonMightResultBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _OneDieBadge(),
            SizedBox(height: 2),
            _SwoopOnFiveSixBadge(),
          ],
        ),
        SizedBox(width: 6),
        Text(
          '+',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(width: 2),
        DamageBadge(value: 10, imparable: false),
      ],
    );
  }
}

class _EmptyDieBadge extends StatelessWidget {
  const _EmptyDieBadge({
    required this.size,
    this.label,
    this.borderColor = Colors.white,
    this.textColor = Colors.white,
  });

  final double size;
  final String? label;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: label == null
          ? null
          : Text(
              label!,
              style: TextStyle(
                color: textColor,
                fontSize: size <= 24 ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _AttackDamage {
  const _AttackDamage(this.value, {this.imparable = false});

  final int value;
  final bool imparable;
}

/// Mutable accumulators passed through [ConditionalRule] application so the
/// generic runtime can mutate attack resolution the same way the legacy
/// per-profile switch did. Top-level (Dart forbids classes nested in other
/// classes).
class _ConditionalAccumulators {
  _ConditionalAccumulators({
    required this.result,
    required this.values,
    required this.symbols,
    required this.attack,
    required this.attackUndefendable,
    required this.lifeSteal,
    required this.cpSteal,
    required this.heroTokens,
    required this.minionTokens,
    required this.notes,
  });

  final _AttackDamage? result;
  final List<int> values;
  final List<DieSymbol> symbols;
  int attack;
  bool attackUndefendable;
  int lifeSteal;
  int cpSteal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final List<String> notes;
}

/// Returns the first goal of an extra-roll attack. Extra-roll attacks
/// (Roc, Oni, Mage de l'Entropie, Mage Lezard, Homme Lezard, Disciple,
/// Yokai) carry a single triggering goal in `attackPlan.goals`.
SymbolGoal? _extraRollGoalFor(EnemyNode enemy) {
  final goals = enemy.attackPlan.goals;
  if (goals.isEmpty) {
    return null;
  }
  return goals.first;
}

/// Returns the parsed [MinionExtraRoll] attached to the first goal of an
/// extra-roll attack, or null when the action has no extra roll. The extra
/// roll is attached to the goal's [SymbolGoalEffect] by the JSON parser.
MinionExtraRoll? _extraRollFor(EnemyNode enemy) {
  final goal = _extraRollGoalFor(enemy);
  if (goal == null) {
    return null;
  }
  return goal.effect?.extraRoll;
}

/// Returns the direct damage dealt by the triggering attack itself (before
/// the extra roll), read from the first goal's effect. Used as the L1 result
/// badge for extra-roll attacks whose action deals damage (The Butcher 3
/// undefendable, The Hermit 3 undefendable, Farceur 4 undefendable, Cyclope
/// Brutal 6). Null when the action only triggers the roll.
_AttackDamage? _extraRollDirectDamageFor(EnemyNode enemy) {
  final goal = _extraRollGoalFor(enemy);
  if (goal == null) {
    return null;
  }
  final effect = goal.effect;
  if (effect == null) {
    return null;
  }
  if (effect.damage <= 0) {
    return null;
  }
  return _AttackDamage(effect.damage, imparable: effect.undefendable);
}

bool _isDruidBearForm(EnemyNode enemy) {
  if (enemy.alterations.contains('Forme Elan')) {
    return false;
  }
  return true;
}

_AttackDamage? _damageForSymbolGoal(EnemyNode enemy, SymbolGoal goal) {
  final key = enemy.profileKey;
  final goalIndex = _goalIndex(enemy.attackPlan.goals, goal);
  // Special hardcoded resolvers take precedence (they encode logic that the
  // JSON effect model cannot express, e.g. dynamic damage from goal values).
  if (key == 'ronin-vagabond') {
    return _AttackDamage(goal.white + 2);
  }
  if (key == 'enchanteur-gobelin') {
    return const _AttackDamage(4, imparable: true);
  }
  if (key == 'archer-de-lombre') {
    return _AttackDamage(goal.yellow + 3);
  }
  if (key == 'ombre-feline') {
    return _AttackDamage(goal.white + 1);
  }
  if (key == 'epeiste-egare') {
    return _AttackDamage(goal.white + 2);
  }
  if (key == 'vert-vert-016') {
    return const _AttackDamage(5, imparable: true);
  }
  if (key == 'vert-vert-012' || key == 'vert-vert-017') {
    return null;
  }
  if (key == 'vert-vert-014') {
    return const _AttackDamage(6);
  }
  if (key == 'vert-vert-015') {
    return const _AttackDamage(6, imparable: true);
  }
  if (key == 'vert-vert-018') {
    if (goal.white == 2 && goal.yellow == 1 && goal.red == 0) {
      return const _AttackDamage(4);
    }
    if (goal.white == 2 && goal.yellow == 2 && goal.red == 0) {
      return const _AttackDamage(5);
    }
    if (goal.white == 2 && goal.yellow == 2 && goal.red == 1) {
      return const _AttackDamage(7);
    }
  }
  if (key == 'vert-vert-019') {
    return const _AttackDamage(4, imparable: true);
  }
  if (key == 'vert-vert-021') {
    return null;
  }
  if (key == 'bleu-bleu-001') {
    return const _AttackDamage(6, imparable: true);
  }
  if (key == 'bleu-bleu-002') {
    if (goal.yellow == 3) {
      return const _AttackDamage(4, imparable: true);
    }
    if (goal.yellow == 4) {
      return const _AttackDamage(5, imparable: true);
    }
    if (goal.yellow == 5) {
      return const _AttackDamage(6, imparable: true);
    }
  }
  if (key == 'bleu-bleu-003') {
    return null;
  }
  if (key == 'bleu-bleu-004') {
    return const _AttackDamage(0);
  }
  // Prefer the structured effect parsed from the JSON `attackPlan.actions`
  // entry for this goal. This is the source of truth and avoids fragile text
  // parsing of the localized `attacks` strings (which caused wrong damage and
  // missed attacks for profiles like Roi Vautour / vert-vert-011).
  final effect = goal.effect;
  if (effect != null) {
    return _AttackDamage(effect.damage, imparable: effect.undefendable);
  }
  return _damageFromAttackText(enemy, goalIndex);
}

_AttackDamage? _suiteDamage(EnemyNode enemy, int length) {
  final key = enemy.profileKey;
  // Prefer the structured effect parsed from the JSON `attackPlan.actions`
  // entry for this suite length. Same rationale as `_damageForSymbolGoal`:
  // the JSON is the source of truth and avoids fragile text parsing.
  final effect = enemy.attackPlan.suiteEffects[length];
  if (effect != null) {
    return _AttackDamage(effect.damage, imparable: effect.undefendable);
  }
  if (key == 'fee') {
    return switch (length) {
      3 => const _AttackDamage(2, imparable: true),
      4 => const _AttackDamage(5),
      5 => const _AttackDamage(6),
      _ => null,
    };
  }
  if (key == 'elfe-du-chaos') {
    return switch (length) {
      3 => const _AttackDamage(4),
      4 => const _AttackDamage(7),
      5 => const _AttackDamage(8),
      _ => null,
    };
  }
  if (key == 'vert-vert-020') {
    return switch (length) {
      3 => const _AttackDamage(4),
      4 => const _AttackDamage(7),
      5 => const _AttackDamage(7),
      _ => null,
    };
  }
  return _suiteDamageFromAttackText(enemy, length);
}

int _goalIndex(List<SymbolGoal> goals, SymbolGoal goal) {
  return goals.indexWhere(
    (candidate) =>
        candidate.white == goal.white &&
        candidate.yellow == goal.yellow &&
        candidate.red == goal.red,
  );
}

_AttackDamage? _damageFromAttackText(EnemyNode enemy, int goalIndex) {
  if (goalIndex < 0) {
    return null;
  }
  final damageValues = _attackDamageValues(enemy.attacks);
  if (goalIndex >= damageValues.length) {
    return null;
  }
  final value = damageValues[goalIndex];
  return _AttackDamage(value, imparable: _attackTextIsImparable(enemy.attacks));
}

_AttackDamage? _suiteDamageFromAttackText(EnemyNode enemy, int length) {
  final index = switch (length) {
    3 => 0,
    4 => 1,
    5 => 2,
    _ => -1,
  };
  if (index < 0) {
    return null;
  }
  final damageValues = _attackDamageValues(enemy.attacks);
  if (index >= damageValues.length) {
    return null;
  }
  return _AttackDamage(
    damageValues[index],
    imparable: _attackTextIsImparable(enemy.attacks),
  );
}

bool _attackNeedsExtraDice(EnemyNode enemy) {
  // Extra dice must be backed by resolver code. Text-only detections create
  // dangling phases where the roll is displayed but never applied.
  return false;
}

int _extraDiceCountFor(EnemyNode enemy) {
  if (enemy.profileKey == 'vert-vert-012') {
    return 2;
  }
  final text = _normalizeAttackText(enemy.attacks.join(' '));
  final match = RegExp(
    r'(?:lance|lancer|roll)\s+(\d+)\s+(?:de|des|die|dice)',
  ).firstMatch(text);
  return (int.tryParse(match?.group(1) ?? '') ?? 1).clamp(1, 5);
}

List<int> _attackDamageValues(List<String> attacks) {
  final values = <int>[];
  for (final line in attacks.skip(1)) {
    final normalized = _normalizeAttackText(line);
    // Primary: "<number>[/<number>...] (degats|damage)" anywhere on the line.
    for (final match in RegExp(
      r'(\d+(?:\s*/\s*\d+)*)\s*(?:degats|damage)',
    ).allMatches(normalized)) {
      final raw = match.group(1);
      if (raw == null) {
        continue;
      }
      values.addAll(
        raw
            .split('/')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>(),
      );
    }
    if (values.isNotEmpty) {
      continue;
    }
    // Fallback A: "X orange = N" style lines (e.g. "3 orange = 4 degats"
    // where the word was not recognized — take the number right after '=').
    final equalsMatch = RegExp(r'=\s*(\d+)').firstMatch(normalized);
    if (equalsMatch != null) {
      final value = int.tryParse(equalsMatch.group(1) ?? '');
      if (value != null) {
        values.add(value);
        continue;
      }
    }
    // Fallback B: bare trailing number when no damage keyword and no '='.
    // Only used as a last resort and only takes the FIRST number to avoid
    // grabbing unrelated counts (e.g. CP cost, symbol thresholds).
    if (!normalized.contains('degats') &&
        !normalized.contains('damage') &&
        !normalized.contains('=')) {
      final bare = RegExp(r'(\d+)').firstMatch(normalized);
      if (bare != null) {
        final value = int.tryParse(bare.group(1) ?? '');
        if (value != null) {
          values.add(value);
        }
      }
    }
  }
  return values;
}

bool _attackTextIsImparable(List<String> attacks) {
  final text = _normalizeAttackText(attacks.join(' '));
  return text.contains('imparable') || text.contains('undefendable');
}

/// Strips French (and common Latin-1) diacritics and lowercases the input.
///
/// Used by attack/defense text parsing so that localized words like `dégâts`,
/// `défensif`, `hémorragie` can be matched against simple ASCII patterns
/// (`degats`, `defensif`, `hemorragie`). Keep this exhaustive: any missing
/// diacritic leaks through and silently breaks the regex matches, which is
/// exactly what caused wrong damage values for Roi Vautour.
String _stripDiacritics(String value) {
  return value
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('á', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('å', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ā', 'a')
      .replaceAll('ç', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ē', 'e')
      .replaceAll('ė', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('í', 'i')
      .replaceAll('ī', 'i')
      .replaceAll('ñ', 'n')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ó', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('œ', 'oe')
      .replaceAll('æ', 'ae')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ú', 'u')
      .replaceAll('ū', 'u')
      .replaceAll('ÿ', 'y')
      .replaceAll('ý', 'y');
}

String _normalizeAttackText(String value) {
  return _stripDiacritics(value);
}

String _compactDefenseText(String value) {
  final stripped = _stripDiacritics(value);
  return stripped
      .replaceAll('jaunes', 'orange')
      .replaceAll('jaune', 'orange')
      .replaceAll('symboles', 'symbols')
      .replaceAll('symbole', 'symbol')
      .replaceAll('des', 'dice')
      .replaceAll('de', 'die')
      .replaceAll('degats', 'damage')
      .replaceAll('degat', 'damage')
      .replaceAll('jet defensif ', '')
      .replaceAll('jetdefensif ', '');
}

class FightStatusPanel extends StatefulWidget {
  const FightStatusPanel({
    required this.adventure,
    required this.enemy,
    required this.phase,
    required this.naraxusRollHistory,
    required this.onFinish,
    required this.onChanged,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final CombatPhase phase;
  final List<String> naraxusRollHistory;
  final VoidCallback? onFinish;
  final VoidCallback onChanged;

  @override
  State<FightStatusPanel> createState() => _FightStatusPanelState();
}

class _FightStatusPanelState extends State<FightStatusPanel> {
  final Set<String> _editing = {};
  final Map<String, int> _draftValues = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: -16),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: const BoxDecoration(
        color: Color(0xee121212),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CombatVersusStatusPanel(
            adventure: widget.adventure,
            enemy: widget.enemy,
            onHeroHp: () => _openEditor('heroHp', widget.adventure.health),
            onHeroCp: () =>
                _openEditor('heroCp', widget.adventure.combatPoints),
            onEnemyHp: () => _openEditor('enemyHp', widget.enemy.health),
            onEnemyCp: () => _openEditor('enemyCp', widget.enemy.combatPoints),
            onEditHeroTokens: _editHeroTokens,
            onEditEnemyTokens: _editEnemyTokens,
            onTokensChanged: _onTokensChanged,
          ),
          if (_editing.contains('heroHp') || _editing.contains('enemyHp')) ...[
            const SizedBox(height: 6),
            _buildEditorPair('enemyHp', 'heroHp'),
          ],
          if (_editing.contains('heroCp') || _editing.contains('enemyCp')) ...[
            const SizedBox(height: 6),
            _buildEditorPair('enemyCp', 'heroCp'),
          ],
          if (widget.onFinish != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: FilledButton.icon(
                    onPressed: widget.onFinish,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorPair(String leftKey, String rightKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _editing.contains(leftKey)
                ? _buildEditorRow(leftKey)
                : const SizedBox(height: 44),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _editing.contains(rightKey)
                ? _buildEditorRow(rightKey)
                : const SizedBox(height: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorRow(String key) {
    final isHero = key.startsWith('hero');
    final isHp = key.endsWith('Hp');
    final accent = isHero ? heroAccent : widget.enemy.rank.color;
    final value = _draftValues[key] ?? 0;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelBorderGrey),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Center(
              child: isHp
                  ? Icon(Icons.favorite, color: accent, size: 17)
                  : Text(
                      'CP',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          _CompactRoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            color: accent,
            onPressed: () => setState(() => _draftValues[key] = value + 1),
          ),
          Expanded(
            child: Center(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _CompactRoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            color: accent,
            onPressed: () => setState(() => _draftValues[key] = value - 1),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            height: 34,
            child: FilledButton(
              onPressed: () => _saveStat(key),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.check, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(String key, int value) {
    setState(() {
      if (_editing.contains(key)) {
        _editing.remove(key);
      } else {
        _editing.add(key);
        _draftValues[key] = value;
      }
    });
  }

  Future<void> _saveStat(String key) async {
    final value = _draftValues[key] ?? 0;
    switch (key) {
      case 'heroHp':
        widget.adventure.setHeroHealth(value);
      case 'heroCp':
        widget.adventure.setHeroPc(value);
      case 'enemyHp':
        final oldHealth = widget.enemy.health;
        widget.enemy.health = value.clamp(0, 99);
        if (widget.phase == CombatPhase.hero &&
            widget.enemy.health < oldHealth &&
            widget.enemy.alterations.contains('Riposte')) {
          await _offerRiposte();
        }
      case 'enemyCp':
        widget.enemy.combatPoints = value.clamp(0, 99);
    }
    setState(() => _editing.remove(key));
    widget.onChanged();
  }

  Future<void> _offerRiposte() async {
    final spend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Riposte'),
        content: const Text(
          'The minion lost HP during the hero turn. Spend Riposte now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (spend != true) {
      return;
    }
    final roll = Random().nextInt(6) + 1;
    final damage = (roll / 2).ceil();
    widget.enemy.alterations.remove('Riposte');
    widget.adventure.setHeroHealth(widget.adventure.health - damage);
    widget.adventure.log('Riposte spent: D6 $roll, hero loses $damage HP.');
  }

  Future<void> _editHeroTokens() async {
    final values = await showAlterationDialog(
      context,
      widget.adventure.alterations,
      duelTokens: [
        ...TokenCatalogRepository.heroTokens(widget.adventure.hero),
        ...widget.adventure.alterations,
        ...widget.enemy.alterations,
      ],
    );
    if (values != null) {
      widget.adventure.setAlterations(values);
      widget.onChanged();
      setState(() {});
    }
  }

  Future<void> _editEnemyTokens() async {
    final values = await showAlterationDialog(
      context,
      widget.enemy.alterations,
      forMinion: true,
      duelTokens: [
        ...TokenCatalogRepository.heroTokens(widget.adventure.hero),
        ...widget.adventure.alterations,
        ...widget.enemy.alterations,
      ],
    );
    if (values != null) {
      widget.enemy.alterations
        ..clear()
        ..addAll(values);
      widget.onChanged();
      setState(() {});
    }
  }

  void _onTokensChanged() {
    widget.onChanged();
    setState(() {});
  }
}

class CombatVersusStatusPanel extends StatelessWidget {
  const CombatVersusStatusPanel({
    required this.adventure,
    required this.enemy,
    required this.onHeroHp,
    required this.onHeroCp,
    required this.onEnemyHp,
    required this.onEnemyCp,
    required this.onEditHeroTokens,
    required this.onEditEnemyTokens,
    required this.onTokensChanged,
    super.key,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final VoidCallback onHeroHp;
  final VoidCallback onHeroCp;
  final VoidCallback onEnemyHp;
  final VoidCallback onEnemyCp;
  final VoidCallback onEditHeroTokens;
  final VoidCallback onEditEnemyTokens;
  final VoidCallback onTokensChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.26)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _CombatantVersusHalf(
                  title: enemy.label,
                  hp: enemy.health,
                  cp: enemy.combatPoints,
                  tokens: enemy.alterations,
                  accent: enemy.rank.color,
                  portraitAsset: enemy.previewAsset,
                  portraitAlignment: enemy.profileKey == 'naraxus'
                      ? Alignment.center
                      : Alignment.centerLeft,
                  hpStyle: _CombatHpStyle.enemy,
                  infiniteCp:
                      enemy.profileKey == 'naraxus' ||
                      enemy.profileKey == 'viseer',
                  onHp: onEnemyHp,
                  onCp: onEnemyCp,
                  onEditTokens: onEditEnemyTokens,
                  onTokensChanged: onTokensChanged,
                ),
              ),
              Container(
                width: 1,
                color: panelBorderGrey.withValues(alpha: 0.75),
              ),
              Expanded(
                child: _CombatantVersusHalf(
                  title: adventure.hero.label,
                  hp: adventure.health,
                  cp: adventure.combatPoints,
                  tokens: adventure.alterations,
                  accent: heroAccent,
                  portraitAsset: adventure.hero.asset,
                  portraitAlignment: adventure.hero.imageAlignment,
                  portraitScale: min(adventure.hero.imageScale, 1.08),
                  hpStyle: _CombatHpStyle.hero,
                  onHp: onHeroHp,
                  onCp: onHeroCp,
                  onEditTokens: onEditHeroTokens,
                  onTokensChanged: onTokensChanged,
                  imageOnRight: true,
                ),
              ),
            ],
          ),
          Positioned(
            top: 66,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: panelBorderGrey),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CombatHpStyle { enemy, hero }

class _CombatantVersusHalf extends StatelessWidget {
  const _CombatantVersusHalf({
    required this.title,
    required this.hp,
    required this.cp,
    required this.tokens,
    required this.accent,
    required this.portraitAsset,
    required this.portraitAlignment,
    required this.hpStyle,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    this.onTokensChanged,
    this.portraitScale = 1,
    this.imageOnRight = false,
    this.infiniteCp = false,
  });

  final String title;
  final int hp;
  final int cp;
  final List<String> tokens;
  final Color accent;
  final String portraitAsset;
  final Alignment portraitAlignment;
  final double portraitScale;
  final _CombatHpStyle hpStyle;
  final VoidCallback onHp;
  final VoidCallback onCp;
  final VoidCallback onEditTokens;
  final VoidCallback? onTokensChanged;
  final bool imageOnRight;
  final bool infiniteCp;

  @override
  Widget build(BuildContext context) {
    final portrait = Expanded(
      flex: 7,
      child: _NamedCombatPortrait(
        title: title,
        asset: portraitAsset,
        alignment: portraitAlignment,
        scale: portraitScale,
        accent: accent,
      ),
    );
    final stats = Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CombatBadgeButton(
              onTap: onHp,
              child: _HpHeartBadge(value: hp, style: hpStyle),
            ),
            const SizedBox(height: 8),
            _CombatBadgeButton(
              onTap: infiniteCp ? () {} : onCp,
              child: _PcTriangleBadge(value: cp, infinity: infiniteCp),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Expanded(
          child: Row(
            children: imageOnRight ? [stats, portrait] : [portrait, stats],
          ),
        ),
        SizedBox(
          height: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
            child: CompactItemStrip(
              label: 'Tokens',
              emptyText: 'Tokens',
              items: tokens,
              accent: accent,
              background: Colors.black.withValues(alpha: 0.22),
              border: panelBorderGrey,
              onTokensChanged: onTokensChanged,
              trailing: IconButton(
                tooltip: 'Edit tokens',
                visualDensity: VisualDensity.compact,
                onPressed: onEditTokens,
                icon: const Icon(Icons.edit, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NamedCombatPortrait extends StatelessWidget {
  const _NamedCombatPortrait({
    required this.title,
    required this.asset,
    required this.alignment,
    required this.accent,
    this.scale = 1,
  });

  final String title;
  final String asset;
  final Alignment alignment;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: _topCropAlignment(alignment),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Alignment _topCropAlignment(Alignment alignment) {
  return Alignment(alignment.x.clamp(-1.0, 1.0).toDouble(), -1);
}

Alignment _heroEyeAlignment(HeroType hero) {
  return switch (hero) {
    HeroType.barbare => const Alignment(0, -0.62),
    HeroType.elfeLunaire => const Alignment(0, -0.70),
    HeroType.tacticien => const Alignment(0, -0.66),
    HeroType.monk => const Alignment(0, -0.78),
    HeroType.paladin => const Alignment(0, -0.72),
    HeroType.pyromancer => const Alignment(0, -0.76),
    HeroType.shadowThief => const Alignment(0, -0.72),
    HeroType.spiderman => const Alignment(0, -0.58),
    _ => const Alignment(0, -0.66),
  };
}

Alignment _minionEyeAlignment(EnemyNode enemy) {
  if (enemy.profileKey == 'naraxus') {
    return Alignment.center;
  }
  return switch (enemy.profileKey) {
    'rat-de-la-rue' => const Alignment(-0.18, -0.58),
    'fee' => const Alignment(0, -0.76),
    'ronin-vagabond' => const Alignment(0, -0.72),
    'enchanteur-gobelin' => const Alignment(-0.12, -0.64),
    'archer-de-lombre' => const Alignment(0, -0.68),
    _ => const Alignment(0, -0.68),
  };
}

BoxFit _minionEyeFit(EnemyNode enemy) {
  return BoxFit.cover;
}

class _CombatBadgeButton extends StatelessWidget {
  const _CombatBadgeButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 74, height: 62, child: Center(child: child)),
      ),
    );
  }
}

class _HpHeartBadge extends StatelessWidget {
  const _HpHeartBadge({required this.value, required this.style});

  final int value;
  final _CombatHpStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HpHeartBadgePainter(style: style),
      child: SizedBox(
        width: 58,
        height: 48,
        child: Center(
          child: Text(
            value.clamp(0, 99).toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _PcTriangleBadge extends StatelessWidget {
  const _PcTriangleBadge({required this.value, this.infinity = false});

  final int value;
  final bool infinity;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 99);
    final valueText = infinity ? '∞' : safeValue.toString();
    final showPcLabel = !infinity && safeValue < 10;
    return CustomPaint(
      painter: const _PcTriangleBadgePainter(),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Stack(
          children: [
            Align(
              alignment: showPcLabel
                  ? const Alignment(-0.54, -0.02)
                  : const Alignment(-0.24, 0),
              child: Text(
                valueText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: infinity ? 24 : (showPcLabel ? 28 : 21),
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.white54, blurRadius: 8)],
                ),
              ),
            ),
            if (showPcLabel)
              Align(
                alignment: const Alignment(0.18, -0.04),
                child: Text(
                  'CP',
                  style: TextStyle(
                    color: const Color(0xff9ee8e2).withValues(alpha: 0.98),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(color: Colors.white54, blurRadius: 5),
                      Shadow(color: Colors.black87, blurRadius: 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HpHeartBadgePainter extends CustomPainter {
  const _HpHeartBadgePainter({required this.style});

  final _CombatHpStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.88)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.64,
        size.width * 0.03,
        size.height * 0.43,
        size.width * 0.12,
        size.height * 0.23,
      )
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.02,
        size.width * 0.42,
        size.height * 0.08,
        size.width * 0.5,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.08,
        size.width * 0.78,
        size.height * 0.02,
        size.width * 0.88,
        size.height * 0.23,
      )
      ..cubicTo(
        size.width * 0.97,
        size.height * 0.43,
        size.width * 0.82,
        size.height * 0.64,
        size.width * 0.5,
        size.height * 0.88,
      )
      ..close();
    final fill = style == _CombatHpStyle.hero
        ? (Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff8d1749), Color(0xffd34165)],
            ).createShader(Offset.zero & size))
        : (Paint()..color = const Color(0xff1a1a1a));
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _HpHeartBadgePainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _PcTriangleBadgePainter extends CustomPainter {
  const _PcTriangleBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.10)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.10,
        size.width * 0.10,
        size.height * 0.23,
      )
      ..lineTo(size.width * 0.10, size.height * 0.77)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.90,
        size.width * 0.22,
        size.height * 0.90,
      )
      ..lineTo(size.width * 0.78, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height * 0.50,
        size.width * 0.78,
        size.height * 0.42,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0f706e), Color(0xff0b4c51)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CombatantStatusRow extends StatelessWidget {
  CombatantStatusRow.hero({
    required AdventureState adventure,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    this.hideCp = false,
    this.rollHistory = const [],
    super.key,
  }) : hero = adventure.hero,
       enemy = null,
       title = 'Hero',
       hp = adventure.health,
       cp = adventure.combatPoints,
       tokens = adventure.alterations,
       accent = heroAccent;

  CombatantStatusRow.enemy({
    required this.enemy,
    required this.onHp,
    required this.onCp,
    required this.onEditTokens,
    this.hideCp = false,
    this.rollHistory = const [],
    super.key,
  }) : hero = null,
       title = 'Enemy',
       hp = enemy!.health,
       cp = enemy.combatPoints,
       tokens = enemy.alterations,
       accent = enemy.rank.color;

  final HeroType? hero;
  final EnemyNode? enemy;
  final String title;
  final int hp;
  final int cp;
  final List<String> tokens;
  final Color accent;
  final VoidCallback onHp;
  final VoidCallback onCp;
  final VoidCallback onEditTokens;
  final bool hideCp;
  final List<String> rollHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hero != null)
          HeroAvatar(hero: hero!, size: 36)
        else if (enemy != null)
          EnemyRankAvatar(enemy: enemy!, size: 36),
        const SizedBox(width: 7),
        SizedBox(
          width: 68,
          child: MapStatChip(
            icon: Icons.favorite,
            label: '',
            value: hp.toString(),
            color: accent,
            accent: accent,
            borderColor: panelBorderGrey,
            onTap: onHp,
          ),
        ),
        const SizedBox(width: 6),
        if (!hideCp) ...[
          SizedBox(
            width: 68,
            child: MapStatChip(
              label: 'CP',
              value: cp.toString(),
              color: accent,
              accent: accent,
              borderColor: panelBorderGrey,
              onTap: onCp,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          flex: hideCp ? 1 : 2,
          child: CompactItemStrip(
            label: 'Tokens',
            emptyText: 'Tokens',
            items: tokens,
            accent: accent,
            background: Colors.black.withValues(alpha: 0.32),
            border: panelBorderGrey,
            trailing: IconButton(
              tooltip: 'Edit tokens',
              visualDensity: VisualDensity.compact,
              onPressed: onEditTokens,
              icon: const Icon(Icons.edit, size: 18),
            ),
          ),
        ),
      ],
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
                          enemy.alterations
                                  .where(_isVisibleStatusTokenLabel)
                                  .isEmpty
                              ? 'Tokens'
                              : enemy.alterations
                                    .where(_isVisibleStatusTokenLabel)
                                    .join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add token',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final values = await showAlterationDialog(
                            context,
                            enemy.alterations,
                            forMinion: true,
                            duelTokens: enemy.alterations,
                          );
                          if (values != null) {
                            setState(() {
                              enemy.alterations
                                ..clear()
                                ..addAll(values);
                            });
                            widget.onChanged();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _editing == 'HP' ? Icons.favorite : Icons.bolt,
                          color: _editing == 'HP'
                              ? enemy.rank.color
                              : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editing!,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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
                    width: 88,
                    child: FilledButton(
                      onPressed: _saveEnemyStat,
                      child: const Text('Save'),
                    ),
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
      enemy.health = _draftValue.clamp(0, 99);
    } else if (_editing == 'CP') {
      enemy.combatPoints = _draftValue.clamp(0, 99);
    }
    setState(() => _editing = null);
    widget.onChanged();
  }
}

class TurnPhasePanel extends StatelessWidget {
  const TurnPhasePanel({
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.primaryEnemy,
    this.secondaryEnemy,
    required this.upkeepApplied,
    required this.heroUpkeepApplied,
    this.canAdvance = true,
    required this.onPhaseChanged,
    required this.onNext,
    required this.onApplyUpkeep,
    required this.onApplyHeroUpkeep,
    super.key,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final EnemyNode primaryEnemy;
  final EnemyNode? secondaryEnemy;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;
  final bool canAdvance;
  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;

  @override
  Widget build(BuildContext context) {
    final poisonCount = enemy.alterations
        .where((token) => token == 'Poison')
        .length;
    final heroHasSilence = adventure.alterations.contains('Silence');
    final heroHasHemorrhage = adventure.alterations.contains('Hémorragie');
    final heroHasRonces = adventure.alterations.contains('Ronces');
    final enemyHasRiposte = enemy.alterations.contains('Riposte');
    const nextColor = Color(0xff8f43ff);
    final reminder = switch (phase) {
      CombatPhase.heroUpkeep => [
        if (heroHasHemorrhage) 'Hémorragie',
        if (heroHasRonces) 'Ronces',
      ].join(' | '),
      CombatPhase.hero => [
        if (enemyHasRiposte) 'Riposte',
        if (heroHasSilence) 'Silence',
      ].join(' | '),
      CombatPhase.minionUpkeep => poisonCount > 0 ? 'Poison x$poisonCount' : '',
      CombatPhase.minionAttack => '',
      CombatPhase.intro => 'Intro',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactPhaseSelector(
                  phase: phase,
                  adventure: adventure,
                  enemy: enemy,
                  primaryEnemy: primaryEnemy,
                  secondaryEnemy: secondaryEnemy,
                  onPhaseChanged: phase == CombatPhase.intro
                      ? (_) {}
                      : onPhaseChanged,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 44,
                child: _IntroPulse(
                  active: phase == CombatPhase.intro,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: nextColor,
                      foregroundColor: Colors.black,
                    ),
                    tooltip: phase == CombatPhase.intro
                        ? 'Start fight'
                        : (phase == CombatPhase.minionUpkeep &&
                                  !upkeepApplied) ||
                              (phase == CombatPhase.heroUpkeep &&
                                  !heroUpkeepApplied)
                        ? 'Apply upkeep and continue'
                        : 'Next phase',
                    onPressed: canAdvance ? onNext : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ],
          ),
          if (reminder.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reminder,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: heroAccent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IntroPulse extends StatefulWidget {
  const _IntroPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_IntroPulse> createState() => _IntroPulseState();
}

class _IntroPulseState extends State<_IntroPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final Animation<double> _animation = Tween<double>(
    begin: 0.55,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _IntroPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.scale(
          scale: 0.96 + _animation.value * 0.04,
          child: child,
        ),
      ),
    );
  }
}

class _CompactPhaseSelector extends StatelessWidget {
  const _CompactPhaseSelector({
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.primaryEnemy,
    this.secondaryEnemy,
    required this.onPhaseChanged,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final EnemyNode primaryEnemy;
  final EnemyNode? secondaryEnemy;
  final ValueChanged<CombatPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryEnemy;
    if (secondary != null && !primaryEnemy.defeated && !secondary.defeated) {
      return Row(
        children: [
          _phaseSlot(
            phaseValue: CombatPhase.heroUpkeep,
            selected: phase == CombatPhase.heroUpkeep,
            accent: heroAccent,
            child: _PhasePortraitIcon(
              asset: adventure.hero.asset,
              alignment: _heroEyeAlignment(adventure.hero),
              scale: adventure.hero.imageScale,
            ),
          ),
          _phaseSlot(
            phaseValue: CombatPhase.hero,
            selected: phase == CombatPhase.hero,
            accent: heroAccent,
            child: const _UpkeepCubeIcon(size: 24),
          ),
          _phaseSlot(
            phaseValue: CombatPhase.minionUpkeep,
            selected:
                phase == CombatPhase.minionUpkeep && enemy.id == secondary.id,
            accent: secondary.rank.color,
            child: _PhasePortraitIcon(
              asset: secondary.previewAsset,
              alignment: _minionEyeAlignment(secondary),
              fit: _minionEyeFit(secondary),
            ),
          ),
          _phaseSlot(
            phaseValue: CombatPhase.minionUpkeep,
            selected:
                phase == CombatPhase.minionUpkeep &&
                enemy.id == primaryEnemy.id,
            accent: primaryEnemy.rank.color,
            child: _PhasePortraitIcon(
              asset: primaryEnemy.profileKey == 'naraxus'
                  ? 'assets/enemy_previews/naxarus_head.png'
                  : primaryEnemy.previewAsset,
              alignment: _minionEyeAlignment(primaryEnemy),
              fit: _minionEyeFit(primaryEnemy),
            ),
          ),
          _phaseSlot(
            phaseValue: CombatPhase.minionAttack,
            selected:
                phase == CombatPhase.minionAttack &&
                enemy.id == primaryEnemy.id,
            accent: primaryEnemy.rank.color,
            child: const _UpkeepCubeIcon(size: 24),
          ),
        ],
      );
    }

    final phases = CombatPhase.values
        .where((value) => value != CombatPhase.intro)
        .toList();
    return Row(
      children: phases.map((value) {
        final selected = phase != CombatPhase.intro && value == phase;
        final accent = _phaseColor(value, enemy);
        return _phaseSlot(
          phaseValue: value,
          selected: selected,
          accent: accent,
          child: switch (value) {
            CombatPhase.heroUpkeep => _PhasePortraitIcon(
              asset: adventure.hero.asset,
              alignment: _heroEyeAlignment(adventure.hero),
              scale: adventure.hero.imageScale,
            ),
            CombatPhase.minionUpkeep => _PhasePortraitIcon(
              asset: enemy.profileKey == 'naraxus'
                  ? 'assets/enemy_previews/naxarus_head.png'
                  : enemy.previewAsset,
              alignment: _minionEyeAlignment(enemy),
              fit: _minionEyeFit(enemy),
            ),
            _ => const _UpkeepCubeIcon(size: 27),
          },
        );
      }).toList(),
    );
  }

  Widget _phaseSlot({
    required CombatPhase phaseValue,
    required bool selected,
    required Color accent,
    required Widget child,
  }) {
    final disabled = phase == CombatPhase.intro;
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => onPhaseChanged(phaseValue),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selected ? 30 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 5),
              Opacity(
                opacity: disabled ? 0.38 : 1,
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: disabled ? Colors.white24 : accent,
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhasePortraitIcon extends StatelessWidget {
  const _PhasePortraitIcon({
    required this.asset,
    required this.alignment,
    this.scale = 1,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Alignment alignment;
  final double scale;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          asset,
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          alignment: alignment,
        ),
      ),
    );
  }
}

Color _phaseColor(CombatPhase phase, EnemyNode enemy) {
  return switch (phase) {
    CombatPhase.intro => const Color(0xff8f43ff),
    CombatPhase.heroUpkeep || CombatPhase.hero => heroAccent,
    CombatPhase.minionUpkeep || CombatPhase.minionAttack => enemy.rank.color,
  };
}

enum DieSymbol { white, yellow, red }

DieSymbol _symbolForFace(int face) {
  if (face == 6) {
    return DieSymbol.red;
  }
  if (face >= 4) {
    return DieSymbol.yellow;
  }
  return DieSymbol.white;
}

class GameDie {
  GameDie({required this.id});

  final int id;
  int? value;
  bool reserved = false;
  bool settled = true;
  int rollTick = 0;

  DieSymbol? get symbol {
    final face = value;
    if (face == null) {
      return null;
    }
    return _symbolForFace(face);
  }
}

class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.dice,
    required this.diceToRoll,
    required this.visibleDiceCount,
    required this.maxDiceCount,
    required this.rollCount,
    required this.maxRolls,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.specialAttackMode,
    required this.onDiceToRollChanged,
    required this.onRoll,
    required this.onTapDie,
    required this.onSelectFace,
    required this.onValidateEdit,
    required this.onToggleEdit,
    required this.onToggleRerollOne,
    required this.rollLabel,
    required this.rollColor,
    super.key,
  });

  final List<GameDie> dice;
  final int diceToRoll;
  final int visibleDiceCount;
  final int maxDiceCount;
  final int rollCount;
  final int maxRolls;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final bool specialAttackMode;
  final ValueChanged<int> onDiceToRollChanged;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;
  final String rollLabel;
  final Color rollColor;

  @override
  Widget build(BuildContext context) {
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 6)).toList();
    final hasRollingDice = visibleDice.any((die) => !die.settled);
    final rollDice = visibleDice.where((die) => !die.reserved).toList();
    final reserveDice = visibleDice.where((die) => die.reserved).toList();
    if (!hasRollingDice) {
      rollDice.sort(_compareDice);
      reserveDice.sort(_compareDice);
    }
    final editingDie = editingDieId == null
        ? null
        : dice.firstWhere((die) => die.id == editingDieId);

    return _DiceBackgroundBand(
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
                items: List.generate(maxDiceCount.clamp(0, 5) + 1, (i) => i)
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: onToggleEdit,
                icon: const Icon(Icons.tune),
                label: Text(editMode ? 'Stop edit' : 'Edit a die'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: onToggleRerollOne,
                icon: const Icon(Icons.refresh),
                label: Text(rerollOneMode ? 'Choose a die' : 'Reroll one die'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DiceZone(title: 'Dice to roll', dice: rollDice, onTapDie: onTapDie),
          const SizedBox(height: 6),
          Row(
            children: [
              if (maxRolls > 1) ...[
                Text(
                  '$rollCount / $maxRolls',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _SolidRollButton(
                  onPressed:
                      !hasRollingDice && rollCount < maxRolls && diceToRoll > 0
                      ? onRoll
                      : null,
                  color: rollColor,
                  child: Text(rollLabel),
                ),
              ),
              const _CubeIcon(size: 28),
            ],
          ),
          const SizedBox(height: 6),
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

class _SolidRollButton extends StatelessWidget {
  const _SolidRollButton({
    required this.color,
    required this.onPressed,
    required this.child,
  });

  final Color color;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.28),
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.42),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      onPressed: onPressed,
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.w900),
        child: child,
      ),
    );
  }
}

int _compareDice(GameDie a, GameDie b) {
  final av = a.value ?? 99;
  final bv = b.value ?? 99;
  final byValue = av.compareTo(bv);
  return byValue == 0 ? a.id.compareTo(b.id) : byValue;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            children: [
              for (final die in dice) ...[
                DieTile(
                  die: die,
                  onTap: die.settled ? () => onTapDie(die) : null,
                ),
                const SizedBox(width: 5),
              ],
              if (dice.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '--',
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class DieTile extends StatefulWidget {
  const DieTile({
    required this.die,
    required this.onTap,
    this.compact = false,
    this.highlight = false,
    this.highlightColor,
    this.onAnimationDone,
    super.key,
  });

  final GameDie die;
  final VoidCallback? onTap;
  final bool compact;
  final bool highlight;
  final Color? highlightColor;
  final VoidCallback? onAnimationDone;

  @override
  State<DieTile> createState() => _DieTileState();
}

class _DieTileState extends State<DieTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _faceTimer;
  int? _animatedValue;
  int _lastRollTick = 0;
  final Random _animationRandom = Random();

  @override
  void initState() {
    super.initState();
    _lastRollTick = widget.die.rollTick;
    _animatedValue = widget.die.value;
    _controller =
        AnimationController(
          vsync: this,
          duration: Duration(
            seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt(),
          ),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _faceTimer?.cancel();
            if (mounted) {
              setState(() => _animatedValue = widget.die.value);
            }
            widget.onAnimationDone?.call();
          }
        });
  }

  @override
  void didUpdateWidget(covariant DieTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.die.rollTick != _lastRollTick && widget.die.value != null) {
      _lastRollTick = widget.die.rollTick;
      _startRollAnimation();
    } else if (!_controller.isAnimating) {
      _animatedValue = widget.die.value;
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startRollAnimation() {
    _faceTimer?.cancel();
    if (combatDiceAnimationSeconds <= 0) {
      _controller.stop();
      if (mounted) {
        setState(() => _animatedValue = widget.die.value);
      }
      return;
    }
    _controller.duration = Duration(
      seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt(),
    );
    if (mounted) {
      setState(() => _animatedValue = _animationRandom.nextInt(6) + 1);
    }
    _controller
      ..reset()
      ..forward();
    _faceTimer = Timer.periodic(const Duration(milliseconds: 95), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _animatedValue = _animationRandom.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 40.0 : 50.0;
    final value = !widget.die.settled || _controller.isAnimating
        ? _animatedValue
        : widget.die.value;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final turn = _controller.value * 10.0 * pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(turn),
                child: child,
              );
            },
            child: Container(
              width: size,
              height: size,
              constraints: BoxConstraints(maxWidth: size),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value == null ? Colors.white12 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: widget.highlight
                    ? Border.all(
                        color: widget.highlightColor ?? heroAccent,
                        width: 3,
                      )
                    : null,
                boxShadow: widget.highlight
                    ? [
                        BoxShadow(
                          color: (widget.highlightColor ?? heroAccent)
                              .withValues(alpha: 0.72),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: value == null
                  ? const Text(
                      '-',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Image.asset(
                      'assets/dice_faces/face_$value.webp',
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          if (widget.highlight)
            Positioned(
              right: -4,
              top: -5,
              child: Icon(
                Icons.check_circle,
                color: widget.highlightColor ?? heroAccent,
                size: widget.compact ? 16 : 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _CombatResolutionPanel extends StatelessWidget {
  const _CombatResolutionPanel({
    required this.adventure,
    required this.enemy,
    required this.allFightEnemiesDefeated,
    required this.onHistory,
    required this.onHomepage,
    required this.onRewardFinished,
    required this.onReview,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final bool allFightEnemiesDefeated;
  final VoidCallback onHistory;
  final VoidCallback onHomepage;
  final VoidCallback onRewardFinished;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final heroDead = adventure.health <= 0;
    final enemyDead = enemy.health <= 0;
    final isNaraxus = enemy.profileKey == 'naraxus';

    final String title;
    final Color titleColor;
    if (heroDead && enemyDead) {
      title = 'Tie!';
      titleColor = Colors.orange;
    } else if (heroDead) {
      title = 'Defeat!';
      titleColor = Colors.redAccent;
    } else {
      title = 'Victory!';
      titleColor = Colors.green;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
        ),
        if (heroDead && enemyDead && isNaraxus)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '50 Victory Points awarded for a tie against Naraxus!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        if (!heroDead && enemyDead && !isNaraxus && allFightEnemiesDefeated)
          RewardPanel(
            adventure: adventure,
            enemy: enemy,
            onFinished: onRewardFinished,
          )
        else
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onHistory,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8f43ff),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Save & History'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onHomepage,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8f43ff),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Homepage'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onReview,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            minimumSize: const Size.fromHeight(40),
          ),
          child: const Text('Revenir en arrière (Review log)'),
        ),
      ],
    );
  }
}
