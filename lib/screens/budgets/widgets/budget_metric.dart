import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// FinTrack HORIZON — Reusable Budget Metric Block.
///
/// Displays financial data with strong amount hierarchy and tabular figures.
class BudgetMetric extends StatelessWidget {
  const BudgetMetric({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textLow,
            fontSize: isPrimary ? 10 : 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: isPrimary
              ? HorizonTypography.headlineLg.copyWith(
                  color: valueColor ?? tokens.textHigh,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontFeatures: HorizonTypography.tabularFigures,
                )
              : HorizonTypography.bodyMd.copyWith(
                  color: valueColor ?? tokens.textHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: HorizonTypography.tabularFigures,
                ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: HorizonTypography.bodySm.copyWith(
              color: tokens.textMedium,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
