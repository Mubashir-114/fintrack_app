import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_formatters.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';
import 'horizon_surface.dart';

/// Telemetry metric card for FinTrack // HORIZON.
/// Features Level 2 elevation, uppercase telemetry tags (`label-caps`),
/// and prominent tabular financial readouts.
class HorizonTelemetryCard extends StatelessWidget {
  const HorizonTelemetryCard({
    super.key,
    required this.label,
    required this.amount,
    this.deltaPercent,
    this.deltaLabel,
    this.isPositiveDelta,
    this.accentColor,
    this.icon,
    this.onTap,
  });

  final String label;
  final num amount;
  final double? deltaPercent;
  final String? deltaLabel;
  final bool? isPositiveDelta;
  final Color? accentColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final formattedAmount = HorizonFormatters.formatInr(amount);

    Color deltaColor = tokens.textMedium;
    if (isPositiveDelta != null) {
      deltaColor = isPositiveDelta! ? tokens.surplus : tokens.outflow;
    }

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      onTap: onTap,
      cornerAccentColor: accentColor ?? tokens.ionCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textMedium,
                  fontSize: 10,
                  letterSpacing: 0.08 * 10,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: accentColor ?? tokens.ionCyan,
                ),
            ],
          ),
          const SizedBox(height: HorizonDimensions.spaceSM),
          Text(
            formattedAmount,
            style: HorizonTypography.tabularAmountLg.copyWith(
              color: tokens.textHigh,
              fontSize: 26,
            ),
          ),
          if (deltaPercent != null || deltaLabel != null) ...[
            const SizedBox(height: HorizonDimensions.spaceSM),
            Row(
              children: [
                if (isPositiveDelta != null)
                  Icon(
                    isPositiveDelta! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 14,
                    color: deltaColor,
                  ),
                if (deltaPercent != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${deltaPercent! >= 0 ? '+' : ''}${deltaPercent!.toStringAsFixed(1)}%',
                    style: HorizonTypography.bodySm.copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (deltaLabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    deltaLabel!,
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textLow,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
