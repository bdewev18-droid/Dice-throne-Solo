import 'dart:io';

void main() {
  final file = File('lib/parts/fight_widgets/turn_phase_panel.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst(
'''    required this.onPhaseChanged,
    required this.onNext,
    this.canAdvance = true,
    this.upkeepApplied = false,
    this.heroUpkeepApplied = false,
    super.key,
  });''',
'''    required this.onPhaseChanged,
    required this.onSettings,
    this.developerMode = false,
    required this.onNext,
    this.canAdvance = true,
    this.upkeepApplied = false,
    this.heroUpkeepApplied = false,
    super.key,
  });'''
  );

  content = content.replaceFirst(
'''  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onNext;
  final bool canAdvance;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;

  @override''',
'''  final ValueChanged<CombatPhase> onPhaseChanged;
  final VoidCallback onSettings;
  final bool developerMode;
  final VoidCallback onNext;
  final bool canAdvance;
  final bool upkeepApplied;
  final bool heroUpkeepApplied;

  @override'''
  );
  file.writeAsStringSync(content);
}
