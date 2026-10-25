import 'package:flutter/material.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';
import 'category_budget_row.dart';

export 'category_budget_row.dart';

/// Legacy export wrapper forwarding to the redesigned [CategoryBudgetRow].
class CategoryBudgetCard extends StatelessWidget {
  const CategoryBudgetCard({
    super.key,
    required this.budget,
    required this.currency,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetCategoryProgressModel budget;
  final CurrencyProvider currency;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CategoryBudgetRow(
      budget: budget,
      currency: currency,
      index: index,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
