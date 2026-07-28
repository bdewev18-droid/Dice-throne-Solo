part of '../main.dart';

class HeroChoicePage extends StatefulWidget {
  const HeroChoicePage({required this.onNext, super.key});

  final ValueChanged<HeroType> onNext;

  @override
  State<HeroChoicePage> createState() => _HeroChoicePageState();
}

class _HeroChoicePageState extends State<HeroChoicePage> {
  HeroType _selectedHero = HeroType.barbare;
  final Set<HeroSegment> _selectedSegments = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _holdTimer;
  HeroType? _holdingHero;
  double _holdProgress = 0;
  bool _holdingRandomHero = false;
  static const Duration _holdToValidateDuration = Duration(seconds: 3);

  @override
  void dispose() {
    _holdTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    if (!heroes.contains(_selectedHero) && heroes.isNotEmpty) {
      _selectedHero = heroes.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your hero')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                labelText: 'Search hero',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            HeroSegmentFilters(
              selectedSegments: _selectedSegments,
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
                      holdProgress: _holdingRandomHero ? _holdProgress : 0,
                      onTap: () => _selectRandomHero(heroes),
                      onHoldStart: () => _startRandomHeroHold(heroes),
                      onHoldEnd: _cancelHeroHold,
                    );
                  }
                  final hero = heroes[index - 1];
                  return HeroCard(
                    hero: hero,
                    selected: _selectedHero == hero,
                    holdProgress: _holdingHero == hero ? _holdProgress : 0,
                    onTap: () => setState(() => _selectedHero = hero),
                    onHoldStart: () => _startHeroHold(hero),
                    onHoldEnd: _cancelHeroHold,
                  );
                },
              ),
            const SizedBox(height: 18),
            ImageActionButton(
              label: 'Next',
              icon: Icons.arrow_forward,
              onPressed: heroes.isEmpty
                  ? null
                  : () => widget.onNext(_selectedHero),
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
    setState(() => _selectedHero = _pickRandomHero(heroes));
  }

  void _startRandomHeroHold(List<HeroType> heroes) {
    if (heroes.isEmpty) {
      return;
    }
    _startHeroHold(_pickRandomHero(heroes), random: true);
  }

  HeroType _pickRandomHero(List<HeroType> heroes) {
    final pool = heroes.length == 1
        ? heroes
        : heroes.where((hero) => hero != _selectedHero).toList();
    return pool[Random().nextInt(pool.length)];
  }

  void _startHeroHold(HeroType hero, {bool random = false}) {
    _holdTimer?.cancel();
    setState(() {
      _selectedHero = hero;
      _holdingHero = hero;
      _holdingRandomHero = random;
      _holdProgress = 0;
    });

    final startedAt = DateTime.now();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      final elapsed = DateTime.now().difference(startedAt);
      final progress =
          elapsed.inMilliseconds / _holdToValidateDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        if (!mounted || _holdingHero != hero) {
          return;
        }
        setState(() {
          _holdProgress = 1;
          _holdingHero = null;
          _holdingRandomHero = false;
        });
        widget.onNext(hero);
        return;
      }
      if (mounted) {
        setState(() => _holdProgress = progress.clamp(0, 1));
      }
    });
  }

  void _cancelHeroHold() {
    if (_holdProgress >= 1) {
      return;
    }
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _holdingHero = null;
        _holdingRandomHero = false;
        _holdProgress = 0;
      });
    }
  }
}

class HeroSegmentFilters extends StatelessWidget {
  const HeroSegmentFilters({
    required this.selectedSegments,
    required this.onChanged,
    super.key,
  });

  final Set<HeroSegment> selectedSegments;
  final void Function(HeroSegment? segment, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selectedSegments.isEmpty,
          onSelected: (_) => onChanged(null, true),
        ),
        ...HeroSegment.values.map(
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

class RandomHeroCard extends StatefulWidget {
  const RandomHeroCard({
    required this.holdProgress,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
    super.key,
  });

  final double holdProgress;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

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
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onTapDown: (_) => widget.onHoldStart(),
      onTapUp: (_) => widget.onHoldEnd(),
      onTapCancel: widget.onHoldEnd,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff171717), Color(0xff37204e)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final angle = _controller.value * pi * 2;
                  return Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 108,
                  height: 148,
                  child: Stack(
                    children: const [
                      _RandomStackedCard(offset: Offset(-16, 10), angle: -0.16),
                      _RandomStackedCard(offset: Offset(16, 10), angle: 0.16),
                      _RandomStackedCard(offset: Offset.zero, angle: 0),
                    ],
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
              if (widget.holdProgress > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: widget.holdProgress,
                        backgroundColor: Colors.black54,
                        color: heroAccent,
                      ),
                    ),
                  ),
                ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Random hero',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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

class _RandomStackedCard extends StatelessWidget {
  const _RandomStackedCard({required this.offset, required this.angle});

  final Offset offset;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: heroAccent, width: 2),
              color: const Color(0xff262626),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.shuffle, size: 52, color: heroAccent),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.hero,
    required this.selected,
    required this.holdProgress,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
    super.key,
  });

  final HeroType hero;
  final bool selected;
  final double holdProgress;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
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
              Transform.scale(
                scale: hero.imageScale,
                child: Image.asset(
                  hero.asset,
                  fit: BoxFit.cover,
                  alignment: hero.imageAlignment,
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
              if (holdProgress > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 3,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: holdProgress,
                        backgroundColor: Colors.black54,
                        color: hero.color,
                      ),
                    ),
                  ),
                ),
              if (holdProgress > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: hero.color),
                    ),
                    child: const Text(
                      'Hold to confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    hero.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
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
          padding: const EdgeInsets.all(16),
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
