import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';

typedef BudgetMonthControl = BudgetMonthSelector;

/// FinTrack HORIZON — Modern Month & Year Selection Bar.
///
/// Features compact `‹   OCTOBER 2026   ›` control, tactile press feedback,
/// and fast date picker modal trigger.
class BudgetMonthSelector extends StatelessWidget {
  const BudgetMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTapMonth,
    this.isLoading = false,
  });

  final int selectedMonth;
  final int selectedYear;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTapMonth;
  final bool isLoading;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return now.month == selectedMonth && now.year == selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(selectedYear, selectedMonth));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
        border: Border.all(color: tokens.rimNeutral),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            // Previous Month Button
            Semantics(
              label: 'Previous month',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: tokens.textMedium,
                tooltip: "Previous Month",
                onPressed: onPreviousMonth,
              ),
            ),

            // Month & Year Display (Tap to open picker)
            Expanded(
              child: HorizonPressable(
                label: "Select month and year: $monthName $selectedYear",
                onPressed: onTapMonth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: tokens.ionCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$monthName $selectedYear",
                          style: HorizonTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.2,
                            color: tokens.textHigh,
                          ),
                        ),
                        if (_isCurrentMonth) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.ionCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                HorizonDimensions.radiusSM,
                              ),
                              border: Border.all(
                                color: tokens.ionCyan.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              "CURRENT",
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: tokens.ionCyan,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Next Month Button
            Semantics(
              label: 'Next month',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: tokens.textMedium,
                tooltip: "Next Month",
                onPressed: onNextMonth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
