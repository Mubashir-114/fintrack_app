import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../models/account_model.dart';
import '../../accounts/widgets/money_text.dart';

/// One managed repository (account) row in Money Storage.
///
/// Open, hairline-separated layout replacing the previous bordered cards:
/// accent pod, identity with badges, live balance, status and a real actions
/// menu. Safe at 2× text through flex + fitted amount scaling.
class StorageNodeRow extends StatelessWidget {
  const StorageNodeRow({
    super.key,
    required this.account,
    required this.balance,
    required this.balanceLabel,
    required this.accent,
    required this.icon,
    required this.statusLabel,
    required this.subStatusLabel,
    required this.badgeLabel,
    this.onViewDetails,
    this.onSetDefault,
    this.showDivider = true,
  });

  final AccountModel account;
  final String balance;
  final String balanceLabel;
  final Color accent;
  final IconData icon;
  final String statusLabel;
  final String subStatusLabel;
  final String badgeLabel;
  final VoidCallback? onViewDetails;
  final VoidCallback? onSetDefault;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final bool isCredit = account.type == 'credit_card';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: onViewDetails,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (account.isDefault)
                            _Badge(
                              label: 'DEFAULT',
                              color: tokens.ionCyan,
                              strong: true,
                            ),
                          _Badge(label: badgeLabel, color: accent),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${account.institutionName ?? 'Asset Repository'}'
                        '${account.maskedLast4 != null ? ' · ···· ${account.maskedLast4}' : ' · ID-${account.id}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.textMedium,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                  final balanceDetails = Column(
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        balanceLabel,
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.textLow,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: MoneyText(
                          decimalString: balance,
                          currencyCode: account.currencyCode,
                          style: HorizonTypography.tabularAmountLg.copyWith(
                            color: isCredit ? tokens.outflow : tokens.textHigh,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: HorizonTypography.labelCaps.copyWith(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        subStatusLabel,
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.bodySm.copyWith(
                          color: tokens.textLow,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: HorizonDimensions.borderDefault,
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 19, color: accent),
                      ),
                      const SizedBox(width: 12),
                      if (stacked)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              identity,
                              const SizedBox(height: 10),
                              balanceDetails,
                            ],
                          ),
                        )
                      else ...[
                        Expanded(flex: 3, child: identity),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: balanceDetails),
                      ],
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: tokens.textLow,
                          size: 18,
                        ),
                        color: tokens.surface2,
                        tooltip: 'Account Actions',
                        onSelected: (action) {
                          if (action == 'details') {
                            onViewDetails?.call();
                          } else if (action == 'default') {
                            onSetDefault?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16,
                                  color: tokens.textMedium,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'View Details',
                                  style: TextStyle(color: tokens.textHigh),
                                ),
                              ],
                            ),
                          ),
                          if (!account.isDefault && account.isAsset)
                            PopupMenuItem(
                              value: 'default',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star_outline_rounded,
                                    size: 16,
                                    color: tokens.ionCyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Set as Default',
                                    style: TextStyle(color: tokens.ionCyan),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.strong = false});

  final String label;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? 0.2 : 0.15),
        borderRadius: HorizonDimensions.borderSM,
        border: strong ? Border.all(color: color, width: 0.8) : null,
      ),
      child: Text(
        label,
        style: HorizonTypography.labelCaps.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
