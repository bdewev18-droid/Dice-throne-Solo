import re

path = "lib/parts/fight.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

pattern = re.compile(r"            if \(showConstrictRow\) \.\.\.\[\n              const SizedBox\(height: 6\),\n              Container\(.*?              \),\n            \],", re.DOTALL)

replacement = """            if (showConstrictRow) ...[
              const SizedBox(height: 6),
              _MultiRollTokenActiveRow(
                label: 'Constrict',
                count: constrictCount,
                imagePath: 'assets/token/Constrict.png',
                fallbackIcon: Icons.link,
                color: isHeroTurn ? const Color(0xff8f43ff) : Colors.greenAccent,
                onUse: isHeroTurn ? onUseConstrict : null,
                isUsed: constrictUsed,
              ),
            ],"""

text = pattern.sub(replacement, text)

with open(path, "w", encoding="utf-8") as f:
    f.write(text)

print("done regex")
