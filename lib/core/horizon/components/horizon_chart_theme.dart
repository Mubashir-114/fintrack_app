import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_formatters.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Styling tokens and helpers for fl_chart visualizations in FinTrack // HORIZON.
class HorizonChartTheme {
  HorizonChartTheme._();

  /// Primary telemetry line styling in Ion Cyan with gradient fill.
  static LineChartBarData telemetryLine({
    required BuildContext context,
    required List<FlSpot> spots,
    Color? color,
    bool isCurved = true,
    bool showDots = false,
  }) {
    final tokens = HorizonThemeTokens.of(context);
    final accent = color ?? tokens.ionCyan;

    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      curveSmoothness: 0.35,
      color: accent,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3.5,
          color: accent,
          strokeWidth: 1.5,
          strokeColor: tokens.surface1,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  /// Secondary projection line in Electric Indigo (dashed vector).
  static LineChartBarData projectionLine({
    required BuildContext context,
    required List<FlSpot> spots,
  }) {
    final tokens = HorizonThemeTokens.of(context);

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: tokens.electricIndigo,
      barWidth: 2.0,
      dashArray: [6, 4],
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Standard grid data with subtle neutral hairline lines.
  static FlGridData gridData(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(
        color: tokens.rimNeutral,
        strokeWidth: 1,
      ),
    );
  }

  /// Standard telemetry tooltip styled in Level 3 overlay surface.
  static LineTouchData lineTouchData(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => tokens.surface3,
        tooltipBorder: BorderSide(color: tokens.rimCyanActive, width: 1),
        tooltipBorderRadius: HorizonDimensions.borderDefault,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              HorizonFormatters.formatInr(spot.y),
              HorizonTypography.tabularAmountSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
