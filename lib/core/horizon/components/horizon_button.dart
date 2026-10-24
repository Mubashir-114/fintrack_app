import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

enum HorizonButtonVariant {
  /// Primary Action (Ion Charge): Solid cyan fill with dark void text.
  primary,

  /// Secondary Action (Sub-level): Elevated surface 2 fill with cyan precision rim.
  secondary,

  /// Ghost / Tertiary: Transparent fill with subtle neutral border and muted text.
  ghost,

  /// Destructive Outflow: Danger alert button for irreversible actions.
  destructive,
}

/// Tactile cockpit action button for FinTrack // HORIZON.
/// Features 0.98 scale tactile compression on press, high-emphasis telemetry labels,
/// and accessible touch targets.
class HorizonButton extends StatefulWidget {
  const HorizonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = HorizonButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.height = HorizonDimensions.buttonHeight,
    this.expandWidth = true,
    this.uppercase = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final HorizonButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expandWidth;
  final bool uppercase;

  @override
  State<HorizonButton> createState() => _HorizonButtonState();
}

class _HorizonButtonState extends State<HorizonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case HorizonButtonVariant.primary:
        bgColor = isEnabled
            ? (_isPressed ? tokens.ionCyan.withValues(alpha: 0.85) : tokens.ionCyan)
            : tokens.ionCyan.withValues(alpha: 0.35);
        fgColor = tokens.onPrimary;
        border = null;
        break;

      case HorizonButtonVariant.secondary:
        bgColor = isEnabled
            ? (_isPressed ? tokens.surface3 : tokens.surface2)
            : tokens.surface1;
        fgColor = isEnabled ? tokens.textHigh : tokens.textLow;
        border = Border.all(
          color: isEnabled ? tokens.rimCyanActive : tokens.rimNeutral,
          width: 1,
        );
        break;

      case HorizonButtonVariant.ghost:
        bgColor = _isPressed ? tokens.surface1 : Colors.transparent;
        fgColor = isEnabled ? tokens.textMedium : tokens.textLow;
        border = Border.all(
          color: tokens.rimNeutral,
          width: 1,
        );
        break;

      case HorizonButtonVariant.destructive:
        bgColor = isEnabled
            ? (_isPressed ? tokens.outflow.withValues(alpha: 0.85) : tokens.outflow)
            : tokens.outflow.withValues(alpha: 0.35);
        fgColor = Colors.white;
        border = null;
        break;
    }

    final content = Row(
      mainAxisSize: widget.expandWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: fgColor),
            const SizedBox(width: HorizonDimensions.spaceSM),
          ],
          Flexible(
            child: Text(
              widget.uppercase ? widget.text.toUpperCase() : widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HorizonTypography.labelCaps.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08 * 11,
                color: fgColor,
              ),
            ),
          ),
        ],
      ],
    );

    final buttonWidget = AnimatedScale(
      scale: _isPressed && isEnabled ? HorizonMotion.pressScaleFactor : 1.0,
      duration: HorizonMotion.press,
      curve: HorizonMotion.emphasized,
      child: AnimatedContainer(
        duration: HorizonMotion.quick,
        height: widget.height,
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: HorizonDimensions.marginMobile),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: HorizonDimensions.borderDefault,
          border: border,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.text,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: widget.expandWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget,
      ),
    );
  }
}
