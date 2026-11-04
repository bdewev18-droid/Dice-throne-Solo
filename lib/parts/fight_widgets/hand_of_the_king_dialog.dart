part of '../../main.dart';

/// Popin de jet de dé pour le jeton Main du Roi (Hand of the King)
/// Correspond au Composant 2 de la recette.
class HandOfTheKingDialog extends StatefulWidget {
  const HandOfTheKingDialog({
    required this.enemy,
    required this.isDifficult,
    this.isUltimateDefense = false,
    required this.onResult,
    super.key,
  });

  final EnemyNode enemy;
  final bool isDifficult;
  final bool isUltimateDefense;
  final ValueChanged<bool> onResult;

  static Future<bool> show(
    BuildContext context, {
    required EnemyNode enemy,
    required bool isDifficult,
    bool isUltimateDefense = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => HandOfTheKingDialog(
        enemy: enemy,
        isDifficult: isDifficult,
        isUltimateDefense: isUltimateDefense,
        onResult: (success) => Navigator.of(ctx).pop(success),
      ),
    );
    return result ?? false;
  }

  @override
  State<HandOfTheKingDialog> createState() => _HandOfTheKingDialogState();
}

class _HandOfTheKingDialogState extends State<HandOfTheKingDialog>
    with SingleTickerProviderStateMixin {
  int? _rolledValue;
  bool _isRolling = false;
  late AnimationController _animController;
  final Random _rng = Random.secure();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isSuccess {
    if (_rolledValue == null) return false;
    final threshold = widget.isDifficult ? 3 : 4;
    return _rolledValue! >= threshold;
  }

  Future<void> _rollDie() async {
    if (_isRolling) return;
    setState(() => _isRolling = true);
    _animController.forward(from: 0);

    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() {
        _rolledValue = _rng.nextInt(6) + 1;
      });
    }

    final finalRoll = _rng.nextInt(6) + 1;
    if (!mounted) return;
    setState(() {
      _rolledValue = finalRoll;
      _isRolling = false;
    });
  }

  void _editDie() {
    if (_isRolling) return;
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1f172b),
        title: const Text(
          'Select Die Face (1-6)',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [1, 2, 3, 4, 5, 6].map((val) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2b1b42),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xffffb300), width: 1),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(val),
              child: Text(
                '$val',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ),
    ).then((chosen) {
      if (chosen != null && mounted) {
        setState(() => _rolledValue = chosen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final diffLabel = widget.isDifficult ? 'Difficult' : 'Medium';
    final successRange = widget.isDifficult ? '3, 4, 5, 6' : '4, 5, 6';
    final failureRange = widget.isDifficult ? '1, 2' : '1, 2, 3';

    final String descText;
    if (widget.isUltimateDefense) {
      descText =
          'Spend 1 Hand of the King token to defend against the Hero\'s Ultimate Ability.\n\n'
          '• Success on $successRange: The Hero must re-roll 1 die from their Ultimate.\n'
          '• Failure on $failureRange: The Ultimate proceeds unmodified.';
    } else {
      descText =
          '${widget.enemy.label} failed their Offensive Roll Phase. Spend 1 Hand of the King token and roll 1 die for a second chance.\n\n'
          '• Success on $successRange: ${widget.enemy.label} gains an additional Offensive Roll Phase!\n'
          '• Failure on $failureRange: Attack remains failed.';
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xff181124),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffffb300).withValues(alpha: 0.75),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffffb300).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Token icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2a1b40),
                  border: Border.all(
                    color: const Color(0xffffb300),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffffb300).withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/token/main_du_roi.webp',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.pan_tool_alt_rounded,
                        color: Color(0xffffb300),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Title
              const Text(
                'Hand of the King',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              // Subtitle
              Text(
                widget.isUltimateDefense
                    ? 'Hero Ultimate Defense ($diffLabel)'
                    : 'Triggered on ${widget.enemy.label} ($diffLabel)',
                style: const TextStyle(
                  color: Color(0xffffd54f),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  descText,
                  style: const TextStyle(
                    color: Color(0xffe2e8f0),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Roll section (Composant 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xff231834),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xffffb300).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hand of the King Roll (1 D6)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Die display
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _rolledValue == null
                              ? Colors.white24
                              : (_isSuccess ? Colors.greenAccent : Colors.redAccent),
                          width: 2,
                        ),
                        boxShadow: [
                          if (_rolledValue != null)
                            BoxShadow(
                              color: (_isSuccess ? Colors.greenAccent : Colors.redAccent)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _rolledValue != null ? '$_rolledValue' : '-',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _rolledValue == null
                                ? Colors.white54
                                : (_isSuccess ? Colors.greenAccent : Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action buttons: Roll and Edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffffb300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isRolling ? null : _rollDie,
                          icon: const Icon(Icons.casino_outlined, size: 16),
                          label: Text(
                            _rolledValue == null ? 'Roll Die' : 'Reroll Die',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isRolling ? null : _editDie,
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Result message banner if rolled
              if (_rolledValue != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.cancel,
                        color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSuccess
                            ? 'SUCCESS! (Rolled $_rolledValue)'
                            : 'FAILURE! (Rolled $_rolledValue)',
                        style: TextStyle(
                          color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rolledValue != null
                        ? (_isSuccess ? Colors.green : const Color(0xff4a3560))
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _rolledValue != null
                      ? () => widget.onResult(_isSuccess)
                      : null,
                  child: Text(
                    _rolledValue == null
                        ? 'Roll die to continue'
                        : (_isSuccess
                            ? (widget.isUltimateDefense
                                ? 'Reroll 1 Ultimate Die'
                                : 'Restart Roll Phase')
                            : 'Continue Turn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
