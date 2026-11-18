part of '../main.dart';

enum HistoryMainTab {
  myHistory('My History', Icons.history_rounded),
  community('Community', Icons.public_rounded),
  clans('Clans', Icons.groups_rounded);

  const HistoryMainTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum CommunityLeaderboardMode {
  normal('Normal', Icons.shield_rounded),
  free('Free', Icons.all_inclusive_rounded),
  naxarus('Naxarus', Icons.local_fire_department_rounded);

  const CommunityLeaderboardMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  final String code;
  final String name;
  final String flag;
}

const List<CountryOption> kSupportedCountries = [
  CountryOption(code: 'FR', name: 'France', flag: '🇫🇷'),
  CountryOption(code: 'US', name: 'United States', flag: '🇺🇸'),
  CountryOption(code: 'CA', name: 'Canada', flag: '🇨🇦'),
  CountryOption(code: 'GB', name: 'United Kingdom', flag: '🇬🇧'),
  CountryOption(code: 'BE', name: 'Belgium', flag: '🇧🇪'),
  CountryOption(code: 'CH', name: 'Switzerland', flag: '🇨🇭'),
  CountryOption(code: 'DE', name: 'Germany', flag: '🇩🇪'),
  CountryOption(code: 'ES', name: 'Spain', flag: '🇪🇸'),
  CountryOption(code: 'IT', name: 'Italy', flag: '🇮🇹'),
  CountryOption(code: 'PT', name: 'Portugal', flag: '🇵🇹'),
  CountryOption(code: 'NL', name: 'Netherlands', flag: '🇳🇱'),
  CountryOption(code: 'PL', name: 'Poland', flag: '🇵🇱'),
  CountryOption(code: 'SE', name: 'Sweden', flag: '🇸🇪'),
  CountryOption(code: 'NO', name: 'Norway', flag: '🇳🇴'),
  CountryOption(code: 'DK', name: 'Denmark', flag: '🇩🇰'),
  CountryOption(code: 'FI', name: 'Finland', flag: '🇫🇮'),
  CountryOption(code: 'AT', name: 'Austria', flag: '🇦🇹'),
  CountryOption(code: 'IE', name: 'Ireland', flag: '🇮🇪'),
  CountryOption(code: 'BR', name: 'Brazil', flag: '🇧🇷'),
  CountryOption(code: 'MX', name: 'Mexico', flag: '🇲🇽'),
  CountryOption(code: 'AR', name: 'Argentina', flag: '🇦🇷'),
  CountryOption(code: 'JP', name: 'Japan', flag: '🇯🇵'),
  CountryOption(code: 'KR', name: 'South Korea', flag: '🇰🇷'),
  CountryOption(code: 'AU', name: 'Australia', flag: '🇦🇺'),
  CountryOption(code: 'NZ', name: 'New Zealand', flag: '🇳🇿'),
  CountryOption(code: 'UN', name: 'International', flag: '🌐'),
];

CountryOption countryOptionForCode(String? code) {
  final normalized = (code ?? 'FR').trim().toUpperCase();
  for (final c in kSupportedCountries) {
    if (c.code == normalized) return c;
  }
  return kSupportedCountries.first;
}

class PlayerProfileInfo {
  const PlayerProfileInfo({
    required this.userId,
    required this.pseudo,
    required this.genericId,
    required this.countryCode,
    required this.favoriteHero,
    required this.shareStats,
  });

  final String userId;
  final String pseudo;
  final String genericId;
  final String countryCode;
  final HeroType favoriteHero;
  final bool shareStats;

  String get displayPseudo =>
      pseudo.trim().isNotEmpty ? pseudo.trim() : genericId;

  factory PlayerProfileInfo.fromSupabase(Map<String, dynamic> row) {
    final uid = row['user_id']?.toString() ?? '';
    final rawPseudo = row['pseudo']?.toString().trim() ?? '';
    final rawGeneric = row['generic_id']?.toString().trim() ?? '';
    final fallbackGen = rawGeneric.isNotEmpty
        ? rawGeneric
        : AppSettings._generateDefaultGenericId(uid);
    final cCode = row['country_code']?.toString().trim().toUpperCase() ?? 'FR';
    final hName = row['favorite_hero']?.toString().trim() ?? 'barbare';
    final hero = _enumByName(HeroType.values, hName) ?? HeroType.barbare;
    return PlayerProfileInfo(
      userId: uid,
      pseudo: rawPseudo,
      genericId: fallbackGen,
      countryCode: cCode.isEmpty ? 'FR' : cCode,
      favoriteHero: hero == HeroType.benjamin ? HeroType.barbare : hero,
      shareStats: row['share_stats'] as bool? ?? true,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.pseudo,
    required this.countryCode,
    required this.favoriteHero,
    required this.hero,
    required this.runsCount,
    required this.avgEnemies,
    required this.avgHp,
    required this.avgDurationSeconds,
    required this.avgScore,
    required this.maxScore,
    required this.streak,
    required this.isCurrentUser,
  });

  final int rank;
  final String userId;
  final String pseudo;
  final String countryCode;
  final HeroType favoriteHero;
  final HeroType hero;
  final int runsCount;
  final double avgEnemies;
  final double avgHp;
  final double avgDurationSeconds;
  final double avgScore;
  final int maxScore;
  final int streak;
  final bool isCurrentUser;

  LeaderboardEntry copyWithRank(int newRank) => LeaderboardEntry(
    rank: newRank,
    userId: userId,
    pseudo: pseudo,
    countryCode: countryCode,
    favoriteHero: favoriteHero,
    hero: hero,
    runsCount: runsCount,
    avgEnemies: avgEnemies,
    avgHp: avgHp,
    avgDurationSeconds: avgDurationSeconds,
    avgScore: avgScore,
    maxScore: maxScore,
    streak: streak,
    isCurrentUser: isCurrentUser,
  );
}

class LeaderboardComputationResult {
  const LeaderboardComputationResult({
    required this.top10,
    required this.playerEntry,
    required this.totalRankedPlayers,
  });

  final List<LeaderboardEntry> top10;
  final LeaderboardEntry? playerEntry;
  final int totalRankedPlayers;
}

class LeaderboardCalculator {
  const LeaderboardCalculator._();

  static bool isBossRunRecord(GameRecord record) {
    return record.mode.difficulty == RunDifficulty.naraxus ||
        record.bossKey != null ||
        record.mode.name.toLowerCase().contains('boss') ||
        record.mode.name.toLowerCase().contains('naxarus') ||
        record.mode.name.toLowerCase().contains('ourokhor') ||
        record.mode.name.toLowerCase().contains('kaelen');
  }

  static bool isNaxarusRunRecord(GameRecord record) {
    if (!isBossRunRecord(record)) return false;
    if (record.bossKey != null && record.bossKey != 'naraxus') {
      return false;
    }
    if (record.mode.name.toLowerCase().contains('ourokhor')) {
      return false;
    }
    return true;
  }

  static bool matchesLeaderboardMode(
    GameRecord record,
    CommunityLeaderboardMode mode,
  ) {
    if (record.hero == HeroType.benjamin) return false;
    return switch (mode) {
      CommunityLeaderboardMode.normal =>
        !isBossRunRecord(record) &&
            record.mode.difficulty == RunDifficulty.medium,
      CommunityLeaderboardMode.free =>
        !isBossRunRecord(record) &&
            record.mode.difficulty == RunDifficulty.free,
      CommunityLeaderboardMode.naxarus => isNaxarusRunRecord(record),
    };
  }

  /// Calcule la meilleure série consécutive de runs à 100 pts (mode Normal/Medium).
  static int computeConsecutive100Streak(List<GameRecord> runs) {
    if (runs.isEmpty) return 0;
    final chronological = [...runs]..sort((a, b) => a.date.compareTo(b.date));
    var current = 0;
    var best = 0;
    for (final run in chronological) {
      if (run.score >= 100) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  /// Calcule la plus longue série consécutive sans perdre (Boss / Naxarus).
  static int computeUndefeatedStreak(List<GameRecord> runs) {
    if (runs.isEmpty) return 0;
    final chronological = [...runs]..sort((a, b) => a.date.compareTo(b.date));
    var current = 0;
    var best = 0;
    for (final run in chronological) {
      if (run.isVictory || run.score >= 100) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  /// Calcule la série pertinente pour une liste de runs selon le mode de classement.
  static int computeStreakForMode(
    List<GameRecord> runs,
    CommunityLeaderboardMode mode,
  ) {
    return switch (mode) {
      CommunityLeaderboardMode.normal => computeConsecutive100Streak(runs),
      CommunityLeaderboardMode.free => computeUndefeatedStreak(runs),
      CommunityLeaderboardMode.naxarus => computeUndefeatedStreak(runs),
    };
  }

  static bool isRunVictory(GameRecord r) {
    if (r.isVictory) return true;
    if (isBossRunRecord(r)) {
      return r.score >= 100 || r.bossHealthRemaining == 0;
    }
    return r.score >= r.mode.defaultTarget;
  }

  /// Utilisé dans "My History" pour afficher la série par héros :
  /// - 0 si aucune victoire
  /// - 100% de victoires -> nb de victoires
  /// - sinon (victoires - défaites), avec un minimum de 1 s'il y a au moins 1 victoire.
  static int computeMyHistoryStreak(
    List<GameRecord> runs, {
    required bool isBossMode,
  }) {
    if (runs.isEmpty) return 0;
    final wins = runs.where(isRunVictory).length;
    if (wins == 0) return 0;
    final losses = runs.length - wins;
    if (losses == 0) return wins;
    return max(1, wins - losses);
  }

  static int compareEntries(
    LeaderboardEntry a,
    LeaderboardEntry b,
    CommunityLeaderboardMode mode,
  ) {
    switch (mode) {
      case CommunityLeaderboardMode.normal:
        final maxDiff = b.maxScore.compareTo(a.maxScore);
        if (maxDiff != 0) return maxDiff;
        // Si le score de 100 est atteint, on met en avant et départage par la série !
        if (a.maxScore >= 100 && b.maxScore >= 100) {
          final streakDiff = b.streak.compareTo(a.streak);
          if (streakDiff != 0) return streakDiff;
        }
        final avgDiff = b.avgScore.compareTo(a.avgScore);
        if (avgDiff != 0) return avgDiff;
        final countDiff = b.runsCount.compareTo(a.runsCount);
        if (countDiff != 0) return countDiff;
        final enemiesDiff = b.avgEnemies.compareTo(a.avgEnemies);
        if (enemiesDiff != 0) return enemiesDiff;
        final hpDiff = b.avgHp.compareTo(a.avgHp);
        if (hpDiff != 0) return hpDiff;
        final timeDiff = a.avgDurationSeconds.compareTo(b.avgDurationSeconds);
        if (timeDiff != 0) return timeDiff;
        return a.pseudo.toLowerCase().compareTo(b.pseudo.toLowerCase());

      case CommunityLeaderboardMode.free:
        final maxDiff = b.maxScore.compareTo(a.maxScore);
        if (maxDiff != 0) return maxDiff;
        final avgDiff = b.avgScore.compareTo(a.avgScore);
        if (avgDiff != 0) return avgDiff;
        final countDiff = b.runsCount.compareTo(a.runsCount);
        if (countDiff != 0) return countDiff;
        final enemiesDiff = b.avgEnemies.compareTo(a.avgEnemies);
        if (enemiesDiff != 0) return enemiesDiff;
        final hpDiff = b.avgHp.compareTo(a.avgHp);
        if (hpDiff != 0) return hpDiff;
        final timeDiff = a.avgDurationSeconds.compareTo(b.avgDurationSeconds);
        if (timeDiff != 0) return timeDiff;
        return a.pseudo.toLowerCase().compareTo(b.pseudo.toLowerCase());

      case CommunityLeaderboardMode.naxarus:
        final streakDiff = b.streak.compareTo(a.streak);
        if (streakDiff != 0) return streakDiff;
        final maxDiff = b.maxScore.compareTo(a.maxScore);
        if (maxDiff != 0) return maxDiff;
        final avgDiff = b.avgScore.compareTo(a.avgScore);
        if (avgDiff != 0) return avgDiff;
        final countDiff = b.runsCount.compareTo(a.runsCount);
        if (countDiff != 0) return countDiff;
        final hpDiff = b.avgHp.compareTo(a.avgHp);
        if (hpDiff != 0) return hpDiff;
        final timeDiff = a.avgDurationSeconds.compareTo(b.avgDurationSeconds);
        if (timeDiff != 0) return timeDiff;
        return a.pseudo.toLowerCase().compareTo(b.pseudo.toLowerCase());
    }
  }

  /// Construit le Top 10 (1 seule entrée max par joueur) + la 11e ligne du joueur courant.
  static LeaderboardComputationResult computeLeaderboard({
    required Map<String, PlayerProfileInfo> profilesByUserId,
    required List<GameRecord> allRecords,
    required CommunityLeaderboardMode mode,
    required String currentUserId,
    HeroType? heroFilter,
    Set<String>? allowedUserIds,
  }) {
    // Regrouper les records par joueur
    final recordsByUser = <String, List<GameRecord>>{};
    for (final record in allRecords) {
      final uid = record.userId ?? '';
      if (uid.isEmpty) continue;
      if (allowedUserIds != null && !allowedUserIds.contains(uid)) {
        continue;
      }
      final profile = profilesByUserId[uid];
      if (profile == null || !profile.shareStats) {
        continue;
      }
      if (!matchesLeaderboardMode(record, mode)) {
        continue;
      }
      if (heroFilter != null && record.hero != heroFilter) {
        continue;
      }
      recordsByUser.putIfAbsent(uid, () => []).add(record);
    }

    final bestEntryPerPlayer = <LeaderboardEntry>[];

    for (final mapEntry in recordsByUser.entries) {
      final uid = mapEntry.key;
      final userRuns = mapEntry.value;
      if (userRuns.isEmpty) continue;
      final profile = profilesByUserId[uid]!;

      // Grouper par héros joué pour ce joueur
      final runsByHero = <HeroType, List<GameRecord>>{};
      for (final r in userRuns) {
        if (r.hero == HeroType.benjamin) continue;
        runsByHero.putIfAbsent(r.hero, () => []).add(r);
      }
      if (runsByHero.isEmpty) continue;

      final candidateHeroEntries = <LeaderboardEntry>[];
      for (final hEntry in runsByHero.entries) {
        final hero = hEntry.key;
        final hRuns = hEntry.value;
        final count = hRuns.length;
        final maxScore = hRuns
            .map((r) => r.score)
            .reduce((a, b) => a > b ? a : b);
        final avgScore =
            hRuns.fold<int>(0, (s, r) => s + r.score) / count;
        final avgEnemies =
            hRuns.fold<int>(0, (s, r) => s + r.enemiesDefeated) / count;
        final hpValues = hRuns
            .map((r) => r.healthRemaining)
            .whereType<int>()
            .toList();
        final avgHp = hpValues.isEmpty
            ? 0.0
            : hpValues.fold<int>(0, (s, v) => s + v) / hpValues.length;
        final durValues = hRuns
            .map((r) => r.duration.inSeconds)
            .where((s) => s > 0)
            .toList();
        final avgDur = durValues.isEmpty
            ? 0.0
            : durValues.fold<int>(0, (s, v) => s + v) / durValues.length;
        final streak = computeStreakForMode(hRuns, mode);

        candidateHeroEntries.add(
          LeaderboardEntry(
            rank: 0,
            userId: uid,
            pseudo: profile.displayPseudo,
            countryCode: profile.countryCode,
            favoriteHero: profile.favoriteHero,
            hero: hero,
            runsCount: count,
            avgEnemies: avgEnemies,
            avgHp: avgHp,
            avgDurationSeconds: avgDur,
            avgScore: avgScore,
            maxScore: maxScore,
            streak: streak,
            isCurrentUser: uid == currentUserId,
          ),
        );
      }

      candidateHeroEntries.sort((a, b) => compareEntries(a, b, mode));
      bestEntryPerPlayer.add(candidateHeroEntries.first);
    }

    bestEntryPerPlayer.sort((a, b) => compareEntries(a, b, mode));

    final ranked = <LeaderboardEntry>[];
    LeaderboardEntry? currentPlayerEntry;

    for (var i = 0; i < bestEntryPerPlayer.length; i++) {
      final entryWithRank = bestEntryPerPlayer[i].copyWithRank(i + 1);
      ranked.add(entryWithRank);
      if (entryWithRank.userId == currentUserId) {
        currentPlayerEntry = entryWithRank;
      }
    }

    return LeaderboardComputationResult(
      top10: ranked.take(10).toList(),
      playerEntry: currentPlayerEntry,
      totalRankedPlayers: ranked.length,
    );
  }
}

enum ClanMembershipStatus {
  pending('Pending', Color(0xffffb300)),
  approved('Approved', Color(0xff4ade80)),
  rejected('Declined', Color(0xfff87171));

  const ClanMembershipStatus(this.label, this.color);
  final String label;
  final Color color;

  static ClanMembershipStatus fromString(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'approved' || 'accepted' => ClanMembershipStatus.approved,
      'rejected' || 'declined' => ClanMembershipStatus.rejected,
      _ => ClanMembershipStatus.pending,
    };
  }
}

class ClanMemberData {
  const ClanMemberData({
    required this.userId,
    required this.pseudo,
    required this.countryCode,
    required this.favoriteHero,
    required this.status,
    required this.isAdmin,
  });

  final String userId;
  final String pseudo;
  final String countryCode;
  final HeroType favoriteHero;
  final ClanMembershipStatus status;
  final bool isAdmin;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'pseudo': pseudo,
    'country_code': countryCode,
    'favorite_hero': favoriteHero.name,
    'status': status.name,
    'role': isAdmin ? 'admin' : 'member',
  };

  factory ClanMemberData.fromJson(Map<String, dynamic> json) {
    final hName = json['favorite_hero']?.toString() ?? 'barbare';
    final hero = _enumByName(HeroType.values, hName) ?? HeroType.barbare;
    return ClanMemberData(
      userId: json['user_id']?.toString() ?? '',
      pseudo: json['pseudo']?.toString().trim() ?? 'Hero',
      countryCode: json['country_code']?.toString().toUpperCase() ?? 'FR',
      favoriteHero: hero == HeroType.benjamin ? HeroType.barbare : hero,
      status: ClanMembershipStatus.fromString(json['status']?.toString()),
      isAdmin: json['role']?.toString() == 'admin',
    );
  }
}

class ClanData {
  const ClanData({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerPseudo,
    required this.members,
  });

  final String id;
  final String name;
  final String ownerId;
  final String ownerPseudo;
  final List<ClanMemberData> members;

  bool isOwner(String userId) => ownerId == userId;

  ClanMemberData? memberFor(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  List<ClanMemberData> get pendingMembers =>
      members.where((m) => m.status == ClanMembershipStatus.pending).toList();

  List<ClanMemberData> get approvedMembers =>
      members.where((m) => m.status == ClanMembershipStatus.approved).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'owner_pseudo': ownerPseudo,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory ClanData.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return ClanData(
      id: json['id']?.toString().toUpperCase() ?? '',
      name: json['name']?.toString() ?? 'Clan',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerPseudo: json['owner_pseudo']?.toString() ?? '',
      members: rawMembers
          .whereType<Map>()
          .map((m) => ClanMemberData.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class CommunityClanRepository {
  CommunityClanRepository._();

  static final CommunityClanRepository instance = CommunityClanRepository._();

  static const String apkDownloadUrl =
      'https://github.com/bdewev18-droid/Dice-throne-Solo/releases/latest/download/app-release.apk';
  static const String webAppUrl =
      'https://bdewev18-droid.github.io/Dice-throne-Solo/';

  static String generateUniqueClanId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final part = List.generate(
      5,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    return 'DT-$part';
  }

  static String buildClanInviteMessage(ClanData clan) {
    return '⚔️ Join my Clan "${clan.name}" on D.T Solo Quest!\n'
        '🔑 Clan Invite ID: ${clan.id}\n\n'
        '📲 Don\'t have the app yet? Download it here:\n'
        '• Android APK: $apkDownloadUrl\n'
        '• Web App: $webAppUrl';
  }

  String currentEffectiveUserId() {
    final session = SupabaseService.instance.currentSession();
    if (session.userId != null && session.userId!.isNotEmpty) {
      return session.userId!;
    }
    return 'local_${AppSettings.instance.playerGenericId}';
  }

  PlayerProfileInfo currentPlayerProfile() {
    final settings = AppSettings.instance;
    return PlayerProfileInfo(
      userId: currentEffectiveUserId(),
      pseudo: settings.playerPseudo,
      genericId: settings.playerGenericId,
      countryCode: settings.playerCountryCode,
      favoriteHero: settings.playerFavoriteHero,
      shareStats: settings.shareStats,
    );
  }

  Future<
    ({
      Map<String, PlayerProfileInfo> profiles,
      List<GameRecord> records,
      List<ClanData> clans,
    })
  >
  loadCommunityAndClansData(List<GameRecord> localRecords) async {
    final myUid = currentEffectiveUserId();
    final myProfile = currentPlayerProfile();

    final profilesMap = <String, PlayerProfileInfo>{};
    if (myProfile.shareStats) {
      profilesMap[myUid] = myProfile;
    }

    final remoteProfiles = await SupabaseService.instance
        .fetchPublicPlayerProfiles();
    for (final row in remoteProfiles) {
      final p = PlayerProfileInfo.fromSupabase(row);
      if (p.userId.isNotEmpty && p.shareStats) {
        profilesMap[p.userId] = p;
      }
    }
    if (myProfile.shareStats) {
      profilesMap[myUid] = myProfile;
    } else {
      profilesMap.remove(myUid);
    }

    // Charger les records publics + records locaux du joueur courant
    final combinedRecords = <GameRecord>[];
    final remoteRows = await SupabaseService.instance.fetchPublicGameRecords();
    for (final row in remoteRows) {
      combinedRecords.add(GameRecord.fromSupabase(row));
    }

    if (myProfile.shareStats) {
      for (final r in localRecords) {
        combinedRecords.add(
          GameRecord(
            id: r.id,
            userId: myUid,
            hero: r.hero,
            date: r.date,
            score: r.score,
            mode: r.mode,
            healthRemaining: r.healthRemaining,
            bossHealthRemaining: r.bossHealthRemaining,
            enemiesDefeated: r.enemiesDefeated,
            duration: r.duration,
            isVictory: r.isVictory,
            bossKey: r.bossKey,
          ),
        );
      }
    }

    // Dédupliquer les records par (userId + hero + mode + score + duration + dateMinute)
    final seenKeys = <String>{};
    final dedupedRecords = <GameRecord>[];
    for (final r in combinedRecords) {
      final uid = r.userId ?? '';
      if (uid.isEmpty) continue;
      final dateMinute =
          '${r.date.toUtc().year}-${r.date.toUtc().month}-${r.date.toUtc().day} ${r.date.toUtc().hour}:${r.date.toUtc().minute}';
      final key =
          '${uid}_${r.hero.name}_${r.mode.name}_${r.score}_${r.duration.inSeconds}_${r.bossKey ?? ''}_$dateMinute';
      if (seenKeys.add(key)) {
        dedupedRecords.add(r);
      }
    }

    // Charger les Clans (Supabase + Cache local)
    final clansById = <String, ClanData>{};
    for (final raw in AppSettings.instance.localClans) {
      final clan = ClanData.fromJson(raw);
      if (clan.id.isNotEmpty) {
        clansById[clan.id] = clan;
      }
    }

    final remoteClans = await SupabaseService.instance
        .fetchUserClansWithMembers();
    for (final raw in remoteClans) {
      final clan = ClanData.fromJson(raw);
      if (clan.id.isNotEmpty) {
        clansById[clan.id] = clan;
      }
    }

    // Ajouter les profils des membres de clans approuvés dans profilesMap s'ils n'y sont pas encore
    for (final clan in clansById.values) {
      for (final member in clan.approvedMembers) {
        profilesMap.putIfAbsent(
          member.userId,
          () => PlayerProfileInfo(
            userId: member.userId,
            pseudo: member.pseudo,
            genericId: member.pseudo,
            countryCode: member.countryCode,
            favoriteHero: member.favoriteHero,
            shareStats: true,
          ),
        );
      }
    }

    final clansList = clansById.values.toList();
    return (
      profiles: profilesMap,
      records: dedupedRecords,
      clans: clansList,
    );
  }

  Future<ClanData> createClan({required String name}) async {
    final myProfile = currentPlayerProfile();
    final clanId = generateUniqueClanId();
    final adminMember = ClanMemberData(
      userId: myProfile.userId,
      pseudo: myProfile.displayPseudo,
      countryCode: myProfile.countryCode,
      favoriteHero: myProfile.favoriteHero,
      status: ClanMembershipStatus.approved,
      isAdmin: true,
    );
    final newClan = ClanData(
      id: clanId,
      name: name.trim(),
      ownerId: myProfile.userId,
      ownerPseudo: myProfile.displayPseudo,
      members: [adminMember],
    );

    final updated = [
      ...AppSettings.instance.localClans.where((c) => c['id'] != clanId),
      newClan.toJson(),
    ];
    await AppSettings.instance.saveLocalClans(updated);

    unawaited(
      SupabaseService.instance.createClanOnServer(
        clanId: clanId,
        name: name.trim(),
        ownerPseudo: myProfile.displayPseudo,
        countryCode: myProfile.countryCode,
        favoriteHero: myProfile.favoriteHero.name,
      ),
    );

    return newClan;
  }

  Future<ClanData> joinClan({
    required String clanId,
    required String pseudo,
    required String countryCode,
    required HeroType favoriteHero,
  }) async {
    final cleanId = clanId.trim().toUpperCase();
    await AppSettings.instance.updatePlayerProfile(
      pseudo: pseudo,
      countryCode: countryCode,
      favoriteHero: favoriteHero,
      shareStats: true,
    );

    final myProfile = currentPlayerProfile();
    final serverClan = await SupabaseService.instance.joinClanOnServer(
      clanId: cleanId,
      pseudo: myProfile.displayPseudo,
      countryCode: myProfile.countryCode,
      favoriteHero: myProfile.favoriteHero.name,
    );

    // Check if clan already exists locally (e.g. testing on same device or cached)
    ClanData? existingLocal;
    for (final raw in AppSettings.instance.localClans) {
      if (raw['id']?.toString().toUpperCase() == cleanId) {
        existingLocal = ClanData.fromJson(raw);
        break;
      }
    }

    final ClanData resultClan;
    if (existingLocal != null) {
      final isOwner = existingLocal.ownerId == myProfile.userId;
      final newMember = ClanMemberData(
        userId: myProfile.userId,
        pseudo: myProfile.displayPseudo,
        countryCode: myProfile.countryCode,
        favoriteHero: myProfile.favoriteHero,
        status: isOwner
            ? ClanMembershipStatus.approved
            : ClanMembershipStatus.pending,
        isAdmin: isOwner,
      );
      final updatedMembers = [
        ...existingLocal.members.where((m) => m.userId != myProfile.userId),
        newMember,
      ];
      resultClan = ClanData(
        id: existingLocal.id,
        name: existingLocal.name,
        ownerId: existingLocal.ownerId,
        ownerPseudo: existingLocal.ownerPseudo,
        members: updatedMembers,
      );
    } else {
      final clanName = serverClan?['name']?.toString() ?? 'Clan $cleanId';
      final ownerId = serverClan?['owner_id']?.toString() ?? '';
      final ownerPseudo = serverClan?['owner_pseudo']?.toString() ?? 'Clan Leader';
      final isOwner = ownerId == myProfile.userId;
      final newMember = ClanMemberData(
        userId: myProfile.userId,
        pseudo: myProfile.displayPseudo,
        countryCode: myProfile.countryCode,
        favoriteHero: myProfile.favoriteHero,
        status: isOwner
            ? ClanMembershipStatus.approved
            : ClanMembershipStatus.pending,
        isAdmin: isOwner,
      );
      resultClan = ClanData(
        id: cleanId,
        name: clanName,
        ownerId: ownerId,
        ownerPseudo: ownerPseudo,
        members: [newMember],
      );
    }

    final updated = [
      ...AppSettings.instance.localClans.where(
        (c) => c['id']?.toString().toUpperCase() != cleanId,
      ),
      resultClan.toJson(),
    ];
    await AppSettings.instance.saveLocalClans(updated);
    return resultClan;
  }

  Future<ClanData> updateMemberStatus({
    required ClanData clan,
    required String memberUserId,
    required ClanMembershipStatus newStatus,
  }) async {
    final updatedMembers = clan.members.map((m) {
      if (m.userId == memberUserId) {
        return ClanMemberData(
          userId: m.userId,
          pseudo: m.pseudo,
          countryCode: m.countryCode,
          favoriteHero: m.favoriteHero,
          status: newStatus,
          isAdmin: m.isAdmin,
        );
      }
      return m;
    }).toList();

    final updatedClan = ClanData(
      id: clan.id,
      name: clan.name,
      ownerId: clan.ownerId,
      ownerPseudo: clan.ownerPseudo,
      members: updatedMembers,
    );

    final updatedList = [
      ...AppSettings.instance.localClans.where((c) => c['id'] != clan.id),
      updatedClan.toJson(),
    ];
    await AppSettings.instance.saveLocalClans(updatedList);

    unawaited(
      SupabaseService.instance.updateClanMemberStatusOnServer(
        clanId: clan.id,
        memberUserId: memberUserId,
        status: newStatus == ClanMembershipStatus.approved
            ? 'approved'
            : 'rejected',
      ),
    );

    return updatedClan;
  }
}

/// Lance le partage natif Android (popin système) ou affiche la boîte de partage multi-canaux.
Future<void> showClanInviteShareDialog(
  BuildContext context,
  ClanData clan,
) async {
  final inviteText = CommunityClanRepository.buildClanInviteMessage(clan);
  const channel = MethodChannel('dt_solo_quest/active_adventure');

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await channel.invokeMethod<bool>('shareText', {
        'subject': 'Join my Clan "${clan.name}" on D.T Solo Quest!',
        'text': inviteText,
      });
    } catch (_) {
      // Fallback to in-app share dialog below
    }
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return Dialog(
        backgroundColor: const Color(0xff171a26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xffffe22d), width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      color: Color(0xffffe22d),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Invite Friends to ${clan.name}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff232738),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffffe22d).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UNIQUE CLAN ID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            clan.id,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xffffe22d),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: clan.id));
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Clan ID copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy ID'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    inviteText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffffe22d),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          try {
                            await channel.invokeMethod<bool>('shareText', {
                              'subject':
                                  'Join my Clan "${clan.name}" on D.T Solo Quest!',
                              'text': inviteText,
                            });
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text(
                          'Phone Share Menu',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'sms:?body=${Uri.encodeComponent(inviteText)}',
                        );
                        await launchUrl(uri);
                      },
                      icon: const Icon(Icons.sms_outlined, size: 17),
                      label: const Text('SMS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'mailto:?subject=${Uri.encodeComponent('Join my D.T Solo Quest Clan (${clan.name})')}&body=${Uri.encodeComponent(inviteText)}',
                        );
                        await launchUrl(uri);
                      },
                      icon: const Icon(Icons.email_outlined, size: 17),
                      label: const Text('Email'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(inviteText)}',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 17),
                      label: const Text('WhatsApp'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: inviteText),
                        );
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Full invitation message copied to clipboard!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.content_copy_rounded, size: 17),
                      label: const Text('Copy Full Message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Ouvre la popin de gestion du Profil Joueur (Pseudo, ID générique, Pays, Avatar Héros, Visibilité Classement).
Future<bool?> showPlayerProfileDialog(
  BuildContext context, {
  bool requireShareStatsForClan = false,
}) {
  final settings = AppSettings.instance;
  final pseudoController = TextEditingController(text: settings.playerPseudo);
  var genericId = settings.playerGenericId;
  var selectedCountry = settings.playerCountryCode;
  var selectedHero = settings.playerFavoriteHero;
  var hideFromLeaderboard = !settings.shareStats;
  if (requireShareStatsForClan) {
    hideFromLeaderboard = false;
  }

  final playableHeroes =
      HeroType.values.where((h) => h != HeroType.benjamin).toList()
        ..sort((a, b) => a.label.compareTo(b.label));

  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentCountry = countryOptionForCode(selectedCountry);
          return Dialog(
            backgroundColor: const Color(0xff161925),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xffffe22d), width: 1.4),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        HeroAvatar(hero: selectedHero, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Player Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${currentCountry.flag} ${pseudoController.text.trim().isNotEmpty ? pseudoController.text.trim() : genericId}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xffffe22d),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (requireShareStatsForClan)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff2b2210),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xffffb300)),
                        ),
                        child: const Text(
                          'Creating or joining a Clan requires sharing your game stats with the community to compute rankings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xffffe22d),
                          ),
                        ),
                      ),
                    const Text(
                      'Player Pseudo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pseudoController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Leave blank to use $genericId',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Generate new default ID',
                          icon: const Icon(Icons.casino_outlined, size: 20),
                          onPressed: () {
                            setModalState(() {
                              genericId = AppSettings._generateDefaultGenericId(
                                '',
                              );
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Default unique ID if left blank: $genericId',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: currentCountry.code,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: kSupportedCountries
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text('${c.flag}  ${c.name} (${c.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCountry = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Favorite Hero (Profile Avatar)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<HeroType>(
                      initialValue: selectedHero,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: playableHeroes
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HeroAvatar(hero: h, size: 24),
                                  const SizedBox(width: 8),
                                  Text(h.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedHero = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1e2233),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: CheckboxListTile(
                        value: hideFromLeaderboard,
                        onChanged: requireShareStatsForClan
                            ? null
                            : (val) {
                                setModalState(
                                  () => hideFromLeaderboard = val ?? false,
                                );
                              },
                        title: const Text(
                          'Do not appear in the general leaderboard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: const Text(
                          'If checked, your stats are hidden and excluded from both Community and Clan rankings.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffffe22d),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        await settings.updatePlayerProfile(
                          pseudo: pseudoController.text,
                          genericId: genericId,
                          countryCode: selectedCountry,
                          favoriteHero: selectedHero,
                          shareStats: !hideFromLeaderboard,
                        );
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop(true);
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class PlayerProfileChipButton extends StatelessWidget {
  const PlayerProfileChipButton({required this.onUpdated, super.key});

  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final country = countryOptionForCode(settings.playerCountryCode);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final changed = await showPlayerProfileDialog(context);
        if (changed == true) {
          onUpdated();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xffffe22d).withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroAvatar(hero: settings.playerFavoriteHero, size: 22),
            const SizedBox(width: 6),
            Text(country.flag, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                settings.displayPseudo,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: Color(0xffffe22d),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityLeaderboardView extends StatefulWidget {
  const CommunityLeaderboardView({
    required this.profilesByUserId,
    required this.allRecords,
    required this.currentUserId,
    required this.onOpenProfile,
    this.allowedUserIds,
    this.headerBanner,
    super.key,
  });

  final Map<String, PlayerProfileInfo> profilesByUserId;
  final List<GameRecord> allRecords;
  final String currentUserId;
  final VoidCallback onOpenProfile;
  final Set<String>? allowedUserIds;
  final Widget? headerBanner;

  @override
  State<CommunityLeaderboardView> createState() =>
      _CommunityLeaderboardViewState();
}

class _CommunityLeaderboardViewState extends State<CommunityLeaderboardView> {
  CommunityLeaderboardMode _mode = CommunityLeaderboardMode.normal;
  HeroType? _selectedHero; // null = All Heroes

  @override
  Widget build(BuildContext context) {
    final playableHeroes =
        HeroType.values.where((h) => h != HeroType.benjamin).toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    final result = LeaderboardCalculator.computeLeaderboard(
      profilesByUserId: widget.profilesByUserId,
      allRecords: widget.allRecords,
      mode: _mode,
      currentUserId: widget.currentUserId,
      heroFilter: _selectedHero,
      allowedUserIds: widget.allowedUserIds,
    );

    final isBossMode = _mode == CommunityLeaderboardMode.naxarus;
    final shareEnabled = AppSettings.instance.shareStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBanner != null) ...[
          widget.headerBanner!,
          const SizedBox(height: 10),
        ],
        // Mode Selector (Normal | Free | Naxarus) & Hero Filter
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xff1b1d29),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: CommunityLeaderboardMode.values.map((m) {
                    final selected = _mode == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xffffe22d)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: selected ? Colors.black : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: DropdownButtonFormField<HeroType?>(
                  initialValue: _selectedHero,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<HeroType?>(
                      value: null,
                      child: Text(
                        'All Heroes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...playableHeroes.map(
                      (h) => DropdownMenuItem<HeroType?>(
                        value: h,
                        child: Row(
                          children: [
                            HeroAvatar(hero: h, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                h.label,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedHero = val),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _modeDescription(_mode),
          style: const TextStyle(fontSize: 11.5, color: Color(0xffbbcbbb)),
        ),
        const SizedBox(height: 10),
        // Table Header matching History columns + Streak
        _LeaderboardTableHeader(isBossMode: isBossMode),
        const Divider(height: 10),
        // Top 10 List
        Expanded(
          child: result.top10.isEmpty
              ? Center(
                  child: Text(
                    _selectedHero == null
                        ? 'No community runs recorded for ${_mode.label} mode yet.'
                        : 'No community runs recorded with ${_selectedHero!.label} in ${_mode.label} mode yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: result.top10.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = result.top10[index];
                    return _LeaderboardRowWidget(
                      entry: entry,
                      mode: _mode,
                      isBossMode: isBossMode,
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        // 11th Row: Pinned Player Result & Rank
        _Pinned11thPlayerRow(
          playerEntry: result.playerEntry,
          mode: _mode,
          isBossMode: isBossMode,
          selectedHero: _selectedHero,
          shareEnabled: shareEnabled,
          onOpenProfile: widget.onOpenProfile,
        ),
      ],
    );
  }

  String _modeDescription(CommunityLeaderboardMode mode) {
    return switch (mode) {
      CommunityLeaderboardMode.normal =>
        'Top 10 by Best Score in Normal (Medium) mode — Consecutive 100-pt Streak 🔥 highlighted & breaks ties at 100 pts.',
      CommunityLeaderboardMode.free =>
        'Top 10 by Maximum Score achieved in Free mode.',
      CommunityLeaderboardMode.naxarus =>
        'Top 10 by Longest Undefeated Win Streak 🔥 against Naxarus.',
    };
  }
}

class _LeaderboardTableHeader extends StatelessWidget {
  const _LeaderboardTableHeader({required this.isBossMode});

  final bool isBossMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text(
              'Rank / Player & Hero',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'NB',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xffffe22d),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          if (!isBossMode)
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/minion.webp',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const Expanded(
            child: Icon(Icons.favorite, size: 16, color: Color(0xffffe22d)),
          ),
          const Expanded(
            child: Icon(Icons.timer, size: 16, color: Color(0xffffe22d)),
          ),
          const Expanded(
            child: Icon(Icons.emoji_events, size: 16, color: Color(0xffffe22d)),
          ),
          const Expanded(
            child: Tooltip(
              message: 'Streak',
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 17,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRowWidget extends StatelessWidget {
  const _LeaderboardRowWidget({
    required this.entry,
    required this.mode,
    required this.isBossMode,
    this.isPinnedFooter = false,
  });

  final LeaderboardEntry entry;
  final CommunityLeaderboardMode mode;
  final bool isBossMode;
  final bool isPinnedFooter;

  @override
  Widget build(BuildContext context) {
    final country = countryOptionForCode(entry.countryCode);
    final highlightStreak =
        (mode == CommunityLeaderboardMode.normal &&
            entry.maxScore >= 100 &&
            entry.streak > 0) ||
        (mode == CommunityLeaderboardMode.naxarus && entry.streak > 0) ||
        (mode == CommunityLeaderboardMode.free && entry.streak > 0);

    final bgColor = isPinnedFooter
        ? const Color(0xff262214)
        : entry.isCurrentUser
        ? const Color(0xff2c2612)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: (entry.isCurrentUser && !isPinnedFooter)
            ? Border.all(
                color: const Color(0xffffe22d).withValues(alpha: 0.7),
                width: 1.2,
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _RankBadge(rank: entry.rank),
                const SizedBox(width: 6),
                HeroAvatar(hero: entry.hero, size: 32),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            country.flag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              entry.pseudo,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: entry.isCurrentUser
                                    ? const Color(0xffffe22d)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          if (entry.isCurrentUser) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffffe22d),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        entry.hero.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _HistoryMetricText(entry.runsCount.toString()),
          ),
          if (!isBossMode)
            Expanded(
              child: _HistoryMetricText(_formatNumber(entry.avgEnemies)),
            ),
          Expanded(
            child: _HistoryMetricText(_formatNumber(entry.avgHp)),
          ),
          Expanded(
            child: _HistoryMetricText(
              _formatSmartDuration(
                Duration(seconds: entry.avgDurationSeconds.round()),
              ),
            ),
          ),
          Expanded(
            child: _HistoryMetricText(
              entry.maxScore.toString(),
              color: const Color(0xffffe22d),
            ),
          ),
          Expanded(
            child: Center(
              child: highlightStreak
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orangeAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '🔥${entry.streak}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    )
                  : Text(
                      entry.streak > 0 ? '${entry.streak}' : '-',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (rank == 1) {
      bg = const Color(0xffffd700);
      fg = Colors.black;
    } else if (rank == 2) {
      bg = const Color(0xffc0c0c0);
      fg = Colors.black;
    } else if (rank == 3) {
      bg = const Color(0xffcd7f32);
      fg = Colors.black;
    } else {
      bg = const Color(0xff25293a);
      fg = Colors.white70;
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _Pinned11thPlayerRow extends StatelessWidget {
  const _Pinned11thPlayerRow({
    required this.playerEntry,
    required this.mode,
    required this.isBossMode,
    required this.selectedHero,
    required this.shareEnabled,
    required this.onOpenProfile,
  });

  final LeaderboardEntry? playerEntry;
  final CommunityLeaderboardMode mode;
  final bool isBossMode;
  final HeroType? selectedHero;
  final bool shareEnabled;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1e1c14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xffffe22d).withValues(alpha: 0.85),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xffffe22d).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR STANDING (11TH ROW)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xffffe22d),
                    letterSpacing: 0.8,
                  ),
                ),
                if (playerEntry != null)
                  Text(
                    'Rank #${playerEntry!.rank}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          if (!shareEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You opted out of leaderboards in your Profile.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenProfile,
                    child: const Text('Profile'),
                  ),
                ],
              ),
            )
          else if (playerEntry != null)
            _LeaderboardRowWidget(
              entry: playerEntry!,
              mode: mode,
              isBossMode: isBossMode,
              isPinnedFooter: true,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  if (selectedHero != null) ...[
                    Opacity(
                      opacity: 0.4,
                      child: HeroAvatar(hero: selectedHero!, size: 30),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${selectedHero!.label}: Unplayed in ${mode.label} mode (No ranking yet)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No run recorded in ${mode.label} mode yet. Complete a run to enter the leaderboard!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ClansTabView extends StatefulWidget {
  const ClansTabView({
    required this.profilesByUserId,
    required this.allRecords,
    required this.clans,
    required this.currentUserId,
    required this.onRefresh,
    super.key,
  });

  final Map<String, PlayerProfileInfo> profilesByUserId;
  final List<GameRecord> allRecords;
  final List<ClanData> clans;
  final String currentUserId;
  final VoidCallback onRefresh;

  @override
  State<ClansTabView> createState() => _ClansTabViewState();
}

class _ClansTabViewState extends State<ClansTabView> {
  String? _selectedClanId;

  ClanData? get _activeClan {
    if (widget.clans.isEmpty) return null;
    if (_selectedClanId != null) {
      for (final c in widget.clans) {
        if (c.id == _selectedClanId) return c;
      }
    }
    return widget.clans.first;
  }

  Future<void> _handleCreateClan() async {
    if (!AppSettings.instance.shareStats) {
      final enabled = await showPlayerProfileDialog(
        context,
        requireShareStatsForClan: true,
      );
      if (enabled != true || !AppSettings.instance.shareStats) return;
      widget.onRefresh();
    }
    if (!mounted) return;

    final nameController = TextEditingController();
    final created = await showDialog<ClanData>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xff171a26),
          title: const Text('Create a Clan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Name your Clan. A unique Clan ID will be generated so you can invite your friends.',
                style: TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Clan Name',
                  hintText: 'e.g. Dice Legends',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffffe22d),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final clan = await CommunityClanRepository.instance.createClan(
                  name: name,
                );
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop(clan);
                }
              },
              child: const Text('Create & Get ID'),
            ),
          ],
        );
      },
    );

    if (created != null && mounted) {
      setState(() => _selectedClanId = created.id);
      widget.onRefresh();
      await showClanInviteShareDialog(context, created);
    }
  }

  Future<void> _handleJoinClan() async {
    final settings = AppSettings.instance;
    final idController = TextEditingController();
    final pseudoController = TextEditingController(text: settings.playerPseudo);
    var selectedCountry = settings.playerCountryCode;
    var selectedHero = settings.playerFavoriteHero;
    final playableHeroes =
        HeroType.values.where((h) => h != HeroType.benjamin).toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    final joined = await showDialog<ClanData>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xff171a26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffffe22d), width: 1.4),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.vpn_key_rounded,
                            color: Color(0xffffe22d),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Join a Clan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the Clan ID you received and complete your player profile (Pseudo, Country, Favorite Hero Avatar). The Clan Admin will validate your request.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: idController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Clan ID (e.g. DT-7K9M)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pseudoController,
                        decoration: InputDecoration(
                          labelText: 'Your Pseudo',
                          hintText:
                              'Leave blank for ${settings.playerGenericId}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: countryOptionForCode(selectedCountry).code,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                        items: kSupportedCountries
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text('${c.flag}  ${c.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCountry = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<HeroType>(
                        initialValue: selectedHero,
                        decoration: const InputDecoration(
                          labelText: 'Favorite Hero (Avatar)',
                          border: OutlineInputBorder(),
                        ),
                        items: playableHeroes
                            .map(
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HeroAvatar(hero: h, size: 24),
                                    const SizedBox(width: 8),
                                    Text(h.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedHero = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xffffe22d),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          final code = idController.text.trim().toUpperCase();
                          if (code.isEmpty) return;
                          final clan = await CommunityClanRepository.instance
                              .joinClan(
                                clanId: code,
                                pseudo: pseudoController.text,
                                countryCode: selectedCountry,
                                favoriteHero: selectedHero,
                              );
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop(clan);
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Request to Join Clan'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (joined != null && mounted) {
      setState(() => _selectedClanId = joined.id);
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareEnabled = AppSettings.instance.shareStats;
    if (!shareEnabled) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xff181b28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 42,
                color: Color(0xffffe22d),
              ),
              const SizedBox(height: 12),
              const Text(
                'Community Data Sharing Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To create or join a Clan, you must enable data sharing with the community so Clan leaderboards can be calculated.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffffe22d),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  await AppSettings.instance.updatePlayerProfile(
                    shareStats: true,
                  );
                  widget.onRefresh();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Enable Data Sharing'),
              ),
            ],
          ),
        ),
      );
    }

    final activeClan = _activeClan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Action Bar: Create Clan / Join Clan / Clan Switcher
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: _handleCreateClan,
                icon: const Icon(Icons.add_moderator_rounded, size: 17),
                label: const Text(
                  'Create Clan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: _handleJoinClan,
                icon: const Icon(Icons.vpn_key_rounded, size: 17),
                label: const Text(
                  'Join with ID',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.clans.isEmpty)
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: const Color(0xff171a26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 46,
                      color: Color(0xffffe22d),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No Clan Joined Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Create a new Clan to get a unique invite ID and share it with your friends, or enter a Clan ID to join an existing lobby.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Multi-Clan Lobby Switcher
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.clans.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final clan = widget.clans[index];
                final selected = activeClan?.id == clan.id;
                final myMember = clan.memberFor(widget.currentUserId);
                final isAdmin =
                    clan.isOwner(widget.currentUserId) ||
                    (myMember?.isAdmin ?? false);
                final isPending =
                    !isAdmin &&
                    myMember?.status == ClanMembershipStatus.pending;

                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedClanId = clan.id),
                  selectedColor: const Color(0xffffe22d),
                  backgroundColor: const Color(0xff1c1f2e),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin
                            ? Icons.workspace_premium_rounded
                            : isPending
                            ? Icons.hourglass_top_rounded
                            : Icons.shield_rounded,
                        size: 14,
                        color: selected ? Colors.black : Colors.amberAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${clan.name} (${clan.id})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.black : Colors.white,
                        ),
                      ),
                      if (isAdmin && clan.pendingMembers.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${clan.pendingMembers.length}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (activeClan != null)
            Expanded(child: _buildActiveClanBody(activeClan)),
        ],
      ],
    );
  }

  Widget _buildActiveClanBody(ClanData clan) {
    final myMember = clan.memberFor(widget.currentUserId);
    final isAdmin =
        clan.isOwner(widget.currentUserId) || (myMember?.isAdmin ?? false);
    final myStatus = isAdmin
        ? ClanMembershipStatus.approved
        : (myMember?.status ?? ClanMembershipStatus.pending);

    final approvedUserIds = clan.approvedMembers.map((m) => m.userId).toSet();
    if (isAdmin) {
      approvedUserIds.add(widget.currentUserId);
    }

    final clanBanner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xff1b1f2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            clan.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: myStatus.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: myStatus.color),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : myStatus.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: myStatus.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: ${clan.id} • ${clan.approvedMembers.length} member(s)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Clan Members & Requests',
                onPressed: () => _showClanMembersSheet(clan, isAdmin: isAdmin),
                icon: Badge(
                  isLabelVisible: isAdmin && clan.pendingMembers.isNotEmpty,
                  label: Text('${clan.pendingMembers.length}'),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => showClanInviteShareDialog(context, clan),
                icon: const Icon(Icons.share_rounded, size: 15),
                label: const Text(
                  'Share ID',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          // Admin Pending Requests inline alert
          if (isAdmin && clan.pendingMembers.isNotEmpty) ...[
            const Divider(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                  color: Color(0xffffb300),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${clan.pendingMembers.length} player(s) waiting for your approval to join!',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xffffe22d),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showClanMembersSheet(clan, isAdmin: true),
                  child: const Text('Review Requests'),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (myStatus != ClanMembershipStatus.approved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          clanBanner,
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xff191c28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: myStatus.color.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      myStatus == ClanMembershipStatus.pending
                          ? Icons.hourglass_top_rounded
                          : Icons.cancel_outlined,
                      size: 40,
                      color: myStatus.color,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      myStatus == ClanMembershipStatus.pending
                          ? 'Membership Pending Approval'
                          : 'Membership Request Declined',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      myStatus == ClanMembershipStatus.pending
                          ? 'Your request to join "${clan.name}" (${clan.id}) has been sent. Once the Clan Admin approves your request, the Clan leaderboard will appear here.'
                          : 'The Clan Admin declined your request to join "${clan.name}".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CommunityLeaderboardView(
      profilesByUserId: widget.profilesByUserId,
      allRecords: widget.allRecords,
      currentUserId: widget.currentUserId,
      allowedUserIds: approvedUserIds,
      headerBanner: clanBanner,
      onOpenProfile: () async {
        final updated = await showPlayerProfileDialog(context);
        if (updated == true) {
          widget.onRefresh();
        }
      },
    );
  }

  void _showClanMembersSheet(ClanData clan, {required bool isAdmin}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff171a26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentClan =
                widget.clans.where((c) => c.id == clan.id).firstOrNull ?? clan;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Color(0xffffe22d),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${currentClan.name} — Members (${currentClan.members.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: currentClan.members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = currentClan.members[index];
                          final flag = countryOptionForCode(
                            member.countryCode,
                          ).flag;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: HeroAvatar(
                              hero: member.favoriteHero,
                              size: 36,
                            ),
                            title: Row(
                              children: [
                                Text(flag),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    member.pseudo,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: member.status.color.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    member.isAdmin
                                        ? 'Admin'
                                        : member.status.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: member.status.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Favorite Hero: ${member.favoriteHero.label}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white60,
                              ),
                            ),
                            trailing:
                                isAdmin && !member.isAdmin
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (member.status !=
                                          ClanMembershipStatus.approved)
                                        IconButton(
                                          tooltip: 'Approve member',
                                          icon: const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xff4ade80),
                                          ),
                                          onPressed: () async {
                                            await CommunityClanRepository
                                                .instance
                                                .updateMemberStatus(
                                                  clan: currentClan,
                                                  memberUserId: member.userId,
                                                  newStatus:
                                                      ClanMembershipStatus
                                                          .approved,
                                                );
                                            widget.onRefresh();
                                            if (sheetCtx.mounted) {
                                              Navigator.of(sheetCtx).pop();
                                            }
                                          },
                                        ),
                                      if (member.status !=
                                          ClanMembershipStatus.rejected)
                                        IconButton(
                                          tooltip: 'Decline / Remove member',
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            color: Color(0xfff87171),
                                          ),
                                          onPressed: () async {
                                            await CommunityClanRepository
                                                .instance
                                                .updateMemberStatus(
                                                  clan: currentClan,
                                                  memberUserId: member.userId,
                                                  newStatus:
                                                      ClanMembershipStatus
                                                          .rejected,
                                                );
                                            widget.onRefresh();
                                            if (sheetCtx.mounted) {
                                              Navigator.of(sheetCtx).pop();
                                            }
                                          },
                                        ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
