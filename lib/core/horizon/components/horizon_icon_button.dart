import 'package:flutter/material.dart';

import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../theme/horizon_theme_tokens.dart';

/// Compact circular action used in screen headers and sheets.
///
/// Keeps every header affordance a real control: [onPressed] either performs
/// an action or the button is not rendered. [badgeCount] > 0 marks the button
/// with a live indicator dot so unread updates are visible at a glance.
class HorizonIconButton extends StatelessWidget {
  const HorizonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.badgeCount = 0,
    this.size = 36,
    this.iconSize = 18,
    this.accent,
    this.filledAccent = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final int badgeCount;
  final double size;
  final double iconSize;
  final Color? accent;

  /// When true the button body uses [accent] with a contrast glyph, for the
  /// single primary action of a header (e.g. "add").
  final bool filledAccent;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final Color base = accent ?? tokens.ionCyan;
    final Color background = filledAccent ? base : tokens.surface2;
    final Color glyph = filledAccent
        ? (tokens.isDark ? Colors.black : Colors.white)
        : base;
    final bool enabled = onPressed != null;

    final Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? tooltip,
      child: Tooltip(
        message: tooltip ?? semanticLabel ?? '',
        child: AnimatedScale(
          duration: HorizonMotion.press,
          scale: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: HorizonMotion.quick,
                curve: HorizonMotion.emphasized,
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filledAccent
                        ? Colors.transparent
                        : (enabled ? tokens.rimNeutral : tokens.rimNeutral),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: iconSize, color: glyph),
                    if (badgeCount > 0)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tokens.ionCyan,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.surface2,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.ionCyan.withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: HorizonDimensions.spaceXS),
      child: button,
    );
  }
}
