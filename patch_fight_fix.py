import re

with open('lib/parts/fight.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Revert the mistake:
content = content.replace("""blindingLightRoll: _blindingLightRoll,
                      showUndo: _stepUndo != null,
                      onUndo: _undoStep,
                      canAdvancePhase: canAdvancePhase,
                      onNext: _handleNextStep,""", "blindingLightRoll: _blindingLightRoll,")

# 2. Add properties to CombatAiChatDock.
# CombatAiChatDock's arguments end at `blindingLightRoll: _blindingLightRoll,` which is line ~1100.
# The correct pattern for CombatAiChatDock is:
#                     blindingLightBaseAttack: _blindingLightBaseAttack,
#                     blindingLightRoll: _blindingLightRoll,
#                   ),
content = re.sub(
    r"(blindingLightBaseAttack:\s*_blindingLightBaseAttack,\s*blindingLightRoll:\s*_blindingLightRoll,)",
    r"\1\n                      showUndo: _stepUndo != null,\n                      onUndo: _undoStep,\n                      canAdvancePhase: canAdvancePhase,\n                      onNext: _handleNextStep,",
    content
)

with open('lib/parts/fight.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("done")
