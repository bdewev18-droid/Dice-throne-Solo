part of '../../main.dart';

/// Interactive dialog for the Fierce Hydra's passive ability:
/// "At the end of the Offensive Roll Phase, roll 1 die: On 6 (Red), gain 1 Head (Chaos token)."
/// Completely formatted in English as requested.
class HydraRegrowthDialog extends StatefulWidget {
  final EnemyNode enemy;
  final AdventureState adventure;
  final int Function()? rollDie;

  const HydraRegrowthDialog({
    required this.enemy,
    required this.adventure,
    this.rollDie,
  });

  @override
  State<HydraRegrowthDialog> createState() => _HydraRegrowthDialogState();
}

class _HydraRegrowthDialogState extends State<HydraRegrowthDialog>
    with SingleTickerProviderStateMixin {
  bool _hasRolled = false;
  int? _rolledValue;
  bool _headGrown = false;
  bool _isRolling = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _executeRoll() {
    if (_hasRolled || _isRolling) return;
    setState(() {
      _isRolling = true;
    });

    _animCtrl.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final roll = widget.rollDie != null
          ? widget.rollDie!()
          : (Random().nextInt(6) + 1);

      setState(() {
        _isRolling = false;
        _hasRolled = true;
        _rolledValue = roll;
        _headGrown = (roll == 6);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentHeads = getHydraChaosCount(widget.enemy);

    return AlertDialog(
      backgroundColor: const Color(0xff181224),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff9b58ff), width: 2),
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/token/Chaos.webp',
            width: 32,
            height: 32,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.auto_awesome, color: Color(0xff9b58ff), size: 28),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HYDRA REGROWTH',
                  style: TextStyle(
                    color: Color(0xffffd700),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Passive Ability • End of Offensive Roll Phase',
                  style: TextStyle(
                    color: Color(0xffbfa5ea),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff241a36),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff9b58ff).withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rule:',
                    style: TextStyle(
                      color: Color(0xffd5baff),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'At the end of the Offensive Roll Phase, roll 1 die:\n'
                    'On a 6 (🔴 Red Symbol), the Hydra sprouts a new head (+1 Chaos token)!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const Divider(color: Color(0xff3d2d59), height: 16),
                  Row(
                    children: [
                      const Text(
                        'Current Heads in play: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff8f43ff).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff8f43ff)),
                        ),
                        child: Text(
                          '$currentHeads Head${currentHeads > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Color(0xffffd700),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Roll outcome & Die display
            Center(
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animCtrl.value * 2 * pi,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _rolledValue == 6
                            ? const Color(0xffb81414)
                            : const Color(0xff2b2042),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _rolledValue == 6
                              ? const Color(0xffff5252)
                              : const Color(0xff9b58ff),
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (_rolledValue == 6)
                            BoxShadow(
                              color: const Color(0xffff1744).withOpacity(0.6),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Center(
                        child: _isRolling
                            ? const CircularProgressIndicator(
                                color: Color(0xffffd700),
                                strokeWidth: 3,
                              )
                            : Text(
                                _rolledValue != null ? '$_rolledValue' : '?',
                                style: TextStyle(
                                  color: _rolledValue == 6
                                      ? Colors.white
                                      : const Color(0xffffd700),
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            if (_hasRolled) ...[
              if (_headGrown)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff4a101d),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffff5252)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xff4caf50), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rolled 6 (Red)! A new head sprouted!\n(+1 Chaos token added to Hydra)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xffffcdd2),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1d172b),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xff4a3b68)),
                  ),
                  child: Text(
                    'Rolled $_rolledValue: No new head grew this turn.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        if (!_hasRolled)
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _executeRoll,
            icon: const Icon(Icons.casino, color: Colors.black),
            label: const Text(
              'ROLL DIE',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffffd700),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_headGrown),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff9b58ff),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONTINUE TO HERO TURN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
