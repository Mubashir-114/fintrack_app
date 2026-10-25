import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';
import 'animated_budget_progress.dart';

/// FinTrack HORIZON — Modern Net Savings Progress Strip.
///
/// Clean, tonal surface displaying net savings progress against target or income.
class BudgetSavingsCard extends StatelessWidget {
  const BudgetSavingsCard({
    super.key,
    required this.savings,
    required this.currency,
    required this.onEditTarget,
  });

  final BudgetSavingsProgressModel savings;
  final CurrencyProvider currency;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    final incomeNum = double.tryParse(savings.totalIncome) ?? 0.0;
    final netSavingsNum = double.tryParse(savings.netSavings) ?? 0.0;
    final targetNum = double.tryParse(savings.savingsTarget ?? '') ?? 0.0;
    final isAchieved = savings.isTargetAchieved;

    final progressVal = targetNum > 0
        ? (netSavingsNum / targetNum).clamp(0.0, 1.0)
        : 0.0;

    final statusColor = isAchieved && targetNum > 0 ? tokens.surplus : tokens.electricIndigo;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
        border: Border.all(color: tokens.rimNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.savings_rounded, size: 16, color: statusColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Net Savings Progress",
                    style: HorizonTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: tokens.textHigh,
                    ),
                  ),
                ],
              ),
              HorizonPressable(
                label: targetNum > 0 ? "Edit savings target" : "Set savings target",
                onPressed: onEditTarget,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    targetNum > 0 ? "Edit Target" : "Set Target",
                    style: HorizonTypography.labelCaps.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tokens.ionCyan,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Amounts: Net Saved vs Target / Income
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Net Saved: ${currency.format(netSavingsNum)}",
                style: HorizonTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: netSavingsNum >= 0 ? tokens.surplus : tokens.outflow,
                  fontFeatures: HorizonTypography.tabularFigures,
                ),
              ),
              Text(
                targetNum > 0
                    ? "Target: ${currency.format(targetNum)}"
                    : "Income: ${currency.format(incomeNum)}",
                style: HorizonTypography.bodySm.copyWith(
                  fontSize: 11,
                  color: tokens.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (targetNum > 0) ...[
            const SizedBox(height: 8),
            AnimatedBudgetProgress(
              progressRatio: progressVal,
              color: isAchieved ? tokens.surplus : tokens.electricIndigo,
              trackColor: tokens.surface3.withValues(alpha: 0.7),
              height: 4.0,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${savings.progressPercentage ?? '0.0'}% achieved",
                  style: HorizonTypography.bodySm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isAchieved ? tokens.surplus : tokens.electricIndigo,
                  ),
                ),
                if (isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tokens.surplus.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "GOAL REACHED ✨",
                      style: HorizonTypography.labelCaps.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: tokens.surplus,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
