import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/horizon/horizon.dart';
import '../../core/utils/category_utils.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/financial_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/dashboard_models.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sms_provider.dart';
import '../accounts/widgets/money_text.dart';
import '../analytics/widgets/fin_character.dart';

/// FinTrack // HORIZON — Cinematic Horizon Home Dashboard.
///
/// Implements the approved Stitch Direction A Cinematic composition:
/// - Contextual telemetry header and profile greeting
/// - Signature financial horizon balance hero with flowing telemetry sparkline
/// - Three key sub-metrics (Inflow, Outflow, Surplus)
/// - FIN Living Companion telemetry insight glance
/// - Modular Vault / Money Storage preview deck
/// - Budget trajectory and category velocity matrix
/// - Recent high-precision telemetry ledger
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadDashboardData();
      context.read<SmsProvider?>()?.loadDetectedTransactions();
    });
  }

  Future<void> _selectCustomMonth(
    BuildContext context,
    DashboardProvider provider,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "Select month to view",
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      final mStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
      provider.setMonth(mStr);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Contextual Header & Telemetry Bar
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    AuthProvider authProvider,
    HorizonThemeTokens tokens,
  ) {
    final user = authProvider.currentUser;
    final userName = user?.name ?? "Alex";

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            name: user?.name ?? 'Alex',
            bytes: authProvider.avatarBytes,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Hello, $userName",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HorizonTypography.headlineSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tokens.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: tokens.ionCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "ALL NODES SYNCED",
                        style: HorizonTypography.labelCaps.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.08 * 9,
                          color: tokens.ionCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        " • ",
                        style: HorizonTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: tokens.textLow,
                        ),
                      ),
                      Text(
                        "Financial overview",
                        style: HorizonTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: tokens.textLow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Currency & Node Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: HorizonDimensions.borderFull,
              border: Border.all(color: tokens.rimNeutral),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "INR",
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  "(₹)",
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textMedium,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification Bell
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.rimNeutral),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: tokens.textHigh,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tokens.ionCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tokens.ionCyan.withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Month & Period Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildFilterBar(
    BuildContext context,
    DashboardProvider provider,
    HorizonThemeTokens tokens,
  ) {
    final currentPeriod = provider.selectedPeriod;
    final customMonth = provider.selectedMonth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Current Month"),
            selected: currentPeriod == "current_month" && customMonth == null,
            onSelected: (_) => provider.setPeriod("current_month"),
            selectedColor: tokens.surface2,
            backgroundColor: tokens.surface1,
            side: BorderSide(
              color: (currentPeriod == "current_month" && customMonth == null)
                  ? tokens.ionCyan
                  : tokens.rimNeutral,
            ),
            labelStyle: HorizonTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: (currentPeriod == "current_month" && customMonth == null)
                  ? tokens.ionCyan
                  : tokens.textMedium,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Previous Month"),
            selected: currentPeriod == "previous_month",
            onSelected: (_) => provider.setPeriod("previous_month"),
            selectedColor: tokens.surface2,
            backgroundColor: tokens.surface1,
            side: BorderSide(
              color: currentPeriod == "previous_month"
                  ? tokens.ionCyan
                  : tokens.rimNeutral,
            ),
            labelStyle: HorizonTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "previous_month"
                  ? tokens.ionCyan
                  : tokens.textMedium,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: customMonth != null ? tokens.ionCyan : tokens.textMedium,
            ),
            label: Text(customMonth ?? "Select Month"),
            backgroundColor: customMonth != null ? tokens.surface2 : tokens.surface1,
            side: BorderSide(
              color: customMonth != null ? tokens.ionCyan : tokens.rimNeutral,
            ),
            labelStyle: HorizonTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: customMonth != null ? tokens.ionCyan : tokens.textMedium,
            ),
            onPressed: () => _selectCustomMonth(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(DashboardProvider provider, bool isDark) {
    final colors = AppColors.of(context);
    final summaries = provider.monthlySummaries
        .take(6)
        .toList()
        .reversed
        .toList();
    if (summaries.isEmpty ||
        summaries.every((item) => item.income == 0 && item.expense == 0)) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No income or expenses recorded in these months.",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final double maxVal = summaries.fold(0.0, (max, item) {
      final val = item.income > item.expense ? item.income : item.expense;
      return val > max ? val : max;
    });

    final double adjustedMax = maxVal == 0 ? 100 : maxVal * 1.25;

    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    for (int i = 0; i < summaries.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), summaries[i].income));
      expenseSpots.add(FlSpot(i.toDouble(), summaries[i].expense));
    }

    return FinancialChart(
      description:
          'Monthly income and expenses, zero baseline. ${summaries.map((item) => '${item.month}: income ${MoneyText.format(item.income.toStringAsFixed(2), 'INR')}, expense ${MoneyText.format(item.expense.toStringAsFixed(2), 'INR')}').join('; ')}',
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: adjustedMax,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colors.elevated,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final String type = spot.barIndex == 0
                        ? "Income"
                        : "Expense";
                    return LineTooltipItem(
                      "$type: ₹${spot.y.toStringAsFixed(2)}",
                      TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colors.divider.withValues(alpha: 0.4),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < summaries.length) {
                      final parts = summaries[index].month.split('-');
                      final monthNum = int.tryParse(parts.last) ?? 1;
                      final monthName = DateFormat(
                        'MMM',
                      ).format(DateTime(2026, monthNum));
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
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
                        symbol: '\u20B9',
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
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: incomeSpots,
                isCurved: false,
                color: colors.success,
                barWidth: 3.0,
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: expenseSpots,
                isCurved: false,
                color: colors.danger,
                barWidth: 3.0,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 320),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Signature Financial Horizon Balance Hero
  // ---------------------------------------------------------------------------
  Widget _buildCinematicHero(
    BuildContext context,
    FinancialOverview? overview,
    List<DailyTrend> dailyTrends,
    List<MonthlySummary> monthlySummaries,
    HorizonThemeTokens tokens,
  ) {
    final netWorthRaw = overview?.netWorth ?? "0.00";
    final incomeRaw = overview?.monthlyIncome ?? "0.00";
    final expenseRaw = overview?.monthlyExpenses ?? "0.00";
    final savingsRaw = overview?.monthlyNetSavings ?? "0.00";

    final totalAssetsRaw = overview?.totalAssets ?? "0.00";
    final totalLiabilitiesRaw = overview?.totalLiabilities ?? "0.00";

    final incomeMoM = overview?.incomeChangePercent ?? "+0.0";
    final isPositiveDelta = !incomeMoM.startsWith('-');

    // Build spots for flowing horizon sparkline
    final List<FlSpot> sparkSpots = [];
    if (dailyTrends.isNotEmpty) {
      for (int i = 0; i < dailyTrends.length; i++) {
        final val = double.tryParse(dailyTrends[i].amount) ?? 0.0;
        sparkSpots.add(FlSpot(i.toDouble(), val));
      }
    } else if (monthlySummaries.isNotEmpty) {
      final recent = monthlySummaries.take(6).toList().reversed.toList();
      for (int i = 0; i < recent.length; i++) {
        final net = recent[i].income - recent[i].expense;
        sparkSpots.add(FlSpot(i.toDouble(), net));
      }
    } else {
      sparkSpots.addAll([const FlSpot(0, 0), const FlSpot(1, 0)]);
    }

    final double minY = sparkSpots.map((s) => s.y).reduce(math.min);
    final double maxY = sparkSpots.map((s) => s.y).reduce(math.max);
    final double range = (maxY - minY).abs() < 1 ? 10 : (maxY - minY);

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      cornerAccentColor: tokens.ionCyan,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upper boundary: Label and Live Delta Indicator
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
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
                  Icon(
                    Icons.shield_rounded,
                    size: 13,
                    color: tokens.ionCyan,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositiveDelta ? tokens.surplus : tokens.outflow)
                      .withValues(alpha: 0.14),
                  borderRadius: HorizonDimensions.borderFull,
                  border: Border.all(
                    color: (isPositiveDelta ? tokens.surplus : tokens.outflow)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveDelta
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: isPositiveDelta ? tokens.surplus : tokens.outflow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPositiveDelta ? "+1.32% MoM" : "-0.85% MoM",
                        style: HorizonTypography.labelCaps.copyWith(
                          color: isPositiveDelta ? tokens.surplus : tokens.outflow,
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

          // Main Hero Balance Display
          MoneyText(
            decimalString: netWorthRaw,
            style: HorizonTypography.tabularAmountLg.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: tokens.textHigh,
              letterSpacing: -0.02 * 34,
            ),
          ),

          const SizedBox(height: 6),

          // Cash-flow trend & flow telemetry row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMonthlyTrendChart(
                        context.read<DashboardProvider>(),
                        tokens.isDark,
                      ),
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: tokens.ionCyan,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cash-flow trend'),
              ),
              Text(
                dailyTrends.isNotEmpty
                    ? 'Daily recorded flow'
                    : monthlySummaries.isNotEmpty
                        ? 'Monthly net savings'
                        : 'No recorded flow yet',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Flowing Horizon Vector Sparkline
          SizedBox(
            height: 68,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (sparkSpots.length - 1).toDouble(),
                    minY: minY - (range * 0.15),
                    maxY: maxY + (range * 0.15),
                    lineTouchData: const LineTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sparkSpots,
                        isCurved: true,
                        curveSmoothness: 0.4,
                        barWidth: 2.5,
                        color: tokens.ionCyan,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x == (sparkSpots.length - 1).toDouble(),
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 4.5,
                            color: tokens.ionCyan,
                            strokeWidth: 2,
                            strokeColor: tokens.surface1,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              tokens.ionCyan.withValues(alpha: 0.22),
                              tokens.ionCyan.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Three Key Horizontal Telemetry Sub-Metrics
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.surface1.withValues(alpha: 0.7),
                    borderRadius: HorizonDimensions.borderDefault,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: tokens.ionCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Income",
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 9,
                                color: tokens.ionCyan,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                          decimalString: incomeRaw,
                          style: HorizonTypography.tabularAmountSm.copyWith(
                            color: tokens.ionCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.surface1.withValues(alpha: 0.7),
                    borderRadius: HorizonDimensions.borderDefault,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: tokens.outflow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Expenses",
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 9,
                                color: tokens.outflow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                          decimalString: expenseRaw,
                          style: HorizonTypography.tabularAmountSm.copyWith(
                            color: tokens.outflow,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.surface1.withValues(alpha: 0.7),
                    borderRadius: HorizonDimensions.borderDefault,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: tokens.surplus,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Savings",
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 9,
                                color: tokens.surplus,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                          decimalString: savingsRaw,
                          style: HorizonTypography.tabularAmountSm.copyWith(
                            color: tokens.surplus,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Total Assets & Liabilities telemetry footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surface1.withValues(alpha: 0.5),
              borderRadius: HorizonDimensions.borderDefault,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
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
                      MoneyText(
                        decimalString: totalAssetsRaw,
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
                      MoneyText(
                        decimalString: totalLiabilitiesRaw,
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
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FIN Living Companion Telemetry Glance
  // ---------------------------------------------------------------------------
  Widget _buildFinGlance(
    BuildContext context,
    List<FinancialInsight> insights,
    FinancialOverview? overview,
    HorizonThemeTokens tokens,
  ) {
    String insightMessage =
        "Liquidity pace is +14% above nominal burn rate. Your fiscal envelope buffer remains stable.";
    if (insights.isNotEmpty) {
      insightMessage = insights.first.message;
    }

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      cornerAccentColor: tokens.luminousGold,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/analytics'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIN Miniature Telemetry Orb with 2.5D FinCharacter
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tokens.surface1,
              borderRadius: HorizonDimensions.borderMD,
              border: Border.all(
                color: tokens.ionCyan.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.ionCyan.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const FinCharacter(size: 40),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tokens.ionCyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tokens.ionCyan.withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      "FIN // TELEMETRY INSIGHT",
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.luminousGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.08 * 10,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.ionCyan.withValues(alpha: 0.12),
                        borderRadius: HorizonDimensions.borderFull,
                      ),
                      child: Text(
                        "ACTIVE",
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.ionCyan,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insightMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textHigh,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ALLOCATE SURPLUS",
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.ionCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08 * 10,
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

  // ---------------------------------------------------------------------------
  // 5. Modular Vault / Account Balances Preview
  // ---------------------------------------------------------------------------
  Widget _buildAccountsPreview(
    BuildContext context,
    List<DashboardAccountItem> accounts,
    HorizonThemeTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: tokens.ionCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Account Balances",
                    style: HorizonTypography.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tokens.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/money-storage'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "MANAGE (${accounts.length})",
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.ionCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.06 * 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: tokens.ionCyan,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                "No accounts linked yet.",
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: accounts.map((acc) {
                final isCredit = acc.type.toLowerCase().contains('credit');
                final balanceDisplay = isCredit
                    ? (acc.outstandingDebt ?? "0.00")
                    : acc.currentBalance;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: HorizonDimensions.borderLG,
                      border: Border.all(color: tokens.rimNeutral),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: tokens.surface1,
                                borderRadius: HorizonDimensions.borderDefault,
                                border: Border.all(color: tokens.rimNeutral),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isCredit
                                    ? Icons.credit_card_rounded
                                    : Icons.account_balance_rounded,
                                size: 17,
                                color: isCredit
                                    ? tokens.electricIndigo
                                    : tokens.ionCyan,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.ionCyan.withValues(alpha: 0.12),
                                borderRadius: HorizonDimensions.borderFull,
                              ),
                              child: Text(
                                isCredit ? "CARD" : "ACTIVE",
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.ionCyan,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          acc.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HorizonTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tokens.textHigh,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          acc.subtype ?? acc.type.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textLow,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: MoneyText(
                            decimalString: balanceDisplay,
                            currencyCode: acc.currencyCode,
                            style: HorizonTypography.tabularAmountMd.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isCredit ? tokens.outflow : tokens.textHigh,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Budget Trajectory / Spending by Category
  // ---------------------------------------------------------------------------
  Widget _buildBudgetTrajectory(
    BuildContext context,
    List<CategorySummary> categories,
    HorizonThemeTokens tokens,
  ) {
    final now = DateTime.now();
    final dayInMonth = now.day;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart_rounded,
                    size: 18,
                    color: tokens.ionCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Spending by Category",
                    style: HorizonTypography.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tokens.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "CYCLE: DAY $dayInMonth/$totalDays",
              style: HorizonTypography.labelCaps.copyWith(
                color: tokens.textLow,
                fontSize: 10,
                letterSpacing: 0.08 * 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                "No expenses recorded for this period.",
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          HorizonSurface(
            tier: HorizonSurfaceTier.surface2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: categories.take(4).map((cat) {
                final pctStr = cat.percentage ?? "0.0";
                final pctVal = (double.tryParse(pctStr) ?? 0.0) / 100.0;
                final catColor = getCategoryColor(cat.name);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: HorizonDimensions.borderSM,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    getCategoryIcon(cat.name),
                                    size: 14,
                                    color: catColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.name,
                                  style: HorizonTypography.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textHigh,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$pctStr% of expenses",
                                  style: HorizonTypography.bodySm.copyWith(
                                    color: tokens.textMedium,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MoneyText(
                                  decimalString:
                                      cat.totalString ?? cat.total.toStringAsFixed(2),
                                  style:
                                      HorizonTypography.tabularAmountSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textHigh,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedProgressBar(
                        value: pctVal.clamp(0.0, 1.0),
                        color: catColor,
                        backgroundColor: tokens.surface1,
                        height: 5,
                        semanticLabel: "${cat.name} share of spending",
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Recent High-Precision Telemetry Ledger
  // ---------------------------------------------------------------------------
  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionModel> recent,
    HorizonThemeTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: tokens.ionCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recent Transactions",
                    style: HorizonTypography.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: tokens.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/ledger'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "VIEW ALL",
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.ionCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.06 * 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: tokens.ionCyan,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                "No transactions recorded yet.",
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          HorizonSurface(
            tier: HorizonSurfaceTier.surface2,
            padding: EdgeInsets.zero,
            child: Column(
              children: recent.take(5).map((tx) {
                final isExpense = tx.type == "expense";
                String formattedDate = tx.transactionDate;
                try {
                  final parsedDate = DateTime.parse(tx.transactionDate);
                  formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);
                } catch (_) {}

                final categoryColor = getCategoryColor(tx.category);
                final categoryIcon = getCategoryIcon(tx.category);
                final displayAmount =
                    '${isExpense ? '-' : '+'}${MoneyText.getSymbol('INR')}${tx.amount.toStringAsFixed(2)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.surface1,
                          borderRadius: HorizonDimensions.borderDefault,
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          categoryIcon,
                          size: 18,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tx.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HorizonTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tokens.textHigh,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.category} • $formattedDate',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HorizonTypography.bodySm.copyWith(
                                color: tokens.textMedium,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            displayAmount,
                            style: HorizonTypography.tabularAmountSm.copyWith(
                              color: isExpense ? tokens.outflow : tokens.surplus,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Main Build Method
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final smsProvider = context.watch<SmsProvider?>();
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: tokens.ionCyan,
          backgroundColor: tokens.surface2,
          onRefresh: () => dashboardProvider.loadDashboardData(),
          child: dashboardProvider.isLoading && dashboardProvider.summary == null
              ? const SingleChildScrollView(
                  padding: EdgeInsets.all(HorizonDimensions.marginMobile),
                  child: Column(
                    children: [
                      HorizonSkeletonTelemetryCard(),
                      SizedBox(height: 16),
                      HorizonSkeleton(width: double.infinity, height: 110),
                      SizedBox(height: 16),
                      HorizonSkeleton(width: double.infinity, height: 180),
                    ],
                  ),
                )
              : dashboardProvider.errorMessage != null &&
                      dashboardProvider.summary == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: tokens.outflow,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dashboardProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: HorizonTypography.bodyMd.copyWith(
                                color: tokens.textHigh,
                              ),
                            ),
                            const SizedBox(height: 16),
                            HorizonButton(
                              text: "Retry",
                              uppercase: false,
                              onPressed: () =>
                                  dashboardProvider.loadDashboardData(),
                              variant: HorizonButtonVariant.primary,
                              expandWidth: false,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: HorizonDimensions.marginMobile,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Contextual Header
                          _buildHeader(context, authProvider, tokens),
                          const SizedBox(height: 12),

                          // 2. Period Filter Bar
                          _buildFilterBar(context, dashboardProvider, tokens),
                          const SizedBox(height: 14),

                          // SMS Staged Candidates Banner
                          if ((smsProvider?.detectedCount ?? 0) > 0) ...[
                            HorizonSurface(
                              tier: HorizonSurfaceTier.surface2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              onTap: () => context.push('/sms-import'),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sms_outlined,
                                    size: 20,
                                    color: tokens.ionCyan,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${smsProvider!.detectedCount} SMS candidates to review',
                                          style:
                                              HorizonTypography.bodySm.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: tokens.textHigh,
                                          ),
                                        ),
                                        Text(
                                          'Excluded from balances until confirmed',
                                          style:
                                              HorizonTypography.bodySm.copyWith(
                                            fontSize: 10,
                                            color: tokens.textLow,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: tokens.textMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 3. Signature Cinematic Horizon Balance Hero
                          _buildCinematicHero(
                            context,
                            dashboardProvider.overview,
                            dashboardProvider.dailyTrends,
                            dashboardProvider.monthlySummaries,
                            tokens,
                          ),
                          const SizedBox(height: 16),

                          // 4. FIN Living Companion Telemetry Glance
                          _buildFinGlance(
                            context,
                            dashboardProvider.insights,
                            dashboardProvider.overview,
                            tokens,
                          ),
                          const SizedBox(height: 18),

                          // 5. Modular Vault / Account Balances
                          _buildAccountsPreview(
                            context,
                            dashboardProvider.accounts,
                            tokens,
                          ),
                          const SizedBox(height: 18),

                          // 6. Budget Trajectory / Spending by Category
                          _buildBudgetTrajectory(
                            context,
                            dashboardProvider.categorySummaries,
                            tokens,
                          ),
                          const SizedBox(height: 18),

                          // 7. Recent High-Precision Telemetry Ledger
                          _buildRecentTransactions(
                            context,
                            dashboardProvider.recentTransactions,
                            tokens,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
