part of '../../main.dart';

final _defenseEvaluatorRandom = Random();

bool isHealRollD6DefenseFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final isHeal = clean.contains('heal') || clean.contains('soin') || clean.contains('pv');
  final isD6 = clean.contains('rolld6') ||
      clean.contains('d6') ||
      clean.contains('additionaldie') ||
      clean.contains('extraroll');
  return isHeal && isD6;
}

/// Checks if a formula requests return damage equal to half an additional D6 (rounded up).
bool isReturnDamageRollD6Formula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final isReturn = clean.contains('return') ||
      clean.contains('riposte') ||
      clean.contains('renvoie') ||
      clean.contains('degat') ||
      clean.contains('dégât');
  final isD6 = clean.contains('rolld6') ||
      clean.contains('d6') ||
      clean.contains('additionaldie') ||
      clean.contains('extraroll');
  final isHalf = clean.contains('/2') ||
      clean.contains('ceil') ||
      clean.contains('half') ||
      clean.contains('moitie') ||
      clean.contains('moitié');
  final isDefenseDie = clean.contains('defensedie') || clean.contains('jetdefensif');
  final isIncoming = clean.contains('incomingdamage');
  return isReturn && isD6 && isHalf && !isDefenseDie && !isIncoming;
}

/// Checks if a formula requests damage prevention equal to half an additional D6 (rounded up).
bool isPreventRollD6HalfFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final isPrevent = clean.contains('prevent') ||
      clean.contains('prevention') ||
      clean.contains('previent') ||
      clean.contains('bloque');
  final isD6 = clean.contains('rolld6') ||
      clean.contains('d6') ||
      clean.contains('additionaldie') ||
      clean.contains('extraroll');
  final isHalf = clean.contains('/2') ||
      clean.contains('ceil') ||
      clean.contains('half') ||
      clean.contains('moitie') ||
      clean.contains('moitié');
  final isDefenseDie = clean.contains('defensedie') || clean.contains('jetdefensif');
  final isIncoming = clean.contains('incomingdamage');
  return isPrevent && isD6 && isHalf && !isDefenseDie && !isIncoming;
}

/// Checks if a formula requests damage prevention equal to the total value of the defense roll die.
bool isPreventDefenseDieValueFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final isPrevent = clean.contains('prevent') ||
      clean.contains('prevention') ||
      clean.contains('previent') ||
      clean.contains('bloque');
  final isDefenseDie = clean.contains('defensedie') ||
      clean.contains('jetdefensif') ||
      clean.contains('d6value') ||
      clean.contains('defenseroll') ||
      clean.contains('rollvalue');
  final isHalf = clean.contains('/2') || clean.contains('ceil') || clean.contains('half');
  final isIncoming = clean.contains('incomingdamage');
  return isPrevent && isDefenseDie && !isHalf && !isIncoming;
}

/// Checks if a formula requests damage prevention equal to an additional D6 roll full value.
bool isPreventRollD6FullFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final isPrevent = clean.contains('prevent') ||
      clean.contains('prevention') ||
      clean.contains('previent') ||
      clean.contains('bloque');
  final isD6 = clean.contains('rolld6') ||
      clean == 'prevent=d6' ||
      clean.contains('d6damage') ||
      clean.contains('rolld6damage') ||
      clean.contains('additionaldie') ||
      clean.contains('extraroll');
  final isHalf = clean.contains('/2') || clean.contains('ceil') || clean.contains('half');
  final isDefenseDie = clean.contains('defensedie') || clean.contains('jetdefensif') || clean.contains('defenseroll') || clean.contains('rollvalue');
  final isIncoming = clean.contains('incomingdamage');
  return isPrevent && isD6 && !isHalf && !isDefenseDie && !isIncoming;
}

/// Parses a damage cap formula (e.g. `damageCap = 6` or `maxIncomingDamage = 6`).
int? parseDamageCap(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:damagecap|maxincomingdamage|maxdamage|cap|plafonddegats?)=(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

/// Checks if a formula requests inflicting Burn or dealing damage if max Burn stack is reached.
bool isBurnOrDamageIfMaxFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  return clean.contains('burnordamage') ||
      (clean.contains('burn') && clean.contains('damage') && (clean.contains('max') || clean.contains('limit')));
}

/// Parses the alternative damage amount from a `burnOrDamageIfMax = X` formula.
int parseBurnOrDamageAmount(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:burnordamageifmax|burnordamage|tokenordamageifmax)=.*?(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 2;
  }
  final fallback = RegExp(r'(\d+)').firstMatch(clean);
  return fallback != null ? (int.tryParse(fallback.group(1)!) ?? 2) : 2;
}

/// Checks if a formula causes the hero attack to fail completely on a D6 roll threshold (e.g. Wyverne D6 >= 5).
bool isAttackFailsOnD6Formula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  return clean.contains('attackfails') ||
      clean.contains('attackfail') ||
      clean.contains('attaqueechoue') ||
      clean.contains('evadeall') ||
      (clean.contains('fail') && clean.contains('d6'));
}

/// Parses the D6 threshold for attack failure (defaults to 5).
int parseAttackFailsThreshold(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:attackfailsifd6>=|evadeallond6>=|d6>=|>=)(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 5;
  }
  return 5;
}

/// Checks if a formula causes the enemy to flee the battle on a D6 roll (e.g. Pillard Gobelin D6 == 6).
bool isFleeFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  return clean.contains('flee') ||
      clean.contains('fuite') ||
      clean.contains('prendlafuite') ||
      clean.contains('escape');
}

/// Parses the D6 threshold for fleeing (defaults to 6).
int parseFleeThreshold(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:fleeifd6==|fleeond6==|fleeifd6>=|fleeond6>=|flee==|flee>=|d6==|d6>=|==|>=|=)(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 6;
  }
  final fallback = RegExp(r'(\d+)').firstMatch(clean);
  return fallback != null ? (int.tryParse(fallback.group(1)!) ?? 6) : 6;
}

/// Checks if a formula requests stealing CP and dealing return damage on a D6 range (e.g. Pillard Gobelin 1-5).
bool isStealCpAndReturnDamageFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final hasSteal = clean.contains('stealcp') || clean.contains('volcp') || clean.contains('volecp') || clean.contains('steal');
  final hasDamage = clean.contains('returndamage') || clean.contains('damage') || clean.contains('degat') || clean.contains('dégât');
  return hasSteal && hasDamage;
}

/// Parses the maximum D6 threshold for stealCp & returnDamage (defaults to 5).
int parseD6RangeMax(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:<=|<|1-|1\.\.)(\d+)').firstMatch(clean);
  if (match != null) {
    final val = int.tryParse(match.group(1)!);
    if (val != null) {
      return clean.contains('<') && !clean.contains('<=') ? (val - 1) : val;
    }
  }
  return 5;
}

/// Parses CP steal amount from formula (defaults to 1).
int parseStealCpValue(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:stealcp[:=]?|vol(?:e)?[:=]?|steal[:=]?)(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 1;
  }
  return 1;
}

/// Parses return damage amount from formula (defaults to 1).
int parseReturnDamageValue(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final match = RegExp(r'(?:returndamage[:=]?|damage[:=]?|degat(?:s)?[:=]?|dégât(?:s)?[:=]?)(\d+)').firstMatch(clean);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 1;
  }
  return 1;
}

/// Checks if a formula requests stealing CP only (without returnDamage).
bool isStealCpFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final hasSteal = clean.contains('stealcp') || clean.contains('volcp') || clean.contains('volecp') || clean.contains('steal');
  final hasDamage = clean.contains('returndamage') || clean.contains('damage') || clean.contains('degat') || clean.contains('dégât');
  return hasSteal && !hasDamage;
}

/// Checks if a formula requests direct return damage only (without stealCp).
bool isDirectReturnDamageFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  final hasDamage = clean.contains('returndamage') || clean.contains('riposte');
  final isHalf = clean.contains('/2') || clean.contains('half') || clean.contains('ceil') || clean.contains('moitie');
  final isDefenseDie = clean.contains('defensedie') || clean.contains('jetdefensif');
  final isIncoming = clean.contains('incomingdamage');
  final hasSteal = clean.contains('steal') || clean.contains('vol');
  return hasDamage && !isHalf && !isDefenseDie && !isIncoming && !hasSteal;
}

/// Checks if a formula requests gaining a token on incoming damage (e.g. Berserker Enrage).
bool isGainTokenIfDamagedFormula(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '').toLowerCase();
  return clean.contains('gaintokenifdamage') ||
      clean.contains('gaintokenifdamaged') ||
      clean.contains('gaintokenondamage') ||
      clean.contains('gaintokenifdegat') ||
      clean.contains('gainchaosifdamage') ||
      (clean.contains('gaintoken') && clean.contains('damage'));
}

/// Parses the token name to gain from a formula (defaults to 'Chaos').
String parseGainTokenName(String rawFormula) {
  final clean = rawFormula.replaceAll(' ', '');
  final match = RegExp(
    r'(?:gaintokenifdamaged|gaintokenifdamage|gaintokenondamage|gaintoken)=([a-zA-ZÀ-ÿ_]+)',
    caseSensitive: false,
  ).firstMatch(clean);
  if (match != null) {
    final rawName = match.group(1)!;
    if (rawName.toLowerCase() == 'chaos') return 'Chaos';
    return rawName;
  }
  if (clean.toLowerCase().contains('chaos')) return 'Chaos';
  return 'Chaos';
}

/// Resolves an enemy's damage cap from its defense formulas, if any.
/// Supports both [EnemyProfile] and [EnemyNode].
int? resolveEnemyDamageCap(dynamic enemy) {
  if (enemy == null) return null;
  List<EnemyDefenseEffect>? effects;
  if (enemy is EnemyNode) {
    effects = enemy.defenseEffects;
  } else if (enemy is EnemyProfile) {
    effects = enemy.defenseEffects;
  }
  if (effects != null) {
    for (final eff in effects) {
      for (final formula in eff.formulas) {
        final cap = parseDamageCap(formula);
        if (cap != null) return cap;
      }
    }
  }
  return null;
}

/// Structured outcome of evaluating a minion defense effect's formulas.
class DefenseFormulaResult {
  const DefenseFormulaResult({
    this.prevented = 0,
    this.returnDamage = 0,
    this.returnDamageUndefendable = false,
    this.ignoreAllIncomingDamage = false,
    this.attackFailed = false,
    this.enemyFled = false,
    this.activatePassive = false,
    this.enemyHeal = 0,
    this.secondaryEnemyHeal = 0,
    this.damageCap,
    this.additionalDieRoll,
    this.stealCp = 0,
    this.grantedHeroTokens = const [],
    this.grantedEnemyTokens = const [],
    this.notes = const [],
    this.matched = false,
  });

  final int prevented;
  final int returnDamage;
  final bool returnDamageUndefendable;
  final bool ignoreAllIncomingDamage;
  final bool attackFailed;
  final bool enemyFled;
  final bool activatePassive;
  final int enemyHeal;
  final int secondaryEnemyHeal;
  final int? damageCap;
  final int? additionalDieRoll;
  final int stealCp;
  final List<String> grantedHeroTokens;
  final List<String> grantedEnemyTokens;
  final List<String> notes;
  final bool matched;

  DefenseFormulaResult combine(DefenseFormulaResult other) {
    return DefenseFormulaResult(
      prevented: prevented + other.prevented,
      returnDamage: returnDamage + other.returnDamage,
      returnDamageUndefendable: returnDamageUndefendable || other.returnDamageUndefendable,
      ignoreAllIncomingDamage: ignoreAllIncomingDamage || other.ignoreAllIncomingDamage,
      attackFailed: attackFailed || other.attackFailed,
      enemyFled: enemyFled || other.enemyFled,
      activatePassive: activatePassive || other.activatePassive,
      enemyHeal: enemyHeal + other.enemyHeal,
      secondaryEnemyHeal: secondaryEnemyHeal + other.secondaryEnemyHeal,
      damageCap: damageCap ?? other.damageCap,
      additionalDieRoll: additionalDieRoll ?? other.additionalDieRoll,
      stealCp: stealCp + other.stealCp,
      grantedHeroTokens: [...grantedHeroTokens, ...other.grantedHeroTokens],
      grantedEnemyTokens: [...grantedEnemyTokens, ...other.grantedEnemyTokens],
      notes: [...notes, ...other.notes],
      matched: matched || other.matched,
    );
  }
}

/// Evaluates a list of defense formulas for a matching defense effect.
///
/// Supported formulas:
/// - `ignoreAllIncomingDamage = true`: ignores all damage, cancelling undefendable.
/// - `prevent = ceil(incomingDamage / 2)`: prevents half the incoming damage (rounded up).
/// - `returnDamage = ceil(incomingDamage / 2)`: returns half the incoming damage.
/// - `returnDamage = ceil(defenseDieValue / 2)`: returns half the first defense die value (undefendable).
/// - `returnDamage = ceil(rollD6() / 2)`: rolls an additional D6 and returns half the roll as undefendable damage (rounded up).
/// - `prevent = ceil(rollD6() / 2)`: rolls an additional D6 and prevents half the roll (rounded up).
///   Can be combined with returnDamage (shares the same additional D6 roll).
/// - `prevent = defenseDieValue`: prevents damage equal to the value of the defense roll die.
/// - `prevent = rollD6()`: rolls an additional D6 and prevents damage equal to the roll value.
/// - `activatePassiveAbility = true`: activates passive minion ability (e.g. Viseer).
/// - `heal = rollD6()` / `heal = d6`: rolls an additional D6 and heals the minion by the rolled value.
///   If [hasDualEnemies] is true (both minions alive), the roll result is divided by 2 (rounded up)
///   and split so each minion heals that half amount.
DefenseFormulaResult evaluateDefenseFormulas({
  required List<String> formulas,
  required int incomingDamage,
  int count = 1,
  int firstDieValue = 0,
  bool hasDualEnemies = false,
  List<String> heroTokens = const [],
  int Function()? rollD6,
}) {
  if (formulas.isEmpty || count <= 0) {
    return const DefenseFormulaResult();
  }

  var prevented = 0;
  var returnDamage = 0;
  var returnDamageUndefendable = false;
  var ignoreAllDamage = false;
  var attackFailed = false;
  var enemyFled = false;
  var activatePassive = false;
  var enemyHeal = 0;
  var secondaryEnemyHeal = 0;
  int? damageCap;
  int? additionalDieRoll;
  var stealCp = 0;
  final grantedHeroTokens = <String>[];
  final grantedEnemyTokens = <String>[];
  final notes = <String>[];
  var matched = false;

  final subFormulas = <String>[];
  for (final raw in formulas) {
    for (final part in raw.split(RegExp(r'[;\n]'))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      if (isStealCpAndReturnDamageFormula(trimmed)) {
        subFormulas.add(trimmed);
        continue;
      }
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx != -1 && trimmed.substring(colonIdx + 1).contains('&')) {
        final prefix = trimmed.substring(0, colonIdx + 1);
        final rest = trimmed.substring(colonIdx + 1);
        for (final sub in rest.split(RegExp(r'[&]|\s+and\s+|\s+et\s+', caseSensitive: false))) {
          final subTrimmed = sub.trim();
          if (subTrimmed.isNotEmpty) {
            subFormulas.add('$prefix $subTrimmed');
          }
        }
      } else {
        for (final sub in trimmed.split(RegExp(r'[&]|\s+and\s+|\s+et\s+', caseSensitive: false))) {
          final subTrimmed = sub.trim();
          if (subTrimmed.isNotEmpty) {
            subFormulas.add(subTrimmed);
          }
        }
      }
    }
  }

  int getOrRollD6() {
    if (additionalDieRoll != null) return additionalDieRoll!;
    if (firstDieValue > 0) {
      additionalDieRoll = firstDieValue;
      return firstDieValue;
    }
    final roll =
        rollD6 != null ? rollD6() : (_defenseEvaluatorRandom.nextInt(6) + 1);
    additionalDieRoll = roll;
    return roll;
  }

  for (final raw in subFormulas) {
    final clean = raw.replaceAll(' ', '').toLowerCase();
    if (clean.isEmpty) continue;

    final parsedCap = parseDamageCap(clean);
    if (parsedCap != null) {
      damageCap = parsedCap;
      if (incomingDamage > parsedCap) {
        final excess = (incomingDamage - parsedCap) * count;
        prevented += excess;
        notes.add('Defense: damage cap of $parsedCap applies. Prevents $excess excess damage.');
      } else {
        notes.add('Defense: damage cap of $parsedCap applies (incoming attack $incomingDamage <= $parsedCap).');
      }
      matched = true;
      continue;
    }

    if (isBurnOrDamageIfMaxFormula(clean)) {
      final altDamage = parseBurnOrDamageAmount(clean);
      final currentBurnCount = heroTokens.where((t) {
        final lower = t.toLowerCase();
        return lower == 'burn' || lower == 'brûlure' || lower == 'brulure';
      }).length;
      if (currentBurnCount >= 1) {
        final totalDmg = altDamage * count;
        returnDamage += totalDmg;
        returnDamageUndefendable = true;
        notes.add('Defense: hero already has max Burn (1). Deals $totalDmg undefendable damage instead.');
      } else {
        for (var i = 0; i < count; i++) {
          grantedHeroTokens.add('Burn');
        }
        notes.add('Defense: inflicts Burn on the hero.');
      }
      matched = true;
      continue;
    }

    if (isAttackFailsOnD6Formula(clean)) {
      final threshold = parseAttackFailsThreshold(clean);
      final roll = getOrRollD6();
      if (roll >= threshold) {
        attackFailed = true;
        ignoreAllDamage = true;
        prevented += incomingDamage;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll >= $threshold). The hero\'s attack fails completely (0 damage, no tokens)!'
            : 'Defense: rolls additional D6 ($roll >= $threshold). The hero\'s attack fails completely (0 damage, no tokens)!');
      } else {
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll < $threshold). Defense roll failed.'
            : 'Defense: rolls additional D6 ($roll < $threshold). Defense roll failed.');
      }
      matched = true;
      continue;
    }

    if (isFleeFormula(clean)) {
      final threshold = parseFleeThreshold(clean);
      final roll = getOrRollD6();
      if (roll >= threshold) {
        enemyFled = true;
        attackFailed = true;
        ignoreAllDamage = true;
        prevented += incomingDamage;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll == $threshold). Enemy flees the battle!'
            : 'Defense: D6 ($roll == $threshold). Enemy flees the battle!');
      } else {
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll != $threshold). Did not flee.'
            : 'Defense: D6 ($roll != $threshold). Did not flee.');
      }
      matched = true;
      continue;
    }

    if (isStealCpAndReturnDamageFormula(clean)) {
      final maxRange = parseD6RangeMax(clean);
      final roll = getOrRollD6();
      if (roll <= maxRange) {
        final parsedCp = parseStealCpValue(clean) * count;
        final parsedDmg = parseReturnDamageValue(clean) * count;
        stealCp += parsedCp;
        returnDamage += parsedDmg;
        returnDamageUndefendable = true;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll <= $maxRange). Steals $parsedCp CP and returns $parsedDmg undefendable damage.'
            : 'Defense: D6 ($roll <= $maxRange). Steals $parsedCp CP and returns $parsedDmg undefendable damage.');
      } else {
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll > $maxRange). No CP stolen, no return damage.'
            : 'Defense: D6 ($roll > $maxRange). No CP stolen, no return damage.');
      }
      matched = true;
      continue;
    }

    if (isStealCpFormula(clean)) {
      final hasCondition = clean.contains('<=') || clean.contains('<') || clean.contains('1-');
      final roll = getOrRollD6();
      final maxRange = hasCondition ? parseD6RangeMax(clean) : 6;
      if (roll <= maxRange) {
        final parsedCp = parseStealCpValue(clean) * count;
        stealCp += parsedCp;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll <= $maxRange). Steals $parsedCp CP.'
            : 'Defense: steals $parsedCp CP.');
      }
      matched = true;
      continue;
    }

    if (isDirectReturnDamageFormula(clean)) {
      final hasCondition = clean.contains('<=') || clean.contains('<') || clean.contains('1-');
      final roll = getOrRollD6();
      final maxRange = hasCondition ? parseD6RangeMax(clean) : 6;
      if (roll <= maxRange) {
        final parsedDmg = parseReturnDamageValue(clean) * count;
        returnDamage += parsedDmg;
        returnDamageUndefendable = true;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll <= $maxRange). Deals $parsedDmg undefendable return damage.'
            : 'Defense: deals $parsedDmg undefendable return damage.');
      }
      matched = true;
      continue;
    }

    if (clean.contains('ignoreallincomingdamage') ||
        clean.contains('ignoreallincoming') ||
        clean.contains('ignorealldamage')) {
      ignoreAllDamage = true;
      prevented += incomingDamage;
      notes.add('Defense: ignores all incoming damage.');
      matched = true;
      continue;
    }

    if (clean.contains('prevent=ceil(incomingdamage/2)') ||
        clean.contains('prevent=incomingdamage/2') ||
        (clean.contains('prevent') && clean.contains('incomingdamage') && (clean.contains('half') || clean.contains('/2')))) {
      final half = (incomingDamage / 2.0).ceil() * count;
      prevented += half;
      notes.add('Defense: prevents half the damage ($half damage).');
      matched = true;
      continue;
    }

    if (clean.contains('returndamage=ceil(incomingdamage/2)') ||
        clean.contains('returndamage=incomingdamage/2') ||
        (clean.contains('return') && clean.contains('incomingdamage') && (clean.contains('half') || clean.contains('/2')))) {
      final half = (incomingDamage / 2.0).ceil() * count;
      returnDamage += half;
      notes.add('Defense: returns half the damage ($half damage).');
      matched = true;
      continue;
    }

    if (clean.contains('returndamage=ceil(defensedievalue/2)') ||
        clean.contains('returndamage=defensedievalue/2') ||
        (clean.contains('return') && clean.contains('defensedie') && (clean.contains('half') || clean.contains('/2')))) {
      final half = (firstDieValue / 2.0).ceil() * count;
      returnDamage += half;
      returnDamageUndefendable = true;
      notes.add('Defense: returns $half undefendable damage (D6: $firstDieValue).');
      matched = true;
      continue;
    }

    if (isReturnDamageRollD6Formula(clean)) {
      final roll = getOrRollD6();
      final half = (roll / 2.0).ceil() * count;
      returnDamage += half;
      returnDamageUndefendable = true;
      notes.add(firstDieValue > 0
          ? 'Defense: D6 ($roll) returns $half undefendable damage.'
          : 'Defense: rolls additional D6 ($roll) and returns $half undefendable damage.');
      matched = true;
      continue;
    }

    if (isPreventRollD6HalfFormula(clean)) {
      final roll = getOrRollD6();
      final half = (roll / 2.0).ceil() * count;
      prevented += half;
      notes.add(firstDieValue > 0
          ? 'Defense: D6 ($roll) prevents $half damage.'
          : 'Defense: rolls additional D6 ($roll) and prevents $half damage.');
      matched = true;
      continue;
    }

    if (isPreventDefenseDieValueFormula(clean)) {
      final val = firstDieValue * count;
      prevented += val;
      notes.add('Defense: prevents $val damage (defense die value: $firstDieValue).');
      matched = true;
      continue;
    }

    if (isPreventRollD6FullFormula(clean)) {
      final roll = getOrRollD6();
      final total = roll * count;
      prevented += total;
      notes.add(firstDieValue > 0
          ? 'Defense: D6 ($roll) prevents $total damage.'
          : 'Defense: rolls additional D6 ($roll) and prevents $total damage.');
      matched = true;
      continue;
    }

    if (clean.contains('activatepassiveability=true')) {
      activatePassive = true;
      notes.add('Defense: activates passive ability.');
      matched = true;
      continue;
    }

    if (isHealRollD6DefenseFormula(clean)) {
      final roll = getOrRollD6();
      if (hasDualEnemies) {
        final half = (roll / 2.0).ceil() * count;
        enemyHeal += half;
        secondaryEnemyHeal += half;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll). 2 minions alive: each heals $half HP.'
            : 'Defense: rolls additional D6 ($roll). 2 minions alive: each heals $half HP.');
      } else {
        final total = roll * count;
        enemyHeal += total;
        notes.add(firstDieValue > 0
            ? 'Defense: D6 ($roll) heals $total HP.'
            : 'Defense: rolls additional D6 ($roll) and heals $total HP.');
      }
      matched = true;
      continue;
    }

    if (isGainTokenIfDamagedFormula(clean)) {
      final tokenName = parseGainTokenName(raw);
      if (incomingDamage >= 1) {
        for (var i = 0; i < count; i++) {
          grantedEnemyTokens.add(tokenName);
        }
        notes.add('Defense: took damage, gains $count $tokenName.');
      } else {
        notes.add('Defense: no damage taken, gains no $tokenName.');
      }
      matched = true;
      continue;
    }
  }

  return DefenseFormulaResult(
    prevented: prevented,
    returnDamage: returnDamage,
    returnDamageUndefendable: returnDamageUndefendable,
    ignoreAllIncomingDamage: ignoreAllDamage,
    attackFailed: attackFailed,
    enemyFled: enemyFled,
    activatePassive: activatePassive,
    enemyHeal: enemyHeal,
    secondaryEnemyHeal: secondaryEnemyHeal,
    damageCap: damageCap,
    additionalDieRoll: additionalDieRoll,
    stealCp: stealCp,
    grantedHeroTokens: grantedHeroTokens,
    grantedEnemyTokens: grantedEnemyTokens,
    notes: notes,
    matched: matched,
  );
}

/// Represents a defense effect whose condition was met during roll resolution.
class MatchedDefenseEffect {
  const MatchedDefenseEffect({
    required this.effect,
    required this.count,
  });

  final EnemyDefenseEffect effect;
  final int count;

  int get requiredSymbolsCount => effect.white + effect.orange + effect.red;
}

/// Filters a list of matched defense effects, ensuring that when an effect is
/// marked [exclusive] (or represents a mutually-exclusive tier), only the
/// highest tier / most specific effect applies.
List<MatchedDefenseEffect> filterActiveDefenseEffects(List<MatchedDefenseEffect> matched) {
  if (matched.length <= 1) return matched;

  final hasExclusive = matched.any((m) => m.effect.exclusive);
  if (!hasExclusive) return matched;

  // Find the most demanding exclusive effect (highest required symbol count)
  final exclusiveEffects = matched.where((m) => m.effect.exclusive).toList()
    ..sort((a, b) => b.requiredSymbolsCount.compareTo(a.requiredSymbolsCount));

  final bestExclusive = exclusiveEffects.first;

  final result = <MatchedDefenseEffect>[];
  result.add(bestExclusive);

  // Keep non-exclusive effects that do not overlap with the exclusive effect's symbol conditions
  for (final m in matched) {
    if (m.effect.exclusive) continue;
    // If a non-exclusive effect uses the exact same symbols or a subset of the exclusive effect's symbols,
    // it was a lower tier that should not stack
    final isSubset = (m.effect.white <= bestExclusive.effect.white &&
                      m.effect.orange <= bestExclusive.effect.orange &&
                      m.effect.red <= bestExclusive.effect.red);
    if (!isSubset) {
      result.add(m);
    }
  }

  return result;
}

