part of '../../main.dart';

class _CombatResolutionPanel extends StatelessWidget {
  const _CombatResolutionPanel({
    required this.adventure,
    required this.enemy,
    required this.allFightEnemiesDefeated,
    required this.onHistory,
    required this.onHomepage,
    required this.onRewardFinished,
    required this.onReview,
  });

  final AdventureState adventure;
  final EnemyNode enemy;
  final bool allFightEnemiesDefeated;
  final VoidCallback onHistory;
  final VoidCallback onHomepage;
  final VoidCallback onRewardFinished;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final heroDead = adventure.health <= 0;
    final enemyDead = enemy.health <= 0;
    final isNaraxus = enemy.profileKey == 'naraxus';

    final String title;
    final Color titleColor;
    if (heroDead && enemyDead) {
      title = 'Tie!';
      titleColor = Colors.orange;
    } else if (heroDead) {
      title = 'Defeat!';
      titleColor = Colors.redAccent;
    } else {
      title = 'Victory!';
      titleColor = Colors.green;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
        ),
        if (heroDead && enemyDead && isNaraxus)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '50 Victory Points awarded for a tie against Naraxus!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        if (!heroDead && enemyDead && !isNaraxus && allFightEnemiesDefeated)
          RewardPanel(
            adventure: adventure,
            enemy: enemy,
            onFinished: onRewardFinished,
          )
        else
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onHistory,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8f43ff),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('History'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onHomepage,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8f43ff),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Homepage'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2d2342),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    side: const BorderSide(
                      color: Color(0xff8f43ff),
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TokenOrderingDialog extends StatefulWidget {
  const TokenOrderingDialog({
    required this.rules,
    required this.targetName,
    required this.isRollPhase,
    super.key,
  });

  final List<StatusTokenRule> rules;
  final String targetName;
  final bool isRollPhase;

  static Future<List<StatusTokenRule>?> show(
    BuildContext context, {
    required List<StatusTokenRule> rules,
    required String targetName,
    required bool isRollPhase,
  }) {
    return showDialog<List<StatusTokenRule>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TokenOrderingDialog(
        rules: rules,
        targetName: targetName,
        isRollPhase: isRollPhase,
      ),
    );
  }

  @override
  State<TokenOrderingDialog> createState() => _TokenOrderingDialogState();
}

class _TokenOrderingDialogState extends State<TokenOrderingDialog> {
  late List<StatusTokenRule> _orderedRules;

  @override
  void initState() {
    super.initState();
    _orderedRules = List<StatusTokenRule>.from(widget.rules);
    _orderedRules.sort((a, b) {
      final aFirst = _isFirstStrike(a.label);
      final bFirst = _isFirstStrike(b.label);
      if (aFirst && !bFirst) return -1;
      if (!aFirst && bFirst) return 1;
      return 0;
    });
  }

  bool _isFirstStrike(String label) {
    final l = label.toLowerCase();
    return l.contains('first strike') ||
        l.contains('premiÃ¨re frappe') ||
        l.contains('premiere frappe') ||
        l.contains('1st frappe') ||
        l.contains('1er frappe');
  }

  void _moveUp(int index) {
    if (index > 0) {
      if (_isFirstStrike(_orderedRules[index - 1].label)) return;
      setState(() {
        final item = _orderedRules.removeAt(index);
        _orderedRules.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _orderedRules.length - 1) {
      if (_isFirstStrike(_orderedRules[index].label)) return;
      setState(() {
        final item = _orderedRules.removeAt(index);
        _orderedRules.insert(index + 1, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = widget.isRollPhase ? 'Roll Phase' : 'Upkeep Phase';
    return AlertDialog(
      backgroundColor: const Color(0xff181424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff8f43ff), width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff8f43ff).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alt_route,
                      color: Color(0xff8f43ff),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Token Resolution Order',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Target: ${widget.targetName} â€¢ $phaseLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Timeline sequence overview bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _orderedRules.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Color(0xff8f43ff),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff2a2240),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xff8f43ff,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${i + 1}. ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff8f43ff),
                                ),
                              ),
                              Text(
                                _orderedRules
                                            .where(
                                              (r) =>
                                                  r.label ==
                                                  _orderedRules[i].label,
                                            )
                                            .length >
                                        1
                                    ? '${_orderedRules[i].label} #${_orderedRules.sublist(0, i + 1).where((r) => r.label == _orderedRules[i].label).length}'
                                    : _orderedRules[i].label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
              const SizedBox(height: 12),
              const Text(
                'Choose the execution order of tokens:',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // List of tokens with ordering buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    var index = 0;
                    index < _orderedRules.length;
                    index++
                  ) ...[
                    Builder(
                      builder: (context) {
                        final rule = _orderedRules[index];
                        final imageAsset = rule.imageAsset;
                        final displayLabel =
                            _orderedRules
                                    .where((r) => r.label == rule.label)
                                    .length >
                                1
                            ? '${rule.label} #${_orderedRules.sublist(0, index + 1).where((r) => r.label == rule.label).length}'
                            : rule.label;
                        return Container(
                          key: ValueKey('${rule.label}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff251d38),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xff8f43ff,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff8f43ff),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (imageAsset != null && imageAsset.isNotEmpty)
                                Image.asset(
                                  imageAsset,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.stars,
                                    size: 24,
                                    color: Color(0xff8f43ff),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.stars,
                                  size: 24,
                                  color: Color(0xff8f43ff),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayLabel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (rule.description.isNotEmpty)
                                      Text(
                                        rule.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 20,
                                ),
                                color:
                                    (index > 0 &&
                                        !_isFirstStrike(
                                          _orderedRules[index - 1].label,
                                        ))
                                    ? Colors.white70
                                    : Colors.white24,
                                onPressed:
                                    (index > 0 &&
                                        !_isFirstStrike(
                                          _orderedRules[index - 1].label,
                                        ))
                                    ? () => _moveUp(index)
                                    : null,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                                color:
                                    (index < _orderedRules.length - 1 &&
                                        !_isFirstStrike(rule.label))
                                    ? Colors.white70
                                    : Colors.white24,
                                onPressed:
                                    (index < _orderedRules.length - 1 &&
                                        !_isFirstStrike(rule.label))
                                    ? () => _moveDown(index)
                                    : null,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8f43ff),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text(
                  'Confirm Order',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.of(context).pop(_orderedRules),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TokenAnimationResult {
  const TokenAnimationResult({
    required this.count,
    this.dontShowAgain = false,
    this.dieRoll,
    this.spentCount = 1,
    this.agilitySuccessCount,
    this.allDiceRolls,
    this.sneakAttackBonus,
    this.preyBonus,
    this.customAction,
  });

  final int count;
  final bool dontShowAgain;
  final int? dieRoll;
  final int spentCount;
  final int? agilitySuccessCount;
  final List<int>? allDiceRolls;
  final int? sneakAttackBonus;
  final int? preyBonus;
  final String? customAction;
}

class TokenAnimationDialog extends StatefulWidget {
  const TokenAnimationDialog({
    required this.rule,
    this.initialCount = 1,
    this.targetName = '',
    this.isMinion = false,
    this.customMessage,
    this.customMessageWidget,
    this.currentHp,
    this.currentCp,
    super.key,
  });

  final StatusTokenRule rule;
  final int initialCount;
  final String targetName;
  final bool isMinion;
  final String? customMessage;
  final Widget? customMessageWidget;
  final int? currentHp;
  final int? currentCp;

  static Future<TokenAnimationResult?> show(
    BuildContext context, {
    required StatusTokenRule rule,
    int initialCount = 1,
    String targetName = '',
    bool isMinion = false,
    String? customMessage,
    Widget? customMessageWidget,
    int? currentHp,
    int? currentCp,
  }) {
    return showDialog<TokenAnimationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TokenAnimationDialog(
        rule: rule,
        initialCount: initialCount,
        targetName: targetName,
        isMinion: isMinion,
        customMessage: customMessage,
        customMessageWidget: customMessageWidget,
        currentHp: currentHp,
        currentCp: currentCp,
      ),
    );
  }

  static int computeCosmicFlareDamage(int count) => count;

  @override
  State<TokenAnimationDialog> createState() => _TokenAnimationDialogState();
}

class _TokenAnimationDialogState extends State<TokenAnimationDialog> {
  late int _count;
  int _spentCount = 1;
  bool _editing = false;
  bool _dontShowAgain = false;
  int? _blindDieRoll;
  int? _secondDieRoll;
  int? _firstAgilityRoll;
  int? _firstBleedRoll;
  final List<int> _previousRolls = [];
  int _blindRollTick = 0;
  bool _manualEditBlind = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount.clamp(0, widget.rule.maxStack);
  }

  int _computeHpDelta(int count) {
    final l = widget.rule.label.toLowerCase();
    if (l == 'regenerate 2' || l == 'régénération 2') {
      return count * 2;
    }
    if (l == 'regenerate' || l == 'régénération') {
      return count * 1;
    }
    if (l == 'salve' || l == 'salvo') {
      return 6;
    }
    if (l.contains('delayed poison') ||
        l.contains('poison latent') ||
        l.contains('poison retardÃ©') ||
        l.contains('poison diffÃ©rÃ©')) {
      return -count * 3;
    }
    if (l.contains('poison') ||
        l.contains('cosmic flare') ||
        l.contains('lueur cosmique')) {
      return -count;
    }
    if (l == 'parasite') {
      return -1;
    }
    if (l == 'wound') {
      return -count;
    }
    final isTimeBomb2 =
        l.contains('time bomb 2') ||
        l.contains('bombe Ã  retardement 2') ||
        (l.contains('time bomb') && !l.contains('1'));
    if (isTimeBomb2 && _blindDieRoll != null && _blindDieRoll! <= 5) {
      return -4;
    }
    if (l.contains('brÃ»lure') || l.contains('brulure') || l.contains('burn')) {
      return count > 0 ? -2 : 0;
    }
    if (l == 'bleed' ||
        l == 'hÃ©morragie' ||
        l == 'hemorragie' ||
        l == 'saignement') {
      if (_blindDieRoll == null && _previousRolls.isEmpty) return 0;
      var dmg = 0;
      for (final r in _previousRolls) {
        if (r <= 4) dmg++;
      }
      if (_blindDieRoll != null && _blindDieRoll! <= 4) dmg++;
      return -dmg;
    }
    if (l == 'wellspring' || l == 'source') {
      if (_blindDieRoll != null) return (_blindDieRoll! / 2.0).ceil();
      return 0;
    }
    if (l.contains('powder keg') || l.contains('baril de poudre')) {
      if (_blindDieRoll != null && _blindDieRoll! <= 2) return -3;
      if (_blindDieRoll == null &&
          widget.customMessage != null &&
          widget.customMessage!.contains('blows up')) {
        return -3;
      }
    }
    return 0;
  }

  int _computeCpDelta(int count) {
    final l = widget.rule.label.toLowerCase();
    if (l == 'knockdown' || l == 'mise Ã  terre') {
      return -2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final title = rule.label;
    final imageAsset = rule.imageAsset;
    final baseDesc = rule.description.isNotEmpty
        ? rule.description
        : rule.appDetails;
    final description = widget.customMessage != null
        ? '${widget.customMessage}\n\n$baseDesc'
        : baseDesc;

    final l = rule.label.toLowerCase();
    final isCoal = l == 'coal' || l == 'charbon';
    final isConcussion = l.contains('concussion') || l.contains('commotion');
    final isKnockdown = l.contains('knockdown') || l.contains('terre');
    final isBlindingLight =
        l.contains('blinding light') ||
        l.contains('blindinglight') ||
        l.contains('lumiÃ¨re aveuglante') ||
        l.contains('lumiere aveuglante');
    final isBlind =
        !isBlindingLight &&
        (l.contains('blind') ||
            l.contains('Ã©blouissement') ||
            l.contains('eblouissement'));
    final isEvasive = l.contains('evasive') || l.contains('evitement');
    final isFlight = l.contains('flight') || l.contains('vol');
    final isAgility =
        l.contains('agility') || l.contains('agilitÃ©') || l.contains('agilite');
    final isTimeBomb1 =
        l.contains('time bomb 1') || l.contains('bombe Ã  retardement 1');
    final isTimeBomb2 =
        l.contains('time bomb 2') ||
        l.contains('bombe Ã  retardement 2') ||
        (l.contains('time bomb') && !isTimeBomb1);
    final isBleed =
        l == 'bleed' ||
        l == 'hÃ©morragie' ||
        l == 'hemorragie' ||
        l == 'saignement';
    final isSneakAttack =
        l.contains('sneak attack') || l.contains('attaque furtive');
    final isWellspring = l.contains('wellspring') || l.contains('source');
    final isRiposte =
        l.contains('riposte') ||
        l.contains('back strike') ||
        l.contains('backstrike');
    final isPhoenixBurn = l.contains('phoenix burn');
    final isPowderKeg =
        l.contains('powder keg') || l.contains('baril de poudre');
    final isNanite = l.contains('nanite');
    final isWound = l == 'wound';
    final isPrey = l.contains('prey') || l.contains('proie');
    final isBagOfTricks =
        l.contains('bag of tricks') ||
        l.contains('sac Ã  malice') ||
        l.contains('sac a malice');
    final isChargedGem =
        l.contains('charged gem') ||
        l.contains('gemme chargÃ©e') ||
        l.contains('gemme chargee');
    final isCosmicFlare =
        l.contains('cosmic flare') || l.contains('lueur cosmique');
    final isDisarm =
        l.contains('disarm') ||
        l.contains('dÃ©sarmement') ||
        l.contains('desarmement');
    final isDisruption = l.contains('disruption') || l.contains('perturbation');
    final isNinjitsu = l.contains('ninjitsu') || l.contains('ninjutsu');
    final isSmokeBomb =
        l.contains('smoke bomb') ||
        l.contains('bombe fumigene') ||
        l.contains('bombe fumigÃ¨ne');
    final isDieRollToken =
        (widget.customMessage == null) &&
        (isBlind ||
            isFlight ||
            isEvasive ||
            isAgility ||
            isTimeBomb1 ||
            isTimeBomb2 ||
            isBleed ||
            isSneakAttack ||
            isWellspring ||
            isRiposte ||
            isBlindingLight ||
            isPhoenixBurn ||
            isPowderKeg ||
            isNanite ||
            isWound ||
            isPrey ||
            isChargedGem ||
            isBagOfTricks ||
            l == 'influence' ||
            l.contains('guard break') ||
            l.contains('brisegarde') ||
            l.contains('brise garde') ||
            isNinjitsu ||
            isSmokeBomb);
    final isGuardBreak =
        l.contains('guard break') ||
        l.contains('brisegarde') ||
        l.contains('brise garde');
    final isInfluence = l == 'influence';
    final isFirstStrike =
        l.contains('first strike') ||
        l.contains('premiÃ¨re frappe') ||
        l.contains('premiere frappe') ||
        l.contains('1st frappe') ||
        l.contains('1er frappe');
    final isEntangle = l.contains('entangle') || l.contains('enchevetrement');
    final isHex = l.contains('hex') || l.contains('malefice');
    final isTargeted = l.contains('targeted') || l.contains('prispourcible');
    final isBarbedVine =
        l.contains('barbed vine') ||
        l.contains('barbedvine') ||
        l.contains('ronces') ||
        l.contains('ronce');
    final isConstrict = l.contains('constrict') || l.contains('compression');
    final isDecrepify =
        l.contains('decrepify') ||
        l.contains('decrepitude') ||
        l.contains('decrep-ify');
    final isDiceCube = l.contains('dice cube') || l.contains('cube');
    final isRealityWarp = _isRealityWarpToken(l);
    final isShame = _isShameToken(l);
    final isSilence = l == 'silence';
    final isInfoOnly =
        isFirstStrike ||
        isEntangle ||
        isHex ||
        isTargeted ||
        isBarbedVine ||
        isConstrict ||
        isDecrepify ||
        isDiceCube ||
        isRealityWarp ||
        isShame ||
        isSilence;

    final hpDelta = _computeHpDelta(_count);
    final cpDelta = _computeCpDelta(_count);

    final hasHpChange = widget.currentHp != null && hpDelta != 0;
    final hasCpChange =
        (widget.currentCp != null && cpDelta != 0) ||
        (isConcussion && widget.currentCp != null) ||
        (isCoal && _count >= 4 && widget.currentCp != null);

    final oldHp = widget.currentHp;
    final newHp = oldHp != null ? (oldHp + hpDelta).clamp(0, 99) : null;

    final oldCp = widget.currentCp;
    final newCp = oldCp != null
        ? ((isConcussion || isCoal) ? oldCp : (oldCp + cpDelta).clamp(0, 99))
        : null;

    return AlertDialog(
      backgroundColor: const Color(0xff181424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff8f43ff), width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: isDieRollToken ? 340 : 300,
          maxWidth: isDieRollToken ? 460 : 380,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  if (imageAsset != null && imageAsset.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff2a2240),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff8f43ff,
                            ).withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        imageAsset,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.stars,
                          size: 80,
                          color: Color(0xff8f43ff),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff2a2240),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff8f43ff,
                            ).withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stars,
                        size: 80,
                        color: Color(0xff8f43ff),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _count > 1 ? '$title (x$_count)' : title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.targetName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Triggered on ${widget.targetName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff8f43ff).withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.customMessageWidget != null) ...[
                    const SizedBox(height: 12),
                    widget.customMessageWidget!,
                  ],
                  if (isDieRollToken) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff251d38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xff8f43ff).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isBleed
                                ? (_spentCount > 1
                                      ? 'Bleed Roll 2 (1 D6)'
                                      : 'Bleed Roll (1 D6)')
                                : isEvasive
                                ? 'Evasive Roll (1 D6)'
                                : isAgility
                                ? (_spentCount > 1
                                      ? 'Agility Roll 2 (1 D6)'
                                      : 'Agility Roll (1 D6)')
                                : isInfluence
                                ? (_spentCount > 1
                                      ? 'Influence Roll $_spentCount (1 D6)'
                                      : 'Influence Roll (1 D6)')
                                : isSneakAttack
                                ? 'Sneak Attack Roll (1 D6)'
                                : isChargedGem
                                ? 'Charged Gem Roll (1 D6)'
                                : isBagOfTricks
                                ? 'Bag of Tricks Roll (1 D6)'
                                : isGuardBreak
                                ? 'Guard Break Roll (1 D6)'
                                : isPrey
                                ? 'Prey Roll (1 D6)'
                                : isBlind
                                ? 'Blind Roll (1 D6)'
                                : isWellspring
                                ? 'Wellspring Roll (1 D6)'
                                : isRiposte
                                ? 'Riposte Roll (1 D6)'
                                : isPhoenixBurn
                                ? 'Phoenix Burn Roll (1 D6)'
                                : isPowderKeg
                                ? 'Powder Keg Roll (1 D6)'
                                : isBlindingLight
                                ? 'Blinding Light Roll (1 D6)'
                                : isWound
                                ? 'Wound Roll (1 D6)'
                                : isTimeBomb1
                                ? 'Time Bomb 1 (1 D6)'
                                : isFlight
                                ? 'Flight Roll (2 D6)'
                                : isSmokeBomb
                                ? 'Smoke Bomb Roll (1 D6)'
                                : isNinjitsu
                                ? 'Ninjitsu Roll (1 D6)'
                                : 'Time Bomb 2 (1 D6)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isFlight)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DieTile(
                                  die: GameDie(id: 99)
                                    ..rollTick = _blindRollTick
                                    ..settled = true
                                    ..value = _blindDieRoll,
                                  onTap: () {
                                    setState(() {
                                      _blindRollTick++;
                                      _blindDieRoll = _random.nextInt(6) + 1;
                                      _manualEditBlind = false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 16),
                                DieTile(
                                  die: GameDie(id: 100)
                                    ..rollTick = _blindRollTick
                                    ..settled = true
                                    ..value = _secondDieRoll,
                                  onTap: () {
                                    setState(() {
                                      _blindRollTick++;
                                      _secondDieRoll = _random.nextInt(6) + 1;
                                      _manualEditBlind = false;
                                    });
                                  },
                                ),
                              ],
                            )
                          else
                            DieTile(
                              die: GameDie(id: 99)
                                ..rollTick = _blindRollTick
                                ..settled = true
                                ..value = _blindDieRoll,
                              onTap: () {
                                setState(() {
                                  _blindRollTick++;
                                  _blindDieRoll = _random.nextInt(6) + 1;
                                  _manualEditBlind = false;
                                });
                              },
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (_blindDieRoll == null)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff8f43ff),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _blindRollTick++;
                                      _blindDieRoll = _random.nextInt(6) + 1;
                                      if (isFlight) {
                                        _secondDieRoll = _random.nextInt(6) + 1;
                                      }
                                      _manualEditBlind = false;
                                    });
                                  },
                                  icon: const Icon(Icons.casino, size: 18),
                                  label: Text(
                                    (isRiposte || isChargedGem || isGuardBreak)
                                        ? 'Use'
                                        : 'Roll Die',
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xff8f43ff),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _blindRollTick++;
                                      _blindDieRoll = _random.nextInt(6) + 1;
                                      if (isFlight) {
                                        _secondDieRoll = _random.nextInt(6) + 1;
                                      }
                                      _manualEditBlind = false;
                                    });
                                  },
                                  icon: const Icon(Icons.casino, size: 18),
                                  label: const Text('Reroll Die'),
                                ),
                              if ((isRiposte || isChargedGem || isGuardBreak) &&
                                  _blindDieRoll == null)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xff8f43ff),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Do not use'),
                                ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xff8f43ff),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _manualEditBlind = !_manualEditBlind;
                                  });
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit Die'),
                              ),
                            ],
                          ),
                          if (_manualEditBlind) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (idx) {
                                final val = idx + 1;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _blindRollTick++;
                                        _blindDieRoll = val;
                                        _manualEditBlind = false;
                                      });
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _blindDieRoll == val
                                            ? const Color(0xff8f43ff)
                                            : const Color(0xff181424),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        '$val',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                          if (_blindDieRoll != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xf2121212),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isWellspring || isRiposte
                                      ? Colors.greenAccent
                                      : isNinjitsu
                                      ? const Color(0xff8f43ff)
                                      : isPowderKeg
                                      ? (_blindDieRoll! <= 2
                                            ? Colors.redAccent
                                            : (_blindDieRoll! == 6
                                                  ? Colors.orangeAccent
                                                  : Colors.grey))
                                      : isNanite
                                      ? (_blindDieRoll! == 6
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                      : isBlindingLight
                                      ? (_blindDieRoll == 1
                                            ? Colors.redAccent
                                            : (_blindDieRoll! <= 3
                                                  ? Colors.orangeAccent
                                                  : Colors.greenAccent))
                                      : isInfluence
                                      ? (_blindDieRoll! <= 3
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                      : isSneakAttack
                                      ? Colors.greenAccent
                                      : isBleed
                                      ? ((_spentCount == 2 &&
                                                _firstBleedRoll != null)
                                            ? (((_firstBleedRoll! <= 4
                                                              ? 1
                                                              : 0) +
                                                          (_blindDieRoll! <= 4
                                                              ? 1
                                                              : 0)) >
                                                      0
                                                  ? Colors.redAccent
                                                  : Colors.greenAccent)
                                            : (_blindDieRoll! <= 4
                                                  ? Colors.redAccent
                                                  : Colors.greenAccent))
                                      : isAgility
                                      ? ((_spentCount == 2 &&
                                                _firstAgilityRoll != null)
                                            ? (((_firstAgilityRoll! <= 3
                                                              ? 1
                                                              : 0) +
                                                          (_blindDieRoll! <= 3
                                                              ? 1
                                                              : 0)) >
                                                      0
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent)
                                            : (_blindDieRoll! <= 3
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent))
                                      : (isTimeBomb1 || isTimeBomb2)
                                      ? (_blindDieRoll! <= 5
                                            ? Colors.redAccent
                                            : Colors.greenAccent)
                                      : _blindDieRoll! <= 2
                                      ? (isEvasive
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                      : (isEvasive
                                            ? Colors.redAccent
                                            : Colors.greenAccent),
                                ),
                              ),
                              child: Text(
                                isWellspring
                                    ? 'Wellspring roll: $_blindDieRoll -> +${(_blindDieRoll! / 2.0).ceil()} Health restored!'
                                    : isRiposte
                                    ? 'Riposte roll: $_blindDieRoll -> Deals ${(_blindDieRoll! / 2.0).ceil()} damage to attacker!'
                                    : isPhoenixBurn
                                    ? (_blindDieRoll! >= 5
                                          ? 'Phoenix Burn roll: $_blindDieRoll -> Token removed!'
                                          : 'Phoenix Burn roll: $_blindDieRoll -> Token stays.')
                                    : isPowderKeg
                                    ? (_blindDieRoll! <= 2
                                          ? 'Powder Keg roll: $_blindDieRoll -> Keg blows up! (3 undefendable dmg)'
                                          : (_blindDieRoll! == 6
                                                ? 'Powder Keg roll: $_blindDieRoll -> Transfer to opponent!'
                                                : 'Powder Keg roll: $_blindDieRoll -> Nothing happens.'))
                                    : isNanite
                                    ? (_blindDieRoll! == 6
                                          ? 'Nanite roll: $_blindDieRoll -> Token removed!'
                                          : 'Nanite roll: $_blindDieRoll -> Token stays.')
                                    : isBlindingLight
                                    ? (_blindDieRoll == 1
                                          ? 'Blinding Light roll: 1 -> Attack fails to activate! (0 damage dealt)'
                                          : (_blindDieRoll! <= 3
                                                ? 'Blinding Light roll: $_blindDieRoll -> Attack damage reduced by 1/2 (rounded up)'
                                                : 'Blinding Light roll: $_blindDieRoll -> Attack succeeds normally! (Full damage)'))
                                    : isInfluence
                                    ? ((_spentCount > 1 &&
                                              _previousRolls.isNotEmpty)
                                          ? 'Influence rolls: ${[..._previousRolls, _blindDieRoll!].join(', ')} -> ${[..._previousRolls, _blindDieRoll!].where((r) => r <= 3).length} Successes!'
                                          : (_blindDieRoll! <= 3
                                                ? 'Influence roll: $_blindDieRoll -> Success! (-1 Roll attempt)'
                                                : 'Influence roll: $_blindDieRoll -> Failed!'))
                                    : isSneakAttack
                                    ? 'Sneak Attack roll: $_blindDieRoll -> +$_blindDieRoll Attack Modifier!'
                                    : isChargedGem
                                    ? (_blindDieRoll! <= 2
                                          ? 'Charged Gem roll: $_blindDieRoll -> Gain 1 CP'
                                          : (_blindDieRoll! <= 4
                                                ? 'Charged Gem roll: $_blindDieRoll -> Deal 2 Imparable dmg'
                                                : 'Charged Gem roll: $_blindDieRoll -> Gain 1 CP & Deal 2 Imparable dmg'))
                                    : isBagOfTricks
                                    ? (_blindDieRoll! == 1
                                          ? 'Bag of Tricks roll: 1 -> Lose 1 CP'
                                          : (_blindDieRoll! >= 6
                                                ? 'Bag of Tricks roll: 6 -> Gain 2 CP'
                                                : 'Bag of Tricks roll: $_blindDieRoll -> Please select an outcome below'))
                                    : isGuardBreak
                                    ? ((_blindDieRoll! == 4 ||
                                              _blindDieRoll! == 5)
                                          ? 'Guard Break roll: $_blindDieRoll -> Success! Attack becomes undefendable.'
                                          : 'Guard Break roll: $_blindDieRoll -> Failed.')
                                    : isPrey
                                    ? (_blindDieRoll! == 1
                                          ? 'Prey roll: 1 -> Token removed (0 damage)'
                                          : (_blindDieRoll! >= 6
                                                ? 'Prey roll: $_blindDieRoll -> +2 Damage!'
                                                : 'Prey roll: $_blindDieRoll -> +1 Damage!'))
                                    : isBleed
                                    ? ((_spentCount == 2 &&
                                              _firstBleedRoll != null)
                                          ? 'Bleed rolls: $_firstBleedRoll, $_blindDieRoll -> ${((_firstBleedRoll! <= 4 ? 1 : 0) + (_blindDieRoll! <= 4 ? 1 : 0))} Damage taken, ${((_firstBleedRoll! >= 5 ? 1 : 0) + (_blindDieRoll! >= 5 ? 1 : 0))} Token(s) removed'
                                          : (_blindDieRoll! <= 4
                                                ? 'Bleed roll: $_blindDieRoll -> Deals 1 Damage! Token remains.'
                                                : 'Bleed roll: $_blindDieRoll -> Token Removed! (0 Damage)'))
                                    : isAgility
                                    ? ((_spentCount == 2 &&
                                              _firstAgilityRoll != null)
                                          ? (((_firstAgilityRoll! <= 3
                                                            ? 1
                                                            : 0) +
                                                        (_blindDieRoll! <= 3
                                                            ? 1
                                                            : 0)) ==
                                                    2
                                                ? 'Agility rolls: $_firstAgilityRoll, $_blindDieRoll -> 2 Successes! Attack Avoided! (0 Damage taken)'
                                                : ((_firstAgilityRoll! <= 3
                                                              ? 1
                                                              : 0) +
                                                          (_blindDieRoll! <= 3
                                                              ? 1
                                                              : 0)) ==
                                                      1
                                                ? 'Agility rolls: $_firstAgilityRoll, $_blindDieRoll -> 1 Success! (1/2 damage prevented)'
                                                : 'Agility rolls: $_firstAgilityRoll, $_blindDieRoll -> Failed! (0 damage prevented)')
                                          : (_blindDieRoll! <= 3
                                                ? 'Agility roll: $_blindDieRoll -> Success! (1/2 damage prevented)'
                                                : (_spentCount < _count
                                                      ? 'Agility roll: $_blindDieRoll -> Failed. (${_count - _spentCount} token(s) remaining)'
                                                      : 'Agility roll: $_blindDieRoll -> Failed! (0 damage prevented)')))
                                    : isEvasive
                                    ? (_blindDieRoll! <= 2
                                          ? 'Evasive roll: $_blindDieRoll -> Attack Avoided! (0 Damage taken)'
                                          : (_spentCount < _count
                                                ? 'Evasive roll: $_blindDieRoll -> Failed. (${_count - _spentCount} token(s) remaining)'
                                                : 'Evasive roll: $_blindDieRoll -> Evasive Failed! (Normal damage applies)'))
                                    : isBlind
                                    ? (_blindDieRoll! <= 2
                                          ? 'Blind roll: $_blindDieRoll -> Attack Fails! (0 Damage)'
                                          : 'Blind roll: $_blindDieRoll -> Attack Touches! (Proceed with defense)')
                                    : isWound
                                    ? (_blindDieRoll! <= 3
                                          ? 'Wound roll: $_blindDieRoll -> Failed! (Token remains)'
                                          : 'Wound roll: $_blindDieRoll -> Success! (Token removed)')
                                    : isFlight
                                    ? ((_blindDieRoll == 6 ||
                                              _secondDieRoll == 6)
                                          ? 'Flight roll: [$_blindDieRoll, $_secondDieRoll] -> Success!'
                                          : 'Flight roll: [$_blindDieRoll, $_secondDieRoll] -> Failed.')
                                    : isNinjitsu
                                    ? (_blindDieRoll! <= 3
                                          ? 'Ninjitsu roll: $_blindDieRoll -> +1 Attack Damage!'
                                          : (_blindDieRoll! <= 5
                                                ? 'Ninjitsu roll: $_blindDieRoll -> +2 Attack Damage!'
                                                : 'Ninjitsu roll: 6 -> Roll 6! Choose reward: +2 DMG, Delayed Poison, or Undefendable.'))
                                    : isTimeBomb1
                                    ? (_blindDieRoll! <= 5
                                          ? 'Time bomb roll: $_blindDieRoll -> Transforms into Time Bomb 2!'
                                          : 'Time bomb roll: 6 -> Transferred to opponent!')
                                    : (_blindDieRoll! <= 5
                                          ? 'Time bomb roll: $_blindDieRoll -> Explodes!'
                                          : 'Time bomb roll: 6 -> Transferred to opponent!'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_editing &&
                      !isDieRollToken &&
                      !isInfoOnly &&
                      rule.maxStack > 1) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff251d38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff8f43ff)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Tokens: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _count > 0
                                  ? () => setState(() => _count--)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                  color: _count > 0
                                      ? Colors.redAccent
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '$_count',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _count < widget.rule.maxStack
                                  ? () => setState(() => _count++)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 22,
                                  color: _count < widget.rule.maxStack
                                      ? const Color(0xff8f43ff)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (hasHpChange || hasCpChange) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff251d38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xff8f43ff).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (hasHpChange)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'HP: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$oldHp',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: Color(0xff8f43ff),
                                    ),
                                  ),
                                  Text(
                                    '$newHp',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: newHp! < oldHp!
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (hasCpChange)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.flash_on,
                                        size: 16,
                                        color: Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'CP: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '$oldCp',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: Color(0xff8f43ff),
                                        ),
                                      ),
                                      Text(
                                        '$newCp',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isConcussion)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text(
                                        '(CP gain prevented)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  if (isCoal && _count >= 4)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text(
                                        '(+1 CP upkeep reduced by 1 âž” 0 CP gained)\nAll 4 Coal tokens removed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (rule.persistent &&
                      !isDieRollToken &&
                      !(isCoal && _count >= 4)) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () =>
                          setState(() => _dontShowAgain = !_dontShowAgain),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _dontShowAgain,
                              activeColor: const Color(0xff8f43ff),
                              onChanged: (val) =>
                                  setState(() => _dontShowAgain = val ?? false),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Hide future reminders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (!isDieRollToken && !isInfoOnly && rule.maxStack > 1)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xff8f43ff)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => setState(() => _editing = !_editing),
                          icon: Icon(
                            _editing ? Icons.check : Icons.edit,
                            size: 16,
                          ),
                          label: Text(_editing ? 'Hide' : 'Edit'),
                        ),
                      if (_blindDieRoll != null &&
                          ((isEvasive && _blindDieRoll! > 2) ||
                              isAgility ||
                              isBleed ||
                              isInfluence ||
                              isTimeBomb1 ||
                              isTimeBomb2 ||
                              isNanite) &&
                          _count > 1 &&
                          (_count - _spentCount) > 0)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xff8f43ff),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _previousRolls.add(_blindDieRoll!);
                              if (isAgility) {
                                _firstAgilityRoll ??= _blindDieRoll;
                              }
                              if (isBleed) {
                                _firstBleedRoll ??= _blindDieRoll;
                              }
                              _spentCount++;
                              _blindRollTick++;
                              _blindDieRoll =
                                  (isBleed ||
                                      isTimeBomb1 ||
                                      isTimeBomb2 ||
                                      isInfluence ||
                                      isNanite)
                                  ? null
                                  : (_random.nextInt(6) + 1);
                              _manualEditBlind = false;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(
                            (isBleed ||
                                    isTimeBomb1 ||
                                    isTimeBomb2 ||
                                    isInfluence ||
                                    isNanite)
                                ? ((_count - _spentCount) > 1
                                      ? 'Resolve next token (${_count - _spentCount})'
                                      : 'Resolve next token')
                                : ((_count - _spentCount) > 1
                                      ? 'Use again (${_count - _spentCount})'
                                      : 'Use again'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (isBagOfTricks &&
                          _blindDieRoll != null &&
                          _blindDieRoll! >= 2 &&
                          _blindDieRoll! <= 5) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'heal_2',
                            ),
                          ),
                          child: const Text('Heal 2 HP'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'gain_1_cp',
                            ),
                          ),
                          child: const Text('Gain 1 CP'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'receive_2_undefendable',
                            ),
                          ),
                          child: const Text('2 Imparable Dmg'),
                        ),
                      ] else if (isDisarm) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade800,
                            disabledForegroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: widget.isMinion
                              ? null
                              : () => Navigator.of(context).pop(
                                  TokenAnimationResult(
                                    count: (_count - 1).clamp(
                                      0,
                                      widget.rule.maxStack,
                                    ),
                                    dontShowAgain: _dontShowAgain,
                                    customAction: 'discard',
                                  ),
                                ),
                          child: const Text(
                            'Discard a card',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'skip_income',
                            ),
                          ),
                          child: const Text(
                            'Skip Income Phase',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ] else if (isDisruption) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'lose_cp',
                            ),
                          ),
                          child: const Text(
                            'Lose 1 CP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              ),
                              dontShowAgain: _dontShowAgain,
                              customAction: 'damage',
                            ),
                          ),
                          child: const Text(
                            'Receive 2 undefendable damage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else if (isKnockdown) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white12,
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: (widget.currentCp ?? 0) >= 2
                              ? () => Navigator.of(context).pop(
                                  TokenAnimationResult(
                                    count: 0,
                                    dontShowAgain: _dontShowAgain,
                                    customAction: 'spend_2_cp',
                                  ),
                                )
                              : null,
                          child: const Text(
                            'Spend 2 CP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(
                            TokenAnimationResult(
                              count: 0,
                              dontShowAgain: _dontShowAgain,
                              customAction: 'skip_roll',
                            ),
                          ),
                          child: const Text(
                            'Skip your offensive roll phase',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else if (!isDieRollToken ||
                          (_blindDieRoll != null &&
                              !((isBleed ||
                                      isInfluence ||
                                      isTimeBomb1 ||
                                      isTimeBomb2 ||
                                      isNanite) &&
                                  _spentCount < _count)))
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8f43ff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            final int? agilitySuccessCount;
                            if (isAgility && _blindDieRoll != null) {
                              if (_spentCount == 2 &&
                                  _firstAgilityRoll != null) {
                                agilitySuccessCount =
                                    (_firstAgilityRoll! <= 3 ? 1 : 0) +
                                    (_blindDieRoll! <= 3 ? 1 : 0);
                              } else {
                                agilitySuccessCount = _blindDieRoll! <= 3
                                    ? 1
                                    : 0;
                              }
                            } else {
                              agilitySuccessCount = null;
                            }
                            final List<int>? allDiceRolls;
                            if ((isBleed ||
                                    isTimeBomb1 ||
                                    isTimeBomb2 ||
                                    isInfluence ||
                                    isNanite) &&
                                _blindDieRoll != null) {
                              allDiceRolls = [
                                ..._previousRolls,
                                _blindDieRoll!,
                              ];
                            } else if (isAgility && _blindDieRoll != null) {
                              if (_firstAgilityRoll != null) {
                                allDiceRolls = [
                                  _firstAgilityRoll!,
                                  _blindDieRoll!,
                                ];
                              } else {
                                allDiceRolls = [_blindDieRoll!];
                              }
                            } else {
                              allDiceRolls = _blindDieRoll != null
                                  ? [_blindDieRoll!]
                                  : null;
                            }
                            var finalCount = _count;
                            if (isBleed && allDiceRolls != null) {
                              final removedCount = allDiceRolls
                                  .where((r) => r >= 5)
                                  .length;
                              finalCount = (_count - removedCount).clamp(
                                0,
                                widget.rule.maxStack,
                              );
                            } else if (isCoal && _count >= 4) {
                              finalCount = (_count - 4).clamp(
                                0,
                                widget.rule.maxStack,
                              );
                            } else if (isPhoenixBurn && _blindDieRoll != null) {
                              if (_blindDieRoll! >= 5) {
                                finalCount = (_count - 1).clamp(
                                  0,
                                  widget.rule.maxStack,
                                );
                              }
                            } else if (isPowderKeg && _blindDieRoll != null) {
                              if (_blindDieRoll! <= 2 || _blindDieRoll! == 6) {
                                finalCount = (_count - 1).clamp(
                                  0,
                                  widget.rule.maxStack,
                                );
                              }
                            } else if (isNanite && allDiceRolls != null) {
                              final countSixes = allDiceRolls
                                  .where((r) => r == 6)
                                  .length;
                              finalCount = (_count - countSixes).clamp(
                                0,
                                widget.rule.maxStack,
                              );
                            } else if (isPrey && _blindDieRoll != null) {
                              if (_blindDieRoll! == 1) {
                                finalCount = (_count - 1).clamp(
                                  0,
                                  widget.rule.maxStack,
                                );
                              }
                            } else if (isInfluence && _blindDieRoll != null) {
                              if (_spentCount >= _count) {
                                finalCount = 0;
                              }
                            } else if (isBagOfTricks ||
                                isGuardBreak ||
                                isCosmicFlare) {
                              finalCount = (_count - 1).clamp(
                                0,
                                widget.rule.maxStack,
                              );
                            }
                            Navigator.of(context).pop(
                              TokenAnimationResult(
                                count: finalCount,
                                dontShowAgain: _dontShowAgain,
                                dieRoll: isFlight
                                    ? ((_blindDieRoll == 6 ||
                                              _secondDieRoll == 6)
                                          ? 6
                                          : 0)
                                    : _blindDieRoll,
                                spentCount: isCosmicFlare
                                    ? _count
                                    : _spentCount,
                                agilitySuccessCount: agilitySuccessCount,
                                allDiceRolls: allDiceRolls,
                                sneakAttackBonus:
                                    isSneakAttack && _blindDieRoll != null
                                    ? _blindDieRoll!
                                    : null,
                                preyBonus: isPrey && _blindDieRoll != null
                                    ? (_blindDieRoll! == 1
                                          ? 0
                                          : (_blindDieRoll! >= 6 ? 2 : 1))
                                    : null,
                              ),
                            );
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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

