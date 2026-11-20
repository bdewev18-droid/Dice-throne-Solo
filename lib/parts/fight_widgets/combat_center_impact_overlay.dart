part of '../../main.dart';

class _CenterImpactItem {
  const _CenterImpactItem({
    required this.ownerName,
    required this.ownerColor,
    required this.text,
    required this.accentColor,
    this.icon,
    this.tokenRule,
    this.isCp = false,
    this.cpValue = 0,
  });

  final String ownerName;
  final Color ownerColor;
  final String text;
  final Color accentColor;
  final IconData? icon;
  final StatusTokenRule? tokenRule;
  final bool isCp;
  final int cpValue;
}

/// Center-screen floating overlay that highlights HP changes, CP changes,
/// and newly inflicted tokens in two columns (Hero left, Minion right) above all UI.
class CombatCenterImpactOverlay extends StatefulWidget {
  const CombatCenterImpactOverlay({
    super.key,
    required this.heroLabel,
    required this.heroHp,
    required this.heroCp,
    required this.heroTokens,
    required this.enemyLabel,
    required this.enemyColor,
    required this.enemyHp,
    required this.enemyCp,
    required this.enemyTokens,
  });

  final String heroLabel;
  final int heroHp;
  final int heroCp;
  final List<String> heroTokens;
  final String enemyLabel;
  final Color enemyColor;
  final int enemyHp;
  final int enemyCp;
  final List<String> enemyTokens;

  @override
  State<CombatCenterImpactOverlay> createState() =>
      _CombatCenterImpactOverlayState();
}

class _CombatCenterImpactOverlayState extends State<CombatCenterImpactOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_CenterImpactItem> _heroItems = const [];
  List<_CenterImpactItem> _enemyItems = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  List<_CenterImpactItem> _collectDeltas({
    required String ownerName,
    required Color ownerColor,
    required int oldHp,
    required int newHp,
    required int oldCp,
    required int newCp,
    required List<String> oldTokens,
    required List<String> newTokens,
  }) {
    final items = <_CenterImpactItem>[];
    final hpDelta = newHp - oldHp;
    final cpDelta = newCp - oldCp;
    if (hpDelta != 0) {
      items.add(
        _CenterImpactItem(
          ownerName: ownerName,
          ownerColor: ownerColor,
          text: hpDelta < 0 ? '$hpDelta HP' : '+$hpDelta HP',
          accentColor: hpDelta < 0
              ? const Color(0xffff4d4d)
              : const Color(0xff4ade80),
          icon: hpDelta < 0
              ? Icons.heart_broken_rounded
              : Icons.favorite_rounded,
        ),
      );
    }
    if (cpDelta != 0) {
      items.add(
        _CenterImpactItem(
          ownerName: ownerName,
          ownerColor: ownerColor,
          text: cpDelta < 0 ? '$cpDelta CP' : '+$cpDelta CP',
          accentColor: GameDesign.gold,
          isCp: true,
          cpValue: cpDelta.abs(),
        ),
      );
    }
    if (newTokens.length > oldTokens.length) {
      final addedCount = newTokens.length - oldTokens.length;
      for (var i = 0; i < addedCount; i++) {
        final added = newTokens[i];
        items.add(
          _CenterImpactItem(
            ownerName: ownerName,
            ownerColor: ownerColor,
            text: '+$added',
            accentColor: const Color(0xffc084fc),
            tokenRule: TokenCatalogRepository.byLabel(added),
            icon: Icons.stars_rounded,
          ),
        );
      }
    }
    return items;
  }

  @override
  void didUpdateWidget(covariant CombatCenterImpactOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextHeroItems = _collectDeltas(
      ownerName: widget.heroLabel,
      ownerColor: heroAccent,
      oldHp: oldWidget.heroHp,
      newHp: widget.heroHp,
      oldCp: oldWidget.heroCp,
      newCp: widget.heroCp,
      oldTokens: oldWidget.heroTokens,
      newTokens: widget.heroTokens,
    );
    final nextEnemyItems = _collectDeltas(
      ownerName: widget.enemyLabel,
      ownerColor: widget.enemyColor,
      oldHp: oldWidget.enemyHp,
      newHp: widget.enemyHp,
      oldCp: oldWidget.enemyCp,
      newCp: widget.enemyCp,
      oldTokens: oldWidget.enemyTokens,
      newTokens: widget.enemyTokens,
    );

    final totalCount = nextHeroItems.length + nextEnemyItems.length;
    if (totalCount > 0) {
      final durationMs = (2200 + (totalCount - 1) * 750).clamp(2200, 4500);
      _controller.duration = Duration(milliseconds: durationMs);
      setState(() {
        _heroItems = nextHeroItems;
        _enemyItems = nextEnemyItems;
      });
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating ||
              (_heroItems.isEmpty && _enemyItems.isEmpty)) {
            return const SizedBox.shrink();
          }
          final t = _controller.value;
          final opacity = t < 0.10
              ? (t / 0.10)
              : t > 0.82
              ? ((1.0 - t) / 0.18).clamp(0.0, 1.0)
              : 1.0;
          final scale = t < 0.12
              ? 0.65 + (t / 0.12) * 0.45
              : t < 0.22
              ? 1.10 - ((t - 0.12) / 0.10) * 0.10
              : 1.0;
          final dy = -t * 32.0;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_heroItems.isNotEmpty)
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < _heroItems.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _ImpactToastCard(item: _heroItems[i]),
                                ],
                              ],
                            ),
                          ),
                        if (_heroItems.isNotEmpty && _enemyItems.isNotEmpty)
                          const SizedBox(width: 12),
                        if (_enemyItems.isNotEmpty)
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var i = 0;
                                  i < _enemyItems.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _ImpactToastCard(item: _enemyItems[i]),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImpactToastCard extends StatelessWidget {
  const _ImpactToastCard({required this.item});

  final _CenterImpactItem item;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (item.tokenRule != null) {
      leading = StatusTokenImage(rule: item.tokenRule!, size: 28);
    } else if (item.isCp) {
      leading = SizedBox(
        width: 28,
        height: 28,
        child: FittedBox(
          fit: BoxFit.contain,
          child: _PcTriangleBadge(value: item.cpValue),
        ),
      );
    } else {
      leading = Icon(
        item.icon ?? Icons.bolt_rounded,
        color: item.accentColor,
        size: 26,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: GameDesign.obsidianBg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: item.accentColor.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ownerName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.ownerColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
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
