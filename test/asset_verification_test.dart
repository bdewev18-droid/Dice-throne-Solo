import 'dart:convert';
import 'dart:io';

import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/data/enemy_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Asset Verification Regression Tests', () {
    test('All HeroType assets exist', () {
      for (final hero in HeroType.values) {
        
        final file = File(hero.asset);
        expect(file.existsSync(), isTrue, reason: 'Hero asset missing for ${hero.name}: ${hero.asset}');
      }
    });

    test('All enemy preview assets from JSON exist', () {
      final file = File('docs/enemy_profiles.json');
      if (!file.existsSync()) return;

      final dynamic parsed = jsonDecode(file.readAsStringSync());
      final list = (parsed['profiles'] as List<dynamic>? ?? const []);

      for (var i = 0; i < list.length; i++) {
        final node = EnemyProfileJson.fromJson(list[i] as Map<String, dynamic>);
        final assetFile = File(node.cardAsset);
        expect(assetFile.existsSync(), isTrue, reason: 'Enemy asset missing for ${node.key}: ${node.cardAsset}');
      }
    });
  });
}
