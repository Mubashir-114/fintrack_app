import '../../core/widgets/profile_avatar.dart';
import '../../providers/sms_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../core/widgets/financial_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_models.dart';
import '../../core/utils/category_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../accounts/widgets/money_text.dart';
import '../accounts/widgets/account_icon.dart';
import 'widgets/premium_dashboard_cards.dart';

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

  Widget _buildFilterBar(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final currentPeriod = provider.selectedPeriod;
    final customMonth = provider.selectedMonth;
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Current Month"),
            selected: currentPeriod == "current_month" && customMonth == null,
            onSelected: (_) => provider.setPeriod("current_month"),
            selectedColor: colors.primary.withValues(alpha: 0.18),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "current_month" && customMonth == null
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Previous Month"),
            selected: currentPeriod == "previous_month",
            onSelected: (_) => provider.setPeriod("previous_month"),
            selectedColor: colors.primary.withValues(alpha: 0.18),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "previous_month"
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_month_rounded, size: 16),
            label: Text(customMonth ?? "Select Month"),
            onPressed: () => _selectCustomMonth(context, provider),
            backgroundColor: customMonth != null
                ? colors.primary.withValues(alpha: 0.18)
                : colors.surface,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: customMonth != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(
    FinancialOverview? overview,
    List<MonthlySummary> monthlySummaries,
    bool isDark,
  ) {
    final netWorth = overview?.netWorth ?? "0.00";
    final totalAssets = overview?.totalAssets ?? "0.00";
    final totalLiabilities = overview?.totalLiabilities ?? "0.00";
    final colors = AppColors.of(context);

    return PremiumSummaryCard(
      animatedHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "NET WORTH",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.55,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedAmountText(
            decimalString: netWorth,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.35,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Your position across every connected account",
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : colors.primary).withValues(
                alpha: .055,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: (isDark ? Colors.white : colors.primary).withValues(
                  alpha: .08,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeroBalance(
                    "ASSETS",
                    totalAssets,
                    AppColors.success,
                    isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: colors.divider.withValues(alpha: .7),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildHeroBalance(
                    "LIABILITIES",
                    totalLiabilities,
                    AppColors.danger,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBalance(
    String label,
    String amount,
    Color color,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: .8,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedAmountText(
          decimalString: amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSection(
    FinancialOverview? overview,
    bool isDark, {
    bool premium = true,
  }) {
    if (premium) return _buildPremiumCashFlowSection(overview, isDark);
    final income = overview?.monthlyIncome ?? "0.00";
    final expenses = overview?.monthlyExpenses ?? "0.00";
    final savings = overview?.monthlyNetSavings ?? "0.00";
    final incomeMoM = overview?.incomeChangePercent ?? "0.0";
    final expenseMoM = overview?.expenseChangePercent ?? "0.0";
    final savingsRate = overview?.savingsRate ?? "0.0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monthly Cash Flow",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        AppDimensions.hSM,
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Income",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${incomeMoM.startsWith('-') ? '' : '+'}$incomeMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: incomeMoM.startsWith('-')
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MoneyText(
                        decimalString: income,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                elevation: 0,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Expenses",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${expenseMoM.startsWith('-') ? '' : '+'}$expenseMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: expenseMoM.startsWith('+')
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MoneyText(
                        decimalString: expenses,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Savings (Cash Flow)",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      decimalString: savings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: savings.startsWith('-')
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Savings Rate",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$savingsRate%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCashFlowSection(
    FinancialOverview? overview,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    final metrics = [
      (
        'Income',
        overview?.monthlyIncome ?? '0.00',
        colors.success,
        Icons.south_west_rounded,
      ),
      (
        'Expenses',
        overview?.monthlyExpenses ?? '0.00',
        colors.danger,
        Icons.north_east_rounded,
      ),
      (
        'Savings',
        overview?.monthlyNetSavings ?? '0.00',
        colors.primary,
        Icons.savings_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = box.maxWidth >= 540 && scale < 1.5
            ? 3
            : box.maxWidth >= 320 && scale < 1.3
            ? 2
            : 1;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: PremiumSummaryCard(
                  padding: const EdgeInsets.all(12),
                  accent: metric.$3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.$1,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedAmountText(
                        decimalString: metric.$2,
                        style: TextStyle(
                          color: metric.$3,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _activityRow(Widget leading, Widget details, Widget amount) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact =
            box.maxWidth / (MediaQuery.textScalerOf(context).scale(14) / 14) <
            300;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [details, const SizedBox(height: 8), amount],
                    )
                  : details,
            ),
            if (!compact) ...[const SizedBox(width: 12), amount],
          ],
        );
      },
    );
  }

  Widget _buildSpendingByCategory(
    List<CategorySummary> categories,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    if (categories.isEmpty) {
      return PremiumEmptyStateCard(
        icon: Icons.donut_large_rounded,
        title: "No expenses recorded for this period.",
        message:
            "Category insights will appear as soon as spending is recorded.",
        accent: colors.secondary,
      );
    }

    return PremiumSummaryCard(
      accent: colors.secondary,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Padding(
        padding: EdgeInsets.zero,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.take(5).length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final pct = cat.percentage ?? "0.0";
            return _activityRow(
              CircleAvatar(
                radius: 18,
                backgroundColor: getCategoryColor(
                  cat.name,
                ).withValues(alpha: .12),
                child: Icon(
                  getCategoryIcon(cat.name),
                  size: 18,
                  color: getCategoryColor(cat.name),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '$pct% of expenses',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  AnimatedProgressBar(
                    value: (double.tryParse(pct) ?? 0) / 100,
                    color: getCategoryColor(cat.name),
                    backgroundColor: colors.divider,
                    height: 4,
                    semanticLabel: '${cat.name} share of spending',
                  ),
                ],
              ),
              MoneyText(
                decimalString: cat.totalString ?? cat.total.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountOverview(
    List<DashboardAccountItem> accounts,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    if (accounts.isEmpty) {
      return PremiumEmptyStateCard(
        icon: Icons.account_balance_wallet_outlined,
        title: "No accounts linked yet.",
        message:
            "Connect an account to bring your complete financial picture to life.",
        actionLabel: "Add Account",
        onAction: () => context.push('/accounts'),
        accent: colors.secondary,
      );
    }

    return SizedBox(
      height:
          150 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 2.5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isCredit = acc.type == "credit_card";
          final accentColor = isCredit ? colors.danger : colors.primary;

          final utilization =
              (double.tryParse(acc.utilizationPercentage ?? '0') ?? 0) / 100;

          return Container(
            width: 218,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [accentColor.withValues(alpha: .12), colors.surface]
                    : [accentColor.withValues(alpha: .07), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: accentColor.withValues(alpha: .24)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? .07 : .05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AccountIcon(
                          type: acc.type,
                          subtype: acc.subtype ?? 'savings',
                          size: 28,
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            acc.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (acc.isDefault)
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      )
                    else if (acc.isArchived)
                      Icon(
                        Icons.archive_outlined,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCredit ? "Outstanding Debt" : "Ledger Balance",
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      decimalString: isCredit
                          ? (acc.outstandingDebt ?? "0.00")
                          : acc.currentBalance,
                      currencyCode: acc.currencyCode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? colors.danger : colors.textPrimary,
                      ),
                    ),
                    if (isCredit && acc.utilizationPercentage != null) ...[
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Utilization",
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            "${acc.utilizationPercentage}%",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedProgressBar(
                        value: utilization,
                        color: accentColor,
                        backgroundColor: colors.divider,
                        height: 4,
                        semanticLabel: "${acc.displayName} utilization",
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
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

  Widget _buildInsightsSection(List<FinancialInsight> insights, bool isDark) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumSectionHeader(title: 'Financial Insights'),
        AppDimensions.hSM,
        Card(
          elevation: 0,
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: colors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.take(3).length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final insight = insights[index];
                IconData icon;
                Color iconColor;

                switch (insight.type) {
                  case 'highest_category':
                    icon = Icons.pie_chart_rounded;
                    iconColor = AppColors.warning;
                    break;
                  case 'largest_expense':
                    icon = Icons.shopping_bag_outlined;
                    iconColor = AppColors.danger;
                    break;
                  case 'savings_rate':
                    icon = Icons.savings_outlined;
                    iconColor = AppColors.success;
                    break;
                  case 'credit_utilization':
                    icon = Icons.credit_card_rounded;
                    iconColor = colors.primary;
                    break;
                  default:
                    icon = Icons.insights_rounded;
                    iconColor = AppColors.info;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanningSection(bool isDark) {
    final colors = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      onTap: () => context.push('/planning'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Icon(
                Icons.savings_rounded,
                color: colors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Financial Planning & Goals",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Savings targets, deterministic cash-flow forecasts & what-if simulator",
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final dashboardProvider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        toolbarHeight:
            65 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1, 2),
        title: Row(
          children: [
            ProfileAvatar(
              name: user?.name ?? '',
              bytes: context.watch<AuthProvider>().avatarBytes,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${user?.name ?? 'User'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    "Financial overview",
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Accounts & Wallets',
            icon: Icon(
              Icons.account_balance_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () => context.push('/accounts'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.sync_rounded, color: colors.textPrimary),
            onPressed: () => dashboardProvider.loadDashboardData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboardProvider.loadDashboardData(),
        child: dashboardProvider.isLoading && dashboardProvider.summary == null
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDimensions.hMD,
                    const DashboardSkeletonCard(height: 210),
                    AppDimensions.hMD,
                    Row(
                      children: [
                        const Expanded(
                          child: DashboardSkeletonCard(
                            height: 118,
                            accent: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: DashboardSkeletonCard(
                            height: 118,
                            accent: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    AppDimensions.hLG,
                    const DashboardSkeletonCard(height: 220),
                  ],
                ),
              )
            : dashboardProvider.errorMessage != null &&
                  dashboardProvider.summary == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dashboardProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => dashboardProvider.loadDashboardData(),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // 7. Date & Month Filter
                    _buildFilterBar(context, dashboardProvider, isDark),
                    AppDimensions.hMD,

                    if ((context.watch<SmsProvider?>()?.detectedCount ?? 0) > 0)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sms_outlined),
                        title: Text(
                          '${context.watch<SmsProvider?>()!.detectedCount} SMS candidates to review',
                        ),
                        subtitle: const Text(
                          'Excluded from balances until confirmed',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/sms-import'),
                      ),
                    // 1. Net worth & Total Assets / Liabilities
                    DashboardEntrance(
                      index: 0,
                      child: _buildNetWorthCard(
                        dashboardProvider.overview,
                        dashboardProvider.monthlySummaries,
                        isDark,
                      ),
                    ),
                    AppDimensions.hMD,

                    // 2. Cash Flow (Income, Expenses, Net Savings)
                    DashboardEntrance(
                      index: 1,
                      child: _buildCashFlowSection(
                        dashboardProvider.overview,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    // 5. Account Balance Overview
                    PremiumSectionHeader(
                      title: "Account Balances",
                      subtitle: "Live balances from your ledger",
                      actionLabel: "Manage",
                      onAction: () => context.push('/accounts'),
                    ),
                    AppDimensions.hXS,
                    DashboardEntrance(
                      index: 2,
                      child: _buildAccountOverview(
                        dashboardProvider.accounts,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    PremiumSectionHeader(
                      title: "Recent Transactions",
                      subtitle: "Latest activity across your accounts",
                      actionLabel: "See All",
                      onAction: () => context.go("/transactions"),
                    ),
                    AppDimensions.hXS,
                    if (dashboardProvider.recentTransactions.isEmpty)
                      const PremiumEmptyStateCard(
                        icon: Icons.receipt_long_rounded,
                        title: "No transactions recorded yet.",
                        message:
                            "New income and expenses will collect here for a quick review.",
                        accent: AppColors.info,
                      )
                    else
                      PremiumSummaryCard(
                        accent: AppColors.info,
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dashboardProvider.recentTransactions
                              .take(4)
                              .length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            endIndent: 16,
                            color: colors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final tx =
                                dashboardProvider.recentTransactions[index];
                            final isExpense = tx.type == "expense";

                            String formattedDate = tx.transactionDate;
                            try {
                              final parsedDate = DateTime.parse(
                                tx.transactionDate,
                              );
                              formattedDate = DateFormat(
                                'MMM dd, yyyy',
                              ).format(parsedDate);
                            } catch (_) {}

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: _activityRow(
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: getCategoryColor(
                                    tx.category,
                                  ).withValues(alpha: .12),
                                  child: Icon(
                                    getCategoryIcon(tx.category),
                                    color: getCategoryColor(tx.category),
                                    size: 20,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${tx.category} \u2022 $formattedDate',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${isExpense ? '-' : '+'}${MoneyText.getSymbol('INR')}${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense
                                        ? AppColors.danger
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    AppDimensions.hLG,
                    // 3. Spending by Category
                    PremiumSectionHeader(
                      title: "Spending by Category",
                      subtitle: "Where this period's money went",
                    ),
                    AppDimensions.hSM,
                    DashboardEntrance(
                      index: 3,
                      child: _buildSpendingByCategory(
                        dashboardProvider.categorySummaries,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Cash-flow trend'),
                      children: [
                        PremiumSummaryCard(
                          child: _buildMonthlyTrendChart(
                            dashboardProvider,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.pie_chart_outline),
                      title: const Text('Budgets'),
                      subtitle: const Text(
                        'Review category limits and progress',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/budgets'),
                    ),
                    AppDimensions.hMD,
                    _buildInsightsSection(dashboardProvider.insights, isDark),
                    AppDimensions.hLG,

                    // Financial Planning & Goals
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: const Text('Ask FIN'),
                      subtitle: const Text(
                        'Explore your approved financial activity',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/analytics'),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Planning & goals'),
                      children: [_buildPlanningSection(isDark)],
                    ),
                    AppDimensions.hLG,

                    // 6. Recent Transactions Section
                    const SizedBox(height: 36),
                  ],
                ),
              ),
      ),
    );
  }
}
