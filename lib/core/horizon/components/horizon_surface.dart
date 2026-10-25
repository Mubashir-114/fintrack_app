import 'package:flutter/material.dart';
import '../tokens/horizon_colors.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../theme/horizon_theme_tokens.dart';

enum HorizonSurfaceTier {
  /// Level 0: Pure canvas void floor.
  canvas,

  /// Level 1: Docked surfaces, base containers, recessed lists.
  surface1,

  /// Level 2: Interactive modules, actionable cards, balance telemetry pods.
  surface2,

  /// Level 3: Overlays, bottom sheets, navigation dock, pinned headers.
  surface3,
}

/// Cinematic 2.5D surface container for FinTrack // HORIZON.
/// Features directional sub-pixel edge lighting, top inner rim highlight,
/// elevation tiers, and optional corner accent luminescence.
class HorizonSurface extends StatefulWidget {
  const HorizonSurface({
    super.key,
    required this.child,
    this.tier = HorizonSurfaceTier.surface2,
    this.padding = const EdgeInsets.all(HorizonDimensions.marginMobile),
    this.borderRadius,
    this.cornerAccentColor,
    this.useTopRimHighlight = true,
    this.onTap,
  });

  final Widget child;
  final HorizonSurfaceTier tier;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? cornerAccentColor;
  final bool useTopRimHighlight;
  final VoidCallback? onTap;

  @override
  State<HorizonSurface> createState() => _HorizonSurfaceState();
}

class _HorizonSurfaceState extends State<HorizonSurface> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final radius = widget.borderRadius ?? HorizonDimensions.borderLG;

    final Color bgColor;
    final Border? border;
    final List<BoxShadow> shadows;

    switch (widget.tier) {
      case HorizonSurfaceTier.canvas:
        bgColor = tokens.canvas;
        border = null;
        shadows = const [];
        break;

      case HorizonSurfaceTier.surface1:
        bgColor = tokens.surface1;
        border = Border.all(color: tokens.rimNeutral, width: 1);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? 0.4 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;

      case HorizonSurfaceTier.surface2:
        bgColor = tokens.surface2;
        border = Border.all(color: tokens.rimCyan, width: 1);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? 0.6 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
        break;

      case HorizonSurfaceTier.surface3:
        bgColor = tokens.surface3;
        border = Border.all(color: tokens.rimCyanActive, width: 1);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? 0.8 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ];
        break;
    }

    final hasTap = widget.onTap != null;
    final scale = _isPressed && hasTap ? HorizonMotion.pressScaleFactor : 1.0;

    Widget surface = ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          border: border,
          boxShadow: shadows,
          gradient: widget.tier == HorizonSurfaceTier.surface2 && tokens.isDark
              ? tokens.cardGradient
              : null,
        ),
        child: Stack(
          children: [
            // Directional corner accent light if configured
            if (widget.cornerAccentColor != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: HorizonColors.cornerAccentLight(
                      widget.cornerAccentColor!,
                    ),
                  ),
                ),
              ),

            // Top hairline rim highlight
            if (widget.useTopRimHighlight &&
                tokens.isDark &&
                widget.tier != HorizonSurfaceTier.canvas)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: tokens.rimTopHighlight),
                ),
              ),

            // Main content
            Padding(
              padding: widget.padding,
              child: Material(
                type: MaterialType.transparency,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );

    if (hasTap) {
      surface = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: HorizonMotion.press,
          curve: HorizonMotion.emphasized,
          child: surface,
        ),
      );
    }

    return surface;
  }
}
