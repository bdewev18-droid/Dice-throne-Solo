part of '../../main.dart';

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
    this.showOnlyAttack = false,
    this.showOnlyDefense = false,
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
  final bool showOnlyAttack;
  final bool showOnlyDefense;

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
    if (oldWidget.enemy.id != widget.enemy.id ||
        oldWidget.enemy.profileKey != widget.enemy.profileKey) {
      _druidFormPreview = null;
      _showAttack = widget.phase == CombatPhase.minionAttack;
      _showDefense = widget.phase == CombatPhase.hero;
      _showPassive = false;
    }
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
        if (!widget.showOnlyDefense)
          _RulesBackgroundBand(
            asset: 'assets/attack_background_feline_shadow.png',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const SizedBox(height: 8), attackContent],
            ),
          ),
        if (!widget.showOnlyAttack)
          _RulesBackgroundBand(
            asset: 'assets/defense_background_feline_shadow.png',
            child: defenseContent,
          ),
        if (!widget.showOnlyDefense && _hasPassiveContent)
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

  bool get _hasPassiveContent {
    final key = enemy.profileKey;
    if (key != null) {
      final profile = EnemyProfileRepository.byKey(key);
      if (profile != null &&
          profile.passives.isEmpty &&
          profile.passiveDisplayRows.isEmpty) {
        return false;
      }
    }
    return enemy.passiveDisplayRows.isNotEmpty || _displayedPassives.isNotEmpty;
  }

  /// Passives rendered by the generic zone. Profiles that already have a
  /// dedicated hard-coded passive view inside [MinionAttackSummary] are
  /// excluded so the passive is not shown twice.
  List<MinionPassive> get _displayedPassives {
    const covered = <String>{
      'vert-vert-012', // Roc â€” dedicated view
      'vert-vert-014', // Druide Tenebreux â€” dedicated view
      'bleu-bleu-004', // Mage de Sang â€” dedicated view
      'viseer', // Viseer â€” dedicated view
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
        badges.add(InlineTokenText(token, color: color));
      }
      for (final token in effect.heroTokens) {
        badges.add(InlineTokenText(token, color: Colors.deepOrangeAccent));
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
        badges.add(
          DamageBadge(value: effect.damage, imparable: effect.undefendable),
        );
      }
      if (effect.label != null && effect.label!.isNotEmpty) {
        badges.add(const SizedBox(width: 4));
        badges.add(
          InlineTokenText(
            effect.label!,
            color: color,
            style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
          ),
        );
      }
      final label2 = effect.label2;
      final label3 = effect.label3;
      if ((label2 != null && label2.isNotEmpty) ||
          (label3 != null && label3.isNotEmpty)) {
        badges.add(const SizedBox(width: 4));
        if (label2 != null &&
            label2.isNotEmpty &&
            label3 != null &&
            label3.isNotEmpty) {
          badges.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                InlineTokenText(
                  label2,
                  color: color,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xffcbd8cc),
                  ),
                ),
                InlineTokenText(
                  label3,
                  color: color,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xffcbd8cc),
                  ),
                ),
              ],
            ),
          );
        } else {
          final label = (label2 != null && label2.isNotEmpty)
              ? label2
              : label3!;
          badges.add(
            InlineTokenText(
              label,
              color: color,
              style: const TextStyle(fontSize: 12, color: Color(0xffcbd8cc)),
            ),
          );
        }
      }
      return badges;
    }

    // Legacy fallback
    final badges = <Widget>[];
    final Widget? legacyLeading = switch (enemy.profileKey) {
      'bleu-bleu-008' when length == 3 => TokenBadge(
        label: 'Entangle',
        color: color,
      ),
      'bleu-bleu-008' when length == 4 => TokenBadge(
        label: 'Silence',
        color: color,
      ),
      'fee' when length == 5 => CpStealBadge(value: 1, color: color),
      'elfe-du-chaos' when length == 5 => TokenBadge(
        label: 'Barbed Vine',
        color: color,
      ),
      'vert-vert-020' when length == 5 => TokenBadge(
        label: 'Knockdown',
        color: color,
      ),
      _ => null,
    };
    final legacyDamage = _suiteDamage(enemy, length);

    if (legacyLeading != null) {
      badges.add(legacyLeading);
      badges.add(const SizedBox(width: 5));
    }
    if (legacyDamage != null) {
      badges.add(
        DamageBadge(
          value: legacyDamage.value,
          imparable: legacyDamage.imparable,
        ),
      );
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

    final Widget mainBody = Builder(
      builder: (context) {
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
                    result.add(
                      DamageBadge(
                        value: damage.value,
                        imparable: damage.imparable,
                      ),
                    );
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
      },
    );

    if (ruleRows.isEmpty) {
      return mainBody;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mainBody,
        const SizedBox(height: 8),
        _DisplayRowsColumn(rows: ruleRows, color: enemy.rank.color),
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
    if (text.contains('hÃ©morragie')) {
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
    if ((text.contains('a terre') || text.contains('Ã  terre')) &&
        enemy.profileKey != 'vert-vert-020') {
      hints.add(
        _hintTokenLine('If condition met:', 'Knockdown', enemy.rank.color),
      );
    }
    if ((text.contains('enchevetrement') || text.contains('enchevÃªtrement')) &&
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
            if (safeCount > 0)
              Text(
                '$safeCount x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            if (safeCount > 0) const SizedBox(width: 4),
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
    required this.onSettings,
    required this.onApplyUpkeep,
    required this.onApplyHeroUpkeep,
    required this.developerMode,
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
  final VoidCallback onSettings;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;
  final bool developerMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xf2121212)),
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
        onSettings: onSettings,
        onApplyUpkeep: onApplyUpkeep,
        onApplyHeroUpkeep: onApplyHeroUpkeep,
        developerMode: developerMode,
      ),
    );
  }
}
