part of '../../main.dart';

/// Badge visualisant un montant absolu de points de vie ({hp:X}).
class HpBadge extends StatelessWidget {
  const HpBadge({required this.value, this.color, super.key});

  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _EffectImageBadge(
      value: value.toString(),
      asset: 'assets/illustration/soin.webp',
      textColor: Colors.white,
      size: 24,
      fontSize: 11,
    );
  }
}
