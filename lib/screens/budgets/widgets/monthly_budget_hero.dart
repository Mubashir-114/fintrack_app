import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';
import 'animated_budget_arc.dart';

/// FinTrack HORIZON — Modern Open Financial Monthly Budget Hero.
///
/// Replaces the dense, multi-bordered legacy card with an open, airy composition
/// ruled by typography, amount hierarchy, and the signature [AnimatedBudgetArc].
class MonthlyBudgetHero extends StatelessWidget {
  const MonthlyBudgetHero({
    super.key,
    required this.overall,
    required this.period,
    required this.currency,
  });

  final BudgetOverallProgressModel overall;
  final BudgetPeriodModel period;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final limitNum = double.tryParse(overall.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(overall.actualSpending) ?? 0.0;
    final remainingNum =
        double.tryParse(overall.remainingAmount) ?? (limitNum - spentNum);
    final utilizationNum =
        double.tryParse(overall.utilizationPercentage) ??
        (limitNum > 0 ? (spentNum / limitNum * 100) : 0.0);
    final projectedNum = double.tryParse(overall.projectedSpending) ?? 0.0;
    final dailyBurnNum = double.tryParse(overall.dailyBurnRate) ?? 0.0;

    final isExceeded = overall.status == "exceeded" || spentNum > limitNum;
    final isApproaching = overall.status == "approaching_limit";

    Color statusColor;
    String statusLabel;
    if (isExceeded) {
      statusColor = tokens.outflow;
      statusLabel = "EXCEEDED";
    } else if (isApproaching) {
      statusColor = tokens.warning;
      statusLabel = "APPROACHING LIMIT";
    } else {
      statusColor = tokens.surplus;
      statusLabel = "ON TRACK";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Semantics(
          label: "Monthly Total Budget",
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: tokens.surface1,
              borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
              border: Border.all(color: tokens.rimNeutral),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Title + Semantic Status Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Monthly Total Budget",
                              style: HorizonTypography.headlineSm.copyWith(
                                color: tokens.textHigh,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          HorizonDimensions.radiusSM,
                        ),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Presentation: Responsive Split or Stack
                Builder(
                  builder: (context) {
                    final textScale = MediaQuery.textScalerOf(
                      context,
                    ).scale(1.0);
                    final isNarrow =
                        constraints.maxWidth < 350 || textScale > 1.3;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Arc Left
                          AnimatedBudgetArc(
                            limit: limitNum,
                            spent: spentNum,
                            remaining: remainingNum,
                            utilizationPercentage: utilizationNum,
                            status: overall.status,
                            size: 156,
                          ),
                          const SizedBox(width: 24),
                          // Key Financial Metrics Right
                          Expanded(
                            child: _buildMetricsColumn(
                              tokens: tokens,
                              limitNum: limitNum,
                              spentNum: spentNum,
                              remainingNum: remainingNum,
                              utilizationNum: utilizationNum,
                              isExceeded: isExceeded,
                              statusColor: statusColor,
                            ),
                          ),
                        ],
                      );
                    } else if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: AnimatedBudgetArc(
                              limit: limitNum,
                              spent: spentNum,
                              remaining: remainingNum,
                              utilizationPercentage: utilizationNum,
                              status: overall.status,
                              size: 130,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildMetricsColumn(
                            tokens: tokens,
                            limitNum: limitNum,
                            spentNum: spentNum,
                            remainingNum: remainingNum,
                            utilizationNum: utilizationNum,
                            isExceeded: isExceeded,
                            statusColor: statusColor,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedBudgetArc(
                            limit: limitNum,
                            spent: spentNum,
                            remaining: remainingNum,
                            utilizationPercentage: utilizationNum,
                            status: overall.status,
                            size: 136,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricsColumn(
                              tokens: tokens,
                              limitNum: limitNum,
                              spentNum: spentNum,
                              remainingNum: remainingNum,
                              utilizationNum: utilizationNum,
                              isExceeded: isExceeded,
                              statusColor: statusColor,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: tokens.rowDivider),
                const SizedBox(height: 12),

                // Secondary Financial Analytics Row (Daily average, Projected spend, Current pace)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  spacing: 12,
                  children: [
                    _SecondaryMetricTile(
                      label: "Daily average",
                      value: "${currency.format(dailyBurnNum)}/d",
                      tokens: tokens,
                    ),
                    _SecondaryMetricTile(
                      label: "Projected total",
                      value: currency.format(projectedNum),
                      tokens: tokens,
                      highlightColor: isExceeded ? tokens.outflow : null,
                    ),
                    _SecondaryMetricTile(
                      label: "Days remaining",
                      value: "${period.daysRemaining} days",
                      tokens: tokens,
                    ),
                  ],
                ),

                // Helpful Financial Guidance Note
                if (projectedNum > 0 && period.daysRemaining > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(
                        HorizonDimensions.radiusSM,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExceeded
                              ? Icons.info_outline_rounded
                              : (isApproaching
                                    ? Icons.trending_up_rounded
                                    : Icons.check_circle_outline_rounded),
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isExceeded
                                ? "Current pace: You are likely to spend ${currency.format(projectedNum)} this month."
                                : (isApproaching
                                      ? "Current pace: Projected to reach ${currency.format(projectedNum)} by month end."
                                      : "Current pace: Spending is on track within your monthly limit."),
                            style: HorizonTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: tokens.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsColumn({
    required HorizonThemeTokens tokens,
    required double limitNum,
    required double spentNum,
    required double remainingNum,
    required double utilizationNum,
    required bool isExceeded,
    required Color statusColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Remaining Amount Hero
        Text(
          isExceeded ? "Over budget by" : "Remaining balance",
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textLow,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        HorizonCountUpAmount(
          amount: remainingNum.abs(),
          style: HorizonTypography.headlineLg.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: remainingNum >= 0 ? tokens.textHigh : tokens.outflow,
            letterSpacing: -0.6,
            fontFeatures: HorizonTypography.tabularFigures,
          ),
        ),
        const SizedBox(height: 6),

        // Spent and Limit Subtitle
        Text.rich(
          TextSpan(
            style: HorizonTypography.bodySm.copyWith(
              color: tokens.textMedium,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: currency.format(spentNum),
                style: TextStyle(
                  color: isExceeded ? tokens.outflow : tokens.textHigh,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: " spent of "),
              TextSpan(
                text: currency.format(limitNum),
                style: TextStyle(
                  color: tokens.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Utilization and cycle days
        Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "${overall.utilizationPercentage}% used",
              style: HorizonTypography.bodySm.copyWith(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              " · ${period.daysRemaining} days left",
              style: HorizonTypography.bodySm.copyWith(
                fontSize: 11,
                color: tokens.textLow,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryMetricTile extends StatelessWidget {
  const _SecondaryMetricTile({
    required this.label,
    required this.value,
    required this.tokens,
    this.highlightColor,
  });

  final String label;
  final String value;
  final HorizonThemeTokens tokens;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HorizonTypography.labelCaps.copyWith(
            color: tokens.textLow,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: HorizonTypography.bodyMd.copyWith(
            color: highlightColor ?? tokens.textHigh,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            fontFeatures: HorizonTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
