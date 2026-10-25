import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/report_provider.dart';

/// Aliases for reusable naming
typedef AddBudgetComposer = AddEditBudgetSheet;
typedef AddEditBudgetDialog = AddEditBudgetSheet;

/// FinTrack HORIZON — Modern Budget Composer Sheet.
///
/// Features the oversized amount hero with integrated currency symbol,
/// a modern category selector with configured status indication,
/// lighter quick amount actions, and smooth keyboard handling.
class AddEditBudgetSheet extends StatefulWidget {
  const AddEditBudgetSheet({
    super.key,
    this.categoryBudget,
  });

  final BudgetCategoryProgressModel? categoryBudget;

  static Future<void> show(
    BuildContext context, {
    BudgetCategoryProgressModel? categoryBudget,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditBudgetSheet(categoryBudget: categoryBudget),
    );
  }

  @override
  State<AddEditBudgetSheet> createState() => _AddEditBudgetSheetState();
}

class _AddEditBudgetSheetState extends State<AddEditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late FocusNode _amountFocusNode;

  int? _selectedCategoryId;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final cb = widget.categoryBudget;
    final provider = context.read<BudgetProvider>();

    _amountController = TextEditingController(text: cb != null ? cb.budgetLimit : '');
    _amountFocusNode = FocusNode();
    _selectedCategoryId = cb?.categoryId;
    _selectedMonth = provider.selectedMonth;
    _selectedYear = provider.selectedYear;

    if (_selectedCategoryId == null) {
      final expenses = CategoryModel.getExpenseCategories();
      final budgetedIds = <int>{
        ...provider.budgetStatuses.map((b) => b.categoryId),
        if (provider.progress != null)
          ...provider.progress!.categoryBudgets.map((b) => b.categoryId),
        ...provider.budgets
            .where((b) => b.month == _selectedMonth && b.year == _selectedYear)
            .map((b) => b.categoryId),
      };
      final unbudgeted = expenses.where((c) => !budgetedIds.contains(c.id)).toList();
      if (unbudgeted.isNotEmpty) {
        _selectedCategoryId = unbudgeted.first.id;
      } else if (expenses.isNotEmpty) {
        _selectedCategoryId = expenses.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _addQuickPreset(double increment) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final next = current + increment;
    _amountController.text = next.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final provider = context.read<BudgetProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final category = CategoryModel.findById(_selectedCategoryId);
    if (category == null || category.type != 'expense') {
      CustomToast.showError(context, "Selected category is not a valid expense category");
      return;
    }

    bool success;
    if (widget.categoryBudget != null) {
      success = await provider.editBudget(
        id: widget.categoryBudget!.budgetId,
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } else {
      // Explicit duplicate guard before dispatching add
      final isAlreadyBudgeted = provider.budgetStatuses.any((b) => b.categoryId == _selectedCategoryId) ||
          (provider.progress?.categoryBudgets.any((b) => b.categoryId == _selectedCategoryId) ?? false) ||
          provider.budgets.any((b) =>
              b.categoryId == _selectedCategoryId &&
              b.month == _selectedMonth &&
              b.year == _selectedYear);
      if (isAlreadyBudgeted) {
        final monthName = DateFormat('MMMM').format(DateTime(2026, _selectedMonth));
        CustomToast.showError(
          context,
          "${category.name} already has a budget for $monthName $_selectedYear",
        );
        return;
      }

      success = await provider.addBudget(
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }

    if (success && mounted) {
      if (provider.selectedMonth != _selectedMonth ||
          provider.selectedYear != _selectedYear) {
        provider.changeDate(_selectedMonth, _selectedYear);
      }
      context.read<ReportProvider>().loadAllReports();
      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        widget.categoryBudget != null
            ? "Budget limit updated"
            : "Budget limit created",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "An error occurred",
      );
    }
  }

  Future<void> _delete() async {
    final cb = widget.categoryBudget;
    if (cb == null) return;

    final tokens = HorizonThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: tokens.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HorizonDimensions.radiusLG),
            side: BorderSide(color: tokens.rimNeutral),
          ),
          title: Text(
            "Delete Budget",
            style: HorizonTypography.headlineSm.copyWith(color: tokens.textHigh),
          ),
          content: Text(
            "Are you sure you want to delete the budget limit for ${cb.category}?",
            style: HorizonTypography.bodyMd.copyWith(color: tokens.textMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text("CANCEL", style: TextStyle(color: tokens.textMedium)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text("DELETE", style: TextStyle(color: tokens.outflow, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<BudgetProvider>();
      final ok = await provider.deleteBudget(cb.budgetId);
      if (mounted) {
        if (ok) {
          context.read<ReportProvider>().loadAllReports();
          Navigator.pop(context);
          CustomToast.showSuccess(context, "Budget limit deleted");
        } else {
          CustomToast.showError(context, provider.errorMessage ?? "Failed to delete");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryBudget != null;
    final provider = context.watch<BudgetProvider>();
    final currency = context.watch<CurrencyProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final expenseCategories = CategoryModel.getExpenseCategories();
    final monthName = DateFormat('MMMM').format(DateTime(2026, _selectedMonth));

    final budgetedIds = <int>{
      ...provider.budgetStatuses.map((b) => b.categoryId),
      if (provider.progress != null)
        ...provider.progress!.categoryBudgets.map((b) => b.categoryId),
      ...provider.budgets
          .where((b) => b.month == _selectedMonth && b.year == _selectedYear)
          .map((b) => b.categoryId),
    };

    final selectedCategory = expenseCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => expenseCategories.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(HorizonDimensions.radiusXL)),
        border: Border(top: BorderSide(color: tokens.rimNeutral)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.surface3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? "Edit Budget Limit" : "Add Budget Limit",
                          style: HorizonTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: tokens.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Target Period: $monthName $_selectedYear",
                          style: HorizonTypography.bodySm.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tokens.textMedium,
                          ),
                        ),
                      ],
                    ),
                    HorizonPressable(
                      label: "Close composer",
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: tokens.textMedium),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Section Header
                Text(
                  "Expense Category",
                  style: HorizonTypography.labelMd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textMedium,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),

                if (isEditing)
                  // Fixed category badge when editing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                      border: Border.all(color: tokens.rimNeutral),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          getCategoryIcon(selectedCategory.name),
                          size: 18,
                          color: tokens.ionCyan,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selectedCategory.name,
                          style: HorizonTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tokens.textHigh,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Modern Category Dropdown with Configured badging
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    isExpanded: true,
                    dropdownColor: tokens.surface2,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: tokens.textMedium),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: tokens.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                        borderSide: BorderSide(color: tokens.rimNeutral),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                        borderSide: BorderSide(color: tokens.rimNeutral),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                        borderSide: BorderSide(color: tokens.ionCyan),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: expenseCategories.map((c) {
                      final isConfigured = budgetedIds.contains(c.id);
                      final catColor = getCategoryColor(c.name);

                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(getCategoryIcon(c.name), size: 15, color: catColor),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: HorizonTypography.bodyMd.copyWith(
                                color: tokens.textHigh,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isConfigured) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tokens.warning.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Configured",
                                  style: HorizonTypography.labelCaps.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),

                const SizedBox(height: 24),

                // Budget Limit Amount Hero
                Text(
                  "Budget limit",
                  style: HorizonTypography.labelMd.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textMedium,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tokens.ionCyan,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currency.currencySymbol,
                        style: HorizonTypography.displayHero.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: tokens.ionCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('budget-amount-field'),
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: HorizonTypography.displayHero.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: tokens.textHigh,
                            letterSpacing: -1.0,
                            fontFeatures: HorizonTypography.tabularFigures,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            hintStyle: HorizonTypography.displayHero.copyWith(
                              fontSize: 38,
                              color: tokens.textLow,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter a budget amount";
                            }
                            final numVal = double.tryParse(val.trim());
                            if (numVal == null || numVal <= 0) {
                              return "Budget must be greater than zero";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Lighter Amount Shortcuts (+₹1,000, +₹2,000, +₹5,000, +₹10,000)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final increment in [1000.0, 2000.0, 5000.0, 10000.0])
                      HorizonPressable(
                        label: "Add ${currency.format(increment)}",
                        onPressed: () => _addQuickPreset(increment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Text(
                            "+${currency.format(increment)}",
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tokens.textHigh,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                // Actions: Save Button (and Delete if editing)
                Row(
                  children: [
                    if (isEditing) ...[
                      HorizonPressable(
                        label: "Delete budget",
                        onPressed: _delete,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.outflow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                            border: Border.all(color: tokens.outflow.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: tokens.outflow, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.ionCyan,
                          foregroundColor: tokens.isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                          ),
                        ),
                        child: Text(
                          isEditing ? "UPDATE BUDGET" : "SAVE BUDGET",
                          style: HorizonTypography.labelCaps.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: tokens.isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
