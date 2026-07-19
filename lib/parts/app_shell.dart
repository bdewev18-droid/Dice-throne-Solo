part of '../main.dart';

class DiceThroneSurvieApp extends StatefulWidget {
  const DiceThroneSurvieApp({super.key});

  @override
  State<DiceThroneSurvieApp> createState() => _DiceThroneSurvieAppState();
}

class _DiceThroneSurvieAppState extends State<DiceThroneSurvieApp> {
  final List<GameRecord> _history = [];
  final _store = ActiveAdventureStore();
  AdventureState? _activeAdventure;
  bool _storageReady = false;

  @override
  void initState() {
    super.initState();
    _loadActiveAdventure();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      title: 'D.T Solo Quest',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd6512a),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff121212),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) {
          return content;
        }
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ClipRect(child: content),
            ),
          ),
        );
      },
      home: Builder(
        builder: (context) {
          if (!_storageReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomePage(
            activeAdventure: _activeAdventure,
            onHistory: () => _openHistory(context),
            onSurvival: () => _openHeroChoice(context),
            onResume: () {
              final adventure = _activeAdventure;
              if (adventure != null) {
                _replaceWithMap(
                  context,
                  adventure,
                  adventure.hero,
                  adventure.config,
                );
              }
            },
            onStopCampaign: _stopActiveCampaign,
            onNaraxus: () => _openNaraxusHeroChoice(context),
          );
        },
      ),
    );
  }

  Future<void> _loadActiveAdventure() async {
    final raw = await _store.read();
    AdventureState? restored;
    if (raw != null) {
      try {
        restored = AdventureState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        if (restored.finished) {
          restored = null;
          await _store.clear();
        }
      } catch (_) {
        await _store.clear();
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAdventure = restored;
      _storageReady = true;
    });
  }

  Future<void> _saveActiveAdventure() async {
    final adventure = _activeAdventure;
    if (adventure == null || adventure.finished) {
      await _store.clear();
      return;
    }
    await _store.write(jsonEncode(adventure.toJson()));
  }

  Future<void> _clearActiveAdventure() async {
    _activeAdventure = null;
    await _store.clear();
    if (mounted) {
      setState(() {});
    }
  }

  void _openHistory(BuildContext context, {RunDifficulty? initialDifficulty}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          records: _history,
          initialDifficulty: initialDifficulty,
          onAddRecord: (record) => setState(() => _history.insert(0, record)),
          onDeleteRecord: (record) => setState(() => _history.remove(record)),
        ),
      ),
    );
  }

  void _openHeroChoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          onNext: (hero) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SurvivalSetupPage(
                  hero: hero,
                  onStart: (config) {
                    final adventure = AdventureState(
                      hero: hero,
                      config: config,
                    );
                    _activeAdventure = adventure;
                    _saveActiveAdventure();
                    _replaceWithMap(context, adventure, hero, config);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openNaraxusHeroChoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroChoicePage(
          onNext: (hero) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => NaraxusBattlePage(
                  hero: hero,
                  historyRecords: _history,
                  onRecord: (record) =>
                      setState(() => _history.insert(0, record)),
                  onOpenHistory: () => _openHistory(
                    appNavigatorKey.currentContext ?? context,
                    initialDifficulty: RunDifficulty.naraxus,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _replaceWithMap(
    BuildContext context,
    AdventureState adventure,
    HeroType hero,
    SurvivalConfig config,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MapPage(
          adventure: adventure,
          historyRecords: _history,
          onRecordScore: _recordAdventure,
          onChanged: () {
            _activeAdventure = adventure;
            _saveActiveAdventure();
          },
          onPauseExit: () {
            _activeAdventure = adventure;
            _saveActiveAdventure();
            appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
          onAbandon: () => _abandonAdventure(adventure),
          onOpenHistory: () => _openHistory(
            appNavigatorKey.currentContext ?? context,
            initialDifficulty: adventure.config.mode.difficulty,
          ),
          onChangeHero: () => _openHeroChoice(context),
          onReplay: () {
            final next = AdventureState(hero: hero, config: config);
            _activeAdventure = next;
            _saveActiveAdventure();
            _replaceWithMap(context, next, hero, config);
          },
        ),
      ),
    );
  }

  void _recordAdventure(AdventureState adventure) {
    if (adventure.recorded) {
      return;
    }
    adventure.recorded = true;
    setState(() {
      _history.insert(
        0,
        GameRecord(
          hero: adventure.hero,
          date: DateTime.now(),
          score: adventure.score,
          mode: adventure.config.mode,
          healthRemaining: adventure.health,
          enemiesDefeated: adventure.defeatedEnemies.length,
          duration: adventure.elapsed,
        ),
      );
      if (identical(_activeAdventure, adventure)) {
        _activeAdventure = null;
        _store.clear();
      }
    });
  }

  Future<void> _abandonAdventure(AdventureState adventure) async {
    adventure.finished = true;
    _recordAdventure(adventure);
    await _store.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      if (identical(_activeAdventure, adventure)) {
        _activeAdventure = null;
      }
    });
    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _stopActiveCampaign() async {
    final adventure = _activeAdventure;
    if (adventure != null) {
      _recordAdventure(adventure);
    }
    await _clearActiveAdventure();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.activeAdventure,
    required this.onHistory,
    required this.onSurvival,
    required this.onResume,
    required this.onStopCampaign,
    required this.onNaraxus,
    super.key,
  });

  final AdventureState? activeAdventure;
  final VoidCallback onHistory;
  final VoidCallback onSurvival;
  final VoidCallback onResume;
  final VoidCallback onStopCampaign;
  final VoidCallback onNaraxus;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showActions = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: MediaQuery.paddingOf(context).top + 18,
            child: Image.asset(
              'assets/home_background_v4.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 18,
            child: const ColoredBox(color: Colors.black),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 650),
                      opacity: _showActions ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_showActions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ImageActionButton(
                              label: 'History',
                              icon: Icons.history,
                              onPressed: widget.onHistory,
                            ),
                            const SizedBox(height: 20),
                            if (widget.activeAdventure == null)
                              ImageActionButton(
                                label: 'Minion rush',
                                icon: Icons.shield,
                                onPressed: widget.onSurvival,
                              )
                            else
                              ActiveCampaignHomeCard(
                                adventure: widget.activeAdventure!,
                                onResume: widget.onResume,
                                onStop: widget.onStopCampaign,
                              ),
                            const SizedBox(height: 20),
                            ImageActionButton(
                              label: 'Naraxus Battle',
                              icon: Icons.local_fire_department,
                              onPressed: widget.onNaraxus,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const VersionPill(label: appVersionLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveCampaignHomeCard extends StatelessWidget {
  const ActiveCampaignHomeCard({
    required this.adventure,
    required this.onResume,
    required this.onStop,
    super.key,
  });

  final AdventureState adventure;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onResume,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff8f43ff),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume current run'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HeroAvatar(hero: adventure.hero, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${adventure.hero.label} - ${adventure.score}/${adventure.targetScore} pts\n'
                  '${adventure.config.label} - ${_formatDateTime(adventure.startedAt)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onStop,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffd85a21),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.stop_circle),
            label: const Text('Stop campaign'),
          ),
        ],
      ),
    );
  }
}

class VersionPill extends StatelessWidget {
  const VersionPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class ImageActionButton extends StatelessWidget {
  const ImageActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: AssetImage('assets/button_background.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Opacity(
            opacity: onPressed == null ? 0.48 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

