part of '../../main.dart';

class CombatIntroDialog extends StatelessWidget {
  const CombatIntroDialog({
    super.key,
    required this.adventure,
    required this.enemy,
    required this.battleText,
    required this.onNext,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final String battleText;
  final VoidCallback onNext;

  static Future<void> show(
    BuildContext context, {
    required AdventureState adventure,
    required EnemyNode enemy,
    required String battleText,
    required VoidCallback onNext,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => CombatIntroDialog(
        adventure: adventure,
        enemy: enemy,
        battleText: battleText,
        onNext: () {
          Navigator.of(dialogCtx).pop();
          onNext();
        },
      ),
    );
  }

  List<String> _cleanLines(String raw) {
    return raw
        .split('\n')
        .map((line) => line.replaceAll('**', '').replaceAll('_', '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Widget _buildPortrait(String assetPath, Color accentColor) {
    final isNetwork =
        assetPath.startsWith('http://') || assetPath.startsWith('https://');
    final image = isNetwork
        ? Image.network(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_rounded,
              color: Colors.white54,
              size: 40,
            ),
          )
        : Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.person_rounded,
              color: Colors.white54,
              size: 40,
            ),
          );

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 14,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = _cleanLines(battleText);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: GameDesign.obsidianBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GameDesign.actionPrimary.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPortrait(
                          adventure.hero.asset,
                          const Color(0xffffe22d),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          adventure.hero.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffffe22d),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 34, left: 8, right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GameDesign.slateSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: GameDesign.slateBorder),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: GameDesign.actionPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPortrait(
                          enemy.previewAsset,
                          enemy.rank.color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          enemy.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: enemy.rank.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GameDesign.slateSurface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: GameDesign.slateBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        Text(
                          lines[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: i == 0
                                ? GameDesign.actionPrimary
                                : Colors.white.withValues(alpha: 0.88),
                            fontSize: i == 0 ? 15 : 13,
                            fontWeight: i == 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (AppSettings.instance.showGameRules) ...[
                GameActionButton(
                  label: 'GAME RULES',
                  icon: Icons.menu_book_rounded,
                  primary: false,
                  onPressed: () => showHowToPlayVideoDialog(context),
                ),
                const SizedBox(height: 10),
              ],
              GameActionButton(
                label: 'NEXT',
                icon: Icons.arrow_forward_rounded,
                primary: true,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
