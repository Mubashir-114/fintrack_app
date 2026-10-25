import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../tokens/horizon_motion.dart';

/// Cash-flow line that draws itself in when data arrives or changes.
///
/// The path is a smoothed polyline revealed left-to-right with a filled area
/// beneath the drawn portion, ending on a single telemetry dot. Under reduced
/// motion the line is rendered fully drawn with no travel.
class HorizonTrendLine extends StatefulWidget {
  const HorizonTrendLine({
    super.key,
    required this.values,
    required this.color,
    this.height = 72,
    this.strokeWidth = 2.5,
    this.dotSurfaceColor,
    this.duration = HorizonMotion.telemetryReveal,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final Color? dotSurfaceColor;
  final Duration duration;

  @override
  State<HorizonTrendLine> createState() => _HorizonTrendLineState();
}

class _HorizonTrendLineState extends State<HorizonTrendLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void didUpdateWidget(HorizonTrendLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.values, widget.values)) {
      _controller.forward(from: 0);
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _TrendPainter(
              values: widget.values,
              color: widget.color,
              dotSurfaceColor: widget.dotSurfaceColor,
              strokeWidth: widget.strokeWidth,
              progress: reduceMotion ? 1 : _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.dotSurfaceColor,
    required this.strokeWidth,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final Color? dotSurfaceColor;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0) return;

    final double minV = values.reduce(math.min);
    final double maxV = values.reduce(math.max);
    final double range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final int n = values.length;
    final double padY = 8;
    final List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final double x = n == 1 ? size.width : (size.width * i) / (n - 1);
      final double normalized = (values[i] - minV) / range;
      final double y =
          size.height - padY - normalized * (size.height - padY * 2);
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      _drawDot(canvas, points.first);
      return;
    }

    final Path full = _smoothPath(points);
    final List<PathMetric> metrics = full.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final double drawn = metrics.first.length * progress.clamp(0.0, 1.0);
    final Path visible = metrics.first.extractPath(0, drawn);

    // Area fill under the drawn segment only, so the reveal reads as progress.
    final Path fill = Path.from(visible);
    fill
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      visible,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    if (progress >= 0.999) _drawDot(canvas, points.last);
  }

  void _drawDot(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 4.5, Paint()..color = color);
    final surface = dotSurfaceColor;
    if (surface != null) {
      canvas.drawCircle(center, 2.2, Paint()..color = surface);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final Offset mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.values.length != values.length;
}
