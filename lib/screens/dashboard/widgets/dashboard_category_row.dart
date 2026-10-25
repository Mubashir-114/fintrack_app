import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/dashboard_models.dart';
import '../../accounts/widgets/money_text.dart';

/// Open category spending row with a hairline separator and an animated
/// share bar. Categories read as one ranked list instead of a boxed matrix.
class DashboardCategoryRow extends StatelessWidget {
  const DashboardCategoryRow({
    super.key,
    required this.category,
    this.showDivider = true,
  });

  final CategorySummary category;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final double pctVal =
        (double.tryParse(category.percentage ?? "0") ?? 0) / 100.0;
    final Color catColor = getCategoryColor(category.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
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
                            getCategoryIcon(category.name),
                            size: 14,
                            color: catColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
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
                          '${category.percentage ?? "0.0"}% of expenses',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.textMedium,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MoneyText(
                          decimalString:
                              category.totalString ??
                              category.total.toStringAsFixed(2),
                          style: HorizonTypography.tabularAmountSm.copyWith(
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
              const SizedBox(height: 8),
              AnimatedProgressBar(
                value: pctVal.clamp(0.0, 1.0),
                color: catColor,
                backgroundColor: tokens.surface2,
                height: 5,
                semanticLabel: '${category.name} share of spending',
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
      ],
    );
  }
}
