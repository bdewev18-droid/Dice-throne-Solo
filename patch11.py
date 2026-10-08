import re

path = "lib/parts/fight_widgets/combat_ai_chat_dock.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(
    "active: phase == CombatPhase.intro,",
    "active: widget.phase == CombatPhase.intro,"
)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
