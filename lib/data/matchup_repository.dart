import 'dart:math';
import '../main.dart';

class MatchupData {
  MatchupData._();

  static const List<HeroType> top10Heroes = [
    HeroType.blackWidow,
    HeroType.forgemaster,
    HeroType.spiderman,
    HeroType.raveness,
    HeroType.druid,
    HeroType.thor,
    HeroType.alchemist,
    HeroType.shadowThief,
    HeroType.iceman,
    HeroType.cursedPirate,
  ];

  static const List<HeroType> top5Heroes = [
    HeroType.blackWidow,
    HeroType.forgemaster,
    HeroType.spiderman,
    HeroType.raveness,
    HeroType.druid,
  ];

  static const Map<HeroType, double> globalWinrates = {
    HeroType.blackWidow: 59.37,
    HeroType.forgemaster: 57.05,
    HeroType.spiderman: 56.21,
    HeroType.raveness: 55.69,
    HeroType.druid: 54.80,
    HeroType.thor: 54.49,
    HeroType.alchemist: 53.87,
    HeroType.shadowThief: 53.53,
    HeroType.iceman: 53.38,
    HeroType.cursedPirate: 52.77,
  };

  /// Table indexée : [RowHero][ColHero] = winrate de RowHero face à ColHero
  static const Map<HeroType, Map<HeroType, double>> _matrix = {
    HeroType.blackWidow: {
      HeroType.forgemaster: 69.23,
      HeroType.spiderman: 57.09,
      HeroType.raveness: 54.07,
      HeroType.gambit: 54.01,
      HeroType.druid: 60.42,
      HeroType.thor: 66.29,
      HeroType.alchemist: 57.75,
      HeroType.shadowThief: 50.32,
      HeroType.iceman: 64.71,
      HeroType.cursedPirate: 47.06,
      HeroType.headlessHorseman: 55.46,
      HeroType.jeanGrey: 59.51,
      HeroType.rogue: 62.58,
      HeroType.krampus: 63.30,
      HeroType.pyromancer: 56.89,
      HeroType.ninja: 48.79,
      HeroType.doctorStrange: 61.86,
      HeroType.paladin: 69.70,
      HeroType.blackPanther: 60.80,
      HeroType.deadpool: 59.70,
      HeroType.artificer: 74.13,
      HeroType.necromancer: 79.01,
      HeroType.captainMarvel: 65.06,
      HeroType.wolverine: 67.33,
      HeroType.psylocke: 75.26,
      HeroType.mysticBrawler: 80.00,
      HeroType.treant: 83.33,
      HeroType.monk: 66.84,
      HeroType.tacticien: 59.82,
      HeroType.paleLady: 69.44,
      HeroType.scarletWitch: 58.73,
      HeroType.vampireLord: 68.64,
      HeroType.santa: 76.00,
      HeroType.huntress: 79.49,
      HeroType.elfeLunaire: 69.77,
      HeroType.loki: 74.32,
      HeroType.cyclops: 76.09,
      HeroType.samurai: 75.61,
      HeroType.duelist: 81.82,
      HeroType.sunElf: 76.47,
      HeroType.gunslinger: 66.04,
      HeroType.storm: 71.43,
      HeroType.barbare: 75.26,
      HeroType.seraph: 67.16,
    },
    HeroType.raveness: {
      HeroType.blackWidow: 48.33,
      HeroType.forgemaster: 56.67,
      HeroType.spiderman: 55.74,
      HeroType.gambit: 52.27,
      HeroType.druid: 54.67,
      HeroType.thor: 57.33,
      HeroType.alchemist: 48.26,
      HeroType.shadowThief: 65.22,
      HeroType.iceman: 58.59,
      HeroType.cursedPirate: 54.62,
      HeroType.headlessHorseman: 51.35,
      HeroType.jeanGrey: 56.48,
      HeroType.rogue: 67.62,
      HeroType.krampus: 50.00,
      HeroType.pyromancer: 50.71,
      HeroType.ninja: 71.43,
      HeroType.doctorStrange: 62.20,
      HeroType.paladin: 70.00,
      HeroType.blackPanther: 27.70,
      HeroType.deadpool: 45.24,
      HeroType.artificer: 60.95,
      HeroType.necromancer: 54.72,
      HeroType.captainMarvel: 65.71,
      HeroType.wolverine: 60.49,
      HeroType.psylocke: 65.31,
      HeroType.mysticBrawler: 66.67,
      HeroType.treant: 74.47,
      HeroType.monk: 74.53,
      HeroType.tacticien: 60.87,
      HeroType.paleLady: 53.52,
      HeroType.scarletWitch: 62.26,
      HeroType.vampireLord: 58.06,
      HeroType.santa: 68.00,
      HeroType.huntress: 77.78,
      HeroType.elfeLunaire: 80.39,
      HeroType.loki: 85.29,
      HeroType.cyclops: 62.22,
      HeroType.samurai: 82.14,
      HeroType.duelist: 71.43,
      HeroType.sunElf: 62.96,
      HeroType.gunslinger: 86.84,
      HeroType.storm: 61.29,
      HeroType.barbare: 75.86,
      HeroType.seraph: 74.19,
    },
    HeroType.cursedPirate: {
      HeroType.blackWidow: 54.68,
      HeroType.forgemaster: 55.93,
      HeroType.spiderman: 67.61,
      HeroType.raveness: 48.74,
      HeroType.gambit: 46.05,
      HeroType.druid: 34.00,
      HeroType.thor: 44.83,
      HeroType.alchemist: 51.49,
      HeroType.shadowThief: 60.11,
      HeroType.iceman: 74.47,
      HeroType.headlessHorseman: 49.37,
      HeroType.jeanGrey: 43.24,
      HeroType.rogue: 40.37,
      HeroType.krampus: 47.83,
      HeroType.pyromancer: 58.29,
      HeroType.ninja: 45.83,
      HeroType.doctorStrange: 55.42,
      HeroType.paladin: 46.48,
      HeroType.blackPanther: 50.97,
      HeroType.deadpool: 59.30,
      HeroType.artificer: 64.66,
      HeroType.necromancer: 61.73,
      HeroType.captainMarvel: 66.27,
      HeroType.wolverine: 47.69,
      HeroType.psylocke: 56.57,
      HeroType.mysticBrawler: 50.00,
      HeroType.treant: 56.86,
      HeroType.monk: 53.11,
      HeroType.tacticien: 64.97,
      HeroType.paleLady: 59.46,
      HeroType.scarletWitch: 57.14,
      HeroType.vampireLord: 46.21,
      HeroType.santa: 62.50,
      HeroType.huntress: 52.07,
      HeroType.elfeLunaire: 81.48,
      HeroType.loki: 55.91,
      HeroType.cyclops: 65.82,
      HeroType.samurai: 53.49,
      HeroType.duelist: 47.37,
      HeroType.sunElf: 57.89,
      HeroType.gunslinger: 80.72,
      HeroType.storm: 70.00,
      HeroType.barbare: 62.61,
      HeroType.seraph: 66.67,
    },
    HeroType.druid: {
      HeroType.blackWidow: 41.67,
      HeroType.forgemaster: 35.55,
      HeroType.spiderman: 60.71,
      HeroType.raveness: 48.00,
      HeroType.gambit: 48.84,
      HeroType.thor: 42.86,
      HeroType.alchemist: 43.06,
      HeroType.shadowThief: 60.00,
      HeroType.iceman: 65.38,
      HeroType.cursedPirate: 66.00,
      HeroType.headlessHorseman: 51.43,
      HeroType.jeanGrey: 62.79,
      HeroType.rogue: 66.67,
      HeroType.krampus: 62.50,
      HeroType.pyromancer: 53.33,
      HeroType.ninja: 47.83,
      HeroType.doctorStrange: 67.57,
      HeroType.paladin: 66.67,
      HeroType.blackPanther: 65.52,
      HeroType.deadpool: 77.27,
      HeroType.artificer: 58.33,
      HeroType.necromancer: 60.87,
      HeroType.captainMarvel: 70.00,
      HeroType.wolverine: 55.81,
      HeroType.psylocke: 58.82,
      HeroType.mysticBrawler: 60.40,
      HeroType.treant: 81.82,
      HeroType.monk: 74.07,
      HeroType.tacticien: 54.55,
      HeroType.paleLady: 66.67,
      HeroType.scarletWitch: 61.54,
      HeroType.vampireLord: 90.00,
      HeroType.santa: 66.67,
      HeroType.huntress: 46.15,
      HeroType.elfeLunaire: 64.71,
      HeroType.loki: 76.00,
      HeroType.cyclops: 59.09,
      HeroType.samurai: 77.78,
      HeroType.duelist: 71.78,
      HeroType.sunElf: 66.67,
      HeroType.gunslinger: 100.00,
      HeroType.storm: 75.00,
      HeroType.barbare: 93.33,
      HeroType.seraph: 100.00,
    },
    HeroType.forgemaster: {
      HeroType.blackWidow: 35.90,
      HeroType.spiderman: 80.00,
      HeroType.raveness: 50.00,
      HeroType.gambit: 46.00,
      HeroType.druid: 71.09,
      HeroType.thor: 55.00,
      HeroType.alchemist: 50.88,
      HeroType.shadowThief: 31.82,
      HeroType.iceman: 81.25,
      HeroType.cursedPirate: 47.46,
      HeroType.headlessHorseman: 44.78,
      HeroType.jeanGrey: 66.67,
      HeroType.rogue: 65.38,
      HeroType.krampus: 72.73,
      HeroType.pyromancer: 38.36,
      HeroType.ninja: 42.11,
      HeroType.doctorStrange: 54.17,
      HeroType.paladin: 50.00,
      HeroType.blackPanther: 69.57,
      HeroType.deadpool: 77.27,
      HeroType.artificer: 72.00,
      HeroType.necromancer: 78.95,
      HeroType.captainMarvel: 80.00,
      HeroType.wolverine: 63.16,
      HeroType.psylocke: 88.24,
      HeroType.mysticBrawler: 64.47,
      HeroType.treant: 66.67,
      HeroType.monk: 71.43,
      HeroType.tacticien: 72.22,
      HeroType.paleLady: 57.63,
      HeroType.scarletWitch: 52.63,
      HeroType.vampireLord: 80.00,
      HeroType.santa: 77.78,
      HeroType.huntress: 57.14,
      HeroType.elfeLunaire: 90.91,
      HeroType.loki: 68.00,
      HeroType.cyclops: 60.00,
      HeroType.samurai: 87.50,
      HeroType.duelist: 63.10,
      HeroType.sunElf: 76.72,
      HeroType.gunslinger: 100.00,
      HeroType.storm: 84.62,
      HeroType.barbare: 52.94,
      HeroType.seraph: 50.00,
    },
    HeroType.shadowThief: {
      HeroType.blackWidow: 50.96,
      HeroType.forgemaster: 70.45,
      HeroType.spiderman: 42.25,
      HeroType.raveness: 35.40,
      HeroType.gambit: 49.22,
      HeroType.druid: 46.67,
      HeroType.thor: 41.44,
      HeroType.alchemist: 45.77,
      HeroType.iceman: 63.10,
      HeroType.cursedPirate: 41.85,
      HeroType.headlessHorseman: 44.35,
      HeroType.jeanGrey: 45.52,
      HeroType.rogue: 48.67,
      HeroType.krampus: 51.96,
      HeroType.pyromancer: 59.60,
      HeroType.ninja: 58.33,
      HeroType.doctorStrange: 47.86,
      HeroType.paladin: 72.28,
      HeroType.blackPanther: 57.89,
      HeroType.deadpool: 65.22,
      HeroType.artificer: 66.03,
      HeroType.necromancer: 50.88,
      HeroType.captainMarvel: 61.90,
      HeroType.wolverine: 60.98,
      HeroType.psylocke: 60.76,
      HeroType.mysticBrawler: 55.56,
      HeroType.treant: 52.14,
      HeroType.monk: 61.81,
      HeroType.tacticien: 58.21,
      HeroType.paleLady: 60.87,
      HeroType.scarletWitch: 56.14,
      HeroType.vampireLord: 58.22,
      HeroType.santa: 50.94,
      HeroType.huntress: 55.56,
      HeroType.elfeLunaire: 72.00,
      HeroType.loki: 59.80,
      HeroType.cyclops: 70.37,
      HeroType.samurai: 69.70,
      HeroType.duelist: 64.29,
      HeroType.sunElf: 68.00,
      HeroType.gunslinger: 69.09,
      HeroType.storm: 63.64,
      HeroType.barbare: 72.90,
      HeroType.seraph: 74.29,
    },
    HeroType.spiderman: {
      HeroType.blackWidow: 45.34,
      HeroType.forgemaster: 20.00,
      HeroType.raveness: 46.72,
      HeroType.gambit: 54.13,
      HeroType.druid: 42.86,
      HeroType.thor: 51.21,
      HeroType.alchemist: 50.43,
      HeroType.shadowThief: 57.75,
      HeroType.iceman: 49.07,
      HeroType.cursedPirate: 35.80,
      HeroType.headlessHorseman: 62.20,
      HeroType.jeanGrey: 64.42,
      HeroType.rogue: 54.78,
      HeroType.krampus: 56.41,
      HeroType.pyromancer: 58.96,
      HeroType.ninja: 66.17,
      HeroType.doctorStrange: 59.31,
      HeroType.paladin: 62.96,
      HeroType.blackPanther: 65.91,
      HeroType.deadpool: 71.64,
      HeroType.artificer: 72.00,
      HeroType.necromancer: 71.62,
      HeroType.captainMarvel: 61.11,
      HeroType.wolverine: 69.03,
      HeroType.psylocke: 59.76,
      HeroType.mysticBrawler: 61.11,
      HeroType.treant: 62.79,
      HeroType.monk: 55.36,
      HeroType.tacticien: 63.16,
      HeroType.paleLady: 71.23,
      HeroType.scarletWitch: 65.00,
      HeroType.vampireLord: 71.83,
      HeroType.santa: 73.81,
      HeroType.huntress: 60.71,
      HeroType.elfeLunaire: 58.57,
      HeroType.loki: 57.86,
      HeroType.cyclops: 70.49,
      HeroType.samurai: 73.47,
      HeroType.duelist: 71.43,
      HeroType.sunElf: 61.54,
      HeroType.gunslinger: 68.75,
      HeroType.storm: 70.91,
      HeroType.barbare: 83.12,
      HeroType.seraph: 67.39,
    },
    HeroType.alchemist: {
      HeroType.blackWidow: 44.39,
      HeroType.forgemaster: 49.12,
      HeroType.spiderman: 51.28,
      HeroType.raveness: 53.48,
      HeroType.gambit: 50.43,
      HeroType.druid: 63.89,
      HeroType.thor: 59.86,
      HeroType.shadowThief: 55.32,
      HeroType.iceman: 39.13,
      HeroType.cursedPirate: 49.50,
      HeroType.headlessHorseman: 50.28,
      HeroType.jeanGrey: 68.69,
      HeroType.rogue: 59.00,
      HeroType.krampus: 55.93,
      HeroType.pyromancer: 45.38,
      HeroType.ninja: 51.06,
      HeroType.doctorStrange: 57.14,
      HeroType.paladin: 63.11,
      HeroType.blackPanther: 55.56,
      HeroType.deadpool: 76.27,
      HeroType.artificer: 50.00,
      HeroType.necromancer: 50.42,
      HeroType.captainMarvel: 64.29,
      HeroType.wolverine: 62.32,
      HeroType.psylocke: 71.43,
      HeroType.mysticBrawler: 64.58,
      HeroType.treant: 53.85,
      HeroType.monk: 55.29,
      HeroType.tacticien: 56.52,
      HeroType.paleLady: 55.78,
      HeroType.scarletWitch: 42.11,
      HeroType.vampireLord: 58.33,
      HeroType.santa: 68.18,
      HeroType.huntress: 82.76,
      HeroType.elfeLunaire: 73.17,
      HeroType.loki: 72.58,
      HeroType.cyclops: 68.63,
      HeroType.samurai: 59.09,
      HeroType.duelist: 63.33,
      HeroType.sunElf: 61.54,
      HeroType.gunslinger: 60.00,
      HeroType.storm: 79.49,
      HeroType.barbare: 60.00,
      HeroType.seraph: 81.40,
    },
    HeroType.iceman: {
      HeroType.blackWidow: 37.65,
      HeroType.forgemaster: 25.00,
      HeroType.spiderman: 58.39,
      HeroType.raveness: 47.66,
      HeroType.gambit: 49.01,
      HeroType.druid: 38.46,
      HeroType.thor: 52.05,
      HeroType.alchemist: 60.87,
      HeroType.shadowThief: 38.10,
      HeroType.cursedPirate: 29.79,
      HeroType.headlessHorseman: 55.05,
      HeroType.jeanGrey: 60.84,
      HeroType.rogue: 62.15,
      HeroType.krampus: 54.10,
      HeroType.pyromancer: 48.34,
      HeroType.ninja: 44.19,
      HeroType.doctorStrange: 60.71,
      HeroType.paladin: 39.42,
      HeroType.blackPanther: 61.76,
      HeroType.deadpool: 57.50,
      HeroType.artificer: 71.30,
      HeroType.necromancer: 61.76,
      HeroType.captainMarvel: 56.86,
      HeroType.wolverine: 73.33,
      HeroType.psylocke: 61.90,
      HeroType.mysticBrawler: 47.37,
      HeroType.treant: 73.58,
      HeroType.monk: 57.69,
      HeroType.tacticien: 67.31,
      HeroType.paleLady: 69.44,
      HeroType.scarletWitch: 71.15,
      HeroType.vampireLord: 70.59,
      HeroType.santa: 77.42,
      HeroType.huntress: 69.23,
      HeroType.elfeLunaire: 76.47,
      HeroType.loki: 70.79,
      HeroType.cyclops: 63.89,
      HeroType.samurai: 60.71,
      HeroType.duelist: 50.00,
      HeroType.sunElf: 100.00,
      HeroType.gunslinger: 87.10,
      HeroType.storm: 71.64,
      HeroType.barbare: 79.07,
      HeroType.seraph: 81.48,
    },
    HeroType.thor: {
      HeroType.blackWidow: 35.61,
      HeroType.forgemaster: 50.00,
      HeroType.spiderman: 49.28,
      HeroType.raveness: 43.33,
      HeroType.gambit: 54.61,
      HeroType.druid: 57.14,
      HeroType.alchemist: 40.82,
      HeroType.shadowThief: 58.56,
      HeroType.iceman: 51.37,
      HeroType.cursedPirate: 56.90,
      HeroType.headlessHorseman: 52.60,
      HeroType.jeanGrey: 51.06,
      HeroType.rogue: 57.26,
      HeroType.krampus: 48.05,
      HeroType.pyromancer: 55.83,
      HeroType.ninja: 58.33,
      HeroType.doctorStrange: 58.65,
      HeroType.paladin: 67.65,
      HeroType.blackPanther: 45.41,
      HeroType.deadpool: 55.32,
      HeroType.artificer: 60.83,
      HeroType.necromancer: 63.33,
      HeroType.captainMarvel: 61.45,
      HeroType.wolverine: 61.18,
      HeroType.psylocke: 67.65,
      HeroType.mysticBrawler: 77.27,
      HeroType.treant: 75.00,
      HeroType.monk: 62.60,
      HeroType.tacticien: 67.90,
      HeroType.paleLady: 59.49,
      HeroType.scarletWitch: 63.83,
      HeroType.vampireLord: 61.11,
      HeroType.santa: 62.50,
      HeroType.huntress: 74.42,
      HeroType.elfeLunaire: 60.71,
      HeroType.loki: 61.29,
      HeroType.cyclops: 65.57,
      HeroType.samurai: 60.98,
      HeroType.duelist: 55.56,
      HeroType.sunElf: 47.06,
      HeroType.gunslinger: 67.74,
      HeroType.storm: 66.67,
      HeroType.barbare: 69.57,
      HeroType.seraph: 74.47,
    },
  };

  /// Renvoie le winrate de [heroA] face à [heroB], ou null si aucune stat
  static double? getWinrate(HeroType heroA, HeroType heroB) {
    if (heroA == heroB) return 50.0;
    if (_matrix.containsKey(heroA) && _matrix[heroA]!.containsKey(heroB)) {
      return _matrix[heroA]![heroB];
    }
    if (_matrix.containsKey(heroB) && _matrix[heroB]!.containsKey(heroA)) {
      return 100.0 - _matrix[heroB]![heroA]!;
    }
    return null;
  }

  /// Génère 3 héros adverses selon le mode sélectionné
  static List<HeroType> generateEnemyTrio({
    required MatchupMode mode,
    required bool expert,
    required List<HeroType> playerTrio,
  }) {
    final random = Random();
    final allAvailable = HeroType.values.where((h) => h != HeroType.benjamin).toList();

    switch (mode) {
      case MatchupMode.free:
        final pool = List<HeroType>.from(allAvailable)..shuffle(random);
        return pool.take(3).toList();

      case MatchupMode.random:
        final pool = List<HeroType>.from(allAvailable)..shuffle(random);
        return pool.take(3).toList();

      case MatchupMode.top10:
        if (expert) {
          return _pickBestSynergyTrio(pool: top10Heroes, minTop: 2, topPool: top10Heroes, playerTrio: playerTrio);
        } else {
          final shuffledTop10 = List<HeroType>.from(top10Heroes)..shuffle(random);
          final chosen = <HeroType>[shuffledTop10[0], shuffledTop10[1]];
          final remainingPool = allAvailable.where((h) => !chosen.contains(h)).toList()..shuffle(random);
          chosen.add(remainingPool.first);
          return chosen;
        }

      case MatchupMode.top5:
        if (expert) {
          return _pickBestSynergyTrio(pool: top10Heroes, minTop: 2, topPool: top5Heroes, playerTrio: playerTrio);
        } else {
          final shuffledTop5 = List<HeroType>.from(top5Heroes)..shuffle(random);
          final chosen = <HeroType>[shuffledTop5[0], shuffledTop5[1]];
          final remainingPool = allAvailable.where((h) => !chosen.contains(h)).toList()..shuffle(random);
          chosen.add(remainingPool.first);
          return chosen;
        }
    }
  }

  /// Sélectionne le trio ayant la meilleure couverture / synergie face au Top 10 ou face aux héros du joueur
  static List<HeroType> _pickBestSynergyTrio({
    required List<HeroType> pool,
    required int minTop,
    required List<HeroType> topPool,
    required List<HeroType> playerTrio,
  }) {
    List<HeroType>? bestTrio;
    double bestScore = -1.0;

    final allHeroes = HeroType.values.where((h) => h != HeroType.benjamin).toList();

    // On teste plusieurs combinaisons valides
    for (int i = 0; i < topPool.length; i++) {
      for (int j = i + 1; j < topPool.length; j++) {
        for (final third in allHeroes) {
          if (third == topPool[i] || third == topPool[j]) continue;
          final trio = [topPool[i], topPool[j], third];
          
          // Score de synergie basé sur la couverture minimale face aux cibles
          final score = _evaluateTrioScore(trio, playerTrio.isNotEmpty ? playerTrio : top10Heroes);
          if (score > bestScore) {
            bestScore = score;
            bestTrio = trio;
          }
        }
      }
    }

    return bestTrio ?? [topPool[0], topPool[1], topPool.length > 2 ? topPool[2] : top10Heroes[2]];
  }

  /// Évalue la robustesse d'un trio (winrate moyen et absence de trou critique)
  static double _evaluateTrioScore(List<HeroType> trio, List<HeroType> targets) {
    double totalWinrate = 0;
    int count = 0;
    for (final hero in trio) {
      for (final target in targets) {
        final wr = getWinrate(hero, target) ?? 50.0;
        totalWinrate += wr;
        count++;
      }
    }
    return count > 0 ? totalWinrate / count : 50.0;
  }

  /// L'IA choisit quel héros du joueur bannir
  static HeroType pickAiBan({
    required List<HeroType> playerTrio,
    required List<HeroType> enemyTrio,
    required bool expert,
  }) {
    if (!expert) {
      return playerTrio[Random().nextInt(playerTrio.length)];
    }
    // Mode Expert : Bannit le héros du joueur qui a le plus fort winrate moyen contre les 3 héros de l'IA
    HeroType? mostDangerousHero;
    double highestThreat = -1.0;

    for (final pHero in playerTrio) {
      double threat = 0.0;
      for (final eHero in enemyTrio) {
        threat += (getWinrate(pHero, eHero) ?? 50.0);
      }
      if (threat > highestThreat) {
        highestThreat = threat;
        mostDangerousHero = pHero;
      }
    }

    return mostDangerousHero ?? playerTrio.first;
  }

  /// L'IA choisit secrètement son héros parmi les 2 restants
  static HeroType pickAiHero({
    required List<HeroType> enemyRemainingTwo,
    required List<HeroType> playerRemainingTwo,
    required bool expert,
  }) {
    if (!expert) {
      return enemyRemainingTwo[Random().nextInt(enemyRemainingTwo.length)];
    }
    // Choix stratégique a priori : le héros ayant le meilleur winrate moyen face aux 2 héros restants possibles du joueur
    final h1 = enemyRemainingTwo[0];
    final h2 = enemyRemainingTwo[1];

    double score1 = 0;
    double score2 = 0;

    for (final pHero in playerRemainingTwo) {
      score1 += (getWinrate(h1, pHero) ?? 50.0);
      score2 += (getWinrate(h2, pHero) ?? 50.0);
    }

    return score1 >= score2 ? h1 : h2;
  }

  /// Analyse du Ban Joueur
  static BanAnalysis analyzePlayerBan({
    required HeroType bannedEnemy,
    required List<HeroType> originalEnemyTrio,
    required List<HeroType> originalPlayerTrio,
  }) {
    // Calcul de la menace de chaque héros ennemi pour l'équipe du joueur
    final Map<HeroType, double> threatScores = {};
    for (final eHero in originalEnemyTrio) {
      double threat = 0;
      for (final pHero in originalPlayerTrio) {
        threat += (getWinrate(eHero, pHero) ?? 50.0);
      }
      threatScores[eHero] = threat / originalPlayerTrio.length;
    }

    // Trouve le pire matchup (le héros adverse le plus menaçant)
    HeroType mostDangerous = originalEnemyTrio.first;
    double maxThreat = -1;
    for (final entry in threatScores.entries) {
      if (entry.value > maxThreat) {
        maxThreat = entry.value;
        mostDangerous = entry.key;
      }
    }

    final isOptimal = bannedEnemy == mostDangerous;
    final bannedThreat = threatScores[bannedEnemy] ?? 50.0;

    String explanation;
    if (isOptimal) {
      explanation = "🎯 **Excellent ban !** ${bannedEnemy.label} était la plus grande menace pour ton trio avec un winrate moyen de **${bannedThreat.toStringAsFixed(1)}%** contre tes héros.";
    } else {
      explanation = "⚠️ **Ban améliorable :** Tu as banni ${bannedEnemy.label} (${bannedThreat.toStringAsFixed(1)}% de menace). La plus grande menace statistique était **${mostDangerous.label}** (${maxThreat.toStringAsFixed(1)}% de winrate moyen face à tes 3 héros).";
    }

    return BanAnalysis(
      isOptimal: isOptimal,
      bannedHero: bannedEnemy,
      optimalHero: mostDangerous,
      explanation: explanation,
      threatScores: threatScores,
    );
  }

  /// Analyse du Choix aveugle du Joueur
  static PickAnalysis analyzePlayerPick({
    required HeroType pickedPlayerHero,
    required List<HeroType> playerRemainingTwo,
    required HeroType pickedEnemyHero,
    required List<HeroType> enemyRemainingTwo,
  }) {
    final otherPlayerHero = playerRemainingTwo.firstWhere(
      (h) => h != pickedPlayerHero,
      orElse: () => playerRemainingTwo.first,
    );
    final otherEnemyHero = enemyRemainingTwo.firstWhere(
      (h) => h != pickedEnemyHero,
      orElse: () => enemyRemainingTwo.first,
    );

    final directWR = getWinrate(pickedPlayerHero, pickedEnemyHero);
    final otherPickWR = getWinrate(otherPlayerHero, pickedEnemyHero);

    // Calcul moyen sur les 2 héros adverses possibles
    final avgPickedWR = ((getWinrate(pickedPlayerHero, pickedEnemyHero) ?? 50.0) +
            (getWinrate(pickedPlayerHero, otherEnemyHero) ?? 50.0)) /
        2;
    final avgOtherWR = ((getWinrate(otherPlayerHero, pickedEnemyHero) ?? 50.0) +
            (getWinrate(otherPlayerHero, otherEnemyHero) ?? 50.0)) /
        2;

    String rating;
    String comment;

    final bothGood = (directWR != null && directWR >= 52.0) &&
        (otherPickWR != null && otherPickWR >= 52.0);

    if (directWR != null && directWR >= 55.0) {
      rating = "Avantageux";
      if (bothGood) {
        comment = "✨ **Très bon choix !** Tes deux héros restants avaient un bon matchup (${directWR.toStringAsFixed(1)}% vs ${otherPickWR?.toStringAsFixed(1) ?? 'N/A'}%), tu étais dans une position confortable sans mauvais choix.";
      } else if (avgPickedWR >= avgOtherWR) {
        comment = "🔥 **Choix optimal !** ${pickedPlayerHero.label} possède le meilleur winrate statistique (${directWR.toStringAsFixed(1)}%) face à ${pickedEnemyHero.label}.";
      } else {
        comment = "👍 **Matchup favorable (${directWR.toStringAsFixed(1)}%) !** Tu prends l'avantage sur cette confrontation.";
      }
    } else if (directWR != null && directWR <= 45.0) {
      rating = "Défavorable";
      if (otherPickWR != null && otherPickWR > directWR) {
        comment = "🚨 **Matchup difficile (${directWR.toStringAsFixed(1)}%).** ${otherPlayerHero.label} offrait un meilleur pourcentage (${otherPickWR.toStringAsFixed(1)}%) contre ${pickedEnemyHero.label}.";
      } else {
        comment = "⚠️ **Matchup tendu (${directWR.toStringAsFixed(1)}%).** L'adversaire avait un avantage de draft sur ce tirage.";
      }
    } else {
      rating = "Équilibré";
      comment = "⚖️ **Matchup équilibré (${directWR != null ? '${directWR.toStringAsFixed(1)}%' : 'N/A'}).** Tout se jouera aux dés et à la gestion de main !";
    }

    return PickAnalysis(
      rating: rating,
      directWinrate: directWR,
      comment: comment,
    );
  }
}

enum MatchupMode {
  free('Mode libre', 'Sélection manuelle des 3 adversaires'),
  random('Mode aléatoire', 'L\'IA tire 3 héros au hasard'),
  top10('Mode Top 10', 'L\'IA sélectionne au moins 2 héros du Top 10'),
  top5('Mode Top 5', 'L\'IA sélectionne au moins 2 héros du Top 5');

  const MatchupMode(this.title, this.description);
  final String title;
  final String description;
}

class BanAnalysis {
  final bool isOptimal;
  final HeroType bannedHero;
  final HeroType optimalHero;
  final String explanation;
  final Map<HeroType, double> threatScores;

  const BanAnalysis({
    required this.isOptimal,
    required this.bannedHero,
    required this.optimalHero,
    required this.explanation,
    required this.threatScores,
  });
}

class PickAnalysis {
  final String rating;
  final double? directWinrate;
  final String comment;

  const PickAnalysis({
    required this.rating,
    required this.directWinrate,
    required this.comment,
  });
}
