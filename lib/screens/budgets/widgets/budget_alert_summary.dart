import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../models/budget_model.dart';

/// FinTrack HORIZON — Compact Actionable Budget Notice & Alert Summary.
///
/// Replaces the old giant yellow card with a sleek, quiet alert strip
/// that expands on tap to review items without visual clutter.
class BudgetAlertSummary extends StatefulWidget {
  const BudgetAlertSummary({
    super.key,
    required this.alerts,
  });

  final BudgetAlertsResponseModel alerts;

  @override
  State<BudgetAlertSummary> createState() => _BudgetAlertSummaryState();
}

class _BudgetAlertSummaryState extends State<BudgetAlertSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final alerts = widget.alerts;
    final alertItems = [...alerts.exceeded, ...alerts.approachingLimit];

    if (alertItems.isEmpty && alerts.overallAlert == null && alerts.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final isCritical = alerts.exceeded.isNotEmpty;
    final accentColor = isCritical ? tokens.outflow : tokens.warning;
    final totalCount = alerts.totalAlertsCount > 0 ? alerts.totalAlertsCount : alertItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tapable Header Strip
          HorizonPressable(
            label: "Toggle budget alerts details",
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCritical ? "Budget Alert" : "Budget Notice",
                    style: HorizonTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertItems.isNotEmpty
                          ? alertItems.first.message
                          : "$totalCount alerts · Tap to review",
                      style: HorizonTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: tokens.textHigh,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: tokens.textMedium,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Details
          if (_expanded) ...[
            Divider(height: 1, color: tokens.rowDivider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alerts.overallAlert != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        alerts.overallAlert!.message,
                        style: HorizonTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: tokens.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  for (final item in alertItems) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: item.severity == 'critical' ? tokens.outflow : tokens.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.message.isNotEmpty
                                      ? item.message
                                      : "${item.category ?? 'Category'}: ${item.actualSpending ?? '0'} spent of ${item.budgetLimit ?? '0'}",
                                  style: HorizonTypography.bodySm.copyWith(
                                    fontSize: 11,
                                    color: tokens.textHigh,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
