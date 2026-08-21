class RewardOutcome {
  const RewardOutcome({
    required this.label,
    required this.healthDelta,
    required this.cpDelta,
    this.token,
  });

  final String label;
  final int healthDelta;
  final int cpDelta;
  final String? token;
}

class UpkeepOutcome {
  const UpkeepOutcome({
    required this.cpDelta,
    required this.healthDelta,
    required this.removedTokens,
    this.addedTokens = const [],
    required this.log,
    this.logParts = const [],
    this.notes = const [],
  });

  final int cpDelta;
  final int healthDelta;
  final List<String> removedTokens;
  final List<String> addedTokens;
  final String log;
  final List<String> logParts;
  // Human-readable notes for tokens requiring player action (e.g. Powder Keg transfer).
  final List<String> notes;
}

class _UpkeepContext {
  _UpkeepContext({
    required this.tokens,
    required this.rollD6,
    this.isHero = false,
    this.isNaxarus = false,
    int initialCp = 0,
  })  : initialCpValue = initialCp,
        currentCp = initialCp {
    if (isHero) {
      logParts.add('+ 1 CP');
    }
  }

  final List<String> tokens;
  final int Function() rollD6;
  final bool isHero;
  final bool isNaxarus;
  final int initialCpValue;

  int healthDelta = 0;
  int currentCp;
  bool concussionActive = false;
  final List<String> removedTokens = [];
  final List<String> addedTokens = [];
  final List<String> logParts = [];
  final List<String> notes = [];

  int count(String label) {
    final lower = label.toLowerCase();
    return tokens.where((t) {
      final tl = t.toLowerCase();
      return tl == lower ||
          (lower == 'burn' && (tl == 'brûlure' || tl == 'brulure')) ||
          (lower == 'knockdown' && (tl == 'à terre' || tl == 'a terre')) ||
          (lower == 'concussion' && tl == 'commotion') ||
          (lower == 'time bomb 1' && tl == 'bombe à retardement 1') ||
          (lower == 'time bomb 2' && (tl == 'bombe à retardement 2' || tl == 'time bomb' || tl == 'bombe à retardement'));
    }).length;
  }

  void remove(String label, {int times = 1}) {
    var n = times;
    final lower = label.toLowerCase();
    for (final t in List<String>.from(tokens)) {
      if (n <= 0) break;
      final tl = t.toLowerCase();
      if (tl == lower ||
          (lower == 'burn' && (tl == 'brûlure' || tl == 'brulure')) ||
          (lower == 'knockdown' && (tl == 'à terre' || tl == 'a terre')) ||
          (lower == 'concussion' && tl == 'commotion') ||
          (lower == 'time bomb 1' && tl == 'bombe à retardement 1') ||
          (lower == 'time bomb 2' && (tl == 'bombe à retardement 2' || tl == 'time bomb' || tl == 'bombe à retardement')) ||
          (lower == 'first strike' && (tl == 'première frappe' || tl == 'premiere frappe' || tl == '1st frappe'))) {
        removedTokens.add(t);
        n--;
      }
    }
  }

  int get cpDelta {
    if (!isHero) {
      return currentCp - initialCpValue;
    }
    final naturalGain = concussionActive ? 0 : 1;
    final finalCp = currentCp + naturalGain;
    return finalCp - initialCpValue;
  }
}

typedef _TokenHandler = void Function(_UpkeepContext ctx);

class GameEngine {
  const GameEngine._();

  static final Map<String, _TokenHandler> _upkeepHandlers = {
    // Poison — 1 dmg per stack, persistent
    'Poison': (ctx) {
      final n = ctx.count('Poison');
      if (n == 0) return;
      ctx.healthDelta -= n;
      ctx.logParts.add('-$n HP from Poison');
    },

    // Burn — 2 dmg, persistent
    'Burn': (ctx) {
      if (ctx.count('Burn') == 0) return;
      ctx.healthDelta -= 2;
      ctx.logParts.add('-2 HP from Burn');
    },
    'Brûlure': (ctx) => _upkeepHandlers['Burn']?.call(ctx),
    'Brulure': (ctx) => _upkeepHandlers['Burn']?.call(ctx),

    // Knockdown / À terre — removes up to 2 CP before natural +1 CP gain, then removes token (Naxarus immune)
    'Knockdown': (ctx) {
      if (ctx.count('Knockdown') == 0) return;
      if (ctx.isNaxarus) return;
      final lost = ctx.currentCp >= 2 ? 2 : ctx.currentCp;
      ctx.currentCp -= lost;
      ctx.remove('Knockdown');
      ctx.logParts.add('-$lost CP from Knockdown, token removed');
    },
    'À terre': (ctx) => _upkeepHandlers['Knockdown']?.call(ctx),
    'A terre': (ctx) => _upkeepHandlers['Knockdown']?.call(ctx),

    // Bleed (Hémorragie) — roll d6 per stack: 1-4 → -1 HP, 5-6 → remove
    'Bleed': (ctx) {
      final n = ctx.count('Bleed');
      if (n == 0) return;
      var dmg = 0;
      var removed = 0;
      for (var i = 0; i < n; i++) {
        final roll = ctx.rollD6();
        if (roll <= 4) {
          dmg++;
        } else {
          ctx.remove('Bleed');
          removed++;
        }
      }
      ctx.healthDelta -= dmg;
      final parts = <String>[];
      if (dmg > 0) parts.add('-$dmg HP');
      if (removed > 0) parts.add('$removed removed');
      ctx.logParts.add('Bleed: ${parts.join(', ')}');
    },

    // Wound — 1 dmg per stack, then roll d6: 4-6 → remove that stack
    'Wound': (ctx) {
      final n = ctx.count('Wound');
      if (n == 0) return;
      var removed = 0;
      for (var i = 0; i < n; i++) {
        ctx.healthDelta -= 1;
        if (ctx.rollD6() >= 4) {
          ctx.remove('Wound');
          removed++;
        }
      }
      final removePart = removed > 0 ? ', $removed removed' : '';
      ctx.logParts.add('-$n HP from Wound$removePart');
    },

    // Cursed Doubloon — 1 dmg per stack (skip for pirate hero at call site)
    'Cursed Doubloon': (ctx) {
      final n = ctx.count('Cursed Doubloon');
      if (n == 0) return;
      ctx.healthDelta -= n;
      ctx.logParts.add('-$n HP from Cursed Doubloon');
    },

    // Powder Keg — roll d6: 1-2 → explodes (-3 HP + remove), 3-5 → nothing, 6 → note transfer
    'Powder Keg': (ctx) {
      if (ctx.count('Powder Keg') == 0) return;
      final roll = ctx.rollD6();
      if (roll <= 2) {
        ctx.healthDelta -= 3;
        ctx.remove('Powder Keg');
        ctx.logParts.add('Powder Keg explodes! -3 HP undefendable (roll: $roll)');
      } else if (roll == 6) {
        ctx.logParts.add('Powder Keg: roll $roll — may transfer token');
        ctx.notes.add('Powder Keg rolled 6: the player may transfer the token to any other player.');
      } else {
        ctx.logParts.add('Powder Keg: roll $roll — nothing happens');
      }
    },

    // Nanite — roll 1 d6 per Nanite: on 6 → remove that Nanite
    'Nanite': (ctx) {
      final n = ctx.count('Nanite');
      if (n == 0) return;
      var removed = 0;
      for (var i = 0; i < n; i++) {
        if (ctx.rollD6() == 6) {
          ctx.remove('Nanite');
          removed++;
        }
      }
      final removePart = removed > 0 ? ', $removed removed' : '';
      ctx.logParts.add('Nanite: rolled $n die${n > 1 ? 's' : ''}$removePart');
    },

    // Holy Presence — note only; fight layer applies dmg to opponents
    'Holy Presence': (ctx) {
      final n = ctx.count('Holy Presence');
      if (n == 0) return;
      ctx.notes.add('Holy Presence: deals $n dmg to all opponents.');
      ctx.logParts.add('Holy Presence: $n outgoing dmg (apply to opponents)');
    },

    // Regenerate — 2+ stacks: heal 2 + remove 1; 1 stack: heal 1 + remove
    'Regenerate': (ctx) {
      final n = ctx.count('Regenerate');
      if (n == 0) return;
      if (n >= 2) {
        ctx.healthDelta += 2;
        ctx.remove('Regenerate');
        ctx.logParts.add('Regenerate: +2 HP, flipped (1 token remains)');
      } else {
        ctx.healthDelta += 1;
        ctx.remove('Regenerate');
        ctx.logParts.add('Regenerate: +1 HP, token removed');
      }
    },

    // Delayed Poison — end-of-turn: remove all stacks + -3 HP each
    'Delayed Poison': (ctx) {
      final n = ctx.count('Delayed Poison');
      if (n == 0) return;
      ctx.healthDelta -= n * 3;
      ctx.remove('Delayed Poison', times: n);
      ctx.logParts.add('Delayed Poison: -${n * 3} HP, $n token${n > 1 ? 's' : ''} removed');
    },

    // Concussion / Commotion - Prevents +1 CP gain during upkeep & removes itself (non-persistent)
    'Concussion': (ctx) {
      if (ctx.count('Concussion') == 0) return;
      ctx.concussionActive = true;
      ctx.logParts.remove('+ 1 CP');
      ctx.logParts.add('CP gain prevented by Concussion');
      ctx.remove('Concussion');
    },
    'Commotion': (ctx) => _upkeepHandlers['Concussion']?.call(ctx),

    // First Strike / Première Frappe - minion starts combat & removes itself (non-persistent)
    'First Strike': (ctx) {
      ctx.logParts.add('Première Frappe');
      ctx.remove('First Strike');
    },
    'Première Frappe': (ctx) => _upkeepHandlers['First Strike']?.call(ctx),
    '1st frappe': (ctx) => _upkeepHandlers['First Strike']?.call(ctx),
  };

  static UpkeepOutcome minionUpkeep({
    required List<String> tokens,
    required int Function() rollD6,
    int currentCp = 0,
    bool isNaxarus = false,
  }) {
    final ctx = _UpkeepContext(
      tokens: tokens,
      rollD6: rollD6,
      isHero: false,
      isNaxarus: isNaxarus,
      initialCp: currentCp,
    );
    final seen = <String>{};
    for (final token in tokens) {
      if (seen.add(token)) {
        _upkeepHandlers[token]?.call(ctx);
      }
    }
    return UpkeepOutcome(
      cpDelta: ctx.cpDelta,
      healthDelta: ctx.healthDelta,
      removedTokens: ctx.removedTokens,
      addedTokens: ctx.addedTokens,
      log: ctx.logParts.join(', '),
      logParts: List<String>.from(ctx.logParts),
      notes: ctx.notes,
    );
  }

  static UpkeepOutcome heroUpkeep({
    required List<String> tokens,
    required int Function() rollD6,
    int currentCp = 0,
    bool isPirate = false,
  }) {
    final ctx = _UpkeepContext(
      tokens: tokens,
      rollD6: rollD6,
      isHero: true,
      initialCp: currentCp,
    );
    final seen = <String>{};
    for (final token in tokens) {
      if (seen.add(token)) {
        if (token == 'Cursed Doubloon' && isPirate) continue;
        _upkeepHandlers[token]?.call(ctx);
      }
    }
    return UpkeepOutcome(
      cpDelta: ctx.cpDelta,
      healthDelta: ctx.healthDelta,
      removedTokens: ctx.removedTokens,
      addedTokens: ctx.addedTokens,
      log: ctx.logParts.join(', '),
      logParts: List<String>.from(ctx.logParts),
      notes: ctx.notes,
    );
  }

  static int combatPointStartGain() => 1;

  static RewardOutcome rewardForD20(int d20, {String chest = 'green'}) {
    final table = _rewardTables[chest] ?? _rewardTables['green']!;
    final code = table[(d20.clamp(1, 20)) - 1];
    return _rewardFromCode(code);
  }

  static const Map<String, List<String>> _rewardTables = {
    'green': [
      '1d', '1d', '2d', '2d', '1cp', '1cp', '2cp', '1vol',
      '1p', '1p', '2hp', '2hp', '3hp', '3hp', '1v', '1v', '1v', '1v', '1b', '1b',
    ],
    'blue': [
      '2d', '2d', '3d', '1cp', '2cp', '2cp', '1vol', '1vol',
      '1p', '2p', '3hp', '3hp', '4hp', '4hp', '1v', '1v', '1b', '1b', '1b', '1vi',
    ],
    'violet': [
      '3d', '3d', '4d', '2cp', '3cp', '1vol', '1vol', '1vol',
      '2p', '3p', '4hp', '4hp', '5hp', '5hp', '1b', '1b', '1b', '1vi', '1vi', '1o',
    ],
    'orange': [
      '1v', '1v', '1v', '1v', '1v', '1v',
      '1b', '1b', '1b', '1b', '1b', '1b',
      '1vi', '1vi', '1vi', '1vi', '1vi',
      '1o', '1o', '1o',
    ],
  };

  static RewardOutcome _rewardFromCode(String code) {
    return switch (code) {
      '1d' => const RewardOutcome(label: 'Dégat Bonus 1', healthDelta: 0, cpDelta: 0, token: 'Dégat Bonus 1'),
      '2d' => const RewardOutcome(label: 'Dégat Bonus 2', healthDelta: 0, cpDelta: 0, token: 'Dégat Bonus 2'),
      '3d' => const RewardOutcome(label: 'Dégat Bonus 3', healthDelta: 0, cpDelta: 0, token: 'Dégat Bonus 3'),
      '4d' => const RewardOutcome(label: 'Dégat Bonus 4', healthDelta: 0, cpDelta: 0, token: 'Dégat Bonus 4'),
      '1cp' => const RewardOutcome(label: '+1 CP', healthDelta: 0, cpDelta: 1),
      '2cp' => const RewardOutcome(label: '+2 CP', healthDelta: 0, cpDelta: 2),
      '3cp' => const RewardOutcome(label: '+3 CP', healthDelta: 0, cpDelta: 3),
      '1vol' => const RewardOutcome(label: 'Vol', healthDelta: 0, cpDelta: 0, token: 'Vol'),
      '1p' => const RewardOutcome(label: 'Pioche 1 carte', healthDelta: 0, cpDelta: 0),
      '2p' => const RewardOutcome(label: 'Pioche 2 cartes', healthDelta: 0, cpDelta: 0),
      '3p' => const RewardOutcome(label: 'Pioche 3 cartes', healthDelta: 0, cpDelta: 0),
      '2hp' => const RewardOutcome(label: '+2 HP', healthDelta: 2, cpDelta: 0),
      '3hp' => const RewardOutcome(label: '+3 HP', healthDelta: 3, cpDelta: 0),
      '4hp' => const RewardOutcome(label: '+4 HP', healthDelta: 4, cpDelta: 0),
      '5hp' => const RewardOutcome(label: '+5 HP', healthDelta: 5, cpDelta: 0),
      '1v' => const RewardOutcome(label: 'Carte verte', healthDelta: 0, cpDelta: 0),
      '1b' => const RewardOutcome(label: 'Carte bleue', healthDelta: 0, cpDelta: 0),
      '1vi' => const RewardOutcome(label: 'Carte violette', healthDelta: 0, cpDelta: 0),
      '1o' => const RewardOutcome(label: 'Carte orange', healthDelta: 0, cpDelta: 0),
      _ => RewardOutcome(label: code, healthDelta: 0, cpDelta: 0),
    };
  }
}
