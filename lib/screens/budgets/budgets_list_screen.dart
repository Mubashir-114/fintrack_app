import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/budget_model.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/horizon/horizon.dart';
import 'widgets/budget_header.dart';
import 'widgets/budget_month_selector.dart';
import 'widgets/budget_hero_overview.dart';
import 'widgets/fin_budget_insight.dart';
import 'widgets/category_budget_card.dart';
import 'widgets/budget_savings_card.dart';
import 'widgets/budget_alert_summary.dart';
import 'widgets/budget_alerts_banner.dart';
import 'widgets/budget_empty_state.dart';
import 'widgets/add_budget_action.dart';
import 'widgets/add_edit_budget_sheet.dart';
import 'widgets/smart_suggestions_sheet.dart';
import 'widgets/budget_history_sheet.dart';

// Re-export sheet widgets and components so existing imports or test references remain functional
export 'widgets/add_edit_budget_sheet.dart' show AddEditBudgetDialog, AddEditBudgetSheet, AddBudgetComposer;
export 'widgets/smart_suggestions_sheet.dart' show SmartSuggestionsBottomSheet, SmartSuggestionsSheet;
export 'widgets/budget_history_sheet.dart' show BudgetHistoryBottomSheet, BudgetHistorySheet;
export 'widgets/monthly_budget_hero.dart' show MonthlyBudgetHero;
export 'widgets/budget_hero_overview.dart' show BudgetHeroOverview;
export 'widgets/category_budget_row.dart' show CategoryBudgetRow;
export 'widgets/category_budget_card.dart' show CategoryBudgetCard;
export 'widgets/budget_alert_summary.dart' show BudgetAlertSummary;
export 'widgets/budget_alerts_banner.dart' show BudgetAlertsBanner;
export 'widgets/budget_empty_state.dart' show BudgetEmptyState;
export 'widgets/budget_month_selector.dart' show BudgetMonthSelector, BudgetMonthControl;
export 'widgets/add_budget_action.dart' show AddBudgetAction;

/// FinTrack HORIZON — Budgets Screen.
///
/// A premium, open financial planning experience with typography-driven hierarchy,
/// signature animated budget arc, and contextual companion guidance.
class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  State<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends State<BudgetsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadAllBudgetData();
    });
  }

  void _showAddEditSheet([BudgetCategoryProgressModel? categoryBudget]) {
    AddEditBudgetSheet.show(context, categoryBudget: categoryBudget);
  }

  void _showSavingsTargetDialog() {
    final provider = context.read<BudgetProvider>();
    final currentTarget = provider.userSavingsTarget?.toString() ??
        provider.progress?.savings.savingsTarget ??
        '';
    final controller = TextEditingController(text: currentTarget);

    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = HorizonThemeTokens.of(ctx);

        return AlertDialog(
          backgroundColor: tokens.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
            side: BorderSide(color: tokens.rimNeutral),
          ),
          title: Text(
            "Monthly Savings Target",
            style: HorizonTypography.headlineSm.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: tokens.textHigh,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set a net savings target (Income - Expenses) for this month.",
                style: HorizonTypography.bodySm.copyWith(color: tokens.textMedium),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: tokens.textHigh, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Target Amount",
                  prefixText: "₹ ",
                  filled: true,
                  fillColor: tokens.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                    borderSide: BorderSide(color: tokens.rimNeutral),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: tokens.textMedium)),
            ),
            if (currentTarget.isNotEmpty)
              TextButton(
                onPressed: () {
                  provider.setUserSavingsTarget(null);
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, "Savings target cleared");
                },
                child: Text("CLEAR", style: TextStyle(color: tokens.outflow)),
              ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());
                if (amount != null && amount > 0) {
                  provider.setUserSavingsTarget(amount);
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, "Savings target updated");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.ionCyan,
                foregroundColor: tokens.isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                ),
              ),
              child: const Text("SET TARGET"),
            ),
          ],
        );
      },
    );
  }

  void _showSuggestionsSheet() {
    SmartSuggestionsSheet.show(context);
  }

  void _showHistorySheet() {
    BudgetHistorySheet.show(context);
  }

  void _handlePreviousMonth() {
    final provider = context.read<BudgetProvider>();
    int newMonth = provider.selectedMonth - 1;
    int newYear = provider.selectedYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    provider.changeDate(newMonth, newYear);
  }

  void _handleNextMonth() {
    final provider = context.read<BudgetProvider>();
    int newMonth = provider.selectedMonth + 1;
    int newYear = provider.selectedYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    provider.changeDate(newMonth, newYear);
  }

  void _selectMonthYear() {
    final provider = context.read<BudgetProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        int tempMonth = provider.selectedMonth;
        int tempYear = provider.selectedYear;
        final tokens = HorizonThemeTokens.of(ctx);

        return AlertDialog(
          backgroundColor: tokens.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
            side: BorderSide(color: tokens.rimNeutral),
          ),
          title: Text(
            "Select Month & Year",
            style: HorizonTypography.headlineSm.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: tokens.textHigh,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    dropdownColor: tokens.surface2,
                    decoration: InputDecoration(
                      labelText: "Month",
                      filled: true,
                      fillColor: tokens.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                        borderSide: BorderSide(color: tokens.rimNeutral),
                      ),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempMonth = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    dropdownColor: tokens.surface2,
                    decoration: InputDecoration(
                      labelText: "Year",
                      filled: true,
                      fillColor: tokens.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                        borderSide: BorderSide(color: tokens.rimNeutral),
                      ),
                    ),
                    items: List.generate(10, (i) => DateTime.now().year - 2 + i)
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempYear = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: tokens.textMedium)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.changeDate(tempMonth, tempYear);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.ionCyan,
                foregroundColor: tokens.isDark ? Colors.black : Colors.white,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                ),
              ),
              child: const Text("SELECT"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BudgetCategoryProgressModel b) {
    final tokens = HorizonThemeTokens.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tokens.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
            side: BorderSide(color: tokens.rimNeutral),
          ),
          title: Text("Delete Budget", style: HorizonTypography.headlineSm.copyWith(color: tokens.textHigh)),
          content: Text(
            "Are you sure you want to delete the budget limit for ${b.category}?",
            style: HorizonTypography.bodyMd.copyWith(color: tokens.textMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: tokens.textMedium)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<BudgetProvider>();
                final success = await provider.deleteBudget(b.budgetId);
                if (!mounted) return;
                if (success) {
                  context.read<ReportProvider>().loadAllReports();
                  CustomToast.showSuccess(context, "Budget limit deleted successfully");
                } else {
                  CustomToast.showError(
                    context,
                    provider.errorMessage ?? "Failed to delete budget",
                  );
                }
              },
              child: Text("DELETE", style: TextStyle(color: tokens.outflow, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final currency = context.watch<CurrencyProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final selectedMonthName =
        DateFormat('MMMM').format(DateTime(2026, provider.selectedMonth));

    final progress = provider.progress;
    final overall = progress?.overall;
    final alerts = provider.alerts;

    // Resilient budget detection: check progress, raw budgets, and statuses
    final hasBudgets = (progress != null &&
            (overall?.hasBudgetsDefined == true ||
                progress.categoryBudgets.isNotEmpty)) ||
        provider.budgets.isNotEmpty ||
        provider.budgetStatuses.isNotEmpty;

    // Category budgets list with resilient fallback from budget statuses
    final categoryBudgets = progress?.categoryBudgets.isNotEmpty == true
        ? progress!.categoryBudgets
        : provider.budgetStatuses
            .map((s) => BudgetCategoryProgressModel(
                  budgetId: s.budgetId,
                  categoryId: s.categoryId,
                  category: s.category,
                  categoryType: "expense",
                  budgetLimit: s.budget.toStringAsFixed(2),
                  actualSpending: s.spent.toStringAsFixed(2),
                  remainingAmount: s.remaining.toStringAsFixed(2),
                  utilizationPercentage: s.percentageUsed.toStringAsFixed(1),
                  projectedSpending: s.spent.toStringAsFixed(2),
                  status: s.status == "over_budget"
                      ? "exceeded"
                      : (s.percentageUsed >= 80
                          ? "approaching_limit"
                          : "on_track"),
                  daysRemaining: 0,
                ))
            .toList();

    // Overall summary with fallback from statuses
    final overallModel = overall != null && overall.hasBudgetsDefined
        ? overall
        : (provider.budgetStatuses.isNotEmpty
            ? BudgetOverallProgressModel(
                budgetLimit: provider.budgetStatuses
                    .fold(0.0, (sum, b) => sum + b.budget)
                    .toStringAsFixed(2),
                actualSpending: provider.budgetStatuses
                    .fold(0.0, (sum, b) => sum + b.spent)
                    .toStringAsFixed(2),
                remainingAmount: provider.budgetStatuses
                    .fold(0.0, (sum, b) => sum + b.remaining)
                    .toStringAsFixed(2),
                utilizationPercentage: provider.budgetStatuses
                            .fold(0.0, (sum, b) => sum + b.budget) >
                        0
                    ? ((provider.budgetStatuses.fold(0.0, (sum, b) => sum + b.spent) /
                                provider.budgetStatuses.fold(0.0, (sum, b) => sum + b.budget)) *
                            100)
                        .toStringAsFixed(1)
                    : "0.0",
                dailyBurnRate: "0.00",
                projectedSpending: provider.budgetStatuses
                    .fold(0.0, (sum, b) => sum + b.spent)
                    .toStringAsFixed(2),
                status: provider.budgetStatuses.any((b) => b.status == "over_budget")
                    ? "exceeded"
                    : "on_track",
                hasBudgetsDefined: true,
              )
            : null);

    final periodModel = progress?.period ??
        const BudgetPeriodModel(
          daysInMonth: 30,
          daysElapsed: 15,
          daysRemaining: 15,
          isCurrentPeriod: true,
          estimationMethod: "Linear Daily Burn-Rate",
        );

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: BudgetHeader(
        onSuggestions: _showSuggestionsSheet,
        onHistory: _showHistorySheet,
        onSelectMonth: _selectMonthYear,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllBudgetData(forceRefresh: true),
        color: tokens.ionCyan,
        backgroundColor: tokens.surface2,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: provider.isLoading && !hasBudgets && progress == null
                ? ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HorizonDimensions.marginMobile,
                      vertical: 8,
                    ),
                    children: const [
                      HorizonSkeleton(width: double.infinity, height: 180),
                      SizedBox(height: 12),
                      HorizonSkeleton(width: double.infinity, height: 90),
                      SizedBox(height: 12),
                      HorizonSkeleton(width: double.infinity, height: 90),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HorizonDimensions.marginMobile,
                      vertical: 8,
                    ),
                    children: [
                      // Month Navigation Bar
                      BudgetMonthSelector(
                        selectedMonth: provider.selectedMonth,
                        selectedYear: provider.selectedYear,
                        isLoading: provider.isLoading,
                        onPreviousMonth: _handlePreviousMonth,
                        onNextMonth: _handleNextMonth,
                        onTapMonth: _selectMonthYear,
                      ),

                      // Meaningful Error State when initial load fails with no budgets
                      if (provider.errorMessage != null && !hasBudgets) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: tokens.surface1,
                            borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.outflow.withValues(alpha: 0.12),
                                ),
                                child: Icon(Icons.cloud_off_rounded, size: 32, color: tokens.outflow),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "Unable to Load Budgets",
                                style: HorizonTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textHigh,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                provider.errorMessage ??
                                    "A network issue occurred while loading budget records.",
                                textAlign: TextAlign.center,
                                style: HorizonTypography.bodySm.copyWith(color: tokens.textMedium),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () => provider.loadAllBudgetData(forceRefresh: true),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text("Retry"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tokens.ionCyan,
                                  foregroundColor: tokens.isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // Populated Budgets View
                      else if (hasBudgets) ...[
                        // Non-intrusive warning banner if background update reported error
                        if (provider.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: tokens.outflow.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                              border: Border.all(color: tokens.outflow.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: tokens.outflow),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.errorMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.outflow,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => provider.loadAllBudgetData(forceRefresh: true),
                                  child: Text(
                                    "RETRY",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.outflow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Monthly Budget Hero Overview
                        if (overallModel != null && overallModel.hasBudgetsDefined) ...[
                          BudgetHeroOverview(
                            overall: overallModel,
                            period: periodModel,
                            currency: currency,
                          ),

                          // Lighter Contextual FIN Insight
                          FinBudgetInsight(
                            overall: overallModel,
                            period: periodModel,
                            currency: currency,
                            onViewSuggestions: _showSuggestionsSheet,
                          ),
                        ],

                        // Compact In-App Alerts Banner
                        if (alerts != null && alerts.totalAlertsCount > 0)
                          BudgetAlertSummary(alerts: alerts),

                        // Net Savings Progress Strip
                        if (progress?.savings != null)
                          BudgetSavingsCard(
                            savings: progress!.savings,
                            currency: currency,
                            onEditTarget: _showSavingsTargetDialog,
                          ),

                        // Section Header: Categories
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Category Budgets (${categoryBudgets.length})",
                                style: HorizonTypography.headlineSm.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: tokens.textHigh,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showSuggestionsSheet,
                                icon: Icon(Icons.auto_awesome_rounded, size: 14, color: tokens.ionCyan),
                                label: Text(
                                  "Suggestions",
                                  style: HorizonTypography.labelCaps.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ionCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Modern Flat Category Budget Rows
                        if (categoryBudgets.isNotEmpty)
                          ...categoryBudgets.asMap().entries.map(
                                (entry) => CategoryBudgetCard(
                                  index: entry.key,
                                  budget: entry.value,
                                  currency: currency,
                                  onEdit: () => _showAddEditSheet(entry.value),
                                  onDelete: () => _confirmDelete(entry.value),
                                ),
                              ),

                        const SizedBox(height: HorizonDimensions.dockClearance),
                      ] else ...[
                        // Engaging Empty State (No duplicate FAB is shown!)
                        BudgetEmptyState(
                          selectedMonthName: selectedMonthName,
                          selectedYear: provider.selectedYear,
                          onCreateBudget: () => _showAddEditSheet(),
                          onExploreSuggestions: _showSuggestionsSheet,
                        ),
                        const SizedBox(height: HorizonDimensions.dockClearance),
                      ],
                    ],
                  ),
          ),
        ),
      ),
      // Contextual Floating Action Button: Shown ONLY when budgets exist
      floatingActionButton: hasBudgets
          ? AddBudgetAction(onPressed: () => _showAddEditSheet())
          : null,
    );
  }
}
