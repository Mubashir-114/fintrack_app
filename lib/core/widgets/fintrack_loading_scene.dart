import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Branded illustration only: the growth curve is not a financial chart.
/// Painting listens directly to the controller; animation never rebuilds layout.
class FinTrackLoadingScene extends StatefulWidget {
  const FinTrackLoadingScene({
    super.key,
    this.height = 220,
    this.animate = true,
  });
  final double height;
  final bool animate;

  @override
  State<FinTrackLoadingScene> createState() => _FinTrackLoadingSceneState();
}

class _FinTrackLoadingSceneState extends State<FinTrackLoadingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  void _syncMotion() {
    final animate =
        widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = .65;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant FinTrackLoadingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LoadingPainter(
              progress: _controller,
              cyan: colors.isDark
                  ? const Color(0xFF63DFDE)
                  : const Color(0xFF087D88),
              gold: const Color(0xFFD6AD72),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter({
    required this.progress,
    required this.cyan,
    required this.gold,
  }) : super(repaint: progress);
  final Animation<double> progress;
  final Color cyan;
  final Color gold;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 320, size.height / 220);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 220 * scale) / 2,
    );
    canvas.scale(scale);
    final phase = progress.value;
    // Fine data tracks flow into the wallet. No percentages or fake values.
    for (var i = 0; i < 3; i++) {
      final y = 104.0 + i * 24;
      final path = Path()
        ..moveTo(18, y + 12)
        ..lineTo(54, y + 12)
        ..quadraticBezierTo(66, y + 12, 72, y)
        ..lineTo(102, y);
      canvas.drawPath(
        path,
        Paint()
          ..color = cyan.withValues(alpha: .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final metric = path.computeMetrics().first;
      final position = metric
          .getTangentForOffset(((phase + i * .28) % 1) * metric.length)!
          .position;
      canvas.drawCircle(position, 2.3, Paint()..color = cyan);
    }
    // Small fixed shadow; no blur filters.
    canvas.drawOval(
      const Rect.fromLTWH(98, 190, 132, 8),
      Paint()..color = const Color(0xFF102235).withValues(alpha: .12),
    );
    final wallet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(91, 104, 146, 84),
      const Radius.circular(19),
    );
    canvas.drawRRect(
      wallet,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF263F59), Color(0xFF101E31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(wallet.outerRect),
    );
    canvas.drawRRect(
      wallet,
      Paint()
        ..color = gold.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      const Offset(107, 116),
      const Offset(220, 116),
      Paint()
        ..color = gold.withValues(alpha: .42)
        ..strokeWidth = 1,
    );
    final clasp = RRect.fromRectAndRadius(
      const Rect.fromLTWH(204, 133, 44, 29),
      const Radius.circular(9),
    );
    canvas.drawRRect(clasp, Paint()..color = const Color(0xFF32485D));
    canvas.drawRRect(
      clasp,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(const Offset(218, 147.5), 3.5, Paint()..color = gold);
    canvas.drawLine(
      const Offset(105, 176),
      const Offset(184, 176),
      Paint()
        ..color = gold.withValues(alpha: .35)
        ..strokeWidth = 1,
    );
    // Coin float is just three pixels; the wallet stays still.
    final coinCenter = Offset(139, 73 + math.sin(phase * math.pi * 2) * 3);
    canvas.drawCircle(
      coinCenter,
      22,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFF7DEAD), gold],
        ).createShader(Rect.fromCircle(center: coinCenter, radius: 22)),
    );
    canvas.drawCircle(
      coinCenter,
      18,
      Paint()
        ..color = const Color(0xFF9F773F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Draw the rupee as a native path so it is independent of font fallback.
    canvas.save();
    canvas.translate(coinCenter.dx, coinCenter.dy);
    final rupee = Path()
      ..moveTo(-8, -10)
      ..lineTo(8, -10)
      ..moveTo(-8, -5)
      ..lineTo(8, -5)
      ..moveTo(-4, -10)
      ..quadraticBezierTo(10, -8, 4, 0)
      ..quadraticBezierTo(1, 4, -6, 3)
      ..lineTo(7, 13);
    canvas.drawPath(
      rupee,
      Paint()
        ..color = const Color(0xFF172536)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Signature growth mark is decorative and contains no data axis.
    final growth = Path()
      ..moveTo(177, 94)
      ..cubicTo(197, 94, 201, 73, 218, 73)
      ..cubicTo(235, 73, 242, 48, 267, 38);
    final metric = growth.computeMetrics().first;
    final reveal = (phase * 2.8).clamp(0.0, 1.0);
    canvas.drawPath(
      metric.extractPath(0, metric.length * reveal),
      Paint()
        ..shader = LinearGradient(
          colors: [gold, cyan],
        ).createShader(const Rect.fromLTWH(177, 38, 90, 56))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    if (reveal > .97) {
      canvas.drawPath(
        Path()
          ..moveTo(255, 38)
          ..lineTo(267, 38)
          ..lineTo(264, 50),
        Paint()
          ..color = cyan
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3,
      );
    }
    // FIN growth-leaf accent; does not replace the character rig.
    canvas.drawLine(
      const Offset(112, 148),
      const Offset(112, 134),
      Paint()
        ..color = gold
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      Path()
        ..moveTo(112, 140)
        ..quadraticBezierTo(98, 138, 102, 129)
        ..quadraticBezierTo(113, 129, 112, 140),
      Paint()..color = gold,
    );
    canvas.drawPath(
      Path()
        ..moveTo(112, 137)
        ..quadraticBezierTo(112, 124, 124, 125)
        ..quadraticBezierTo(125, 134, 112, 137),
      Paint()..color = cyan,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.gold != gold ||
      oldDelegate.progress != progress;
}
