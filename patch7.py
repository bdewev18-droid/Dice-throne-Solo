import re

path = "lib/parts/fight_widgets/combat_ai_chat_dock.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace block around onEnemyCpSaved
pattern = r"(onEnemyCpSaved:\s*\(value\)\s*\{\s*final oldCp = enemy\.combatPoints;\s*enemy\.combatPoints = value\.clamp\(0, 99\);\s*if \(oldCp != enemy\.combatPoints\)\s*\{\s*adventure\.log\(\s*'\[CP\] [^']+'\s*,\s*\);\s*\}\s*onChanged\(\);\s*\},\s*\),)"
match = re.search(pattern, content)
print("Match found:", match is not None)

# It's easier to just find onEnemyCpSaved: (value) { ... },\n              ),
# Let's do a more robust regex
pattern2 = r"onEnemyCpSaved: \(value\) \{[\s\S]*?onChanged\(\);\s*\},\s*\),"
match2 = re.search(pattern2, content)
print("Match2 found:", match2 is not None)

if match2:
    repl = match2.group(0) + '''
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
'''
    content = content.replace(match2.group(0), repl)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

