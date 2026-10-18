import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../models/companion_model.dart';
import 'fin_visual_controller.dart';

/// Shared native articulated rig. Size includes the leaf and planted feet.
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
  /// Used so the gripping hand lands on the clipped edge at every width.
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
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  );
  late final AnimationController _gesture = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 1800),
  );
  /// Very slow weight shift: one small posture adjustment per cycle.
  late final AnimationController _posture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 17000),
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
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _sync();
  }

  void _sync() {
    if (_observedState != _state) {
      _observedState = _state;
      if (_motionAllowed && _state == FinCharacterState.greeting) {
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
      _gesture.value = 1;
      _posture.value = 0;
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
    _idle.dispose();
    _gesture.dispose();
    _posture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'FIN financial companion, currently ${_state.label}',
    button: widget.onTap != null,
    child: GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size * .72,
        height: widget.size,
        child: RepaintBoundary(
          child: TweenAnimationBuilder<_Pose>(
            tween: _PoseTween(end: _Pose.forState(_state)),
            duration: _motionAllowed
                ? const Duration(milliseconds: 480)
                : Duration.zero,
            curve: Curves.easeInOutCubic,
            builder: (context, posture, _) => AnimatedBuilder(
              animation: Listenable.merge([_idle, _gesture, _posture]),
              builder: (context, _) => CustomPaint(
                painter: _FinPainter(
                  pose: posture,
                  state: _state,
                  phase: _motionAllowed ? _idle.value : 0,
                  gesture: _gesture.value,
                  adjust: _motionAllowed ? _postureAdjustment(_posture.value) : 0,
                  dark: Theme.of(context).brightness == Brightness.dark,
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

/// A single calm weight shift per cycle, flat for the rest of it.
double _postureAdjustment(double t) {
  if (t < .58 || t > .80) return 0;
  return math.sin(((t - .58) / .22) * math.pi);
}

/// Angles start with the arm pointing down. Feet never move with breathing.
class _Pose {
  final double head, torso, shoulderL, elbowL, shoulderR, elbowR;
  const _Pose({
    this.head = -.035,
    this.torso = -.015,
    this.shoulderL = .13,
    this.elbowL = -.22,
    this.shoulderR = -.1,
    this.elbowR = .25,
  });
  factory _Pose.forState(FinCharacterState state) => switch (state) {
    FinCharacterState.greeting => const _Pose(
      head: -.09,
      shoulderL: 1.05,
      elbowL: 1.7,
    ),
    FinCharacterState.listening || FinCharacterState.attentive => const _Pose(
      head: .11,
      torso: .018,
      elbowL: -.4,
      elbowR: .4,
    ),
    FinCharacterState.thinking => const _Pose(
      head: -.14,
      shoulderR: .35,
      elbowR: 2.55,
      shoulderL: -.15,
      elbowL: -.6,
    ),
    FinCharacterState.explaining => const _Pose(
      head: -.06,
      shoulderL: .45,
      elbowL: .8,
      shoulderR: -.15,
      elbowR: .55,
    ),
    FinCharacterState.happy ||
    FinCharacterState.celebrating ||
    FinCharacterState.encouraging => const _Pose(
      head: -.07,
      shoulderL: .85,
      elbowL: 1.55,
      shoulderR: -.4,
      elbowR: .7,
    ),
    FinCharacterState.concerned ||
    FinCharacterState.caution ||
    FinCharacterState.error => const _Pose(
      head: .09,
      shoulderL: -.3,
      elbowL: -1.05,
      shoulderR: .3,
      elbowR: 1.05,
    ),
    FinCharacterState.confused || FinCharacterState.emptyData => const _Pose(
      head: .17,
      shoulderL: .45,
      elbowL: .85,
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
  );
  @override
  bool operator ==(Object other) =>
      other is _Pose &&
      head == other.head &&
      torso == other.torso &&
      shoulderL == other.shoulderL &&
      elbowL == other.elbowL &&
      shoulderR == other.shoulderR &&
      elbowR == other.elbowR;
  @override
  int get hashCode =>
      Object.hash(head, torso, shoulderL, elbowL, shoulderR, elbowR);
}

class _PoseTween extends Tween<_Pose> {
  _PoseTween({required _Pose end}) : super(begin: end, end: end);
  @override
  _Pose lerp(double t) => _Pose.lerp(begin!, end!, t);
}

/// Model space is 230 x 320. Each part rotates about its physical joint.
class _FinPainter extends CustomPainter {
  final _Pose pose;
  final FinCharacterState state;
  final double phase;
  final double gesture;
  final double adjust;
  final bool dark, peeking, left;
  final double reveal;
  const _FinPainter({
    required this.pose,
    required this.state,
    required this.phase,
    required this.gesture,
    required this.adjust,
    required this.dark,
    required this.peeking,
    required this.left,
    required this.reveal,
  });
  static const navy = Color(0xFF07172B),
      cyan = Color(0xFF41E5F2),
      gold = Color(0xFFE9B95F),
      bronze = Color(0xFF9C672A);
  double get breath => math.sin(phase * math.pi * 2);
  bool get joyful => {
    FinCharacterState.greeting,
    FinCharacterState.happy,
    FinCharacterState.celebrating,
    FinCharacterState.encouraging,
  }.contains(state);
  bool get caution => {
    FinCharacterState.caution,
    FinCharacterState.concerned,
    FinCharacterState.error,
  }.contains(state);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 230, size.height / 320);
    if (!peeking) {
      c.drawOval(
        const Rect.fromLTWH(48, 302, 134, 10),
        Paint()
          ..color = navy.withValues(alpha: dark ? .45 : .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    _leg(c, -1);
    _leg(c, 1);
    _shell(c, const Rect.fromLTWH(86, 204, 58, 31), 15);
    _metal(c, const Rect.fromLTWH(86, 204, 58, 7), 3);
    c.save();
    c.translate(115, 208);
    c.rotate(
      pose.torso +
          breath * .004 +
          adjust * .012 +
          (peeking ? (left ? -.018 : .018) : 0),
    );
    c.translate(-115, -208);
    c.save();
    c.translate(115, 202);
    c.scale(1 + breath * .003, 1 + breath * .004);
    c.translate(-115, -202);
    final chest = Path()
      ..moveTo(86, 125)
      ..quadraticBezierTo(115, 116, 144, 125)
      ..cubicTo(158, 132, 157, 165, 143, 197)
      ..quadraticBezierTo(115, 212, 87, 197)
      ..cubicTo(73, 165, 72, 132, 86, 125)
      ..close();
    _shellPath(c, chest, const Rect.fromLTWH(76, 120, 78, 85));
    _joint(c, const Offset(92, 189), 3.5);
    _joint(c, const Offset(138, 189), 3.5);
    _emblem(c);
    if (peeking) {
      _peekingArm(c);
    } else {
      _arm(c, -1, pose.shoulderL, pose.elbowL);
      _arm(c, 1, pose.shoulderR, pose.elbowR);
    }
    c.restore();
    _metal(c, const Rect.fromLTWH(101, 111, 28, 13), 5);
    _head(c);
    c.restore();
    c.restore();
  }

  Paint _ceramic(Rect rect) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [
              Color(0xFFFFFEF8),
              Color(0xFFF6EDD9),
              Color(0xFFD8C5A2),
              Color(0xFFA89372),
            ]
          : const [
              Colors.white,
              Color(0xFFFFF8E7),
              Color(0xFFE2D1B5),
              Color(0xFFC2AC87),
            ],
      stops: const [0, .4, .8, 1],
    ).createShader(rect);
  void _shell(Canvas c, Rect rect, double radius) {
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    c.drawRRect(
      shape.shift(const Offset(1, 2)),
      Paint()..color = navy.withValues(alpha: .24),
    );
    c.drawRRect(shape, _ceramic(rect));
    c.drawRRect(
      shape.deflate(.7),
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  void _shellPath(Canvas c, Path path, Rect rect) {
    c.drawPath(
      path.shift(const Offset(1, 2)),
      Paint()..color = navy.withValues(alpha: .2),
    );
    c.drawPath(path, _ceramic(rect));
    c.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _metal(Canvas c, Rect rect, double radius) {
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..shader = const LinearGradient(
          colors: [bronze, gold, Color(0xFFFFE9A7), bronze],
          stops: [0, .35, .55, 1],
        ).createShader(rect),
    );
  }

  void _joint(Canvas c, Offset at, double r) {
    c.drawCircle(at, r + 1.8, Paint()..color = navy);
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.4),
          colors: [Color(0xFFFFE9A7), gold, bronze],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    c.drawCircle(at, r * .48, Paint()..color = bronze.withValues(alpha: .5));
  }

  void _leg(Canvas c, double side) {
    final hip = Offset(115 + side * 17, 224);
    final knee = Offset(115 + side * 23, side < 0 ? 256 : 258);
    final ankle = Offset(115 + side * 30, 292);
    _joint(c, hip, 9);
    _segment(c, hip, knee, 23, 17);
    _joint(c, knee, 8);
    _segment(c, knee + const Offset(0, 3), ankle, 18, 24);
    _metal(c, Rect.fromCenter(center: ankle, width: 25, height: 7), 3);
    final foot = Rect.fromLTWH(ankle.dx - 19 + side * 3, 289, 38, 16);
    _shell(c, foot, 10);
    c.drawLine(
      Offset(foot.left + 3, 304),
      Offset(foot.right - 3, 304),
      Paint()
        ..color = navy
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _segment(Canvas c, Offset start, Offset end, double top, double bottom) {
    c.save();
    c.translate(start.dx, start.dy);
    c.rotate(math.atan2(end.dy - start.dy, end.dx - start.dx) - math.pi / 2);
    final length = (end - start).distance;
    final path = Path()
      ..moveTo(-top / 2, 4)
      ..quadraticBezierTo(0, -2, top / 2, 4)
      ..lineTo(bottom / 2, length - 4)
      ..quadraticBezierTo(0, length + 2, -bottom / 2, length - 4)
      ..close();
    _shellPath(
      c,
      path,
      Rect.fromLTWH(-top / 2, 0, math.max(top, bottom), length),
    );
    c.restore();
  }

  void _arm(Canvas c, double side, double shoulder, double elbow) {
    c.save();
    c.translate(115 + side * 44, 134);
    final wave = state == FinCharacterState.greeting
        ? math.sin(gesture * math.pi * 4) * .12 * (1 - gesture)
        : 0;
    c.rotate(
      shoulder +
          breath * .008 +
          (side < 0 ? wave : 0) +
          (side > 0 ? adjust * .045 : 0),
    );
    _joint(c, Offset.zero, 10);
    _shell(c, const Rect.fromLTWH(-11, -8, 22, 23), 10);
    _shell(c, const Rect.fromLTWH(-8, 10, 16, 32), 8);
    c.translate(0, 43);
    _joint(c, Offset.zero, 7);
    c.rotate(elbow);
    _shell(c, const Rect.fromLTWH(-9, 4, 18, 31), 8);
    _metal(c, const Rect.fromLTWH(-8, 30, 16, 5), 2);
    c.translate(0, 41);
    _hand(
      c,
      open:
          side < 0 &&
          (joyful ||
              state == FinCharacterState.explaining ||
              state == FinCharacterState.emptyData ||
              state == FinCharacterState.confused),
    );
    c.restore();
  }

  void _hand(Canvas c, {bool open = false}) {
    _shell(c, const Rect.fromLTWH(-8, -6, 16, 16), 6);
    for (var i = 0; i < 3; i++) {
      _shell(
        c,
        Rect.fromLTWH(
          -7 + i * 5,
          open ? 4 : 5,
          4,
          open ? 12.0 - (i - 1).abs() * 2 : 5,
        ),
        2,
      );
    }
    c.save();
    c.translate(-7, -1);
    c.rotate(open ? .6 : -.3);
    _shell(c, const Rect.fromLTWH(-4, 0, 5, 10), 3);
    c.restore();
  }

  void _head(Canvas c) {
    c.save();
    c.translate(115, 111);
    c.rotate(
      pose.head +
          breath * .012 +
          adjust * .02 +
          (peeking ? (left ? .12 : -.12) : 0),
    );
    c.translate(-115, -111);
    _joint(c, const Offset(57, 76), 11);
    _joint(c, const Offset(173, 76), 11);
    _shell(c, const Rect.fromLTWH(58, 39, 114, 75), 29);
    final visor = RRect.fromRectAndRadius(
      const Rect.fromLTWH(68, 49, 94, 54),
      const Radius.circular(23),
    );
    c.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF203B50), navy, Color(0xFF030B16)],
        ).createShader(visor.outerRect),
    );
    c.drawRRect(
      visor.deflate(1),
      Paint()
        ..color = cyan.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    c.drawPath(
      Path()
        ..moveTo(81, 58)
        ..quadraticBezierTo(108, 48, 142, 58),
      Paint()
        ..color = Colors.white.withValues(alpha: .22)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    _eyes(c);
    _metal(c, const Rect.fromLTWH(112, 24, 6, 17), 3);
    c.save();
    c.translate(115, 27);
    c.rotate(breath * .035);
    for (final side in [-1.0, 1.0]) {
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(side * 20, -24, side * 28, -13)
        ..quadraticBezierTo(side * 22, 1, 0, 0)
        ..close();
      c.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE9A7), gold, bronze],
          ).createShader(const Rect.fromLTWH(-28, -22, 56, 23)),
      );
    }
    c.restore();
    c.restore();
  }

  void _eyes(Canvas c) {
    final blink = phase > .91 && phase < .935;
    for (final side in [-1.0, 1.0]) {
      final look = peeking
          ? (left ? 3.0 : -3.0)
          : state == FinCharacterState.thinking
          ? 3.0
          : breath * .5;
      final x = 115 + side * 22 + look,
          y = state == FinCharacterState.thinking ? 76.0 : 80.0;
      final eye = Path();
      if (blink) {
        eye
          ..moveTo(x - 6, y)
          ..lineTo(x + 6, y);
      } else if (joyful || state == FinCharacterState.idle) {
        eye
          ..moveTo(x - 7, y + 2)
          ..quadraticBezierTo(x, y - 12, x + 7, y + 2);
      } else if (caution) {
        eye
          ..moveTo(x - 7, y - side * 3)
          ..quadraticBezierTo(x, y + 4, x + 7, y + side * 3);
      } else {
        eye.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 9, height: 14),
            const Radius.circular(4.5),
          ),
        );
      }
      c.drawPath(
        eye,
        Paint()
          ..color = cyan.withValues(alpha: dark ? .5 : .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      c.drawPath(
        eye,
        Paint()
          ..color = cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _emblem(Canvas c) {
    _joint(c, const Offset(115, 157), 16);
    c.drawPath(
      Path()
        ..moveTo(105, 162)
        ..lineTo(112, 155)
        ..lineTo(117, 158)
        ..lineTo(126, 149)
        ..moveTo(120, 149)
        ..lineTo(126, 149)
        ..lineTo(126, 155),
      Paint()
        ..color = const Color(0xFFFFFCF1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// The far arm enters from beyond the clipped edge, fingers curling over it
  /// as if holding on while FIN leans into the page.
  void _peekingArm(Canvas c) {
    // The clipped edge in model space, e.g. x≈130 when 57% is revealed.
    final edge = left ? 230 * (1 - reveal) : 230 * reveal;
    final wrist = Offset(left ? edge - 26 : edge + 26, 158);
    final hand = Offset(left ? edge + 6 : edge - 6, 129);
    _segment(c, wrist, hand, 16, 13);
    c.save();
    c.translate(hand.dx, hand.dy);
    c.rotate(left ? -.2 : .2);
    _hand(c);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _FinPainter old) =>
      old.pose != pose ||
      old.state != state ||
      old.phase != phase ||
      old.gesture != gesture ||
      old.adjust != adjust ||
      old.dark != dark ||
      old.peeking != peeking ||
      old.left != left ||
      old.reveal != reveal;
}
