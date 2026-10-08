import re

def fix_turn_phase_panel():
    path = "lib/parts/fight_widgets/turn_phase_panel.dart"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Constructor
    content = re.sub(
        r"required this\.onNext,",
        "required this.onNext,\n    required this.onSettings,\n    this.developerMode = false,",
        content
    )
    # Fields
    content = re.sub(
        r"final VoidCallback onNext;",
        "final VoidCallback onNext;\n  final VoidCallback onSettings;\n  final bool developerMode;",
        content
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def fix_combat_dock():
    path = "lib/parts/fight_widgets/combat_ai_chat_dock.dart"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Constructor
    content = re.sub(
        r"this\.webbedActive = false,",
        "this.webbedActive = false,\n    this.showUndo = false,\n    this.onUndo,\n    this.canAdvancePhase = false,\n    this.onNext,",
        content
    )
    # Fields
    content = re.sub(
        r"final bool webbedActive;",
        "final bool webbedActive;\n  final bool showUndo;\n  final VoidCallback? onUndo;\n  final bool canAdvancePhase;\n  final VoidCallback? onNext;",
        content
    )

    # Fix syntax error around 2652?
    # Let's just fix it if it's there. My replace earlier worked but maybe I made a syntax error in it?
    # Let's check if (onFinish != null)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

fix_turn_phase_panel()
fix_combat_dock()
print("DONE")
