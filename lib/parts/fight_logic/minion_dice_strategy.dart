part of '../../main.dart';

class MinionSymbolDecision {
  const MinionSymbolDecision({
    required this.values,
    required this.reservedDieIds,
    required this.reason,
    this.targetGoal,
    this.isGoalMet = false,
    this.matchingDiceCount = 0,
    this.requiredDiceCount = 0,
  });

  final List<int> values;
  final List<int> reservedDieIds;
  final String reason;
  final SymbolGoal? targetGoal;
  final bool isGoalMet;
  final int matchingDiceCount;
  final int requiredDiceCount;
}

/// Helper methods for MinionDiceEngine symbol hold calculations.
extension MinionDiceEngineSymbols on MinionDiceEngine {
  static MinionSymbolDecision chooseSymbolHold({
    required List<GameDie> dice,
    required List<SymbolGoal> goals,
    EnemyNode? enemy,
  }) {
    final active = dice.where((d) => d.value != null && d.symbol != null).toList();
    if (active.isEmpty || goals.isEmpty) {
      return const MinionSymbolDecision(
        values: [],
        reservedDieIds: [],
        reason: 'No active dice or goals available.',
      );
    }

    // Filter out fallback goals with 0 required symbols
    final realGoals = goals.where((g) => (g.white + g.yellow + g.red) > 0).toList();
    if (realGoals.isEmpty) {
      return const MinionSymbolDecision(
        values: [],
        reservedDieIds: [],
        reason: 'No symbol requirements in goals.',
      );
    }

    // Check if any real goal is fully met
    final metGoals = <({SymbolGoal goal, List<GameDie> matched})>[];
    for (final goal in realGoals) {
      final matched = _findMatchingDice(active, goal);
      final reqCount = goal.white + goal.yellow + goal.red;
      if (matched.length >= reqCount && _checkGoalMet(active, goal)) {
        metGoals.add((goal: goal, matched: matched));
      }
    }

    if (metGoals.isNotEmpty) {
      // Pick the best met goal (highest requirements or highest damage)
      metGoals.sort((a, b) {
        final aCount = a.goal.white + a.goal.yellow + a.goal.red;
        final bCount = b.goal.white + b.goal.yellow + b.goal.red;
        if (aCount != bCount) return bCount.compareTo(aCount);
        if (enemy != null) {
          final aDmg = _damageForSymbolGoal(enemy, a.goal)?.value ?? 0;
          final bDmg = _damageForSymbolGoal(enemy, b.goal)?.value ?? 0;
          return bDmg.compareTo(aDmg);
        }
        return 0;
      });

      final bestMet = metGoals.first;
      final targetGoal = bestMet.goal;

      // If the minion can improve towards a higher tier of the same primary symbol
      // (e.g. Banshee: 2 red validated, but 3, 4, 5 red exist), hold all dice matching that symbol!
      final higherGoalExists = realGoals.any((g) {
        final totalG = g.white + g.yellow + g.red;
        final totalTarget = targetGoal.white + targetGoal.yellow + targetGoal.red;
        if (totalG <= totalTarget) return false;
        if (targetGoal.red > 0 && g.red > targetGoal.red) return true;
        if (targetGoal.yellow > 0 && g.yellow > targetGoal.yellow) return true;
        if (targetGoal.white > 0 && g.white > targetGoal.white) return true;
        return false;
      });

      List<GameDie> keptDice;
      if (higherGoalExists) {
        // Keep all active dice that match any of the symbols in targetGoal
        keptDice = active.where((d) {
          if (targetGoal.red > 0 && d.symbol == DieSymbol.red) return true;
          if (targetGoal.yellow > 0 && d.symbol == DieSymbol.yellow) return true;
          if (targetGoal.white > 0 && d.symbol == DieSymbol.white) return true;
          return false;
        }).toList();
      } else {
        keptDice = bestMet.matched;
      }

      final keptValues = keptDice.map((d) => d.effectiveValue ?? d.value!).toList()..sort();
      final reqCount = targetGoal.white + targetGoal.yellow + targetGoal.red;

      return MinionSymbolDecision(
        values: keptValues,
        reservedDieIds: keptDice.map((d) => d.id).toList(),
        reason: 'Attack validated ($reqCount symbol(s)). Keeping ${keptValues.join('/')} to hit or improve.',
        targetGoal: targetGoal,
        isGoalMet: true,
        matchingDiceCount: keptDice.length,
        requiredDiceCount: reqCount,
      );
    }

    // No goal is met yet. Evaluate which goal to build toward (statistical hold).
    // Find goals that have at least 1 matching die rolled.
    final candidateGoals = <({SymbolGoal goal, List<GameDie> matched, int needed, int missing})>[];
    for (final goal in realGoals) {
      final matched = _findMatchingDice(active, goal);
      final needed = goal.white + goal.yellow + goal.red;
      final missing = (needed - matched.length).clamp(0, 99);
      if (matched.isNotEmpty) {
        candidateGoals.add((goal: goal, matched: matched, needed: needed, missing: missing));
      }
    }

    if (candidateGoals.isEmpty) {
      return const MinionSymbolDecision(
        values: [],
        reservedDieIds: [],
        reason: 'No matching symbols found. Rerolling all dice.',
      );
    }

    // Sort candidate goals to maximize probability of success:
    // 1. Lowest missing dice count (e.g. 1 missing is strictly easier than 2 missing)
    // 2. Highest matched count (e.g. 2/3 is better progress than 1/2)
    // 3. Lowest needed count (easier overall goal)
    // 4. Natural order in enemy goals list
    candidateGoals.sort((a, b) {
      if (a.missing != b.missing) return a.missing.compareTo(b.missing);
      if (a.matched.length != b.matched.length) {
        return b.matched.length.compareTo(a.matched.length);
      }
      if (a.needed != b.needed) return a.needed.compareTo(b.needed);
      return 0;
    });

    final bestCandidate = candidateGoals.first;
    final keptDice = bestCandidate.matched;
    final keptValues = keptDice.map((d) => d.effectiveValue ?? d.value!).toList()..sort();

    return MinionSymbolDecision(
      values: keptValues,
      reservedDieIds: keptDice.map((d) => d.id).toList(),
      reason: 'Aiming for ${bestCandidate.needed} symbol(s): keeping ${keptValues.join('/')} (${bestCandidate.matched.length}/${bestCandidate.needed}) to maximize chances on reroll.',
      targetGoal: bestCandidate.goal,
      isGoalMet: false,
      matchingDiceCount: bestCandidate.matched.length,
      requiredDiceCount: bestCandidate.needed,
    );
  }

  static bool _checkGoalMet(List<GameDie> dice, SymbolGoal goal) {
    int w = 0;
    int y = 0;
    int r = 0;
    for (final d in dice) {
      if (d.symbol == DieSymbol.white) w++;
      if (d.symbol == DieSymbol.yellow) y++;
      if (d.symbol == DieSymbol.red) r++;
    }
    final eff = goal.effect;
    if (eff != null && eff.orWhiteOrange && (goal.white > 0 || goal.yellow > 0)) {
      final matchW = goal.white > 0 && w >= goal.white;
      final matchY = goal.yellow > 0 && y >= goal.yellow;
      final matchR = goal.red == 0 || r >= goal.red;
      return (matchW || matchY) && matchR;
    }
    if (eff != null && eff.orOrangeRed && (goal.yellow > 0 || goal.red > 0)) {
      final matchY = goal.yellow > 0 && y >= goal.yellow;
      final matchR = goal.red > 0 && r >= goal.red;
      final matchW = goal.white == 0 || w >= goal.white;
      return (matchY || matchR) && matchW;
    }
    return w >= goal.white && y >= goal.yellow && r >= goal.red;
  }

  static List<GameDie> _findMatchingDice(List<GameDie> active, SymbolGoal goal) {
    final eff = goal.effect;
    final isOrWO = eff != null && eff.orWhiteOrange && (goal.white > 0 || goal.yellow > 0);
    final isOrOR = eff != null && eff.orOrangeRed && (goal.yellow > 0 || goal.red > 0);

    if (isOrWO) {
      final needed = goal.white > 0 ? goal.white : goal.yellow;
      final woDice = active.where((d) => d.symbol == DieSymbol.white || d.symbol == DieSymbol.yellow).toList();
      final rDice = active.where((d) => d.symbol == DieSymbol.red).take(goal.red).toList();
      return [...woDice.take(needed), ...rDice];
    }

    if (isOrOR) {
      final needed = goal.yellow > 0 ? goal.yellow : goal.red;
      final orDice = active.where((d) => d.symbol == DieSymbol.yellow || d.symbol == DieSymbol.red).toList();
      final wDice = active.where((d) => d.symbol == DieSymbol.white).take(goal.white).toList();
      return [...orDice.take(needed), ...wDice];
    }

    final matched = <GameDie>[];
    int remainingW = goal.white;
    int remainingY = goal.yellow;
    int remainingR = goal.red;

    for (final die in active) {
      if (die.symbol == DieSymbol.white && remainingW > 0) {
        matched.add(die);
        remainingW--;
      } else if (die.symbol == DieSymbol.yellow && remainingY > 0) {
        matched.add(die);
        remainingY--;
      } else if (die.symbol == DieSymbol.red && remainingR > 0) {
        matched.add(die);
        remainingR--;
      }
    }
    return matched;
  }
}
