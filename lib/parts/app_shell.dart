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
  AuthSession _auth = AuthSession.unknown;
  StreamSubscription<AuthSessionEvent>? _authSub;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_handleSettingsChanged);
    _loadActiveAdventure();
    _initAuthAndHistory();
    // Écoute les changements de session Supabase : la session restaurée
    // après un redirect OAuth web (ou un refresh silencieux) est poussée
    // ici automatiquement, sans rechargement de page ni intervention.
    _authSub = SupabaseService.instance.sessionStream.listen((event) {
      if (!mounted) {
        return;
      }
      final wasSignedIn = _auth.isSignedIn;
      final nowSignedIn = event.session.isSignedIn;
      setState(() => _auth = event.session);
      // Recharge l'historique uniquement lors d'une vraie transition de
      // session (connexion/déconnexion), pas sur chaque refresh token.
      if (event.transition && nowSignedIn && !wasSignedIn) {
        _loadHistory();
      } else if (event.transition && !nowSignedIn && wasSignedIn) {
        setState(_history.clear);
      }
    });
  }

  void _handleSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_handleSettingsChanged);
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _initAuthAndHistory() async {
    final session = SupabaseService.instance.currentSession();
    setState(() => _auth = session);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await HistoryRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history
        ..clear()
        ..addAll(records);
    });
  }

  Future<void> _handleAddRecord(GameRecord record) async {
    if (record.hero == HeroType.benjamin) {
      return; // Do not save history for test accounts
    }
    final saved = await HistoryRepository.instance.add(record);
    if (!mounted) {
      return;
    }
    setState(() {
      _history.removeWhere((r) => r.id == saved.id && saved.id != null);
      _history.insert(0, saved);
    });
  }

  Future<void> _handleDeleteRecord(GameRecord record) async {
    await HistoryRepository.instance.delete(record);
    if (!mounted) {
      return;
    }
    setState(() => _history.remove(record));
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _auth = const AuthSession(status: AuthStatus.signingIn));
    try {
      final session = await SupabaseService.instance.signInWithGoogle();
      if (!mounted) {
        return;
      }
      setState(() => _auth = session);
      if (session.isSignedIn) {
        await _loadHistory();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _auth = AuthSession.signedOut);
      _showAuthError(context, e);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _auth = const AuthSession(status: AuthStatus.signingIn));
    try {
      final session = await SupabaseService.instance.signInAnonymously();
      if (!mounted) {
        return;
      }
      setState(() => _auth = session);
      if (session.isSignedIn) {
        await _loadHistory();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _auth = AuthSession.signedOut);
      _showAuthError(context, e);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.instance.signOut();
    setState(() {
      _auth = AuthSession.signedOut;
      _history.clear();
    });
    await _loadHistory();
  }

  void _showAuthError(BuildContext context, Object error) {
    // AlertDialog via la navigatorKey globale : garantie visible même si
    // le contexte local n'a plus de Scaffold (cas du retour muet après
    // picker Google). Le SnackBar pouvait être raté de justesse.
    final navContext = appNavigatorKey.currentContext ?? context;
    showDialog<void>(
      context: navContext,
      builder: (_) => AlertDialog(
        title: const Text('Connexion impossible'),
        content: SingleChildScrollView(child: Text('$error')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(navContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      home: Builder(builder: (context) => _buildHomePage(context)),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    if (!_storageReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return HomePage(
      activeAdventure: _activeAdventure,
      auth: _auth,
      historyCount: _history.length,
      onHistory: () => _openHistory(context),
      onBestiary: () => _openBestiary(context),
      onSurvival: () => _openHeroChoice(context),
      onResume: () {
        final adventure = _activeAdventure;
        if (adventure != null) {
          Navigator.of(context).push(
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
                  _returnToHome();
                },
                onAbandon: () => _abandonAdventure(adventure),
                onOpenHistory: () => _openHistory(
                  appNavigatorKey.currentContext ?? context,
                  initialDifficulty: adventure.config.mode.difficulty,
                ),
                onChangeHero: () => _openHeroChoice(context),
                onReplay: () {
                  final next = AdventureState(
                    hero: adventure.hero,
                    config: adventure.config,
                  );
                  _activeAdventure = next;
                  _saveActiveAdventure();
                  _replaceWithMap(
                    context,
                    next,
                    adventure.hero,
                    adventure.config,
                  );
                },
              ),
            ),
          );
        }
      },
      onStopCampaign: _stopActiveCampaign,
      onNaraxus: () => _openBossBattle(context),
      onSignInGoogle: _signInWithGoogle,
      onSignInAnonymous: _signInAnonymously,
      onSignOut: _signOut,
    );
  }

  void _returnToHome() {
    final context = appNavigatorKey.currentContext;
    if (context != null) {
      _AppBootstrap.restartApp(context);
    }
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
          onAddRecord: (record) => _handleAddRecord(record),
          onDeleteRecord: (record) => _handleDeleteRecord(record),
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

  void _openBestiary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BestiaryPage(
          historyRecords: _history,
        ),
      ),
    );
  }

  void _openBossBattle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BossBattleSelectionPage(
          onStartBossWithHero: (bossKey) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HeroChoicePage(
                  onNext: (hero) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => NaraxusBattlePage(
                          hero: hero,
                          historyRecords: _history,
                          onRecord: (record) => _handleAddRecord(record),
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
                  onRecord: (record) => _handleAddRecord(record),
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
            _returnToHome();
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
    final record = GameRecord(
      hero: adventure.hero,
      date: DateTime.now(),
      score: adventure.score,
      mode: adventure.config.mode,
      healthRemaining: adventure.health,
      enemiesDefeated: adventure.defeatedEnemies.length,
      duration: adventure.elapsed,
      isVictory: adventure.victory,
    );
    _handleAddRecord(record);
    setState(() {
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
    _returnToHome();
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
    required this.auth,
    required this.onHistory,
    required this.onBestiary,
    required this.onSurvival,
    required this.onResume,
    required this.onStopCampaign,
    required this.onNaraxus,
    required this.onSignInGoogle,
    required this.onSignInAnonymous,
    required this.onSignOut,
    this.historyCount = 0,
    super.key,
  });

  final AdventureState? activeAdventure;
  final AuthSession auth;
  final int historyCount;
  final VoidCallback onHistory;
  final VoidCallback onBestiary;
  final VoidCallback onSurvival;
  final VoidCallback onResume;
  final VoidCallback onStopCampaign;
  final VoidCallback onNaraxus;
  final VoidCallback onSignInGoogle;
  final VoidCallback onSignInAnonymous;
  final VoidCallback onSignOut;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showActions = false;
  static const String _minionRushImage = 'assets/enemy_previews/violet-002.webp';
  static const Alignment _minionRushAlignment = Alignment(0.0, -0.75);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showActions = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final validatedMonsters = EnemyProfileRepository.validatedCatalogCount;
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
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: AccountChip(
                      auth: widget.auth,
                      onSignInGoogle: widget.onSignInGoogle,
                      onSignInAnonymous: widget.onSignInAnonymous,
                      onSignOut: widget.onSignOut,
                    ),
                  ),
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
                            if (widget.activeAdventure != null) ...[
                              ActiveCampaignHomeCard(
                                adventure: widget.activeAdventure!,
                                onResume: widget.onResume,
                                onStop: widget.onStopCampaign,
                              ),
                              const SizedBox(height: 14),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: WedgeActionButton(
                                    title: 'MINION',
                                    titleAccent: 'RUSH',
                                    titleAccentColor: const Color(0xffc084fc),
                                    subtitle: '3 Game Modes',
                                    subtitleColor: const Color(0xffffe22d),
                                    imageAsset: _minionRushImage,
                                    imageAlignment: _minionRushAlignment,
                                    borderColor: const Color(0xff9b58ff),
                                    onPressed: widget.onSurvival,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BossBattleActionButton(
                                    onPressed: widget.onNaraxus,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: WedgeActionButton(
                                    title: 'HISTORY',
                                    subtitle:
                                        '${widget.historyCount} ${widget.historyCount <= 1 ? "Game" : "Games"}',
                                    subtitleColor: const Color(0xffffe22d),
                                    imageAsset: 'assets/podium.jpg',
                                    imageAlignment: const Alignment(0.0, -0.35),
                                    borderColor: const Color(0xffffd700),
                                    onPressed: widget.onHistory,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: WedgeActionButton(
                                    title: 'BESTIARY',
                                    subtitle: '$validatedMonsters Monsters',
                                    subtitleColor: const Color(0xffffe22d),
                                    imageAsset:
                                        'assets/enemy_previews/naxarus_head.png',
                                    imageAlignment:
                                        const Alignment(0.4, 0.0),
                                    borderColor: const Color(0xffd51f2a),
                                    onPressed: widget.onBestiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  VersionPill(
                    label:
                        '$appVersionLabel${AppSettings.instance.developerMode ? ' - Dev mode' : ''}',
                    isDev: AppSettings.instance.developerMode,
                    onTap: () async {
                      await AppSettings.instance.setDeveloperMode(
                        !AppSettings.instance.developerMode,
                      );
                    },
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/map-visual-2.webp',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 40,
                  bottom: 40,
                  width: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: adventure.hero.color, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: adventure.hero.color.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Transform.scale(
                      scale: adventure.hero.imageScale,
                      child: Image.asset(
                        adventure.hero.asset,
                        fit: BoxFit.cover,
                        alignment: adventure.hero.imageAlignment,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        adventure.hero.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${adventure.score}/${adventure.targetScore} pts',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${adventure.config.label} - ${_formatDateTime(adventure.startedAt)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onResume,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: adventure.hero.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: onStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              side: const BorderSide(color: Colors.redAccent, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.warning_rounded, size: 18),
            label: const Text(
              'Abandonner la quête',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class VersionPill extends StatelessWidget {
  const VersionPill({
    required this.label,
    this.isDev = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool isDev;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDev ? Colors.orangeAccent : Colors.white24,
            width: isDev ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDev ? Colors.orangeAccent : Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
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
    this.badgeLabel,
    this.color,
    this.showIcon = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? badgeLabel;
  final Color? color;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                height: 76,
                decoration: BoxDecoration(
                  color: color ?? Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Opacity(
                  opacity: onPressed == null ? 0.42 : 1,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showIcon) ...[
                            Icon(icon, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (badgeLabel != null && onPressed == null)
            Positioned(
              left: -18,
              top: 10,
              child: Transform.rotate(
                angle: -0.55,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff7a33cc).withValues(alpha: 0.92),
                    border: Border.all(color: const Color(0xffd0a5ff), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeLabel!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BossBattleActionButton extends StatelessWidget {
  const BossBattleActionButton({
    required this.onPressed,
    this.bossName = 'KAELEN VOSS',
    this.bossImage = 'assets/enemy_previews/kaelen-voss.webp',
    this.bossImageAlignment = const Alignment(0.0, -0.85),
    this.bossImageOffset = const Offset(35.0, 0.0),
    this.badgeLabel = 'BOSS OF THE MONTH',
    super.key,
  });

  final VoidCallback? onPressed;
  final String bossName;
  final String bossImage;
  final Alignment bossImageAlignment;
  final Offset bossImageOffset;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Right-side boss wedge artwork
                    Positioned.fill(
                      child: ClipPath(
                        clipper: const _BossWedgeClipper(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.translate(
                              offset: bossImageOffset,
                              child: Image.asset(
                                bossImage,
                                fit: BoxFit.cover,
                                alignment: bossImageAlignment,
                              ),
                            ),
                            // Dark gradient overlay for text readability
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                  stops: const [0.45, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Gold diagonal divider line
                    Positioned.fill(
                      child: CustomPaint(
                        painter: const _BossWedgeBorderPainter(),
                      ),
                    ),
                    // Left-side "BOSS BATTLE" text
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      right: 76,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'BOSS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'BATTLE',
                                style: TextStyle(
                                  color: Color(0xffffe22d),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom-right boss name
                    Positioned(
                      right: 6,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xffffb300).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          bossName,
                          style: const TextStyle(
                            color: Color(0xffffe22d),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Top-right compact patch / tag
        Positioned(
          top: -8,
          right: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff4a1942),
                    Color(0xff231032),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xffffb300),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 10,
                    color: Color(0xffffe22d),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Color(0xffffe22d),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
}

class _BossWedgeClipper extends CustomClipper<Path> {
  const _BossWedgeClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.48, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.32, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BossWedgeBorderPainter extends CustomPainter {
  const _BossWedgeBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffffb300).withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.48, 0)
      ..lineTo(size.width * 0.32, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => false;
}

class WedgeActionButton extends StatelessWidget {
  const WedgeActionButton({
    required this.title,
    required this.imageAsset,
    required this.onPressed,
    this.titleColor = Colors.white,
    this.titleAccent,
    this.titleAccentColor,
    this.subtitle,
    this.subtitleColor = const Color(0xffffe22d),
    this.imageAlignment = Alignment.center,
    this.borderColor = const Color(0xffffb300),
    this.badgeLabel,
    this.topRatio = 0.58,
    this.bottomRatio = 0.44,
    this.imageOffsetLeft = 45.0,
    this.imageScale = 1.0,
    super.key,
  });

  final String title;
  final String? titleAccent;
  final Color titleColor;
  final Color? titleAccentColor;
  final String? subtitle;
  final Color subtitleColor;
  final String imageAsset;
  final Alignment imageAlignment;
  final Color borderColor;
  final VoidCallback? onPressed;
  final String? badgeLabel;
  final double topRatio;
  final double bottomRatio;
  final double imageOffsetLeft;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Opacity(
                  opacity: onPressed == null ? 0.45 : 1.0,
                  child: Stack(
                    children: [
                      // Wedge artwork on right
                      Positioned.fill(
                        child: ClipPath(
                          clipper: _WedgeClipper(
                            topRatio: topRatio,
                            bottomRatio: bottomRatio,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final effectiveLeft = max(
                                imageOffsetLeft,
                                constraints.maxWidth * bottomRatio - 20,
                              );
                              return Stack(
                                children: [
                                  Positioned(
                                    left: effectiveLeft,
                                    top: 0,
                                    bottom: 0,
                                    right: -15,
                                    child: ClipRect(
                                      child: Transform.scale(
                                        scale: imageScale,
                                        alignment: imageAlignment,
                                        child: Image.asset(
                                          imageAsset,
                                          fit: BoxFit.cover,
                                          alignment: imageAlignment,
                                          errorBuilder: (_, __, ___) => ColoredBox(
                                            color: Colors.black45,
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.white24,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Cinematic dark gradient overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.05),
                                            Colors.black.withValues(alpha: 0.65),
                                          ],
                                          stops: const [0.55, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // Diagonal divider line
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WedgeBorderPainter(
                            color: borderColor,
                            topRatio: topRatio,
                            bottomRatio: bottomRatio,
                          ),
                        ),
                      ),
                      // Left text column
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final effectiveRight = constraints.maxWidth > 250
                                ? constraints.maxWidth * (1.0 - topRatio) + 12.0
                                : 56.0;
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 14,
                                right: effectiveRight,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (titleAccent != null) ...[
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        titleAccent!,
                                        style: TextStyle(
                                          color: titleAccentColor ?? const Color(0xffffe22d),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle!,
                                        style: TextStyle(
                                          color: subtitleColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (badgeLabel != null && onPressed == null)
          Positioned(
            left: -18,
            top: 10,
            child: Transform.rotate(
              angle: -0.55,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff7a33cc).withValues(alpha: 0.92),
                  border: Border.all(color: const Color(0xffd0a5ff), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  badgeLabel!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WedgeClipper extends CustomClipper<Path> {
  const _WedgeClipper({this.topRatio = 0.58, this.bottomRatio = 0.44});

  final double topRatio;
  final double bottomRatio;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * topRatio, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * bottomRatio, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WedgeClipper oldClipper) =>
      oldClipper.topRatio != topRatio || oldClipper.bottomRatio != bottomRatio;
}

class _WedgeBorderPainter extends CustomPainter {
  const _WedgeBorderPainter({
    required this.color,
    this.topRatio = 0.58,
    this.bottomRatio = 0.44,
  });

  final Color color;
  final double topRatio;
  final double bottomRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * topRatio, 0)
      ..lineTo(size.width * bottomRatio, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WedgeBorderPainter oldPainter) =>
      oldPainter.color != color ||
      oldPainter.topRatio != topRatio ||
      oldPainter.bottomRatio != bottomRatio;
}

/// Chip de compte : connecté (email + déconnexion) ou invité
/// (boutons Google / Anonyme). Compact pour ne pas encombrer l'accueil.
class AccountChip extends StatelessWidget {
  const AccountChip({
    required this.auth,
    required this.onSignInGoogle,
    required this.onSignInAnonymous,
    required this.onSignOut,
    super.key,
  });

  final AuthSession auth;
  final VoidCallback onSignInGoogle;
  final VoidCallback onSignInAnonymous;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final isSigningIn = auth.status == AuthStatus.signingIn;
    if (isSigningIn) {
      return _pill(
        child: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (auth.isSignedIn &&
        !auth.isAnonymous &&
        (auth.email?.isNotEmpty ?? false)) {
      return _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                auth.email!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _signOutButton(),
          ],
        ),
      );
    }
    return _pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          const Text(
            'Invité',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.login,
            label: 'Google',
            onTap: onSignInGoogle,
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return InkWell(
      onTap: onSignOut,
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(Icons.logout, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}
