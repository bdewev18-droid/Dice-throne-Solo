part of '../../main.dart';

class DicePanel extends StatelessWidget {
  const DicePanel({
    required this.dice,
    required this.diceToRoll,
    required this.visibleDiceCount,
    required this.maxDiceCount,
    required this.rollCount,
    required this.maxRolls,
    required this.editMode,
    required this.rerollOneMode,
    required this.editingDieId,
    required this.specialAttackMode,
    required this.onDiceToRollChanged,
    required this.onRoll,
    required this.onTapDie,
    required this.onSelectFace,
    required this.onValidateEdit,
    required this.onToggleEdit,
    required this.onToggleRerollOne,
    required this.rollLabel,
    required this.rollColor,
    super.key,
  });

  final List<GameDie> dice;
  final int diceToRoll;
  final int visibleDiceCount;
  final int maxDiceCount;
  final int rollCount;
  final int maxRolls;
  final bool editMode;
  final bool rerollOneMode;
  final int? editingDieId;
  final bool specialAttackMode;
  final ValueChanged<int> onDiceToRollChanged;
  final VoidCallback onRoll;
  final ValueChanged<GameDie> onTapDie;
  final void Function(GameDie die, int face) onSelectFace;
  final VoidCallback onValidateEdit;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleRerollOne;
  final String rollLabel;
  final Color rollColor;

  @override
  Widget build(BuildContext context) {
    final visibleDice = dice.take(visibleDiceCount.clamp(0, 6)).toList();
    final hasRollingDice = visibleDice.any((die) => !die.settled);
    final rollDice = visibleDice.where((die) => !die.reserved).toList();
    final reserveDice = visibleDice.where((die) => die.reserved).toList();
    if (!hasRollingDice) {
      rollDice.sort(_compareDice);
      reserveDice.sort(_compareDice);
    }
    final editingDie = editingDieId == null
        ? null
        : dice.firstWhere((die) => die.id == editingDieId);

    return _DiceBackgroundBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dice zone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              DropdownButton<int>(
                value: diceToRoll,
                items: List.generate(maxDiceCount.clamp(0, 5) + 1, (i) => i)
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count dice'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onDiceToRollChanged(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: onToggleEdit,
                icon: const Icon(Icons.tune),
                label: Text(editMode ? 'Stop edit' : 'Edit a die'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: heroAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: onToggleRerollOne,
                icon: const Icon(Icons.refresh),
                label: Text(rerollOneMode ? 'Choose a die' : 'Reroll one die'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DiceZone(title: 'Dice to roll', dice: rollDice, onTapDie: onTapDie),
          const SizedBox(height: 6),
          Row(
            children: [
              if (maxRolls > 1) ...[
                Text(
                  '$rollCount / $maxRolls',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _SolidRollButton(
                  onPressed:
                      !hasRollingDice && rollCount < maxRolls && diceToRoll > 0
                      ? onRoll
                      : null,
                  color: rollColor,
                  child: Text(rollLabel),
                ),
              ),
              const _CubeIcon(size: 28),
            ],
          ),
          const SizedBox(height: 6),
          DiceZone(title: 'Reserve', dice: reserveDice, onTapDie: onTapDie),
          if (editingDie != null) ...[
            const SizedBox(height: 12),
            Text(
              'Edit die ${editingDie.id + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5, 6]
                  .where((face) => face != editingDie.value)
                  .map(
                    (face) => ActionChip(
                      label: Text(face.toString()),
                      onPressed: () => onSelectFace(editingDie, face),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onValidateEdit,
              child: const Text('Confirm die'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SolidRollButton extends StatelessWidget {
  const _SolidRollButton({
    required this.color,
    required this.onPressed,
    required this.child,
  });

  final Color color;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.28),
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.42),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      onPressed: onPressed,
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.w900),
        child: child,
      ),
    );
  }
}

int _compareDice(GameDie a, GameDie b) {
  final av = a.value ?? 99;
  final bv = b.value ?? 99;
  final byValue = av.compareTo(bv);
  return byValue == 0 ? a.id.compareTo(b.id) : byValue;
}

class DiceZone extends StatelessWidget {
  const DiceZone({
    required this.title,
    required this.dice,
    required this.onTapDie,
    super.key,
  });

  final String title;
  final List<GameDie> dice;
  final ValueChanged<GameDie> onTapDie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            children: [
              for (final die in dice) ...[
                DieTile(
                  die: die,
                  onTap: die.settled ? () => onTapDie(die) : null,
                ),
                const SizedBox(width: 5),
              ],
              if (dice.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '--',
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w900,
                      ),
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

Color _scarletWitchColor(int face) {
  switch (face) {
    case 1:
    case 2:
    case 3:
      return const Color(0xffF8A5C2);
    case 4:
      return const Color(0xffFFEAA7);
    case 5:
      return const Color(0xffFF7675);
    case 6:
      return const Color(0xffFFFFFF);
    default:
      return const Color(0xffF8A5C2);
  }
}

class DieTile extends StatefulWidget {
  const DieTile({
    required this.die,
    required this.onTap,
    this.compact = false,
    this.highlight = false,
    this.highlightColor,
    this.onAnimationDone,
    super.key,
  });

  final GameDie die;
  final VoidCallback? onTap;
  final bool compact;
  final bool highlight;
  final Color? highlightColor;
  final VoidCallback? onAnimationDone;

  @override
  State<DieTile> createState() => _DieTileState();
}

class _DieTileState extends State<DieTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _faceTimer;
  int? _animatedValue;
  int _lastRollTick = 0;
  final Random _animationRandom = Random();

  @override
  void initState() {
    super.initState();
    _lastRollTick = widget.die.rollTick;
    _animatedValue = widget.die.value;
    _controller =
        AnimationController(
          vsync: this,
          duration: Duration(
            seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt(),
          ),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _faceTimer?.cancel();
            if (mounted) {
              setState(() => _animatedValue = widget.die.value);
            }
            widget.onAnimationDone?.call();
          }
        });
  }

  @override
  void didUpdateWidget(covariant DieTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.die.rollTick != _lastRollTick && widget.die.value != null) {
      _lastRollTick = widget.die.rollTick;
      _startRollAnimation();
    } else if (!_controller.isAnimating) {
      _animatedValue = widget.die.value;
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startRollAnimation() {
    _faceTimer?.cancel();
    if (combatDiceAnimationSeconds <= 0) {
      _controller.stop();
      if (mounted) {
        setState(() => _animatedValue = widget.die.value);
      }
      return;
    }
    _controller.duration = Duration(
      seconds: combatDiceAnimationSeconds.clamp(1, 5).toInt(),
    );
    if (mounted) {
      setState(() => _animatedValue = _animationRandom.nextInt(6) + 1);
    }
    _controller
      ..reset()
      ..forward();
    _faceTimer = Timer.periodic(const Duration(milliseconds: 95), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _animatedValue = _animationRandom.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 40.0 : 50.0;
    final value = !widget.die.settled || _controller.isAnimating
        ? _animatedValue
        : widget.die.value;
    final isHexBlank =
        widget.die.isHexed &&
        value == 6 &&
        (widget.die.settled || !_controller.isAnimating);
    final isScarletWitch = widget.die.isScarletWitch && value != null;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final turn = _controller.value * 10.0 * pi;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(turn),
                child: child,
              );
            },
            child: Container(
              width: size,
              height: size,
              constraints: BoxConstraints(maxWidth: size),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHexBlank
                    ? const Color(0xff38383a)
                    : (isScarletWitch
                          ? _scarletWitchColor(value)
                          : (value == null
                                ? Colors.white12
                                : Colors.transparent)),
                borderRadius: BorderRadius.circular(8),
                border: isHexBlank
                    ? Border.all(color: Colors.white30, width: 1.5)
                    : (widget.die.isScarletWitch
                          ? Border.all(color: const Color(0xff8f43ff), width: 2)
                          : (widget.highlight
                                ? Border.all(
                                    color: widget.highlightColor ?? heroAccent,
                                    width: 3,
                                  )
                                : null)),
                boxShadow: widget.highlight
                    ? [
                        BoxShadow(
                          color: (widget.highlightColor ?? heroAccent)
                              .withValues(alpha: 0.72),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: value == null
                  ? const Text(
                      '-',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : isHexBlank
                  ? const Text(
                      'Ã˜',
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    )
                  : (widget.die.isScarletWitch
                        ? Text(
                            '$value',
                            style: const TextStyle(
                              color: Color(0xff181424),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          )
                        : Image.asset(
                            'assets/dice_faces/face_$value.webp',
                            fit: BoxFit.contain,
                          )),
            ),
          ),
          if (widget.highlight)
            Positioned(
              right: -4,
              top: -5,
              child: Icon(
                Icons.check_circle,
                color: widget.highlightColor ?? heroAccent,
                size: widget.compact ? 16 : 18,
              ),
            ),
          if (widget.die.isLocked)
            Positioned(
              left: -4,
              top: -5,
              child: Icon(
                Icons.lock,
                color: Colors.redAccent,
                size: widget.compact ? 14 : 16,
              ),
            ),
        ],
      ),
    );
  }
}

