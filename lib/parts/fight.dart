part of '../main.dart';

class FightPage extends StatefulWidget {
  const FightPage({
    required this.adventure,
    required this.historyRecords,
    required this.enemyId,
    required this.onChanged,
    required this.onPauseExit,
    required this.onAbandon,
    this.onFinished,
    this.onGameOverHome,
    this.onGameOverHistory,
    super.key,
  });

  final AdventureState adventure;
  final List<GameRecord> historyRecords;
  final int enemyId;
  final VoidCallback onChanged;
  final VoidCallback onPauseExit;
  final VoidCallback onAbandon;
  final VoidCallback? onFinished;
  final VoidCallback? onGameOverHome;
  final VoidCallback? onGameOverHistory;

  @override
  State<FightPage> createState() => _FightPageState();
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
  bool _aiMode = true;
  bool _showManualExtraDicePhase = false;
  bool _gameOverDialogShown = false;
  int _battleAttackValue = 0;
  int _battleDefenseValue = 0;
  int _battleReturnDamage = 0;
  int _battleLifeSteal = 0;
  int _battleEnemyHeal = 0;
  int _battleCpSteal = 0;
  int _heroAttackCount = 0;
  int _heroAttackTotal = 0;
  int _lastHeroAttack = 0;
  String _lastBattleOutcomeMessage = '';
  String _extraDiceOutcomeMessage = '';
  final List<String> _battleHeroTokens = [];
  final List<String> _battleMinionTokens = [];
  final List<String> _battleNotes = [];
  final List<String> _naraxusRollHistory = [];

  EnemyNode get enemy => widget.adventure.enemyById(widget.enemyId);

  bool get _isNaraxus => enemy.profileKey == 'naraxus';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      _dice.add(GameDie(id: i));
    }
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
    _combatScrollController.dispose();
    super.dispose();
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
        (_phase != CombatPhase.hero || _battleAttackValue == 0);
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _openPauseDialog();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CombatBottomDock(
                phase: _phase,
                adventure: widget.adventure,
                enemy: enemy,
                upkeepApplied: _upkeepApplied,
                heroUpkeepApplied: _heroUpkeepApplied,
                canAdvancePhase: canAdvancePhase,
                onPhaseChanged: _setPhase,
                onNext: _advancePhase,
                onApplyUpkeep: _applyUpkeep,
                onApplyHeroUpkeep: _applyHeroUpkeep,
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
                    EnemyRulesPanel(
                      enemy: enemy,
                      phase: _phase,
                      aiMode: _aiMode,
                      onDetails: _openAdventureDetails,
                      onAbandon: _openPauseDialog,
                      onExport: _openCombatExport,
                      attackKey: _attackRulesKey,
                      defenseKey: _defenseRulesKey,
                      onAiModeChanged: (value) {
                        setState(() {
                          _aiMode = value;
                          _configureDiceForPhase(
                            autoRollAttack:
                                _aiMode && _phase == CombatPhase.minionAttack,
                          );
                        });
                      },
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
                      if (_showAiExtraDicePhase) ...[
                        const SizedBox(height: 12),
                        ManualExtraDicePhasePanel(
                          key: _extraDicePhaseKey,
                          title: _extraDicePhaseTitle,
                          initialDiceCount: _extraDiceCount,
                          accent: enemy.rank.color,
                          autoRoll: !_isNaraxus,
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
                ),
              ),
              CombatAiChatDock(
                aiMode: _aiMode,
                aiMessage: aiMessage,
                phase: _phase,
                adventure: widget.adventure,
                enemy: enemy,
                returnDamage: _battleReturnDamage,
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
                onFinish:
                    enemy.health <= 0 ||
                        (_isNaraxus && widget.adventure.health <= 0)
                    ? _finishCombat
                    : null,
                onChanged: () {
                  widget.onChanged();
                  setState(() {});
                },
              ),
            ],
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
    setState(() {
      final rollable = _dice
          .where((die) => !die.reserved)
          .take(_diceToRoll)
          .toList();
      for (final die in rollable) {
        die.value = _random.nextInt(6) + 1;
        die.rollTick++;
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
      if (_phase == CombatPhase.minionAttack && _aiMode) {
        _applyMinionDiceStrategy();
      }
      _refreshBattleResolutionFromDice();
      widget.onChanged();
      if (_rollCount == _maxRolls) {
        _specialAttackReady = _shouldResolveSpecialAttack();
      }
    });
    if (_showAiExtraDicePhase) {
      _scrollToRulesKey(_extraDicePhaseKey);
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
    if (phase == CombatPhase.hero) {
      _scrollToRulesKey(_defenseRulesKey);
    } else if (phase == CombatPhase.minionAttack) {
      _scrollToRulesKey(_attackRulesKey);
    }
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

  void _advancePhase() {
    final next = switch (_phase) {
      CombatPhase.intro => _firstCombatPhaseFor(enemy),
      CombatPhase.heroUpkeep => CombatPhase.hero,
      CombatPhase.hero => CombatPhase.minionUpkeep,
      CombatPhase.minionUpkeep => CombatPhase.minionAttack,
      CombatPhase.minionAttack => CombatPhase.heroUpkeep,
    };
    _setPhase(next);
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
    _editingDieId = null;
    _editMode = false;
    _rerollOneMode = false;
    _specialAttackReady = false;
    _specialAttackMode = false;
    for (final die in _dice) {
      die
        ..value = null
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
    if (!_aiMode || _phase != CombatPhase.minionAttack || _rollCount == 0) {
      return false;
    }
    if (_specialAttackReady) {
      return true;
    }
    if (_isNaraxus) {
      final value = _dice.first.value;
      return value == 3 || value == 6;
    }
    return _attackNeedsExtraDice(enemy) && _currentAttackGoalMet();
  }

  int get _extraDiceCount {
    if (_isNaraxus && _dice.first.value == 3) {
      return 4;
    }
    if (_isNaraxus && _dice.first.value == 6) {
      return 1;
    }
    return _extraDiceCountFor(enemy);
  }

  String get _extraDicePhaseTitle {
    if (_isNaraxus && _dice.first.value == 3) {
      return 'Gashing Bite extra roll';
    }
    if (_isNaraxus && _dice.first.value == 6) {
      return "Dragon's Might extra roll";
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
    _battleReturnDamage = 0;
    _battleLifeSteal = 0;
    _battleEnemyHeal = 0;
    _battleCpSteal = 0;
    _battleHeroTokens.clear();
    _battleMinionTokens.clear();
    _battleNotes.clear();
    _extraDiceOutcomeMessage = '';
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
    var lifeSteal = 0;
    final notes = <String>[];
    final heroTokens = <String>[];

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
        notes.add('Defense: returns $returnDamage damage.');
      case 'enchanteur-gobelin':
        if (yellow > 0) {
          returnDamage = 1;
          notes.add('Defense: orange symbol returns 1 damage.');
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
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
        }
        if (returnDamage > 0) {
          notes.add('Defense: returns $returnDamage damage.');
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
      case 'vert-vert-015':
        if (red > 0) {
          returnDamage = (_battleAttackValue / 2).ceil();
          notes.add('Defense: red returns half the damage.');
        }
      case 'vert-vert-017':
        if (white > 0) {
          returnDamage = 2;
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
        returnDamage = white;
        prevented = yellow + red;
        if (returnDamage > 0) {
          notes.add('Defense: white returns $returnDamage damage.');
        }
        if (prevented > 0) {
          notes.add('Defense: prevents $prevented damage.');
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
        lifeSteal = red;
        if (lifeSteal > 0) {
          notes.add('Defense: steals $lifeSteal HP.');
        }
      default:
        notes.add('Defense rolled. Check the minion card for exact effects.');
    }

    if (prevented == 0 &&
        returnDamage == 0 &&
        lifeSteal == 0 &&
        heroTokens.isEmpty) {
      notes.add('Defense roll failed.');
    }

    _battleDefenseValue = prevented.clamp(0, 99);
    _battleReturnDamage = returnDamage.clamp(0, 99);
    _battleLifeSteal = lifeSteal.clamp(0, 99);
    _battleEnemyHeal = 0;
    _battleHeroTokens
      ..clear()
      ..addAll(heroTokens);
    _battleNotes
      ..clear()
      ..addAll(notes);
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
    var lifeSteal = 0;
    var cpSteal = 0;

    if (_attackNeedsExtraDice(enemy) && _currentAttackGoalMet()) {
      notes.add('Attack ready: resolve the extra dice phase before applying.');
    } else if (enemy.profileKey == 'oni-delirant' &&
        _symbolGoalMet(const SymbolGoal(yellow: 4))) {
      notes.add('Attack ready: roll 1 die to choose the Oni effect.');
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

    switch (enemy.profileKey) {
      case 'fee':
        if (_bestSuiteLength(values) >= 5) {
          cpSteal = 1;
          notes.add('Large suite: steal 1 CP.');
        }
      case 'elfe-du-chaos':
        if (_bestSuiteLength(values) >= 5) {
          heroTokens.add('Ronces');
          notes.add('Large suite: hero receives Ronces.');
        }
      case 'archer-de-lombre':
        if (hasThreeSameValue) {
          heroTokens.add('Silence');
          notes.add('3 identical values: hero receives Silence.');
        }
      case 'ombre-feline':
        if (hasThreeSameValue) {
          heroTokens.add('Hémorragie');
          notes.add('3 identical values: hero receives Hemorragie.');
        }
      case 'ronin-vagabond':
        if (hasFourSameSymbol) {
          minionTokens.add('Riposte');
          notes.add('4 identical symbols: minion gains Riposte.');
        }
      case 'oni-delirant':
        if (_symbolGoalMet(const SymbolGoal(yellow: 4))) {
          attack = 0;
          lifeSteal = 0;
        }
      case 'vert-vert-013':
        if (_symbolGoalMet(const SymbolGoal(white: 3, red: 1))) {
          heroTokens.add('Poison');
          notes.add('Validated attack: hero receives Poison.');
        }
      case 'vert-vert-018':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 1))) {
          heroTokens.add('Enchevêtrement');
          notes.add('Validated attack: hero receives Enchevêtrement.');
        }
      case 'vert-vert-020':
        if (_bestSuiteLength(values) >= 5) {
          heroTokens.add('À Terre');
          notes.add('Large suite: hero receives À Terre.');
        }
      case 'bleu-vert-022':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 2, red: 1))) {
          heroTokens.add('Parasite');
          notes.add('Validated attack: hero receives Parasite.');
        } else if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 2))) {
          heroTokens.add('Poison');
          notes.add('Validated attack: hero receives Poison.');
        }
      case 'bleu-vert-023':
        if (_symbolGoalMet(const SymbolGoal(white: 2, yellow: 1, red: 1))) {
          attack = 0;
          lifeSteal = 2;
          notes.add('Validated attack: steals 2 HP.');
        }
    }

    _battleAttackValue = attack.clamp(0, 99);
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
        enemyHeal = 4;
        _removeRandomEnemyToken();
        notes.add('Swoop: Naxarus removes 1 random token and heals 4 HP.');
        notes.add('Swoop: 3 undefendable damage.');
      case 2:
        attack = 8;
        notes.add('Ember Spark: hero moves top 3 deck cards to discard.');
        notes.add('Ember Spark: 8 damage.');
      case 3:
        attack = 0;
        notes.add(
          'Gashing Bite: the player rolls 4 dice in the extra dice phase.',
        );
        notes.add(
          'Damage will equal the 2 highest dice after hero interactions.',
        );
      case 4:
        attack = 9;
        heroTokens.add('Hoarding');
        notes.add('Hoarding: hero loses 1 die on the next battle roll.');
        notes.add('Hoarding: 9 damage.');
      case 5:
        attack = 8;
        notes.add('Thundering Roar: hero discards 1 card.');
        notes.add('Thundering Roar: 8 undefendable damage.');
      case 6:
        attack = 10;
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
    if (!_isNaraxus || _phase != CombatPhase.minionAttack) {
      return;
    }
    final baseAttack = _dice.first.value;
    final values =
        extraDice
            .where((die) => die.value != null)
            .map((die) => die.value!)
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (values.isEmpty) {
      return;
    }
    setState(() {
      if (baseAttack == 3) {
        final topTwo = values.take(2).toList();
        final damage = topTwo.fold<int>(0, (sum, value) => sum + value);
        _battleAttackValue = damage.clamp(0, 99);
        _battleEnemyHeal = 0;
        _battleHeroTokens.clear();
        _battleNotes
          ..clear()
          ..add(
            'Gashing Bite: top dice ${topTwo.join(' + ')} deal $damage damage.',
          );
        _extraDiceOutcomeMessage =
            'Gashing Bite extra roll: ${values.reversed.join('/')}.\n'
            'Naxarus inflicts $damage damage with the 2 highest dice (${topTwo.join(' + ')}).';
      } else if (baseAttack == 6) {
        final extra = values.first;
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

  void _applyBattleResolution() {
    if (!_isBattlePhase) {
      return;
    }
    late final CombatPhase nextPhase;
    setState(() {
      final netDamage = max(0, _battleAttackValue - _battleDefenseValue);
      if (_phase == CombatPhase.hero) {
        enemy.health = (enemy.health - netDamage).clamp(0, 99);
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
              '${enemy.label} prevented $_battleDefenseValue damage.\n'
              'Net damage: deals $netDamage damage.'
              '${_battleReturnDamage > 0 ? ' Return damage: $_battleReturnDamage.' : ''}'
              '${_battleLifeSteal > 0 ? ' Life steal: $_battleLifeSteal.' : ''}'
              '${_battleHeroTokens.isNotEmpty ? ' Hero receives ${_battleHeroTokens.join(', ')}.' : ''}'
              '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}';
        }
        _heroAttackCount++;
        _heroAttackTotal += _battleAttackValue;
        _lastHeroAttack = _battleAttackValue;
        nextPhase = CombatPhase.minionUpkeep;
      } else {
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
            '${widget.adventure.hero.label} prevented $_battleDefenseValue damage.\n'
            'Net damage: deals $netDamage damage.'
            '${_battleHeroTokens.isNotEmpty ? ' ${widget.adventure.hero.label} receives ${_battleHeroTokens.join(', ')}.' : ''}'
            '${_battleMinionTokens.isNotEmpty ? ' ${enemy.label} receives ${_battleMinionTokens.join(', ')}.' : ''}'
            '${_battleEnemyHeal > 0 ? ' ${enemy.label} heals $_battleEnemyHeal HP.' : ''}'
            '${_battleCpSteal > 0 ? ' ${enemy.label} steals $_battleCpSteal CP.' : ''}';
        nextPhase = CombatPhase.heroUpkeep;
      }
      widget.onChanged();
    });
    _maybeShowGameOverDialog();
    if (widget.adventure.health <= 0 || (_isNaraxus && enemy.health <= 0)) {
      return;
    }
    _setPhase(nextPhase);
  }

  void _applyHeroUpkeep() {
    if (!mounted || _heroUpkeepApplied || _phase != CombatPhase.heroUpkeep) {
      return;
    }
    setState(() {
      _heroUpkeepApplied = true;
      final poisonCount = widget.adventure.alterations
          .where((token) => token == 'Poison')
          .length;
      widget.adventure.setHeroPc(
        widget.adventure.combatPoints + GameEngine.combatPointStartGain(),
      );
      var upkeepLog = '${widget.adventure.hero.label} gains 1 CP';
      if (poisonCount > 0) {
        widget.adventure.setHeroHealth(widget.adventure.health - poisonCount);
        upkeepLog += ', loses $poisonCount HP from Poison';
      }
      if (widget.adventure.alterations.contains('Hémorragie')) {
        upkeepLog += '. Hémorragie requires a manual upkeep roll';
      }
      widget.adventure.log('$upkeepLog.');
      widget.onChanged();
    });
    _maybeShowGameOverDialog();
  }

  void _applyUpkeep() {
    if (_upkeepApplied) {
      return;
    }
    setState(() {
      final outcome = GameEngine.minionUpkeep(
        tokens: enemy.alterations,
        rollD6: () => _random.nextInt(6) + 1,
      );
      final cpDelta = _isNaraxus ? 0 : outcome.cpDelta;
      enemy.combatPoints = (enemy.combatPoints + cpDelta).clamp(0, 99);
      enemy.health = (enemy.health + outcome.healthDelta).clamp(0, 99);
      for (final token in outcome.removedTokens) {
        enemy.alterations.remove(token);
      }
      _upkeepApplied = true;
      final upkeepLog = _isNaraxus ? _naxarusUpkeepLog(outcome) : outcome.log;
      if (upkeepLog.isNotEmpty) {
        widget.adventure.log('${enemy.label} upkeep: $upkeepLog.');
      }
      _lastBattleOutcomeMessage = '';
      widget.onChanged();
    });
    if (enemy.health <= 0) {
      if (!_isNaraxus) {
        _finishCombat();
      } else {
        _maybeShowGameOverDialog();
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
          ..reserved = true;
      }
      _dice.first
        ..value = roll
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
    _maybeShowGameOverDialog();
  }

  void _finishCombat() {
    if (_isNaraxus) {
      widget.onFinished?.call();
      return;
    }
    widget.adventure.completeCombat(enemy);
    widget.onChanged();
    if (enemy.defeated && widget.adventure.health > 0) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pop(false);
  }

  void _maybeShowGameOverDialog() {
    if (_gameOverDialogShown || !mounted) {
      return;
    }
    final isGameOver =
        widget.adventure.health <= 0 || (_isNaraxus && enemy.health <= 0);
    if (!isGameOver) {
      return;
    }
    _gameOverDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final action = await showDialog<_GameOverAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(_isNaraxus ? 'Battle finished' : 'Run finished'),
          content: Text(
            widget.adventure.health <= 0
                ? '${widget.adventure.hero.label} has no HP left.'
                : '${enemy.label} has no HP left.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_GameOverAction.newGame),
              child: const Text('New game'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_GameOverAction.history),
              child: const Text('History'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_GameOverAction.quit),
              child: const Text('Quit'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) {
        return;
      }
      switch (action) {
        case _GameOverAction.newGame:
          if (_isNaraxus) {
            widget.onFinished?.call();
          } else {
            widget.onGameOverHome?.call();
          }
        case _GameOverAction.history:
          if (_isNaraxus) {
            widget.onGameOverHistory?.call();
          } else {
            widget.onGameOverHistory?.call();
          }
        case _GameOverAction.quit:
          if (_isNaraxus) {
            widget.onFinished?.call();
          } else {
            widget.onGameOverHome?.call();
          }
          SystemNavigator.pop();
      }
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

enum _GameOverAction { newGame, history, quit }

class CompactItemStrip extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final displayItems = compactDuplicates
        ? _compactItemModels(items)
        : items
              .map(
                (value) => CompactItemModel(
                  label: value,
                  tooltip: value,
                  rewardCardColor: _rewardCardColor(value),
                ),
              )
              .toList();
    final displayLabel = items.isEmpty ? emptyText : '';
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabel = items.isEmpty || constraints.maxWidth >= 190;

          return Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              if (showLabel && displayLabel.isNotEmpty) ...[
                Text(
                  displayLabel,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: displayItems.isEmpty
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...displayItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(item.tooltip)),
                                    );
                                  },
                                  child: Tooltip(
                                    message: item.tooltip,
                                    child: item.rewardCardColor == null
                                        ? CompactItemBadge(
                                            value: item.label,
                                            color: accent,
                                          )
                                        : RewardCardBadge(
                                            color: item.rewardCardColor!,
                                            tooltip: item.tooltip,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              ?trailing,
            ],
          );
        },
      ),
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

class CompactItemBadge extends StatelessWidget {
  const CompactItemBadge({required this.value, required this.color, super.key});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
    required this.onAiModeChanged,
    required this.onDetails,
    required this.onAbandon,
    required this.onExport,
    this.attackKey,
    this.defenseKey,
    super.key,
  });

  final EnemyNode enemy;
  final CombatPhase phase;
  final bool aiMode;
  final ValueChanged<bool> onAiModeChanged;
  final VoidCallback onDetails;
  final VoidCallback onAbandon;
  final VoidCallback onExport;
  final Key? attackKey;
  final Key? defenseKey;

  @override
  State<EnemyRulesPanel> createState() => _EnemyRulesPanelState();
}

class _EnemyRulesPanelState extends State<EnemyRulesPanel> {
  bool _showAttack = false;
  bool _showDefense = false;

  EnemyNode get enemy => widget.enemy;

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
      child: MinionAttackSummary(enemy: enemy),
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
      child: MinionDefenseSummary(enemy: enemy),
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
                      child: Text(
                        enemy.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: enemy.rank.color,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Combat settings',
                    onPressed: () => _openSettings(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: panelBorderGrey),
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
      ],
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => SafeArea(
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(
                    width: 112,
                    child: Text(
                      'Control',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: _AiModeSwitch(
                      enabled: widget.aiMode,
                      color: Colors.white,
                      onChanged: widget.onAiModeChanged,
                    ),
                  ),
                ],
              ),
            ],
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

class _AiModeSwitch extends StatelessWidget {
  const _AiModeSwitch({
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStatePropertyAll(BorderSide(color: color)),
      ),
      segments: const [
        ButtonSegment(value: true, label: Text('AI')),
        ButtonSegment(value: false, label: Text('Manual')),
      ],
      selected: {enabled},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _RulesBackgroundBand extends StatelessWidget {
  const _RulesBackgroundBand({
    required this.asset,
    required this.child,
  });

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

class MinionAttackSummary extends StatelessWidget {
  const MinionAttackSummary({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    if (enemy.profileKey == 'naraxus') {
      return _NaxarusAttackSummary(enemy: enemy);
    }
    if (enemy.profileKey == 'oni-delirant') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'If successful, roll 1 die',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const _ResultLine(
            symbol: DieSymbol.white,
            children: [DamageBadge(value: 5, imparable: true)],
          ),
          const _ResultLine(
            symbol: DieSymbol.yellow,
            children: [DamageBadge(value: 6, imparable: true)],
          ),
          _ResultLine(
            symbol: DieSymbol.red,
            children: [LifeStealBadge(value: 4, color: enemy.rank.color)],
          ),
        ],
      );
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
              const DamageBadge(value: 5, imparable: false),
              TokenBadge(label: 'PO', color: enemy.rank.color),
            ],
          ),
          _AttackResultLine(
            goal: const SymbolGoal(white: 2, yellow: 2, red: 1),
            result: [
              const DamageBadge(value: 6, imparable: false),
              TokenBadge(label: 'PAR', color: enemy.rank.color),
            ],
          ),
        ],
      );
    }

    switch (enemy.attackPlan.style) {
      case MinionAttackStyle.symbols:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...enemy.attackPlan.goals.map((goal) {
              final damage = _damageForSymbolGoal(enemy, goal);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: SymbolGoalView(goal: goal)),
                    if (damage != null)
                      DamageBadge(
                        value: damage.value,
                        imparable: damage.imparable,
                      ),
                  ],
                ),
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
              damage: _suiteDamage(enemy, 3),
            ),
            _SuiteLine(
              label: 'Small',
              length: 4,
              damage: _suiteDamage(enemy, 4),
            ),
            _SuiteLine(
              label: 'Large',
              length: 5,
              damage: _suiteDamage(enemy, 5),
            ),
            ..._shortTokenHints(enemy),
          ],
        );
      case MinionAttackStyle.none:
        return Text(enemy.attacks.skip(1).join('\n'));
    }
  }

  List<Widget> _shortTokenHints(EnemyNode enemy) {
    final hints = <Widget>[];
    final text = enemy.attacks.join(' ').toLowerCase();
    if (text.contains('riposte')) {
      hints.add(const Text('If 4 identical symbols: Riposte.'));
    }
    if (text.contains('silence')) {
      hints.add(const Text('If 3 identical values: Silence.'));
    }
    if (text.contains('hémorragie')) {
      hints.add(const Text('If 3 identical values: Hémorragie.'));
    }
    if (text.contains('ronces')) {
      hints.add(const Text('If large suite: Ronces.'));
    }
    if (text.contains('poison')) {
      hints.add(const Text('If condition met: Poison.'));
    }
    if (text.contains('parasite')) {
      hints.add(const Text('If condition met: Parasite.'));
    }
    if (text.contains('a terre') || text.contains('à terre')) {
      hints.add(const Text('If condition met: À Terre.'));
    }
    if (text.contains('enchevetrement') || text.contains('enchevêtrement')) {
      hints.add(const Text('If condition met: Enchevêtrement.'));
    }
    return hints;
  }
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
        Flexible(
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
  const RewardChestBadge({required this.rank, required this.count, super.key});

  final EnemyRank rank;
  final int count;

  @override
  Widget build(BuildContext context) {
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
  const MinionDefenseSummary({required this.enemy, super.key});

  final EnemyNode enemy;

  @override
  Widget build(BuildContext context) {
    if (enemy.profileKey == 'naraxus') {
      return const _NaxarusDefenseGrid();
    }
    final lines = _defenseEffectLines(enemy);
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

List<Widget> _defenseEffectLines(EnemyNode enemy) {
  final text = enemy.defense.toLowerCase();
  final lines = <Widget>[];

  void symbol(SymbolGoal goal, List<Widget> result) {
    lines.add(
      _DefenseEffectLine(
        left: SymbolGoalView(goal: goal),
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
      dieValueLine(1, const [DamageBadge(value: 1, imparable: false)]);
      dieValueLine(2, const [DamageBadge(value: 1, imparable: false)]);
      dieValueLine(3, const [DamageBadge(value: 2, imparable: false)]);
      dieValueLine(4, const [DamageBadge(value: 2, imparable: false)]);
      dieValueLine(5, const [DamageBadge(value: 3, imparable: false)]);
      dieValueLine(6, const [DamageBadge(value: 3, imparable: false)]);
      return lines;
    case 'enchanteur-gobelin':
      symbol(const SymbolGoal(yellow: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'PO', color: enemy.rank.color),
      ]);
      return lines;
    case 'archer-de-lombre':
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 3)]);
      return lines;
    case 'ombre-feline':
      symbol(const SymbolGoal(white: 1), [
        TokenBadge(label: 'HEM', color: enemy.rank.color),
      ]);
      return lines;
    case 'epeiste-egare':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(red: 1), const [
        DamageBadge(value: 1, imparable: false),
      ]);
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 1)]);
      return lines;
    case 'elfe-du-chaos':
      symbol(const SymbolGoal(yellow: 2), const [PreventBadge(value: 1)]);
      lines.add(
        const Text(
          'Prevents half the incoming damage, rounded up.',
          style: TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
        ),
      );
      return lines;
    case 'oni-delirant':
      symbol(const SymbolGoal(yellow: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
      ]);
      return lines;
    case 'vert-vert-011':
      symbol(const SymbolGoal(yellow: 1), const [_HalfPreventBadge()]);
      return lines;
    case 'vert-vert-012':
    case 'vert-vert-016':
      symbol(const SymbolGoal(yellow: 1), const [
        _MultiplierBadge(),
        PreventBadge(value: 1),
      ]);
      return lines;
    case 'vert-vert-013':
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'PO', color: enemy.rank.color),
      ]);
      return lines;
    case 'vert-vert-015':
      symbol(const SymbolGoal(red: 1), const [_HalfReturnBadge()]);
      return lines;
    case 'vert-vert-017':
      symbol(const SymbolGoal(white: 1), const [
        DamageBadge(value: 2, imparable: true),
      ]);
      return lines;
    case 'vert-vert-018':
      symbol(const SymbolGoal(yellow: 1), [
        TokenBadge(label: 'DOWN', color: enemy.rank.color),
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
        _MultiplierBadge(),
        PreventBadge(value: 1),
      ]);
      symbol(const SymbolGoal(red: 1), const [
        _MultiplierBadge(),
        PreventBadge(value: 1),
      ]);
      return lines;
    case 'bleu-vert-022':
      symbol(const SymbolGoal(yellow: 1), const [PreventBadge(value: 2)]);
      symbol(const SymbolGoal(red: 1), [
        TokenBadge(label: 'PAR', color: enemy.rank.color),
      ]);
      return lines;
    case 'bleu-vert-023':
      symbol(const SymbolGoal(red: 1), [
        LifeStealBadge(value: 1, color: enemy.rank.color),
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
    required this.returnDamage,
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
  final int returnDamage;
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
    final tokenText = [
      if (heroTokens.isNotEmpty) 'Hero: ${heroTokens.join(', ')}',
      if (minionTokens.isNotEmpty) 'Minion: ${minionTokens.join(', ')}',
      if (returnDamage > 0) 'Return damage: $returnDamage',
      if (lifeSteal > 0) 'Life steal: $lifeSteal',
      if (enemyHeal > 0 && enemy.profileKey != 'naraxus')
        'Enemy heals: $enemyHeal',
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
          if (aiMode)
            _AiChatWithHealth(
              message: _battleChatText(aiMessage, tokenText),
              accent: chatAccent,
              heroHp: adventure.health,
              enemyHp: enemy.health,
              enemyColor: enemy.rank.color,
              heroName: adventure.hero.label,
              enemyName: enemy.label,
              portraitAsset:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.asset
                  : enemy.previewAsset,
              portraitAlignment:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.imageAlignment
                  : enemy.profileKey == 'naraxus'
                  ? Alignment.center
                  : Alignment.centerLeft,
              portraitScale:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.imageScale
                  : 1,
              showHealthControls: false,
              onHeroHpSaved: (value) {
                adventure.setHeroHealth(value);
                onChanged();
              },
              onEnemyHpSaved: (value) {
                enemy.health = value.clamp(0, 99);
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

enum _HpQuickTarget { hero, enemy }

class _AiChatWithHealth extends StatefulWidget {
  const _AiChatWithHealth({
    required this.message,
    required this.accent,
    required this.heroHp,
    required this.enemyHp,
    required this.enemyColor,
    required this.heroName,
    required this.enemyName,
    required this.portraitAsset,
    required this.portraitAlignment,
    this.portraitScale = 1,
    this.showHealthControls = true,
    required this.onHeroHpSaved,
    required this.onEnemyHpSaved,
  });

  final String message;
  final Color accent;
  final int heroHp;
  final int enemyHp;
  final Color enemyColor;
  final String heroName;
  final String enemyName;
  final String portraitAsset;
  final Alignment portraitAlignment;
  final double portraitScale;
  final bool showHealthControls;
  final ValueChanged<int> onHeroHpSaved;
  final ValueChanged<int> onEnemyHpSaved;

  @override
  State<_AiChatWithHealth> createState() => _AiChatWithHealthState();
}

class _AiChatWithHealthState extends State<_AiChatWithHealth> {
  _HpQuickTarget? _target;
  late int _draftHp;

  @override
  void didUpdateWidget(covariant _AiChatWithHealth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_target == _HpQuickTarget.hero && oldWidget.heroHp != widget.heroHp) {
      _draftHp = widget.heroHp;
    } else if (_target == _HpQuickTarget.enemy &&
        oldWidget.enemyHp != widget.enemyHp) {
      _draftHp = widget.enemyHp;
    }
  }

  void _openEditor(_HpQuickTarget target) {
    setState(() {
      _target = target;
      _draftHp = target == _HpQuickTarget.hero ? widget.heroHp : widget.enemyHp;
    });
  }

  void _save() {
    final target = _target;
    if (target == null) {
      return;
    }
    final value = _draftHp.clamp(0, 99).toInt();
    if (target == _HpQuickTarget.hero) {
      widget.onHeroHpSaved(value);
    } else {
      widget.onEnemyHpSaved(value);
    }
    setState(() => _target = null);
  }

  @override
  Widget build(BuildContext context) {
    const hpWidth = 56.0;
    const editorWidth = 78.0;
    final editorColor = _target == _HpQuickTarget.hero
        ? heroAccent
        : widget.enemyColor;
    final chat = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
      ),
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
      final portrait = SizedBox(
        width: 112,
        child: ClipRect(
          child: Transform.scale(
            scale: widget.portraitScale,
            child: Image.asset(
              widget.portraitAsset,
              fit: BoxFit.cover,
              alignment: widget.portraitAlignment,
            ),
          ),
        ),
      );
      return SizedBox(
        height: chatHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.accent == heroAccent) ...[
              Expanded(child: chat),
              portrait,
            ] else ...[
              portrait,
              Expanded(child: chat),
            ],
          ],
        ),
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
                value: _draftHp,
                color: editorColor,
                onChanged: (delta) => setState(
                  () => _draftHp = (_draftHp + delta).clamp(0, 99).toInt(),
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
              onHeroTap: () => _openEditor(_HpQuickTarget.hero),
              onEnemyTap: () => _openEditor(_HpQuickTarget.enemy),
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
      child: SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            side: BorderSide(color: color, width: 1.4),
          ),
          icon: Icon(icon, size: 18, color: color),
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
    '(${RegExp.escape(heroName)}|${RegExp.escape(enemyName)}|\\{[a-zA-Z]+:[^}]+\\}|\\*\\*[^*]+\\*\\*|_[^_]+_|prevents? \\d+ damage|prevented \\d+ damage|prévents? \\d+ damage|prévient \\d+ damage|deals? \\d+ undefendable damage|dealt \\d+ undefendable damage|inflicts? \\d+ undefendable damage|inflige \\d+ undefendable damage|deals? \\d+ defendable damage|dealt \\d+ defendable damage|inflicts? \\d+ defendable damage|inflige \\d+ defendable damage|deals? \\d+ damage|dealt \\d+ damage|inflicts? \\d+ damage|inflige \\d+ damage|heals? \\d+ HP|healed \\d+ HP|\\d+ HP)',
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
  if (lower.contains('damage') || lower.contains('dégât')) {
    final verb = lower.contains('inflige')
        ? 'inflige '
        : lower.contains('inflict')
        ? 'inflicts '
        : lower.contains('dealt')
        ? 'dealt '
        : lower.contains('return')
        ? 'return '
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
          child: TokenBadge(
            label: _tokenShortLabel(rule.label),
            color: enemyColor,
          ),
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
    final isWhite = color == Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isWhite ? Colors.transparent : color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isWhite ? Colors.white : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
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
          RoundIconButton(
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
          RoundIconButton(
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
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 5)).toList()
      ..sort(_compareDice);
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
                    onTap: editMode || rerollOneMode
                        ? () => onTapDie(die)
                        : null,
                    highlight: die.reserved || editingDieId == die.id,
                    highlightColor: editingDieId == die.id
                        ? heroAccent
                        : enemy.rank.color,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (visibleDice.isNotEmpty || isDefensePhase) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: enemy.rank.color,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: rollCount < maxRolls && diceToRoll > 0 ? onRoll : null,
              child: Text(
                isDefensePhase
                    ? 'Roll defense'
                    : (rollCount == 0 ? 'Roll' : 'Reroll'),
                style: const TextStyle(fontWeight: FontWeight.w900),
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
) {
  final tokenSummary = _tokenUpkeepSummary(
    owner: enemy.label,
    tokens: enemy.alterations,
    isHero: false,
  );
  final lines = <String>[
    if (lastBattleOutcome.isNotEmpty) lastBattleOutcome,
    '**Upkeep of ${enemy.label}.**',
    if (enemy.profileKey != 'naraxus')
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
      _editingDieId = null;
      for (final die in _dice) {
        die
          ..value = null
          ..reserved = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleDice = _dice.take(_diceToRoll.clamp(0, 5)).toList();
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final die in visibleDice)
                DieTile(
                  die: die,
                  onTap: () => _tapDie(die),
                  compact: true,
                  highlightColor: _editingDieId == die.id
                      ? heroAccent
                      : die.reserved
                      ? widget.accent
                      : null,
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
                        _dice
                                .firstWhere((die) => die.id == _editingDieId)
                                .value =
                            face;
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
          ImageActionButton(
            label: _rollCount == 0 ? 'Roll' : 'Reroll',
            icon: Icons.casino,
            onPressed: _diceToRoll <= 0 ? null : _rollVisibleDice,
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
    setState(() {
      final visibleDice = _dice.take(_diceToRoll.clamp(0, 5)).toList();
      for (final die in visibleDice) {
        die.value = _random.nextInt(6) + 1;
        die.rollTick++;
      }
      _rollCount++;
    });
    widget.onChanged?.call(_dice.take(_diceToRoll.clamp(0, 5)).toList());
  }

  void _tapDie(GameDie die) {
    setState(() {
      if (_editMode) {
        _editingDieId = die.id;
        return;
      }
      if (_rerollMode) {
        die.value = _random.nextInt(6) + 1;
        die.rollTick++;
        _rerollMode = false;
        widget.onChanged?.call(_dice.take(_diceToRoll.clamp(0, 5)).toList());
        return;
      }
      if (_rollCount > 0) {
        die.reserved = !die.reserved;
      }
    });
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.symbol, required this.children});

  final DieSymbol symbol;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          DieSymbolMark(symbol: symbol),
          const SizedBox(width: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SuiteLine extends StatelessWidget {
  const _SuiteLine({
    required this.label,
    required this.length,
    required this.damage,
  });

  final String label;
  final int length;
  final _AttackDamage? damage;

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
          if (damage != null)
            DamageBadge(value: damage!.value, imparable: damage!.imparable),
        ],
      ),
    );
  }
}

class _AttackResultLine extends StatelessWidget {
  const _AttackResultLine({required this.goal, required this.result});

  final SymbolGoal goal;
  final List<Widget> result;

  @override
  Widget build(BuildContext context) {
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
    canvas.translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
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
      child: Image.asset(
        asset,
        width: 34,
        height: 34,
        fit: BoxFit.contain,
      ),
    );
  }
}

class DamageBadge extends StatelessWidget {
  const DamageBadge({required this.value, required this.imparable, super.key});

  final int value;
  final bool imparable;

  @override
  Widget build(BuildContext context) {
    final color = imparable ? Colors.redAccent : Colors.white;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: imparable
            ? Colors.redAccent.withValues(alpha: 0.9)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: imparable ? Colors.white : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PreventBadge extends StatelessWidget {
  const PreventBadge({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.lightBlueAccent, width: 2),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HalfPreventBadge extends StatelessWidget {
  const _HalfPreventBadge();

  @override
  Widget build(BuildContext context) {
    return const _TextBadge(
      label: '1/2',
      color: Colors.lightBlueAccent,
      icon: Icons.shield,
    );
  }
}

class _HalfReturnBadge extends StatelessWidget {
  const _HalfReturnBadge();

  @override
  Widget build(BuildContext context) {
    return const _TextBadge(
      label: '1/2',
      color: Colors.white,
      icon: Icons.bolt,
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

class _TextBadge extends StatelessWidget {
  const _TextBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
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

class _LegacyDieValueBadge extends StatelessWidget {
  const _LegacyDieValueBadge({
    required this.value,
    this.showValue = true,
    this.size = 30,
  });

  final int value;
  final bool showValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: showValue
          ? Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            )
          : const Icon(Icons.casino, color: Colors.white, size: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        '-$value / +$value',
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
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.greenAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Text(
        '+$value',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
      children: const [
        Text('4x', style: TextStyle(fontWeight: FontWeight.w900)),
        _EmptyDieBadge(size: 22),
        Text('='),
        _EmptyDieBadge(size: 22, label: '^'),
        Text('+'),
        _EmptyDieBadge(size: 22, label: '^'),
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
    return const Wrap(
      spacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('1x', style: TextStyle(fontWeight: FontWeight.w900)),
        _EmptyDieBadge(size: 24),
      ],
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

_AttackDamage? _damageForSymbolGoal(EnemyNode enemy, SymbolGoal goal) {
  final key = enemy.profileKey;
  final goalIndex = _goalIndex(enemy.attackPlan.goals, goal);
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
  if (key == 'vert-vert-012' || key == 'vert-vert-017') {
    return null;
  }
  return _damageFromAttackText(enemy, goalIndex);
}

_AttackDamage? _suiteDamage(EnemyNode enemy, int length) {
  final key = enemy.profileKey;
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
  final text = _normalizeAttackText(enemy.attacks.join(' '));
  return text.contains('lance ') ||
      text.contains('roll ') ||
      text.contains('lancer ');
}

int _extraDiceCountFor(EnemyNode enemy) {
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
    if (!normalized.contains('degats') && !normalized.contains('damage')) {
      final afterEquals = normalized.split('=').last;
      final fallbackValues = RegExp(r'\d+')
          .allMatches(afterEquals)
          .map((match) => int.tryParse(match.group(0) ?? ''))
          .whereType<int>()
          .toList();
      if (fallbackValues.isNotEmpty) {
        values.add(fallbackValues.last);
      }
    }
  }
  return values;
}

bool _attackTextIsImparable(List<String> attacks) {
  final text = _normalizeAttackText(attacks.join(' '));
  return text.contains('imparable') || text.contains('undefendable');
}

String _normalizeAttackText(String value) {
  return value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ï', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ô', 'o');
}

String _compactDefenseText(String value) {
  return value
      .replaceAll('jaunes', 'orange')
      .replaceAll('jaune', 'orange')
      .replaceAll('symboles', 'symbols')
      .replaceAll('symbole', 'symbol')
      .replaceAll('dés', 'dice')
      .replaceAll('dé', 'die')
      .replaceAll('dégâts', 'damage')
      .replaceAll('dégât', 'damage')
      .replaceAll('Jet défensif ', '')
      .replaceAll('Jet defensif ', '');
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
            onHeroCp: () => _openEditor('heroCp', widget.adventure.combatPoints),
            onEnemyHp: () => _openEditor('enemyHp', widget.enemy.health),
            onEnemyCp: () => _openEditor('enemyCp', widget.enemy.combatPoints),
            onEditHeroTokens: _editHeroTokens,
            onEditEnemyTokens: _editEnemyTokens,
          ),
          if (_editing.contains('heroHp') || _editing.contains('enemyHp')) ...[
            const SizedBox(height: 6),
            _buildEditorPair('heroHp', 'enemyHp'),
          ],
          if (_editing.contains('heroCp') || _editing.contains('enemyCp')) ...[
            const SizedBox(height: 6),
            _buildEditorPair('heroCp', 'enemyCp'),
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
        border: Border.all(color: accent.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Center(
              child: isHp
                  ? Icon(Icons.favorite, color: accent, size: 17)
                  : Text(
                      'PC',
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
    );
    if (values != null) {
      widget.enemy.alterations
        ..clear()
        ..addAll(values);
      widget.onChanged();
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
      ),
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
                  onHp: onEnemyHp,
                  onCp: onEnemyCp,
                  onEditTokens: onEditEnemyTokens,
                ),
              ),
              Container(width: 1, color: panelBorderGrey.withValues(alpha: 0.75)),
              Expanded(
                child: _CombatantVersusHalf(
                  title: adventure.hero.label,
                  hp: adventure.health,
                  cp: adventure.combatPoints,
                  tokens: adventure.alterations,
                  accent: heroAccent,
                  portraitAsset: adventure.hero.asset,
                  portraitAlignment: adventure.hero.imageAlignment,
                  portraitScale: adventure.hero.imageScale,
                  hpStyle: _CombatHpStyle.hero,
                  onHp: onHeroHp,
                  onCp: onHeroCp,
                  onEditTokens: onEditHeroTokens,
                  imageOnRight: true,
                ),
              ),
            ],
          ),
          IgnorePointer(
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
    this.portraitScale = 1,
    this.imageOnRight = false,
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
  final bool imageOnRight;

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
              child: _HpHeartBadge(
                value: hp,
                style: hpStyle,
              ),
            ),
            const SizedBox(height: 8),
            _CombatBadgeButton(
              onTap: onCp,
              child: _PcTriangleBadge(value: cp),
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
        Transform.scale(
          scale: scale,
          child: Image.asset(asset, fit: BoxFit.cover, alignment: alignment),
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
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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
  const _PcTriangleBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 99);
    final valueText = safeValue.toString();
    final showPcLabel = safeValue < 10;
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
                  fontSize: showPcLabel ? 28 : 21,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.white54, blurRadius: 8)],
                ),
              ),
            ),
            if (showPcLabel)
              Align(
                alignment: const Alignment(0.18, -0.04),
                child: Text(
                  'PC',
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
                          final values = await showAlterationDialog(
                            context,
                            enemy.alterations,
                            forMinion: true,
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
                          icon: Icons.remove,
                          tooltip: 'Remove',
                          onPressed: () => setState(() => _draftValue--),
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
                          icon: Icons.add,
                          tooltip: 'Add',
                          onPressed: () => setState(() => _draftValue++),
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
                    onPressed: canAdvance
                        ? () {
                            if (phase == CombatPhase.heroUpkeep &&
                                !heroUpkeepApplied) {
                              onApplyHeroUpkeep();
                            }
                            if (phase == CombatPhase.minionUpkeep &&
                                !upkeepApplied) {
                              onApplyUpkeep();
                            }
                            onNext();
                          }
                        : null,
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
    required this.onPhaseChanged,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final ValueChanged<CombatPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final phases = CombatPhase.values
        .where((value) => value != CombatPhase.intro)
        .toList();
    final disabled = phase == CombatPhase.intro;
    return Row(
      children: phases.map((value) {
        final selected = !disabled && value == phase;
        final accent = _phaseColor(value, enemy);
        return Expanded(
          child: InkWell(
            onTap: disabled ? null : () => onPhaseChanged(value),
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
                      child: switch (value) {
                        CombatPhase.heroUpkeep => _PhasePortraitIcon(
                          asset: adventure.hero.asset,
                          alignment: adventure.hero.imageAlignment,
                          scale: adventure.hero.imageScale,
                        ),
                        CombatPhase.minionUpkeep => _PhasePortraitIcon(
                          asset: enemy.previewAsset,
                          alignment: enemy.profileKey == 'naraxus'
                              ? Alignment.center
                              : Alignment.topCenter,
                        ),
                        _ => const _UpkeepCubeIcon(size: 30),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhasePortraitIcon extends StatelessWidget {
  const _PhasePortraitIcon({
    required this.asset,
    required this.alignment,
    this.scale = 1,
  });

  final String asset;
  final Alignment alignment;
  final double scale;

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
          fit: BoxFit.cover,
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
    final rollDice = visibleDice.where((die) => !die.reserved).toList()
      ..sort(_compareDice);
    final reserveDice = visibleDice.where((die) => die.reserved).toList()
      ..sort(_compareDice);
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
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: rollColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: rollCount < maxRolls && diceToRoll > 0
                      ? onRoll
                      : null,
                  icon: const Icon(Icons.casino),
                  label: Text(rollLabel),
                ),
              ),
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
                DieTile(die: die, onTap: () => onTapDie(die)),
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
    super.key,
  });

  final GameDie die;
  final VoidCallback? onTap;
  final bool compact;
  final bool highlight;
  final Color? highlightColor;

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _faceTimer?.cancel();
          if (mounted) {
            setState(() => _animatedValue = widget.die.value);
          }
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
    final value = _controller.isAnimating ? _animatedValue : widget.die.value;
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
              final squash = 0.92 + sin(_controller.value * pi * 12) * 0.08;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(turn),
                child: Transform.scale(scaleY: squash, child: child),
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

