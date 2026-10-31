part of '../../main.dart';

/// Badge visualisant un montant de Points de Combat ({cp:X}).
/// Affiche le symbole PC triangulaire iconique avec le montant à l'intérieur.
class CpBadge extends StatelessWidget {
  const CpBadge({required this.value, this.color, super.key});

  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final valStr = value.toString();
    final isTwoDigits = valStr.length > 1;
    final width = isTwoDigits ? 30.0 : 25.0;
    const height = 20.0;

    return CustomPaint(
      painter: const _PcTriangleBadgePainter(),
      child: SizedBox(
        width: width,
        height: height,
        child: Align(
          alignment: const Alignment(-0.32, 0),
          child: Text(
            valStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTwoDigits ? 10 : 11.5,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge visualisant un gain de CP ({gain-cp:X} / {gains-cp:X}).
/// Bouton ovale stylisé identique à CpStealBadge mais avec 'Gain X CP'.
class CpGainBadge extends StatelessWidget {
  const CpGainBadge({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        'Gain $value CP',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
