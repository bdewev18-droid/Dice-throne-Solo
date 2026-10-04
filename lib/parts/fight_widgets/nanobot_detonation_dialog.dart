part of '../../main.dart';

class _NanobotDetonationDialog extends StatefulWidget {
  final int enemyNanitesCount;
  final String enemyLabel;
  final int currentHp;
  final AdventureState adventure;

  const _NanobotDetonationDialog({
    required this.enemyNanitesCount,
    required this.enemyLabel,
    required this.currentHp,
    required this.adventure,
  });

  @override
  State<_NanobotDetonationDialog> createState() =>
      _NanobotDetonationDialogState();
}

class _NanobotDetonationDialogState extends State<_NanobotDetonationDialog> {
  late bool askPossession;
  bool maskChecked = false;

  @override
  void initState() {
    super.initState();
    askPossession = !widget.adventure.maskedPopinTokens.contains(
      'nanobot_possession',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dmg = widget.enemyNanitesCount == 1
        ? 1
        : (widget.enemyNanitesCount == 2 ? 3 : 5);

    return AlertDialog(
      backgroundColor: const Color(0xff181424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff8f43ff), width: 2),
      ),
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Image.asset(
              'assets/token/nanobot.webp',
              width: 32,
              height: 32,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text('Nanobot', style: TextStyle(color: Color(0xff8f43ff))),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (askPossession)
            const Text(
              'Do you possess the Nanobot board?',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            )
          else ...[
            Text(
              "${widget.enemyLabel} has ${widget.enemyNanitesCount} Nanite(s).\nDo you want to activate Nanobot to detonate them for $dmg undefendable damage?",
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset('assets/token/Nanite.png', width: 64, height: 64),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff251d38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff8f43ff).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  const Text(
                    'HP: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.currentHp}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xff8f43ff),
                    ),
                  ),
                  Text(
                    '${(widget.currentHp - dmg).clamp(0, 99)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xff8f43ff), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'No',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: askPossession
                    ? () {
                        widget.adventure.maskedPopinTokens.add(
                          'nanobot_possession',
                        );
                        setState(() {
                          askPossession = false;
                        });
                      }
                    : () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff8f43ff),
                  minimumSize: const Size.fromHeight(46),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!askPossession) ...[
                      Image.asset(
                        'assets/token/synth.webp',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
