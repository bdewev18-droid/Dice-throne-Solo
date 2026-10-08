import re

path = "lib/parts/fight.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# I need to find IntrinsicHeight( that wraps CombatAiChatDock and remove it.
# Let's see the exact text.
pattern = r"IntrinsicHeight\(\s*child:\s*Row\(\s*crossAxisAlignment:\s*CrossAxisAlignment\.stretch,\s*children:\s*\[\s*Expanded\(\s*child:\s*(CombatAiChatDock\([\s\S]*?)\),\s*\),\s*Container\(\s*width:\s*52,\s*decoration:[\s\S]*?\]\s*,\s*\)\s*,\s*\)\s*,\s*\)"
match = re.search(pattern, content)
if match:
    print("Match found!")
    # We replace the whole IntrinsicHeight with just the CombatAiChatDock
    content = content.replace(match.group(0), match.group(1))
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
else:
    print("Match not found!")

