import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/horizon/horizon.dart';
import '../../core/horizon/components/horizon_pressable.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/transactions_list_screen.dart';
import 'widgets/ledger_cash_flow_summary.dart';
import 'widgets/ledger_controls.dart';
import 'widgets/ledger_transaction_row.dart';

/// A date-grouped financial journal over the existing transaction provider.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});
  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  static const _maxContentWidth = 760.0;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionProvider>().clearFilters();
    });
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<TransactionProvider>();
    if (provider.hasMore &&
        !provider.isLoading &&
        !provider.isLoadingMore &&
        _scrollController.position.extentAfter <
            HorizonDimensions.dockClearance * 2) {
      provider.loadTransactions(loadMore: true);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<TransactionProvider>().setSearchQuery(
          query.trim().isEmpty ? null : query.trim(),
        );
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    context.read<TransactionProvider>().setSearchQuery(null);
  }

  void _resetFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    context.read<TransactionProvider>().clearFilters();
  }

  void _openAddEditSheet([TransactionModel? transaction]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTransactionSheet(transaction: transaction),
    ).then((_) {
      if (mounted) context.read<TransactionProvider>().loadTransactions();
    });
  }

  Future<void> _pickDateRange(TransactionProvider provider) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          provider.selectedDateRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) {
        final tokens = HorizonThemeTokens.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: tokens.primary,
              onPrimary: tokens.onPrimary,
              surface: tokens.surface2,
              onSurface: tokens.textHigh,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) provider.setDateRange(picked);
  }

  String _period(TransactionProvider provider) {
    final range = provider.selectedDateRange;
    if (range != null) {
      return '${DateFormat('d MMM yyyy').format(range.start)} – ${DateFormat('d MMM yyyy').format(range.end)}';
    }
    final dates = provider.transactions
        .map((tx) => DateTime.tryParse(tx.transactionDate))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return 'Your transactions';
    final months = dates
        .map((date) => DateFormat('MMMM yyyy').format(date))
        .toSet();
    return months.length == 1 ? months.first : 'Transaction history';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      // The shell reserves its dock; this footer reserves the add action.
      // Neither can cover an amount or the last transaction.
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: HorizonDimensions.spaceSM,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Align(
                    alignment: Alignment.centerRight,
                    heightFactor: 1,
                    child: LedgerAddTransactionAction(
                      onPressed: () => _openAddEditSheet(),
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < HorizonDimensions.breakpointTablet &&
                constraints.maxHeight < HorizonDimensions.breakpointTablet;
            final margin =
                constraints.maxWidth >= HorizonDimensions.breakpointTablet
                ? HorizonDimensions.marginTablet
                : HorizonDimensions.marginMobile;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Consumer<TransactionProvider>(
                  builder: (context, provider, _) {
                    final items = provider.transactions;
                    final filtered =
                        provider.selectedType != null ||
                        provider.selectedDateRange != null ||
                        provider.searchQuery != null;
                    final range = provider.selectedDateRange;
                    final grouped = <String, List<TransactionModel>>{};
                    for (final item in items) {
                      grouped
                          .putIfAbsent(item.transactionDate, () => [])
                          .add(item);
                    }
                    // Flatten date groups for lazy construction on paginated lists.
                    final entries = <Object>[];
                    for (final group in grouped.entries) {
                      entries.add(group);
                      entries.addAll(group.value);
                    }
                    return RefreshIndicator(
                      color: tokens.primary,
                      backgroundColor: tokens.surface2,
                      onRefresh: () => provider.loadTransactions(),
                      child: CustomScrollView(
                        key: const ValueKey('ledger-scroll'),
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              margin,
                              HorizonDimensions.spaceSM,
                              margin,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LedgerHeader(
                                    compact: compact,
                                    period: _period(provider),
                                    count:
                                        (provider.isLoading ||
                                                provider.errorMessage !=
                                                    null) &&
                                            items.isEmpty
                                        ? null
                                        : provider.totalTransactions > 0
                                        ? provider.totalTransactions
                                        : items.length,
                                    onManage: () =>
                                        context.push('/transactions'),
                                    onImport: () => context.push('/sms-import'),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? HorizonDimensions.spaceMD
                                        : HorizonDimensions.spaceLG,
                                  ),
                                  LedgerSearchField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    onClear: _clearSearch,
                                  ),
                                  const SizedBox(
                                    height: HorizonDimensions.spaceSM,
                                  ),
                                  LedgerFilterRail(
                                    selectedType: provider.selectedType,
                                    dateLabel: range == null
                                        ? null
                                        : '${DateFormat('d MMM').format(range.start)} – ${DateFormat('d MMM').format(range.end)}',
                                    hasFilters: filtered,
                                    onTypeChanged: (type) {
                                      if (type == null) {
                                        _resetFilters();
                                      } else {
                                        provider.setType(
                                          provider.selectedType == type
                                              ? null
                                              : type,
                                        );
                                      }
                                    },
                                    onDate: () => _pickDateRange(provider),
                                    onReset: _resetFilters,
                                  ),
                                  if (items.isNotEmpty)
                                    LedgerCashFlowSummary(
                                      transactions: items,
                                      compact: compact,
                                    ),
                                  if (provider.isLoading && items.isNotEmpty)
                                    LinearProgressIndicator(
                                      color: tokens.primary,
                                      backgroundColor: tokens.divider,
                                      minHeight: HorizonDimensions.spaceXS,
                                    ),
                                  if (provider.errorMessage != null &&
                                      items.isNotEmpty)
                                    _LedgerMessage(
                                      compact: true,
                                      title: 'Couldn’t refresh transactions',
                                      description:
                                          'Showing the records already loaded.',
                                      action: 'Try again',
                                      onAction: () =>
                                          provider.loadTransactions(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (provider.isLoading && items.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(margin),
                                child: const _LedgerLoading(),
                              ),
                            )
                          else if (provider.errorMessage != null &&
                              items.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(margin),
                                child: _LedgerMessage(
                                  title: 'Ledger unavailable',
                                  description:
                                      'Your transactions couldn’t be loaded. Please try again.',
                                  action: 'Try again',
                                  onAction: () => provider.loadTransactions(),
                                ),
                              ),
                            )
                          else if (items.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(margin),
                                child: _LedgerMessage(
                                  title: filtered
                                      ? 'No matching transactions'
                                      : 'Your ledger starts here',
                                  description: filtered
                                      ? 'Try a different search or clear your filters.'
                                      : 'Add your first transaction to start your financial journal.',
                                  action: filtered
                                      ? 'Clear filters'
                                      : 'Add transaction',
                                  onAction: filtered
                                      ? _resetFilters
                                      : () => _openAddEditSheet(),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: margin),
                              sliver: SliverList.builder(
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  if (entry is TransactionModel) {
                                    return LedgerTransactionRow(
                                      key: ValueKey(entry.id),
                                      transaction: entry,
                                      onPressed: () => _openAddEditSheet(entry),
                                    );
                                  }
                                  final group =
                                      entry
                                          as MapEntry<
                                            String,
                                            List<TransactionModel>
                                          >;
                                  final net = group.value.fold(
                                    0.0,
                                    (sum, tx) =>
                                        sum +
                                        (ledgerIsInflow(tx)
                                            ? tx.amount
                                            : -tx.amount),
                                  );
                                  return LedgerDateHeader(
                                    date: group.key,
                                    net: net,
                                  );
                                },
                              ),
                            ),
                          if (provider.isLoadingMore)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  HorizonDimensions.spaceLG,
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: HorizonDimensions.spaceLG,
                                      height: HorizonDimensions.spaceLG,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: tokens.primary,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: HorizonDimensions.spaceSM,
                                    ),
                                    Text(
                                      'Loading more transactions',
                                      style: HorizonTypography.bodySm.copyWith(
                                        color: tokens.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: HorizonDimensions.spaceLG),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LedgerLoading extends StatelessWidget {
  const _LedgerLoading();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading transactions',
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: HorizonDimensions.spaceLG),
          child: HorizonSkeleton(
            width: double.infinity,
            height: HorizonDimensions.buttonHeight,
          ),
        ),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: HorizonDimensions.spaceMD),
            child: Row(
              children: [
                HorizonSkeleton(
                  width: HorizonDimensions.spaceXL,
                  height: HorizonDimensions.spaceXL,
                ),
                SizedBox(width: HorizonDimensions.spaceMD),
                Expanded(
                  child: HorizonSkeleton(
                    width: double.infinity,
                    height: HorizonDimensions.spaceLG,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _LedgerMessage extends StatelessWidget {
  const _LedgerMessage({
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
    this.compact = false,
  });
  final String title;
  final String description;
  final String action;
  final VoidCallback onAction;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? HorizonDimensions.spaceSM
            : HorizonDimensions.spaceXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                (compact
                        ? HorizonTypography.bodyMd
                        : HorizonTypography.headlineSm)
                    .copyWith(color: tokens.textHigh),
          ),
          const SizedBox(height: HorizonDimensions.spaceSM),
          Text(
            description,
            style:
                (compact ? HorizonTypography.bodySm : HorizonTypography.bodyMd)
                    .copyWith(color: tokens.textMedium),
          ),
          const SizedBox(height: HorizonDimensions.spaceMD),
          HorizonPressable(
            label: action,
            onPressed: onAction,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                action,
                style: HorizonTypography.bodyMd.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
