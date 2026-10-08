import 'dart:io';

void main() {
  final file = File('lib/parts/fight_widgets/turn_phase_panel.dart');
  String content = file.readAsStringSync();
  final index = content.indexOf('class _IntroPulse extends StatefulWidget {');
  if (index != -1) {
    content = content.substring(0, index).trim() + '\\n';
    file.writeAsStringSync(content);
  }
}
