
import 'dart:io';
import 'dart:convert';
import '../lib/models/enemy_profile.dart';
import '../lib/data/enemy_profile_repository.dart';

void main() async {
  final source = File('docs/enemy_profiles.json').readAsStringSync();
  final json = jsonDecode(source) as Map<String, dynamic>;
  final rawProfiles = (json['profiles'] as List<dynamic>? ?? const []);
  final profiles = rawProfiles
      .whereType<Map<String, dynamic>>()
      .map(EnemyProfileJson.fromJson)
      .toList(growable: false);
      
  final fee = profiles.firstWhere((p) => p.key == 'fee');
  print('Fee passives length: ');
  for (final p in fee.passives) {
      print('Fee passive: ');
  }
}
