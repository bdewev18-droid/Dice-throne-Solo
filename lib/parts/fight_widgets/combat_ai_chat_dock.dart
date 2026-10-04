part of '../../main.dart';

class CombatAiChatDock extends StatelessWidget {
  const CombatAiChatDock({
    required this.aiMode,
    this.influenceRollReduction = 0,
    required this.aiMessage,
    required this.phase,
    required this.adventure,
    required this.enemy,
    required this.primaryEnemy,
    this.secondaryEnemy,
    required this.canSwitchTarget,
    required this.onSelectTarget,
    required this.returnDamage,
    required this.returnDamageUndefendable,
    required this.lifeSteal,
    required this.enemyHeal,
    required this.cpSteal,
    required this.heroTokens,
    required this.minionTokens,
    required this.notes,
    required this.showResolution,
    required this.attackValue,
    this.attackModifier,
    required this.defenseValue,
    this.defenseModifier,
    this.showStunCover = false,
    this.showOnlyCardsCover = false,
    this.onOnlyCardsUnlock,
    required this.onAttackChanged,
    required this.onDefenseChanged,
    required this.onApply,
    this.blockApply = false,
    required this.onFinish,
    required this.onChanged,
    this.onEditHeroTokens,
    this.onEditEnemyTokens,
    this.onHeroTokenRemoved,
    this.onEnemyTokenRemoved,
    this.showBlindButton = false,
    this.onBlindPressed,
    this.showEvasiveAttackCover = false,
    this.showFlightAttackCover = false,
    this.showParlayAttackCover = false,
    this.showWebbedAttackCover = false,
    this.heroEvasiveCount = 0,
    this.heroEvasiveAvoided = false,
    this.onUseHeroEvasive,
    this.heroFlightCount = 0,
    this.minionFlightCount = 0,
    this.flightAvoided = false,
    this.flightUndefendable = false,
    this.onUseHeroFlight,
    this.onUseMinionFlight,
    this.heroAgilityCount = 0,
    this.heroAgilityActive = false,
    this.heroAgilitySuccesses = 0,
    this.heroAgilityPrevented = 0,
    this.onUseHeroAgility,
    this.minionAgilityAvoided = false,
    this.shadowsActive = false,
    this.heroShadowsCount = 0,
    this.onUseHeroShadows,
    this.minionShadowsCount = 0,
    this.minionShadowsActive = false,
    this.onUseMinionShadows,
    this.attackerSneakAttackCount = 0,
    this.attackerSneakAttackActive = false,
    this.attackerSneakAttackBonus = 0,
    this.canUseAttackerSneakAttack = false,
    this.onUseAttackerSneakAttack,
    this.attackerGuardBreakCount = 0,
    this.canUseAttackerGuardBreak = false,
    this.onUseAttackerGuardBreak,
    this.defenderPreyCount = 0,
    this.preyUsedCount = 0,
    this.canUsePrey = false,
    this.onUsePrey,
    this.windShearCount = 0,
    this.windShearActive = false,
    this.canUseWindShear = false,
    this.onUseWindShear,
    this.attackerAccuracyCount = 0,
    this.accuracyUsed = false,
    this.canUseAccuracy = false,
    this.onUseAccuracy,
    this.attackerCritCount = 0,
    this.critUsed = false,
    this.canUseCrit = false,
    this.onUseCrit,
    this.availableDamageBonus = const [],
    this.usedDamageBonus = const [],
    this.onUseDamageBonus,
    this.honorCount = 0,
    this.salveCount = 0,
    this.onUseSalve,
    this.smokeBombCount = 0,
    this.onUseSmokeBomb,
    this.smokeBombSuccess = false,
    this.honorDamageBonus = 0,
    this.onUseHonor,
    this.ninjitsuCount = 0,
    this.ninjitsuDamageBonus = 0,
    this.ninjitsuUndefendable = false,
    this.onUseNinjitsu,
    this.protectCount = 0,
    this.protectUsed = false,
    this.minionAutoProtect = false,
    this.onUseProtect,
    this.retributionCount = 0,
    this.retributionUsed = false,
    this.minionAutoRetribution = false,
    this.onUseRetribution,
    this.guardBreakSuccess = false,
    this.barbedVineActive = false,
    this.barbedVineCount = 0,
    this.onUseBarbedVine,
    this.barbedVineUsed = false,
    this.constrictActive = false,
    this.constrictCount = 0,
    this.onUseConstrict,
    this.constrictUsed = false,
    this.decrepifyActive = false,
    this.diceCubeActive = false,
    this.diceCubeCount = 0,
    this.entangleActive = false,
    this.entangleCount = 0,
    this.heroWellspringCount = 0,
    this.onUseHeroWellspring,
    this.enemyWellspringCount = 0,
    this.onUseEnemyWellspring,
    this.showBlindingLightAttackCover = false,
    this.onBlindingLightPressed,
    this.blindingLightZeroDamage = false,
    this.blindingLightReducedDamage = 0,
    this.blindingLightBaseAttack = 0,
    this.blindingLightRoll,
    this.realityWarpActive = false,
    this.silenceActive = false,
    this.webbedActive = false,
    super.key,
  });

  final bool aiMode;
  final int influenceRollReduction;
  final String aiMessage;
  final CombatPhase phase;
  final AdventureState adventure;
  final EnemyNode enemy;
  final EnemyNode primaryEnemy;
  final EnemyNode? secondaryEnemy;
  final bool canSwitchTarget;
  final bool shadowsActive;
  final int heroShadowsCount;
  final VoidCallback? onUseHeroShadows;
  final int minionShadowsCount;
  final bool minionShadowsActive;
  final VoidCallback? onUseMinionShadows;
  final int attackerSneakAttackCount;
  final bool attackerSneakAttackActive;
  final int attackerSneakAttackBonus;
  final bool canUseAttackerSneakAttack;
  final VoidCallback? onUseAttackerSneakAttack;
  final int attackerGuardBreakCount;
  final bool canUseAttackerGuardBreak;
  final VoidCallback? onUseAttackerGuardBreak;
  final int defenderPreyCount;
  final int preyUsedCount;
  final bool canUsePrey;
  final VoidCallback? onUsePrey;
  final int windShearCount;
  final bool windShearActive;
  final bool canUseWindShear;
  final VoidCallback? onUseWindShear;
  final int attackerAccuracyCount;
  final bool accuracyUsed;
  final bool canUseAccuracy;
  final VoidCallback? onUseAccuracy;
  final int attackerCritCount;
  final bool critUsed;
  final bool canUseCrit;
  final VoidCallback? onUseCrit;
  final List<int> availableDamageBonus;
  final List<int> usedDamageBonus;
  final ValueChanged<int>? onUseDamageBonus;
  final int honorCount;
  final int salveCount;
  final VoidCallback? onUseSalve;
  final int smokeBombCount;
  final VoidCallback? onUseSmokeBomb;
  final bool smokeBombSuccess;
  final int honorDamageBonus;
  final VoidCallback? onUseHonor;
  final int ninjitsuCount;
  final int ninjitsuDamageBonus;
  final bool ninjitsuUndefendable;
  final VoidCallback? onUseNinjitsu;
  final int protectCount;
  final bool protectUsed;
  final bool minionAutoProtect;
  final VoidCallback? onUseProtect;
  final int retributionCount;
  final bool retributionUsed;
  final bool minionAutoRetribution;
  final VoidCallback? onUseRetribution;
  final bool guardBreakSuccess;
  final bool barbedVineActive;
  final int barbedVineCount;
  final ValueChanged<int>? onUseBarbedVine;
  final bool barbedVineUsed;
  final bool constrictActive;
  final int constrictCount;
  final ValueChanged<int>? onUseConstrict;
  final bool constrictUsed;
  final bool decrepifyActive;
  final bool diceCubeActive;
  final int diceCubeCount;
  final bool entangleActive;
  final int entangleCount;
  final int heroWellspringCount;
  final VoidCallback? onUseHeroWellspring;
  final int enemyWellspringCount;
  final VoidCallback? onUseEnemyWellspring;
  final bool showBlindingLightAttackCover;
  final VoidCallback? onBlindingLightPressed;
  final bool blindingLightZeroDamage;
  final int blindingLightReducedDamage;
  final int blindingLightBaseAttack;
  final int? blindingLightRoll;
  final bool realityWarpActive;
  final bool silenceActive;
  final bool webbedActive;
  final ValueChanged<EnemyNode> onSelectTarget;
  final int returnDamage;
  final bool returnDamageUndefendable;
  final int lifeSteal;
  final int enemyHeal;
  final int cpSteal;
  final List<String> heroTokens;
  final List<String> minionTokens;
  final List<String> notes;
  final bool showResolution;
  final int attackValue;
  final int? attackModifier;
  final int defenseValue;
  final int? defenseModifier;
  final bool showStunCover;
  final bool showOnlyCardsCover;
  final VoidCallback? onOnlyCardsUnlock;
  final ValueChanged<int> onAttackChanged;
  final ValueChanged<int> onDefenseChanged;
  final VoidCallback onApply;
  final bool blockApply;
  final VoidCallback? onFinish;
  final VoidCallback onChanged;
  final VoidCallback? onEditHeroTokens;
  final VoidCallback? onEditEnemyTokens;
  final ValueChanged<String>? onHeroTokenRemoved;
  final ValueChanged<String>? onEnemyTokenRemoved;
  final bool showBlindButton;
  final VoidCallback? onBlindPressed;
  final bool showEvasiveAttackCover;
  final bool showFlightAttackCover;
  final bool showParlayAttackCover;
  final bool showWebbedAttackCover;
  final int heroEvasiveCount;
  final bool heroEvasiveAvoided;
  final VoidCallback? onUseHeroEvasive;
  final int heroFlightCount;
  final int minionFlightCount;
  final bool flightAvoided;
  final bool flightUndefendable;
  final VoidCallback? onUseHeroFlight;
  final VoidCallback? onUseMinionFlight;
  final int heroAgilityCount;
  final bool heroAgilityActive;
  final int heroAgilitySuccesses;
  final int heroAgilityPrevented;
  final VoidCallback? onUseHeroAgility;
  final bool minionAgilityAvoided;

  @override
  Widget build(BuildContext context) {
    final bool hasAnyAction = salveCount > 0 ||
        windShearCount > 0 ||
        defenderPreyCount > 0 ||
        attackerCritCount > 0 ||
        attackerAccuracyCount > 0 ||
        honorCount > 0 ||
        ninjitsuCount > 0 ||
        smokeBombCount > 0 ||
        barbedVineCount > 0 ||
        constrictCount > 0 ||
        diceCubeCount > 0 ||
        entangleCount > 0 ||
        heroWellspringCount > 0 ||
        enemyWellspringCount > 0;

    if (!aiMode && !showResolution && onFinish == null && !hasAnyAction) {
      return const SizedBox.shrink();
    }
    final chatAccent =
        phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
        ? heroAccent
        : enemy.rank.color;
    final enemyCpInfinity =
        enemy.profileKey == 'naraxus' || enemy.profileKey == 'viseer';
    final cleanHeroTokens = heroTokens
        .map((t) => t.replaceAll(RegExp(r'_active', caseSensitive: false), ''))
        .toList();
    final cleanMinionTokens = minionTokens
        .map((t) => t.replaceAll(RegExp(r'_active', caseSensitive: false), ''))
        .toList();
    
    final isHeroTurn = phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep;
    final heroAsset = adventure.hero.asset;
    final enemyAsset = enemy.cardAsset;
    final attackerAsset = isHeroTurn ? heroAsset : enemyAsset;
    final defenderAsset = isHeroTurn ? enemyAsset : heroAsset;
final isHeroBattle = phase == CombatPhase.hero;
    final hasBlindingLightInAiMessage = aiMessage.contains(
      'Blinding Light (D6:',
    );
    String? blindingLightInterpretation;
    if (!hasBlindingLightInAiMessage) {
      final attackerName = isHeroBattle ? adventure.hero.label : enemy.label;
      if (blindingLightRoll != null) {
        if (blindingLightZeroDamage || blindingLightRoll == 1) {
          blindingLightInterpretation =
              'Blinding Light (D6: 1) on $attackerName: Offensive Ability fails to activate! 0 damage dealt.';
        } else if (blindingLightRoll == 2 || blindingLightRoll == 3) {
          final netDmg = (blindingLightBaseAttack - blindingLightReducedDamage)
              .clamp(0, 99);
          blindingLightInterpretation =
              'Blinding Light (D6: $blindingLightRoll) on $attackerName: Attack damage is reduced by half (-$blindingLightReducedDamage). Net attack: $netDmg.';
        } else {
          blindingLightInterpretation =
              'Blinding Light (D6: $blindingLightRoll) on $attackerName: Attack applies at full strength ($blindingLightBaseAttack damage).';
        }
      } else if (showBlindingLightAttackCover) {
        blindingLightInterpretation =
            'Blinding Light is active on $attackerName: Roll 1 D6 on attack (1 = fails, 2-3 = 1/2 damage, 4-6 = full damage).';
      }
    }
    final tokenText = [
      if (cleanHeroTokens.isNotEmpty) 'Hero: ${cleanHeroTokens.join(', ')}',
      if (cleanMinionTokens.isNotEmpty)
        'Minion: ${cleanMinionTokens.join(', ')}',
      ?blindingLightInterpretation,
      if (returnDamage > 0)
        returnDamageUndefendable
            ? 'Returns $returnDamage undefendable damage'
            : 'Returns $returnDamage damage',
      if (lifeSteal > 0) 'Steals $lifeSteal health',
      if (enemyHeal > 0 && !enemyCpInfinity) 'Enemy heals: $enemyHeal',
      if (cpSteal > 0) 'CP steal: $cpSteal',
      if (enemy.profileKey != 'naraxus') ...notes,
    ];
    final attackColor = isHeroBattle ? heroAccent : enemy.rank.color;
    final defenseColor = isHeroBattle ? enemy.rank.color : heroAccent;
    final defenderHasTargeted = phase == CombatPhase.hero
        ? enemy.alterations.any(
            (t) =>
                _normalizeTokenKey(t) == 'targeted' ||
                _normalizeTokenKey(t) == 'prispourcible',
          )
        : (phase == CombatPhase.minionAttack
              ? adventure.alterations.any(
                  (t) =>
                      _normalizeTokenKey(t) == 'targeted' ||
                      _normalizeTokenKey(t) == 'prispourcible',
                )
              : false);
    final defenderFocusFireCount = phase == CombatPhase.hero
        ? enemy.alterations
              .where(
                (t) =>
                    _normalizeTokenKey(t) == 'focusfire' ||
                    _normalizeTokenKey(t) == 'tirciblÃ©' ||
                    _normalizeTokenKey(t) == 'tircible',
              )
              .length
        : (phase == CombatPhase.minionAttack
              ? adventure.alterations
                    .where(
                      (t) =>
                          _normalizeTokenKey(t) == 'focusfire' ||
                          _normalizeTokenKey(t) == 'tirciblÃ©' ||
                          _normalizeTokenKey(t) == 'tircible',
                    )
                    .length
              : 0);
    final attackerHasShame = phase == CombatPhase.hero
        ? adventure.alterations.any(_isShameToken)
        : (phase == CombatPhase.minionAttack
              ? enemy.alterations.any(_isShameToken)
              : false);
    final attackerWitherCount = phase == CombatPhase.hero
        ? adventure.alterations
              .where(
                (t) =>
                    _normalizeTokenKey(t).contains('wither') ||
                    _normalizeTokenKey(t).contains('flÃ©trissement') ||
                    _normalizeTokenKey(t).contains('fletrissement'),
              )
              .length
        : (phase == CombatPhase.minionAttack
              ? enemy.alterations
                    .where(
                      (t) =>
                          _normalizeTokenKey(t).contains('wither') ||
                          _normalizeTokenKey(t).contains('flÃ©trissement') ||
                          _normalizeTokenKey(t).contains('fletrissement'),
                    )
                    .length
              : 0);
    final defenderHasSunMarked = phase == CombatPhase.hero
        ? enemy.alterations.any(
            (t) =>
                _normalizeTokenKey(t).contains('sun-marked') ||
                _normalizeTokenKey(t).contains('sun marked') ||
                _normalizeTokenKey(t).contains('sunmarked'),
          )
        : (phase == CombatPhase.minionAttack
              ? adventure.alterations.any(
                  (t) =>
                      _normalizeTokenKey(t).contains('sun-marked') ||
                      _normalizeTokenKey(t).contains('sun marked') ||
                      _normalizeTokenKey(t).contains('sunmarked'),
                )
              : false);
    final bool showHeroEvasiveRow =
        phase == CombatPhase.minionAttack &&
        (heroEvasiveCount > 0 || heroEvasiveAvoided);
    final bool showHeroFlightRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (heroFlightCount > 0) &&
        !(flightAvoided || flightUndefendable);
    final bool showHeroAgilityRow =
        phase == CombatPhase.minionAttack &&
        (heroAgilityCount > 0 || heroAgilityActive);
    final bool showHeroShadowsRow =
        phase == CombatPhase.minionAttack &&
        (heroShadowsCount > 0 || shadowsActive);
    final bool showBarbedVineRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (barbedVineActive || barbedVineCount > 0);
    final bool showConstrictRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (constrictActive || constrictCount > 0);
    final bool showDecrepifyRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        decrepifyActive;
    final bool showBlindingLightRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (blindingLightRoll != null);
    final bool showDiceCubeRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (diceCubeActive || diceCubeCount > 0);
    final bool showEntangleRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (entangleActive || entangleCount > 0);
    final bool showInfluenceRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (influenceRollReduction > 0);
    final bool showSneakAttackRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (attackerSneakAttackCount > 0 || attackerSneakAttackActive);
    final bool showGuardBreakRow =
        (phase == CombatPhase.hero || phase == CombatPhase.minionAttack) &&
        (attackerGuardBreakCount > 0 || guardBreakSuccess);
    final bool showShadowsAttackCover =
        phase == CombatPhase.minionAttack && shadowsActive;
    final bool isAgilityAvoided =
        (phase == CombatPhase.minionAttack &&
            heroAgilityActive &&
            heroAgilitySuccesses >= 2) ||
        (phase == CombatPhase.hero && minionAgilityAvoided);
//     final bool isHeroTurn =
//         phase == CombatPhase.heroUpkeep || phase == CombatPhase.hero;
    final bool isMinionTurn =
        phase == CombatPhase.minionUpkeep || phase == CombatPhase.minionAttack;
    final bool showWellspringRow =
        (isHeroTurn && heroWellspringCount > 0) ||
        (isMinionTurn && enemyWellspringCount > 0);
    final int wellspringCount = isHeroTurn
        ? heroWellspringCount
        : enemyWellspringCount;
    final VoidCallback? onUseWellspring = isHeroTurn
        ? onUseHeroWellspring
        : onUseEnemyWellspring;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xf2121212),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aiMode && canSwitchTarget && secondaryEnemy != null) ...[
            _DualEnemyTargetButtons(
              primaryEnemy: primaryEnemy,
              secondaryEnemy: secondaryEnemy!,
              activeEnemy: enemy,
              onSelect: onSelectTarget,
            ),
            const SizedBox(height: 8),
          ],
          if (aiMode)
            _AiChatWithHealth(
              message: _battleChatText(aiMessage, tokenText),
              accent: chatAccent,
              heroHp: adventure.health,
              heroCp: adventure.combatPoints,
              enemyHp: enemy.health,
              enemyCp: enemy.combatPoints,
              enemyCpInfinity: enemyCpInfinity,
              enemyColor: enemy.rank.color,
              heroName: adventure.hero.label,
              enemyName: enemy.label,
              heroTokens: adventure.alterations.map((t) {
                if (shadowsActive &&
                    (t.toLowerCase() == 'shadows' ||
                        t.toLowerCase() == 'ombre')) {
                  return '${t}_active';
                }
                if (phase == CombatPhase.hero &&
                    (barbedVineActive || barbedVineCount > 0) &&
                    (t.toLowerCase() == 'barbed vine' ||
                        t.toLowerCase() == 'barbedvine' ||
                        t.toLowerCase() == 'ronces' ||
                        t.toLowerCase() == 'ronce')) {
                  return '${t}_active';
                }
                if ((phase == CombatPhase.hero ||
                        phase == CombatPhase.minionAttack) &&
                    influenceRollReduction > 0 &&
                    t.toLowerCase() == 'influence') {
                  return '$t (-$influenceRollReduction)_active';
                }
                return t;
              }).toList(),
              enemyTokens: enemy.alterations.map((t) {
                if (phase == CombatPhase.minionAttack &&
                    (barbedVineActive || barbedVineCount > 0) &&
                    (t.toLowerCase() == 'barbed vine' ||
                        t.toLowerCase() == 'barbedvine' ||
                        t.toLowerCase() == 'ronces' ||
                        t.toLowerCase() == 'ronce')) {
                  return '${t}_active';
                }
                if ((phase == CombatPhase.hero ||
                        phase == CombatPhase.minionAttack) &&
                    influenceRollReduction > 0 &&
                    t.toLowerCase() == 'influence') {
                  return '$t (-$influenceRollReduction)_active';
                }
                return t;
              }).toList(),
              onEditHeroTokens: onEditHeroTokens,
              onEditEnemyTokens: onEditEnemyTokens,
              onTokensChanged: onChanged,
              onHeroTokenRemoved: onHeroTokenRemoved,
              onEnemyTokenRemoved: onEnemyTokenRemoved,
              portraitAsset:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.asset
                  : enemy.previewAsset,
              portraitAlignment:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? _topCropAlignment(adventure.hero.imageAlignment)
                  : enemy.profileKey == 'naraxus'
                  ? Alignment.topCenter
                  : _topCropAlignment(Alignment.centerLeft),
              portraitScale:
                  phase == CombatPhase.hero || phase == CombatPhase.heroUpkeep
                  ? adventure.hero.imageScale
                  : 1,
              portraitFit: BoxFit.cover,
              showPortraitVitals:
                  phase == CombatPhase.hero ||
                  phase == CombatPhase.minionAttack,
              showHealthControls: false,
              onHeroHpSaved: (value) {
                adventure.setHeroHealth(value);
                onChanged();
              },
              onHeroCpSaved: (value) {
                adventure.setHeroPc(value);
                onChanged();
              },
              onEnemyHpSaved: (value) {
                final oldHp = enemy.health;
                enemy.health = value.clamp(0, enemy.maxHealth);
                if (oldHp != enemy.health) {
                  adventure.log(
                    '[HP] ${enemy.label} HP: $oldHp âž” ${enemy.health} (Manual Adjustment)',
                  );
                }
                onChanged();
              },
              onEnemyCpSaved: (value) {
                final oldCp = enemy.combatPoints;
                enemy.combatPoints = value.clamp(0, 99);
                if (oldCp != enemy.combatPoints) {
                  adventure.log(
                    '[CP] ${enemy.label} CP: $oldCp âž” ${enemy.combatPoints} (Manual Adjustment)',
                  );
                }
                onChanged();
              },
            ),
          if (showWellspringRow) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff1f1a2e),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xff8f43ff).withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  _ActionRowLabel(
                    tokenLabel: 'Wellspring',
                    tokenAsset: 'assets/token/Wellspring.png',
                    text: wellspringCount > 1
                        ? 'Wellspring (x$wellspringCount)'
                        : 'Wellspring',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onUseWellspring,
                    child: const Text(
                      'Use',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showResolution) ...[
            if (defenderHasTargeted)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Targeted',
                tokenAsset: 'assets/token/Targeted.png',
                activeText: attackValue > 0
                    ? 'Active (+2 DMG)'
                    : 'Pending (ATK = 0)',
              ),
            if (defenderFocusFireCount > 0)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Focus Fire',
                tokenAsset: 'assets/token/focus-fire.webp',
                activeText: attackValue > 0
                    ? 'Active (+$defenderFocusFireCount DMG)'
                    : 'Pending (ATK = 0)',
              ),
            if (attackerHasShame) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  final rule = TokenCatalogRepository.byLabel('Shame');
                  if (rule != null) showTokenDetails(context, rule);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: attackValue > 0
                        ? const Color(0xff2a1b18)
                        : const Color(0xff1a1722),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: attackValue > 0
                          ? const Color(0xff8f43ff)
                          : Colors.white24,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/token/shame.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.do_not_disturb_on,
                          color: Color(0xff8f43ff),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Shame : ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '-1 DMG',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xff8f43ff),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: attackValue > 0
                              ? const Color(0xff8f43ff).withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: attackValue > 0
                                ? const Color(0xff8f43ff)
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              attackValue > 0
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 12,
                              color: attackValue > 0
                                  ? const Color(0xff8f43ff)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              attackValue > 0
                                  ? 'Active (-1 DMG)'
                                  : 'Pending (ATK = 0)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: attackValue > 0
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (attackerWitherCount > 0)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: attackerWitherCount > 1
                    ? 'Wither (x$attackerWitherCount)'
                    : 'Wither',
                tokenAsset: 'assets/token/Wither.png',
                activeText: attackValue > 0
                    ? 'Active (-$attackerWitherCount DMG)'
                    : 'Pending (ATK = 0)',
              ),
            if (showHeroEvasiveRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: heroEvasiveAvoided
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: heroEvasiveAvoided
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Evasive',
                      tokenAsset: 'assets/token/Evasive.png',
                      text: 'Evasive (x$heroEvasiveCount)',
                    ),
                    const SizedBox(width: 8),
                    if (heroEvasiveAvoided)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Avoided (0 DMG)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8f43ff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onUseHeroEvasive,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (showHeroFlightRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (flightAvoided || flightUndefendable)
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (flightAvoided || flightUndefendable)
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Flight',
                      tokenAsset: 'assets/token/Flight.png',
                      text: 'Flight (x$heroFlightCount)',
                    ),
                    const SizedBox(width: 8),
                    if (flightAvoided || flightUndefendable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              flightAvoided
                                  ? 'Avoided (0 DMG)'
                                  : 'Undefendable',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8f43ff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onUseHeroFlight,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (showHeroAgilityRow) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff1f1b2e),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: heroAgilityActive
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Agility',
                      tokenAsset: 'assets/token/Agility.webp',
                      text: 'Agility (x$heroAgilityCount)',
                    ),
                    const SizedBox(width: 8),
                    if (heroAgilityActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              heroAgilitySuccesses >= 2
                                  ? 'Avoided (0 DMG)'
                                  : (heroAgilitySuccesses == 1
                                        ? 'Half DMG (-$heroAgilityPrevented)'
                                        : 'Failed (0 prevented)'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (heroAgilityCount > 0 && heroAgilitySuccesses < 2) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: onUseHeroAgility,
                          child: const Text(
                            'Use',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ] else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8f43ff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onUseHeroAgility,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (showHeroShadowsRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff132b1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Shadows',
                      tokenAsset: 'assets/token/Shadows.png',
                      text: heroShadowsCount > 1
                          ? 'Shadows (x$heroShadowsCount)'
                          : 'Shadows',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showBarbedVineRow) ...[
              const SizedBox(height: 6),
              _MultiRollTokenActiveRow(ownerAsset: attackerAsset,
                tokenLabel: 'Barbed Vine',
                tokenAsset: 'assets/token/Barbed-Vine.png',
                count: barbedVineCount,
                color: isHeroTurn
                    ? const Color(0xff8f43ff)
                    : Colors.greenAccent,
                onUse: isHeroTurn ? onUseBarbedVine : null,
                isUsed: barbedVineUsed,
              ),
            ],
            if (showConstrictRow) ...[
              const SizedBox(height: 6),
              _MultiRollTokenActiveRow(ownerAsset: attackerAsset,
                tokenLabel: 'Constrict',
                count: constrictCount,
                tokenAsset: 'assets/token/Constrict.png',
                color: isHeroTurn
                    ? const Color(0xff8f43ff)
                    : Colors.greenAccent,
                onUse: isHeroTurn ? onUseConstrict : null,
                isUsed: constrictUsed,
              ),
            ],
            if (critUsed ||
                (phase == CombatPhase.minionAttack &&
                    attackerCritCount > 0 &&
                    attackValue > 0))
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Crit',
                tokenAsset: 'assets/token/crit.png',
                activeText: 'Active (+ 4 DMG)',
              ),
            for (final val in usedDamageBonus)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Damage bonus $val',
                tokenAsset: 'assets/token/bonus-atk-$val.webp',
                activeText: 'Active (+$val DMG)',
              ),
            if (phase == CombatPhase.minionAttack && attackValue > 0)
              for (final val in availableDamageBonus)
                _ActiveTokenBadge(ownerAsset: attackerAsset,
                  tokenLabel: 'Damage bonus $val',
                  tokenAsset: 'assets/token/bonus-atk-$val.webp',
                  activeText: 'Active (+$val DMG)',
                ),
            if (honorDamageBonus > 0)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Honor',
                tokenAsset: 'assets/token/honor.png',
                activeText: 'Active (+$honorDamageBonus DMG)',
              ),
            if (ninjitsuDamageBonus > 0 || ninjitsuUndefendable)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Ninjitsu',
                tokenAsset: 'assets/token/ninjitsu.png',
                activeText: ninjitsuUndefendable
                    ? 'Active (Undefendable)'
                    : 'Active (+$ninjitsuDamageBonus DMG)',
              ),
            if (realityWarpActive)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Reality Warp',
                tokenAsset: 'assets/token/reality-warp.webp',
              ),
            if (silenceActive)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Silence',
                tokenAsset: 'assets/token/Silence.webp',
              ),
            if (webbedActive)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Webbed',
                tokenAsset: 'assets/token/Webbed.webp',
              ),
            if (flightAvoided || flightUndefendable)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Flight',
                tokenAsset: 'assets/token/Flight.png',
                activeText: flightAvoided
                    ? 'Active (Avoided)'
                    : 'Active (Undefendable)',
              ),
            if (showBlindingLightRow)
              _ActiveTokenBadge(ownerAsset: attackerAsset,
                tokenLabel: 'Blinding Light',
                tokenAsset: 'assets/token/Blinding Light.webp',
              ),
            if (showDecrepifyRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff132b1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const _ActionRowLabel(
                      tokenLabel: 'Decrep-ify',
                      tokenAsset: 'assets/token/Decrep-ify.png',
                      text: 'Decrep-ify',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showDiceCubeRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff132b1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Dice cube',
                      tokenAsset: 'assets/token/Dice cube.webp',
                      text: diceCubeCount > 1
                          ? 'Dice cube (x$diceCubeCount)'
                          : 'Dice cube',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showEntangleRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff132b1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Entangle',
                      tokenAsset: 'assets/token/Entangle.png',
                      text: entangleCount > 1
                          ? 'Entangle (x$entangleCount) (-1 Roll)'
                          : 'Entangle (-1 Roll)',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showInfluenceRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff132b1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const _ActionRowLabel(
                      tokenLabel: 'Influence',
                      tokenAsset: 'assets/token/influence.webp',
                      text: 'Influence',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.greenAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active (-$influenceRollReduction roll attempt${influenceRollReduction > 1 ? 's' : ''})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showSneakAttackRow) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: attackerSneakAttackActive
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: attackerSneakAttackActive
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Sneak Attack',
                      tokenAsset: 'assets/token/Sneak-Attack.png',
                      text: attackerSneakAttackCount > 1
                          ? 'Sneak Attack (x$attackerSneakAttackCount)'
                          : 'Sneak Attack',
                    ),
                    const SizedBox(width: 8),
                    if (attackerSneakAttackActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active (+$attackerSneakAttackBonus DMG)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUseAttackerSneakAttack
                              ? const Color(0xff8f43ff)
                              : Colors.grey.shade700,
                          foregroundColor: canUseAttackerSneakAttack
                              ? Colors.white
                              : Colors.white38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: canUseAttackerSneakAttack
                            ? onUseAttackerSneakAttack
                            : null,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (showGuardBreakRow)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Guard Break',
                tokenAsset: 'assets/token/Guard-Break.png',
                text: attackerGuardBreakCount > 1
                    ? 'Guard Break (x)'
                    : 'Guard Break',
                isActive: guardBreakSuccess,
                activeText: 'Active (Undefendable)',
                showUseButton: !guardBreakSuccess,
                canUse: canUseAttackerGuardBreak,
                onUse: onUseAttackerGuardBreak,
              ),
            if (windShearCount > 0 || windShearActive)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Wind Shear',
                tokenAsset: 'assets/token/wind-shear.webp',
                text: windShearCount > 1 ? 'Wind Shear (x)' : 'Wind Shear',
                isActive: windShearActive,
                activeText: '+2 DEF / 2 DMG imparables',
                showUseButton: !windShearActive,
                canUse: canUseWindShear,
                onUse: onUseWindShear,
              ),
            if (defenderPreyCount > 0)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Prey',
                tokenAsset: 'assets/token/Prey.png',
                text: preyUsedCount > 0 ? 'Prey (Used /)' : 'Prey (/)',
                isActive: preyUsedCount > 0,
                activeText: 'Active',
                showUseButton: preyUsedCount < defenderPreyCount,
                canUse: canUsePrey,
                onUse: onUsePrey,
              ),
            if (attackerCritCount > 0 || critUsed)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Crit',
                tokenAsset: 'assets/token/Crit.png',
                text: attackerCritCount > 1 ? 'Crit (x)' : 'Crit',
                isActive: critUsed,
                activeText: 'Active (Auto-crit)',
                showUseButton: !critUsed,
                canUse: canUseCrit,
                onUse: onUseCrit,
              ),
            if (attackerAccuracyCount > 0 || accuracyUsed)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Accuracy',
                tokenAsset: 'assets/token/Accuracy.png',
                text: attackerAccuracyCount > 1 ? 'Accuracy (x)' : 'Accuracy',
                isActive: accuracyUsed,
                activeText: 'Active (Undefendable)',
                showUseButton: !accuracyUsed,
                canUse: canUseAccuracy,
                onUse: onUseAccuracy,
              ),
            if (honorCount > 0 &&
                phase == CombatPhase.hero &&
                honorDamageBonus == 0)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Honor',
                tokenAsset: 'assets/token/honor.png',
                text: honorCount > 1 ? 'Honor (x)' : 'Honor',
                isActive: false,
                activeText: '',
                showUseButton: true,
                canUse: onUseHonor != null,
                onUse: onUseHonor,
              ),
            if (ninjitsuDamageBonus > 0 ||
                ninjitsuUndefendable ||
                (ninjitsuCount > 0 && phase == CombatPhase.hero))
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Ninjitsu',
                tokenAsset: 'assets/token/Ninjutsu.webp',
                text: ninjitsuCount > 1 ? 'Ninjitsu (x)' : 'Ninjitsu',
                isActive: ninjitsuDamageBonus > 0 || ninjitsuUndefendable,
                activeText: ninjitsuUndefendable
                    ? 'Active (Undefendable)'
                    : 'Active (+ DMG)',
                showUseButton: ninjitsuCount > 0,
                canUse: onUseNinjitsu != null,
                onUse: onUseNinjitsu,
              ),
            if (salveCount > 0)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Salve',
                tokenAsset: 'assets/token/Salve.png',
                text: salveCount > 1 ? 'Salve (x)' : 'Salve',
                isActive: false,
                activeText: '',
                showUseButton: true,
                canUse: onUseSalve != null,
                onUse: onUseSalve,
              ),
            if (smokeBombCount > 0 || smokeBombSuccess)
              _TokenActionRow(ownerAsset: attackerAsset,
                tokenLabel: 'Smoke Bomb',
                tokenAsset: 'assets/token/bombe-fumigene.png',
                text: smokeBombCount > 1 ? 'Smoke Bomb (x)' : 'Smoke Bomb',
                isActive: smokeBombSuccess,
                activeText: 'Active (Avoids DMG)',
                showUseButton: !smokeBombSuccess,
                canUse: onUseSmokeBomb != null,
                onUse: onUseSmokeBomb,
              ),
            if (protectUsed ||
                minionAutoProtect ||
                (protectCount > 0 && phase == CombatPhase.minionAttack)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (protectUsed || minionAutoProtect)
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (protectUsed || minionAutoProtect)
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Protect',
                      tokenAsset: 'assets/token/Protect.png',
                      text: 'Protection',
                    ),
                    const SizedBox(width: 8),
                    if (protectUsed || minionAutoProtect)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (protectCount > 0 &&
                        phase == CombatPhase.minionAttack &&
                        !protectUsed)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onUseProtect != null
                                ? const Color(0xff8f43ff)
                                : Colors.grey.shade700,
                            foregroundColor: onUseProtect != null
                                ? Colors.white
                                : Colors.white38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onUseProtect,
                          child: const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (retributionUsed ||
                minionAutoRetribution ||
                (retributionCount > 0 &&
                    phase == CombatPhase.minionAttack)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (retributionUsed || minionAutoRetribution)
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (retributionUsed || minionAutoRetribution)
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Retribution',
                      tokenAsset: 'assets/token/Retribution.png',
                      text: 'RÃ©tribution',
                    ),
                    const SizedBox(width: 8),
                    if (retributionUsed || minionAutoRetribution)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active (+${(attackValue / 2.0).ceil()} DMG)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (retributionCount > 0 &&
                        phase == CombatPhase.minionAttack &&
                        !retributionUsed)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: onUseRetribution != null
                                ? const Color(0xff8f43ff)
                                : Colors.grey.shade700,
                            foregroundColor: onUseRetribution != null
                                ? Colors.white
                                : Colors.white38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: onUseRetribution,
                          child: const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (attackerCritCount > 0 &&
                !(critUsed ||
                    (phase == CombatPhase.minionAttack &&
                        attackValue > 0))) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: critUsed
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: critUsed
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Crit',
                      tokenAsset: 'assets/token/crit.png',
                      text: 'Crit',
                    ),
                    const SizedBox(width: 8),
                    if (critUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Active (+4 DMG)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!critUsed && phase == CombatPhase.hero)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUseCrit
                              ? const Color(0xff8f43ff)
                              : Colors.grey.shade700,
                          foregroundColor: canUseCrit
                              ? Colors.white
                              : Colors.white38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: canUseCrit ? onUseCrit : null,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Builder(
              builder: (context) {
                final rows = <Widget>[];
                final unallocatedUsed = List.of(usedDamageBonus);
                for (final val in availableDamageBonus) {
                  final isUsed = unallocatedUsed.remove(val);
                  final isAutoApplied =
                      phase == CombatPhase.minionAttack && attackValue > 0;
                  if (isUsed || isAutoApplied) continue;

                  final canUseThis =
                      !isUsed &&
                      phase == CombatPhase.hero &&
                      onUseDamageBonus != null;
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUsed
                              ? const Color(0xff132b1e)
                              : const Color(0xff1f1a2e),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUsed
                                ? Colors.greenAccent.withValues(alpha: 0.6)
                                : const Color(
                                    0xff8f43ff,
                                  ).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            _ActionRowLabel(
                              tokenLabel: 'Damage bonus $val',
                              tokenAsset: 'assets/token/bonus-atk-$val.webp',
                              text: 'DÃ©gÃ¢t bonus $val',
                            ),
                            const SizedBox(width: 8),
                            if (isUsed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Colors.greenAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Active (+$val DMG)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isUsed && phase == CombatPhase.hero)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: onUseDamageBonus != null
                                      ? const Color(0xff8f43ff)
                                      : Colors.grey.shade700,
                                  foregroundColor: onUseDamageBonus != null
                                      ? Colors.white
                                      : Colors.white38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: onUseDamageBonus != null
                                    ? () => onUseDamageBonus!(val)
                                    : null,
                                child: const Text(
                                  'Use',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
            if (windShearCount > 0 || windShearActive) ...[
              const SizedBox(height: 8),
              if (windShearActive)
                _ActiveTokenBadge(ownerAsset: attackerAsset,
                  tokenLabel: 'Wind Shear',
                  tokenAsset: 'assets/token/wind-shear.webp',
                  activeText: '+2 DEF / Counter 2 DMG',
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff1f1a2e),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff3b315b)),
                  ),
                  child: Row(
                    children: [
                      _ActionRowLabel(
                        tokenLabel: 'Wind Shear',
                        tokenAsset: 'assets/token/wind-shear.webp',
                        text: 'Wind Shear (' + windShearCount.toString() + ')',
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff3b315b),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: canUseWindShear ? onUseWindShear : null,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (defenderPreyCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: preyUsedCount > 0
                      ? const Color(0xff132b1e)
                      : const Color(0xff1f1a2e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: preyUsedCount > 0
                        ? Colors.greenAccent.withValues(alpha: 0.6)
                        : const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    _ActionRowLabel(
                      tokenLabel: 'Prey',
                      tokenAsset: 'assets/token/Prey.png',
                      text: preyUsedCount > 0
                          ? 'Prey (Used $preyUsedCount/$defenderPreyCount)'
                          : 'Prey ($preyUsedCount/$defenderPreyCount)',
                    ),
                    const Spacer(),
                    if (preyUsedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (preyUsedCount > 0 && preyUsedCount < defenderPreyCount)
                      const SizedBox(width: 8),
                    if (preyUsedCount < defenderPreyCount)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUsePrey
                              ? const Color(0xff8f43ff)
                              : Colors.grey.shade700,
                          foregroundColor: canUsePrey
                              ? Colors.white
                              : Colors.white38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: canUsePrey ? onUsePrey : null,
                        child: const Text(
                          'Use',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: showBlindingLightAttackCover
                      ? SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff8f43ff),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            onPressed: onBlindingLightPressed,
                            icon: Image.asset(
                              'assets/token/Blinding-Light.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (ctx, err, stack) =>
                                  const Icon(Icons.flash_off, size: 20),
                            ),
                            label: const Text(
                              'Blinding Light',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : (showParlayAttackCover ||
                            smokeBombSuccess ||
                            showShadowsAttackCover ||
                            showFlightAttackCover ||
                            showEvasiveAttackCover)
                      ? SizedBox(
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: showParlayAttackCover
                                  ? Colors.orange.shade800
                                  : attackColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  showParlayAttackCover
                                      ? 'assets/token/Parlay.png'
                                      : smokeBombSuccess
                                      ? 'assets/token/Smoke-Bomb.png'
                                      : showShadowsAttackCover
                                      ? 'assets/token/Shadows.png'
                                      : showFlightAttackCover
                                      ? 'assets/token/Flight.png'
                                      : (isAgilityAvoided
                                            ? 'assets/token/Agility.webp'
                                            : 'assets/token/Evasive.png'),
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                    showParlayAttackCover
                                        ? Icons.block
                                        : smokeBombSuccess
                                        ? Icons.cloud_off
                                        : showShadowsAttackCover
                                        ? Icons.cloud
                                        : showFlightAttackCover
                                        ? Icons.air
                                        : Icons.air,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    showParlayAttackCover
                                        ? 'PARLAY: NO DAMAGE DEALT'
                                        : smokeBombSuccess
                                        ? 'ATTACK AVOIDED (SMOKE BOMB)'
                                        : showShadowsAttackCover
                                        ? 'ATTACK AVOIDED (SHADOWS)'
                                        : showFlightAttackCover
                                        ? 'ATTACK AVOIDED (FLIGHT)'
                                        : (isAgilityAvoided
                                              ? 'ATTACK AVOIDED (AGILITY)'
                                              : 'ATTACK AVOIDED (EVASIVE)'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _BattleCounter(
                          label: 'ATK',
                          value: blindingLightReducedDamage > 0
                              ? blindingLightBaseAttack
                              : attackValue,
                          modifier: blindingLightReducedDamage > 0
                              ? -blindingLightReducedDamage
                              : attackModifier,
                          color: blindingLightZeroDamage
                              ? Colors.greenAccent
                              : attackColor,
                          isLocked: blindingLightZeroDamage,
                          onChanged: blindingLightZeroDamage
                              ? (_) {}
                              : onAttackChanged,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: showBlindButton
                      ? SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: defenseColor,
                              disabledBackgroundColor: defenseColor.withValues(
                                alpha: 0.3,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            onPressed: attackValue > 0 ? onBlindPressed : null,
                            icon: Image.asset(
                              'assets/token/Blind.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (ctx, err, stack) =>
                                  const Icon(Icons.visibility_off, size: 20),
                            ),
                            label: const Text(
                              'Blind',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : (showStunCover ||
                            showWebbedAttackCover ||
                            flightUndefendable)
                      ? SizedBox(
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  (showWebbedAttackCover || flightUndefendable)
                                  ? Colors.blue.shade900
                                  : defenseColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  showWebbedAttackCover
                                      ? 'assets/token/Webbed.webp'
                                      : flightUndefendable
                                      ? 'assets/token/Flight.png'
                                      : 'assets/token/stun.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                    (showWebbedAttackCover ||
                                            flightUndefendable)
                                        ? Icons.pest_control
                                        : Icons.flash_on,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    showWebbedAttackCover
                                        ? 'ATTACK UNDEFENDABLE (WEBBED)'
                                        : flightUndefendable
                                        ? 'ONLY CARDS'
                                        : 'Stun',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : showOnlyCardsCover
                      ? SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: defenseColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            onPressed: onOnlyCardsUnlock,
                            child: const Text(
                              'Only cards',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      : _BattleCounter(
                          label: 'DEF',
                          value: defenseValue,
                          modifier: defenseModifier,
                          color: defenseColor,
                          onChanged: onDefenseChanged,
                        ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        (((showBlindButton || showBlindingLightAttackCover) &&
                                attackValue > 0) ||
                            blockApply)
                        ? null
                        : onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff8f43ff),
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white38,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onFinish != null) ...[
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 210,
                child: ImageActionButton(
                  label: 'Finish',
                  icon: Icons.flag,
                  onPressed: onFinish!,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
