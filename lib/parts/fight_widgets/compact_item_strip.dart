part of '../../main.dart';

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
    this.onTokenRemoved,
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
  final ValueChanged<String>? onTokenRemoved;

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
                                          getCount:
                                              widget.onTokensChanged != null
                                              ? () => widget.items
                                                    .where(
                                                      (t) =>
                                                          _compactTokenBaseLabel(
                                                            t,
                                                          ) ==
                                                          rule.label,
                                                    )
                                                    .length
                                              : null,
                                          onMinus:
                                              widget.onTokensChanged != null
                                              ? () {
                                                  final idx = widget.items
                                                      .indexWhere(
                                                        (t) =>
                                                            _compactTokenBaseLabel(
                                                              t,
                                                            ) ==
                                                            rule.label,
                                                      );
                                                  if (idx != -1) {
                                                    final removedItem =
                                                        widget.items[idx];
                                                    widget.items.removeAt(idx);
                                                    if (widget.onTokenRemoved !=
                                                        null) {
                                                      widget.onTokenRemoved!(
                                                        removedItem,
                                                      );
                                                    }
                                                    widget.onTokensChanged!();
                                                  }
                                                }
                                              : null,
                                          onPlus: widget.onTokensChanged != null
                                              ? () {
                                                  widget.items.add(rule.label);
                                                  widget.onTokensChanged!();
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
              if (widget.trailing != null) widget.trailing!,
            ],
          );
        },
      ),
    );
  }
}

class _CompactItemVisual extends StatelessWidget {
  const _CompactItemVisual({
    required this.item,
    required this.color,
    this.size = 30,
  });

  static final RegExp _healthRewardPattern = RegExp(r'^\+(\d+) HP$');
  static final RegExp _cpRewardPattern = RegExp(r'^\+(\d+) CP$');

  final CompactItemModel item;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final healthMatch = _healthRewardPattern.firstMatch(item.label);
    if (healthMatch != null) {
      return _EffectImageBadge(
        value: '+${healthMatch.group(1)!}',
        asset: 'assets/illustration/soin.webp',
        textColor: Colors.white,
        size: size + 4,
        fontSize: 12,
      );
    }
    final cpMatch = _cpRewardPattern.firstMatch(item.label);
    if (cpMatch != null) {
      final value = int.tryParse(cpMatch.group(1)!);
      if (value != null) {
        return SizedBox(
          width: size + 6,
          height: size + 6,
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
      size: size,
    );
  }
}

class HeroTokenStrip extends StatelessWidget {
  const HeroTokenStrip({
    required this.tokens,
    required this.onEdit,
    this.onTokenRemoved,
    super.key,
  });

  final List<String> tokens;
  final VoidCallback onEdit;
  final ValueChanged<String>? onTokenRemoved;

  @override
  Widget build(BuildContext context) {
    return CompactItemStrip(
      label: 'Tokens',
      emptyText: 'Tokens',
      items: tokens,
      onTokenRemoved: onTokenRemoved,
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
    this.size = 30,
    super.key,
  });

  final String value;
  final String tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isActive =
        tooltip.toLowerCase().contains('_active') ||
        value.toLowerCase().contains('_active');
    final rule =
        TokenCatalogRepository.byLabel(_compactTokenBaseLabel(tooltip)) ??
        TokenCatalogRepository.byLabel(_compactTokenBaseLabel(value));
    if (rule != null) {
      final cleanTooltip = tooltip.replaceAll(
        RegExp(r'_active', caseSensitive: false),
        '',
      );
      final countMatch = RegExp(r' x(\d+)').firstMatch(cleanTooltip);
      final count = countMatch?.group(1);
      Widget image = StatusTokenImage(rule: rule, size: size);
      if (isActive) {
        image = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: image,
        );
      }
      return Stack(
        clipBehavior: Clip.none,
        children: [
          image,
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
                  style: TextStyle(
                    fontSize: (size * 0.3).clamp(8.0, 11.0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      constraints: BoxConstraints(
        minWidth: size + max(0, value.length - 2) * 8,
      ),
      height: size - 2,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: (size * 0.38).clamp(9.0, 13.0),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

String _compactTokenBaseLabel(String value) {
  return value
      .replaceFirst(RegExp(r' x\d+$'), '')
      .replaceFirst(RegExp(r' \(\-\d+\)$'), '')
      .replaceAll(RegExp(r'_active', caseSensitive: false), '')
      .trim();
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
  if (value == 'PremiÃ¨re Frappe') {
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
