import 'package:flutter/material.dart';

/// Unified Game Design System ("Obsidian & Platinum") for D.T Solo Quest.
/// Guarantees visual consistency from Home Page -> Hero Choice -> Map -> Fight.
class GameDesign {
  const GameDesign._();

  // Primary Action Color (Platinum — outside hero yellow and 5 enemy rank colors)
  static const Color actionPrimary = Color(0xffe2e8f0);
  static const Color gold = actionPrimary;
  static const Color goldDark = Color(0xffcbd5e1);
  static const Color goldText = Color(0xff121212);

  // Secondary / Consultation Surfaces
  static const Color slateSurface = Color(0xff1b1f2e);
  static const Color slateBorder = Color(0xff3a4159);
  static const Color obsidianBg = Color(0xff131620);
  static const Color cardBg = Color(0xff181c28);

  // Unified Geometry
  static const double buttonHeight = 52.0;
  static const double buttonRadius = 10.0;
  static const double cardRadius = 12.0;
}

/// Standardised primary/secondary action button used across Home, Setup, Map & Fight.
class GameActionButton extends StatelessWidget {
  const GameActionButton({
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.icon,
    this.primary = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.height = GameDesign.buttonHeight,
    this.centerContent = false,
    super.key,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double height;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ??
        (primary ? GameDesign.gold : GameDesign.slateSurface);
    final fg =
        foregroundColor ?? (primary ? GameDesign.goldText : Colors.white);
    final border =
        borderColor ??
        (primary
            ? GameDesign.gold
            : GameDesign.slateBorder);

    final isDisabled = onPressed == null;

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(GameDesign.buttonRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: isDisabled ? bg.withValues(alpha: 0.35) : bg,
              borderRadius: BorderRadius.circular(GameDesign.buttonRadius),
              border: Border.all(
                color: isDisabled ? Colors.white12 : border,
                width: 1.5,
              ),
              boxShadow: (!isDisabled && primary)
                  ? [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: centerContent && subtitle != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: 20,
                                color: isDisabled ? Colors.white38 : fg,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDisabled ? Colors.white38 : fg,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.white24
                                : (primary
                                      ? GameDesign.goldText.withValues(
                                          alpha: 0.72,
                                        )
                                      : GameDesign.gold),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: isDisabled ? Colors.white38 : fg,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: subtitle != null
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDisabled ? Colors.white38 : fg,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.white24
                                  : (primary
                                        ? GameDesign.goldText.withValues(
                                            alpha: 0.72,
                                          )
                                        : GameDesign.gold),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
