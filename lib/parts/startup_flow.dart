part of '../main.dart';

enum _StartupStage { splashAndAuth, physicalStep1, physicalStep2 }

class StartupOnboardingFlow extends StatefulWidget {
  const StartupOnboardingFlow({
    required this.auth,
    required this.onSignInGoogle,
    required this.onCompleted,
    super.key,
  });

  final AuthSession auth;
  final Future<void> Function() onSignInGoogle;
  final VoidCallback onCompleted;

  @override
  State<StartupOnboardingFlow> createState() => _StartupOnboardingFlowState();
}

class _StartupOnboardingFlowState extends State<StartupOnboardingFlow> {
  _StartupStage _stage = _StartupStage.splashAndAuth;
  bool _checkingVersion = true;
  String _versionStatus = 'Checking for latest version...';
  bool _hideNextTime = false;

  @override
  void initState() {
    super.initState();
    _runStartupVersionCheck();
  }

  Future<void> _runStartupVersionCheck() async {
    try {
      await Future.wait([
        AppUpdateService.checkAndPrompt(context),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
    } catch (_) {
      // Ignore silent network issues
    }
    if (!mounted) return;
    setState(() {
      _checkingVersion = false;
      _versionStatus = 'Up to date ($appVersionLabel)';
    });
  }

  void _proceedAfterSplash() {
    if (AppSettings.instance.hidePhysicalRequirementsOnStartup) {
      widget.onCompleted();
    } else {
      setState(() => _stage = _StartupStage.physicalStep1);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_hideNextTime) {
      await AppSettings.instance.setHidePhysicalRequirementsOnStartup(true);
    }
    if (mounted) {
      widget.onCompleted();
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
                  // Version check card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: GameDesign.obsidianBg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameDesign.slateBorder),
                    ),
                    child: Row(
                      children: [
                        if (_checkingVersion)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: GameDesign.gold,
                            ),
                          )
                        else
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Color(0xff4ade80),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _versionStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          appVersionLabel,
                          style: const TextStyle(
                            color: GameDesign.gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_checkingVersion) ...[
                    if (isSigningIn)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            color: GameDesign.gold,
                          ),
                        ),
                      )
                    else if (isGoogleSignedIn) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroAvatar(
                              hero: AppSettings.instance.playerFavoriteHero,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              countryOptionForCode(
                                AppSettings.instance.playerCountryCode,
                              ).flag,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppSettings.instance.displayPseudo,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GameActionButton(
                        label: 'CONTINUE',
                        icon: Icons.arrow_forward_rounded,
                        primary: true,
                        onPressed: _proceedAfterSplash,
                      ),
                    ] else ...[
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalRequirementsScreen(BuildContext context) {
    final isStep1 = _stage == _StartupStage.physicalStep1;
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
                border: Border.all(color: GameDesign.gold.withValues(alpha: 0.6)),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: GameDesign.gold,
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
                isStep1 ? '1 / 2' : '2 / 2',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: GameDesign.gold,
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
                    if (isStep1) ...[
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'boss'),
                        title: '1. Dice Throne 2-Hero Battle Box',
                        description:
                            'To play Boss Battles, you must own at least one official physical Dice Throne 2-Hero Box (e.g. Barbarian v. Moon Elf). You will need your physical hero board, hero combat dice, and hero deck.',
                        actionLink: _buildOfficialLink(
                          label: 'Official website: dicethrone.com/heroes',
                          url: 'https://dicethrone.com/heroes/',
                        ),
                        imageWidget: ClipRRect(
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
                      ),
                      const SizedBox(height: 14),
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'minion'),
                        title: '2. Dice Throne Adventures (DTA) Core Box',
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
                                  height: 110,
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
                                  height: 110,
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
                                height: 85,
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
                                height: 115,
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
                      _buildRequirementCard(
                        badge: _buildHpButtonBadge(type: 'video'),
                        title: '4. How to Play (Video Tutorial)',
                        description:
                            'Discover the complete gameplay flow of Dice Throne Adventures with this 10-minute video guide covering physical setup, turns, combat rolls, and loot.',
                        actionLink: _buildOfficialLink(
                          label: 'Watch Video Tutorial on YouTube',
                          url: 'https://www.youtube.com/watch?v=js_cZrv6cZY',
                        ),
                        imageWidget: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => showHowToPlayVideoDialog(context),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 135,
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
                                  height: 135,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xffc4302b),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom action bar with checkbox + Next / Enter buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xff181c28),
                border: Border(top: BorderSide(color: GameDesign.slateBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _hideNextTime,
                    onChanged: (val) =>
                        setState(() => _hideNextTime = val ?? false),
                    title: const Text(
                      'Hide on next app launch',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: GameDesign.gold,
                    checkColor: Colors.black,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (!isStep1) ...[
                        Expanded(
                          flex: 1,
                          child: GameActionButton(
                            label: 'BACK',
                            icon: Icons.arrow_back_rounded,
                            primary: false,
                            onPressed: () => setState(
                              () => _stage = _StartupStage.physicalStep1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: GameActionButton(
                          label: isStep1 ? 'NEXT' : 'ENTER SOLO QUEST',
                          icon: isStep1
                              ? Icons.arrow_forward_rounded
                              : Icons.play_arrow_rounded,
                          primary: true,
                          onPressed: isStep1
                              ? () => setState(
                                  () => _stage = _StartupStage.physicalStep2,
                                )
                              : _finishOnboarding,
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
