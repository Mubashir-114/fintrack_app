import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/fin_surface.dart';
import '../../../models/account_model.dart';
import 'account_icon.dart';
import 'money_text.dart';

/// Card displayed in the accounts list. Visually distinguishes credit-card
/// liabilities (red accent) from asset accounts (primary accent).
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;

  const AccountCard({super.key, required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isCredit = account.type == 'credit_card';
    final accentColor = switch (account.type) {
      'credit_card' => colors.danger,
      'cash' => colors.highlight,
      'wallet' => colors.info,
      _ => colors.primary,
    };
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MoneyText(
          decimalString: isCredit && account.creditLimit != null
              ? account.creditLimit!
              : account.openingAmount,
          currencyCode: account.currencyCode,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isCredit ? colors.danger : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isCredit ? 'Credit limit' : 'Opening amount',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
    return FinSurface(
      accent: accentColor,
      emphasized: true,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AccountIcon(
                    type: account.type,
                    subtype: account.subtype,
                    size: 40,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              account.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (account.isDefault) _DefaultBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _SubtitleRow(account: account, isDark: colors.isDark),
                      ],
                    ),
                  ),
                  if (!compact) ...[const SizedBox(width: 12), amount],
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 12),
                Align(alignment: AlignmentDirectional.centerEnd, child: amount),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.of(context).primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Text(
        'Default',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).primary,
        ),
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  final AccountModel account;
  final bool isDark;

  const _SubtitleRow({required this.account, required this.isDark});

  String get _subtitle {
    final parts = <String>[];
    if (account.institutionName != null) {
      parts.add(account.institutionName!);
    }
    if (account.maskedLast4 != null) {
      parts.add('••••${account.maskedLast4}');
    }
    if (parts.isEmpty) {
      return _typeLabel(account.subtype);
    }
    return parts.join(' · ');
  }

  String _typeLabel(String subtype) {
    switch (subtype) {
      case 'savings':
        return 'Savings Account';
      case 'current':
        return 'Current Account';
      case 'salary':
        return 'Salary Account';
      case 'stored_value':
        return 'Digital Wallet';
      case 'credit_card':
        return 'Credit Card';
      case 'cash':
        return 'Cash';
      default:
        return subtype;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? AppColors.of(context).textSecondary
        : AppColors.of(context).textSecondary;
    return Text(
      _subtitle,
      style: TextStyle(fontSize: 12, color: color),
      overflow: TextOverflow.ellipsis,
    );
  }
}
