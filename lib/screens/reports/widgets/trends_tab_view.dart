import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fin_surface.dart';
import '../../../core/widgets/financial_chart.dart';
import '../../../models/report_models.dart';
import '../../../providers/currency_provider.dart';

/// Complete redesign of the Trends Tab for FinTrack 2.0.
/// Provides a compact high-quality financial summary, an interactive
/// cash-flow chart with period inspection and single-month adaptations,
/// and fact-based financial observations.
class TrendsTabView extends StatefulWidget {
  const TrendsTabView({
    super.key,
    required this.summary,
    required this.trends,
    required this.periodLabel,
    required this.onRefresh,
  });

  final ReportSummary? summary;
  final List<TrendsReport> trends;
  final String periodLabel;
  final Future<void> Function() onRefresh;

  @override
  State<TrendsTabView> createState() => _TrendsTabViewState();
}

class _TrendsTabViewState extends State<TrendsTabView> {
  int? _selectedTrendIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final summary = widget.summary;

    if (summary == null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: colors.primary,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: const [
            EmptyState(
              icon: Icons.analytics_outlined,
              title: "No trend data available",
              description:
                  "Record transactions or adjust the date range to see financial trends.",
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Financial Overview - Primary Performance Card
            _buildPrimaryPerformanceCard(context, summary, colors),
            const SizedBox(height: 12),

            // Secondary Compact Metrics Row
            _buildSecondaryMetrics(context, summary, colors),
            const SizedBox(height: 20),

            // B. Interactive Cash-Flow Chart
            _buildChartSection(context, colors),
            const SizedBox(height: 20),

            // C. Financial Observations
            _buildObservationsSection(context, summary, widget.trends, colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // A. FINANCIAL OVERVIEW
  // ===========================================================================

  Widget _buildPrimaryPerformanceCard(
    BuildContext context,
    ReportSummary summary,
    dynamic colors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.watch<CurrencyProvider>();
    final isNetPositive = summary.netBalance >= 0;
    final netColor = isNetPositive ? colors.success : colors.danger;

    return FinSurface(
      padding: EdgeInsets.zero,
      accent: colors.primary,
      emphasized: true,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Period label & Contextual trend indicator
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.periodLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: netColor.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: netColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNetPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 13,
                            color: netColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isNetPositive ? "Net Surplus" : "Net Deficit",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: netColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Net cash flow display
                Text(
                  "Net Cash Flow",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${isNetPositive ? '+' : '-'}${currency.format(summary.netBalance.abs())}",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Income vs Expense comparison ratio bar
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Income: ${currency.format(summary.totalIncome)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Expense: ${currency.format(summary.totalExpense)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                FinancialFlowBar(
                  income: summary.totalIncome,
                  expense: summary.totalExpense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetrics(
    BuildContext context,
    ReportSummary summary,
    dynamic colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Savings Rate',
            value: '${summary.savingsRate.toStringAsFixed(1)}%',
            icon: Icons.savings_outlined,
            accentColor: summary.savingsRate >= 0
                ? colors.primary
                : colors.danger,
            colors: colors,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Transactions',
            value: '${summary.totalTransactions}',
            icon: Icons.receipt_long_rounded,
            accentColor: colors.info,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required dynamic colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Icon(icon, size: 13, color: accentColor)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // B. INTERACTIVE CASH-FLOW CHART
  // ===========================================================================

  Widget _buildChartSection(BuildContext context, dynamic colors) {
    final trends = widget.trends;

    return FinSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with legend
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cash-Flow Trends",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Monthly inflow vs outflow analysis",
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem("Inflow", colors.success, colors),
                  const SizedBox(width: 10),
                  _buildLegendItem("Outflow", colors.danger, colors),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart Body depending on data availability
          if (trends.isEmpty ||
              trends.every((item) => item.income == 0 && item.expense == 0))
            _buildEmptyChartState(colors)
          else if (trends.length == 1)
            _buildSinglePeriodView(trends.first, colors)
          else
            _buildMultiPeriodChart(trends, colors),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color dotColor, dynamic colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartState(dynamic colors) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 40,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            "No recorded cash flow in this range",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Record transactions or widen your date filter to see monthly trends",
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Meaningful single-period comparison rather than an isolated thin bar
  /// floating inside a huge empty chart.
  Widget _buildSinglePeriodView(TrendsReport report, dynamic colors) {
    final currency = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = report.income - report.expense;
    final isNetPositive = net >= 0;
    final netColor = isNetPositive ? colors.success : colors.danger;
    final totalFlow = report.income + report.expense;
    final incomePct = totalFlow > 0 ? (report.income / totalFlow * 100) : 0.0;
    final expensePct = totalFlow > 0 ? (report.expense / totalFlow * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                "${report.monthName} ${report.year}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: netColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "${isNetPositive ? '+' : '-'}${currency.format(net.abs())} Net",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: netColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          FinancialComparisonRow(
            label: 'Monthly Inflow',
            amount: currency.format(report.income),
            share: incomePct / 100,
            color: colors.success,
          ),
          const SizedBox(height: 14),
          FinancialComparisonRow(
            label: 'Monthly Outflow',
            amount: currency.format(report.expense),
            share: expensePct / 100,
            color: colors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            "Displaying isolated single-month performance. Additional months will plot multi-period trends.",
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: colors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiPeriodChart(List<TrendsReport> trends, dynamic colors) {
    final currency = context.watch<CurrencyProvider>();

    double maxVal = 0.0;
    for (final item in trends) {
      if (item.income > maxVal) maxVal = item.income;
      if (item.expense > maxVal) maxVal = item.expense;
    }
    final adjustedMax = maxVal <= 0 ? 100.0 : maxVal * 1.25;

    final selectedIdx =
        _selectedTrendIndex != null &&
            _selectedTrendIndex! >= 0 &&
            _selectedTrendIndex! < trends.length
        ? _selectedTrendIndex!
        : trends.length - 1;
    final selectedReport = trends[selectedIdx];
    final selectedNet = selectedReport.income - selectedReport.expense;
    final isNetPositive = selectedNet >= 0;

    return Column(
      children: [
        FinancialChart(
          description:
              'Monthly cash flow. ${trends.map((item) => '${item.monthName} ${item.year}: income ${currency.format(item.income)}, expense ${currency.format(item.expense)}').join('; ')}',
          child: SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: adjustedMax,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.spot != null) {
                      final index = response!.spot!.touchedBarGroupIndex;
                      if (index >= 0 && index < trends.length) {
                        setState(() {
                          _selectedTrendIndex = index;
                        });
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.elevated,
                    tooltipBorder: BorderSide(color: colors.cardBorder),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final String type = rodIndex == 0 ? "Inflow" : "Outflow";
                      final Color valColor = rodIndex == 0
                          ? colors.success
                          : colors.danger;
                      return BarTooltipItem(
                        "$type\n${currency.format(rod.toY)}",
                        TextStyle(
                          color: valColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: adjustedMax / 4,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          NumberFormat.compactCurrency(
                            symbol: currency.currencySymbol,
                            decimalDigits: 0,
                          ).format(value),
                          style: TextStyle(
                            fontSize: 9,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < trends.length) {
                          final isSelected = idx == selectedIdx;
                          final name = trends[idx].monthName;
                          final label = name.length >= 3
                              ? name.substring(0, 3)
                              : name;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: adjustedMax / 4,
                  getDrawingHorizontalLine: (val) {
                    return FlLine(
                      color: colors.divider.withValues(alpha: 0.35),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(trends.length, (index) {
                  final item = trends[index];
                  final isSelected = index == selectedIdx;
                  final barWidth = math.max(
                    6.0,
                    math.min(12.0, 160.0 / (trends.length * 2)),
                  );

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: item.income,
                        color: isSelected
                            ? colors.success
                            : colors.success.withValues(alpha: 0.75),
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: item.expense,
                        color: isSelected
                            ? colors.danger
                            : colors.danger.withValues(alpha: 0.75),
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.standard,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Inspection Banner for selected month
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.quick,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${selectedReport.monthName} ${selectedReport.year}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Inflow: ${currency.format(selectedReport.income)}  •  Outflow: ${currency.format(selectedReport.expense)}",
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isNetPositive ? colors.success : colors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${isNetPositive ? '+' : '-'}${currency.format(selectedNet.abs())}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNetPositive ? colors.success : colors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // C. FINANCIAL OBSERVATIONS
  // ===========================================================================

  Widget _buildObservationsSection(
    BuildContext context,
    ReportSummary summary,
    List<TrendsReport> trends,
    dynamic colors,
  ) {
    final currency = context.watch<CurrencyProvider>();
    final observations = <Widget>[];

    // Observation 1: Savings Status
    if (summary.savingsRate >= 20) {
      observations.add(
        _buildObservationRow(
          icon: Icons.check_circle_outline_rounded,
          iconColor: colors.success,
          title: "Healthy Savings Retention",
          detail:
              "You preserved ${summary.savingsRate.toStringAsFixed(1)}% of your income into net savings during this period.",
          colors: colors,
        ),
      );
    } else if (summary.savingsRate > 0) {
      observations.add(
        _buildObservationRow(
          icon: Icons.info_outline_rounded,
          iconColor: colors.primary,
          title: "Positive Net Flow",
          detail:
              "Net cash flow is positive with ${summary.savingsRate.toStringAsFixed(1)}% saved from total receipts.",
          colors: colors,
        ),
      );
    } else if (summary.totalExpense > summary.totalIncome) {
      final deficit = (summary.totalExpense - summary.totalIncome).abs();
      observations.add(
        _buildObservationRow(
          icon: Icons.warning_amber_rounded,
          iconColor: colors.danger,
          title: "Spending Exceeded Income",
          detail:
              "Outflows surpassed inflows by ${currency.format(deficit)} over this reporting period.",
          colors: colors,
        ),
      );
    } else {
      final empty = summary.totalIncome == 0 && summary.totalExpense == 0;
      observations.add(
        _buildObservationRow(
          icon: Icons.info_outline_rounded,
          iconColor: colors.info,
          title: empty ? 'No Recorded Cash Flow' : 'Balanced Cash Flow',
          detail: empty
              ? 'Record transactions or choose another period to see observations.'
              : 'Recorded income and outflow are equal for this period.',
          colors: colors,
        ),
      );
    }

    // Observation 2: Peak Spending Period (if multi-period)
    if (trends.length > 1) {
      TrendsReport peak = trends.first;
      for (final t in trends) {
        if (t.expense > peak.expense) peak = t;
      }
      observations.add(
        _buildObservationRow(
          icon: Icons.trending_up_rounded,
          iconColor: colors.warning,
          title: "Peak Outflow Period",
          detail:
              "Highest expenditure occurred in ${peak.monthName} ${peak.year} (${currency.format(peak.expense)}).",
          colors: colors,
        ),
      );

      // Observation 3: Consecutive trend if >= 2
      final latest = trends.last;
      final prior = trends[trends.length - 2];
      if (prior.expense > 0) {
        final change = ((latest.expense - prior.expense) / prior.expense) * 100;
        final isIncrease = change > 0;
        observations.add(
          _buildObservationRow(
            icon: isIncrease
                ? Icons.arrow_outward_rounded
                : Icons.south_east_rounded,
            iconColor: isIncrease ? colors.danger : colors.success,
            title: change == 0
                ? 'Monthly Spending Unchanged'
                : (isIncrease
                      ? "Monthly Spending Increased"
                      : "Monthly Spending Reduced"),
            detail:
                "Outflow shifted by ${change.abs().toStringAsFixed(1)}% from ${prior.monthName} to ${latest.monthName}.",
            colors: colors,
          ),
        );
      }
    }

    // Observation 4: Activity Volume
    observations.add(
      _buildObservationRow(
        icon: Icons.receipt_long_rounded,
        iconColor: colors.info,
        title: "Transaction Volume",
        detail:
            "${summary.totalTransactions} transactions accounted for across the selected window.",
        colors: colors,
      ),
    );

    return FinSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Financial Observations",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...observations,
        ],
      ),
    );
  }

  Widget _buildObservationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String detail,
    required dynamic colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.35,
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
