import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/currency_provider.dart';
import '../../../core/utils/money_formatter.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/transaction_model.dart';

/// Recent transaction row for the dashboard: one continuous list with a
/// hairline separator, tabular amount and category telemetry subtitle.
class DashboardRecentRow extends StatelessWidget {
  const DashboardRecentRow({
    super.key,
    required this.transaction,
    required this.dateString,
    this.onTap,
    this.showDivider = true,
  });

  final TransactionModel transaction;
  final String dateString;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool isExpense = transaction.type == "expense";
    final Color categoryColor = getCategoryColor(transaction.category);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 328 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final identity = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.title,
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textHigh,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transaction.category} • $dateString',
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.textMedium,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  );
                  final amount = Align(
                    alignment: stacked
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: stacked
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Text(
                        '${isExpense ? '-' : '+'}'
                        '${MoneyFormatter.amount(transaction.amount, currencyCode: context.watch<CurrencyProvider?>()?.currencyCode ?? 'INR')}',
                        style: HorizonTypography.tabularAmountSm.copyWith(
                          color: isExpense ? tokens.outflow : tokens.surplus,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                  return Row(
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: HorizonDimensions.borderDefault,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          getCategoryIcon(transaction.category),
                          size: 17,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (stacked)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              identity,
                              const SizedBox(height: 6),
                              amount,
                            ],
                          ),
                        )
                      else ...[
                        Expanded(flex: 3, child: identity),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: amount),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: tokens.rimNeutral),
      ],
    );
  }
}
