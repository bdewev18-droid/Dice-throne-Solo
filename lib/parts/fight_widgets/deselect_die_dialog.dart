part of '../../main.dart';

class DeselectDieDialog extends StatefulWidget {
  const DeselectDieDialog({
    required this.dice,
    required this.enemyColor,
    super.key,
  });

  final List<GameDie> dice;
  final Color enemyColor;

  static Future<List<int>?> show(
    BuildContext context, {
    required List<GameDie> dice,
    required Color enemyColor,
  }) {
    return showDialog<List<int>>(
      context: context,
      builder: (_) => DeselectDieDialog(
        dice: dice,
        enemyColor: enemyColor,
      ),
    );
  }

  @override
  State<DeselectDieDialog> createState() => _DeselectDieDialogState();
}

class _DeselectDieDialogState extends State<DeselectDieDialog> {
  final Set<int> _toDeselectIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final reservedDice = widget.dice
        .where((d) => d.settled && d.reserved && d.value != null)
        .toList();

    return Dialog(
      backgroundColor: const Color(0xff141926),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: const Color(0xffffb300).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffffb300).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffffb300),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Deselect AI Die',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffffb300).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xffffb300).withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'An AI configuration or dice-selection error can occasionally happen. '
                'Tap any reserved die below to deselect it so it can be rolled again. '
                'This deselection will be logged as a bug report in the Run Log to help improve the AI.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reservedDice.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No reserved dice are currently selected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              )
            else ...[
              const Text(
                'Tap the die/dice to deselect:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final die in reservedDice)
                    _DeselectDieItem(
                      die: die,
                      markedForDeselect: _toDeselectIds.contains(die.id),
                      accent: widget.enemyColor,
                      onTap: () {
                        setState(() {
                          if (_toDeselectIds.contains(die.id)) {
                            _toDeselectIds.remove(die.id);
                          } else {
                            _toDeselectIds.add(die.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffffb300),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white38,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _toDeselectIds.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_toDeselectIds.toList()),
                    icon: const Icon(Icons.layers_clear_rounded, size: 18),
                    label: Text(
                      _toDeselectIds.isEmpty
                          ? 'Deselect'
                          : 'Deselect (${_toDeselectIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeselectDieItem extends StatelessWidget {
  const _DeselectDieItem({
    required this.die,
    required this.markedForDeselect,
    required this.accent,
    required this.onTap,
  });

  final GameDie die;
  final bool markedForDeselect;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: markedForDeselect
                  ? const Color(0xffff5252).withValues(alpha: 0.22)
                  : accent.withValues(alpha: 0.16),
              border: Border.all(
                color: markedForDeselect
                    ? const Color(0xffff5252)
                    : accent,
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IgnorePointer(
                  child: DieTile(
                    die: die,
                    onTap: null,
                    highlight: false,
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: markedForDeselect
                          ? const Color(0xffff5252)
                          : const Color(0xff1e2433),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: Icon(
                      markedForDeselect
                          ? Icons.close_rounded
                          : Icons.lock_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            markedForDeselect ? 'Will deselect' : 'Die #${die.id + 1}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: markedForDeselect
                  ? const Color(0xffff8a80)
                  : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
