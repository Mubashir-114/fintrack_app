import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/horizon/horizon.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/notification_center_sheet.dart';
import '../../core/widgets/financial_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/companion_model.dart';
import '../../models/dashboard_models.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/currency_provider.dart';
import '../../core/utils/money_formatter.dart';
import '../../providers/sms_provider.dart';
import '../accounts/widgets/money_text.dart';
import 'widgets/dashboard_account_row.dart';
import 'widgets/dashboard_category_row.dart';
import 'widgets/dashboard_fin_insight.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/dashboard_recent_row.dart';

/// FinTrack // HORIZON — Horizon Home Dashboard.
///
/// Composition: contextual header, animated range switcher, net-worth hero
/// with line-draw cash-flow trend, contextual FIN insight, then open account,
/// category and recent-transaction lists separated by hairlines and rhythm
/// rather than stacked cards.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _finTimer;
  FinCharacterState _finState = FinCharacterState.explaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadDashboardData();
      context.read<SmsProvider?>()?.loadDetectedTransactions();
      // Powers the header update badge; failures are swallowed by the provider.
      context.read<BudgetProvider?>()?.loadBudgetAlerts();
    });
  }

  @override
  void dispose() {
    _finTimer?.cancel();
    super.dispose();
  }

  /// Calm micro-reaction: FIN notices the reporting period change, thinks,
  /// then settles back. Skipped entirely under reduced motion.
  void _reactToPeriodChange() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _finTimer?.cancel();
    setState(() => _finState = FinCharacterState.thinking);
    _finTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _finState = FinCharacterState.explaining);
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
    final currencyCode =
        context.watch<CurrencyProvider?>()?.currencyCode ?? 'INR';
    final user = authProvider.currentUser;
    final userName = user?.name ?? "Alex";

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile entry: navigates to the profile hub.
          Semantics(
            button: true,
            label: 'Open profile',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: () => context.push('/profile'),
                customBorder: const CircleBorder(),
                child: ProfileAvatar(
                  name: user?.name ?? 'Alex',
                  bytes: authProvider.avatarBytes,
                  size: 40,
                ),
              ),
            ),
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
          // Currency badge — informational, not a control.
          Semantics(
            label: 'Display currency: $currencyCode',
            excludeSemantics: true,
            child: Container(
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
                    currencyCode,
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.ionCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "(${MoneyFormatter.getSymbol(currencyCode)})",
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textMedium,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Notification bell — opens the real update center.
          HorizonIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: 'Open updates',
            badgeCount: NotificationCenterSheet.pendingCount(context),
            onPressed: () => NotificationCenterSheet.show(
              context,
              onNavigate: (route) => context.go(route),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(DashboardProvider provider, bool isDark) {
    final currencyCode =
        context.watch<CurrencyProvider?>()?.currencyCode ?? 'INR';
    final colors = AppColors.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
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
          'Monthly income and expenses, zero baseline. ${summaries.map((item) => '${item.month}: income ${MoneyText.format(item.income.toStringAsFixed(2), currencyCode)}, expense ${MoneyText.format(item.expense.toStringAsFixed(2), currencyCode)}').join('; ')}',
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
                      "$type: ${MoneyFormatter.amount(spot.y, currencyCode: currencyCode)}",
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
                  reservedSize: largeText ? 32 : 24,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (largeText &&
                        index != 0 &&
                        index != summaries.length ~/ 2 &&
                        index != summaries.length - 1) {
                      return const SizedBox.shrink();
                    }
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
                  reservedSize: largeText ? 82 : 48,
                  interval: adjustedMax / 4,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      MoneyFormatter.compact(value, currencyCode),
                      maxLines: 1,
                      softWrap: false,
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
  // Cash-flow trend sheet
  // ---------------------------------------------------------------------------
  void _showCashFlowSheet(BuildContext context, HorizonThemeTokens tokens) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.rimNeutral,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cash-flow trend',
                      style: HorizonTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.textHigh,
                      ),
                    ),
                  ),
                  HorizonIconButton(
                    icon: Icons.close_rounded,
                    semanticLabel: 'Close cash-flow trend',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Income against expenses for the selected period',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: _buildMonthlyTrendChart(
                    context.read<DashboardProvider>(),
                    tokens.isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Range switcher
  // ---------------------------------------------------------------------------
  Widget _buildRangeSwitcher(
    BuildContext context,
    DashboardProvider provider,
    HorizonThemeTokens tokens,
  ) {
    final bool hasCustom = provider.selectedMonth != null;
    return HorizonRangeSwitcher(
      options: const ['Current Month', 'Previous Month'],
      selectedIndex: hasCustom
          ? -1
          : (provider.selectedPeriod == 'previous_month' ? 1 : 0),
      onSelected: (index) {
        provider.setPeriod(index == 0 ? 'current_month' : 'previous_month');
        _reactToPeriodChange();
      },
      customLabel: hasCustom ? provider.selectedMonth : null,
      onCustomSelected: () async {
        await _selectCustomMonth(context, provider);
        if (!mounted) return;
        _reactToPeriodChange();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Open sections
  // ---------------------------------------------------------------------------
  List<double> _sparkValues(DashboardProvider provider) {
    final values = <double>[];
    final daily = provider.dailyTrends;
    if (daily.isNotEmpty) {
      for (final trend in daily) {
        values.add(double.tryParse(trend.amount) ?? 0.0);
      }
    } else if (provider.monthlySummaries.isNotEmpty) {
      final recent = provider.monthlySummaries.take(6).toList().reversed;
      for (final month in recent) {
        values.add(month.income - month.expense);
      }
    }
    if (values.isEmpty) values.addAll(const [0, 0]);
    return values;
  }

  String _flowCaption(DashboardProvider provider) {
    if (provider.dailyTrends.isNotEmpty) return 'Daily recorded flow';
    if (provider.monthlySummaries.isNotEmpty) return 'Monthly net savings';
    return 'No recorded flow yet';
  }

  String _friendlyDate(String raw) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Widget _buildAccountsSection(
    BuildContext context,
    List<DashboardAccountItem> accounts,
    HorizonThemeTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HorizonSectionHeader(
          title: 'Account Balances',
          icon: Icons.account_balance_wallet_rounded,
          actionLabel: 'Manage (${accounts.length})',
          onAction: () => context.push('/money-storage'),
        ),
        if (accounts.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No accounts linked yet.',
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < accounts.length; i++)
                DashboardAccountRow(
                  account: accounts[i],
                  showDivider: i != accounts.length - 1,
                  onTap: () => context.push('/accounts/${accounts[i].id}'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    List<CategorySummary> categories,
    HorizonThemeTokens tokens,
  ) {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HorizonSectionHeader(
          title: 'Spending by Category',
          icon: Icons.pie_chart_rounded,
          caption: 'CYCLE: DAY ${now.day}/$totalDays',
        ),
        if (categories.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No expenses recorded for this period.',
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < categories.length && i < 4; i++)
                DashboardCategoryRow(
                  category: categories[i],
                  showDivider: i != categories.length - 1 && i != 3,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    List<TransactionModel> recent,
    HorizonThemeTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HorizonSectionHeader(
          title: 'Recent Transactions',
          icon: Icons.receipt_long_rounded,
          actionLabel: 'View all',
          onAction: () => context.push('/ledger'),
        ),
        if (recent.isEmpty)
          HorizonSurface(
            tier: HorizonSurfaceTier.surface1,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No transactions recorded yet.',
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.textMedium,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < recent.length && i < 5; i++)
                DashboardRecentRow(
                  transaction: recent[i],
                  dateString: _friendlyDate(recent[i].transactionDate),
                  showDivider: i != recent.length - 1 && i != 4,
                  onTap: () => context.push('/ledger'),
                ),
            ],
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
    // The badge must update when an asynchronous budget alert load completes.
    context.watch<BudgetProvider?>();
    final tokens = HorizonThemeTokens.of(context);

    Widget body;
    if (dashboardProvider.isLoading && dashboardProvider.summary == null) {
      body = const SingleChildScrollView(
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
      );
    } else if (dashboardProvider.errorMessage != null &&
        dashboardProvider.summary == null) {
      body = Center(
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
                onPressed: () => dashboardProvider.loadDashboardData(),
                variant: HorizonButtonVariant.primary,
                expandWidth: false,
              ),
            ],
          ),
        ),
      );
    } else {
      final String insightMessage = dashboardProvider.insights.isNotEmpty
          ? dashboardProvider.insights.first.message
          : "Liquidity pace is +14% above nominal burn rate. Your fiscal envelope buffer remains stable.";
      final int pendingSms = smsProvider?.detectedTransactions.length ?? 0;

      body = RefreshIndicator(
        color: tokens.ionCyan,
        backgroundColor: tokens.surface2,
        onRefresh: () => dashboardProvider.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: HorizonDimensions.marginMobile,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HorizonStaggeredReveal(
                    order: 0,
                    child: _buildHeader(context, authProvider, tokens),
                  ),
                  const SizedBox(height: 12),
                  HorizonStaggeredReveal(
                    order: 1,
                    child: _buildRangeSwitcher(
                      context,
                      dashboardProvider,
                      tokens,
                    ),
                  ),
                  if (pendingSms > 0) ...[
                    const SizedBox(height: 14),
                    HorizonSurface(
                      tier: HorizonSurfaceTier.surface1,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$pendingSms SMS candidates to review',
                                  style: HorizonTypography.bodySm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textHigh,
                                  ),
                                ),
                                Text(
                                  'Excluded from balances until confirmed',
                                  style: HorizonTypography.bodySm.copyWith(
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
                  ],
                  const SizedBox(height: 16),
                  HorizonStaggeredReveal(
                    order: 2,
                    child: DashboardHero(
                      overview: dashboardProvider.overview,
                      sparkValues: _sparkValues(dashboardProvider),
                      flowCaption: _flowCaption(dashboardProvider),
                      onShowCashFlow: () => _showCashFlowSheet(context, tokens),
                    ),
                  ),
                  const SizedBox(height: 6),
                  HorizonStaggeredReveal(
                    order: 3,
                    child: DashboardFinInsight(
                      message: insightMessage,
                      state: _finState,
                      onTap: () => context.push('/analytics'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
                  const SizedBox(height: 18),
                  HorizonStaggeredReveal(
                    order: 4,
                    child: _buildAccountsSection(
                      context,
                      dashboardProvider.accounts,
                      tokens,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
                  const SizedBox(height: 18),
                  HorizonStaggeredReveal(
                    order: 5,
                    child: _buildCategorySection(
                      context,
                      dashboardProvider.categorySummaries,
                      tokens,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
                  const SizedBox(height: 18),
                  HorizonStaggeredReveal(
                    order: 6,
                    child: _buildRecentSection(
                      context,
                      dashboardProvider.recentTransactions,
                      tokens,
                    ),
                  ),
                  const SizedBox(height: HorizonDimensions.dockClearance),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(child: body),
    );
  }
}
