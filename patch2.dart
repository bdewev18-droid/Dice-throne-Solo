import 'dart:io';

void main() {
  final file = File('lib/parts/fight_widgets/turn_phase_panel.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll(
'''                child: _IntroPulse(
                  active: phase == CombatPhase.intro,
                  child: IconButton.filledTonal(
                    tooltip: 'Combat settings',
                    onPressed: onSettings,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.22),
                      foregroundColor: developerMode
                          ? Colors.orangeAccent
                          : Colors.white.withValues(alpha: 0.8),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                  ),
                ),''',
'''                child: IconButton.filledTonal(
                  tooltip: 'Combat settings',
                  onPressed: onSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.22),
                    foregroundColor: developerMode
                        ? Colors.orangeAccent
                        : Colors.white.withValues(alpha: 0.8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  icon: const Icon(Icons.settings),
                ),'''
  );
  file.writeAsStringSync(content);
}
