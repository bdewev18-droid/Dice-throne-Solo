import re

with open('lib/parts/fight.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Issue 1: Hide Dice Panel during intro.
# Find: _phase != CombatPhase.intro) \n CombatDicePanel
# Wait, actually it's:
#                  if (!_isCollapsed &&
#                      _phase != CombatPhase.heroUpkeep &&
#                      _phase != CombatPhase.minionUpkeep)
#                    CombatDicePanel(
# Let's add intro.
content = content.replace(
    "                  if (!_isCollapsed &&\n                      _phase != CombatPhase.heroUpkeep &&\n                      _phase != CombatPhase.minionUpkeep)\n                    CombatDicePanel(",
    "                  if (!_isCollapsed &&\n                      _phase != CombatPhase.heroUpkeep &&\n                      _phase != CombatPhase.minionUpkeep &&\n                      _phase != CombatPhase.intro)\n                    CombatDicePanel("
)

# Issue 2: Separate Attack and Defense rows in roll phase.
# Find:
#                  if (isRollPhase && !showResolution && !showStunCover) ...[
#                    const SizedBox(height: 12),
#                    IntrinsicHeight(
#                      child: Row(
#                        crossAxisAlignment: CrossAxisAlignment.stretch,
#                        children: [
#                          Expanded(
#                            child: _BattleCounter( ... attack ... ),
#                          ),
#                          const SizedBox(width: 8),
#                          Expanded(
#                            child: _BattleCounter( ... defense ... ),
#                          ),
#                          const SizedBox(width: 8),
#                          SizedBox(
#                            width: 52,
#                            child: FilledButton( ... OK ... ),
#                          ),
#                        ],
#                      ),
#                    ),
#                  ],
#
# Let's replace it with two separate blocks!
# One block for attack (if _phase == hero), and one for defense.
# But wait, the user said:
# "Je dois avoir (zone attaque (desription des attaque dépliée) puis zone dice dépliée avec le résultat du 1er jet puis la zone défense repliée car on est en zone d'attaque."
# Wait, the `_BattleCounter` is rendered inside `CombatAiChatDock`!
# Let's check where `isRollPhase && !showResolution` is.
