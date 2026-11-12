part of '../../main.dart';

/// Interactive Venom Gauge component for the final snake boss (Ourokhor).
///
/// Refactored for 9 milestone debuffs targeting the hero:
/// - 0: Targeted
/// - 3: Knockdown
/// - 6: Wither
/// - 9: Prey
/// - 12: Blind
/// - 15: Bleed
/// - 18: Blinding Light
/// - 21: Hex
/// - 24: Stun
///
/// Features:
/// - Smooth horizontal scrollable milestone ribbon (Nina UX Architecture)
/// - Auto-centering on the latest reached milestone
/// - Gauge tracks from 0 to 24
/// - Visual progress bar with venom gradient
class OurokhorPoisonGaugeCard extends StatefulWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final Set<int> triggeredMilestones;

  const OurokhorPoisonGaugeCard({
    super.key,
    required this.value,
    this.max = 24,
    required this.onChanged,
    this.triggeredMilestones = const {},
  });

  static const List<({int threshold, String token, String label, String asset, String description})> milestones = [
    (
      threshold: 0,
      token: 'Targeted',
      label: 'Targeted',
      asset: 'assets/token/Targeted.png',
      description: 'Milestone 0: Hero is afflicted with Targeted',
    ),
    (
      threshold: 3,
      token: 'Knockdown',
      label: 'Knockdown',
      asset: 'assets/token/A-terre.png',
      description: 'Milestone 3: Hero is afflicted with Knockdown',
    ),
    (
      threshold: 6,
      token: 'Wither',
      label: 'Wither',
      asset: 'assets/token/Wither.png',
      description: 'Milestone 6: Hero is afflicted with Wither',
    ),
    (
      threshold: 9,
      token: 'Prey',
      label: 'Prey',
      asset: 'assets/token/Prey.png',
      description: 'Milestone 9: Hero is afflicted with Prey',
    ),
    (
      threshold: 12,
      token: 'Blind',
      label: 'Blind',
      asset: 'assets/token/Blind.png',
      description: 'Milestone 12: Hero is afflicted with Blind',
    ),
    (
      threshold: 15,
      token: 'Bleed',
      label: 'Bleed',
      asset: 'assets/token/Bleed.png',
      description: 'Milestone 15: Hero is afflicted with Bleed',
    ),
    (
      threshold: 18,
      token: 'Blinding Light',
      label: 'Blind Light',
      asset: 'assets/token/Blinding-Light.png',
      description: 'Milestone 18: Hero is afflicted with Blinding Light',
    ),
    (
      threshold: 21,
      token: 'Hex',
      label: 'Hex',
      asset: 'assets/token/hex.png',
      description: 'Milestone 21: Hero is afflicted with Hex',
    ),
    (
      threshold: 24,
      token: 'Stun',
      label: 'Stun',
      asset: 'assets/token/stun.png',
      description: 'Milestone 24: Hero is afflicted with Stun',
    ),
  ];

  @override
  State<OurokhorPoisonGaugeCard> createState() => _OurokhorPoisonGaugeCardState();
}

class _OurokhorPoisonGaugeCardState extends State<OurokhorPoisonGaugeCard> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(animate: false));
  }

  @override
  void didUpdateWidget(covariant OurokhorPoisonGaugeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _scrollToActive(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final clamped = widget.value.clamp(0, widget.max);
    int activeIndex = 0;
    for (int i = 0; i < OurokhorPoisonGaugeCard.milestones.length; i++) {
      if (clamped >= OurokhorPoisonGaugeCard.milestones[i].threshold) {
        activeIndex = i;
      }
    }
    // Item width is 84 + 6 margin = 90
    final targetOffset = (activeIndex * 90.0 - 60.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clampedVal = widget.value.clamp(0, widget.max);
    final ratio = clampedVal / widget.max;
    final isMaxLevel = clampedVal >= widget.max;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff16352b),
            Color(0xff0e231c),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMaxLevel ? const Color(0xffc084fc) : const Color(0xff10b981).withValues(alpha: 0.6),
          width: isMaxLevel ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isMaxLevel ? const Color(0xffa855f7) : const Color(0xff10b981)).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title, value badge, hero target badge, manual buttons
          Row(
            children: [
              Image.asset(
                'assets/token/poison.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.science_outlined,
                  color: Color(0xff34d399),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'VENOM GAUGE',
                          style: TextStyle(
                            color: Color(0xff34d399),
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMaxLevel
                                ? const Color(0xffa855f7).withValues(alpha: 0.35)
                                : const Color(0xff10b981).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMaxLevel
                                  ? const Color(0xffd8b4fe).withValues(alpha: 0.5)
                                  : const Color(0xff6ee7b7).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$clampedVal / ${widget.max}',
                            style: TextStyle(
                              color: isMaxLevel ? const Color(0xffe9d5ff) : const Color(0xffa7f3d0),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xffef4444).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xfff87171).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'DEBUFFS HERO',
                            style: TextStyle(
                              color: Color(0xfffca5a5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Advances on poison damage • Hero receives debuff token upon reaching each milestone',
                      style: TextStyle(
                        color: Color(0xff9cbab0),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Step adjustment buttons
              _buildAdjustButton(
                icon: Icons.remove,
                tooltip: 'Decrease Venom Gauge (-1)',
                enabled: clampedVal > 0,
                onTap: () => widget.onChanged(-1),
              ),
              const SizedBox(width: 6),
              _buildAdjustButton(
                icon: Icons.add,
                tooltip: 'Increase Venom Gauge (+1)',
                enabled: clampedVal < widget.max,
                onTap: () => widget.onChanged(1),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xff142b22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xff224a3a),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xff059669),
                            Color(0xff10b981),
                            Color(0xff34d399),
                            Color(0xffeab308),
                            Color(0xffef4444),
                            Color(0xffc084fc),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Scrollable 9-Milestone Ribbon (Nina UX Design)
          SizedBox(
            height: 98,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: OurokhorPoisonGaugeCard.milestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final m = OurokhorPoisonGaugeCard.milestones[index];
                final isReached = clampedVal >= m.threshold;
                final isStun = m.threshold == 24;
                final activeColor = isStun ? const Color(0xffc084fc) : const Color(0xff34d399);
                final activeBg = isStun ? const Color(0xff4a1d6d) : const Color(0xff065f46);
                final inactiveBg = const Color(0xff162e25);
                final inactiveBorder = const Color(0xff2a4d3e);

                return Tooltip(
                  message: '${m.threshold} pts: ${m.description}',
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isReached ? activeBg : inactiveBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isReached ? activeColor : inactiveBorder,
                        width: isReached ? 1.6 : 1.0,
                      ),
                      boxShadow: isReached
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${m.threshold}',
                              style: TextStyle(
                                color: isReached ? Colors.white : const Color(0xff8ea99e),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isReached) ...[
                              const SizedBox(width: 3),
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: activeColor,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Image.asset(
                          m.asset,
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.warning_amber_rounded,
                            size: 26,
                            color: isReached ? activeColor : const Color(0xff8ea99e),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isReached
                                ? (isStun ? const Color(0xfff3e8ff) : const Color(0xffd1fae5))
                                : const Color(0xffa2bfb4),
                            fontSize: 10.5,
                            fontWeight: isReached ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xff1b3d31) : const Color(0xff12261f),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled ? const Color(0xff346c56) : const Color(0xff1e3a2f),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? const Color(0xff34d399) : const Color(0xff436658),
            ),
          ),
        ),
      ),
    );
  }
}
