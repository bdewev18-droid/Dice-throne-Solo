part of '../main.dart';

enum _StartupStage {
  splashAndAuth,
  physicalStep1,
  physicalStep2,
  physicalStep3,
}

class StartupOnboardingFlow extends StatefulWidget {
  const StartupOnboardingFlow({
    required this.auth,
    required this.historyRecords,
    required this.onSignInGoogle,
    required this.onCompleted,
    super.key,
  });

  final AuthSession auth;
  final List<GameRecord> historyRecords;
  final Future<void> Function() onSignInGoogle;
  final ValueChanged<RemoteAppVersion?> onCompleted;

  @override
  State<StartupOnboardingFlow> createState() => _StartupOnboardingFlowState();
}

class _StartupOnboardingFlowState extends State<StartupOnboardingFlow> {
  _StartupStage _stage = _StartupStage.splashAndAuth;
  bool _checkingVersion = true;
  RemoteAppVersion? _availableUpdate;
  String _versionStatus = 'Checking for latest version...';
  bool _hideNextTime = false;

  @override
  void initState() {
    super.initState();
    _runStartupVersionCheck();
  }

  Future<void> _runStartupVersionCheck() async {
    RemoteAppVersion? remote;
    try {
      final results = await Future.wait([
        AppUpdateService.checkUpdate(),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
      remote = results[0] as RemoteAppVersion?;
    } catch (_) {
      // Ignore silent network issues
    }
    if (!mounted) return;
    setState(() {
      _checkingVersion = false;
      _availableUpdate = remote;
      _versionStatus = remote != null
          ? 'New version available: v${remote.version} (Tap to update)'
          : 'Up to date ($appVersionLabel)';
    });
  }

  void _proceedAfterSplash() {
    if (AppSettings.instance.hidePhysicalRequirementsOnStartup) {
      widget.onCompleted(_availableUpdate);
    } else {
      setState(() => _stage = _StartupStage.physicalStep1);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_hideNextTime) {
      await AppSettings.instance.setHidePhysicalRequirementsOnStartup(true);
    }
    if (mounted) {
      widget.onCompleted(_availableUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _StartupStage.splashAndAuth) {
      return _buildSplashScreen(context);
    }
    return _buildPhysicalRequirementsScreen(context);
  }

  Widget _buildSplashScreen(BuildContext context) {
    final isSigningIn = widget.auth.status == AuthStatus.signingIn;
    final isGoogleSignedIn =
        widget.auth.isSignedIn &&
        !widget.auth.isAnonymous &&
        (widget.auth.email?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: MediaQuery.paddingOf(context).top + 18,
            child: Image.asset(
              'assets/home_background_v5.jpg',
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  if (!_checkingVersion) ...[
                    if (isGoogleSignedIn) ...[
                      _buildPlayerProfileHeroCard(
                        context,
                        isGoogleSignedIn: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isSigningIn)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            color: GameDesign.actionPrimary,
                          ),
                        ),
                      )
                    else if (isGoogleSignedIn)
                      GameActionButton(
                        label: 'CONTINUE',
                        icon: Icons.arrow_forward_rounded,
                        primary: true,
                        onPressed: _proceedAfterSplash,
                      )
                    else ...[
                      GameActionButton(
                        label: 'SIGN IN WITH GOOGLE',
                        subtitle: 'Sync your runs, bestiary & rankings',
                        icon: Icons.login_rounded,
                        primary: true,
                        height: 56,
                        onPressed: () async {
                          await widget.onSignInGoogle();
                          if (mounted &&
                              SupabaseService.instance
                                  .currentSession()
                                  .isSignedIn) {
                            _proceedAfterSplash();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      GameActionButton(
                        label: 'CONTINUE AS GUEST',
                        icon: Icons.person_outline_rounded,
                        primary: false,
                        onPressed: _proceedAfterSplash,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  // Clean, unboxed version status placed below buttons
                  InkWell(
                    onTap: _availableUpdate != null
                        ? () => AppUpdateService.promptUpdate(
                            context,
                            _availableUpdate!,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_checkingVersion)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GameDesign.actionPrimary,
                              ),
                            )
                          else if (_availableUpdate != null)
                            const Icon(
                              Icons.system_update_rounded,
                              size: 16,
                              color: Color(0xffffb300),
                            )
                          else
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: Color(0xff4ade80),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _versionStatus,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _availableUpdate != null
                                    ? const Color(0xffffb300)
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 6),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildPlayerProfileHeroCard(
    BuildContext context, {
    required bool isGoogleSignedIn,
  }) {
    final settings = AppSettings.instance;
    final favHero = settings.playerFavoriteHero;
    final country = countryOptionForCode(settings.playerCountryCode);
    final validRuns = widget.historyRecords
        .where((r) => r.hero != HeroType.benjamin)
        .toList();
    final gamesCount = validRuns.length;
    final winsCount = validRuns.where(LeaderboardCalculator.isRunVictory).length;
    final winRatePct =
        gamesCount == 0 ? 0 : ((winsCount / gamesCount) * 100).round();
    final totalEnemies = EnemyProfileRepository.validatedCatalogCount;
    final defeatedCount = settings.defeatedEnemyKeys.length;
    final bestiaryPct = totalEnemies == 0
        ? 0
        : ((defeatedCount / totalEnemies) * 100).clamp(0, 100).round();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final updated = await showPlayerProfileDialog(context);
        if (updated == true && mounted) {
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GameDesign.obsidianBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: favHero.color.withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: favHero.color.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(country.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          settings.displayPseudo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Favorite: ${favHero.label}',
                    style: TextStyle(
                      color: favHero.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ProfileStatPill(
                        label: 'GAMES',
                        value: '$gamesCount',
                      ),
                      const SizedBox(width: 8),
                      _ProfileStatPill(
                        label: 'WIN RATE',
                        value: '$winRatePct%',
                      ),
                      const SizedBox(width: 8),
                      _ProfileStatPill(
                        label: 'BESTIARY',
                        value: '$bestiaryPct%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: favHero.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: favHero.color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Transform.scale(
                scale: min(favHero.imageScale, 1.15),
                child: Image.asset(
                  favHero.asset,
                  fit: BoxFit.cover,
                  alignment: favHero.imageAlignment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalRequirementsScreen(BuildContext context) {
    final stepNumber = switch (_stage) {
      _StartupStage.physicalStep1 => 1,
      _StartupStage.physicalStep2 => 2,
      _StartupStage.physicalStep3 => 3,
      _ => 1,
    };
    const cardBg = Color(0xffe2e7e5);

    return Scaffold(
      backgroundColor: GameDesign.obsidianBg,
      appBar: AppBar(
        backgroundColor: GameDesign.obsidianBg,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GameDesign.slateSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: GameDesign.actionPrimary.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: GameDesign.actionPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Physical Games Required',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GameDesign.slateSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameDesign.slateBorder),
              ),
              child: Text(
                '$stepNumber / 3',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: GameDesign.actionPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stepNumber == 2 || stepNumber == 3) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GameDesign.slateSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GameDesign.slateBorder),
                        ),
                        child: const Text(
                          'D.T Solo Quest is an unofficial companion app. To play, you must physically own Dice Throne board game components.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (stepNumber == 1) ...[
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'boss'),
                        title: '1. Dice Throne 2-Hero Battle Box',
                        description:
                            'To play Boss Battles, you must own at least one official physical Dice Throne 2-Hero Box (e.g. Barbarian v. Moon Elf). You will need your physical hero board, hero combat dice, and hero deck.',
                        actionLink: _buildOfficialLink(
                          label: 'Official website: dicethrone.com/heroes',
                          url: 'https://dicethrone.com/heroes/',
                        ),
                        imageWidget: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: cardBg,
                                height: 125,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/requirement/popin4.webp',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: cardBg,
                                height: 135,
                                width: double.infinity,
                                child: Image.network(
                                  'https://bdewev18-droid.github.io/DT-SoloQuest-website/physical_board.webp',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.black38,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (stepNumber == 2) ...[
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'minion'),
                        title: '2. Minion Rush Mode (DTA Core Box)',
                        description:
                            'To play Minion Rush, in addition to a 2-Hero Battle Box, you must own the physical Dice Throne Adventures (DTA) box for minion decks, brackets, and tokens.',
                        actionLink: _buildOfficialLink(
                          label: 'Official expansions: shop.dicethrone.com',
                          url:
                              'https://shop.dicethrone.com/collections/expansions',
                        ),
                        imageWidget: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: cardBg,
                                  height: 135,
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
                                  color: cardBg,
                                  height: 135,
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
                    ] else ...[
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'loot'),
                        title: '3. Loot Cards & Status Effect Tokens',
                        description:
                            'During a run, physically add loot cards into your hero deck upon winning rewards (Common, Rare, Epic, Legendary) and track status tokens with your physical tray.',
                        imageWidget: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: cardBg,
                                height: 105,
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
                                color: cardBg,
                                height: 135,
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
                    ],
                  ],
                ),
              ),
            ),
            // Bottom action bar with prominent visibility toggle + Back / Next / Enter buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xff181c28),
                border: Border(top: BorderSide(color: GameDesign.slateBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        setState(() => _hideNextTime = !_hideNextTime),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _hideNextTime
                            ? GameDesign.actionPrimary.withValues(alpha: 0.14)
                            : GameDesign.obsidianBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _hideNextTime
                              ? GameDesign.actionPrimary
                              : GameDesign.slateBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hideNextTime
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_outlined,
                            size: 18,
                            color: _hideNextTime
                                ? GameDesign.actionPrimary
                                : Colors.white60,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Skip this guide on future launches',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Switch(
                            value: _hideNextTime,
                            onChanged: (val) =>
                                setState(() => _hideNextTime = val),
                            activeThumbColor: GameDesign.goldText,
                            activeTrackColor: GameDesign.actionPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (stepNumber > 1) ...[
                        Expanded(
                          flex: 1,
                          child: GameActionButton(
                            label: 'BACK',
                            icon: Icons.arrow_back_rounded,
                            primary: false,
                            onPressed: () => setState(
                              () => _stage = stepNumber == 2
                                  ? _StartupStage.physicalStep1
                                  : _StartupStage.physicalStep2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: GameActionButton(
                          label: stepNumber < 3 ? 'NEXT' : 'ENTER SOLO QUEST',
                          icon: stepNumber < 3
                              ? Icons.arrow_forward_rounded
                              : Icons.play_arrow_rounded,
                          primary: true,
                          onPressed: () {
                            if (stepNumber == 1) {
                              setState(
                                () => _stage = _StartupStage.physicalStep2,
                              );
                            } else if (stepNumber == 2) {
                              setState(
                                () => _stage = _StartupStage.physicalStep3,
                              );
                            } else {
                              _finishOnboarding();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ProfileStatPill extends StatelessWidget {
  const _ProfileStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: GameDesign.slateSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameDesign.slateBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: GameDesign.actionPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
