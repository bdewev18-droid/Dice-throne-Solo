part of '../../main.dart';

/// Interactive popin displayed between the end of an offensive phase and
/// the beginning of the next phase when an enemy effect or attack forces the hero
/// to discard one or more cards from their hand (e.g. Farceur / The Jester,
/// Goblin Enchanter, Melodious Girl, Orc Shaman, Naxarus' Thundering Roar).
class DiscardCardDialog extends StatelessWidget {
  const DiscardCardDialog({
    required this.count,
    this.enemyName,
    this.reason,
    super.key,
  });

  final int count;
  final String? enemyName;
  final String? reason;

  static Future<bool> show(
    BuildContext context, {
    int count = 1,
    String? enemyName,
    String? reason,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => DiscardCardDialog(
            count: count,
            enemyName: enemyName,
            reason: reason,
          ),
        ) ??
        true;
  }

  @override
  Widget build(BuildContext context) {
    final title = count > 1 ? 'Discard $count Cards' : 'Discard 1 Card';
    final subtitle = enemyName != null && enemyName!.trim().isNotEmpty
        ? '$enemyName Effect'
        : (reason != null && reason!.trim().isNotEmpty ? reason! : 'Encounter Effect');

    return AlertDialog(
      backgroundColor: const Color(0xff181424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff8f43ff), width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing card discard badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2a2240),
                  border: Border.all(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff8f43ff).withValues(alpha: 0.4),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.style_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xffe11d48),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.south_east_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
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
                  color: const Color(0xff8f43ff).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffc084fc),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Explanatory instruction box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff231b2e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 10),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Color(0xfffbbf24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        count > 1
                            ? 'Please choose and discard $count cards from your hand into your discard pile before proceeding.'
                            : 'Please choose and discard 1 card from your hand into your discard pile before proceeding.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffe2e8f0),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'Confirm Discard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8f43ff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
