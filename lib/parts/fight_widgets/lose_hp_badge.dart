part of '../../main.dart';

/// Badge visualisant une perte sèche de points de vie (unpreventable health loss).
class LoseHpBadge extends StatelessWidget {
  const LoseHpBadge({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'lose',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        _EffectImageBadge(
          value: '-$value',
          asset: 'assets/illustration/soin.webp',
          textColor: Colors.white,
          size: 28,
          fontSize: 12,
        ),
      ],
    );
  }
}
