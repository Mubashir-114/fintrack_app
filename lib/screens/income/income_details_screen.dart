import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/fin_surface.dart';
import '../../models/transaction_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../accounts/widgets/money_text.dart';
import '../dashboard/widgets/premium_dashboard_cards.dart';

/// Explains credited money by source while keeping the dashboard lightweight.
class IncomeDetailsScreen extends StatefulWidget {
  const IncomeDetailsScreen({super.key});

  @override
  State<IncomeDetailsScreen> createState() => _IncomeDetailsScreenState();
}

class _IncomeDetailsScreenState extends State<IncomeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboard = context.read<DashboardProvider>();
      final transactions = context.read<TransactionProvider>();
      if (dashboard.summary == null) dashboard.loadDashboardData();
      transactions.setType('income');
    });
  }

  String _sourceFor(TransactionModel item) {
    if (item.category.trim().isNotEmpty) return item.category;
    if (item.bank?.trim().isNotEmpty == true) return item.bank!;
    if (item.sender?.trim().isNotEmpty == true) return item.sender!;
    return item.title;
  }

  String _dateLabel(String value) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  Widget _sourceCard(BuildContext context, String source, double amount, int count) {
    final colors = AppColors.of(context);
    return FinSurface(
      emphasized: true,
      accent: colors.success,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.south_west_rounded, color: colors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('$count credited ${count == 1 ? 'entry' : 'entries'}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
          MoneyText(decimalString: amount.toStringAsFixed(2), style: TextStyle(color: colors.success, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _timelineEntry(BuildContext context, TransactionModel item) {
    final colors = AppColors.of(context);
    final sms = item.source.toLowerCase().contains('sms');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.arrow_downward_rounded, color: colors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${_sourceFor(item)} • ${_dateLabel(item.transactionDate)}${sms ? ' • SMS detected' : ''}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(decimalString: item.amount.toStringAsFixed(2), showSign: true, style: TextStyle(color: colors.success, fontSize: 13, fontWeight: FontWeight.w800)),
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
        title: const Text('Income details'),
        actions: [
          TextButton(onPressed: () => context.push('/ledger'), child: const Text('Ledger')),
        ],
      ),
      body: Consumer2<DashboardProvider, TransactionProvider>(
        builder: (context, dashboard, transactions, _) {
          final overview = dashboard.overview;
          final bySource = <String, List<TransactionModel>>{};
          for (final item in transactions.transactions) {
            bySource.putIfAbsent(_sourceFor(item), () => []).add(item);
          }
          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              await Future.wait([
                dashboard.loadDashboardData(),
                transactions.loadTransactions(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                FinSurface(
                  emphasized: true,
                  accent: colors.success,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Credited this month', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      const SizedBox(height: 8),
                      MoneyText(decimalString: overview?.monthlyIncome ?? '0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: colors.textPrimary)),
                      const SizedBox(height: 7),
                      Text('This is income received during the selected period, not stored wealth.', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const PremiumSectionHeader(title: 'Where it came from', subtitle: 'Source-wise totals from credited entries'),
                const SizedBox(height: 10),
                if (transactions.isLoading && transactions.transactions.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (bySource.isEmpty)
                  PremiumEmptyStateCard(icon: Icons.south_west_rounded, title: 'No income entries yet', message: 'Credited salary and other income will be grouped here.', accent: colors.success)
                else
                  for (final entry in bySource.entries) ...[
                    _sourceCard(context, entry.key, entry.value.fold<double>(0, (sum, item) => sum + item.amount), entry.value.length),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 16),
                const PremiumSectionHeader(title: 'Credited timeline', subtitle: 'Recent deposits and detected income'),
                const SizedBox(height: 6),
                FinSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < transactions.transactions.length; i++) ...[
                        _timelineEntry(context, transactions.transactions[i]),
                        if (i != transactions.transactions.length - 1) Divider(height: 1, color: colors.divider),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
