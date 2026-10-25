import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../models/companion_model.dart';
import '../../analytics/widgets/fin_character.dart';

/// A compact FIN moment for the composer: FIN beside a purse, with a single
/// coin moving into the purse on income and out of it on expense.
///
/// Deliberately small and non-interactive so it reads as companion feedback
/// rather than decoration that competes with the form.
class FinPurseMoment extends StatefulWidget {
  const FinPurseMoment({super.key, required this.isIncome, this.height = 62});

  final bool isIncome;
  final double height;

  @override
  State<FinPurseMoment> createState() => _FinPurseMomentState();
}

class _FinPurseMomentState extends State<FinPurseMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coin = AnimationController(
    vsync: this,
    duration: HorizonMotion.expressive,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant FinPurseMoment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isIncome != widget.isIncome) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _coin.value = 1;
      } else {
        _coin.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _coin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final accent = widget.isIncome ? tokens.surplus : tokens.outflow;
    final height = widget.height;
    final width = height * 1.22;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: _coin,
            builder: (context, child) {
              final t = Curves.easeInOutCubic.transform(_coin.value);
              final visible = t < 0.995;
              final start = Offset(width * 0.44, height * 0.44);
              final end = Offset(width * 0.82, height * 0.24);
              final from = widget.isIncome ? start : end;
              final to = widget.isIncome ? end : start;
              final position = Offset.lerp(from, to, t)!;
              final arc = -math.sin(math.pi * t) * height * 0.16;
              final opacity = t < 0.82 ? 1.0 : (1 - (t - 0.82) / 0.18);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: FinCharacter(
                      size: height * 0.94,
                      state: widget.isIncome
                          ? FinCharacterState.happy
                          : FinCharacterState.attentive,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: CustomPaint(
                      size: Size(30, 27),
                      painter: _PursePainter(
                        accent: accent,
                        clasp: tokens.luminousGold,
                        dark: tokens.isDark,
                      ),
                    ),
                  ),
                  if (visible)
                    Positioned(
                      left: position.dx,
                      top: position.dy + arc,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.luminousGold,
                            border: Border.all(
                              color: tokens.luminousGold.withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A small, geometric purse — never a piggy bank.
class _PursePainter extends CustomPainter {
  const _PursePainter({
    required this.accent,
    required this.clasp,
    required this.dark,
  });

  final Color accent;
  final Color clasp;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.3, w * 0.96, h * 0.68),
      Radius.circular(w * 0.17),
    );
    final flap = Path()
      ..moveTo(w * 0.1, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.0, w * 0.9, h * 0.42)
      ..lineTo(w * 0.9, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.1, h * 0.52)
      ..close();

    final fill = Paint()..color = accent.withValues(alpha: dark ? 0.2 : 0.14);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = accent.withValues(alpha: dark ? 0.8 : 0.7);

    canvas.drawRRect(body, fill);
    canvas.drawPath(
      flap,
      Paint()..color = accent.withValues(alpha: dark ? 0.32 : 0.24),
    );
    canvas.drawRRect(body, rim);
    canvas.drawPath(flap, rim);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: w * 0.16,
          height: h * 0.14,
        ),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = clasp.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _PursePainter old) =>
      old.accent != accent || old.clasp != clasp || old.dark != dark;
}
