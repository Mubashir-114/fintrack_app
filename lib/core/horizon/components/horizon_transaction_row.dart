import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_formatters.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Cockpit transaction ledger row for FinTrack // HORIZON.
/// High-density financial entry with tabular numerals, category icon pod,
/// and clear surplus/outflow telemetry indicators.
class HorizonTransactionRow extends StatelessWidget {
  const HorizonTransactionRow({
    super.key,
    required this.title,
    required this.amount,
    required this.isExpense,
    this.category,
    this.accountName,
    this.dateString,
    this.categoryIcon = Icons.receipt_long_rounded,
    this.categoryColor,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final num amount;
  final bool isExpense;
  final String? category;
  final String? accountName;
  final String? dateString;
  final IconData categoryIcon;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final amountColor = isExpense ? tokens.outflow : tokens.surplus;
    final finalDisplayAmount = isExpense
        ? '-${HorizonFormatters.formatInr(amount, showSign: false)}'
        : '+${HorizonFormatters.formatInr(amount, showSign: false)}';

    final subtitleParts = <String>[];
    if (category != null && category!.isNotEmpty) subtitleParts.add(category!);
    if (accountName != null && accountName!.isNotEmpty) subtitleParts.add(accountName!);
    if (dateString != null && dateString!.isNotEmpty) subtitleParts.add(dateString!);
    final subtitle = subtitleParts.join(' • ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // 36x36 Level 2 surface square rounded to 8px
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.surface2,
                      borderRadius: HorizonDimensions.borderDefault,
                      border: Border.all(
                        color: (categoryColor ?? tokens.ionCyan).withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      categoryIcon,
                      size: 18,
                      color: categoryColor ?? tokens.ionCyan,
                    ),
                  ),
                  const SizedBox(width: HorizonDimensions.spaceMD),

                  // Title and metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HorizonTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tokens.textHigh,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: HorizonDimensions.spaceSM),

                  // Tabular numerical readout
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 84),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        finalDisplayAmount,
                        textAlign: TextAlign.right,
                        style: HorizonTypography.tabularAmountSm.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: tokens.rowDivider,
            indent: HorizonDimensions.marginMobile + 36 + HorizonDimensions.spaceMD,
          ),
      ],
    );
  }
}
