import 'dart:io';

void main() {
  final file = File('lib/parts/fight_widgets/combat_ai_chat_dock.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    'padding: const EdgeInsets.only(top: 8, bottom: 4),',
    'padding: const EdgeInsets.only(top: 2, bottom: 2),',
  );
  content = content.replaceAll(
    'color: Colors.white54,',
    'color: Colors.white54, size: 20,',
  );

  final target1 = '''          if (!_isCollapsed) ...[
            const SizedBox(height: 8),
            if (aiMode)
              _AiChatWithHealth(''';
  final repl1 = '''          if (!_isCollapsed) ...[
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: !aiMode ? const SizedBox.shrink() : _AiChatWithHealth(''';
  content = content.replaceAll(target1, repl1);

  final target2 = '''                onEnemyCpSaved: (value) {
                  final oldCp = enemy.combatPoints;
                  enemy.combatPoints = value.clamp(0, 99);
                  if (oldCp != enemy.combatPoints) {
                    adventure.log(
                      '[CP] \ CP: \ ➔ \ (Manual Adjustment)',
                    );
                  }
                  onChanged();
                },
              ),''';
  final repl2 = '''                onEnemyCpSaved: (value) {
                  final oldCp = enemy.combatPoints;
                  enemy.combatPoints = value.clamp(0, 99);
                  if (oldCp != enemy.combatPoints) {
                    adventure.log(
                      '[CP] \ CP: \ ➔ \ (Manual Adjustment)',
                    );
                  }
                  onChanged();
                },
              ),
            ),
            Container(
              width: 52,
              decoration: const BoxDecoration(
                color: Color(0x668f43ff),
                border: Border(
                  left: BorderSide(color: Colors.white12),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: showUndo ? onUndo : null,
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back,
                            color: showUndo ? Colors.white : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  Expanded(
                    child: _IntroPulse(
                      active: phase == CombatPhase.intro,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canAdvancePhase ? onNext : null,
                          child: Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_forward,
                              color: canAdvancePhase ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],''';
  content = content.replaceAll(target2, repl2);

  final target3 = '''    this.realityWarpActive = false,
    this.silenceActive = false,
    this.webbedActive = false,
    super.key,
  });''';
  final repl3 = '''    this.realityWarpActive = false,
    this.silenceActive = false,
    this.webbedActive = false,
    this.showUndo = false,
    this.onUndo,
    this.canAdvancePhase = false,
    this.onNext,
    super.key,
  });''';
  content = content.replaceAll(target3, repl3);

  final target4 = '''  final bool webbedActive;

  @override''';
  final repl4 = '''  final bool webbedActive;
  final bool showUndo;
  final VoidCallback? onUndo;
  final bool canAdvancePhase;
  final VoidCallback? onNext;

  @override''';
  content = content.replaceAll(target4, repl4);

  final introPulse = '''\n\nclass _IntroPulse extends StatefulWidget {
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
''';
  content += introPulse;

  file.writeAsStringSync(content);
}
