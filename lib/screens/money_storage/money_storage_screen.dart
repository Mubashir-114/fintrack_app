import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/fin_surface.dart';
import '../../models/account_model.dart';
import '../../models/dashboard_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../accounts/widgets/account_icon.dart';
import '../accounts/widgets/money_text.dart';
import '../dashboard/widgets/premium_dashboard_cards.dart';

/// Shows stored balances separately from monthly cash flow.
class MoneyStorageScreen extends StatefulWidget {
  const MoneyStorageScreen({super.key});

  @override
  State<MoneyStorageScreen> createState() => _MoneyStorageScreenState();
}

class _MoneyStorageScreenState extends State<MoneyStorageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboard = context.read<DashboardProvider>();
      final accounts = context.read<AccountProvider>();
      if (dashboard.summary == null) dashboard.loadDashboardData();
      if (accounts.accounts.isEmpty) accounts.loadAccounts();
    });
  }

  String _groupLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Bank accounts';
      case 'wallet':
        return 'Wallets & UPI';
      case 'cash':
        return 'Cash';
      case 'credit_card':
        return 'Credit cards';
      default:
        return 'Other accounts';
    }
  }

  DashboardAccountItem? _liveBalance(
    List<DashboardAccountItem> balances,
    int id,
  ) {
    for (final balance in balances) {
      if (balance.id == id) return balance;
    }
    return null;
  }

  Widget _accountCard(
    BuildContext context,
    AccountModel account,
    DashboardAccountItem? live,
  ) {
    final colors = AppColors.of(context);
    final isCredit = account.type == 'credit_card';
    final current = isCredit
        ? (live?.outstandingDebt ?? live?.currentBalance ?? account.openingAmount)
        : (live?.currentBalance ?? account.openingAmount);
    final label = isCredit ? 'Outstanding now' : 'Current balance';
    final accent = isCredit ? colors.danger : colors.primary;
    return FinSurface(
      emphasized: true,
      accent: accent,
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/accounts/${account.id}'),
      child: Row(
        children: [
          AccountIcon(type: account.type, subtype: account.subtype, accentColor: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_groupLabel(account.type)}${account.institutionName == null ? '' : ' • ${account.institutionName}'}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                const SizedBox(height: 9),
                Text(label, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
                const SizedBox(height: 2),
                MoneyText(decimalString: current, currencyCode: account.currencyCode, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
              const SizedBox(height: 17),
              Text('Opening', style: TextStyle(fontSize: 10, color: colors.textSecondary)),
              const SizedBox(height: 2),
              MoneyText(decimalString: account.openingAmount, currencyCode: account.currencyCode, style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Money storage'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'Add account', onPressed: () => context.push('/accounts/add')),
        ],
      ),
      body: Consumer2<DashboardProvider, AccountProvider>(
        builder: (context, dashboard, accounts, _) {
          final active = accounts.accounts.where((account) => account.isActive).toList();
          final grouped = <String, List<AccountModel>>{};
          for (final account in active) {
            grouped.putIfAbsent(account.type, () => []).add(account);
          }
          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              await Future.wait([dashboard.loadDashboardData(), accounts.refresh()]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                FinSurface(
                  emphasized: true,
                  accent: colors.primary,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stored across active accounts', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      const SizedBox(height: 8),
                      MoneyText(decimalString: dashboard.overview?.totalAssets ?? '0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: colors.textPrimary)),
                      const SizedBox(height: 7),
                      Text('Balances are separate from monthly income and expenses.', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const PremiumSectionHeader(title: 'Account map', subtitle: 'Bank, wallet, cash and credit-card visibility'),
                const SizedBox(height: 10),
                if (accounts.isLoading && active.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (active.isEmpty)
                  PremiumEmptyStateCard(icon: Icons.account_balance_wallet_outlined, title: 'No active accounts', message: 'Add a bank, wallet, cash account or card to see where money is stored.', actionLabel: 'Add account', onAction: () => context.push('/accounts/add'), accent: colors.primary)
                else
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Text(_groupLabel(entry.key), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                          const SizedBox(width: 8),
                          Text('${entry.value.length}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                    for (final account in entry.value) ...[
                      _accountCard(context, account, _liveBalance(dashboard.accounts, account.id)),
                      const SizedBox(height: 8),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
