import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../models/companion_model.dart';
import '../../../analytics/widgets/fin_character.dart';
import '../../../analytics/widgets/fin_visual_controller.dart';
import 'fin_motion_state.dart';

/// Reusable living, articulated FIN character widget with smooth native motion.
///
/// Features:
/// - Smooth organic hover/float oscillation
/// - Dynamic contact shadow responding to elevation
/// - Soft body sway and breathing kinematics
/// - Immediate tactile response on interactive tap
/// - Full reduced-motion compliance (zero timers / static rest when disabled)
/// - Multiple motion state modes (idle, listening, thinking, supportive, alert, docked)
class FinLiveCharacter extends StatefulWidget {
  final FinMotionState motionState;
  final FinCharacterState? characterState;
  final double size;
  final bool? animationsEnabled;
  final bool animationActive;
  final bool allowAnimationInTests;
  final VoidCallback? onTap;
  final FinVisualController? controller;
  final bool showShadow;
  final bool isInteractive;

  const FinLiveCharacter({
    super.key,
    this.motionState = FinMotionState.idle,
    this.characterState,
    this.size = 120,
    this.animationsEnabled,
    this.animationActive = true,
    this.allowAnimationInTests = false,
    this.onTap,
    this.controller,
    this.showShadow = true,
    this.isInteractive = true,
  });

  @override
  State<FinLiveCharacter> createState() => _FinLiveCharacterState();
}

class _FinLiveCharacterState extends State<FinLiveCharacter>
    with TickerProviderStateMixin {
  /// Vertical floating and soft sway cycle (~3.6s)
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// Tactile micro-bounce on tap (~320ms)
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  bool get _motionAllowed =>
      (widget.animationsEnabled ?? true) &&
      (widget.controller?.animationsEnabled ?? true) &&
      widget.animationActive &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled &&
      (!WidgetsBinding.instance.runtimeType.toString().contains(
            'TestWidgetsFlutterBinding',
          ) ||
          widget.allowAnimationInTests);

  FinCharacterState get _effectiveCharacterState {
    if (widget.characterState != null) {
      return widget.characterState!;
    }
    return widget.motionState.toCharacterState();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FinLiveCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionState != widget.motionState ||
        oldWidget.animationsEnabled != widget.animationsEnabled ||
        oldWidget.animationActive != widget.animationActive) {
      _syncMotion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (_motionAllowed) {
      if (widget.motionState == FinMotionState.docked) {
        // Calmer, slower breathing cycle for docked state
        _floatController.duration = const Duration(milliseconds: 4800);
      } else {
        _floatController.duration = const Duration(milliseconds: 3600);
      }
      if (!_floatController.isAnimating) {
        _floatController.repeat();
      }
    } else {
      _floatController.stop();
      _floatController.value = 0;
      _bounceController.stop();
      _bounceController.value = 0;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isInteractive && _motionAllowed) {
      _bounceController.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveState = _effectiveCharacterState;

    final characterWidth = widget.size * 0.72;
    final totalHeight = widget.size + (widget.showShadow ? 18.0 : 0.0);

    return Semantics(
      label: 'FIN live companion, state: ${widget.motionState.label}',
      button: widget.onTap != null || widget.isInteractive,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: characterWidth + 24,
          height: totalHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatController, _bounceController]),
            builder: (context, _) {
              // Float amplitude depends on motion state
              final double floatAmplitude = switch (widget.motionState) {
                FinMotionState.docked => 1.2,
                FinMotionState.alert => 4.8,
                FinMotionState.thinking => 3.2,
                _ => 4.0,
              };

              final double floatPhase = _motionAllowed
                  ? _floatController.value
                  : 0.0;
              final double floatOffset =
                  -math.sin(floatPhase * math.pi * 2) * floatAmplitude;

              // Soft body sway (~1.2 degrees)
              final double swayAngle = _motionAllowed
                  ? math.sin(floatPhase * math.pi * 2) * 0.018
                  : 0.0;

              // Tactile tap reaction
              final double bounceOffset = _bounceController.isAnimating
                  ? -math.sin(_bounceController.value * math.pi) * 5.0
                  : 0.0;

              final double totalY = floatOffset + bounceOffset;

              // Shadow scale and opacity inversely proportional to height
              final double shadowScale = (1.0 - (totalY / 24.0)).clamp(
                0.85,
                1.15,
              );
              final double shadowAlpha = (isDark ? 0.45 : 0.20) * shadowScale;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, totalY),
                    child: Transform.rotate(
                      angle: swayAngle,
                      child: FinCharacter(
                        size: widget.size,
                        state: effectiveState,
                        animationsEnabled: widget.animationsEnabled,
                        animationActive: widget.animationActive,
                        allowAnimationInTests: widget.allowAnimationInTests,
                        controller: widget.controller,
                      ),
                    ),
                  ),
                  if (widget.showShadow) ...[
                    const SizedBox(height: 4),
                    Transform.scale(
                      scaleX: shadowScale,
                      scaleY: 0.85,
                      child: Container(
                        width: widget.size * 0.42,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: shadowAlpha),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: shadowAlpha * 0.8,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
