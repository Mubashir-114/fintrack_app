import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../models/companion_model.dart';
import 'fin_visual_controller.dart';

/// FinTrack HORIZON — 2.5D Articulated Living FIN Character Rig.
///
/// Interprets the approved Stitch HORIZON capsule character art direction:
/// - Warm cream/champagne articulated capsule body with directional 2.5D rim lighting
/// - Glossy dark-navy face visor with curved glass specular sheen
/// - Ionized cyan glowing eyes with natural blinking and expressive shapes
/// - Distinctive golden sprout leaf on head top with multi-layer metallic gradients
/// - Golden chest growth emblem with rotating orbital dashed telemetry ring
/// - Full-body articulation: shoulders, arms, hands, legs, planted magnetic feet
/// - Dynamic side-peeking mode with physical viewport edge gripping
class FinCharacter extends StatefulWidget {
  final FinCharacterState state;
  final double size;
  final bool? animationsEnabled;
  final bool animationActive, allowAnimationInTests;
  final VoidCallback? onTap;
  final FinVisualController? controller;
  final bool isPeeking, peekingOnLeft;
  final double peekProgress;

  /// Fraction of the character's width that is inside the visible window.
  /// Used so the gripping hand lands exactly on the clipped edge at any viewport.
  final double peekReveal;

  const FinCharacter({
    super.key,
    this.state = FinCharacterState.idle,
    this.size = 100,
    this.animationsEnabled,
    this.animationActive = true,
    this.allowAnimationInTests = false,
    this.onTap,
    this.controller,
    this.isPeeking = false,
    this.peekingOnLeft = false,
    this.peekProgress = 0,
    this.peekReveal = .8,
  });

  @override
  State<FinCharacter> createState() => _FinCharacterState();
}

class _FinCharacterState extends State<FinCharacter>
    with TickerProviderStateMixin {
  /// Breathing, golden leaf sway, and chest orbit cycle (4.6s)
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );

  /// State-change gesture controller (greeting wave, celebrating hop, etc.)
  late final AnimationController _gesture = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 1800),
  );

  /// Subtle weight shifts and posture micro-adjustments
  late final AnimationController _posture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 14000),
  );

  /// Natural eye blinking controller
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  FinCharacterState? _observedState;
  FinCharacterState get _state => widget.controller?.state ?? widget.state;

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

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_changed);
    _idle.addListener(_checkBlink);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _sync();
  }

  void _checkBlink() {
    if (!_motionAllowed || _blink.isAnimating) return;
    // Trigger a natural blink at around 75% of the idle cycle
    final v = _idle.value;
    if (v > 0.74 && v < 0.77) {
      _blink.forward(from: 0);
    }
  }

  void _sync() {
    if (_observedState != _state) {
      _observedState = _state;
      if (_motionAllowed &&
          (_state == FinCharacterState.greeting ||
              _state == FinCharacterState.celebrating ||
              _state == FinCharacterState.happy)) {
        _gesture.forward(from: 0);
      }
    }
    if (_motionAllowed) {
      if (!_idle.isAnimating) _idle.repeat();
      if (!_posture.isAnimating) _posture.repeat();
    } else {
      _idle.stop();
      _gesture.stop();
      _posture.stop();
      _blink.stop();
      _gesture.value = 1;
      _posture.value = 0;
      _blink.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant FinCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_changed);
      widget.controller?.addListener(_changed);
    }
    _sync();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_changed);
    _idle.removeListener(_checkBlink);
    _idle.dispose();
    _gesture.dispose();
    _posture.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPose = _Pose.forState(_state);

    return Semantics(
      label: 'FIN financial companion, currently ${_state.label}',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size * 0.72,
          height: widget.size,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<_Pose>(
              tween: _PoseTween(end: currentPose),
              duration: _motionAllowed
                  ? const Duration(milliseconds: 380)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, posture, _) => AnimatedBuilder(
                animation: Listenable.merge([
                  _idle,
                  _gesture,
                  _posture,
                  _blink,
                ]),
                builder: (context, _) => CustomPaint(
                  painter: _Fin25DPainter(
                    pose: posture,
                    state: _state,
                    phase: _motionAllowed ? _idle.value : 0,
                    gesture: _gesture.value,
                    adjust: _motionAllowed
                        ? _postureAdjustment(_posture.value)
                        : 0,
                    blink: _blink.isAnimating
                        ? math.sin(_blink.value * math.pi)
                        : 0,
                    dark: isDark,
                    peeking: widget.isPeeking && widget.peekProgress < .5,
                    left: widget.peekingOnLeft,
                    reveal: widget.peekReveal.clamp(.5, 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A subtle natural weight shift per cycle.
double _postureAdjustment(double t) {
  if (t < .52 || t > .78) return 0;
  return math.sin(((t - .52) / .26) * math.pi);
}

/// Parametric kinematic state for FIN's full body.
class _Pose {
  final double head;
  final double torso;
  final double shoulderL;
  final double elbowL;
  final double shoulderR;
  final double elbowR;
  final double eyeArc;
  final double eyeOpenness;
  final double leafSway;
  final double chestPulse;
  final double floatOffset;

  const _Pose({
    this.head = -0.02,
    this.torso = 0.0,
    this.shoulderL = 0.12,
    this.elbowL = -0.15,
    this.shoulderR = -0.12,
    this.elbowR = 0.15,
    this.eyeArc = 0.65,
    this.eyeOpenness = 1.0,
    this.leafSway = 0.0,
    this.chestPulse = 0.5,
    this.floatOffset = 0.0,
  });

  factory _Pose.forState(FinCharacterState state) => switch (state) {
    FinCharacterState.greeting => const _Pose(
      head: -0.08,
      torso: -0.03,
      shoulderL: 0.1,
      elbowL: -0.12,
      shoulderR: -1.35,
      elbowR: -1.15,
      eyeArc: 1.0,
      eyeOpenness: 1.0,
      leafSway: 0.18,
      chestPulse: 0.85,
      floatOffset: -4.0,
    ),
    FinCharacterState.listening || FinCharacterState.attentive => const _Pose(
      head: 0.08,
      torso: 0.03,
      shoulderL: 0.18,
      elbowL: -0.35,
      shoulderR: -0.18,
      elbowR: 0.35,
      eyeArc: 0.0,
      eyeOpenness: 1.15,
      leafSway: -0.05,
      chestPulse: 0.7,
      floatOffset: 0.0,
    ),
    FinCharacterState.thinking => const _Pose(
      head: -0.14,
      torso: -0.02,
      shoulderL: 0.08,
      elbowL: -0.2,
      shoulderR: 0.1,
      elbowR: 1.2,
      eyeArc: 0.25,
      eyeOpenness: 0.85,
      leafSway: -0.1,
      chestPulse: 0.65,
      floatOffset: 0.0,
    ),
    FinCharacterState.explaining => const _Pose(
      head: -0.04,
      torso: 0.02,
      shoulderL: 0.15,
      elbowL: -0.2,
      shoulderR: -0.55,
      elbowR: -1.0,
      eyeArc: 0.6,
      eyeOpenness: 1.0,
      leafSway: 0.05,
      chestPulse: 0.75,
      floatOffset: 0.0,
    ),
    FinCharacterState.happy ||
    FinCharacterState.celebrating ||
    FinCharacterState.encouraging => const _Pose(
      head: 0.0,
      torso: 0.0,
      shoulderL: 0.95,
      elbowL: 1.15,
      shoulderR: -0.95,
      elbowR: 1.15,
      eyeArc: 1.0,
      eyeOpenness: 1.0,
      leafSway: 0.24,
      chestPulse: 1.0,
      floatOffset: -8.0,
    ),
    FinCharacterState.concerned || FinCharacterState.caution => const _Pose(
      head: 0.08,
      torso: -0.02,
      shoulderL: -0.25,
      elbowL: -0.75,
      shoulderR: 0.25,
      elbowR: 0.75,
      eyeArc: -0.75,
      eyeOpenness: 0.9,
      leafSway: -0.12,
      chestPulse: 0.9,
      floatOffset: 0.0,
    ),
    FinCharacterState.confused || FinCharacterState.emptyData => const _Pose(
      head: 0.18,
      torso: 0.02,
      shoulderL: 0.35,
      elbowL: 0.6,
      shoulderR: -0.15,
      elbowR: 0.2,
      eyeArc: 0.1,
      eyeOpenness: 0.9,
      leafSway: 0.1,
      chestPulse: 0.5,
      floatOffset: 0.0,
    ),
    FinCharacterState.error => const _Pose(
      head: 0.06,
      torso: 0.0,
      shoulderL: 0.05,
      elbowL: -0.1,
      shoulderR: -0.05,
      elbowR: 0.1,
      eyeArc: -0.4,
      eyeOpenness: 0.75,
      leafSway: -0.05,
      chestPulse: 0.4,
      floatOffset: 0.0,
    ),
    FinCharacterState.docked => const _Pose(
      head: 0.05,
      torso: 0.0,
      shoulderL: -0.05,
      elbowL: -0.05,
      shoulderR: 0.05,
      elbowR: 0.05,
      eyeArc: 0.85,
      eyeOpenness: 0.18,
      leafSway: -0.02,
      chestPulse: 0.25,
      floatOffset: 2.0,
    ),
    FinCharacterState.idle => const _Pose(),
  };

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
    head: lerpDouble(a.head, b.head, t)!,
    torso: lerpDouble(a.torso, b.torso, t)!,
    shoulderL: lerpDouble(a.shoulderL, b.shoulderL, t)!,
    elbowL: lerpDouble(a.elbowL, b.elbowL, t)!,
    shoulderR: lerpDouble(a.shoulderR, b.shoulderR, t)!,
    elbowR: lerpDouble(a.elbowR, b.elbowR, t)!,
    eyeArc: lerpDouble(a.eyeArc, b.eyeArc, t)!,
    eyeOpenness: lerpDouble(a.eyeOpenness, b.eyeOpenness, t)!,
    leafSway: lerpDouble(a.leafSway, b.leafSway, t)!,
    chestPulse: lerpDouble(a.chestPulse, b.chestPulse, t)!,
    floatOffset: lerpDouble(a.floatOffset, b.floatOffset, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _Pose &&
      head == other.head &&
      torso == other.torso &&
      shoulderL == other.shoulderL &&
      elbowL == other.elbowL &&
      shoulderR == other.shoulderR &&
      elbowR == other.elbowR &&
      eyeArc == other.eyeArc &&
      eyeOpenness == other.eyeOpenness &&
      leafSway == other.leafSway &&
      chestPulse == other.chestPulse &&
      floatOffset == other.floatOffset;

  @override
  int get hashCode => Object.hash(
    head,
    torso,
    shoulderL,
    elbowL,
    shoulderR,
    elbowR,
    eyeArc,
    eyeOpenness,
    leafSway,
    chestPulse,
    floatOffset,
  );
}

class _PoseTween extends Tween<_Pose> {
  _PoseTween({required _Pose end}) : super(begin: end, end: end);

  @override
  _Pose lerp(double t) => _Pose.lerp(begin!, end!, t);
}

/// 2.5D Layered Vector CustomPainter.
///
/// Canonical model space is 200 x 240, matching the Stitch design specifications.
class _Fin25DPainter extends CustomPainter {
  final _Pose pose;
  final FinCharacterState state;
  final double phase;
  final double gesture;
  final double adjust;
  final double blink;
  final bool dark;
  final bool peeking;
  final bool left;
  final double reveal;

  const _Fin25DPainter({
    required this.pose,
    required this.state,
    required this.phase,
    required this.gesture,
    required this.adjust,
    required this.blink,
    required this.dark,
    required this.peeking,
    required this.left,
    required this.reveal,
  });

  // Canonical HORIZON FIN Colors
  static const Color navyVoid = Color(0xFF080D17);
  static const Color visorDark = Color(0xFF0E1626);
  static const Color visorDeep = Color(0xFF172338);
  static const Color ionCyan = Color(0xFF75DEED);
  static const Color glowCyan = Color(0xFF6CD6E4);
  static const Color amberAlert = Color(0xFFF7C778);
  static const Color leafGoldTop = Color(0xFFFFE7C6);
  static const Color leafGoldMid = Color(0xFFE5B76A);
  static const Color leafGoldDeep = Color(0xFFA87A1E);
  static const Color emblemGoldDeep = Color(0xFF875E0F);
  static const Color ceramicTop = Color(0xFFFBF8EE);
  static const Color ceramicMid = Color(0xFFEBE3CD);
  static const Color ceramicBase = Color(0xFFC2B79B);
  static const Color armCream = Color(0xFFDDD4BA);

  double get breath => math.sin(phase * math.pi * 2);

  bool get isCaution => {
    FinCharacterState.caution,
    FinCharacterState.concerned,
    FinCharacterState.error,
  }.contains(state);

  @override
  void paint(Canvas c, Size size) {
    // Model viewport: 200 x 240
    c.save();
    c.scale(size.width / 200, size.height / 240);

    // 1. Ground Contact Shadow (hidden/softened during peeking)
    if (!peeking) {
      final shadowAlpha =
          (dark ? 0.6 : 0.25) * (1 - (pose.floatOffset / -16).clamp(0.0, 0.6));
      c.drawOval(
        Rect.fromCenter(center: const Offset(100, 230), width: 92, height: 14),
        Paint()
          ..color = navyVoid.withValues(alpha: shadowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // 2. Planted Magnetic Feet and Lower Struts
    _drawFeetAndLegs(c);

    // 3. Body Torso & Head Rig with Articulation
    c.save();
    // Torso articulation pivot
    c.translate(100, 150);
    final peekingLean = peeking ? (left ? 0.08 : -0.08) : 0.0;
    c.rotate(pose.torso + breath * 0.006 + adjust * 0.015 + peekingLean);
    final breathScale = 1.0 + breath * 0.012;
    c.scale(breathScale, breathScale);
    c.translate(-100, -150 + pose.floatOffset);

    // Main Capsule Body (Warm Cream / Champagne Capsule)
    _drawMainBodyCapsule(c);

    // Gold Chest Growth Emblem
    _drawChestEmblem(c);

    // Articulated Arms
    if (peeking) {
      _drawPeekingArms(c);
    } else {
      _drawStandardArms(c);
    }

    // Head Visor & Sprout
    c.save();
    // Head pivot at top of torso
    c.translate(100, 74);
    c.rotate(pose.head + breath * 0.01 + (peeking ? (left ? 0.06 : -0.06) : 0));
    c.translate(-100, -74);

    _drawVisorAndFace(c);
    _drawTopLeaf(c);

    c.restore(); // Head
    c.restore(); // Torso

    c.restore(); // Model scaling
  }

  void _drawFeetAndLegs(Canvas c) {
    // Left Leg & Foot
    _drawSingleFoot(c, const Offset(76, 218), -1);
    // Right Leg & Foot
    _drawSingleFoot(c, const Offset(124, 218), 1);
  }

  void _drawSingleFoot(Canvas c, Offset center, double side) {
    // Leg strut connecting body to foot
    final strutRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 10),
      width: 14,
      height: 18,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(strutRect, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ceramicMid, ceramicBase],
        ).createShader(strutRect),
    );

    // Magnetic rounded foot pod
    final footRect = Rect.fromCenter(center: center, width: 28, height: 14);
    final footRRect = RRect.fromRectAndRadius(
      footRect,
      const Radius.circular(7),
    );

    // Foot base shadow
    c.drawRRect(
      footRRect.shift(const Offset(0, 1.5)),
      Paint()..color = navyVoid.withValues(alpha: 0.3),
    );

    // Ceramic gradient
    c.drawRRect(
      footRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ceramicTop, ceramicMid, ceramicBase],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(footRect),
    );

    // Dark magnetic sole pad
    final soleRect = Rect.fromLTWH(
      footRect.left + 2,
      footRect.bottom - 2.5,
      footRect.width - 4,
      2.5,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(soleRect, const Radius.circular(1.5)),
      Paint()..color = navyVoid.withValues(alpha: 0.85),
    );

    // Crisp rim contour
    c.drawRRect(
      footRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _drawMainBodyCapsule(Canvas c) {
    // Body Capsule: x: 52, y: 46, width: 96, height: 170, rx: 48
    const bodyRect = Rect.fromLTWH(52, 46, 96, 170);
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      const Radius.circular(48),
    );

    // Soft drop shadow
    c.drawRRect(
      bodyRRect.shift(const Offset(1, 4)),
      Paint()
        ..color = navyVoid.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main Warm Cream / Champagne Gradient
    c.drawRRect(
      bodyRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ceramicTop, ceramicMid, ceramicBase],
          stops: [0.0, 0.65, 1.0],
        ).createShader(bodyRect),
    );

    // Soft Specular 2.5D Directional Rim Light on Body Side
    // Path: M54 94 C54 67, 74 48, 100 48 C80 50, 56 68, 56 98 L56 168 C56 195, 78 214, 100 214 C76 212, 54 195, 54 168 Z
    final rimPath = Path()
      ..moveTo(54, 94)
      ..cubicTo(54, 67, 74, 48, 100, 48)
      ..cubicTo(80, 50, 56, 68, 56, 98)
      ..lineTo(56, 168)
      ..cubicTo(56, 195, 78, 214, 100, 214)
      ..cubicTo(76, 212, 54, 195, 54, 168)
      ..close();

    c.drawPath(
      rimPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );

    // Crisp exterior rim stroke
    c.drawRRect(
      bodyRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  void _drawChestEmblem(Canvas c) {
    const center = Offset(100, 178);

    // Ambient emblem glow
    final glowColor = isCaution ? amberAlert : ionCyan;
    c.drawCircle(
      center,
      22,
      Paint()
        ..color = glowColor.withValues(alpha: 0.12 * pose.chestPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Recessed dark bezel
    c.drawCircle(
      center,
      15,
      Paint()..color = const Color(0xFF171C26).withValues(alpha: 0.92),
    );
    c.drawCircle(
      center,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = navyVoid,
    );

    // Dashed golden orbit ring with phase-driven subtle rotation
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(phase * math.pi * 2);
    c.translate(-center.dx, -center.dy);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = leafGoldMid.withValues(alpha: 0.85);

    // Draw clean dashed circle
    const numDashes = 12;
    const sweep = (math.pi * 2) / numDashes;
    for (var i = 0; i < numDashes; i++) {
      if (i % 2 == 0) {
        c.drawArc(
          Rect.fromCircle(center: center, radius: 17),
          i * sweep,
          sweep * 0.55,
          false,
          orbitPaint,
        );
      }
    }
    c.restore();

    // Golden Growth Emblem Chevron Arrow
    // Path: M100 167 L108 175 L104 175 L104 186 L96 186 L96 175 L92 175 Z
    final emblemPath = Path()
      ..moveTo(100, 167)
      ..lineTo(108, 175)
      ..lineTo(104, 175)
      ..lineTo(104, 186)
      ..lineTo(96, 186)
      ..lineTo(96, 175)
      ..lineTo(92, 175)
      ..close();

    const emblemBounds = Rect.fromLTWH(92, 167, 16, 19);
    c.drawPath(
      emblemPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [leafGoldTop, leafGoldMid, emblemGoldDeep],
          stops: [0.0, 0.45, 1.0],
        ).createShader(emblemBounds),
    );
  }

  void _drawStandardArms(Canvas c) {
    // Left Arm Pivot: (42, 105)
    _drawArm(
      c,
      shoulder: const Offset(42, 105),
      angleShoulder: pose.shoulderL,
      angleElbow: pose.elbowL,
      isRight: false,
    );

    // Right Arm Pivot: (158, 105)
    final waveAngle = state == FinCharacterState.greeting
        ? math.sin(gesture * math.pi * 4) * 0.22 * (1 - gesture)
        : 0.0;

    _drawArm(
      c,
      shoulder: const Offset(158, 105),
      angleShoulder: pose.shoulderR + waveAngle,
      angleElbow: pose.elbowR,
      isRight: true,
    );
  }

  void _drawArm(
    Canvas c, {
    required Offset shoulder,
    required double angleShoulder,
    required double angleElbow,
    required bool isRight,
  }) {
    c.save();
    c.translate(shoulder.dx, shoulder.dy);
    c.rotate(angleShoulder);

    // Shoulder sphere
    c.drawCircle(Offset.zero, 7, Paint()..color = ceramicMid);

    // Upper Arm Segment (Champagne Ceramic)
    final upperRect = Rect.fromLTWH(isRight ? -4 : -8, 0, 12, 28);
    c.drawRRect(
      RRect.fromRectAndRadius(upperRect, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          colors: [armCream, ceramicMid],
        ).createShader(upperRect),
    );

    // Elbow pivot
    c.translate(isRight ? 2 : -2, 26);
    c.rotate(angleElbow);

    c.drawCircle(Offset.zero, 5, Paint()..color = armCream);

    // Forearm & Rounded Hand Pod
    final lowerRect = Rect.fromLTWH(isRight ? -4 : -7, 0, 11, 24);
    c.drawRRect(
      RRect.fromRectAndRadius(lowerRect, const Radius.circular(5.5)),
      Paint()
        ..shader = LinearGradient(
          colors: [armCream, ceramicTop],
        ).createShader(lowerRect),
    );

    // Hand Pod
    c.drawCircle(
      Offset(isRight ? 1.5 : -1.5, 23),
      6,
      Paint()..color = ceramicTop,
    );
    c.drawCircle(
      Offset(isRight ? 1.5 : -1.5, 23),
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    c.restore();
  }

  void _drawPeekingArms(Canvas c) {
    // When peeking, the near arm grips the visible edge of the viewport
    if (left) {
      // Peeking from left: right arm reaches to the grip edge
      final gripX = (200 * reveal).clamp(120.0, 196.0);
      _drawGrippingArm(
        c,
        shoulder: const Offset(150, 110),
        target: Offset(gripX, 105),
        isLeftHand: false,
      );
      // Left arm stays tucked
      _drawArm(
        c,
        shoulder: const Offset(42, 105),
        angleShoulder: 0.1,
        angleElbow: -0.2,
        isRight: false,
      );
    } else {
      // Peeking from right: left arm reaches to grip edge
      final gripX = (200 * (1 - reveal)).clamp(4.0, 80.0);
      _drawGrippingArm(
        c,
        shoulder: const Offset(50, 110),
        target: Offset(gripX, 105),
        isLeftHand: true,
      );
      // Right arm stays tucked
      _drawArm(
        c,
        shoulder: const Offset(158, 105),
        angleShoulder: -0.1,
        angleElbow: 0.2,
        isRight: true,
      );
    }
  }

  void _drawGrippingArm(
    Canvas c, {
    required Offset shoulder,
    required Offset target,
    required bool isLeftHand,
  }) {
    c.save();
    final armPath = Path()
      ..moveTo(shoulder.dx, shoulder.dy - 6)
      ..quadraticBezierTo(
        (shoulder.dx + target.dx) / 2,
        shoulder.dy + 8,
        target.dx,
        target.dy,
      );

    c.drawPath(
      armPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = armCream,
    );

    // Tactile Gripping Hand Pod on the viewport bezel
    c.drawCircle(target, 7, Paint()..color = ceramicTop);
    // Bezel grip fingers wrapping around edge
    for (var i = -1; i <= 1; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              target.dx + (isLeftHand ? -3 : 3),
              target.dy + i * 4.5,
            ),
            width: 4,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = ceramicMid,
      );
    }
    c.restore();
  }

  void _drawVisorAndFace(Canvas c) {
    // Visor: x: 66, y: 74, width: 68, height: 60, rx: 24
    const visorRect = Rect.fromLTWH(66, 74, 68, 60);
    final visorRRect = RRect.fromRectAndRadius(
      visorRect,
      const Radius.circular(24),
    );

    // Visor Outer Recessed Bezel
    c.drawRRect(visorRRect.inflate(1.2), Paint()..color = navyVoid);

    // Visor Glossy Gradient
    c.drawRRect(
      visorRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [visorDark, navyVoid, visorDeep],
          stops: [0.0, 0.5, 1.0],
        ).createShader(visorRect),
    );

    // Reflective Glass Sheen
    // Path: M72 82 C72 78, 80 76, 92 76 C82 78, 74 84, 74 96 L74 114 C72 108, 72 90, 72 82 Z
    final sheenPath = Path()
      ..moveTo(72, 82)
      ..cubicTo(72, 78, 80, 76, 92, 76)
      ..cubicTo(82, 78, 74, 84, 74, 96)
      ..lineTo(74, 114)
      ..cubicTo(72, 108, 72, 90, 72, 82)
      ..close();

    c.drawPath(sheenPath, Paint()..color = ionCyan.withValues(alpha: 0.25));

    // Subtle Specular Dot Glint on top-right of visor glass
    c.drawCircle(
      const Offset(118, 80),
      1.5,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Expressive Ionized Cyan Glowing Eyes
    _drawGlowingEyes(c);
  }

  void _drawGlowingEyes(Canvas c) {
    final eyeColor = isCaution ? amberAlert : ionCyan;
    final effectiveOpenness = (pose.eyeOpenness * (1.0 - blink)).clamp(
      0.05,
      1.2,
    );

    // Left Eye Center: (84, 101), Right Eye Center: (116, 101)
    _drawSingleEye(c, const Offset(84, 101), eyeColor, effectiveOpenness);
    _drawSingleEye(c, const Offset(116, 101), eyeColor, effectiveOpenness);
  }

  void _drawSingleEye(Canvas c, Offset center, Color color, double openness) {
    c.save();

    // 1. Neon Bloom Glow Pass
    final glowPaint = Paint()
      ..color = (isCaution ? amberAlert : glowCyan).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // 2. Core Crisp Pass
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (openness <= 0.15) {
      // Blinking / Sleeping Horizontal Slit
      path.moveTo(center.dx - 6, center.dy);
      path.lineTo(center.dx + 6, center.dy);
    } else if (pose.eyeArc > 0.5) {
      // Happy / Greeting Smile Crescents (Upward Arch)
      // Reference: M80 102 C80 96, 88 96, 88 102
      path.moveTo(center.dx - 5.5, center.dy + 2.5);
      path.cubicTo(
        center.dx - 5.5,
        center.dy - 4.5 * openness,
        center.dx + 5.5,
        center.dy - 4.5 * openness,
        center.dx + 5.5,
        center.dy + 2.5,
      );
    } else if (pose.eyeArc < -0.3) {
      // Concerned / Caution Downward Arch
      path.moveTo(center.dx - 5.5, center.dy - 2.0);
      path.cubicTo(
        center.dx - 5.5,
        center.dy + 4.5 * openness,
        center.dx + 5.5,
        center.dy + 4.5 * openness,
        center.dx + 5.5,
        center.dy - 2.0,
      );
    } else {
      // Attentive / Thinking Circular Reticle
      final eyeRect = Rect.fromCenter(
        center: center,
        width: 10 * openness,
        height: 10 * openness,
      );
      path.addOval(eyeRect);
    }

    c.drawPath(path, glowPaint);
    c.drawPath(path, corePaint);

    // Specular Pupil Glint Dot (when open)
    if (openness > 0.4) {
      c.drawCircle(
        Offset(center.dx + 1.2, center.dy - 2.0),
        1.2,
        Paint()..color = Colors.white,
      );
    }

    c.restore();
  }

  void _drawTopLeaf(Canvas c) {
    c.save();
    // Leaf base pivot at head apex (100, 46)
    c.translate(100, 46);
    c.rotate(breath * 0.04 + pose.leafSway + (peeking ? 0.06 : 0));
    c.translate(-100, -46);

    // Primary Sprout / Gold Leaf
    // Path: M100 46 C98 32, 90 20, 102 12 C114 22, 110 34, 100 46 Z
    final leafPath = Path()
      ..moveTo(100, 46)
      ..cubicTo(98, 32, 90, 20, 102, 12)
      ..cubicTo(114, 22, 110, 34, 100, 46)
      ..close();

    const leafBounds = Rect.fromLTWH(90, 12, 24, 34);
    c.drawPath(
      leafPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [leafGoldTop, leafGoldMid, leafGoldDeep],
          stops: [0.0, 0.6, 1.0],
        ).createShader(leafBounds),
    );

    // Secondary Golden Highlight Leaflet
    // Path: M100 32 C108 28, 116 26, 118 20 C114 18, 106 24, 100 32 Z
    final subLeafPath = Path()
      ..moveTo(100, 32)
      ..cubicTo(108, 28, 116, 26, 118, 20)
      ..cubicTo(114, 18, 106, 24, 100, 32)
      ..close();

    c.drawPath(
      subLeafPath,
      Paint()..color = leafGoldTop.withValues(alpha: 0.8),
    );

    // Gold Stem Attachment Bead
    c.drawCircle(
      const Offset(100, 46),
      3.2,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [leafGoldTop, leafGoldMid, leafGoldDeep],
            ).createShader(
              Rect.fromCircle(center: const Offset(100, 46), radius: 3.2),
            ),
    );

    c.restore();
  }

  @override
  bool shouldRepaint(covariant _Fin25DPainter old) =>
      pose != old.pose ||
      state != old.state ||
      phase != old.phase ||
      gesture != old.gesture ||
      adjust != old.adjust ||
      blink != old.blink ||
      dark != old.dark ||
      peeking != old.peeking ||
      left != old.left ||
      reveal != old.reveal;
}
