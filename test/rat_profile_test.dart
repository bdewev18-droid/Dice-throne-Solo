import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rat de la Rue Regression Tests', () {
    test('Rat de la Rue retains validated French text for Chapardage', () {
      final file = File('docs/enemy_profiles.json');
      expect(file.existsSync(), isTrue, reason: 'enemy_profiles.json is missing');

      final content = file.readAsStringSync();
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final list = parsed['profiles'] as List<dynamic>;

      final ratProfile = list.firstWhere(
        (p) => p['name'] == 'Rat de la Rue',
        orElse: () => null,
      );

      expect(ratProfile, isNotNull, reason: 'Rat de la Rue profile should exist');

      final attackPlan = ratProfile['attackPlan'] as Map<String, dynamic>;
      final actions = attackPlan['actions'] as List<dynamic>;

      bool foundSmallSuiteText = false;
      bool foundLargeSuiteText = false;

      for (final action in actions) {
        final condition = action['condition'] as Map<String, dynamic>;
        if (condition['type'] == 'suite') {
          if (condition['suite'] == 'small') {
            expect(action['label3'], contains('& Nb CP = Damage'));
            foundSmallSuiteText = true;
          } else if (condition['suite'] == 'large') {
            expect(action['label3'], contains('& Nb CP = Damage'));
            foundLargeSuiteText = true;
          }
        }
      }

      expect(foundSmallSuiteText, isTrue, reason: 'Small suite should have the correct text formula');
      expect(foundLargeSuiteText, isTrue, reason: 'Large suite should have the correct text formula');
    });
  });
}
