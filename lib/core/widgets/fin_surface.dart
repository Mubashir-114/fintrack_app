import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_motion.dart';

/// Shared, low-elevation surface for summaries, lists and settings groups.
class FinSurface extends StatelessWidget {
  const FinSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.emphasized = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppDimensions.radiusLG);
    final tint = accent ?? colors.primary;
    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: emphasized ? tint.withValues(alpha: .28) : colors.cardBorder,
          ),
          gradient: emphasized
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      tint.withValues(alpha: colors.isDark ? .10 : .045),
                      colors.surface,
                    ),
                    colors.surface,
                  ],
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class FinIconTile extends StatelessWidget {
  const FinIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor ?? color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: .12)),
    ),
    child: Icon(icon, color: color, size: size * .52),
  );
}

/// A brief reveal that never delays data or replays on ordinary rebuilds.
class FinReveal extends StatelessWidget {
  const FinReveal({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
