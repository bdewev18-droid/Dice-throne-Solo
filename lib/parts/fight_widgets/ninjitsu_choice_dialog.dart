part of '../../main.dart';

/// Modal dialog presented when a player rolls a 6 on a Ninjitsu die.
/// Formatted according to Material 3 principles and touch-first ergonomics.
class NinjitsuChoiceDialog extends StatelessWidget {
  const NinjitsuChoiceDialog({super.key});

  static Future<int> show(BuildContext context) async {
    return await showDialog<int>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const NinjitsuChoiceDialog(),
        ) ??
        1;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff181424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff8f43ff), width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Ninjitsu icon and die badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2a2240),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff8f43ff).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/token/Ninjutsu.webp',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.auto_awesome,
                    size: 54,
                    color: Color(0xff8f43ff),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ninjitsu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff8f43ff).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.casino,
                      size: 15,
                      color: Color(0xffce93d8),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Résultat du dé : 6 (Critique)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xffce93d8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choisissez votre récompense pour cette attaque :',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Option 1: +2 Damage
              _NinjitsuChoiceCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xffffb74d),
                title: '+2 Dégâts',
                description: 'Ajoute 2 dégâts supplémentaires à l\'attaque en cours.',
                onTap: () => Navigator.of(context).pop(1),
              ),
              const SizedBox(height: 10),

              // Option 2: Delayed Poison
              _NinjitsuChoiceCard(
                icon: Icons.science_outlined,
                iconColor: const Color(0xff66bb6a),
                title: 'Poison Différé',
                description: 'Inflige 1 jeton Poison Différé au défenseur (3 dégâts en phase d\'entretien).',
                onTap: () => Navigator.of(context).pop(2),
              ),
              const SizedBox(height: 10),

              // Option 3: Undefendable Attack
              _NinjitsuChoiceCard(
                icon: Icons.gavel_rounded,
                iconColor: const Color(0xff4fc3f7),
                title: 'Attaque Indéfendable',
                description: 'Rend l\'attaque indéfendable (le défenseur ne peut pas lancer ses dés de défense).',
                onTap: () => Navigator.of(context).pop(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NinjitsuChoiceCard extends StatelessWidget {
  const _NinjitsuChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withValues(alpha: 0.15),
        highlightColor: iconColor.withValues(alpha: 0.08),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff221b35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: iconColor.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
