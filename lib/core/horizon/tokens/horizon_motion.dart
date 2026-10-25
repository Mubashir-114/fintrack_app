import 'package:flutter/animation.dart';

/// Motion and tactile feedback tokens for FinTrack // HORIZON.
/// Mimics physical cockpit instrumentation toggles, milled metal edges,
/// and micro-actuated cards.
class HorizonMotion {
  HorizonMotion._();

  /// Press interaction duration: 120ms.
  static const Duration press = Duration(milliseconds: 120);

  /// Quick micro-interaction duration: 200ms.
  static const Duration quick = Duration(milliseconds: 200);

  /// Standard screen and sheet transition duration: 300ms.
  static const Duration standard = Duration(milliseconds: 300);

  /// Telemetry data reveal / chart draw duration: 420ms.
  static const Duration telemetryReveal = Duration(milliseconds: 420);

  /// Ambient background telemetry pulse duration: 4000ms.
  static const Duration ambient = Duration(milliseconds: 4000);

  /// One-off expressive feedback such as a companion gesture: 520ms.
  static const Duration expressive = Duration(milliseconds: 520);

  /// Scale factor applied during tactile press feedback.
  static const double pressScaleFactor = 0.98;

  /// High-density cockpit curve with crisp actuation.
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);

  /// Decelerated entrance curve.
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);

  /// Accelerated exit curve.
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);
}
