part of '../../main.dart';

/// Popin de jet d'extra-dé pour le passif de la Chimère (violet-violet-014).
/// Si l'Offensive Roll Phase échoue, la chimère lance 1 dé supplémentaire :
/// - 1 à 3 (faces blanches) : Recommence une nouvelle Offensive Roll Phase.
/// - 4 à 6 : L'attaque échoue.
/// Utilise les faces officielles de dés du jeu (assets/dice_faces/face_X.webp)
/// et un tirage aléatoire non-biaisé (Random.secure).
class ChimeraFailureRollDialog extends StatefulWidget {
  const ChimeraFailureRollDialog({
    required this.enemy,
    required this.onResult,
    super.key,
  });

  final EnemyNode enemy;
  final ValueChanged<bool> onResult;

  static Future<bool> show(BuildContext context, EnemyNode enemy) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => ChimeraFailureRollDialog(
        enemy: enemy,
        onResult: (restart) => Navigator.of(ctx).pop(restart),
      ),
    );
    return result ?? false;
  }

  @override
  State<ChimeraFailureRollDialog> createState() =>
      _ChimeraFailureRollDialogState();
}

class _ChimeraFailureRollDialogState extends State<ChimeraFailureRollDialog>
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
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _rollDie() async {
    if (_isRolling) return;
    setState(() {
      _isRolling = true;
    });
    _animController.forward(from: 0);

    for (var i = 0; i < 9; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
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

  bool get _isRestartSuccess => _rolledValue != null && _rolledValue! <= 3;

  @override
  Widget build(BuildContext context) {
    final isSuccess = _isRestartSuccess;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xff180f24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffa855f7).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffa855f7).withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 2,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icone de la chimère
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2a1b40),
                  border: Border.all(
                    color: const Color(0xffc084fc).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffc084fc).withValues(alpha: 0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      widget.enemy.cardAsset.isNotEmpty
                          ? widget.enemy.cardAsset
                          : 'assets/violet/violet-014.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xffc084fc),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Titre
              Text(
                widget.enemy.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Sous-titre
              const Text(
                'Passive: Offensive Failure',
                style: TextStyle(
                  color: Color(0xffc084fc),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Description de la règle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Offensive Roll Phase failed!\nRoll 1 extra die:',
                      style: TextStyle(
                        color: Color(0xffe5e7eb),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const DieSymbolMark(symbol: DieSymbol.white),
                        const SizedBox(width: 6),
                        const Text(
                          '1 - 3: Restart Roll Phase',
                          style: TextStyle(
                            color: Color(0xffcbd5e1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• 4 - 6: Attack Fails',
                      style: TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Dé officiel
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final angle = _animController.value * 2 * pi;
                  return Transform.rotate(
                    angle: _isRolling ? angle : 0,
                    child: child,
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xff22173b),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _rolledValue != null
                          ? (isSuccess
                              ? const Color(0xff38bdf8)
                              : const Color(0xffef4444))
                          : const Color(0xffa855f7),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_rolledValue != null
                                ? (isSuccess
                                    ? const Color(0xff38bdf8)
                                    : const Color(0xffef4444))
                                : const Color(0xffa855f7))
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _rolledValue != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/dice_faces/face_$_rolledValue.webp',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(
                                '$_rolledValue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.casino,
                            size: 38,
                            color: Color(0xffa855f7),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Résultat
              if (_rolledValue != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isSuccess
                            ? const Color(0xff0284c7)
                            : const Color(0xffdc2626))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: isSuccess
                          ? const Color(0xff38bdf8)
                          : const Color(0xffef4444),
                    ),
                  ),
                  child: Text(
                    isSuccess
                        ? '🔄 White face rolled (Die $_rolledValue)! Restarting roll phase'
                        : '❌ Face $_rolledValue rolled: Attack failed',
                    style: TextStyle(
                      color: isSuccess
                          ? const Color(0xffbae6fd)
                          : const Color(0xfffecaca),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),

              // Boutons d'action
              if (_rolledValue == null)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isRolling ? null : _rollDie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffa855f7),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangle64Border(),
                    ),
                    child: _isRolling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Roll extra die',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onResult(isSuccess);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? const Color(0xff0284c7)
                          : const Color(0xff475569),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangle64Border(),
                    ),
                    child: Text(
                      isSuccess ? 'Restart Offensive Roll Phase' : 'End Attack Phase',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
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
