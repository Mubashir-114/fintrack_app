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
    this.note,
    this.amountDisplay,
    this.trailing,
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

  /// Optional secondary line shown under the metadata.
  final String? note;

  /// Optional pre-formatted amount (e.g. in the user's active currency).
  /// When provided it replaces the default INR formatting.
  final String? amountDisplay;

  /// Optional trailing control, such as an overflow actions menu.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final amountColor = isExpense ? tokens.outflow : tokens.surplus;
    final finalDisplayAmount =
        amountDisplay ??
        (isExpense
            ? '-${HorizonFormatters.formatInr(amount, showSign: false)}'
            : '+${HorizonFormatters.formatInr(amount, showSign: false)}');

    final subtitleParts = <String>[];
    if (category != null && category!.isNotEmpty) {
      subtitleParts.add(category!);
    }
    if (accountName != null && accountName!.isNotEmpty) {
      subtitleParts.add(accountName!);
    }
    if (dateString != null && dateString!.isNotEmpty) {
      subtitleParts.add(dateString!);
    }
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 328 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final amountWidget = FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: stacked
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Text(
                      finalDisplayAmount,
                      style: HorizonTypography.tabularAmountSm.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  );
                  return Row(
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.surface2,
                          borderRadius: HorizonDimensions.borderDefault,
                          border: Border.all(
                            color: (categoryColor ?? tokens.ionCyan).withValues(
                              alpha: 0.20,
                            ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: stacked ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: HorizonTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tokens.textHigh,
                              ),
                            ),
                            if (stacked) ...[
                              const SizedBox(height: 4),
                              amountWidget,
                            ],
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: stacked ? 3 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (note != null && note!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                note!.trim(),
                                maxLines: stacked ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textLow,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!stacked) ...[
                        const SizedBox(width: HorizonDimensions.spaceSM),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: amountWidget,
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(width: 4),
                        trailing!,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: tokens.rowDivider,
            indent:
                HorizonDimensions.marginMobile + 36 + HorizonDimensions.spaceMD,
          ),
      ],
    );
  }
}
