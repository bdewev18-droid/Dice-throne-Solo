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
      home: Builder(
        builder: (context) => _buildHomePage(context),
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    if (!_storageReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return HomePage(
      activeAdventure: _activeAdventure,
      auth: _auth,
      onHistory: () => _openHistory(context),
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
                  final next = AdventureState(hero: adventure.hero, config: adventure.config);
                  _activeAdventure = next;
                  _saveActiveAdventure();
                  _replaceWithMap(context, next, adventure.hero, adventure.config);
                },
              ),
            ),
          );
        }
      },
      onStopCampaign: _stopActiveCampaign,
      onNaraxus: () => _openNaraxusHeroChoice(context),
      onMatchup: () => _openMatchup(context),
      onSignInGoogle: _signInWithGoogle,
      onSignInAnonymous: _signInAnonymously,
      onSignOut: _signOut,
    );
  }

  void _openMatchup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MatchupSetupPage(),
      ),
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
    required this.onSurvival,
    required this.onResume,
    required this.onStopCampaign,
    required this.onNaraxus,
    required this.onMatchup,
    required this.onSignInGoogle,
    required this.onSignInAnonymous,
    required this.onSignOut,
    super.key,
  });

  final AdventureState? activeAdventure;
  final AuthSession auth;
  final VoidCallback onHistory;
  final VoidCallback onSurvival;
  final VoidCallback onResume;
  final VoidCallback onStopCampaign;
  final VoidCallback onNaraxus;
  final VoidCallback onMatchup;
  final VoidCallback onSignInGoogle;
  final VoidCallback onSignInAnonymous;
  final VoidCallback onSignOut;

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
                                badgeLabel: 'Coming soon',
                                onPressed: AppSettings.instance.developerMode ? widget.onSurvival : null,
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
                            const SizedBox(height: 20),
                            ImageActionButton(
                              label: 'Match-up',
                              icon: Icons.sports_kabaddi,
                              badgeLabel: 'Dev mode',
                              onPressed: AppSettings.instance.developerMode ? widget.onMatchup : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  VersionPill(
                    label: '$appVersionLabel${AppSettings.instance.developerMode ? ' - Dev mode' : ''}',
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
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? badgeLabel;

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
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/button_background.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Opacity(
                  opacity: onPressed == null ? 0.42 : 1,
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
          ),
          if (badgeLabel != null && onPressed == null)
            Transform.rotate(
              angle: -0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffd6512a).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amberAccent, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  badgeLabel!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
    if (auth.isSignedIn && !auth.isAnonymous && (auth.email?.isNotEmpty ?? false)) {
      return _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user,
              size: 16,
              color: Colors.white,
            ),
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
