import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/category_utils.dart';
import '../../core/widgets/fin_surface.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../accounts/widgets/money_text.dart';
import '../dashboard/widgets/premium_dashboard_cards.dart';

/// A focused view of money movement. The dashboard keeps only a preview;
/// this page is the place for the complete, auditable transaction flow.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().clearFilters();
    });
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      context.read<TransactionProvider>().loadTransactions(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  String _dateLabel(String value) {
    try {
      return DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  bool _isInflow(TransactionModel transaction) =>
      transaction.type == 'income' || transaction.type == 'transfer_in';

  String _typeLabel(TransactionModel transaction) {
    switch (transaction.type) {
      case 'income':
        return 'Income';
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return 'Transfer';
      default:
        return 'Expense';
    }
  }

  Color _typeColor(BuildContext context, TransactionModel transaction) {
    final colors = AppColors.of(context);
    if (transaction.type.startsWith('transfer')) return colors.transfer;
    return _isInflow(transaction) ? colors.success : colors.danger;
  }

  Widget _summaryStrip(BuildContext context, List<TransactionModel> items) {
    final colors = AppColors.of(context);
    final income = items
        .where((item) => _isInflow(item))
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenses = items
        .where((item) => !_isInflow(item) && !item.type.startsWith('transfer'))
        .fold<double>(0, (sum, item) => sum + item.amount);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _LedgerMetric(
          label: 'Inflows',
          amount: income.toStringAsFixed(2),
          color: colors.success,
        ),
        _LedgerMetric(
          label: 'Outflows',
          amount: expenses.toStringAsFixed(2),
          color: colors.danger,
        ),
        _LedgerMetric(
          label: 'Entries',
          amount: items.length.toString(),
          color: colors.primary,
          isCount: true,
        ),
      ],
    );
  }

  Widget _entry(BuildContext context, TransactionModel transaction) {
    final colors = AppColors.of(context);
    final accent = _typeColor(context, transaction);
    final isSms = transaction.source.toLowerCase().contains('sms');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: .12),
            child: Icon(
              transaction.type.startsWith('transfer')
                  ? Icons.swap_horiz_rounded
                  : getCategoryIcon(transaction.category),
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_typeLabel(transaction)}${transaction.category.isEmpty ? '' : ' • ${transaction.category}'}',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _LedgerBadge(
                      label: isSms ? 'SMS detected' : 'Manual entry',
                      color: isSms ? colors.info : colors.textSecondary,
                    ),
                    if (transaction.accountName != null)
                      _LedgerBadge(
                        label: transaction.accountName!,
                        color: colors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(
            decimalString: _isInflow(transaction)
                ? transaction.amount.toStringAsFixed(2)
                : '-${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            showSign: _isInflow(transaction),
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
        title: const Text('Ledger'),
        actions: [
          IconButton(
            tooltip: 'Manage transactions',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/transactions'),
          ),
          IconButton(
            tooltip: 'Import SMS transactions',
            icon: const Icon(Icons.sms_outlined),
            onPressed: () => context.push('/sms-import'),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final items = provider.transactions;
          final grouped = <String, List<TransactionModel>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.transactionDate, () => []).add(item);
          }

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () => provider.loadTransactions(),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const PremiumSectionHeader(
                  title: 'Money movement',
                  subtitle: 'Follow what came in, what went out, and why',
                ),
                const SizedBox(height: 12),
                _summaryStrip(context, items),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LedgerFilter(
                        label: 'All entries',
                        selected: provider.selectedType == null,
                        onTap: () => provider.setType(null),
                      ),
                      _LedgerFilter(
                        label: 'Income',
                        selected: provider.selectedType == 'income',
                        color: colors.success,
                        onTap: () => provider.setType('income'),
                      ),
                      _LedgerFilter(
                        label: 'Expenses',
                        selected: provider.selectedType == 'expense',
                        color: colors.danger,
                        onTap: () => provider.setType('expense'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (provider.isLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null && items.isEmpty)
                  PremiumEmptyStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Ledger unavailable',
                    message: provider.errorMessage!,
                    actionLabel: 'Try again',
                    onAction: provider.loadTransactions,
                    accent: colors.danger,
                  )
                else if (items.isEmpty)
                  PremiumEmptyStateCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'No ledger entries yet',
                    message: 'Income, expenses and detected transactions will appear here.',
                    accent: colors.info,
                  )
                else
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _dateLabel(entry.key),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                    FinSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < entry.value.length; i++) ...[
                            _entry(context, entry.value[i]),
                            if (i != entry.value.length - 1)
                              Divider(height: 1, indent: 72, color: colors.divider),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                if (provider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LedgerMetric extends StatelessWidget {
  const _LedgerMetric({required this.label, required this.amount, required this.color, this.isCount = false});

  final String label;
  final String amount;
  final Color color;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    return FinSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      accent: color,
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.of(context).textSecondary)),
          const SizedBox(height: 4),
          isCount
              ? Text(amount, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color))
              : MoneyText(decimalString: amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _LedgerBadge extends StatelessWidget {
  const _LedgerBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

class _LedgerFilter extends StatelessWidget {
  const _LedgerFilter({required this.label, required this.selected, required this.onTap, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tint = color ?? colors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: tint.withValues(alpha: .16),
        labelStyle: TextStyle(color: selected ? tint : colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
