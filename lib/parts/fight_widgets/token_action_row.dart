part of '../../main.dart';

class _ActionRowLabel extends StatelessWidget {
  const _ActionRowLabel({
    required this.tokenLabel,
    required this.tokenAsset,
    required this.text,
  });

  final String tokenLabel;
  final String tokenAsset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          final rule = TokenCatalogRepository.byLabel(tokenLabel);
          if (rule != null) showTokenDetails(context, rule);
        },
        child: Row(
          children: [
            Image.asset(
              tokenAsset,
              width: 22,
              height: 22,
              errorBuilder: (ctx, err, stack) =>
                  const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiRollTokenActiveRow extends StatefulWidget {
  const _MultiRollTokenActiveRow({
    required this.tokenLabel,
    required this.tokenAsset,
    this.ownerWidget,
    required this.count,
    required this.color,
    required this.onUse,
    this.isUsed = false,
  });
  final String tokenLabel;
  final String tokenAsset;
  final Widget? ownerWidget;
  final int count;
  final Color color;
  final ValueChanged<int>? onUse;
  final bool isUsed;

  @override
  State<_MultiRollTokenActiveRow> createState() =>
      _MultiRollTokenActiveRowState();
}

class _MultiRollTokenActiveRowState extends State<_MultiRollTokenActiveRow> {
  int _rolls = 1;

  @override
  Widget build(BuildContext context) {
    final canUse = widget.onUse != null;
    final isPurple = widget.color.toARGB32() == 0xff8f43ff;
    final bgColor = isPurple
        ? const Color(0xff1f1a2e)
        : const Color(0xff132b1e);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                final rule = TokenCatalogRepository.byLabel(widget.tokenLabel);
                if (rule != null) {
                  showTokenDetails(context, rule);
                }
              },
              child: Row(
                children: [
                  if (widget.ownerWidget != null) ...[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: widget.ownerWidget!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Image.asset(
                    widget.tokenAsset,
                    width: 22,
                    height: 22,
                    errorBuilder: (ctx, err, stack) =>
                        Icon(Icons.warning, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.count > 1
                          ? '${widget.tokenLabel} (x${widget.count})'
                          : widget.tokenLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canUse) ...[
            const SizedBox(width: 4),
            const Text(
              'Rolls',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3].map((val) {
                final selected = _rolls == val;
                final drawColor = widget.isUsed
                    ? widget.color.withValues(alpha: 0.5)
                    : widget.color;
                return GestureDetector(
                  onTap: widget.isUsed
                      ? null
                      : () => setState(() => _rolls = val),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? drawColor : Colors.transparent,
                      border: Border.all(color: drawColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'x$val',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? (widget.isUsed ? Colors.white70 : Colors.white)
                            : (widget.isUsed ? Colors.white38 : Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 4),
            if (widget.isUsed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.greenAccent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => widget.onUse!(_rolls),
                child: const Text(
                  'Select',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
          ] else ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.color, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: widget.color),
                  const SizedBox(width: 4),
                  Text(
                    'Actif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TokenActionRow extends StatelessWidget {
  const _TokenActionRow({
    required this.tokenLabel,
    required this.tokenAsset,
    this.ownerWidget,
    required this.text,
    this.isActive = false,
    this.activeText = 'Active',
    required this.showUseButton,
    required this.canUse,
    required this.onUse,
  });

  final String tokenLabel;
  final String tokenAsset;
  final Widget? ownerWidget;
  final String text;
  final bool isActive;
  final String activeText;
  final bool showUseButton;
  final bool canUse;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xff132b1e) : const Color(0xff1f1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : const Color(0xff8f43ff).withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          if (ownerWidget != null) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: ownerWidget!,
            ),
            const SizedBox(width: 8),
          ],
          _ActionRowLabel(
            tokenLabel: tokenLabel,
            tokenAsset: tokenAsset,
            text: text,
          ),
          const SizedBox(width: 8),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          if (isActive && showUseButton) const SizedBox(width: 8),
          if (showUseButton)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canUse
                    ? const Color(0xff8f43ff)
                    : Colors.grey.shade700,
                foregroundColor: canUse ? Colors.white : Colors.white38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: canUse ? onUse : null,
              child: const Text(
                'Use',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveTokenBadge extends StatelessWidget {
  const _ActiveTokenBadge({
    required this.tokenLabel,
    required this.tokenAsset,
    this.ownerWidget,
    this.activeText = 'Active',
  });

  final String tokenLabel;
  final String tokenAsset;
  final Widget? ownerWidget;
  final String activeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff132b1e),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              if (ownerWidget != null) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: ownerWidget!,
                ),
                const SizedBox(width: 8),
              ],
              _ActionRowLabel(
                tokenLabel: tokenLabel,
                tokenAsset: tokenAsset,
                text: tokenLabel,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
