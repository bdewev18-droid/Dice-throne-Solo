part of '../main.dart';

enum _BestiaryRankFilter {
  all('All', null, Color(0xffffe22d)),
  green('Green', EnemyRank.green, Color(0xff34d36d)),
  blue('Blue', EnemyRank.blue, Color(0xff3bb9ff)),
  violet('Violet', EnemyRank.violet, Color(0xff9b58ff)),
  orange('Orange', EnemyRank.orange, Color(0xffff8a2b)),
  boss('Boss', null, Color(0xffd51f2a));

  const _BestiaryRankFilter(this.label, this.rank, this.color);

  final String label;
  final EnemyRank? rank;
  final Color color;

  bool matches(EnemyProfile profile) {
    return switch (this) {
      _BestiaryRankFilter.all => true,
      _BestiaryRankFilter.green => profile.rank == EnemyRank.green,
      _BestiaryRankFilter.blue => profile.rank == EnemyRank.blue,
      _BestiaryRankFilter.violet => profile.rank == EnemyRank.violet,
      _BestiaryRankFilter.orange => profile.rank == EnemyRank.orange,
      _BestiaryRankFilter.boss =>
        profile.key == 'naraxus' || profile.key == 'kaelen-voss',
    };
  }
}

enum _BestiaryPackFilter {
  all('All packs', null, 'assets/packs/pack_dta.webp'),
  dta('DTA Minions', 'dta', 'assets/packs/pack_dta.webp'),
  promo('Promo Pack', 'promo', 'assets/packs/pack_promo.webp'),
  santa("Santa's Pack", 'santa', 'assets/packs/pack_santa.webp'),
  community("Community's Cards", 'community', 'assets/packs/pack_community.webp');

  const _BestiaryPackFilter(this.label, this.packKey, this.imageAsset);

  final String label;
  final String? packKey;
  final String imageAsset;

  bool matches(EnemyProfile profile) {
    if (packKey == null) return true;
    return profile.sourcePack == packKey;
  }
}

enum _BestiaryStatusFilter {
  all('All cards'),
  defeated('Defeated'),
  undefeated('Undefeated'),
  banned('Banned');

  const _BestiaryStatusFilter(this.label);
  final String label;
}

enum _BestiaryViewMode {
  grid3,
  grid4,
  list;
}

List<StatusTokenRule> _profileTokenRules(EnemyProfile profile) {
  final foundKeys = <String>{};
  final result = <StatusTokenRule>[];

  void addToken(String? raw) {
    if (raw == null) return;
    var name = raw.trim();
    if (name.isEmpty) return;
    if (name.startsWith('token:')) {
      name = name.substring('token:'.length).trim();
    }
    final norm = _normalizeTokenKey(name);
    if (norm.isEmpty || foundKeys.contains(norm)) return;
    final rule = TokenCatalogRepository.byLabel(name);
    if (rule != null) {
      foundKeys.add(norm);
      result.add(rule);
    }
  }

  void scanDisplayRows(List<DisplayRow> rows) {
    for (final row in rows) {
      for (final item in row.items) {
        if (item.startsWith('token:')) {
          addToken(item);
        }
      }
    }
  }

  for (final t in profile.initialTokens) {
    addToken(t);
  }

  for (final goal in profile.attackPlan.goals) {
    final effect = goal.effect;
    if (effect != null) {
      for (final t in effect.heroTokens) {
        addToken(t);
      }
      for (final t in effect.minionTokens) {
        addToken(t);
      }
      final extra = effect.extraRoll;
      if (extra != null) {
        for (final o in extra.outcomes) {
          for (final t in o.tokens) {
            addToken(t);
          }
        }
        scanDisplayRows(extra.displayRows);
      }
    }
  }

  for (final effect in profile.attackPlan.suiteEffects.values) {
    for (final t in effect.heroTokens) {
      addToken(t);
    }
    for (final t in effect.minionTokens) {
      addToken(t);
    }
    final extra = effect.extraRoll;
    if (extra != null) {
      for (final o in extra.outcomes) {
        for (final t in o.tokens) {
          addToken(t);
        }
      }
      scanDisplayRows(extra.displayRows);
    }
  }

  for (final rule in profile.attackPlan.conditionalRules) {
    for (final t in rule.effect.heroTokens) {
      addToken(t);
    }
    for (final t in rule.effect.minionTokens) {
      addToken(t);
    }
    for (final t in rule.condition.present) {
      addToken(t);
    }
    scanDisplayRows(rule.displayRows);
  }

  scanDisplayRows(profile.attackPlan.displayRows);

  for (final d in profile.defenseEffects) {
    for (final t in d.tokens) {
      addToken(t);
    }
  }
  scanDisplayRows(profile.defenseDisplayRows);

  for (final p in profile.passives) {
    final eff = p.effect;
    if (eff != null) {
      for (final t in eff.heroTokens) {
        addToken(t);
      }
    }
  }
  scanDisplayRows(profile.passiveDisplayRows);

  if ((profile.key == 'naraxus' || profile.key == 'kaelen-voss') &&
      profile.attackPlan.style == MinionAttackStyle.none &&
      profile.attackPlan.displayRows.isEmpty) {
    for (final bToken in ['Poison', 'Brûlure', 'Commotion', 'À Terre', 'Cécité']) {
      addToken(bToken);
    }
  }

  return result;
}

class BestiaryPage extends StatefulWidget {
  const BestiaryPage({
    this.activeAdventure,
    this.historyRecords = const [],
    super.key,
  });

  final AdventureState? activeAdventure;
  final List<GameRecord> historyRecords;

  @override
  State<BestiaryPage> createState() => _BestiaryPageState();
}

class _BestiaryPageState extends State<BestiaryPage> {
  final Set<_BestiaryRankFilter> _selectedRanks = <_BestiaryRankFilter>{};
  final Set<_BestiaryPackFilter> _selectedPacks = <_BestiaryPackFilter>{};
  final Set<_BestiaryStatusFilter> _selectedStatuses = <_BestiaryStatusFilter>{};
  final Set<String> _selectedTokenLabels = <String>{};
  _BestiaryViewMode _viewMode = _BestiaryViewMode.grid3;

  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  List<EnemyProfile> _allCatalogProfiles() {
    final byKey = <String, EnemyProfile>{};
    for (final profile in EnemyProfileRepository.all) {
      if (profile.key == 'green-fallback' ||
          profile.key == 'blue-generic' ||
          profile.key == 'violet-generic' ||
          profile.key == 'orange-generic') {
        continue;
      }
      if (!profile.isFullyValidated) {
        continue;
      }
      byKey[profile.key] = profile;
    }
    final viseer =
        EnemyProfileRepository.byKey('viseer') ??
        defaultProfileFor(EnemyRank.viseer);
    byKey.putIfAbsent(viseer.key, () => viseer);
    final naxarus = EnemyProfileRepository.byKey('naraxus') ?? naraxusProfile;
    byKey.putIfAbsent(naxarus.key, () => naxarus);
    final kaelenVoss =
        EnemyProfileRepository.byKey('kaelen-voss') ?? kaelenVossProfile;
    byKey.putIfAbsent(kaelenVoss.key, () => kaelenVoss);

    int rankOrder(EnemyRank r) => switch (r) {
      EnemyRank.green => 0,
      EnemyRank.blue => 1,
      EnemyRank.violet => 2,
      EnemyRank.orange => 3,
      EnemyRank.viseer => 4,
      EnemyRank.naraxus => 5,
    };

    final list = byKey.values.toList()
      ..sort((a, b) {
        final rCmp = rankOrder(a.rank).compareTo(rankOrder(b.rank));
        if (rCmp != 0) return rCmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  Set<String> _computedDefeatedKeys() {
    final keys = <String>{...AppSettings.instance.defeatedEnemyKeys};
    final adv = widget.activeAdventure;
    if (adv != null) {
      for (final enemy in adv.enemies) {
        if (enemy.defeated && !enemy.fled && enemy.profileKey != null) {
          keys.add(enemy.profileKey!);
        }
      }
    }
    if (widget.historyRecords.any(
      (r) => r.mode.difficulty == RunDifficulty.naraxus && r.isVictory,
    )) {
      keys.add('naraxus');
    }
    return keys;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xff4fa8ff)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff8ab4f8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildHubOptionChip({
    required bool isSelected,
    required String label,
    Widget? leading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 8 : 11,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffffe22d).withValues(alpha: 0.18)
              : const Color(0xff121929),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xffffe22d) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xffffe22d).withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              if (label.isNotEmpty) const SizedBox(width: 6),
            ],
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xffffe22d) : Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              const Icon(Icons.check, size: 13, color: Color(0xffffe22d)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    Widget? leading,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: label.isEmpty ? 5 : 8,
        right: 4,
        top: 3,
        bottom: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff162238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xff4fa8ff).withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            if (label.isNotEmpty) const SizedBox(width: 5),
          ],
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (leading != null) ...[
            const SizedBox(width: 3),
          ],
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onDeleted,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterHub(List<EnemyProfile> allProfiles, Set<String> defeatedKeys) {
    final tempRanks = Set<_BestiaryRankFilter>.from(_selectedRanks);
    final tempPacks = Set<_BestiaryPackFilter>.from(_selectedPacks);
    final tempStatuses = Set<_BestiaryStatusFilter>.from(_selectedStatuses);
    final tempTokens = Set<String>.from(_selectedTokenLabels);
    String tokenSearch = '';

    final tokenMap = <String, StatusTokenRule>{};
    final tokenCounts = <String, int>{};

    for (final profile in allProfiles) {
      final rules = _profileTokenRules(profile);
      for (final rule in rules) {
        tokenMap[rule.label] = rule;
        tokenCounts[rule.label] = (tokenCounts[rule.label] ?? 0) + 1;
      }
    }

    final sortedRules = tokenMap.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final previewCount = allProfiles.where((profile) {
              if (tempRanks.isNotEmpty && !tempRanks.any((r) => r.matches(profile))) {
                return false;
              }
              if (tempPacks.isNotEmpty && !tempPacks.any((p) => p.matches(profile))) {
                return false;
              }
              final isDefeated = defeatedKeys.contains(profile.key);
              final isBanned = AppSettings.instance.disabledCommunityEnemyKeys.contains(profile.key);
              if (tempStatuses.isNotEmpty && !tempStatuses.any((s) => switch (s) {
                _BestiaryStatusFilter.all => true,
                _BestiaryStatusFilter.defeated => isDefeated,
                _BestiaryStatusFilter.undefeated => !isDefeated,
                _BestiaryStatusFilter.banned => isBanned,
              })) {
                return false;
              }
              if (tempTokens.isNotEmpty) {
                final rules = _profileTokenRules(profile);
                final profileTokenNames = rules.map((r) => r.label).toSet();
                if (!tempTokens.any(profileTokenNames.contains)) return false;
              }
              return true;
            }).length;

            final hasActiveFilters = tempRanks.isNotEmpty ||
                tempPacks.isNotEmpty ||
                tempStatuses.isNotEmpty ||
                tempTokens.isNotEmpty;

            final displayedTokens = tokenSearch.trim().isEmpty
                ? sortedRules
                : sortedRules
                    .where((r) => r.label
                        .toLowerCase()
                        .contains(tokenSearch.trim().toLowerCase()))
                    .toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xff0e172a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  top: BorderSide(color: Color(0xff4fa8ff), width: 1.5),
                  left: BorderSide(color: Color(0xff1e293b), width: 1),
                  right: BorderSide(color: Color(0xff1e293b), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 25,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle & Header
                  Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 8, left: 16, right: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xff1e2d4a), width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xffffe22d).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Color(0xffffe22d),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Filter Catalog',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            if (hasActiveFilters)
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    tempRanks.clear();
                                    tempPacks.clear();
                                    tempStatuses.clear();
                                    tempTokens.clear();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Reset all',
                                  style: TextStyle(
                                    color: Color(0xffff6b6b),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Sections
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // SECTION 1: RANK / LEVEL
                        _buildSectionHeader('RANK / LEVEL', Icons.military_tech_rounded),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final rFilter in _BestiaryRankFilter.values)
                              _buildHubOptionChip(
                                isSelected: rFilter == _BestiaryRankFilter.all
                                    ? tempRanks.isEmpty
                                    : tempRanks.contains(rFilter),
                                label: rFilter == _BestiaryRankFilter.all
                                    ? 'All ranks'
                                    : (rFilter == _BestiaryRankFilter.boss ? 'Boss' : ''),
                                leading: rFilter.rank != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.asset(
                                          rFilter.rank!.asset,
                                          width: 52,
                                          height: 32,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (rFilter == _BestiaryRankFilter.boss
                                        ? Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Color(0xffd51f2a),
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : null),
                                onTap: () => setSheetState(() {
                                  if (rFilter == _BestiaryRankFilter.all) {
                                    tempRanks.clear();
                                  } else {
                                    if (tempRanks.contains(rFilter)) {
                                      tempRanks.remove(rFilter);
                                    } else {
                                      tempRanks.add(rFilter);
                                    }
                                  }
                                }),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // SECTION 2: EXPANSION PACK
                        _buildSectionHeader('EXPANSION PACK', Icons.auto_awesome_motion_rounded),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final pFilter in _BestiaryPackFilter.values)
                              _buildHubOptionChip(
                                isSelected: pFilter == _BestiaryPackFilter.all
                                    ? tempPacks.isEmpty
                                    : tempPacks.contains(pFilter),
                                label: pFilter.label,
                                onTap: () => setSheetState(() {
                                  if (pFilter == _BestiaryPackFilter.all) {
                                    tempPacks.clear();
                                  } else {
                                    if (tempPacks.contains(pFilter)) {
                                      tempPacks.remove(pFilter);
                                    } else {
                                      tempPacks.add(pFilter);
                                    }
                                  }
                                }),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // SECTION 3: STATUS
                        _buildSectionHeader('CARD STATUS', Icons.verified_user_rounded),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final sFilter in _BestiaryStatusFilter.values)
                              _buildHubOptionChip(
                                isSelected: sFilter == _BestiaryStatusFilter.all
                                    ? tempStatuses.isEmpty
                                    : tempStatuses.contains(sFilter),
                                label: sFilter.label,
                                leading: Icon(
                                  switch (sFilter) {
                                    _BestiaryStatusFilter.all => Icons.all_inclusive,
                                    _BestiaryStatusFilter.defeated => Icons.emoji_events,
                                    _BestiaryStatusFilter.undefeated => Icons.hourglass_empty,
                                    _BestiaryStatusFilter.banned => Icons.block,
                                  },
                                  size: 15,
                                  color: (sFilter == _BestiaryStatusFilter.all
                                          ? tempStatuses.isEmpty
                                          : tempStatuses.contains(sFilter))
                                      ? const Color(0xffffe22d)
                                      : Colors.white70,
                                ),
                                onTap: () => setSheetState(() {
                                  if (sFilter == _BestiaryStatusFilter.all) {
                                    tempStatuses.clear();
                                  } else {
                                    if (tempStatuses.contains(sFilter)) {
                                      tempStatuses.remove(sFilter);
                                    } else {
                                      tempStatuses.add(sFilter);
                                    }
                                  }
                                }),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // SECTION 4: TOKENS
                        Row(
                          children: [
                            _buildSectionHeader('STATUS TOKENS', Icons.token_rounded),
                            const Spacer(),
                            if (tempTokens.isNotEmpty)
                              Text(
                                '${tempTokens.length} selected',
                                style: const TextStyle(
                                  color: Color(0xffffe22d),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Token Search Bar
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xff141e33),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            onChanged: (val) => setSheetState(() => tokenSearch = val),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Search token name...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: Colors.white38, size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Token Chips Wrap
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final rule in displayedTokens)
                              Builder(
                                builder: (ctx) {
                                  final isTokenSelected = tempTokens.contains(rule.label);
                                  final count = tokenCounts[rule.label] ?? 0;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      setSheetState(() {
                                        if (isTokenSelected) {
                                          tempTokens.remove(rule.label);
                                        } else {
                                          tempTokens.add(rule.label);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isTokenSelected
                                            ? const Color(0xffffe22d).withValues(alpha: 0.18)
                                            : const Color(0xff121929),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isTokenSelected
                                              ? const Color(0xffffe22d)
                                              : Colors.white24,
                                          width: isTokenSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: isTokenSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xffffe22d).withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (rule.imageAsset != null)
                                            Image.asset(
                                              rule.imageAsset!,
                                              width: 18,
                                              height: 18,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.token,
                                                size: 16,
                                                color: Colors.amberAccent,
                                              ),
                                            )
                                          else
                                            const Icon(Icons.token, size: 16, color: Colors.amberAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            rule.label,
                                            style: TextStyle(
                                              color: isTokenSelected ? const Color(0xffffe22d) : Colors.white,
                                              fontSize: 12,
                                              fontWeight: isTokenSelected ? FontWeight.w800 : FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isTokenSelected
                                                  ? const Color(0xffffe22d).withValues(alpha: 0.3)
                                                  : Colors.white10,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$count',
                                              style: TextStyle(
                                                color: isTokenSelected ? Colors.white : Colors.white60,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isTokenSelected) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check, size: 13, color: Color(0xffffe22d)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xff0b1220),
                      border: Border(
                        top: BorderSide(color: Color(0xff1e2d4a), width: 1.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (hasActiveFilters)
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xffff4d4d), width: 1.5),
                                backgroundColor: const Color(0xffff4d4d).withValues(alpha: 0.12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  tempRanks.clear();
                                  tempPacks.clear();
                                  tempStatuses.clear();
                                  tempTokens.clear();
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Color(0xffff6b6b),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (hasActiveFilters) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffffe22d),
                              foregroundColor: const Color(0xff0b1220),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 4,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedRanks
                                  ..clear()
                                  ..addAll(tempRanks);
                                _selectedPacks
                                  ..clear()
                                  ..addAll(tempPacks);
                                _selectedStatuses
                                  ..clear()
                                  ..addAll(tempStatuses);
                                _selectedTokenLabels
                                  ..clear()
                                  ..addAll(tempTokens);
                              });
                              Navigator.of(bottomSheetCtx).pop();
                            },
                            child: Text(
                              'Apply Filters ($previewCount)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProfiles = _allCatalogProfiles();
    final defeatedKeys = _computedDefeatedKeys();

    final filtered = allProfiles.where((profile) {
      if (_selectedRanks.isNotEmpty &&
          !_selectedRanks.any((r) => r.matches(profile))) {
        return false;
      }
      if (_selectedPacks.isNotEmpty &&
          !_selectedPacks.any((p) => p.matches(profile))) {
        return false;
      }
      final isDefeated = defeatedKeys.contains(profile.key);
      final isBanned = AppSettings.instance.disabledCommunityEnemyKeys.contains(profile.key);
      if (_selectedStatuses.isNotEmpty &&
          !_selectedStatuses.any((s) => switch (s) {
            _BestiaryStatusFilter.all => true,
            _BestiaryStatusFilter.defeated => isDefeated,
            _BestiaryStatusFilter.undefeated => !isDefeated,
            _BestiaryStatusFilter.banned => isBanned,
          })) {
        return false;
      }

      if (_selectedTokenLabels.isNotEmpty) {
        final rules = _profileTokenRules(profile);
        final profileTokenNames = rules.map((r) => r.label).toSet();
        final matchesAnyToken = _selectedTokenLabels.any(profileTokenNames.contains);
        if (!matchesAnyToken) return false;
      }

      return true;
    }).toList();

    final defeatedInFilter = filtered
        .where((p) => defeatedKeys.contains(p.key))
        .length;

    final activeFilterCount = _selectedRanks.length +
        _selectedPacks.length +
        _selectedStatuses.length +
        _selectedTokenLabels.length;

    return Scaffold(
      backgroundColor: const Color(0xff0b1220),
      appBar: AppBar(
        backgroundColor: const Color(0xff09152b),
        title: const Text(
          'Bestiary',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
        actions: [
          IconButton(
            tooltip: switch (_viewMode) {
              _BestiaryViewMode.grid3 => '3 cards per row (tap for 4)',
              _BestiaryViewMode.grid4 => '4 cards per row (tap for list)',
              _BestiaryViewMode.list => 'List mode (tap for 3 cards)',
            },
            onPressed: () => setState(() {
              _viewMode = switch (_viewMode) {
                _BestiaryViewMode.grid3 => _BestiaryViewMode.grid4,
                _BestiaryViewMode.grid4 => _BestiaryViewMode.list,
                _BestiaryViewMode.list => _BestiaryViewMode.grid3,
              };
            }),
            icon: Icon(
              switch (_viewMode) {
                _BestiaryViewMode.grid3 => Icons.grid_view_rounded,
                _BestiaryViewMode.grid4 => Icons.apps_rounded,
                _BestiaryViewMode.list => Icons.view_list_rounded,
              },
              color: const Color(0xffffe22d),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Yu-Gi-Oh! Deck Header Banner (Compact & Clean)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0c2348), Color(0xff071326)],
                ),
                border: Border(
                  top: BorderSide(color: Color(0xff4fa8ff), width: 1.2),
                  bottom: BorderSide(color: Color(0xff4fa8ff), width: 1.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xff8b4513),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0xffffc857),
                        width: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enemy Catalog: ${filtered.length} cards',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.isEmpty ? 0 : ((defeatedInFilter / filtered.length) * 100).round()}% defeated',
                    style: TextStyle(
                      color: defeatedInFilter > 0 ? const Color(0xff34d36d) : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Unified Filter Strip (Filters Button + Active Tags Inline & Wrap Below)
            Container(
              color: const Color(0xff070e1a),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Item 1: Main Filters Button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openFilterHub(allProfiles, defeatedKeys),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: activeFilterCount > 0
                            ? const Color(0xffffe22d).withValues(alpha: 0.18)
                            : const Color(0xff121d33),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeFilterCount > 0
                              ? const Color(0xffffe22d)
                              : Colors.white24,
                          width: activeFilterCount > 0 ? 1.5 : 1,
                        ),
                        boxShadow: activeFilterCount > 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xffffe22d).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: activeFilterCount > 0
                                ? const Color(0xffffe22d)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activeFilterCount > 0
                                ? 'Filters ($activeFilterCount)'
                                : 'Filters',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Active Tags: placed right next to Filters button on line 1, and wrap below when full!
                  for (final r in _selectedRanks)
                    _buildActiveChip(
                      label: r == _BestiaryRankFilter.boss ? 'Boss' : '',
                      leading: r.rank != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.asset(
                                r.rank!.asset,
                                width: 22,
                                height: 14,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (r == _BestiaryRankFilter.boss
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffd51f2a),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null),
                      onDeleted: () => setState(() => _selectedRanks.remove(r)),
                    ),
                  for (final p in _selectedPacks)
                    _buildActiveChip(
                      label: p.label,
                      onDeleted: () => setState(() => _selectedPacks.remove(p)),
                    ),
                  for (final s in _selectedStatuses)
                    _buildActiveChip(
                      label: s.label,
                      leading: Icon(
                        switch (s) {
                          _BestiaryStatusFilter.all => Icons.all_inclusive,
                          _BestiaryStatusFilter.defeated => Icons.emoji_events,
                          _BestiaryStatusFilter.undefeated => Icons.hourglass_empty,
                          _BestiaryStatusFilter.banned => Icons.block,
                        },
                        size: 13,
                        color: const Color(0xff4fa8ff),
                      ),
                      onDeleted: () => setState(() => _selectedStatuses.remove(s)),
                    ),
                  for (final tokenName in _selectedTokenLabels)
                    Builder(
                      builder: (context) {
                        final rule = TokenCatalogRepository.byLabel(tokenName);
                        return _buildActiveChip(
                          label: tokenName,
                          leading: rule?.imageAsset != null
                              ? Image.asset(
                                  rule!.imageAsset!,
                                  width: 15,
                                  height: 15,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.token,
                                    size: 14,
                                    color: Colors.amberAccent,
                                  ),
                                )
                              : const Icon(Icons.token, size: 14, color: Colors.amberAccent),
                          onDeleted: () => setState(() => _selectedTokenLabels.remove(tokenName)),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Content: Grid 3, Grid 4 or List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xff14284b), Color(0xff091122)],
                  ),
                ),
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No enemy cards match this filter.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : _viewMode == _BestiaryViewMode.list
                        ? ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final profile = filtered[index];
                              final isDefeated = defeatedKeys.contains(profile.key);
                              return _BestiaryListRow(
                                profile: profile,
                                defeated: isDefeated,
                                onToggleCommunity: () {
                                  if (mounted) setState(() {});
                                },
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BestiaryEnemyDetailPage(
                                        profile: profile,
                                        encountered: isDefeated,
                                      ),
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                },
                              );
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(6),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _viewMode == _BestiaryViewMode.grid3 ? 3 : 4,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              childAspectRatio: _viewMode == _BestiaryViewMode.grid3 ? 0.65 : 0.68,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final profile = filtered[index];
                              final isDefeated = defeatedKeys.contains(profile.key);
                              return _BestiaryYgoCard(
                                profile: profile,
                                encountered: isDefeated,
                                grayscaleMatrix: _grayscaleMatrix,
                                compact: _viewMode == _BestiaryViewMode.grid4,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BestiaryEnemyDetailPage(
                                        profile: profile,
                                        encountered: isDefeated,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestiaryListRow extends StatelessWidget {
  const _BestiaryListRow({
    required this.profile,
    required this.defeated,
    required this.onTap,
    this.onToggleCommunity,
  });

  final EnemyProfile profile;
  final bool defeated;
  final VoidCallback onTap;
  final VoidCallback? onToggleCommunity;

  @override
  Widget build(BuildContext context) {
    final tokens = _profileTokenRules(profile);
    final accent = profile.rank.color;
    final isBoss = profile.key == 'naraxus' ||
        profile.key == 'kaelen-voss' ||
        profile.rank == EnemyRank.naraxus;
    final previewAsset = switch (profile.key) {
      'naraxus' => 'assets/enemy_previews/naraxus.webp',
      'kaelen-voss' => 'assets/enemy_previews/kaelen-voss.webp',
      'viseer' => 'assets/enemy_previews/orange-viseer.webp',
      _ => profile.rank.asset,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xff141c2e),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: defeated ? accent.withValues(alpha: 0.6) : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 28,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent, width: 1),
                ),
                child: isBoss
                    ? Image.asset(
                        previewAsset,
                        fit: BoxFit.cover,
                        alignment: _bestiaryPreviewAlignment(profile.key),
                        errorBuilder: (_, __, ___) => Image.asset(
                          profile.rank.asset,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        profile.rank.asset,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        color: defeated ? Colors.white : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${profile.maxHealth} HP',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (tokens.isNotEmpty) ...[
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final rule in tokens) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: rule.imageAsset != null
                                          ? Image.asset(
                                              rule.imageAsset!,
                                              width: 16,
                                              height: 16,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.token,
                                                size: 14,
                                                color: Colors.amberAccent,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.token,
                                              size: 14,
                                              color: Colors.amberAccent,
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Text(
                            'No status tokens',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (profile.sourcePack == 'community') ...[
                Builder(
                  builder: (context) {
                    final isEnabled = AppSettings.instance
                        .isCommunityEnemyEnabled(profile.key);
                    return IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: isEnabled
                          ? 'Community card active in Rush (tap to ban)'
                          : 'Community card banned from Rush (tap to enable)',
                      icon: Icon(
                        isEnabled
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
                        color: isEnabled
                            ? const Color(0xff54e98a)
                            : Colors.redAccent,
                      ),
                      onPressed: () async {
                        await AppSettings.instance
                            .toggleCommunityEnemyEnabled(profile.key);
                        onToggleCommunity?.call();
                      },
                    );
                  },
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                defeated ? Icons.emoji_events_rounded : Icons.lock_outline,
                size: 20,
                color: defeated ? const Color(0xffffe22d) : Colors.white30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestiaryYgoCard extends StatelessWidget {
  const _BestiaryYgoCard({
    required this.profile,
    required this.encountered,
    required this.grayscaleMatrix,
    required this.compact,
    required this.onTap,
  });

  final EnemyProfile profile;
  final bool encountered;
  final List<double> grayscaleMatrix;
  final bool compact;
  final VoidCallback onTap;

  EnemyNode _toNode() {
    return EnemyNode(
      id: 0,
      label: profile.name,
      rank: profile.rank,
      maxHealth: profile.maxHealth,
      cp: profile.cp,
      attacks: profile.attacks,
      defense: profile.defense,
      defenseDice: profile.defenseDice,
      attackPlan: profile.attackPlan,
      cardAsset: profile.cardAsset,
      profileKey: profile.key,
      initialTokens: profile.initialTokens,
      rewardChests: profile.rewardChests,
      rewardRank: profile.rewardRank,
      rewardRanks: profile.rewardRanks,
      passives: profile.passives,
      defenseDisplayRows: profile.defenseDisplayRows,
      passiveDisplayRows: profile.passiveDisplayRows,
      defenseEffects: profile.defenseEffects,
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = _toNode();
    final frameColor = switch (profile.rank) {
      EnemyRank.green => const Color(0xff2e8b57),
      EnemyRank.blue => const Color(0xff2a6db0),
      EnemyRank.violet => const Color(0xff6b3fa0),
      EnemyRank.orange => const Color(0xffc86d25),
      EnemyRank.viseer || EnemyRank.naraxus => const Color(0xffa82028),
    };
    final accentColor = profile.rank.color;

    final cardBody = Container(
      padding: EdgeInsets.all(compact ? 3.5 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            frameColor,
            Color.lerp(frameColor, Colors.black, 0.45)!,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: encountered
              ? const Color(0xffd4af37)
              : Colors.white.withValues(alpha: 0.28),
          width: encountered ? 1.6 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Yu-Gi-Oh! Top Name Plate
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 3 : 4,
              vertical: compact ? 1.5 : 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 8.5 : 10,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // 2. Yu-Gi-Oh! Level Stars / Rank Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < _starsForRank(profile.rank); i++)
                Icon(
                  Icons.star,
                  size: compact ? 8.5 : 10,
                  color: accentColor,
                ),
            ],
          ),
          const SizedBox(height: 2),
          // 3. Yu-Gi-Oh! Square/Portrait Artwork Window
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: const Color(0xffb59b5c),
                  width: compact ? 1.2 : 1.6,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    node.previewAsset,
                    fit: BoxFit.cover,
                    alignment: _bestiaryPreviewAlignment(profile.key),
                  ),
                  if (!encountered)
                    Container(
                      color: Colors.black.withValues(alpha: 0.32),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.lock_outline,
                        size: compact ? 16 : 20,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          // 4. Yu-Gi-Oh! Bottom Effect / HP & Status Tokens Box
          Container(
            height: compact ? 20 : 23,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 3 : 4,
              vertical: 1.5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffe8dcc4),
              border: Border.all(
                color: const Color(0xff8c6d3b),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HP/${profile.maxHealth}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: compact ? 7.5 : 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final tokens = _profileTokenRules(profile);
                    if (tokens.isEmpty) {
                      return Text(
                        '--',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: compact ? 7.5 : 9,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final rule in tokens.take(compact ? 3 : 4)) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: rule.imageAsset != null
                                ? Image.asset(
                                    rule.imageAsset!,
                                    width: compact ? 12 : 14,
                                    height: compact ? 12 : 14,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.token,
                                      size: compact ? 10 : 12,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Icon(
                                    Icons.token,
                                    size: compact ? 10 : 12,
                                    color: Colors.black87,
                                  ),
                          ),
                        ],
                        if (tokens.length > (compact ? 3 : 4))
                          Text(
                            '+',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: compact ? 7 : 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: encountered
          ? cardBody
          : Opacity(
              opacity: 0.62,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(grayscaleMatrix),
                child: cardBody,
              ),
            ),
    );
  }

  static int _starsForRank(EnemyRank rank) {
    return switch (rank) {
      EnemyRank.green => 1,
      EnemyRank.blue => 2,
      EnemyRank.violet => 3,
      EnemyRank.orange => 4,
      EnemyRank.viseer => 4,
      EnemyRank.naraxus => 5,
    };
  }
}

class BestiaryEnemyDetailPage extends StatefulWidget {
  const BestiaryEnemyDetailPage({
    required this.profile,
    required this.encountered,
    super.key,
  });

  final EnemyProfile profile;
  final bool encountered;

  @override
  State<BestiaryEnemyDetailPage> createState() =>
      _BestiaryEnemyDetailPageState();
}

class _BestiaryEnemyDetailPageState extends State<BestiaryEnemyDetailPage> {
  late final EnemyNode _enemy = _createNode();

  EnemyNode _createNode() {
    return EnemyNode(
      id: 0,
      label: widget.profile.name,
      rank: widget.profile.rank,
      maxHealth: widget.profile.maxHealth,
      cp: widget.profile.cp,
      attacks: widget.profile.attacks,
      defense: widget.profile.defense,
      defenseDice: widget.profile.defenseDice,
      attackPlan: widget.profile.attackPlan,
      cardAsset: widget.profile.cardAsset,
      profileKey: widget.profile.key,
      initialTokens: widget.profile.initialTokens,
      rewardChests: widget.profile.rewardChests,
      rewardRank: widget.profile.rewardRank,
      rewardRanks: widget.profile.rewardRanks,
      passives: widget.profile.passives,
      defenseDisplayRows: widget.profile.defenseDisplayRows,
      passiveDisplayRows: widget.profile.passiveDisplayRows,
      defenseEffects: widget.profile.defenseEffects,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final accent = profile.rank.color;
    final isBossWithoutChest =
        profile.rank == EnemyRank.naraxus || profile.rank == EnemyRank.viseer;
    final isDefeated =
        AppSettings.instance.isEnemyDefeated(profile.key) ||
        widget.encountered;

    return Scaffold(
      backgroundColor: const Color(0xff0d111a),
      appBar: AppBar(
        backgroundColor: const Color(0xff09152b),
        title: Text(
          profile.name,
          style: TextStyle(color: accent, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: isDefeated
                ? 'Marked as defeated (tap to toggle)'
                : 'Not defeated yet (tap to mark as defeated)',
            onPressed: () async {
              await AppSettings.instance.toggleEnemyDefeated(profile.key);
              if (mounted) {
                setState(() {});
              }
            },
            icon: Icon(
              isDefeated ? Icons.emoji_events_rounded : Icons.lock_outline,
              color: isDefeated ? const Color(0xffffe22d) : Colors.white54,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // 0. Expansion Pack Origin & Rush Inclusion Toggle
            if (profile.sourcePack == 'community') ...[
              Builder(
                builder: (context) {
                  final isEnabled = AppSettings.instance
                      .isCommunityEnemyEnabled(profile.key);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xff122b1c)
                          : const Color(0xff2d1217),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEnabled
                            ? const Color(0xff54e98a)
                            : Colors.redAccent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isEnabled
                                  ? const Color(0xff54e98a)
                                  : Colors.redAccent)
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEnabled
                              ? Icons.verified_user_rounded
                              : Icons.block_rounded,
                          color: isEnabled
                              ? const Color(0xff54e98a)
                              : Colors.redAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEnabled
                                    ? 'Community Card Active in Rush'
                                    : 'Community Card Banned from Rush',
                                style: TextStyle(
                                  color: isEnabled
                                      ? const Color(0xff54e98a)
                                      : Colors.redAccent,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEnabled
                                    ? 'Eligible to appear in Minion Rush when Community pack is enabled.'
                                    : 'Excluded from Minion Rush runs even if Community pack is on.',
                                style: TextStyle(
                                  color: isEnabled
                                      ? Colors.white70
                                      : Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: const Color(0xff54e98a),
                          onChanged: (val) async {
                            await AppSettings.instance
                                .toggleCommunityEnemyEnabled(profile.key);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        switch (profile.sourcePack) {
                          'promo' => 'assets/packs/pack_promo.webp',
                          'santa' => 'assets/packs/pack_santa.webp',
                          _ => 'assets/packs/pack_dta.webp',
                        },
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      switch (profile.sourcePack) {
                        'promo' => 'Promo pack DTA (Official)',
                        'santa' => "Santa's workshop Promo pack DTA (Official)",
                        _ => 'DTA Minions (Core Game)',
                      },
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Pack toggle in Rush mode',
                      style: TextStyle(color: Colors.white38, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
            // 1. Large Yu-Gi-Oh! / Hero Card Showcase
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _enemy.previewAsset,
                          fit: BoxFit.cover,
                          alignment: _bestiaryPreviewAlignment(profile.key),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.90),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: accent),
                                  ),
                                  child: Text(
                                    profile.rank.label,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                HpBadge(value: profile.maxHealth),
                                if (profile.cp > 0) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: _PcTriangleBadge(value: profile.cp),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (!isBossWithoutChest)
                                  RewardChestBadge(
                                    rank: profile.rewardRank ?? profile.rank,
                                    count: profile.rewardChests,
                                    ranks: profile.rewardRanks,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (profile.initialTokens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Start tokens:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final token in profile.initialTokens)
                      TokenBadge(label: token, color: accent),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // 2. Full Attack, Passive & Defense Rules Panel (All Expanded)
            EnemyRulesPanel(
              enemy: _enemy,
              phase: CombatPhase.hero,
              aiMode: false,
              developerMode: false,
              onDetails: () {},
              onAbandon: () {},
              onExport: () {},
              onRestartCombat: (_) {},
              showUndo: false,
              onUndo: () {},
            ),
          ],
        ),
      ),
    );
  }
}


class BossBattleSelectionPage extends StatelessWidget {
  const BossBattleSelectionPage({
    required this.onStartBossWithHero,
    super.key,
  });

  final ValueChanged<String> onStartBossWithHero;

  @override
  Widget build(BuildContext context) {
    final naxarus = EnemyProfileRepository.byKey('naraxus') ?? naraxusProfile;
    final kaelenVoss =
        EnemyProfileRepository.byKey('kaelen-voss') ?? kaelenVossProfile;

    return Scaffold(
      backgroundColor: const Color(0xff0b090e),
      appBar: AppBar(
        backgroundColor: const Color(0xff14101a),
        title: const Text(
          'Boss Battle',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            // Monthly Boss Event banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff3a1d5c).withValues(alpha: 0.85),
                    const Color(0xff1a1226).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xffffb300).withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffffb300).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffffb300),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xffffd54f),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY BOSS EVENT',
                          style: TextStyle(
                            color: Color(0xffffd54f),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'One new custom monster is created every month!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CHOOSE YOUR OPPONENT (2 BOSSES)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            // Option 1: Naxarus (Official)
            _BossChoiceCard(
              profile: naxarus,
              subtitle: 'Official Final Boss • Relentless 1-Die Brutality',
              isUnofficial: false,
              isBossOfTheMonth: false,
              accentColor: const Color(0xffd51f2a),
              imageAlignment: const Alignment(0, -0.34),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (detailContext) => BossBattleDetailPage(
                      profile: naxarus,
                      isUnofficial: false,
                      isBossOfTheMonth: false,
                      onChooseHeroAndFight: () {
                        onStartBossWithHero(naxarus.key);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            // Option 2: Kaelen Voss (Unofficial + Boss of the Month)
            _BossChoiceCard(
              profile: kaelenVoss,
              subtitle: 'Boss of the Month • Exclusive Monthly Challenger',
              isUnofficial: true,
              isBossOfTheMonth: true,
              accentColor: const Color(0xff9b58ff),
              imageAlignment: const Alignment(0, -0.48),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (detailContext) => BossBattleDetailPage(
                      profile: kaelenVoss,
                      isUnofficial: true,
                      isBossOfTheMonth: true,
                      onChooseHeroAndFight: () {
                        onStartBossWithHero(kaelenVoss.key);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BossChoiceCard extends StatelessWidget {
  const _BossChoiceCard({
    required this.profile,
    required this.subtitle,
    required this.isUnofficial,
    required this.isBossOfTheMonth,
    required this.accentColor,
    required this.imageAlignment,
    required this.onTap,
  });

  final EnemyProfile profile;
  final String subtitle;
  final bool isUnofficial;
  final bool isBossOfTheMonth;
  final Color accentColor;
  final Alignment imageAlignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final node = _bestiaryNodeFromProfile(profile);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff171321),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isBossOfTheMonth
                  ? const Color(0xffffb300)
                  : accentColor.withValues(alpha: 0.85),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unofficial Banner Ribbon at top if unofficial
              if (isUnofficial)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xffd6512a),
                        Color(0xff9b23ea),
                      ],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'UNOFFICIAL BOSS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.stars_rounded,
                        color: Color(0xffffe22d),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'BOSS OF THE MONTH',
                        style: TextStyle(
                          color: Color(0xffffe22d),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  color: const Color(0xff8c141d),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'OFFICIAL BOSS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              // Artwork + Overlay
              SizedBox(
                height: 275,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      node.previewAsset,
                      fit: BoxFit.cover,
                      alignment: imageAlignment,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.90),
                          ],
                          stops: const [0.55, 0.78, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffb71c1c),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white38,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${profile.maxHealth} HP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom action footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                color: const Color(0xff1f192c),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to view Boss details, Attack & Defense',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'INSPECT',
                          style: TextStyle(
                            color: Color(0xffffe22d),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xffffe22d),
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BossBattleDetailPage extends StatefulWidget {
  const BossBattleDetailPage({
    required this.profile,
    required this.isUnofficial,
    required this.isBossOfTheMonth,
    required this.onChooseHeroAndFight,
    super.key,
  });

  final EnemyProfile profile;
  final bool isUnofficial;
  final bool isBossOfTheMonth;
  final VoidCallback onChooseHeroAndFight;

  @override
  State<BossBattleDetailPage> createState() => _BossBattleDetailPageState();
}

class _BossBattleDetailPageState extends State<BossBattleDetailPage> {
  late final EnemyNode _enemy;

  @override
  void initState() {
    super.initState();
    _enemy = _bestiaryNodeFromProfile(widget.profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      backgroundColor: const Color(0xff0b090e),
      appBar: AppBar(
        backgroundColor: const Color(0xff14101a),
        title: Text(
          profile.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xff14101a),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: widget.onChooseHeroAndFight,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffd51f2a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: Color(0xffffe22d),
                    width: 1.5,
                  ),
                ),
              ),
              icon: const Icon(Icons.local_fire_department, size: 24),
              label: Text(
                'CHOOSE HERO & FIGHT ${profile.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            if (widget.isUnofficial || widget.isBossOfTheMonth) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff4a1942),
                      Color(0xff231438),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xffffb300),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xffffd54f),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'UNOFFICIAL • BOSS OF THE MONTH',
                          style: TextStyle(
                            color: Color(0xffffd54f),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This Boss is an original creation for the Boss of the Month event (one custom Boss created each month).',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Large Boss Artwork Card
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff1b1523),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isUnofficial
                          ? const Color(0xffffb300)
                          : const Color(0xffd51f2a),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 0.78,
                        child: Image.asset(
                          _enemy.previewAsset,
                          fit: BoxFit.cover,
                          alignment: _bestiaryPreviewAlignment(profile.key),
                        ),
                      ),
                      if (widget.isUnofficial)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffd6512a),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.amberAccent,
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'UNOFFICIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.94),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${profile.maxHealth} HP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.shield,
                                color: Colors.lightBlueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${profile.defenseDice}D DEF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.isUnofficial
                                      ? 'BOSS OF THE MONTH'
                                      : 'OFFICIAL BOSS',
                                  style: const TextStyle(
                                    color: Color(0xffffe22d),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Full Attack, Passive & Defense Rules Panel
            EnemyRulesPanel(
              enemy: _enemy,
              phase: CombatPhase.hero,
              aiMode: false,
              developerMode: false,
              onDetails: () {},
              onAbandon: () {},
              onExport: () {},
              onRestartCombat: (_) {},
              showUndo: false,
              onUndo: () {},
            ),
          ],
        ),
      ),
    );
  }
}


EnemyNode _bestiaryNodeFromProfile(EnemyProfile profile) {
  return EnemyNode(
    id: 0,
    label: profile.name,
    rank: profile.rank,
    maxHealth: profile.maxHealth,
    cp: profile.cp,
    attacks: profile.attacks,
    defense: profile.defense,
    defenseDice: profile.defenseDice,
    attackPlan: profile.attackPlan,
    cardAsset: profile.cardAsset,
    profileKey: profile.key,
    initialTokens: profile.initialTokens,
    rewardChests: profile.rewardChests,
    rewardRank: profile.rewardRank,
    rewardRanks: profile.rewardRanks,
    passives: profile.passives,
    defenseDisplayRows: profile.defenseDisplayRows,
    passiveDisplayRows: profile.passiveDisplayRows,
    defenseEffects: profile.defenseEffects,
  );
}

Alignment _bestiaryPreviewAlignment(String profileKey) {
  return switch (profileKey) {
    'naraxus' => const Alignment(0, -0.34),
    'kaelen-voss' => const Alignment(0, -0.75),
    _ => Alignment.topCenter,
  };
}
