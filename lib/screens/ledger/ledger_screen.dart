import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/utils/category_utils.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../transactions/transactions_list_screen.dart';

/// FinTrack // HORIZON — Financial Workspace Ledger Screen.
///
/// Implements the approved Stitch Records Deck workspace:
/// - Screen Header & Workspace Context (telemetry eyebrow, month, entries count)
/// - Search & Telemetry Scanner Input (debounced keyword search)
/// - Horizontal Filter Array (All Records, Inflows, Outflows, Date Range)
/// - Cash Flow Velocity Band (Dual Bento Pod with Inflow/Outflow pillars & net liquidity)
/// - Date-Grouped Transaction Deck with HorizonTransactionRow cards
/// - Quick-Add Transaction Action (FAB opens AddEditTransactionSheet)
/// - Seamless infinite scrolling pagination and pull-to-refresh
/// - Horizon empty, skeleton loading, and error states
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

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

  void _onSearchChanged(String query, TransactionProvider provider) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      provider.setSearchQuery(query.trim().isEmpty ? null : query.trim());
    });
  }

  void _openAddEditSheet([TransactionModel? transaction]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionSheet(transaction: transaction),
    ).then((_) {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  Future<void> _pickDateRange(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: provider.selectedDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        final tokens = HorizonThemeTokens.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: tokens.ionCyan,
                  onPrimary: tokens.isDark ? Colors.black : Colors.white,
                  surface: tokens.surface2,
                  onSurface: tokens.textHigh,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked);
    }
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

  String _formatDateGroupHeader(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final txDate = DateTime(date.year, date.month, date.day);

      if (txDate == today) {
        return "Today, ${DateFormat('d MMM').format(date)}";
      } else if (txDate == today.subtract(const Duration(days: 1))) {
        return "Yesterday, ${DateFormat('d MMM').format(date)}";
      } else {
        return DateFormat('EEEE, d MMM').format(date);
      }
    } catch (_) {
      return rawDate;
    }
  }

  bool _isInflow(TransactionModel tx) =>
      tx.type == 'income' || tx.type == 'transfer_in';

  // ---------------------------------------------------------------------------
  // 1. Header & Workspace Context
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    TransactionProvider provider,
    HorizonThemeTokens tokens,
  ) {
    final now = DateTime.now();
    final monthStr = DateFormat('MMM yyyy').format(now).toUpperCase();
    final totalEntries = provider.totalTransactions > 0
        ? provider.totalTransactions
        : provider.transactions.length;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eyebrow and month
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                "LEDGER // TELEMETRY",
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.ionCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.08 * 10,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.ionCyan,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                monthStr,
                style: HorizonTypography.labelCaps.copyWith(
                  color: tokens.textLow,
                  fontSize: 10,
                  letterSpacing: 0.05 * 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Main Title & Entries Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Records Deck",
                    style: HorizonTypography.headlineMd.copyWith(
                      color: tokens.textHigh,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.015 * 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: HorizonDimensions.borderFull,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: tokens.ionCyan,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "$totalEntries ENTRIES",
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.textHigh,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.08 * 9,
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
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Search & Telemetry Scanner
  // ---------------------------------------------------------------------------
  Widget _buildSearchInput(
    BuildContext context,
    TransactionProvider provider,
    HorizonThemeTokens tokens,
  ) {
    return HorizonTextField(
      controller: _searchController,
      hintText: "Search merchant, UPI, note, tag...",
      prefixIcon: Icons.search_rounded,
      onChanged: (val) => _onSearchChanged(val, provider),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Horizontal Filter Array
  // ---------------------------------------------------------------------------
  Widget _buildFilterArray(
    BuildContext context,
    TransactionProvider provider,
    List<TransactionModel> items,
    HorizonThemeTokens tokens,
  ) {
    final selectedType = provider.selectedType;
    final dateRange = provider.selectedDateRange;

    final incomeCount = items.where((it) => _isInflow(it)).length;
    final expenseCount = items.where((it) => !_isInflow(it)).length;

    String dateLabel = "Date Range";
    if (dateRange != null) {
      dateLabel =
          "${DateFormat('d MMM').format(dateRange.start)} - ${DateFormat('d MMM').format(dateRange.end)}";
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          HorizonChip(
            label: "All Records",
            selected: selectedType == null && dateRange == null,
            onSelected: (_) {
              provider.clearFilters();
              _searchController.clear();
            },
          ),
          const SizedBox(width: 8),
          HorizonChip(
            label: "Inflows",
            selected: selectedType == 'income',
            count: incomeCount > 0 ? incomeCount : null,
            onSelected: (sel) => provider.setType(sel ? 'income' : null),
          ),
          const SizedBox(width: 8),
          HorizonChip(
            label: "Outflows",
            selected: selectedType == 'expense',
            count: expenseCount > 0 ? expenseCount : null,
            onSelected: (sel) => provider.setType(sel ? 'expense' : null),
          ),
          const SizedBox(width: 8),
          HorizonChip(
            label: dateLabel,
            selected: dateRange != null,
            icon: Icons.calendar_today_rounded,
            onSelected: (_) => _pickDateRange(context, provider),
          ),
          if (selectedType != null || dateRange != null || provider.searchQuery != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                provider.clearFilters();
                _searchController.clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.surface1,
                  borderRadius: HorizonDimensions.borderDefault,
                  border: Border.all(color: tokens.rimNeutral),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: tokens.textLow),
                    const SizedBox(width: 4),
                    Text(
                      "Reset",
                      style: HorizonTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: tokens.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Cash Flow Velocity Band (Dual Bento Pod)
  // ---------------------------------------------------------------------------
  Widget _buildVelocityBand(
    BuildContext context,
    List<TransactionModel> items,
    HorizonThemeTokens tokens,
  ) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now).toUpperCase();

    final incomeItems = items.where((item) => _isInflow(item)).toList();
    final expenseItems = items.where((item) => !_isInflow(item)).toList();

    final double totalInflows =
        incomeItems.fold(0.0, (sum, it) => sum + it.amount);
    final double totalOutflows =
        expenseItems.fold(0.0, (sum, it) => sum + it.amount);
    final double netLiquidity = totalInflows - totalOutflows;
    final bool isNetPositive = netLiquidity >= 0;

    final double maxVal = totalInflows > totalOutflows ? totalInflows : totalOutflows;
    final double inflowPct = maxVal > 0 ? (totalInflows / maxVal) : 0.0;
    final double outflowPct = maxVal > 0 ? (totalOutflows / maxVal) : 0.0;

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      cornerAccentColor: tokens.ionCyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Velocity Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: tokens.ionCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$monthName CASH FLOW VELOCITY",
                      style: HorizonTypography.labelCaps.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tokens.textMedium,
                        letterSpacing: 0.08 * 10,
                      ),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isNetPositive ? tokens.surplus : tokens.outflow)
                        .withValues(alpha: 0.12),
                    borderRadius: HorizonDimensions.borderFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isNetPositive ? tokens.surplus : tokens.outflow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isNetPositive ? "STABLE FLOW" : "NET OUTFLOW",
                        style: HorizonTypography.labelCaps.copyWith(
                          fontSize: 9,
                          color: isNetPositive ? tokens.surplus : tokens.outflow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dual Bento Pods (Inflow & Outflow Pillars)
          Row(
            children: [
              // Inflow Pod
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surface1,
                    borderRadius: HorizonDimensions.borderDefault,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          Text(
                            "INFLOWS",
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 9,
                              color: tokens.textMedium,
                            ),
                          ),
                          Text(
                            "${incomeItems.length} CREDITS",
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 9,
                              color: tokens.textLow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+${HorizonFormatters.formatInr(totalInflows, showSign: false)}',
                          style: HorizonTypography.tabularAmountMd.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: tokens.surplus,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress Spark
                      ClipRRect(
                        borderRadius: HorizonDimensions.borderFull,
                        child: LinearProgressIndicator(
                          value: inflowPct.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: tokens.surface2,
                          valueColor: AlwaysStoppedAnimation<Color>(tokens.surplus),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Outflow Pod
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surface1,
                    borderRadius: HorizonDimensions.borderDefault,
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          Text(
                            "OUTFLOWS",
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 9,
                              color: tokens.textMedium,
                            ),
                          ),
                          Text(
                            "${expenseItems.length} DEBITS",
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 9,
                              color: tokens.textLow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '-${HorizonFormatters.formatInr(totalOutflows, showSign: false)}',
                          style: HorizonTypography.tabularAmountMd.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: tokens.outflow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress Spark
                      ClipRRect(
                        borderRadius: HorizonDimensions.borderFull,
                        child: LinearProgressIndicator(
                          value: outflowPct.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: tokens.surface2,
                          valueColor: AlwaysStoppedAnimation<Color>(tokens.outflow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Net Free Liquidity Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tokens.surface1.withValues(alpha: 0.6),
              borderRadius: HorizonDimensions.borderDefault,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  "Net Free Liquidity Generated",
                  style: HorizonTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: tokens.textMedium,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Net: ",
                        style: HorizonTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: tokens.textLow,
                        ),
                      ),
                      Text(
                        '${isNetPositive ? '+' : '-'}${HorizonFormatters.formatInr(netLiquidity.abs(), showSign: false)}',
                        style: HorizonTypography.tabularAmountSm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isNetPositive ? tokens.surplus : tokens.outflow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Date-Grouped Transaction Deck
  // ---------------------------------------------------------------------------
  Widget _buildDateGroup(
    BuildContext context,
    String dateKey,
    List<TransactionModel> txGroup,
    HorizonThemeTokens tokens,
  ) {
    final double dayNet = txGroup.fold(0.0, (sum, tx) {
      return _isInflow(tx) ? (sum + tx.amount) : (sum - tx.amount);
    });
    final bool isDayPositive = dayNet >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header: Date Eyebrow & Net Day Sum
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: tokens.ionCyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tokens.ionCyan.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateGroupHeader(dateKey),
                        style: HorizonTypography.labelCaps.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.textHigh,
                          letterSpacing: 0.06 * 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${isDayPositive ? '+' : '-'}${HorizonFormatters.formatInr(dayNet.abs(), showSign: false)}',
                    style: HorizonTypography.tabularAmountSm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDayPositive ? tokens.surplus : tokens.outflow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Transaction Surface Deck
          HorizonSurface(
            tier: HorizonSurfaceTier.surface2,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < txGroup.length; i++) ...[
                  HorizonTransactionRow(
                    title: txGroup[i].title,
                    amount: txGroup[i].amount,
                    isExpense: !_isInflow(txGroup[i]),
                    category: txGroup[i].category,
                    accountName: txGroup[i].accountName,
                    dateString: txGroup[i].source.toLowerCase().contains('sms')
                        ? 'SMS'
                        : null,
                    categoryIcon: getCategoryIcon(txGroup[i].category),
                    categoryColor: getCategoryColor(txGroup[i].category),
                    showDivider: i != txGroup.length - 1,
                    onTap: () => _openAddEditSheet(txGroup[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Build Method
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Ledger",
          style: HorizonTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textHigh,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Manage all transactions",
            icon: Icon(
              Icons.tune_rounded,
              size: 20,
              color: tokens.textMedium,
            ),
            onPressed: () => context.push('/transactions'),
          ),
          IconButton(
            tooltip: "SMS Transactions",
            icon: Icon(
              Icons.sms_outlined,
              size: 20,
              color: tokens.textMedium,
            ),
            onPressed: () => context.push('/sms-import'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditSheet(),
        backgroundColor: tokens.ionCyan,
        foregroundColor: tokens.isDark ? Colors.black : Colors.white,
        tooltip: "Record Transaction",
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: HorizonDimensions.borderDefault,
        ),
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final items = provider.transactions;
          final grouped = <String, List<TransactionModel>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.transactionDate, () => []).add(item);
          }

          return RefreshIndicator(
            color: tokens.ionCyan,
            backgroundColor: tokens.surface2,
            onRefresh: () => provider.loadTransactions(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: HorizonDimensions.marginMobile,
                vertical: 8,
              ),
              children: [
                // 1. Header & Financial Context
                _buildHeader(context, provider, tokens),
                const SizedBox(height: 12),

                // 2. Search Scanner
                _buildSearchInput(context, provider, tokens),
                const SizedBox(height: 12),

                // 3. Horizontal Filter Array
                _buildFilterArray(context, provider, items, tokens),
                const SizedBox(height: 14),

                // 4. Cash Flow Velocity Band (Dual Bento Pod)
                if (items.isNotEmpty) ...[
                  _buildVelocityBand(context, items, tokens),
                  const SizedBox(height: 18),
                ],

                // 5. Loading, Error, Empty, or Populated Deck
                if (provider.isLoading && items.isEmpty) ...[
                  const HorizonSkeletonTelemetryCard(),
                  const SizedBox(height: 14),
                  const HorizonSkeleton(width: double.infinity, height: 72),
                  const SizedBox(height: 10),
                  const HorizonSkeleton(width: double.infinity, height: 72),
                  const SizedBox(height: 10),
                  const HorizonSkeleton(width: double.infinity, height: 72),
                ] else if (provider.errorMessage != null && items.isEmpty) ...[
                  HorizonErrorCard(
                    title: "Ledger Unavailable",
                    errorMessage: provider.errorMessage!,
                    onRetry: () => provider.loadTransactions(),
                  ),
                ] else if (items.isEmpty) ...[
                  HorizonEmptyState(
                    title: "No ledger entries yet",
                    description:
                        "Income, expenses and detected transactions will appear here.",
                    icon: Icons.receipt_long_rounded,
                    actionLabel: "Record Transaction",
                    onAction: () => _openAddEditSheet(),
                  ),
                ] else ...[
                  for (final entry in grouped.entries)
                    _buildDateGroup(context, entry.key, entry.value, tokens),
                ],

                // Pagination spinner
                if (provider.isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.ionCyan,
                        ),
                      ),
                    ),
                  ),

                // Safe dock clearance
                const SizedBox(height: HorizonDimensions.dockClearance),
              ],
            ),
          );
        },
      ),
    );
  }
}
