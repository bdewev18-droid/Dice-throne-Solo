import re

path = "lib/parts/fight_widgets/turn_phase_panel.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("    required this.onNext,\n", "")
content = content.replace("  final VoidCallback onNext;\n", "")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
