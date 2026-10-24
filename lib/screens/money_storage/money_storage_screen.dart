import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../models/account_model.dart';
import '../../models/dashboard_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../accounts/widgets/money_text.dart';

/// FinTrack // HORIZON — Money Storage & Asset Nodes Screen.
///
/// Implements the approved Stitch accounts_money_storage design:
/// - Screen Telemetry Header (LIQUIDITY // ASSET NODES)
/// - Top action buttons (Tune filter & Add node)
/// - Category Filter Chips (All Nodes, Banking, Treasury, Liabilities)
/// - Net Consolidated Liquidity Hero Module with sub-metrics ticker
/// - Operational Actions Command Deck (Reconcile, Transfer, Link Node)
/// - Managed Asset Repositories cards with colored telemetry edges
/// - Protocol Security Footer
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
    if (account.type == 'bank') return 'BANK ACCOUNT RECORD';
    if (account.type == 'credit_card') return 'CREDIT CARD RECORD';
    if (account.type == 'wallet') return 'WALLET RECORD';
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
            Row(
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
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.rimNeutral),
              ),
              child: Icon(Icons.tune, color: tokens.ionCyan, size: 18),
            ),
            tooltip: 'Filter nodes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filter presets active', style: HorizonTypography.bodySm),
                  backgroundColor: tokens.surface3,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
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

          // Calculate sub-metrics
          double inHandTotal = 0;
          double termVaultTotal = 0;
          double exposureTotal = 0;

          for (final acc in active) {
            final live = _liveBalance(dashboard.accounts, acc.id);
            final amtStr = acc.type == 'credit_card'
                ? (live?.outstandingDebt ?? live?.currentBalance ?? acc.openingAmount)
                : (live?.currentBalance ?? acc.openingAmount);
            final amt = double.tryParse(amtStr) ?? 0.0;

            if (acc.type == 'credit_card') {
              exposureTotal += amt;
            } else if (acc.type == 'cash' || acc.type == 'bank' || acc.type == 'wallet') {
              inHandTotal += amt;
            } else {
              termVaultTotal += amt;
            }
          }

          // Filter accounts
          final filtered = active.where((a) {
            if (_selectedFilter == 'bank') return a.type == 'bank';
            if (_selectedFilter == 'vault') return a.type != 'bank' && a.type != 'credit_card' && a.type != 'wallet' && a.type != 'cash';
            if (_selectedFilter == 'credit') return a.type == 'credit_card';
            return true;
          }).toList();

          final netWorthStr = dashboard.overview?.netWorth ?? dashboard.overview?.totalAssets ?? '0.00';
          final inflowMtd = dashboard.overview?.monthlyIncome ?? '0.00';

          return RefreshIndicator(
            color: tokens.ionCyan,
            backgroundColor: tokens.surface2,
            onRefresh: () async {
              await Future.wait([dashboard.loadDashboardData(), accounts.refresh()]);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: 8,
              ),
              children: [
                // ── Category Filter Pills ───────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Nodes (${active.length})', tokens),
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

                // ── Net Consolidated Liquidity Hero Module ──────────────────
                HorizonSurface(
                  tier: HorizonSurfaceTier.surface2,
                  cornerAccentColor: tokens.ionCyan,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Top Telemetry Metadata
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'NET CONSOLIDATED LIQUIDITY',
                            style: HorizonTypography.labelCaps.copyWith(
                              color: tokens.textMedium,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tokens.surface3,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: tokens.rimNeutral),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: tokens.ionCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${active.length} RECONCILED',
                                  style: HorizonTypography.labelCaps.copyWith(
                                    color: tokens.ionCyan,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Main Balance Display
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹ ',
                            style: HorizonTypography.headlineMd.copyWith(
                              color: tokens.ionCyan,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: MoneyText(
                              decimalString: netWorthStr,
                              style: HorizonTypography.displayHero.copyWith(
                                color: tokens.textHigh,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Inflow MTD Subtitle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tokens.surface1,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+₹$inflowMtd INFLOW MTD',
                              style: HorizonTypography.labelCaps.copyWith(
                                color: tokens.ionCyan,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Real-time ledger sync',
                            style: HorizonTypography.bodySm.copyWith(
                              color: tokens.textMedium,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sub-metrics Horizontal Ticker Grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.surface1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tokens.rimNeutral),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.account_balance_wallet, size: 12, color: tokens.ionCyan),
                                        const SizedBox(width: 4),
                                        Text(
                                          'In-Hand',
                                          style: HorizonTypography.labelCaps.copyWith(color: tokens.textMedium, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: MoneyText(
                                      decimalString: inHandTotal.toStringAsFixed(2),
                                      style: HorizonTypography.tabularAmountSm.copyWith(
                                        color: tokens.textHigh,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Active Cash',
                                      style: HorizonTypography.labelCaps.copyWith(color: tokens.ionCyan, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.surface1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tokens.rimNeutral),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock, size: 12, color: tokens.luminousGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Term Vault',
                                          style: HorizonTypography.labelCaps.copyWith(color: tokens.textMedium, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: MoneyText(
                                      decimalString: termVaultTotal.toStringAsFixed(2),
                                      style: HorizonTypography.tabularAmountSm.copyWith(
                                        color: tokens.textHigh,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'RECORDED ASSETS',
                                      style: HorizonTypography.labelCaps.copyWith(color: tokens.luminousGold, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.surface1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tokens.rimNeutral),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.credit_card, size: 12, color: tokens.outflow),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Exposure',
                                          style: HorizonTypography.labelCaps.copyWith(color: tokens.textMedium, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: MoneyText(
                                      decimalString: '-${exposureTotal.toStringAsFixed(2)}',
                                      style: HorizonTypography.tabularAmountSm.copyWith(
                                        color: tokens.outflow,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Due 05 Nov',
                                      style: HorizonTypography.labelCaps.copyWith(color: tokens.textMedium, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HorizonDimensions.spaceMD),

                // ── Operational Actions Command Deck ───────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Future.wait([dashboard.loadDashboardData(), accounts.refresh()]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('All nodes reconciled with latest ledger', style: HorizonTypography.bodySm),
                                backgroundColor: tokens.surface3,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tokens.surface3,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.sync, color: tokens.ionCyan, size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Reconcile',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${active.length} Nodes',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/accounts/transfer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tokens.surface3,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.swap_horiz, color: tokens.electricIndigo, size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Transfer',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Zero fee',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/accounts/add'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tokens.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tokens.surface3,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.add_link, color: tokens.luminousGold, size: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Link Node',
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textHigh,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '+ Bank / UPI',
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HorizonDimensions.spaceLG),

                // ── Managed Asset Repositories Header ───────────────────────
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'MANAGED ASSET REPOSITORIES',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.textMedium,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'ALL CHANNELS ACTIVE',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.ionCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Node Cards List ─────────────────────────────────────────
                if (filtered.isEmpty)
                  HorizonEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No Nodes in Filter',
                    description: 'No active asset repositories found for the selected filter.',
                    actionLabel: 'Add Node',
                    onAction: () => context.push('/accounts/add'),
                  )
                else
                  for (final account in filtered) ...[
                    _buildNodeCard(
                      context,
                      account,
                      _liveBalance(dashboard.accounts, account.id),
                      tokens,
                    ),
                    const SizedBox(height: 10),
                  ],

                const SizedBox(height: HorizonDimensions.spaceMD),

                // ── Protocol Security Footer Card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surface1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.security, color: tokens.ionCyan, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reconciliation Node Protocol',
                              style: HorizonTypography.bodySm.copyWith(
                                color: tokens.textHigh,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Saved records on the FinTrack backend',
                              style: HorizonTypography.bodySm.copyWith(
                                color: tokens.textMedium,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.surface3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'V2.4',
                          style: HorizonTypography.labelCaps.copyWith(
                            color: tokens.ionCyan,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildFilterChip(String key, String label, HorizonThemeTokens tokens) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tokens.surface2 : tokens.surface1,
          borderRadius: BorderRadius.circular(999),
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
    );
  }

  Widget _buildNodeCard(
    BuildContext context,
    AccountModel account,
    DashboardAccountItem? live,
    HorizonThemeTokens tokens,
  ) {
    final accent = _getNodeAccent(account, tokens);
    final badge = _getNodeBadge(account);
    final balLabel = _getBalanceLabel(account);
    final status = _getNodeStatus(account);
    final subStatus = _getNodeSubStatus(account);

    final isCredit = account.type == 'credit_card';
    final current = isCredit
        ? (live?.outstandingDebt ?? live?.currentBalance ?? account.openingAmount)
        : (live?.currentBalance ?? account.openingAmount);

    return GestureDetector(
      onTap: () => context.push('/accounts/${account.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.rimNeutral),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Telemetry Left Edge Stripe
              Container(
                width: 4,
                color: accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon, Titles, Badges, Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: tokens.surface3,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getNodeIcon(account), color: accent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        account.displayName,
                                        style: HorizonTypography.bodyMd.copyWith(
                                          color: tokens.textHigh,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (account.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: tokens.ionCyan.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: tokens.ionCyan, width: 0.8),
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        badge,
                                        style: HorizonTypography.labelCaps.copyWith(
                                          color: accent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${account.institutionName ?? 'Asset Repository'} · ${account.maskedLast4 != null ? '···· ${account.maskedLast4}' : 'ID-${account.id}'}',
                                  style: HorizonTypography.bodySm.copyWith(
                                    color: tokens.textMedium,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: tokens.textLow, size: 18),
                            color: tokens.surface2,
                            tooltip: 'Account Actions',
                            onSelected: (action) async {
                              if (action == 'details') {
                                context.push('/accounts/${account.id}');
                              } else if (action == 'default') {
                                final accountsProvider = context.read<AccountProvider>();
                                final ok = await accountsProvider.setDefault(account.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '${account.displayName} is now your default account'
                                            : (accountsProvider.actionError ?? 'Failed to set default account'),
                                        style: HorizonTypography.bodySm,
                                      ),
                                      backgroundColor: tokens.surface3,
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'details',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 16, color: tokens.textMedium),
                                    const SizedBox(width: 8),
                                    Text('View Details', style: TextStyle(color: tokens.textHigh)),
                                  ],
                                ),
                              ),
                              if (!account.isDefault && account.isAsset)
                                PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_outline_rounded, size: 16, color: tokens.ionCyan),
                                      const SizedBox(width: 8),
                                      Text('Set as Default', style: TextStyle(color: tokens.ionCyan)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Bottom Row: Balances & Live Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                balLabel,
                                style: HorizonTypography.labelCaps.copyWith(
                                  color: tokens.textMedium,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 2),
                              MoneyText(
                                decimalString: current,
                                currencyCode: account.currencyCode,
                                style: HorizonTypography.tabularAmountLg.copyWith(
                                  color: isCredit ? tokens.outflow : tokens.textHigh,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status,
                                    style: HorizonTypography.labelCaps.copyWith(
                                      color: accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subStatus,
                                style: HorizonTypography.bodySm.copyWith(
                                  color: tokens.textLow,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
