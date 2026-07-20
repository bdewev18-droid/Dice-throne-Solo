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
      pc: _intValue(json['cp'] ?? json['pc'], fallback: 0),
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

  static MinionAttackPlan _attackPlanFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const MinionAttackPlan.none();
    }
    final style = value['style'] as String? ?? 'none';
    if (style == 'suite') {
      return const MinionAttackPlan.suite();
    }
    if (style == 'symbols') {
      final goals = (value['goals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (goal) => SymbolGoal(
              white: _intValue(goal['white'], fallback: 0),
              yellow: _intValue(goal['orange'] ?? goal['yellow'], fallback: 0),
              red: _intValue(goal['red'], fallback: 0),
            ),
          )
          .toList(growable: false);
      return MinionAttackPlan.symbols(goals);
    }
    return const MinionAttackPlan.none();
  }
}
