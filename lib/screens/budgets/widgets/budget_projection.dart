import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// FinTrack HORIZON — Reusable Budget Projection Block.
///
/// Converts complex velocity forecasting into plain human financial guidance.
class BudgetProjection extends StatelessWidget {
  const BudgetProjection({
    super.key,
    required this.dailyAverage,
    required this.projectedTotal,
    required this.daysRemaining,
    required this.isExceeded,
    required this.isApproaching,
  });

  final String dailyAverage;
  final String projectedTotal;
  final int daysRemaining;
  final bool isExceeded;
  final bool isApproaching;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final accentColor = isExceeded
        ? tokens.outflow
        : (isApproaching ? tokens.warning : tokens.surplus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
      ),
      child: Row(
        children: [
          Icon(
            isExceeded
                ? Icons.warning_amber_rounded
                : (isApproaching ? Icons.trending_up_rounded : Icons.check_circle_outline_rounded),
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExceeded
                  ? "Current pace: Likely to reach $projectedTotal this month."
                  : (isApproaching
                      ? "Current pace: Likely to spend $projectedTotal this month."
                      : "Current pace: Spending is on track for this cycle."),
              style: HorizonTypography.bodySm.copyWith(
                fontSize: 11,
                color: tokens.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
