import 'dart:io';

void main() {
  final file = File('lib/parts/fight_widgets/turn_phase_panel.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll(
'''              SizedBox(
                width: 52,
                height: 44,
                child: _IntroPulse(
                  active: phase == CombatPhase.intro,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: nextColor,
                      foregroundColor: Colors.black,
                    ),
                    tooltip: phase == CombatPhase.intro
                        ? 'Start fight'
                        : (phase == CombatPhase.minionUpkeep &&
                                  !upkeepApplied) ||
                              (phase == CombatPhase.heroUpkeep &&
                                  !heroUpkeepApplied)
                        ? 'Apply upkeep and continue'
                        : 'Next phase',
                    onPressed: canAdvance ? onNext : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),''',
'''              SizedBox(
                width: 52,
                height: 52,
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
              ),'''
  );
  file.writeAsStringSync(content);
}
