import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../models/account_model.dart';
import '../../models/dashboard_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/liquidity_summary.dart';
import 'widgets/storage_action_row.dart';
import 'widgets/storage_node_row.dart';

/// FinTrack // HORIZON — Money Storage & Asset Nodes Screen.
///
/// Composition: telemetry header, filter rail, one anchoring liquidity
/// summary with an open metric strip, a compact operational action row, then
/// managed repositories as hairline-separated rows instead of cards.
class MoneyStorageScreen extends StatefulWidget {
  const MoneyStorageScreen({super.key});

  @override
  State<MoneyStorageScreen> createState() => _MoneyStorageScreenState();
}

class _MoneyStorageScreenState extends State<MoneyStorageScreen> {
  String _selectedFilter = 'all'; // 'all', 'bank', 'vault', 'credit'

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

  DashboardAccountItem? _liveBalance(
    List<DashboardAccountItem> balances,
    int id,
  ) {
    for (final balance in balances) {
      if (balance.id == id) return balance;
    }
    return null;
  }

  String _getNodeBadge(AccountModel account) {
    if (account.type == 'bank') return 'BANK ACCOUNT';
    if (account.type == 'credit_card') return 'CREDIT CARD';
    if (account.type == 'wallet') return 'WALLET';
    if (account.type == 'cash') return 'OFFLINE RECORD';
    return 'TIER 1 RESERVE';
  }

  String _getBalanceLabel(AccountModel account) {
    if (account.type == 'credit_card') return 'CURRENT OUTSTANDING';
    if (account.type == 'bank') return 'RECORDED BALANCE';
    if (account.type == 'wallet') return 'WALLET BALANCE';
    if (account.type == 'cash') return 'ON-HAND VAULT';
    return 'STORED CAPITAL';
  }

  Color _getNodeAccent(AccountModel account, HorizonThemeTokens tokens) {
    if (account.type == 'credit_card') return tokens.outflow;
    if (account.type == 'bank') return tokens.ionCyan;
    if (account.type == 'wallet') return tokens.electricIndigo;
    if (account.type == 'cash') return tokens.surplus;
    return tokens.luminousGold;
  }

  IconData _getNodeIcon(AccountModel account) {
    if (account.type == 'credit_card') return Icons.credit_card;
    if (account.type == 'bank') return Icons.account_balance;
    if (account.type == 'wallet') return Icons.qr_code_2;
    if (account.type == 'cash') return Icons.payments_outlined;
    return Icons.shield_outlined;
  }

  String _getNodeStatus(AccountModel account) {
    return account.isActive ? 'ACTIVE RECORD' : 'ARCHIVED RECORD';
  }

  String _getNodeSubStatus(AccountModel account) {
    return account.isDefault ? 'Default account' : 'Saved transactions only';
  }

  Future<void> _reconcile(
    BuildContext context,
    DashboardProvider dashboard,
    AccountProvider accounts,
  ) async {
    final tokens = HorizonThemeTokens.of(context);
    await Future.wait([dashboard.loadDashboardData(), accounts.refresh()]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All nodes reconciled with latest ledger',
          style: HorizonTypography.bodySm,
        ),
        backgroundColor: tokens.surface3,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    AccountProvider provider,
    AccountModel account,
  ) async {
    final tokens = HorizonThemeTokens.of(context);
    final ok = await provider.setDefault(account.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${account.displayName} is now your default account'
              : (provider.actionError ?? 'Failed to set default account'),
          style: HorizonTypography.bodySm,
        ),
        backgroundColor: tokens.surface3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: tokens.textHigh),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tokens.ionCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIQUIDITY // ASSET NODES',
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.textMedium,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Money Storage',
              style: HorizonTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textHigh,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.ionCyan,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: tokens.canvas, size: 20),
            ),
            tooltip: 'Add node',
            onPressed: () => context.push('/accounts/add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<DashboardProvider, AccountProvider>(
        builder: (context, dashboard, accounts, _) {
          final active = accounts.accounts.where((a) => a.isActive).toList();

          // Sub-metric totals for the liquidity summary.
          double inHandTotal = 0;
          double termVaultTotal = 0;
          double exposureTotal = 0;

          for (final acc in active) {
            final live = _liveBalance(dashboard.accounts, acc.id);
            final amtStr = acc.type == 'credit_card'
                ? (live?.outstandingDebt ??
                      live?.currentBalance ??
                      acc.openingAmount)
                : (live?.currentBalance ?? acc.openingAmount);
            final amt = double.tryParse(amtStr) ?? 0.0;

            if (acc.type == 'credit_card') {
              exposureTotal += amt;
            } else if (acc.type == 'cash' ||
                acc.type == 'bank' ||
                acc.type == 'wallet') {
              inHandTotal += amt;
            } else {
              termVaultTotal += amt;
            }
          }

          final filtered = active.where((a) {
            if (_selectedFilter == 'bank') return a.type == 'bank';
            if (_selectedFilter == 'vault') {
              return a.type != 'bank' &&
                  a.type != 'credit_card' &&
                  a.type != 'wallet' &&
                  a.type != 'cash';
            }
            if (_selectedFilter == 'credit') return a.type == 'credit_card';
            return true;
          }).toList();

          final netWorthStr =
              dashboard.overview?.netWorth ??
              dashboard.overview?.totalAssets ??
              '0.00';
          final inflowMtd = dashboard.overview?.monthlyIncome ?? '0.00';

          return RefreshIndicator(
            color: tokens.ionCyan,
            backgroundColor: tokens.surface2,
            onRefresh: () async {
              await Future.wait([
                dashboard.loadDashboardData(),
                accounts.refresh(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: 8,
              ),
              children: [
                // ── Filter rail ──────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'all',
                        'All Nodes (${active.length})',
                        tokens,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('bank', 'Banking', tokens),
                      const SizedBox(width: 8),
                      _buildFilterChip('vault', 'Treasury', tokens),
                      const SizedBox(width: 8),
                      _buildFilterChip('credit', 'Liabilities', tokens),
                    ],
                  ),
                ),
                const SizedBox(height: HorizonDimensions.spaceMD),

                // ── Liquidity summary ────────────────────────────────────
                LiquiditySummary(
                  netLiquidity: netWorthStr,
                  inflowMonthToDate: inflowMtd,
                  reconciledCount: active.length,
                  inHand: inHandTotal,
                  termVault: termVaultTotal,
                  exposure: exposureTotal,
                ),
                const SizedBox(height: HorizonDimensions.spaceMD),

                // ── Operational actions ─────────────────────────────────
                StorageActionRow(
                  actions: [
                    StorageAction(
                      icon: Icons.sync_rounded,
                      label: 'Reconcile',
                      caption: '${active.length} NODES',
                      accent: tokens.ionCyan,
                      onTap: () => _reconcile(context, dashboard, accounts),
                    ),
                    StorageAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      caption: 'ZERO FEE',
                      accent: tokens.electricIndigo,
                      onTap: () => context.push('/accounts/transfer'),
                    ),
                    StorageAction(
                      icon: Icons.add_link_rounded,
                      label: 'Link node',
                      caption: '+ BANK / UPI',
                      accent: tokens.luminousGold,
                      onTap: () => context.push('/accounts/add'),
                    ),
                  ],
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── Managed repositories ────────────────────────────────
                HorizonSectionHeader(
                  title: 'Managed Repositories',
                  icon: Icons.account_balance_wallet_rounded,
                  caption: 'ALL CHANNELS ACTIVE',
                ),
                if (filtered.isEmpty)
                  HorizonEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No Nodes in Filter',
                    description:
                        'No active asset repositories found for the selected filter.',
                    actionLabel: 'Add Node',
                    onAction: () => context.push('/accounts/add'),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++)
                        StorageNodeRow(
                          account: filtered[i],
                          balance: _balanceOf(dashboard, filtered[i]),
                          balanceLabel: _getBalanceLabel(filtered[i]),
                          accent: _getNodeAccent(filtered[i], tokens),
                          icon: _getNodeIcon(filtered[i]),
                          statusLabel: _getNodeStatus(filtered[i]),
                          subStatusLabel: _getNodeSubStatus(filtered[i]),
                          badgeLabel: _getNodeBadge(filtered[i]),
                          showDivider: i != filtered.length - 1,
                          onViewDetails: () =>
                              context.push('/accounts/${filtered[i].id}'),
                          onSetDefault: () =>
                              _setDefault(context, accounts, filtered[i]),
                        ),
                    ],
                  ),

                const SizedBox(height: HorizonDimensions.spaceLG),
                Text(
                  'Records are stored on the FinTrack backend and reconcile '
                  'whenever you refresh. Pull down to sync every node.',
                  style: HorizonTypography.bodySm.copyWith(
                    color: tokens.textLow,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: HorizonDimensions.dockClearance),
              ],
            ),
          );
        },
      ),
    );
  }

  String _balanceOf(DashboardProvider dashboard, AccountModel account) {
    final live = _liveBalance(dashboard.accounts, account.id);
    if (account.type == 'credit_card') {
      return live?.outstandingDebt ??
          live?.currentBalance ??
          account.openingAmount;
    }
    return live?.currentBalance ?? account.openingAmount;
  }

  Widget _buildFilterChip(String key, String label, HorizonThemeTokens tokens) {
    final isSelected = _selectedFilter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = key),
        borderRadius: HorizonDimensions.borderFull,
        child: AnimatedContainer(
          duration: HorizonMotion.quick,
          curve: HorizonMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? tokens.surface2 : tokens.surface1,
            borderRadius: HorizonDimensions.borderFull,
            border: Border.all(
              color: isSelected ? tokens.ionCyan : tokens.rimNeutral,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.ionCyan,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: HorizonTypography.labelMd.copyWith(
                  color: isSelected ? tokens.ionCyan : tokens.textMedium,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
