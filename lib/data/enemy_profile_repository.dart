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
      passives: _passivesFromJson(json),
    );
  }

  /// Merges root-level `passives` with `attackPlan.passives`, preserving the
  /// JSON declaration order. Dedupes by `text` so a passive declared both at
  /// the root and inside the attack plan is only listed once.
  static List<MinionPassive> _passivesFromJson(Map<String, dynamic> json) {
    final merged = <MinionPassive>[];
    final seen = <String>{};

    void addAll(Object? raw) {
      if (raw is! List) return;
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        final passive = MinionPassive.fromJson(entry);
        if (passive.text.isEmpty) continue;
        if (seen.add(passive.text)) {
          merged.add(passive);
        }
      }
    }

    addAll(json['passives']);
    final attackPlan = json['attackPlan'];
    if (attackPlan is Map<String, dynamic>) {
      addAll(attackPlan['passives']);
    }
    return List<MinionPassive>.unmodifiable(merged);
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
          extraRoll: _extraRollFromJson(action['extraRoll']),
        );
      }
    }
    return null;
  }

  /// Parses the JSON `extraRoll` block into a [MinionExtraRoll] for display.
  ///
  /// Supports the unified structure (`mode`/`rollText`/`outcomes`/`finalText`)
  /// and falls back to the legacy shapes (`{dice, text}`, `{dice, outcomes}`,
  /// `{dice, effects}`) so the display stays correct while the JSON is being
  /// migrated. Returns null when the block is absent or empty.
  static MinionExtraRoll? _extraRollFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final dice = _intValue(value['dice'], fallback: 0);
    if (dice <= 0) {
      return null;
    }
    final modeStr = (value['mode'] as String?)?.trim().toLowerCase();
    final outcomesRaw = value['outcomes'];
    final effectsRaw = value['effects'];
    final outcomes = <ExtraRollOutcome>[];

    // Unified / legacy per-face outcomes.
    if (outcomesRaw is List) {
      for (final raw in outcomesRaw) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        final outcome = _outcomeFromJson(raw);
        if (outcome != null) {
          outcomes.add(outcome);
        }
      }
    }
    // Legacy `{dice, effects[{condition:"any", damageFormula, tokens}]}`.
    if (effectsRaw is List) {
      for (final raw in effectsRaw) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }
        final tokens = _stringList(raw['tokens']);
        final damageFormula =
            (raw['damageFormula'] as String?)?.trim().toLowerCase();
        final label = (raw['label'] as String?)?.trim();
        // A "roll" damage formula with no face condition means the roll value
        // itself drives the damage — surfaced via rollText, not an outcome.
        // Token-only "any" effects become an `any` outcome for display.
        if (tokens.isNotEmpty && damageFormula != 'roll') {
          outcomes.add(ExtraRollOutcome(
            face: ExtraRollFace.any,
            label: label,
            tokens: tokens,
          ));
        }
      }
    }

    final finalText = (value['finalText'] as String?)?.trim();
    final rollText = (value['rollText'] as String?)?.trim() ??
        (value['text'] as String?)?.trim() ??
        '';
    final mode = modeStr == 'simple'
        ? ExtraRollMode.simple
        : (modeStr == 'perFace'
            ? ExtraRollMode.perFace
            : (outcomes.isEmpty
                ? ExtraRollMode.simple
                : ExtraRollMode.perFace));
    return MinionExtraRoll(
      dice: dice,
      mode: mode,
      rollText: rollText,
      outcomes: outcomes,
      finalText: (finalText != null && finalText.isNotEmpty) ? finalText : null,
    );
  }

  /// Parses one outcome entry (unified `face`/`label`/`damage`/... or legacy
  /// `condition.symbols`-keyed outcome).
  static ExtraRollOutcome? _outcomeFromJson(Map<String, dynamic> raw) {
    final faceStr = (raw['face'] as String?)?.trim().toLowerCase();
    ExtraRollFace face;
    if (faceStr == 'white') {
      face = ExtraRollFace.white;
    } else if (faceStr == 'yellow' || faceStr == 'orange') {
      face = ExtraRollFace.yellow;
    } else if (faceStr == 'red') {
      face = ExtraRollFace.red;
    } else if (faceStr == 'any') {
      face = ExtraRollFace.any;
    } else {
      // Legacy: derive face from condition.symbols.
      final cond = raw['condition'];
      if (cond is Map<String, dynamic>) {
        final symbols = cond['symbols'];
        if (symbols is Map<String, dynamic>) {
          final w = _intValue(symbols['white'], fallback: 0);
          final y = _intValue(symbols['orange'] ?? symbols['yellow'], fallback: 0);
          final r = _intValue(symbols['red'], fallback: 0);
          if (w > 0) {
            face = ExtraRollFace.white;
          } else if (r > 0) {
            face = ExtraRollFace.red;
          } else if (y > 0) {
            face = ExtraRollFace.yellow;
          } else {
            face = ExtraRollFace.any;
          }
        } else {
          face = ExtraRollFace.any;
        }
      } else {
        face = ExtraRollFace.any;
      }
    }
    final label = (raw['label'] as String?)?.trim();
    return ExtraRollOutcome(
      face: face,
      label: label,
      damage: _intValue(raw['damage'], fallback: 0),
      undefendable: raw['undefendable'] as bool? ?? false,
      stealHp: _intValue(raw['stealHp'], fallback: 0),
      stealCp: _intValue(raw['stealCp'], fallback: 0),
      tokens: _stringList(raw['tokens']),
    );
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
