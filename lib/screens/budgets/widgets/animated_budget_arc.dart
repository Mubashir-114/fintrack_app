import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// Clean, modern partial circular arc representing budget consumption.
///
/// Sweeps smoothly from 0% to the target usage ratio on entrance,
/// displays count-up figures in the focal center, and communicates
/// threshold status with subtle, calm financial colors.
class AnimatedBudgetArc extends StatefulWidget {
  const AnimatedBudgetArc({
    super.key,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.utilizationPercentage,
    required this.status,
    this.size = 148,
    this.strokeWidth = 9.0,
  });

  final double limit;
  final double spent;
  final double remaining;
  final double utilizationPercentage;
  final String status;
  final double size;
  final double strokeWidth;

  @override
  State<AnimatedBudgetArc> createState() => _AnimatedBudgetArcState();
}

class _AnimatedBudgetArcState extends State<AnimatedBudgetArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _arcAnimation;
  late final Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _arcAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion && !_controller.isCompleted) {
      _controller.value = 1.0;
    }

    final targetRatio = widget.limit > 0
        ? (widget.spent / widget.limit).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded =
        widget.status == 'exceeded' || widget.spent > widget.limit;
    final isApproaching =
        widget.status == 'approaching_limit' ||
        (!isExceeded && widget.utilizationPercentage >= 70.0);

    Color activeColor;
    if (isExceeded) {
      activeColor = tokens.outflow;
    } else if (isApproaching) {
      activeColor = tokens.warning;
    } else {
      activeColor = tokens.ionCyan;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animatedRatio = reduceMotion
              ? targetRatio
              : _arcAnimation.value * targetRatio;

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _BudgetArcPainter(
                  progressRatio: animatedRatio,
                  trackColor: tokens.surface3.withValues(alpha: 0.7),
                  progressColor: activeColor,
                  strokeWidth: widget.strokeWidth,
                  thresholdColor: tokens.warning.withValues(alpha: 0.8),
                  isExceeded: isExceeded,
                ),
              ),
              FadeTransition(
                opacity: reduceMotion
                    ? const AlwaysStoppedAnimation(1.0)
                    : _contentFadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.utilizationPercentage.toStringAsFixed(1)}%",
                      style: HorizonTypography.displayHero.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: isExceeded ? tokens.outflow : tokens.textHigh,
                        fontFeatures: HorizonTypography.tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExceeded ? "OVER LIMIT" : "USED",
                      style: HorizonTypography.labelCaps.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isExceeded ? tokens.outflow : tokens.textLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetArcPainter extends CustomPainter {
  const _BudgetArcPainter({
    required this.progressRatio,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.thresholdColor,
    required this.isExceeded,
  });

  final double progressRatio;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final Color thresholdColor;
  final bool isExceeded;

  // Open 240-degree arc: starts at 150 deg (5pi/6), sweeps 240 deg (4pi/3)
  static const double _startAngle = (150 * math.pi) / 180;
  static const double _totalSweep = (240 * math.pi) / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, _startAngle, _totalSweep, false, trackPaint);

    // 80% threshold tick on the track
    final thresholdAngle = _startAngle + (_totalSweep * 0.8);
    final thresholdOffset = Offset(
      center.dx + radius * math.cos(thresholdAngle),
      center.dy + radius * math.sin(thresholdAngle),
    );
    final tickPaint = Paint()
      ..color = thresholdColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(thresholdOffset, strokeWidth * 0.38, tickPaint);

    // Progress Arc
    if (progressRatio > 0.001) {
      final activePaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final currentSweep = _totalSweep * progressRatio.clamp(0.0, 1.0);
      canvas.drawArc(arcRect, _startAngle, currentSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(_BudgetArcPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
