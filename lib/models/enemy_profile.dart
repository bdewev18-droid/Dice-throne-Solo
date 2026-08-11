import 'package:flutter/material.dart';

enum EnemyRank {
  green('Level 1', 1, Color(0xff34d36d), 'assets/map_green.jpg'),
  blue('Level 2', 2, Color(0xff3bb9ff), 'assets/map_blue.png'),
  violet('Level 3', 3, Color(0xff9b58ff), 'assets/map_violet.png'),
  viseer('Viseer', 4, Color(0xffff8a2b), 'assets/viser.webp'),
  orange('Level 4', 6, Color(0xffff8a2b), 'assets/map_orange.png'),
  naraxus('Naraxus', 0, Color(0xffd51f2a), 'assets/home_background_v4.png');

  const EnemyRank(this.label, this.points, this.color, this.asset);

  final String label;
  final int points;
  final Color color;
  final String asset;

  String get rewardChestKey {
    return switch (this) {
      EnemyRank.green => 'green',
      EnemyRank.blue => 'blue',
      EnemyRank.violet => 'violet',
      EnemyRank.orange => 'orange',
      EnemyRank.viseer => 'orange',
      EnemyRank.naraxus => 'orange',
    };
  }
}

class EnemyProfile {
  const EnemyProfile({
    required this.key,
    required this.name,
    required this.rank,
    required this.maxHealth,
    required this.cp,
    required this.cardAsset,
    required this.attacks,
    required this.defense,
    required this.defenseDice,
    required this.attackPlan,
    this.initialTokens = const [],
    this.rewardChests = 1,
    this.rewardRank,
    this.rewardRanks = const [],
    this.passives = const [],
    this.defenseDisplayRows = const [],
    this.passiveDisplayRows = const [],
  });

  final String key;
  final String name;
  final EnemyRank rank;
  final int maxHealth;
  final int cp;
  final String cardAsset;
  final List<String> attacks;
  final String defense;
  final int defenseDice;
  final MinionAttackPlan attackPlan;
  final List<String> initialTokens;
  final int rewardChests;
  final EnemyRank? rewardRank;
  final List<EnemyRank> rewardRanks;

  /// Passive abilities declared for this profile, parsed from the JSON
  /// `passives` array (root) merged with `attackPlan.passives`. Each entry
  /// carries a localized text and optional structured effects. The JSON is
  /// the source of truth; the UI renders these when no dedicated hard-coded
  /// view exists for the profile.
  final List<MinionPassive> passives;

  /// Optional authored defense display rows parsed from defensePlan.displayRows.
  final List<DisplayRow> defenseDisplayRows;

  /// Optional authored passive display rows parsed from root passiveDisplayRows.
  final List<DisplayRow> passiveDisplayRows;
}

enum MinionAttackStyle { symbols, suite, none }

class SymbolGoal {
  const SymbolGoal({
    this.white = 0,
    this.yellow = 0,
    this.red = 0,
    this.effect,
  });

  final int white;
  final int yellow;
  final int red;

  /// Effects associated with this goal when it is met, as declared in the
  /// JSON `attackPlan.actions` array. May be null when the JSON only provides
  /// a goals list without per-action effects (legacy/simple profiles).
  final SymbolGoalEffect? effect;

  /// Equality based on the symbol thresholds only, so that two goals with the
  /// same white/yellow/red counts are considered the same target regardless of
  /// their attached effect (used when matching a goal against attackPlan.goals).
  @override
  bool operator ==(Object other) {
    return other is SymbolGoal &&
        other.white == white &&
        other.yellow == yellow &&
        other.red == red;
  }

  @override
  int get hashCode => Object.hash(white, yellow, red);
}

/// Per-goal attack effects parsed from the JSON `attackPlan.actions` entry.
///
/// The JSON is the source of truth for damage and flags; reading these values
/// directly avoids fragile text parsing of the localized `attacks` strings.
class SymbolGoalEffect {
  const SymbolGoalEffect({
    this.damage = 0,
    this.undefendable = false,
    this.stealHp = 0,
    this.stealCp = 0,
    this.heal = 0,
    this.heroTokens = const [],
    this.minionTokens = const [],
    this.label,
    this.label2,
    this.label3,
    this.extraRoll,
    this.align = 'left',
    this.formulas = const [],
  });

  final int damage;
  final bool undefendable;
  final int stealHp;
  final int stealCp;
  final int heal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final String? label;
  final String? label2;
  final String? label3;
  final List<String> formulas;

  /// Optional additional dice roll triggered when this goal's attack
  /// succeeds. Parsed from the JSON `attackPlan.actions[].extraRoll` block.
  /// Used only for the attack display (the runtime resolution stays keyed on
  /// `profileKey`); null when the action has no extra roll.
  final MinionExtraRoll? extraRoll;

  /// The horizontal alignment of this action's main goal line ('left' or 'center').
  final String align;
}

/// Face of a die referenced by an [ExtraRollOutcome].
///
/// `any` means the outcome applies regardless of the rolled face (e.g. a token
/// applied systematically, like Homme Lezard's "À Terre").
enum ExtraRollFace { white, yellow, red, any }

/// Mode of an extra roll.
///
/// - `simple` : the roll value itself drives the effect (e.g. "deal damage
///   equal to the total roll value"). No per-face outcome is shown.
/// - `perFace` : the effect depends on the face obtained; one
///   [ExtraRollOutcome] is rendered per face.
enum ExtraRollMode { simple, perFace }

/// A single per-face outcome of an [MinionExtraRoll] (e.g. "white: deal 5
/// undefendable damage"). The `label` is the localized result text shown to
/// the right of the die symbol; structured fields drive the badges.
class ExtraRollOutcome {
  const ExtraRollOutcome({
    required this.face,
    this.label,
    this.damage = 0,
    this.undefendable = false,
    this.stealHp = 0,
    this.stealCp = 0,
    this.tokens = const [],
    this.align,
  });

  final ExtraRollFace face;
  final String? label;
  final int damage;
  final bool undefendable;
  final int stealHp;
  final int stealCp;
  final List<String> tokens;
  final String? align;
}

/// Additional dice roll triggered by a successful attack.
///
/// Source of truth for the **display** of the extra-roll attacks (Roc, Oni,
/// Mage de l'Entropie, Mage Lezard, Homme Lezard, Disciple, Yokai). The
/// runtime resolution (`_resolveExtraDicePhase`) is intentionally not driven
/// by this model to avoid changing gameplay.
class MinionExtraRoll {
  const MinionExtraRoll({
    required this.dice,
    required this.mode,
    this.align = 'left',
    required this.rollText,
    this.outcomes = const [],
    this.finalText,
    this.displayRows = const [],
  });

  /// Number of additional dice to roll.
  final int dice;

  /// Whether the effect depends on the face (`perFace`) or just the roll
  /// value (`simple`).
  final ExtraRollMode mode;

  /// The horizontal alignment of this extra roll section ('left' or 'center').
  final String align;

  /// Line-2 text shown beside the roll icon (e.g.
  /// "Si l'attaque réussit, lancez 1 dé.").
  final String rollText;

  /// Per-face outcomes (L3-5). Empty for `simple` mode rolls whose only
  /// per-roll effect is the token-less "any" outcome can still appear here.
  final List<ExtraRollOutcome> outcomes;

  /// Optional line-6 final effect text computed after the roll (e.g.
  /// "Puis inflige 7 dégâts + nb Chaos."). Rendered via [InlineTokenText].
  final String? finalText;

  /// Optional authored rows for fine display control. When present, these rows
  /// replace the default roll/outcome/final text block for this extra roll.
  final List<DisplayRow> displayRows;
}

enum ConditionalConditionType {
  /// N identical die *values* (e.g. three 4s). Matches when at least one
  /// value appears `count` times among the rolled dice.
  sameValue,

  /// N identical die *symbols/faces* (e.g. four orange). Matches when at
  /// least one symbol appears `count` times.
  sameSymbol,

  /// A straight (suite) of at least `minLength` consecutive values.
  suite,

  /// A symbol goal (white/orange/red thresholds) is met, as for a regular
  /// attack action.
  symbols,

  /// The attack succeeded (a non-null attack result) AND the `inner`
  /// sub-condition is met. Used for rules like "successful attack + 3
  /// identical values".
  attackSucceededAnd,

  /// Presence/absence of alterations (tokens) on the minion. Matches when
  /// all `present` tokens are set and none of `absent` are. Used for
  /// form-dependent rules (e.g. Druid bear/elk form via 'Forme Elan').
  alteration,

  /// Free-form authored rule (display-only; never auto-applied by the
  /// generic runtime). Carries a `text` used for display.
  text,
}

/// Condition part of a [ConditionalRule].
///
/// Parsed from the JSON `conditionalRules[].condition` block. The `type`
/// field selects which predicate the runtime evaluates; the remaining
/// fields are only meaningful for the matching type. `negate` inverts the
/// predicate (used for "passive when goal NOT met" rules). `and` adds a
/// conjunctive sub-condition evaluated alongside the primary predicate,
/// allowing compound rules like `symbols(yellow:3) AND alteration(absent
/// 'Forme Elan')`.
class ConditionalCondition {
  const ConditionalCondition({
    required this.type,
    this.count = 0,
    this.minLength = 0,
    this.white = 0,
    this.orange = 0,
    this.red = 0,
    this.inner,
    this.present = const [],
    this.absent = const [],
    this.text,
    this.negate = false,
    this.and = const [],
  });

  final ConditionalConditionType type;
  final int count;
  final int minLength;
  final int white;

  /// Orange symbol threshold (JSON historically uses `orange`; `yellow` is
  /// accepted as an alias during parsing).
  final int orange;
  final int red;

  /// Sub-condition for `attackSucceededAnd` rules.
  final ConditionalCondition? inner;

  /// Alterations that must be present (and `absent` that must be missing)
  /// for an `alteration` condition to match.
  final List<String> present;
  final List<String> absent;

  /// Free-form label for `text` rules (display-only).
  final String? text;

  /// Inverts the predicate when true (e.g. "goal NOT met").
  final bool negate;

  /// Additional conjunctive sub-conditions (all must also match).
  final List<ConditionalCondition> and;
}

/// Effect applied when a [ConditionalRule]'s condition is met.
///
/// Mirrors the structured fields used by [SymbolGoalEffect] so the runtime
/// can apply the outcome without text parsing. Tokens target the hero
/// (`heroTokens`) or the minion (`minionTokens`). `damage` overrides the
/// attack damage when non-null (0 cancels it); `damageFormula` is an
/// alternative to `damage` for state-dependent damage (e.g. "cp+cpSteal").
class ConditionalEffect {
  const ConditionalEffect({
    this.heroTokens = const [],
    this.minionTokens = const [],
    this.damage,
    this.damageFormula,
    this.undefendable = false,
    this.lifeSteal = 0,
    this.cpSteal = 0,
    this.note,
  });

  final List<String> heroTokens;
  final List<String> minionTokens;

  /// When non-null, overrides the attack damage (0 cancels it).
  final int? damage;

  /// When non-null, overrides the attack damage with a state-dependent
  /// formula. Supported: `cp` (minion's CP), `cp+cpSteal` (CP plus the
  /// cpSteal applied by this very rule). Mutually exclusive with [damage].
  final String? damageFormula;
  final bool undefendable;
  final int lifeSteal;
  final int cpSteal;
  final String? note;
}

/// A bonus/conditional attack rule that is not a primary attack action.
///
/// Examples: "If you roll 3 identical values, inflict Silence",
/// "4 identical symbols: minion gains Riposte", "Large suite: steal 1 CP".
///
/// Rules are evaluated in declaration order. When a rule carries
/// [exclusive] (default `true`), the first matching rule wins and the
/// remaining rules are skipped — this models the `if / else if` cascades
/// previously hard-coded per enemy (e.g. Rat de la Rue, Hemo-Siphon). Set
/// [exclusive] to `false` for independent rules that should all fire.
///
/// `minRollCount` gates the rule on the number of dice rolled this attack
/// (used for passives like Roc's "failed offensive roll" which needs
/// `rollCount >= 3`).
///
/// `displayRows` is the authored (or Generate-produced) rendering shown in
/// the combat UI alongside the attack actions.
class ConditionalRule {
  const ConditionalRule({
    required this.condition,
    required this.effect,
    this.displayRows = const [],
    this.exclusive = true,
    this.minRollCount = 0,
  });

  final ConditionalCondition condition;
  final ConditionalEffect effect;
  final List<DisplayRow> displayRows;
  final bool exclusive;
  final int minRollCount;
}

class DisplayRow {
  const DisplayRow({this.align = 'left', this.items = const []});

  final String align;
  final List<String> items;
}

class MinionAttackPlan {
  const MinionAttackPlan.symbols(
    this.goals, {
    this.displayRows = const [],
    this.conditionalRules = const [],
  }) : style = MinionAttackStyle.symbols,
       suiteEffects = const {};

  const MinionAttackPlan.suite({
    this.suiteEffects = const {},
    this.displayRows = const [],
    this.conditionalRules = const [],
  }) : style = MinionAttackStyle.suite,
       goals = const [];

  const MinionAttackPlan.none({
    this.displayRows = const [],
    this.conditionalRules = const [],
  }) : style = MinionAttackStyle.none,
       goals = const [],
       suiteEffects = const {};

  final MinionAttackStyle style;
  final List<SymbolGoal> goals;

  /// Effects per suite length (3/4/5) for suite-style plans, parsed from the
  /// JSON `attackPlan.actions` array. Empty for symbols/none plans.
  final Map<int, SymbolGoalEffect> suiteEffects;

  /// Optional authored display rows. When present, combat UI uses these rows
  /// before falling back to the generated symbol/suite summary.
  final List<DisplayRow> displayRows;

  /// Bonus/conditional rules attached to this attack plan, parsed from the
  /// JSON `attackPlan.conditionalRules` array. The generic runtime applies
  /// them after the primary attack resolution; the first matching exclusive
  /// rule wins. Display-only `text` rules are surfaced but never auto-applied.
  final List<ConditionalRule> conditionalRules;
}

/// A passive ability attached to an enemy profile.
///
/// Parsed from the JSON `passives` entries (either at the profile root or
/// inside `attackPlan.passives`). The `text` is the localized description
/// shown in the UI passive zone; `timing` describes when it triggers
/// (e.g. `offensiveRollFailed`, `upkeep`). `effect` mirrors the structured
/// fields used by the attack/defense plans so the engine can apply it
/// deterministically without parsing the text.
class MinionPassive {
  const MinionPassive({required this.text, this.timing, this.effect});

  factory MinionPassive.fromJson(Map<String, dynamic> json) {
    final text = (json['text'] as String?)?.trim() ?? '';
    final timing = (json['timing'] as String?)?.trim();
    final effectsJson = json['effects'];
    MinionPassiveEffect? effect;
    if (effectsJson is Map<String, dynamic>) {
      effect = MinionPassiveEffect(
        damage: _asInt(effectsJson['damage']),
        undefendable: effectsJson['undefendable'] as bool? ?? false,
        stealHp: _asInt(effectsJson['stealHp']),
        stealCp: _asInt(effectsJson['stealCp']),
        heal: _asInt(effectsJson['heal']),
        heroTokens: _asStringList(effectsJson['tokens']),
      );
    }
    return MinionPassive(text: text, timing: timing, effect: effect);
  }

  final String text;
  final String? timing;
  final MinionPassiveEffect? effect;

  @override
  String toString() => text;

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}

/// Structured effects for a [MinionPassive], mirroring the fields used by
/// [SymbolGoalEffect] so the engine can apply passive outcomes without text
/// parsing.
class MinionPassiveEffect {
  const MinionPassiveEffect({
    this.damage = 0,
    this.undefendable = false,
    this.stealHp = 0,
    this.stealCp = 0,
    this.heal = 0,
    this.heroTokens = const [],
  });

  final int damage;
  final bool undefendable;
  final int stealHp;
  final int stealCp;
  final int heal;
  final List<String> heroTokens;
}
