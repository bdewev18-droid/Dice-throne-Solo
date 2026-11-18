part of '../../main.dart';

/// Enveloppe un avatar ou panneau de stats de combat et déclenche un effet
/// Game Design (secousse, flash coloré, badge flottant) dès que les PV, PC ou
/// tokens changent.
class CombatImpactAvatarWrapper extends StatefulWidget {
  const CombatImpactAvatarWrapper({
    required this.hp,
    required this.cp,
    required this.tokens,
    required this.child,
    super.key,
  });

  final int hp;
  final int cp;
  final List<String> tokens;
  final Widget child;

  @override
  State<CombatImpactAvatarWrapper> createState() =>
      _CombatImpactAvatarWrapperState();
}

class _CombatImpactAvatarWrapperState extends State<CombatImpactAvatarWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _badgeText;
  Color _badgeColor = Colors.redAccent;
  bool _shakeOnImpact = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
  }

  @override
  void didUpdateWidget(covariant CombatImpactAvatarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hpDelta = widget.hp - oldWidget.hp;
    final cpDelta = widget.cp - oldWidget.cp;
    final oldTokensCount = oldWidget.tokens.length;
    final newTokensCount = widget.tokens.length;

    if (hpDelta != 0) {
      _triggerImpact(
        text: hpDelta < 0 ? '$hpDelta HP' : '+$hpDelta HP',
        color: hpDelta < 0 ? const Color(0xffff4d4d) : const Color(0xff4ade80),
        shake: hpDelta < 0,
      );
    } else if (cpDelta != 0) {
      _triggerImpact(
        text: cpDelta < 0 ? '$cpDelta CP' : '+$cpDelta CP',
        color: GameDesign.gold,
        shake: false,
      );
    } else if (newTokensCount > oldTokensCount) {
      final added = widget.tokens.first;
      _triggerImpact(
        text: '+$added',
        color: const Color(0xffc084fc),
        shake: false,
      );
    }
  }

  void _triggerImpact({
    required String text,
    required Color color,
    required bool shake,
  }) {
    setState(() {
      _badgeText = text;
      _badgeColor = color;
      _shakeOnImpact = shake;
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final isActive = _controller.isAnimating && _badgeText != null;
        final shakeX = (isActive && _shakeOnImpact && t < 0.35)
            ? sin(t * 28 * pi) * 5.0 * (1.0 - t / 0.35)
            : 0.0;
        final flashOpacity = (isActive && t < 0.30)
            ? (1.0 - t / 0.30) * 0.38
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(shakeX, 0),
              child: Stack(
                children: [
                  child!,
                  if (flashOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _badgeColor.withValues(alpha: flashOpacity),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Positioned(
                top: -6 - (t * 28),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: t < 0.75 ? 1.0 : ((1.0 - t) / 0.25).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: t < 0.15 ? 0.7 + (t / 0.15) * 0.4 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _badgeColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _badgeColor.withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          _badgeText!,
                          style: TextStyle(
                            color: _badgeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
