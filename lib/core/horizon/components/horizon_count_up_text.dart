import 'package:flutter/material.dart';

import '../tokens/horizon_formatters.dart';
import '../tokens/horizon_motion.dart';

/// Animated financial readout.
///
/// Values settle on the exact formatted amount so a count-up can never lie
/// about the final figure. Under reduced motion the value renders immediately.
class HorizonCountUpAmount extends StatelessWidget {
  const HorizonCountUpAmount({
    super.key,
    required this.amount,
    required this.style,
    this.duration = HorizonMotion.telemetryReveal,
    this.curve = HorizonMotion.enter,
    this.decimalDigits = true,
  });

  /// Target amount. The widget counts toward this value.
  final double amount;

  /// Text style of the rendered amount.
  final TextStyle style;

  final Duration duration;
  final Curve curve;
  final bool decimalDigits;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Text(
        HorizonFormatters.formatInr(amount, decimalDigits: decimalDigits),
        style: style,
      );
    }

    // Keyed on the amount so a period switch replays the count-up.
    return TweenAnimationBuilder<double>(
      key: ValueKey<double>(amount),
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: curve,
      builder: (context, value, _) => Text(
        HorizonFormatters.formatInr(value, decimalDigits: decimalDigits),
        style: style,
      ),
    );
  }
}
