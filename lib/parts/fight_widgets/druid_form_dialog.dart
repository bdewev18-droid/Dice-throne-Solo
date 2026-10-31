part of '../../main.dart';

/// Popin de jet de dé pour le changement de forme du Druide Ténébreux (vert-vert-014).
/// Utilise les faces officielles de dés du jeu (assets/dice_faces/face_X.webp)
/// et un générateur purement aléatoire sans aucune pondération (Random.secure).
class DruidFormRollDialog extends StatefulWidget {
  const DruidFormRollDialog({
    required this.enemy,
    required this.onFormChosen,
    super.key,
  });

  final EnemyNode enemy;
  final ValueChanged<String> onFormChosen;

  static Future<String?> show(BuildContext context, EnemyNode enemy) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => DruidFormRollDialog(
        enemy: enemy,
        onFormChosen: (form) => Navigator.of(ctx).pop(form),
      ),
    );
  }

  @override
  State<DruidFormRollDialog> createState() => _DruidFormRollDialogState();
}

class _DruidFormRollDialogState extends State<DruidFormRollDialog>
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

  String? get _resolvedForm {
    if (_rolledValue == null) return null;
    return _rolledValue! <= 3 ? 'Forme Ours' : 'Forme Elan';
  }

  @override
  Widget build(BuildContext context) {
    final form = _resolvedForm;
    final isBear = form == 'Forme Ours';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xff130a1e),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xff9b51e0).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff9b51e0).withValues(alpha: 0.35),
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
              // Icone du druide / forme
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff1f1733),
                  border: Border.all(
                    color: const Color(0xff4ade80).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff4ade80).withValues(alpha: 0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      widget.enemy.cardAsset.isNotEmpty
                          ? widget.enemy.cardAsset
                          : 'assets/illustration/soin.webp',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.pets,
                        color: Color(0xff4ade80),
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
                'Passive: Shapeshifting',
                style: TextStyle(
                  color: Color(0xff4ade80),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Description du jet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Text(
                  'Roll 1 die to determine the Druid\'s form:\n• 1 - 3: Bear Form (Ours)\n• 4 - 6: Elk Form (Élan)',
                  style: TextStyle(
                    color: Color(0xffd1d5db),
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Dé officiel de l'application
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
                          ? (isBear ? const Color(0xfff97316) : const Color(0xff10b981))
                          : const Color(0xff9b51e0),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_rolledValue != null
                                ? (isBear ? const Color(0xfff97316) : const Color(0xff10b981))
                                : const Color(0xff9b51e0))
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
                            color: Color(0xff9b51e0),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Forme obtenue
              if (_rolledValue != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isBear
                            ? const Color(0xfff97316)
                            : const Color(0xff10b981))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: isBear
                          ? const Color(0xfff97316)
                          : const Color(0xff10b981),
                    ),
                  ),
                  child: Text(
                    isBear
                        ? '🐻 Bear Form Active (Die $_rolledValue)'
                        : '🦌 Elk Form Active (Die $_rolledValue)',
                    style: TextStyle(
                      color: isBear
                          ? const Color(0xfffdba74)
                          : const Color(0xff6ee7b7),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),

              // Actions
              if (_rolledValue == null)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isRolling ? null : _rollDie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff9b51e0),
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
                            'Roll die',
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
                      widget.onFormChosen(form!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBear
                          ? const Color(0xffea580c)
                          : const Color(0xff059669),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangle64Border(),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 15,
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

class RoundedRectangle64Border extends RoundedRectangleBorder {
  RoundedRectangle64Border() : super(borderRadius: BorderRadius.circular(10));
}
