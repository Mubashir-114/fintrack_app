import 'package:flutter/material.dart';

import '../tokens/horizon_motion.dart';

/// Staggered entrance used by the dashboard's financial sections.
///
/// Each section fades and rises a few pixels on first layout, ordered by
/// [order], so data appears in reading order instead of all at once. Under
/// reduced motion the child is shown immediately.
class HorizonStaggeredReveal extends StatelessWidget {
  const HorizonStaggeredReveal({
    super.key,
    required this.order,
    required this.child,
    this.distance = 12,
    this.duration = HorizonMotion.standard,
  });

  /// Zero-based position in the entrance sequence.
  final int order;
  final Widget child;
  final double distance;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final int staggerMs = (order.clamp(0, 6)) * 60;
    final int totalMs = duration.inMilliseconds + staggerMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(
        totalMs == 0 ? 0 : staggerMs / totalMs,
        1,
        curve: HorizonMotion.enter,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
