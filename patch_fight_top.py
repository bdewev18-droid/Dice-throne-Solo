import re

with open('lib/parts/fight.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove EnemyFightHeader instantiation
content = re.sub(
    r"EnemyFightHeader\(\s*enemy:\s*enemy,\s*developerMode:\s*_developerMode,\s*showUndo:\s*_stepUndo\s*!=\s*null,\s*onUndo:\s*_undoStep,\s*onOpenSettings:\s*\(\)\s*=>\s*_openSettings\(context\),\s*\),\s*",
    "",
    content
)

# 2. Update CombatBottomDock instantiation
content = re.sub(
    r"onNext:\s*_handleNextStep,",
    r"onSettings: () => _openSettings(context),\n                    developerMode: _developerMode,",
    content
)

# 3. Add arguments to CombatAiChatDock
# Find the end of CombatAiChatDock arguments, which is `blindingLightRoll: _blindingLightRoll,`
content = re.sub(
    r"(blindingLightRoll:\s*_blindingLightRoll,)",
    r"\1\n                      showUndo: _stepUndo != null,\n                      onUndo: _undoStep,\n                      canAdvancePhase: canAdvancePhase,\n                      onNext: _handleNextStep,",
    content
)

# 4. Remove the `EnemyFightHeader` class definition completely.
# It starts with `class EnemyFightHeader extends StatelessWidget {` and ends before `class CombatStatusLine extends StatelessWidget {` or similar.
# Let's just find `class EnemyFightHeader` to `class ` and remove it.
content = re.sub(
    r"class EnemyFightHeader extends StatelessWidget \{[\s\S]*?(?=class [A-Z])",
    "",
    content
)

with open('lib/parts/fight.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("done")
