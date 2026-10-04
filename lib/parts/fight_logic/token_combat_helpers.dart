part of '../../main.dart';

// --- Token helper predicates and alteration checkers ---

String _tokenClean(String t) =>
    t.replaceAll(RegExp(r'_active', caseSensitive: false), '');

bool _isCoalToken(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'coal' || k == 'charbon';
}

bool _isRealityWarpToken(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'realitywarp' || k == 'deformationdelarealite';
}

bool _isShameToken(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'shame' || k == 'honte';
}

bool _isBarbedVineAlteration(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'barbedvine' ||
      k == 'barbedvines' ||
      k == 'ronces' ||
      k == 'ronce';
}

bool _isConstrictAlteration(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'constrict' || k == 'compression';
}

bool _isDecrepifyAlteration(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'decrepify' || k == 'decrepitude' || k == 'decrep-ify';
}

bool _isDiceCubeAlteration(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'dicecube' || k == 'cube';
}

bool _isEntangleAlteration(String t) {
  final k = _normalizeTokenKey(_tokenClean(t));
  return k == 'entangle' || k == 'enchevetrement';
}

bool _isBarbedVineToken(String t) => _isBarbedVineAlteration(t);
bool _isConstrictToken(String t) => _isConstrictAlteration(t);
bool _isDecrepifyToken(String t) => _isDecrepifyAlteration(t);
bool _isDiceCubeToken(String t) => _isDiceCubeAlteration(t);
bool _isEntangleToken(String t) => _isEntangleAlteration(t);

bool _isShadowsToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'shadows' || k == 'shadow' || k == 'ombre';
}

bool _isEvasiveToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'evasive' || k == 'evitement';
}

bool _isFlightToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'flight' || k == 'vol';
}

bool _isParasiteToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'parasite';
}

bool _isBleedToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'bleed' || k == 'hemorragie' || k == 'saignement';
}

bool _isTimeBomb1(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'timebomb1' ||
      k == 'bombearetardement1' ||
      k == 'bombeàretardement1';
}

bool _isTimeBomb2(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'timebomb2' ||
      k == 'bombearetardement2' ||
      k == 'bombeàretardement2' ||
      ((k == 'timebomb' ||
              k == 'bombearetardement' ||
              k == 'bombeàretardement') &&
          !k.endsWith('1'));
}

bool _isTimeBombToken(String t) => _isTimeBomb1(t) || _isTimeBomb2(t);

bool _isCritToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'crit' || k == 'critique';
}

bool _isSneakAttackToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'sneakattack' || k == 'attaquefurtive';
}

bool _isGuardBreakToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'guardbreak' || k == 'brisegarde';
}

bool _isPreyToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'prey' || k == 'proie';
}

bool _isAccuracyToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'accuracy' || k == 'précision' || k == 'precision';
}

bool _isWellspringToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'wellspring' || k == 'source';
}

bool _isBlindingLightToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'blindinglight' || k == 'lumiereaveuglante';
}

bool _isTargetedToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'targeted' || k == 'prispourcible';
}

bool _isWebbedToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'webbed' || k == 'entoile' || k == 'entoilé';
}

bool _isFocusFireToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'focusfire' || k == 'tirciblé' || k == 'tircible';
}

bool _isAgilityToken(String t) {
  final k = _normalizeTokenKey(t);
  return k == 'agility' || k == 'agilite' || k == 'agilité';
}

bool _isStunToken(String label) {
  final k = _normalizeTokenKey(label);
  return k == 'stun' || k == 'etourdissement';
}

bool _isDelayedPoisonToken(String label) {
  final k = _normalizeTokenKey(label);
  return k == 'delayedpoison' ||
      k == 'poisonlatent' ||
      k == 'poisonretarde' ||
      k == 'poisondiffere';
}

bool _isRiposteToken(String label) {
  final k = _normalizeTokenKey(label);
  return k == 'riposte' || k == 'backstrike' || k == 'back strike';
}

// --- Token upkeep summary and counts ---

Map<String, int> _tokenCounts(List<String> tokens) {
  final counts = <String, int>{};
  for (final token in tokens) {
    counts[token] = (counts[token] ?? 0) + 1;
  }
  return counts;
}

String _tokenUpkeepSummary({
  required String owner,
  required List<String> tokens,
  required bool isHero,
  int currentCp = 0,
}) {
  if (tokens.isEmpty) {
    return '';
  }
  final counts = _tokenCounts(tokens);
  final lines = <String>[];
  var poisonDamage = 0;
  for (final entry in counts.entries) {
    final token = entry.key;
    final count = entry.value;
    final lower = token.toLowerCase();
    if (lower.contains('poison')) {
      poisonDamage += count;
      lines.add('$count Poison token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        '$owner will receive ${List.filled(count, '1 poison damage').join(' and ')}. Total: $count HP will be removed at the end of upkeep.',
      );
    } else if (lower.contains('bleed') ||
        lower.contains('hémorragie') ||
        lower.contains('hemorragie') ||
        lower.contains('saignement')) {
      lines.add('$count Bleed token${count > 1 ? 's' : ''} found on $owner.');
      lines.add(
        isHero
            ? '$owner must roll for Bleed during upkeep, then update HP and tokens.'
            : 'I have Bleed. I am ready to roll to see if the token stays; confirm with OK when this token is resolved.',
      );
    } else if (lower.contains('brûlure') || lower.contains('brulure')) {
      lines.add('$count Burn token${count > 1 ? 's' : ''} found on $owner.');
      lines.add('Resolve Burn damage before moving to battle.');
    } else if (lower.contains('coal') || lower.contains('charbon')) {
      if (count < 4) {
        lines.add(
          '$count Coal token${count > 1 ? 's' : ''} found on $owner (accumulates up to 4 to reduce next CP gain).',
        );
      }
    }
  }
  if (lines.isEmpty) {
    return '';
  }
  if (poisonDamage > 0) {
    lines.add('The upkeep damage may defeat $owner if HP is too low.');
  }
  return lines.join('\n');
}
