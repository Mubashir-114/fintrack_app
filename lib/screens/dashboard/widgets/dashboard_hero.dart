import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../models/dashboard_models.dart';
import 'dashboard_metric_strip.dart';

/// The financial overview hero.
///
/// One anchoring surface holds the whole money story: net worth count-up,
/// month-over-month delta, the line-draw cash-flow trend, the three key
/// figures as an open strip, and assets/liabilities. No nested boxes.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.overview,
    required this.sparkValues,
    required this.flowCaption,
    required this.onShowCashFlow,
  });

  final FinancialOverview? overview;
  final List<double> sparkValues;
  final String flowCaption;
  final VoidCallback onShowCashFlow;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    final netWorth = double.tryParse(overview?.netWorth ?? "0") ?? 0;
    final income = double.tryParse(overview?.monthlyIncome ?? "0") ?? 0;
    final expense = double.tryParse(overview?.monthlyExpenses ?? "0") ?? 0;
    final savings = double.tryParse(overview?.monthlyNetSavings ?? "0") ?? 0;
    final totalAssets = double.tryParse(overview?.totalAssets ?? "0") ?? 0;
    final totalLiabilities =
        double.tryParse(overview?.totalLiabilities ?? "0") ?? 0;

    final String deltaRaw = overview?.incomeChangePercent ?? "+0.0";
    final bool positiveDelta = !deltaRaw.startsWith('-');
    final Color deltaColor = positiveDelta ? tokens.surplus : tokens.outflow;

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      cornerAccentColor: tokens.ionCyan,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Telemetry label + real month-over-month delta.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "NET WORTH",
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.textMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 10,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.shield_rounded, size: 13, color: tokens.ionCyan),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.14),
                  borderRadius: HorizonDimensions.borderFull,
                  border: Border.all(color: deltaColor.withValues(alpha: 0.3)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positiveDelta
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$deltaRaw% MoM',
                        style: HorizonTypography.labelCaps.copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Main count-up balance.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: HorizonCountUpAmount(
              amount: netWorth,
              style: HorizonTypography.tabularAmountLg.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: tokens.textHigh,
                letterSpacing: -0.02 * 36,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Cash-flow access + flow context.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: onShowCashFlow,
                style: TextButton.styleFrom(
                  foregroundColor: tokens.ionCyan,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cash-flow trend'),
              ),
              Text(
                flowCaption,
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Line-draw cash-flow trend.
          HorizonTrendLine(
            values: sparkValues,
            color: tokens.ionCyan,
            dotSurfaceColor: tokens.surface2,
            height: 72,
          ),

          const SizedBox(height: 12),

          DashboardMetricStrip(
            income: income,
            expense: expense,
            savings: savings,
          ),

          const SizedBox(height: 12),

          // Assets & liabilities, kept light under the strip.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total Assets: ",
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: tokens.textMedium,
                      ),
                    ),
                    HorizonCountUpAmount(
                      amount: totalAssets,
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total Liabilities: ",
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: tokens.textMedium,
                      ),
                    ),
                    HorizonCountUpAmount(
                      amount: totalLiabilities,
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.outflow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
