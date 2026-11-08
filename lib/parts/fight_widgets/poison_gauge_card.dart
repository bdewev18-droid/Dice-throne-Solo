part of '../../main.dart';

/// Interactive Venom Gauge component for the final snake boss (Ourokhor).
///
/// Features:
/// - Gauge from 0 to 25 tracking total venom damage suffered during battle.
/// - 5 cumulative milestones:
///   * 5: Damage bonus 2 (every turn)
///   * 10: Riposte (every turn)
///   * 15: Evasive (every turn)
///   * 20: Damage bonus 3 (every turn)
///   * 25: Hex inflicted on hero (every turn)
/// - Passive: Ourokhor gains tokens from all reached milestones each turn.
/// - Passive: Ourokhor heals HP equal to poison damage suffered by hero.
/// - Sticky above attack panel, scrolls with the page view.
class OurokhorPoisonGaugeCard extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const OurokhorPoisonGaugeCard({
    super.key,
    required this.value,
    this.max = 25,
    required this.onChanged,
  });

  static const List<({int threshold, String label, String asset, String description})> milestones = [
    (
      threshold: 5,
      label: '+2 Dmg',
      asset: 'assets/token/bonus-atk-2.webp',
      description: 'Damage bonus 2 every turn (max 2 damage bonus tokens total)',
    ),
    (
      threshold: 10,
      label: 'Riposte',
      asset: 'assets/token/Back-Strike.png',
      description: 'Riposte every turn (max stack: 1)',
    ),
    (
      threshold: 15,
      label: 'Evasive',
      asset: 'assets/token/Evasive.png',
      description: 'Evasive every turn (max stack: 3)',
    ),
    (
      threshold: 20,
      label: '+3 Dmg',
      asset: 'assets/token/bonus-atk-3.webp',
      description: 'Damage bonus 3 every turn (max 2 damage bonus tokens total)',
    ),
    (
      threshold: 25,
      label: 'Hex',
      asset: 'assets/token/hex.png',
      description: 'Hero is Hexed every turn (max stack: 1)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final clampedVal = value.clamp(0, max);
    final ratio = clampedVal / max;
    final isMaxLevel = clampedVal >= 25;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff16352b),
            const Color(0xff0e231c),
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
          // Header Row: Title, value, manual buttons
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
                    Row(
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            '$clampedVal / $max',
                            style: TextStyle(
                              color: isMaxLevel ? const Color(0xffe9d5ff) : const Color(0xffa7f3d0),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Passive: Tokens every turn (stack limits enforced) • Passive: Heal on roll failure',
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
                onTap: () => onChanged(-1),
              ),
              const SizedBox(width: 6),
              _buildAdjustButton(
                icon: Icons.add,
                tooltip: 'Increase Venom Gauge (+1)',
                enabled: clampedVal < max,
                onTap: () => onChanged(1),
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

          // 5 Milestone Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((m) {
              final isReached = clampedVal >= m.threshold;
              final isHex = m.threshold == 25;
              final activeColor = isHex ? const Color(0xffc084fc) : const Color(0xff34d399);
              final activeBg = isHex ? const Color(0xff4a1d6d) : const Color(0xff065f46);
              final inactiveBg = const Color(0xff162e25);
              final inactiveBorder = const Color(0xff2a4d3e);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Tooltip(
                    message: '${m.threshold} pts: ${m.description}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                      decoration: BoxDecoration(
                        color: isReached ? activeBg : inactiveBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isReached ? activeColor : inactiveBorder,
                          width: isReached ? 1.6 : 1.0,
                        ),
                        boxShadow: isReached
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${m.threshold}',
                                style: TextStyle(
                                  color: isReached ? Colors.white : const Color(0xff8ea99e),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (isReached) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.check_circle,
                                  size: 11,
                                  color: activeColor,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Image.asset(
                            m.asset,
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.bolt,
                              size: 22,
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
                                  ? (isHex ? const Color(0xfff3e8ff) : const Color(0xffd1fae5))
                                  : const Color(0xffa2bfb4),
                              fontSize: 10.5,
                              fontWeight: isReached ? FontWeight.w900 : FontWeight.w600,
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
