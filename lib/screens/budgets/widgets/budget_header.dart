import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// FinTrack HORIZON — Simplified Budget Header App Bar.
///
/// Features clean title, high scanability, and audited, fully functional actions:
/// Smart Suggestions, Budget History, and Month Selection.
class BudgetHeader extends StatelessWidget implements PreferredSizeWidget {
  const BudgetHeader({
    super.key,
    required this.onSuggestions,
    required this.onHistory,
    required this.onSelectMonth,
  });

  final VoidCallback onSuggestions;
  final VoidCallback onHistory;
  final VoidCallback onSelectMonth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return AppBar(
      backgroundColor: tokens.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        "Budgets",
        style: HorizonTypography.headlineSm.copyWith(
          fontWeight: FontWeight.w700,
          color: tokens.textHigh,
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Smart Suggestions",
          icon: Icon(
            Icons.lightbulb_outline_rounded,
            color: tokens.textMedium,
            size: 20,
          ),
          onPressed: onSuggestions,
        ),
        IconButton(
          tooltip: "Budget History",
          icon: Icon(Icons.history_rounded, color: tokens.textMedium, size: 20),
          onPressed: onHistory,
        ),
        IconButton(
          tooltip: "Select Month",
          icon: Icon(
            Icons.calendar_month_rounded,
            color: tokens.textMedium,
            size: 20,
          ),
          onPressed: onSelectMonth,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
