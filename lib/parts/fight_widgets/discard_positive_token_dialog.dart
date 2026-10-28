part of '../../main.dart';

class DiscardPositiveTokenDialog extends StatelessWidget {
  const DiscardPositiveTokenDialog({
    required this.enemyName,
    this.discardedToken,
    super.key,
  });

  final String enemyName;
  final String? discardedToken;

  static Future<void> show(
    BuildContext context, {
    required String enemyName,
    String? discardedToken,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DiscardPositiveTokenDialog(
        enemyName: enemyName,
        discardedToken: discardedToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenRule = discardedToken != null
        ? TokenCatalogRepository.byLabel(discardedToken!)
        : null;
    final tokenAsset = tokenRule?.imageAsset;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff181a20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xffffe22d).withValues(alpha: 0.6),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffffe22d).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xffffe22d).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Color(0xffffe22d),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DISCARD STATUS TOKEN',
                        style: TextStyle(
                          color: Color(0xffffe22d),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        enemyName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text(
                    'The hero must immediately discard a positive status token at random.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (discardedToken != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tokenAsset != null) ...[
                          Image.asset(
                            tokenAsset,
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.stars,
                              color: Color(0xffffe22d),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          discardedToken!,
                          style: const TextStyle(
                            color: Color(0xffffe22d),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discarded from your board.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'No positive status token on your board.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffffe22d),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
