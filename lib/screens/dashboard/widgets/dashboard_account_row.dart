import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../models/dashboard_models.dart';
import '../../accounts/widgets/money_text.dart';

/// Compact account preview row for the dashboard.
///
/// Replaces the previous 210px bordered card deck: accounts read as one
/// continuous list with hairline separators, so balances preview without
/// competing with the hero.
class DashboardAccountRow extends StatelessWidget {
  const DashboardAccountRow({
    super.key,
    required this.account,
    this.onTap,
    this.showDivider = true,
  });

  final DashboardAccountItem account;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool isCredit = account.type.toLowerCase().contains('credit');
    final Color accent = isCredit ? tokens.electricIndigo : tokens.ionCyan;
    final String balanceDisplay = isCredit
        ? (account.outstandingDebt ?? "0.00")
        : account.currentBalance;

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
                        account.displayName,
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textHigh,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            (account.subtype ?? account.type.toUpperCase())
                                .toUpperCase(),
                            maxLines: stacked ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: HorizonTypography.labelCaps.copyWith(
                              color: tokens.textLow,
                              fontSize: 9,
                            ),
                          ),
                          if (isDefaultBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.ionCyan.withValues(alpha: 0.16),
                                borderRadius: HorizonDimensions.borderSM,
                              ),
                              child: Text(
                                'DEFAULT',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.ionCyan,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
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
                      child: Column(
                        crossAxisAlignment: stacked
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoneyText(
                            decimalString: balanceDisplay,
                            currencyCode: account.currencyCode,
                            style: HorizonTypography.tabularAmountMd.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isCredit
                                  ? tokens.outflow
                                  : tokens.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCredit ? 'OUTSTANDING' : 'AVAILABLE',
                            style: HorizonTypography.labelCaps.copyWith(
                              color: tokens.textLow,
                              fontSize: 9,
                            ),
                          ),
                        ],
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
                          isCredit
                              ? Icons.credit_card_rounded
                              : Icons.account_balance_rounded,
                          size: 17,
                          color: accent,
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
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: tokens.textLow,
                      ),
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

  bool get isDefaultBadge => account.isDefault == true;
}
