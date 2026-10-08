import 'dart:io';
void main() {
  final file = File('lib/parts/fight_widgets/turn_phase_panel.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll(
    '                child: IconButton.filledTonal(\n                  tooltip: \\'Combat settings\\',\n                  onPressed: onSettings,\n                  style: IconButton.styleFrom(\n                    backgroundColor: Colors.black.withValues(alpha: 0.22),\n                    foregroundColor: developerMode\n                        ? Colors.orangeAccent\n                        : Colors.white.withValues(alpha: 0.8),\n                    side: BorderSide(\n                      color: Colors.white.withValues(alpha: 0.1),\n                    ),\n                  ),\n                  icon: const Icon(Icons.settings),\n                ),\n              ),\n            ]',
    '                child: IconButton.filledTonal(\n                  tooltip: \\'Combat settings\\',\n                  onPressed: onSettings,\n                  style: IconButton.styleFrom(\n                    backgroundColor: Colors.black.withValues(alpha: 0.22),\n                    foregroundColor: developerMode\n                        ? Colors.orangeAccent\n                        : Colors.white.withValues(alpha: 0.8),\n                    side: BorderSide(\n                      color: Colors.white.withValues(alpha: 0.1),\n                    ),\n                  ),\n                  icon: const Icon(Icons.settings),\n                ),\n              ),\n            ],'
  );
  file.writeAsStringSync(content);
}
