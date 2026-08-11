import 'dart:convert';
import 'dart:io';

import 'package:dice_throne_survie/data/enemy_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JSON Parsing Regression Tests', () {
    test('docs/enemy_profiles.json can be read and parsed', () {
      final file = File('docs/enemy_profiles.json');
      expect(file.existsSync(), isTrue, reason: 'enemy_profiles.json is missing');

      final content = file.readAsStringSync();
      expect(content, isNotEmpty, reason: 'enemy_profiles.json is empty');

      final dynamic parsed = jsonDecode(content);
      expect(parsed, isA<Map<String, dynamic>>(), reason: 'Root should be a map');
      
      final list = (parsed as Map<String, dynamic>)['profiles'] as List<dynamic>;
      expect(list.isNotEmpty, isTrue, reason: 'Profile list should not be empty');

      for (var i = 0; i < list.length; i++) {
        final item = list[i] as Map<String, dynamic>;
        expect(item['key'], isNotNull, reason: 'Item \ missing key');
        expect(item['name'], isNotNull, reason: 'Item \ missing name');
        expect(item['rank'], isNotNull, reason: 'Item \ missing rank');
        
        final node = EnemyProfileJson.fromJson(list[i] as Map<String, dynamic>);
        expect(node.key, isNotEmpty);
      }
    });
  });
}
