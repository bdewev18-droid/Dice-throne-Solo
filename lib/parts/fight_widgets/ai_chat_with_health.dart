part of '../../main.dart';

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
    this.heroTokens = const [],
    this.enemyTokens = const [],
    this.onEditHeroTokens,
    this.onEditEnemyTokens,
    this.onTokensChanged,
    this.onHeroTokenRemoved,
    this.onEnemyTokenRemoved,
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
  final List<String> heroTokens;
  final List<String> enemyTokens;
  final VoidCallback? onEditHeroTokens;
  final VoidCallback? onEditEnemyTokens;
  final VoidCallback? onTokensChanged;
  final ValueChanged<String>? onHeroTokenRemoved;
  final ValueChanged<String>? onEnemyTokenRemoved;
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
      final tokens = portraitIsHero ? widget.heroTokens : widget.enemyTokens;
      final onEditTokens = portraitIsHero
          ? widget.onEditHeroTokens
          : widget.onEditEnemyTokens;
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
          tokens: tokens,
          accent: widget.accent,
          showTokens: widget.showPortraitVitals,
          onEditTokens: onEditTokens ?? () {},
          onTokensChanged: widget.onTokensChanged ?? () {},
          onTokenRemoved: portraitIsHero
              ? widget.onHeroTokenRemoved
              : widget.onEnemyTokenRemoved,
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
    this.tokens = const [],
    this.accent = const Color(0xff8f43ff),
    this.showTokens = false,
    this.onEditTokens,
    this.onTokensChanged,
    this.onTokenRemoved,
  }) : imageOnRight = false;

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
  final List<String> tokens;
  final Color accent;
  final bool showTokens;
  final bool imageOnRight;
  final VoidCallback? onEditTokens;
  final VoidCallback? onTokensChanged;
  final ValueChanged<String>? onTokenRemoved;

  @override
  Widget build(BuildContext context) {
    final visibleItems = tokens
        .where((value) => _isVisibleStatusTokenLabel(value))
        .toList(growable: false);
    final displayItems = _compactItemModels(visibleItems);

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
        if (showTokens)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                border: Border(
                  top: BorderSide(
                    color: accent.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: displayItems.isEmpty
                        ? InkWell(
                            onTap: onEditTokens,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                'Tokens',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: displayItems.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
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
                                          getCount: () => tokens
                                              .where(
                                                (t) =>
                                                    _compactTokenBaseLabel(t) ==
                                                    rule.label,
                                              )
                                              .length,
                                          onMinus: onTokensChanged != null
                                              ? () {
                                                  final idx = tokens.indexWhere(
                                                    (t) =>
                                                        _compactTokenBaseLabel(
                                                          t,
                                                        ) ==
                                                        rule.label,
                                                  );
                                                  if (idx != -1) {
                                                    tokens.removeAt(idx);
                                                    onTokensChanged!();
                                                  }
                                                }
                                              : null,
                                          onPlus: onTokensChanged != null
                                              ? () {
                                                  tokens.add(rule.label);
                                                  onTokensChanged!();
                                                }
                                              : null,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              item.tooltip.replaceAll(
                                                RegExp(
                                                  r'_active',
                                                  caseSensitive: false,
                                                ),
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Tooltip(
                                      message: item.tooltip.replaceAll(
                                        RegExp(
                                          r'_active',
                                          caseSensitive: false,
                                        ),
                                        '',
                                      ),
                                      child: _CompactItemVisual(
                                        item: item,
                                        color: accent,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  if (onEditTokens != null)
                    InkWell(
                      onTap: onEditTokens,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 14,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                ],
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
            icon: Icons.remove,
            tooltip: 'Remove $label',
            color: color,
            onPressed: () => onChanged(-1),
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
            icon: Icons.add,
            tooltip: 'Add $label',
            color: color,
            onPressed: () => onChanged(1),
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
