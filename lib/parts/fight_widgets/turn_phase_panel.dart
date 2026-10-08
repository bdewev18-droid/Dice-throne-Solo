part of '../../main.dart';

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
    required this.onSettings,
    this.developerMode = false,
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
  final VoidCallback onSettings;
  final bool developerMode;
  final VoidCallback onApplyUpkeep;
  final VoidCallback onApplyHeroUpkeep;

  @override
  Widget build(BuildContext context) {
    final poisonCount = enemy.alterations
        .where((token) => token == 'Poison')
        .length;
    final heroHasSilence = adventure.alterations.contains('Silence');
    final heroHasHemorrhage = adventure.alterations.contains('HÃ©morragie');
    final heroHasRonces = adventure.alterations.contains('Ronces');
    final enemyHasRiposte = enemy.alterations.contains('Riposte');
    const nextColor = Color(0xff8f43ff);
    final reminder = switch (phase) {
      CombatPhase.heroUpkeep => [
        if (heroHasHemorrhage) 'HÃ©morragie',
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
                height: 52,
                child: IconButton.filledTonal(
                  tooltip: 'Combat settings',
                  onPressed: onSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.22),
                    foregroundColor: developerMode
                        ? Colors.orangeAccent
                        : Colors.white.withOpacity(0.8),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  icon: const Icon(Icons.settings),
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

