import re

with open('lib/parts/fight.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Swap 'heroHp' and 'enemyHp' in FightStatusPanel
# In `_FightStatusPanelState`, the build method has:
# `_buildEditorPair('enemyHp', 'heroHp')` -> Change to `_buildEditorPair('heroHp', 'enemyHp')`
# `_buildEditorPair('enemyCp', 'heroCp')` -> Change to `_buildEditorPair('heroCp', 'enemyCp')`
content = content.replace("_buildEditorPair('enemyHp', 'heroHp')", "_buildEditorPair('heroHp', 'enemyHp')")
content = content.replace("_buildEditorPair('enemyCp', 'heroCp')", "_buildEditorPair('heroCp', 'enemyCp')")

# 2. Split EnemyRulesPanel
# Currently it is:
#                         EnemyRulesPanel(
#                           enemy: enemy,
#                           phase: _phase,
#                           aiMode: _aiMode,
#                           developerMode: _developerMode,
#                           onDetails: _openAdventureDetails,
#                           onAbandon: _openPauseDialog,
#                           onExport: _openCombatExport,
#                           onRestartCombat: _restartCombatFromSettings,
#                           showUndo: _stepUndo != null,
#                           onUndo: _undoStep,
#                           attackKey: _attackRulesKey,
#                           defenseKey: _defenseRulesKey,
#                         ),
#                         if (_aiMode) ...[

# We need to replace the EnemyRulesPanel with ONLY the Attack part.
# Then we will place the Defense part AFTER the Dice zones.
# Wait, the Dice zones are:
#                         if (_aiMode) ...[
#                           if (_phase != CombatPhase.heroUpkeep && _phase != CombatPhase.minionUpkeep) ...[
#                             const SizedBox(height: 12),
#                             MinionAiPanel(...)
#                           ],
#                           // some other stuff...
#                         ] else if (!_aiMode) ...[
#                           const SizedBox(height: 12),
#                           DicePanel(...)
#                         ],

# Let's extract the exact text of `EnemyRulesPanel` block.
pattern_rules = r"(EnemyRulesPanel\(\s*enemy:\s*enemy,\s*phase:\s*_phase,\s*aiMode:\s*_aiMode,\s*developerMode:\s*_developerMode,\s*onDetails:\s*_openAdventureDetails,\s*onAbandon:\s*_openPauseDialog,\s*onExport:\s*_openCombatExport,\s*onRestartCombat:\s*_restartCombatFromSettings,\s*showUndo:\s*_stepUndo\s*!=\s*null,\s*onUndo:\s*_undoStep,\s*attackKey:\s*_attackRulesKey,\s*defenseKey:\s*_defenseRulesKey,\s*\),)"
match = re.search(pattern_rules, content)
if match:
    full_rules_text = match.group(1)
    attack_rules_text = full_rules_text.replace("),", "  showOnlyAttack: true,\n                        ),")
    defense_rules_text = full_rules_text.replace("),", "  showOnlyDefense: true,\n                        ),")
    
    # Replace original with Attack
    content = content.replace(full_rules_text, attack_rules_text)
    
    # Now we need to insert the Defense block AFTER the Dice blocks.
    # Where does the `] else if (!_aiMode) ... [` block end?
    # It ends before:
    #                         if (_specialAttackReady && !_aiMode) ...[
    # Let's insert it right before `if (_specialAttackReady && !_aiMode) ...[`
    insert_target = "if (_specialAttackReady && !_aiMode) ...["
    if insert_target in content:
        content = content.replace(
            insert_target,
            f"const SizedBox(height: 12),\n                        {defense_rules_text}\n                          {insert_target}"
        )
    else:
        print("Could not find insert target for defense rules")

# 3. Hide MinionAiPanel and DicePanel during Intro
# For MinionAiPanel:
# if (_phase != CombatPhase.heroUpkeep && _phase != CombatPhase.minionUpkeep) ...[
content = content.replace(
    "if (_phase != CombatPhase.heroUpkeep && _phase != CombatPhase.minionUpkeep) ...[",
    "if (_phase != CombatPhase.heroUpkeep && _phase != CombatPhase.minionUpkeep && _phase != CombatPhase.intro) ...["
)

# For DicePanel, it's not wrapped in a phase check right now.
# Wait, it's inside `else if (!_aiMode) ...[`
#                           const SizedBox(height: 12),
#                           DicePanel(
# Let's wrap DicePanel in a phase check.
content = content.replace(
    "                          const SizedBox(height: 12),\n                          DicePanel(",
    "                          if (_phase != CombatPhase.heroUpkeep && _phase != CombatPhase.minionUpkeep && _phase != CombatPhase.intro) ...[\n                            const SizedBox(height: 12),\n                            DicePanel("
)
# We also need to close the `...[` we just opened.
# DicePanel ends with `),`
# Then there's `if (_specialAttackReady && !_aiMode) ...[`
# We can find `                          ),` before `if (_specialAttackReady && !_aiMode) ...[`
# Wait, it's safer to use regex to find the end of DicePanel.
# DicePanel ends with `                              rollLabel: ...\n                            ),`
dice_panel_end_pattern = r"(rollLabel:\s*_phase\s*==\s*CombatPhase\.hero[\s\S]*?\),\s*)"
match = re.search(dice_panel_end_pattern, content)
if match:
    content = content.replace(match.group(1), match.group(1) + "                          ],\n")

with open('lib/parts/fight.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("done")
