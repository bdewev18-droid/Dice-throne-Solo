import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/enemy_profile.dart';

class EnemyProfileRepository {
  const EnemyProfileRepository._();

  static List<EnemyProfile> _profiles = const [];

  static Future<void> load() async {
    try {
      final source = await rootBundle.loadString('docs/enemy_profiles.json');
      final json = jsonDecode(source) as Map<String, dynamic>;
      final rawProfiles = (json['profiles'] as List<dynamic>? ?? const []);
      _profiles = rawProfiles
          .whereType<Map<String, dynamic>>()
          .map(EnemyProfileJson.fromJson)
          .toList(growable: false);
    } catch (error) {
      debugPrint('Enemy profile JSON load failed: $error');
      _profiles = const [];
    }
  }

  static bool get isLoaded => _profiles.isNotEmpty;

  static List<EnemyProfile> byRank(EnemyRank rank) {
    return _profiles.where((profile) => profile.rank == rank).toList();
  }

  static EnemyProfile? byKey(String key) {
    for (final profile in _profiles) {
      if (profile.key == key) {
        return profile;
      }
    }
    return null;
  }
}

class EnemyProfileJson {
  const EnemyProfileJson._();

  static EnemyProfile fromJson(Map<String, dynamic> json) {
    final rank = _rankFromName(json['rank'] as String?) ?? EnemyRank.green;
    final rewardRank = _rankFromName(json['rewardRank'] as String?);
    return EnemyProfile(
      key: json['key'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown',
      rank: rank,
      maxHealth: _intValue(json['maxHealth'], fallback: 1),
      cp: _intValue(json['cp'] ?? json['pc'], fallback: 0),
      cardAsset: json['cardAsset'] as String? ?? rank.asset,
      initialTokens: _stringList(json['initialTokens']),
      rewardChests: _intValue(json['rewardChests'], fallback: 1),
      rewardRank: rewardRank,
      rewardRanks: _rankList(json['rewardRanks']),
      attacks: _stringList(json['attacks']),
      defense: json['defense'] as String? ?? '',
      defenseDice: _intValue(json['defenseDice'], fallback: 0),
      attackPlan: _attackPlanFromJson(json['attackPlan']),
    );
  }

  static EnemyRank? _rankFromName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final rank in EnemyRank.values) {
      if (rank.name == normalized) {
        return rank;
      }
    }
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static List<EnemyRank> _rankList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map(_rankFromName)
        .whereType<EnemyRank>()
        .toList(growable: false);
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  /// Finds the action whose symbol condition matches the given goal thresholds
  /// and returns its effects. Returns null when no matching action exists.
  static SymbolGoalEffect? _effectFromActions(
    List<Map<String, dynamic>> actions, {
    required int white,
    required int yellow,
    required int red,
  }) {
    for (final action in actions) {
      final condition = action['condition'];
      if (condition is! Map<String, dynamic>) {
        continue;
      }
      final symbols = condition['symbols'];
      if (symbols is! Map<String, dynamic>) {
        continue;
      }
      final matchesWhite = _intValue(symbols['white'], fallback: 0) == white;
      final matchesYellow =
          _intValue(symbols['orange'] ?? symbols['yellow'], fallback: 0) ==
          yellow;
      final matchesRed = _intValue(symbols['red'], fallback: 0) == red;
      if (matchesWhite && matchesYellow && matchesRed) {
        return SymbolGoalEffect(
          damage: _intValue(action['damage'], fallback: 0),
          undefendable: action['undefendable'] as bool? ?? false,
          stealHp: _intValue(action['stealHp'], fallback: 0),
          stealCp: _intValue(action['stealCp'], fallback: 0),
          heal: _intValue(action['heal'], fallback: 0),
          heroTokens: _stringList(action['tokens']),
          minionTokens: const [],
          label: (action['label'] as String?)?.trim(),
        );
      }
    }
    return null;
  }

  static MinionAttackPlan _attackPlanFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const MinionAttackPlan.none();
    }
    final style = value['style'] as String? ?? 'none';
    if (style == 'suite') {
      final actions = (value['actions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final suiteEffects = <int, SymbolGoalEffect>{};
      for (final action in actions) {
        final condition = action['condition'];
        if (condition is! Map<String, dynamic>) {
          continue;
        }
        if (condition['type'] != 'suite') {
          continue;
        }
        final length = _intValue(condition['length'], fallback: -1);
        if (length < 3) {
          continue;
        }
        suiteEffects[length] = SymbolGoalEffect(
          damage: _intValue(action['damage'], fallback: 0),
          undefendable: action['undefendable'] as bool? ?? false,
          stealHp: _intValue(action['stealHp'], fallback: 0),
          stealCp: _intValue(action['stealCp'], fallback: 0),
          heal: _intValue(action['heal'], fallback: 0),
          heroTokens: _stringList(action['tokens']),
          minionTokens: const [],
          label: (action['label'] as String?)?.trim(),
        );
      }
      return MinionAttackPlan.suite(suiteEffects: suiteEffects);
    }
    if (style == 'symbols') {
      final rawGoals = (value['goals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final actions = (value['actions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final goals = <SymbolGoal>[];
      for (final goal in rawGoals) {
        final white = _intValue(goal['white'], fallback: 0);
        final yellow = _intValue(goal['orange'] ?? goal['yellow'], fallback: 0);
        final red = _intValue(goal['red'], fallback: 0);
        goals.add(
          SymbolGoal(
            white: white,
            yellow: yellow,
            red: red,
            effect: _effectFromActions(
              actions,
              white: white,
              yellow: yellow,
              red: red,
            ),
          ),
        );
      }
      return MinionAttackPlan.symbols(goals);
    }
    return const MinionAttackPlan.none();
  }
}
