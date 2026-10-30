part of '../../main.dart';

/// Structured outcome produced when a minion passive activates upon
/// offensive roll phase failure (`offensive_failure` / `offensiveRollFailed`).
class MinionOffensiveFailureOutcome {
  const MinionOffensiveFailureOutcome({
    this.damage = 0,
    this.undefendable = false,
    this.heal = 0,
    this.lifeSteal = 0,
    this.loseHp = 0,
    this.cpSteal = 0,
    this.heroTokens = const [],
    this.minionTokens = const [],
    this.notes = const [],
    this.triggered = false,
    this.removeHeroPositiveTokens = false,
  });

  final int damage;
  final bool undefendable;
  final int heal;
  final int lifeSteal;
  final int loseHp;
  final int cpSteal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final List<String> notes;
  final bool triggered;
  final bool removeHeroPositiveTokens;

  static const empty = MinionOffensiveFailureOutcome();
}

/// Structured outcome produced during minion upkeep / start-of-turn passives.
class MinionUpkeepPassiveOutcome {
  const MinionUpkeepPassiveOutcome({
    this.log = '',
    this.heroDamage = 0,
    this.minionHeal = 0,
    this.heroTokens = const [],
    this.minionTokens = const [],
    this.triggered = false,
  });

  final String log;
  final int heroDamage;
  final int minionHeal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final bool triggered;

  static const empty = MinionUpkeepPassiveOutcome();
}

/// Engine helper dedicated to evaluating and executing minion passives.
class MinionPassiveResolver {
  /// Evaluates whether an offensive failure passive should trigger for [enemy].
  ///
  /// Triggers when the minion finishes its offensive roll phase without meeting
  /// any valid attack goal ([hasValidAttack] is false and [rollPhaseFinished] is true).
  static MinionOffensiveFailureOutcome resolveOffensiveFailure({
    required EnemyNode enemy,
    required bool hasValidAttack,
    required bool rollPhaseFinished,
  }) {
    if (hasValidAttack || !rollPhaseFinished) {
      return MinionOffensiveFailureOutcome.empty;
    }

    final failurePassives = enemy.passives.where((p) {
      final t = (p.type ?? '').toLowerCase().trim();
      final tm = (p.timing ?? '').toLowerCase().trim();
      return t == 'offensive_failure' ||
          tm == 'offensiverollfailed' ||
          tm == 'offensive_roll_failed';
    }).toList();

    if (failurePassives.isEmpty) {
      return MinionOffensiveFailureOutcome.empty;
    }

    var damage = 0;
    var undefendable = false;
    var heal = 0;
    var lifeSteal = 0;
    var loseHp = 0;
    var cpSteal = 0;
    var removeHeroPositiveTokens = false;
    final heroTokens = <String>[];
    final minionTokens = <String>[];
    final notes = <String>[];

    final processedKeys = <String>{};

    for (final p in failurePassives) {
      // Deduplicate using impact or text as unique key
      final key = (p.impact?.isNotEmpty == true ? p.impact! : p.text)
          .toLowerCase()
          .trim();
      if (!processedKeys.add(key)) continue;

      if (p.impact?.toLowerCase().contains('positive status') == true ||
          p.text.toLowerCase().contains('positive status')) {
        removeHeroPositiveTokens = true;
      }

      final eff = p.effect;
      if (eff != null) {
        if (eff.damage > 0) {
          damage += eff.damage;
          if (eff.undefendable) {
            undefendable = true;
          }
        }
        if (eff.heal > 0) {
          heal += eff.heal;
        }
        if (eff.stealHp > 0) {
          lifeSteal += eff.stealHp;
        }
        if (eff.loseHp > 0) {
          loseHp += eff.loseHp;
        }
        if (eff.stealCp > 0) {
          cpSteal += eff.stealCp;
        }
      }

      final target = (p.target ?? '').toLowerCase().trim();
      final tokensToAdd = <String>[
        ...p.tokens,
        if (eff != null) ...eff.heroTokens,
        if (eff != null) ...eff.minionTokens,
      ];
      // Deduplicate token strings if repeated
      final uniqueTokens = <String>{...tokensToAdd}.toList();

      if (target == 'minion') {
        minionTokens.addAll(uniqueTokens);
      } else if (target == 'both') {
        heroTokens.addAll(uniqueTokens);
        minionTokens.addAll(uniqueTokens);
      } else {
        // default: opponent / hero
        heroTokens.addAll(uniqueTokens);
      }

      final noteDesc = StringBuffer('Passive triggered: ${p.text}');
      notes.add(noteDesc.toString());
    }

    // Consolidate offensive failure notes if multiple failure passives triggered
    final consolidatedNotes = <String>[];
    if (failurePassives.length > 1) {
      final impacts = <String>[];
      for (final p in failurePassives) {
        var imp = (p.impact ?? '').trim();
        if (imp.isEmpty) {
          final t = p.text.trim();
          const prefix = 'If the Offensive Roll Phase fails:';
          if (t.toLowerCase().startsWith(prefix.toLowerCase())) {
            imp = t.substring(prefix.length).trim();
          } else if (t.contains(':')) {
            imp = t.substring(t.indexOf(':') + 1).trim();
          } else {
            imp = t;
          }
        }
        imp = imp.replaceAll(RegExp(r'\.+$'), '').trim();
        if (imp.isNotEmpty && !impacts.contains(imp)) {
          impacts.add(imp);
        }
      }
      if (impacts.isNotEmpty) {
        consolidatedNotes.add(
          'Passive triggered: If the Offensive Roll Phase fails: ${impacts.join(', ')}.',
        );
      } else {
        consolidatedNotes.addAll(notes);
      }
    } else {
      consolidatedNotes.addAll(notes);
    }

    return MinionOffensiveFailureOutcome(
      damage: damage,
      undefendable: undefendable,
      heal: heal,
      lifeSteal: lifeSteal,
      loseHp: loseHp,
      cpSteal: cpSteal,
      heroTokens: List<String>.unmodifiable(heroTokens),
      minionTokens: List<String>.unmodifiable(minionTokens),
      notes: List<String>.unmodifiable(consolidatedNotes),
      triggered: true,
      removeHeroPositiveTokens: removeHeroPositiveTokens,
    );
  }

  /// Evaluates start-of-turn / minion upkeep passives ([minionUpkeep] or [start_of_turn]).
  static MinionUpkeepPassiveOutcome resolveMinionUpkeep({
    required EnemyNode enemy,
    required AdventureState adventure,
  }) {
    // 1. Check known specific profiles with historical legacy behavior
    if (enemy.profileKey == 'bleu-bleu-004') {
      enemy.alterations.add('Chaos');
      final chaosCount = enemy.alterations
          .where((t) => t.trim().toLowerCase() == 'chaos')
          .length;
      var log = 'Blood Mage gains 1 Chaos and now has $chaosCount Chaos';
      var heroDmg = 0;
      var heal = 0;
      if (chaosCount >= 3) {
        for (var i = 0; i < 3; i++) {
          enemy.alterations.remove('Chaos');
        }
        heroDmg = 3;
        heal = 3;
        log += ', spends 3 Chaos and steals 3 health';
      }
      return MinionUpkeepPassiveOutcome(
        log: log,
        heroDamage: heroDmg,
        minionHeal: heal,
        triggered: true,
      );
    }

    if (enemy.profileKey == 'bleu-bleu-005') {
      final hasSiphon = enemy.alterations.any(
        (t) => _normalizeTokenKey(t) == 'siphonvital' || _normalizeTokenKey(t) == 'siphon',
      );
      if (!hasSiphon) {
        enemy.alterations.add('Siphon vital');
        return const MinionUpkeepPassiveOutcome(
          log: 'Sorcière d\'Os gains 1 Siphon vital',
          minionTokens: ['Siphon vital'],
          triggered: true,
        );
      } else {
        return const MinionUpkeepPassiveOutcome(
          log: 'Sorcière d\'Os already has Siphon vital',
          triggered: true,
        );
      }
    }

    if (enemy.profileKey == 'orange-orange-011') {
      // Fallen Pharaoh: gains 1 Siphon vital. If already at max (1), heals 3 HP.
      final hasSiphon = enemy.alterations.any(
        (t) => _normalizeTokenKey(t) == 'siphonvital' || _normalizeTokenKey(t) == 'siphon',
      );
      if (!hasSiphon) {
        enemy.alterations.add('Siphon vital');
        return const MinionUpkeepPassiveOutcome(
          log: 'Fallen Pharaoh gains 1 Siphon vital',
          minionTokens: ['Siphon vital'],
          triggered: true,
        );
      } else {
        return const MinionUpkeepPassiveOutcome(
          log: 'Fallen Pharaoh already has Siphon vital and heals 3 HP',
          minionHeal: 3,
          triggered: true,
        );
      }
    }

    // 2. Generic data-driven passives for other minions with start_of_turn / minionUpkeep
    final upkeepPassives = enemy.passives.where((p) {
      final t = (p.type ?? '').toLowerCase().trim();
      final tm = (p.timing ?? '').toLowerCase().trim();
      return t == 'start_of_turn' || tm == 'minionupkeep';
    }).toList();

    if (upkeepPassives.isEmpty) {
      return MinionUpkeepPassiveOutcome.empty;
    }

    final logs = <String>[];
    final heroTokens = <String>[];
    final minionTokens = <String>[];
    var totalHeal = 0;

    for (final p in upkeepPassives) {
      final eff = p.effect;
      final target = (p.target ?? '').toLowerCase().trim();
      final tokensToAdd = <String>[
        ...p.tokens,
        if (eff != null) ...eff.heroTokens,
        if (eff != null) ...eff.minionTokens,
      ];

      for (final tok in tokensToAdd) {
        if (target == 'minion') {
          minionTokens.add(tok);
          enemy.alterations.add(tok);
        } else {
          heroTokens.add(tok);
          adventure.alterations.add(tok);
        }
      }

      if (eff != null && eff.heal > 0) {
        totalHeal += eff.heal;
      }

      logs.add('Passive triggered (${enemy.label}): ${p.text}');
    }

    return MinionUpkeepPassiveOutcome(
      log: logs.join('; '),
      minionHeal: totalHeal,
      heroTokens: heroTokens,
      minionTokens: minionTokens,
      triggered: true,
    );
  }

  /// Groups and consolidates passives that share the same timing / condition
  /// so that sentences like "If the Offensive Roll Phase fails:" are not repeated.
  static List<MinionPassive> consolidatePassives(List<MinionPassive> passives) {
    if (passives.length <= 1) return passives;

    final groups = <String, List<MinionPassive>>{};
    for (final p in passives) {
      final type = (p.type ?? 'custom').trim().toLowerCase();
      final timing = (p.timing ?? 'custom').trim().toLowerCase();
      final key = '${type}__$timing';
      groups.putIfAbsent(key, () => []).add(p);
    }

    final consolidated = <MinionPassive>[];
    for (final entry in groups.entries) {
      final list = entry.value;
      if (list.length == 1) {
        consolidated.add(list.first);
      } else {
        final first = list.first;
        final type = (first.type ?? '').toLowerCase().trim();
        final prefix = type == 'offensive_failure'
            ? 'If the Offensive Roll Phase fails: '
            : (type == 'start_of_turn' ? 'At the start of its turn: ' : null);

        if (prefix != null) {
          final impacts = <String>[];
          var totalDamage = 0;
          var isUndef = false;
          var totalHeal = 0;
          var totalLifeSteal = 0;
          var totalLoseHp = 0;
          var totalCpSteal = 0;
          final allHeroTokens = <String>[];
          final allMinionTokens = <String>[];

          for (final p in list) {
            var imp = (p.impact ?? '').trim();
            if (imp.isEmpty) {
              final t = p.text.trim();
              if (t.toLowerCase().startsWith(prefix.toLowerCase().trim())) {
                imp = t.substring(prefix.length).trim();
              } else if (t.contains(':')) {
                imp = t.substring(t.indexOf(':') + 1).trim();
              } else {
                imp = t;
              }
            }
            imp = imp.replaceAll(RegExp(r'\.+$'), '').trim();
            if (imp.isNotEmpty && !impacts.contains(imp)) {
              impacts.add(imp);
            }

            final eff = p.effect;
            if (eff != null) {
              totalDamage += eff.damage;
              if (eff.undefendable) isUndef = true;
              totalHeal += eff.heal;
              totalLifeSteal += eff.stealHp;
              totalLoseHp += eff.loseHp;
              totalCpSteal += eff.stealCp;
              allHeroTokens.addAll(eff.heroTokens);
              allMinionTokens.addAll(eff.minionTokens);
            }
          }

          final combinedText = '$prefix${impacts.join(', ')}.';
          consolidated.add(
            MinionPassive(
              text: combinedText,
              type: first.type,
              timing: first.timing,
              target: 'both',
              impact: impacts.join(', '),
              effect: MinionPassiveEffect(
                damage: totalDamage,
                undefendable: isUndef,
                heal: totalHeal,
                stealHp: totalLifeSteal,
                loseHp: totalLoseHp,
                stealCp: totalCpSteal,
                heroTokens: List.unmodifiable(allHeroTokens),
                minionTokens: List.unmodifiable(allMinionTokens),
              ),
            ),
          );
        } else {
          consolidated.addAll(list);
        }
      }
    }
    return consolidated;
  }
}
