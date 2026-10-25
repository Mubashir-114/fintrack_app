import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/horizon_theme_tokens.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_motion.dart';

/// Branded tap target with keyboard activation and a visible focus outline.
class HorizonPressable extends StatefulWidget {
  const HorizonPressable({
    super.key,
    required this.child,
    required this.onPressed,
    required this.label,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String label;
  final bool? selected;

  @override
  State<HorizonPressable> createState() => _HorizonPressableState();
}

class _HorizonPressableState extends State<HorizonPressable> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      selected: widget.selected,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? HorizonMotion.pressScaleFactor : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : HorizonMotion.press,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: HorizonDimensions.buttonHeight,
              ),
              decoration: BoxDecoration(
                borderRadius: HorizonDimensions.borderDefault,
                border: _focused
                    ? Border.all(color: HorizonThemeTokens.of(context).ionCyan)
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
