import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../models/budget_model.dart';
import '../../../models/companion_model.dart';
import '../../../providers/currency_provider.dart';
import '../../analytics/widgets/fin_character.dart';

/// FinTrack HORIZON — Lighter Contextual FIN Budget Insight.
///
/// Integrates FIN seamlessly as a supportive financial companion without
/// heavy telemetry cards or alarmist styling.
class FinBudgetInsight extends StatelessWidget {
  const FinBudgetInsight({
    super.key,
    required this.overall,
    required this.period,
    required this.currency,
    required this.onViewSuggestions,
  });

  final BudgetOverallProgressModel overall;
  final BudgetPeriodModel period;
  final CurrencyProvider currency;
  final VoidCallback onViewSuggestions;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final limitNum = double.tryParse(overall.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(overall.actualSpending) ?? 0.0;
    final remainingNum = double.tryParse(overall.remainingAmount) ?? (limitNum - spentNum);
    final utilizationNum = double.tryParse(overall.utilizationPercentage) ??
        (limitNum > 0 ? (spentNum / limitNum * 100) : 0.0);

    final isExceeded = overall.status == "exceeded" || spentNum > limitNum;
    final isApproaching = overall.status == "approaching_limit" ||
        (!isExceeded && utilizationNum >= 75.0);

    // FIN Character Pose: Calm & helpful
    FinCharacterState finState;
    Color accentBorder;
    String headline;
    String subline;

    if (isExceeded) {
      finState = FinCharacterState.explaining;
      accentBorder = tokens.outflow.withValues(alpha: 0.35);
      headline = "Spending has exceeded your monthly plan.";
      subline = "${currency.format(remainingNum.abs())} over limit with ${period.daysRemaining} days left in the cycle.";
    } else if (isApproaching) {
      finState = FinCharacterState.caution;
      accentBorder = tokens.warning.withValues(alpha: 0.35);
      headline = "You're using your monthly budget faster than planned.";
      subline = "${currency.format(remainingNum)} remains for the next ${period.daysRemaining} days.";
    } else {
      finState = FinCharacterState.attentive;
      accentBorder = tokens.rimNeutral;
      headline = "Your monthly spending pace is steady.";
      subline = "${currency.format(remainingNum)} available across the next ${period.daysRemaining} days.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
        border: Border.all(color: accentBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small, friendly FIN companion
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.surface1,
              borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
              border: Border.all(color: tokens.rimNeutral),
            ),
            alignment: Alignment.center,
            child: FinCharacter(
              size: 38,
              state: finState,
            ),
          ),
          const SizedBox(width: 12),

          // Contextual Guidance Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: HorizonTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: tokens.textHigh,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: HorizonTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: tokens.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                HorizonPressable(
                  label: "View budget suggestions",
                  onPressed: onViewSuggestions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View suggestions",
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.ionCyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: tokens.ionCyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
