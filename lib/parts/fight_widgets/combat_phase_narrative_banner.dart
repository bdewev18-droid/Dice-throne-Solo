part of '../../main.dart';

/// Displays non-dice phase narrative information (upkeep, draw, CP gain,
/// passive triggers) between the Turn Phase panel and the Versus status panel.
class CombatPhaseNarrativeBanner extends StatelessWidget {
  const CombatPhaseNarrativeBanner({
    super.key,
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.message,
  });

  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final String message;

  List<String> _formatLines(String raw) {
    return raw
        .split('\n')
        .where((line) => !line.trim().startsWith('{video:'))
        .map(
          (line) => line
              .replaceAll('**', '')
              .replaceAll('_', '')
              .replaceAll(RegExp(r'\{[^}]+\}'), '')
              .trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (phase == CombatPhase.intro) {
      return const SizedBox.shrink();
    }

    final isHeroTurn =
        phase == CombatPhase.heroUpkeep || phase == CombatPhase.hero;
    final accent = isHeroTurn ? heroAccent : enemy.rank.color;
    final isUpkeep =
        phase == CombatPhase.heroUpkeep || phase == CombatPhase.minionUpkeep;

    final List<String> lines;
    if (isUpkeep) {
      lines = _formatLines(message);
    } else {
      lines = [
        phase == CombatPhase.hero
            ? '${adventure.hero.label} — Roll & Attack Phase'
            : '${enemy.label} — Attack & Hero Defense Phase',
      ];
    }

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameDesign.slateSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isUpkeep ? Icons.auto_awesome_rounded : Icons.sports_mma_rounded,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 3),
                  Text(
                    lines[i],
                    style: TextStyle(
                      color: i == 0
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.78),
                      fontSize: i == 0 ? 12.5 : 11.5,
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
