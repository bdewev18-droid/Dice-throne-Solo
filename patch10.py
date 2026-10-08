import re

def fix_turn_phase_panel():
    path = "lib/parts/fight_widgets/turn_phase_panel.dart"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Constructor
    content = content.replace(
        "    required this.onNext,\n    required this.onApplyUpkeep,",
        "    required this.onNext,\n    required this.onSettings,\n    this.developerMode = false,\n    required this.onApplyUpkeep,"
    )
    # Fields
    content = content.replace(
        "  final VoidCallback onNext;\n  final VoidCallback onApplyUpkeep;",
        "  final VoidCallback onNext;\n  final VoidCallback onSettings;\n  final bool developerMode;\n  final VoidCallback onApplyUpkeep;"
    )
    # Button
    target_btn = '''              SizedBox(
                width: 52,
                height: 44,
                child: _IntroPulse(
                  active: phase == CombatPhase.intro,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: nextColor,
                      foregroundColor: Colors.black,
                    ),
                    tooltip: phase == CombatPhase.intro
                        ? 'Start fight'
                        : (phase == CombatPhase.minionUpkeep &&
                                  !upkeepApplied) ||
                              (phase == CombatPhase.heroUpkeep &&
                                  !heroUpkeepApplied)
                        ? 'Apply upkeep and continue'
                        : 'Next phase',
                    onPressed: canAdvance ? onNext : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),'''

    repl_btn = '''              SizedBox(
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
              ),'''
    content = content.replace(target_btn, repl_btn)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def fix_combat_dock():
    path = "lib/parts/fight_widgets/combat_ai_chat_dock.dart"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Handle shrink
    content = content.replace(
        "padding: const EdgeInsets.only(top: 8, bottom: 4),",
        "padding: const EdgeInsets.only(top: 2, bottom: 2),"
    )
    content = content.replace(
        "color: Colors.white54,",
        "color: Colors.white54, size: 20,"
    )

    # Constructor & Fields
    content = content.replace(
        "    this.webbedActive = false,\n    super.key,\n  });",
        "    this.webbedActive = false,\n    this.showUndo = false,\n    this.onUndo,\n    this.canAdvancePhase = false,\n    this.onNext,\n    super.key,\n  });"
    )
    content = content.replace(
        "  final bool webbedActive;\n  final ValueChanged<EnemyNode> onSelectTarget;",
        "  final bool webbedActive;\n  final bool showUndo;\n  final VoidCallback? onUndo;\n  final bool canAdvancePhase;\n  final VoidCallback? onNext;\n  final ValueChanged<EnemyNode> onSelectTarget;"
    )

    # Text wrapping
    target1 = '''          if (!_isCollapsed) ...[
            const SizedBox(height: 8),
            if (aiMode)
              _AiChatWithHealth('''
    repl1 = '''          if (!_isCollapsed) ...[
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: !aiMode ? const SizedBox.shrink() : _AiChatWithHealth('''
    content = content.replace(target1, repl1)

    # Back/Next arrows (safely grabbing the end)
    pattern2 = r"onEnemyCpSaved: \(value\) \{[\s\S]*?onChanged\(\);\s*\},\s*\),"
    match2 = re.search(pattern2, content)
    repl2 = match2.group(0) + '''
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
                        onTap: widget.showUndo ? widget.onUndo : null,
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back,
                            color: widget.showUndo ? Colors.white : Colors.white24,
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
                          onTap: widget.canAdvancePhase ? widget.onNext : null,
                          child: Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_forward,
                              color: widget.canAdvancePhase ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],'''
    content = content.replace(match2.group(0) + "\n          ],", repl2)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

fix_turn_phase_panel()
fix_combat_dock()
print("DONE")
