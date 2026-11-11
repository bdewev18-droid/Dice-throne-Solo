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
    await AppSettings.instance.syncFromSupabase(historyRecords: records);
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
        builder: (_) => BestiaryPage(historyRecords: _history),
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
                          bossKey: bossKey,
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
  static const String _minionRushImage =
      'assets/enemy_previews/violet-002.webp';
  static const Alignment _minionRushAlignment = Alignment(0.0, -0.75);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showActions = true);
        AppUpdateService.checkAndPrompt(context);
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
                                    imageAlignment: const Alignment(0.4, 0.0),
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
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: VersionPill(
                            label:
                                '$appVersionLabel${AppSettings.instance.developerMode ? ' - Dev mode' : ''}',
                            isDev: AppSettings.instance.developerMode,
                          ),
                        ),
                        _PhysicalGameRequirementFooter(
                          onTap: () => _showPhysicalRequirementsDialog(context),
                        ),
                      ],
                    ),
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

class _PhysicalGameRequirementFooter extends StatelessWidget {
  const _PhysicalGameRequirementFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xffffd700).withValues(alpha: 0.7),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Physical game required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'More information ↗',
              style: TextStyle(
                color: Color(0xffffe22d),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildOfficialLink({required String label, required String url}) {
  return InkWell(
    onTap: () async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: Color(0xff1d4ed8),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff1d4ed8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xff1d4ed8),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showHowToPlayVideoDialog(BuildContext context) {
  const videoUrl = 'https://www.youtube.com/watch?v=js_cZrv6cZY';
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: const Color(0xff121929),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffe53935), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xffc4302b),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Play Video Guide',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Learn Dice Throne Adventures in 10 minutes',
                          style: TextStyle(fontSize: 11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Thumbnail preview container
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await launchUrl(
                    Uri.parse(videoUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black,
                        child: Image.network(
                          'https://img.youtube.com/vi/js_cZrv6cZY/hqdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xff1a233a),
                            child: const Center(
                              child: Icon(
                                Icons.video_library_rounded,
                                size: 54,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 200,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffc4302b),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This tutorial covers the physical setup, hero turn sequence, minion roll phase, loot rewards, and token mechanics.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffc4302b),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Watch on YouTube',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                ),
                onPressed: () async {
                  await launchUrl(
                    Uri.parse(videoUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showPhysicalRequirementsDialog(BuildContext context) {
  const dialogBgColor = Color(0xffe2e7e5);
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xff2a2e39),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xffffe22d),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Physical Games Required',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff1e232a),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'DTA Solo Quest is an unofficial companion application. To play, you must physically own Dice Throne board game products.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff4b5563),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Section 1: Boss Battles
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'boss'),
                        title: '1. Dice Throne 2-Hero Battle Box',
                        description:
                            'To play Boss Battles, you must own at least one official physical Dice Throne 2-Hero Box of your choice (e.g. Barbarian v. Moon Elf, Gunslinger v. Samurai, Treant v. Ninja). You will need your physical hero board, hero combat dice, and hero deck to fight.',
                        actionLink: _buildOfficialLink(
                          label:
                              'More info on official website: dicethrone.com/heroes',
                          url: 'https://dicethrone.com/heroes/',
                        ),
                        imageWidget: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: dialogBgColor,
                            height: 130,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/requirement/popin4.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Section 2: Minion Rush Mode
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'minion'),
                        title: '2. Dice Throne Adventures (DTA) Core Box',
                        description:
                            'To play Minion Rush, in addition to a 2-Hero Battle Box, you must own the physical Dice Throne Adventures (DTA) box. It contains all physical minion card decks, level brackets, and adventure components.',
                        actionLink: _buildOfficialLink(
                          label:
                              'More info on official expansions: shop.dicethrone.com',
                          url:
                              'https://shop.dicethrone.com/collections/expansions',
                        ),
                        imageWidget: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: dialogBgColor,
                                  height: 120,
                                  child: Image.asset(
                                    'assets/packs/pack_dta.webp',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: dialogBgColor,
                                  height: 120,
                                  child: Image.asset(
                                    'assets/requirement/popin3.webp',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Section 3: Loot & Tokens
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'loot'),
                        title: '3. Loot Cards & Status Effect Tokens',
                        description:
                            'During a run, you must physically add loot cards into your hero deck upon winning rewards (Common, Rare, Epic, Legendary). You also physically track or place status tokens using the DTA token tray.',
                        imageWidget: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: dialogBgColor,
                                height: 90,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/requirement/popin.webp',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: dialogBgColor,
                                height: 120,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/requirement/popin2.webp',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Section 4: How to Play (Video Tutorial)
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'video'),
                        title: '4. How to Play (Video Tutorial)',
                        description:
                            'Discover or review the complete gameplay flow of Dice Throne Adventures with this video guide. It explains physical card setup, turn phases, combat rolls, and token management.',
                        actionLink: _buildOfficialLink(
                          label: 'Watch Video Tutorial on YouTube',
                          url: 'https://www.youtube.com/watch?v=js_cZrv6cZY',
                        ),
                        imageWidget: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => showHowToPlayVideoDialog(ctx),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  color: Colors.black,
                                  child: Image.network(
                                    'https://img.youtube.com/vi/js_cZrv6cZY/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xff1e293b),
                                      child: const Center(
                                        child: Icon(
                                          Icons.smart_display_rounded,
                                          color: Colors.white38,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 140,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffe53935),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Color(0xff2a2e39)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildHpButtonBadge({required String type}) {
  if (type == 'boss') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff181920),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffd51f2a), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffd51f2a).withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'BOSS ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            'BATTLE',
            style: TextStyle(
              color: Color(0xffffe22d),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  } else if (type == 'minion') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff181920),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xff9b58ff), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff9b58ff).withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'MINION ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            'RUSH',
            style: TextStyle(
              color: Color(0xffc084fc),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  } else if (type == 'video') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff181920),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffe53935), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffe53935).withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.play_circle_fill, size: 14, color: Color(0xffef5350)),
          SizedBox(width: 4),
          Text(
            'HOW TO PLAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff181920),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xff2d6a4f), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2d6a4f).withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'LOOT & TOKENS',
        style: TextStyle(
          color: Color(0xff52b788),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

Widget _buildRequirementCard({
  required Widget badge,
  required String title,
  required String description,
  required Widget imageWidget,
  Widget? actionLink,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffcbd5d1), width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        badge,
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: Color(0xff1e232a),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xff4b5563),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        imageWidget,
        if (actionLink != null) ...[const SizedBox(height: 10), actionLink],
      ],
    ),
  );
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

class VersionPill extends StatefulWidget {
  const VersionPill({
    required this.label,
    this.isDev = false,
    this.requiredTaps = 11,
    this.onTap,
    super.key,
  });

  final String label;
  final bool isDev;
  final int requiredTaps;
  final VoidCallback? onTap;

  @override
  State<VersionPill> createState() => _VersionPillState();
}

class _VersionPillState extends State<VersionPill> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTap() async {
    if (widget.onTap != null && widget.requiredTaps <= 1) {
      widget.onTap!();
      return;
    }
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!).inMilliseconds > 1500) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    final target = widget.requiredTaps;
    if (_tapCount >= target) {
      _tapCount = 0;
      final newMode = !AppSettings.instance.developerMode;
      await AppSettings.instance.setDeveloperMode(newMode);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newMode
                  ? 'Developer mode activated!'
                  : 'Developer mode deactivated.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: newMode ? Colors.orange : Colors.grey[800],
          ),
        );
      }
    } else if (_tapCount >= target - 3 && mounted) {
      final remaining = target - _tapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$remaining tap${remaining > 1 ? 's' : ''} left for developer mode',
          ),
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDev ? Colors.orangeAccent : Colors.white24,
            width: widget.isDev ? 1.5 : 1,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.isDev ? Colors.orangeAccent : Colors.white,
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
                    border: Border.all(
                      color: const Color(0xffd0a5ff),
                      width: 1,
                    ),
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
    this.bossSubtitle = 'New Monster Monthly',
    this.bossImage = 'assets/enemy_previews/ourokhor.jpg',
    this.bossImageAlignment = const Alignment(0.0, -0.65),
    this.imageOffsetLeft = 60.0,
    this.bossImageScale = 1.05,
    this.topRatio = 0.58,
    this.bottomRatio = 0.44,
    this.borderColor = const Color(0xff9b58ff),
    super.key,
  });

  final VoidCallback? onPressed;
  final String bossSubtitle;
  final String bossImage;
  final Alignment bossImageAlignment;
  final double imageOffsetLeft;
  final double bossImageScale;
  final double topRatio;
  final double bottomRatio;
  final Color borderColor;

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
                    // Right-side boss wedge artwork (shifted ~0.5 cm right)
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _BossWedgeClipper(
                          topRatio: topRatio,
                          bottomRatio: bottomRatio,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final effectiveLeft = max(
                              imageOffsetLeft,
                              constraints.maxWidth * bottomRatio - 15,
                            );
                            return Stack(
                              children: [
                                Positioned(
                                  left: effectiveLeft,
                                  top: 0,
                                  bottom: 0,
                                  right: -10,
                                  child: ClipRect(
                                    child: Transform.scale(
                                      scale: bossImageScale,
                                      alignment: bossImageAlignment,
                                      child: Image.asset(
                                        bossImage,
                                        fit: BoxFit.cover,
                                        alignment: bossImageAlignment,
                                      ),
                                    ),
                                  ),
                                ),
                                // Dark gradient overlay for artwork depth & contrast
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
                    // Violet diagonal divider line
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BossWedgeBorderPainter(
                          topRatio: topRatio,
                          bottomRatio: bottomRatio,
                          color: borderColor,
                        ),
                      ),
                    ),
                    // Left-side 3-line text block (matching Minion Rush styling)
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
                                  const Text(
                                    'BOSS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Text(
                                    'BATTLE',
                                    style: TextStyle(
                                      color: Color(0xffc084fc), // Purple / violet
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    bossSubtitle,
                                    style: const TextStyle(
                                      color: Color(0xffffe22d), // Gold/yellow like '3 Game Modes'
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
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
      ],
    );
  }
}

class _BossWedgeClipper extends CustomClipper<Path> {
  final double topRatio;
  final double bottomRatio;
  const _BossWedgeClipper({this.topRatio = 0.58, this.bottomRatio = 0.44});

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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BossWedgeBorderPainter extends CustomPainter {
  final double topRatio;
  final double bottomRatio;
  final Color color;
  const _BossWedgeBorderPainter({
    this.topRatio = 0.58,
    this.bottomRatio = 0.44,
    this.color = const Color(0xff9b58ff),
  });

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
  bool shouldRepaint(covariant CustomPainter oldPainter) => false;
}

class PulsingBlink extends StatefulWidget {
  const PulsingBlink({
    required this.child,
    this.active = true,
    this.duration = const Duration(milliseconds: 750),
    this.minOpacity = 0.25,
    this.maxOpacity = 1.0,
    this.minScale = 0.98,
    this.maxScale = 1.03,
    this.enableScale = false,
    super.key,
  });

  final Widget child;
  final bool active;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final double minScale;
  final double maxScale;
  final bool enableScale;

  @override
  State<PulsingBlink> createState() => _PulsingBlinkState();
}

class _PulsingBlinkState extends State<PulsingBlink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingBlink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final opacity = widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
        Widget current = Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: child,
        );
        if (widget.enableScale) {
          final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
          current = Transform.scale(scale: scale, child: current);
        }
        return current;
      },
      child: widget.child,
    );
  }
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
    this.blinkTitle = false,
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
  final bool blinkTitle;

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
                                                Icons
                                                    .image_not_supported_outlined,
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
                                            Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.65,
                                            ),
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
                                      PulsingBlink(
                                        active: blinkTitle,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        titleAccent!,
                                        style: TextStyle(
                                          color:
                                              titleAccentColor ??
                                              const Color(0xffffe22d),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ] else ...[
                                      PulsingBlink(
                                        active: blinkTitle,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                            letterSpacing: 0.5,
                                          ),
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
