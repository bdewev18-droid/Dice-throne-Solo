import re

with open('lib/parts/fight.dart', 'r', encoding='utf-8') as f:
    content = f.read()

open_enemy_card_code = """
  void _openEnemyCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(child: Image.asset(enemy.cardAsset)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
"""

if "_openEnemyCard" not in content:
    content = content.replace("void _openSettings(BuildContext context) {", open_enemy_card_code + "\n  void _openSettings(BuildContext context) {")

# We want to wrap the SettingsActionTiles in a Row.
# First, let's extract the tiles part.
settings_tiles_pattern = r"(_SettingsActionTile\(\s*icon:\s*Icons\.receipt_long,[\s\S]*?onTap:\s*_openPauseDialog,\s*\),)"
match = re.search(settings_tiles_pattern, content)
if match:
    tiles_content = match.group(1)
    
    new_layout = f"""
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
{tiles_content}
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: InkWell(
                            onTap: () {{
                              Navigator.of(context).pop();
                              _openEnemyCard(context);
                            }},
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                enemy.cardAsset,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),"""
    content = content.replace(tiles_content, new_layout)

with open('lib/parts/fight.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("done")
