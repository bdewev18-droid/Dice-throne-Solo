part of '../main.dart';

class HeroChoicePage extends StatefulWidget {
  const HeroChoicePage({required this.onNext, super.key});

  final ValueChanged<HeroType> onNext;

  @override
  State<HeroChoicePage> createState() => _HeroChoicePageState();
}

class _HeroChoicePageState extends State<HeroChoicePage> {
  HeroType? _selectedHero;
  final Set<HeroSegment> _selectedSegments = {};
  final Set<int> _selectedComplexities = {1, 2, 3, 4, 5, 6};
  final TextEditingController _searchController = TextEditingController();
  bool _randomHeroLocked = false;
  bool _myHeroesOnly = false;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_handleAppSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_handleAppSettingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleAppSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final heroes =
        HeroType.values
            .where((hero) => hero.label.toLowerCase().contains(query))
            .where(
              (hero) =>
                  _selectedSegments.isEmpty ||
                  hero.segments.any(_selectedSegments.contains),
            )
            .where((hero) => _selectedComplexities.contains(hero.complexity))
            .where(
              (hero) => !_myHeroesOnly || AppSettings.instance.ownsHero(hero),
            )
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    if (_selectedHero != null && !heroes.contains(_selectedHero)) {
      _selectedHero = null;
      _randomHeroLocked = false;
    }
    final randomHeroes = heroes
        .where((hero) => AppSettings.instance.ownsHero(hero))
        .toList();
    final selectedHero = _selectedHero;
    final selectedOwned =
        selectedHero != null && AppSettings.instance.ownsHero(selectedHero);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your hero')),
      bottomNavigationBar: selectedOwned
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.86),
                  border: const Border(top: BorderSide(color: Colors.white24)),
                ),
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () => widget.onNext(selectedHero),
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedHero.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Launch campaign',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search hero',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ComplexityFilterBar(
                    selectedLevels: _selectedComplexities,
                    onToggle: (level) => setState(() {
                      if (_selectedComplexities.contains(level)) {
                        if (_selectedComplexities.length > 1) {
                          _selectedComplexities.remove(level);
                        }
                      } else {
                        _selectedComplexities.add(level);
                      }
                      _randomHeroLocked = false;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            HeroSegmentFilters(
              selectedSegments: _selectedSegments,
              myHeroesOnly: _myHeroesOnly,
              onMyHeroesChanged: (value) => setState(() {
                _myHeroesOnly = value;
                _randomHeroLocked = false;
              }),
              onChanged: (segment, selected) {
                setState(() {
                  if (segment == null) {
                    _selectedSegments.clear();
                  } else if (selected) {
                    _selectedSegments
                      ..clear()
                      ..add(segment);
                  } else {
                    _selectedSegments.remove(segment);
                  }
                  _randomHeroLocked = false;
                });
              },
            ),
            const SizedBox(height: 14),
            if (heroes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No hero found',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: heroes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return RandomHeroCard(
                      heroes: randomHeroes,
                      selectedHero: _randomHeroLocked ? _selectedHero : null,
                      onTap: () => _selectRandomHero(randomHeroes),
                      onStart: randomHeroes.isEmpty
                          ? null
                          : selectedHero == null
                          ? null
                          : () => widget.onNext(selectedHero),
                    );
                  }
                  final hero = heroes[index - 1];
                  final owned = AppSettings.instance.ownsHero(hero);
                  return HeroCard(
                    hero: hero,
                    selected: _selectedHero == hero,
                    owned: owned,
                    onTap: () => setState(() {
                      _selectedHero = hero;
                      _randomHeroLocked = false;
                    }),
                    onDoubleTap: owned ? () => widget.onNext(hero) : null,
                    onStart: owned ? () => widget.onNext(hero) : null,
                    onToggleOwned: () {
                      unawaited(AppSettings.instance.toggleHeroOwnership(hero));
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _selectRandomHero(List<HeroType> heroes) {
    if (heroes.isEmpty) {
      return;
    }
    setState(() {
      _selectedHero = _pickRandomHero(heroes);
      _randomHeroLocked = true;
    });
  }

  HeroType _pickRandomHero(List<HeroType> heroes) {
    final pool = heroes.length == 1
        ? heroes
        : heroes.where((hero) => hero != _selectedHero).toList();
    return pool[Random().nextInt(pool.length)];
  }
}

class HeroSegmentFilters extends StatelessWidget {
  const HeroSegmentFilters({
    required this.selectedSegments,
    required this.myHeroesOnly,
    required this.onMyHeroesChanged,
    required this.onChanged,
    super.key,
  });

  final Set<HeroSegment> selectedSegments;
  final bool myHeroesOnly;
  final ValueChanged<bool> onMyHeroesChanged;
  final void Function(HeroSegment? segment, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('My heroes'),
              SizedBox(width: 5),
              Icon(Icons.bookmark, size: 16),
            ],
          ),
          selected: myHeroesOnly,
          onSelected: onMyHeroesChanged,
        ),
        FilterChip(
          label: const Text('All'),
          selected: selectedSegments.isEmpty,
          onSelected: (_) => onChanged(null, true),
        ),
        ...const [
          HeroSegment.season1,
          HeroSegment.season2,
          HeroSegment.avengers,
          HeroSegment.xmen,
          HeroSegment.outcast,
          HeroSegment.other,
          HeroSegment.santaKrampus,
        ].map(
          (segment) => FilterChip(
            label: Text(segment.label),
            selected: selectedSegments.contains(segment),
            onSelected: (selected) => onChanged(segment, selected),
          ),
        ),
      ],
    );
  }
}

class _ComplexityFilterBar extends StatelessWidget {
  const _ComplexityFilterBar({
    required this.selectedLevels,
    required this.onToggle,
  });

  final Set<int> selectedLevels;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var level = 1; level <= 6; level++)
            _ComplexityFilterDie(
              level: level,
              selected: selectedLevels.contains(level),
              onTap: () => onToggle(level),
            ),
        ],
      ),
    );
  }
}

class _ComplexityFilterDie extends StatelessWidget {
  const _ComplexityFilterDie({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 32,
        height: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: selected ? 1 : 0.38,
              child: _ComplexityDieCrop(level: level, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplexityDieCrop extends StatelessWidget {
  const _ComplexityDieCrop({required this.level, required this.size});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clampedLevel = level.clamp(1, 6).toInt();
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/complexity/$clampedLevel-niv.webp',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white12,
            alignment: Alignment.center,
            child: Text(
              clampedLevel.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class RandomHeroCard extends StatefulWidget {
  const RandomHeroCard({
    required this.heroes,
    required this.selectedHero,
    required this.onTap,
    required this.onStart,
    super.key,
  });

  final List<HeroType> heroes;
  final HeroType? selectedHero;
  final VoidCallback onTap;
  final VoidCallback? onStart;

  @override
  State<RandomHeroCard> createState() => _RandomHeroCardState();
}

class _RandomHeroCardState extends State<RandomHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedHero = widget.selectedHero;
    final hasPool = widget.heroes.isNotEmpty;
    return InkWell(
      onTap: hasPool ? widget.onTap : null,
      onDoubleTap: widget.onStart,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedHero == null ? Colors.white30 : selectedHero.color,
            width: selectedHero == null ? 1 : 4,
          ),
          color: const Color(0xff121212),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!hasPool)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Add heroes to your collection first',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                )
              else if (selectedHero == null)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final heroIndex =
                        (_controller.value * widget.heroes.length).floor() %
                        widget.heroes.length;
                    final hero = widget.heroes[heroIndex];
                    return _RandomHeroFullArt(hero: hero);
                  },
                )
              else
                _RandomHeroFullArt(hero: selectedHero),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedHero != null)
                        Text(
                          selectedHero.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedHero.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const Text(
                        'Random hero',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

class _RandomHeroFullArt extends StatelessWidget {
  const _RandomHeroFullArt({required this.hero});

  final HeroType hero;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: hero.imageScale,
      child: Image.asset(
        hero.asset,
        fit: BoxFit.cover,
        alignment: hero.imageAlignment,
      ),
    );
  }
}

class _HeroComplexityBadge extends StatelessWidget {
  const _HeroComplexityBadge({required this.hero});

  final HeroType hero;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      hero.complexityAsset,
      height: 24,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        'Complexity ${hero.complexity}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
    return Semantics(label: 'Complexity ${hero.complexity}', child: image);
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.hero,
    required this.selected,
    required this.owned,
    required this.onTap,
    required this.onDoubleTap,
    required this.onStart,
    required this.onToggleOwned,
    super.key,
  });

  final HeroType hero;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onStart;
  final VoidCallback onToggleOwned;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? hero.color : Colors.white24,
            width: selected ? 4 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: owned
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                child: Transform.scale(
                  scale: hero.imageScale,
                  child: Image.asset(
                    hero.asset,
                    fit: BoxFit.cover,
                    alignment: hero.imageAlignment,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 58,
                child: Center(child: _HeroComplexityBadge(hero: hero)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: owned ? 'In my collection' : 'Not in my collection',
                  onPressed: onToggleOwned,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.58),
                    foregroundColor: owned ? Colors.white : Colors.white54,
                    side: BorderSide(
                      color: owned ? Colors.white : Colors.white24,
                    ),
                  ),
                  icon: Icon(owned ? Icons.bookmark : Icons.bookmark_border),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hero.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          color: selected ? hero.color : Colors.white,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

class HeroAvatar extends StatelessWidget {
  const HeroAvatar({required this.hero, this.size = 42, super.key});

  final HeroType hero;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hero.color,
        border: Border.all(color: hero.color.withValues(alpha: 0.9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Transform.scale(
        scale: hero.imageScale * 1.35,
        child: Image.asset(
          hero.asset,
          fit: BoxFit.cover,
          alignment: hero.imageAlignment,
        ),
      ),
    );
  }
}

class SurvivalSetupPage extends StatefulWidget {
  const SurvivalSetupPage({
    required this.hero,
    required this.onStart,
    super.key,
  });

  final HeroType hero;
  final ValueChanged<SurvivalConfig> onStart;

  @override
  State<SurvivalSetupPage> createState() => _SurvivalSetupPageState();
}

class _SurvivalSetupPageState extends State<SurvivalSetupPage> {
  SurvivalMode _mode = SurvivalMode.mediumFixed;
  bool _randomRoute = false;
  bool _expertFreeMode = false;
  final Map<EnemyRank, int> _freeCounts = {
    EnemyRank.green: 1,
    EnemyRank.blue: 0,
    EnemyRank.violet: 0,
    EnemyRank.orange: 2,
  };

  int get _freeTotal =>
      _freeCounts.values.fold(0, (total, value) => total + value);

  int get _freeScore => _freeCounts.entries.fold(
    0,
    (total, entry) => total + entry.key.points * entry.value,
  );

  bool get _freeValid =>
      _freeTotal == 13 &&
      (_freeCounts[EnemyRank.green] ?? 0) >= 1 &&
      (_freeCounts[EnemyRank.orange] ?? 0) >= 2 &&
      _freeScore >= 20;

  Map<EnemyRank, int> get _displayCounts =>
      _mode == SurvivalMode.free ? _freeCounts : _rankCountsForMode(_mode);

  int get _targetScore => _mode == SurvivalMode.free
      ? _freeScore
      : (_randomRoute ? _randomModeFor(_mode) : _mode).defaultTarget;

  List<EnemyRank> get _setupRanksToDisplay => [
    EnemyRank.green,
    EnemyRank.blue,
    EnemyRank.violet,
    EnemyRank.orange,
    if (_mode == SurvivalMode.hardFixed) EnemyRank.viseer,
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveMode = _mode == SurvivalMode.free
        ? SurvivalMode.free
        : _randomRoute
        ? _randomModeFor(_mode)
        : _mode;
    final config = effectiveMode == SurvivalMode.free
        ? SurvivalConfig(
            mode: SurvivalMode.free,
            targetScore: _freeScore,
            freeCounts: Map<EnemyRank, int>.from(_freeCounts),
          )
        : SurvivalConfig(
            mode: effectiveMode,
            targetScore: effectiveMode.defaultTarget,
          );
    final canStart = effectiveMode != SurvivalMode.free || _freeValid;

    return Scaffold(
      appBar: AppBar(title: const Text('Survival setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
          children: [
            InfoCard(
              child: Row(
                children: [
                  HeroAvatar(hero: widget.hero, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.hero.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SurvivalMode>(
              segments: const [
                ButtonSegment(value: SurvivalMode.free, label: Text('Free')),
                ButtonSegment(
                  value: SurvivalMode.mediumFixed,
                  label: Text('Medium'),
                ),
                ButtonSegment(
                  value: SurvivalMode.hardFixed,
                  label: Text('Difficult'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _randomRoute = _mode == SurvivalMode.free;
                });
              },
            ),
            const SizedBox(height: 12),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$_targetScore pts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff54e98a),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Random route'),
                    value: _mode == SurvivalMode.free || _randomRoute,
                    onChanged: _mode == SurvivalMode.free
                        ? null
                        : (value) => setState(() => _randomRoute = value),
                  ),
                  if (!(_mode != SurvivalMode.free && _randomRoute)) ...[
                    const SizedBox(height: 8),
                    ..._setupRanksToDisplay.map(
                      (rank) => _buildRankCounter(
                        rank,
                        valueOverride: _displayCounts[rank] ?? 0,
                        enabled: _mode == SurvivalMode.free,
                      ),
                    ),
                  ],
                  if (_mode == SurvivalMode.free) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Enemies: $_freeTotal / 13',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Enemies left to add: ${max(0, 13 - _freeTotal)}',
                      style: const TextStyle(color: Color(0xff54e98a)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Expert mode'),
                      subtitle: const Text('Allow Level 4 changes'),
                      value: _expertFreeMode,
                      onChanged: (value) =>
                          setState(() => _expertFreeMode = value),
                    ),
                    if (!_freeValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Adjust the enemy count before starting.',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ImageActionButton(
              label: 'Start run',
              icon: Icons.play_arrow,
              onPressed: canStart ? () => widget.onStart(config) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCounter(
    EnemyRank rank, {
    int? valueOverride,
    bool enabled = true,
  }) {
    final value = valueOverride ?? _freeCounts[rank] ?? 0;
    final min = rank == EnemyRank.green
        ? 1
        : rank == EnemyRank.orange
        ? 2
        : 0;
    final orangeLocked =
        enabled && rank == EnemyRank.orange && !_expertFreeMode;
    final canEdit = enabled && !orangeLocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: AssetImage(rank.asset),
                fit: BoxFit.cover,
                colorFilter: rank == EnemyRank.viseer
                    ? ColorFilter.mode(
                        rank.color.withValues(alpha: 0.6),
                        BlendMode.multiply,
                      )
                    : null,
              ),
              border: Border.all(color: rank.color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('${rank.label} (${rank.points} pts)')),
          RoundIconButton(
            icon: Icons.remove,
            tooltip: 'Remove',
            onPressed: !canEdit || value <= min
                ? null
                : () => setState(() => _freeCounts[rank] = value - 1),
          ),
          SizedBox(
            width: 42,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          RoundIconButton(
            icon: Icons.add,
            tooltip: 'Add',
            onPressed: !canEdit || _freeTotal >= 13
                ? null
                : () => setState(() => _freeCounts[rank] = value + 1),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = const Color(0xff54e98a),
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        side: BorderSide(color: onPressed == null ? Colors.white12 : color),
      ),
      icon: Icon(icon),
    );
  }
}
