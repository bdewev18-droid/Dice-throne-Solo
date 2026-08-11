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
      defenseDisplayRows: _defenseDisplayRowsFromJson(json['defensePlan']),
      passiveDisplayRows: _displayRowsFromJson(json['passiveDisplayRows']),
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
          label2: (action['label2'] as String?)?.trim(),
          label3: (action['label3'] as String?)?.trim(),
          extraRoll: _extraRollFromJson(action['extraRoll']),
          align: action['align'] as String? ?? 'left',
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
        final damageFormula = (raw['damageFormula'] as String?)
            ?.trim()
            .toLowerCase();
        final label = (raw['label'] as String?)?.trim();
        // A "roll" damage formula with no face condition means the roll value
        // itself drives the damage — surfaced via rollText, not an outcome.
        // Token-only "any" effects become an `any` outcome for display.
        if (tokens.isNotEmpty && damageFormula != 'roll') {
          outcomes.add(
            ExtraRollOutcome(
              face: ExtraRollFace.any,
              label: label,
              tokens: tokens,
            ),
          );
        }
      }
    }

    final finalText = (value['finalText'] as String?)?.trim();
    final rollText =
        (value['rollText'] as String?)?.trim() ??
        (value['text'] as String?)?.trim() ??
        '';
    final mode = modeStr == 'simple'
        ? ExtraRollMode.simple
        : (modeStr == 'perFace'
              ? ExtraRollMode.perFace
              : (outcomes.isEmpty
                    ? ExtraRollMode.simple
                    : ExtraRollMode.perFace));
    final align = (value['align'] as String?)?.trim() ?? 'left';
    return MinionExtraRoll(
      dice: dice,
      mode: mode,
      align: align,
      rollText: rollText,
      outcomes: outcomes,
      finalText: (finalText != null && finalText.isNotEmpty) ? finalText : null,
      displayRows: _displayRowsFromJson(value['displayRows']),
    );
  }

  static List<DisplayRow> _displayRowsFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }
    final rows = <DisplayRow>[];
    for (final raw in value) {
      if (raw is! Map<String, dynamic>) continue;
      final align = (raw['align'] as String?)?.trim().toLowerCase() ?? 'left';
      final items = _stringList(raw['items']);
      if (items.isEmpty) continue;
      rows.add(DisplayRow(align: align, items: items));
    }
    return List<DisplayRow>.unmodifiable(rows);
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
          final y = _intValue(
            symbols['orange'] ?? symbols['yellow'],
            fallback: 0,
          );
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
      align: raw['align'] as String?,
    );
  }

  static MinionAttackPlan _attackPlanFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const MinionAttackPlan.none();
    }
    final style = value['style'] as String? ?? 'none';
    final displayRows = _displayRowsFromJson(value['displayRows']);
    final conditionalRules = _conditionalRulesFromJson(value['conditionalRules']);
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
          label2: (action['label2'] as String?)?.trim(),
          label3: (action['label3'] as String?)?.trim(),
          formulas: _stringList(action['formulas']),
        );
      }
      return MinionAttackPlan.suite(
        suiteEffects: suiteEffects,
        displayRows: displayRows,
        conditionalRules: conditionalRules,
      );
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
      return MinionAttackPlan.symbols(
        goals,
        displayRows: displayRows,
        conditionalRules: conditionalRules,
      );
    }
    return MinionAttackPlan.none(
      displayRows: displayRows,
      conditionalRules: conditionalRules,
    );
  }

  static List<DisplayRow> _defenseDisplayRowsFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const [];
    }
    return _displayRowsFromJson(value['displayRows']);
  }

  /// Parses the JSON `attackPlan.conditionalRules` array into
  /// [ConditionalRule]s. Supports two shapes:
  ///
  /// - **New (clean) format**: `{ condition: { type, count/... },
  ///   effect: { heroTokens, ... }, displayRows, exclusive }`.
  /// - **Legacy format**: `{ condition: "text", tokens, effects: {...},
  ///   text }` — converted into a display-only `text` rule carrying the
  ///   tokens as `heroTokens` and the authored `text`/`displayRows`.
  static List<ConditionalRule> _conditionalRulesFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }
    final rules = <ConditionalRule>[];
    for (final raw in value) {
      if (raw is! Map<String, dynamic>) continue;
      final rule = _conditionalRuleFromJson(raw);
      if (rule != null) rules.add(rule);
    }
    return List<ConditionalRule>.unmodifiable(rules);
  }

  static ConditionalRule? _conditionalRuleFromJson(Map<String, dynamic> raw) {
    final condition = _conditionFromConditionalJson(raw['condition']);
    if (condition == null) {
      // Legacy shape: `condition` is a plain string ("text") carrying the
      // authored rule text in a sibling `text` field. Promote it to a
      // display-only text rule so it stays visible without being
      // auto-applied by the generic runtime.
      final legacyText = (raw['text'] as String?)?.trim();
      if (legacyText == null || legacyText.isEmpty) return null;
      final legacyTokens = _stringList(raw['tokens']);
      return ConditionalRule(
        condition: const ConditionalCondition(
          type: ConditionalConditionType.text,
        ),
        effect: ConditionalEffect(heroTokens: legacyTokens, note: legacyText),
        displayRows: _displayRowsFromJson(raw['displayRows']),
        exclusive: false,
      );
    }
    final effect = _effectFromConditionalJson(
      raw['effect'],
      fallbackTokens: _stringList(raw['tokens']),
      fallbackText: (raw['text'] as String?)?.trim(),
    );
    return ConditionalRule(
      condition: condition,
      effect: effect,
      displayRows: _displayRowsFromJson(raw['displayRows']),
      exclusive: raw['exclusive'] as bool? ?? true,
      minRollCount: _intValue(raw['minRollCount'], fallback: 0),
    );
  }

  /// Parses the `condition` block of a conditional rule. Returns null when
  /// the block is missing or has no resolvable `type`.
  static ConditionalCondition? _conditionFromConditionalJson(Object? value) {
    if (value is String) {
      // Legacy: a bare "text" string. Treated as display-only.
      return ConditionalCondition(
        type: ConditionalConditionType.text,
        text: value.trim().isEmpty ? null : value.trim(),
      );
    }
    if (value is! Map<String, dynamic>) return null;
    final typeStr = (value['type'] as String?)?.trim().toLowerCase();
    final type = switch (typeStr) {
      'samevalue' => ConditionalConditionType.sameValue,
      'samesymbol' => ConditionalConditionType.sameSymbol,
      'suite' => ConditionalConditionType.suite,
      'symbols' => ConditionalConditionType.symbols,
      'attacksucceededand' || 'attackokand' =>
        ConditionalConditionType.attackSucceededAnd,
      'alteration' => ConditionalConditionType.alteration,
      'text' => ConditionalConditionType.text,
      _ => ConditionalConditionType.text,
    };
    if (typeStr == null || typeStr.isEmpty) return null;
    final inner = type == ConditionalConditionType.attackSucceededAnd
        ? _conditionFromConditionalJson(value['inner'])
        : null;
    final andRaw = value['and'];
    final and = <ConditionalCondition>[];
    if (andRaw is List) {
      for (final entry in andRaw) {
        if (entry is! Map<String, dynamic>) continue;
        final sub = _conditionFromConditionalJson(entry);
        if (sub != null) and.add(sub);
      }
    }
    return ConditionalCondition(
      type: type,
      count: _intValue(value['count'], fallback: 0),
      minLength: _intValue(value['minLength'] ?? value['length'], fallback: 0),
      white: _intValue(value['white'], fallback: 0),
      orange: _intValue(value['orange'] ?? value['yellow'], fallback: 0),
      red: _intValue(value['red'], fallback: 0),
      inner: inner,
      present: _stringList(value['present']),
      absent: _stringList(value['absent']),
      text: (value['text'] as String?)?.trim(),
      negate: value['negate'] as bool? ?? false,
      and: and,
    );
  }

  /// Parses the `effect` block, with legacy fallbacks (`tokens` at the rule
  /// root, `text` as a note) when the clean `effect` object is absent.
  static ConditionalEffect _effectFromConditionalJson(
    Object? value, {
    required List<String> fallbackTokens,
    required String? fallbackText,
  }) {
    if (value is! Map<String, dynamic>) {
      return ConditionalEffect(
        heroTokens: fallbackTokens,
        note: (fallbackText != null && fallbackText.isNotEmpty)
            ? fallbackText
            : null,
      );
    }
    final heroTokens = _stringList(value['heroTokens']);
    final minionTokens = _stringList(value['minionTokens']);
    final hasDamage = value['damage'] != null;
    final damageFormula = (value['damageFormula'] as String?)?.trim();
    return ConditionalEffect(
      heroTokens: heroTokens.isEmpty ? fallbackTokens : heroTokens,
      minionTokens: minionTokens,
      damage: hasDamage ? _intValue(value['damage'], fallback: 0) : null,
      damageFormula: (damageFormula != null && damageFormula.isNotEmpty)
          ? damageFormula
          : null,
      undefendable: value['undefendable'] as bool? ?? false,
      lifeSteal: _intValue(value['lifeSteal'] ?? value['stealHp'], fallback: 0),
      cpSteal: _intValue(value['cpSteal'] ?? value['stealCp'], fallback: 0),
      note: (value['note'] as String?)?.trim() ??
          ((fallbackText != null && fallbackText.isNotEmpty)
              ? fallbackText
              : null),
    );
  }
}
