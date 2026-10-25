import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../core/utils/category_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/horizon/horizon.dart';
import 'add_transaction_sheet.dart';

export 'add_transaction_sheet.dart';

/// Formats transaction date into a friendly, localized human-readable label.
String formatFriendlyDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('d MMM').format(date);
    return DateFormat('d MMM yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().loadTransactions();
      if (context.read<AccountProvider>().accounts.isEmpty) {
        context.read<AccountProvider>().loadAccounts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadTransactions(loadMore: true);
    }
  }

  void _onSearchChanged(String query, TransactionProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.setSearchQuery(query.trim().isEmpty ? null : query.trim());
    });
  }

  void _showAddEditSheet([TransactionModel? transaction]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionSheet(transaction: transaction),
    );
  }

  Future<void> _selectDateRange() async {
    final provider = context.read<TransactionProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: provider.selectedDateRange,
    );
    if (range != null) {
      provider.setDateRange(range);
    }
  }

  void _showSortSheet(TransactionProvider provider) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Sort Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption(
                  label: "Newest First",
                  isSelected:
                      provider.sortBy == "transaction_date" &&
                      provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("transaction_date", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Oldest First",
                  isSelected:
                      provider.sortBy == "transaction_date" &&
                      provider.sortOrder == "asc",
                  onTap: () {
                    provider.setSort("transaction_date", "asc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Highest Amount",
                  isSelected:
                      provider.sortBy == "amount" &&
                      provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("amount", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Lowest Amount",
                  isSelected:
                      provider.sortBy == "amount" &&
                      provider.sortOrder == "asc",
                  onTap: () {
                    provider.setSort("amount", "asc");
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colors.primary : colors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterChips(TransactionProvider provider, bool isDark) {
    final colors = AppColors.of(context);
    final hasActiveCategory = provider.selectedCategoryId != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Filter
          _buildTypePill(
            label: "All",
            isSelected: provider.selectedType == null,
            onTap: () => provider.setType(null),
            colors: colors,
          ),
          const SizedBox(width: 8),

          // Expense Filter
          _buildTypePill(
            label: "Expense",
            isSelected: provider.selectedType == "expense",
            onTap: () => provider.setType("expense"),
            colors: colors,
            indicatorColor: colors.danger,
          ),
          const SizedBox(width: 8),

          // Income Filter
          _buildTypePill(
            label: "Income",
            isSelected: provider.selectedType == "income",
            onTap: () => provider.setType("income"),
            colors: colors,
            indicatorColor: colors.success,
          ),
          const SizedBox(width: 12),

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: hasActiveCategory
                  ? colors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                  : colors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: hasActiveCategory ? colors.primary : colors.cardBorder,
                width: 1.0,
              ),
            ),
            child: DropdownButton<int?>(
              value: provider.selectedCategoryId,
              isDense: true,
              hint: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: hasActiveCategory
                    ? colors.primary
                    : colors.textSecondary,
              ),
              dropdownColor: colors.surface,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    "All Categories",
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                ...CategoryModel.categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(c.name),
                          size: 16,
                          color: getCategoryColor(c.name),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) => provider.setCategoryId(val),
            ),
          ),

          if (hasActiveCategory) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => provider.setCategoryId(null),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
    Color? indicatorColor,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: HorizonDimensions.borderFull,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.quick,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surface,
            borderRadius: HorizonDimensions.borderFull,
            border: Border.all(
              color: isSelected ? colors.primary : colors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (indicatorColor != null && !isSelected) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    dynamic colors,
    ThemeData theme,
    bool isDark,
    TransactionProvider provider,
  ) {
    final isExpense = tx.type == "expense";

    // Open ledger-style row: hairline separated, no card outline.
    return HorizonTransactionRow(
      title: tx.title,
      amount: tx.amount,
      isExpense: isExpense,
      category: tx.category,
      accountName: tx.accountName,
      dateString: formatFriendlyDate(tx.transactionDate),
      categoryIcon: getCategoryIcon(tx.category),
      categoryColor: getCategoryColor(tx.category),
      note: tx.note,
      amountDisplay:
          '${isExpense ? '-' : '+'}'
          '${context.watch<CurrencyProvider>().format(tx.amount)}',
      onTap: () => _showAddEditSheet(tx),
      trailing: _buildRowMenu(tx, provider, colors),
    );
  }

  Widget _buildRowMenu(
    TransactionModel tx,
    TransactionProvider provider,
    dynamic colors,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: colors.textSecondary,
        size: 18,
      ),
      color: colors.surface,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.cardBorder),
      ),
      onSelected: (action) {
        if (action == 'edit') {
          _showAddEditSheet(tx);
        } else if (action == 'delete') {
          _confirmDelete(context, tx, provider);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: colors.danger,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(fontSize: 13, color: colors.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionModel tx,
    TransactionProvider provider,
  ) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Transaction",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete \"${tx.title}\"?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "CANCEL",
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteTransaction(tx.id);
              if (!mounted) return;
              if (success) {
                this.context.read<DashboardProvider>().loadDashboardData();
                this.context.read<ReportProvider>().loadAllReports();
                this.context.read<BudgetProvider>().loadBudgetStatus();
                CustomToast.showSuccess(
                  this.context,
                  "Transaction deleted successfully",
                );
              } else {
                CustomToast.showError(
                  this.context,
                  provider.errorMessage ?? "Failed to delete transaction",
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    final hasFilters =
        provider.selectedType != null ||
        provider.selectedCategoryId != null ||
        provider.searchQuery != null ||
        provider.selectedDateRange != null;

    final tokens = HorizonThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Transactions",
          style: HorizonTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textHigh,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'SMS Import',
            icon: const Icon(Icons.sms_outlined),
            onPressed: () => context.push('/sms-import'),
          ),
          IconButton(
            tooltip: "Sort",
            icon: Icon(
              Icons.sort_rounded,
              color:
                  provider.sortBy != "transaction_date" ||
                      provider.sortOrder != "desc"
                  ? colors.primary
                  : colors.textSecondary,
            ),
            onPressed: () => _showSortSheet(provider),
          ),
          IconButton(
            tooltip: "Date Range",
            icon: Icon(
              Icons.date_range_rounded,
              color: provider.selectedDateRange != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
            onPressed: _selectDateRange,
          ),
          if (hasFilters)
            IconButton(
              tooltip: "Clear Filters",
              icon: Icon(Icons.filter_alt_off_rounded, color: colors.danger),
              onPressed: () {
                _debounce?.cancel();
                _searchController.clear();
                provider.clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search field — quiet, underlined, one hairline of chrome.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              AppDimensions.sm,
              AppDimensions.md,
              AppDimensions.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _onSearchChanged(val, provider),
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: "Search merchant, note...",
                hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.textSecondary,
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 32,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          provider.setSearchQuery(null);
                        },
                      )
                    : null,
                isDense: true,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: 6.0,
            ),
            child: _buildFilterChips(provider, isDark),
          ),

          const Divider(height: 1),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTransactions(),
              child: provider.isLoading && provider.transactions.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: AppDimensions.md,
                      ),
                      children: List.generate(
                        6,
                        (index) => SkeletonLoader.listTile(),
                      ),
                    )
                  : provider.transactions.isEmpty
                  ? _buildEmptyState(provider)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        top: AppDimensions.sm,
                        bottom: AppDimensions.sm,
                      ),
                      itemCount:
                          provider.transactions.length +
                          (provider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final tx = provider.transactions[index];
                        return _buildTransactionCard(
                          context,
                          tx,
                          colors,
                          theme,
                          isDark,
                          provider,
                        );
                      },
                    ),
            ),
          ),
          // Reserve the Add control's area so no scrolling amount sits under it.
          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: tokens.ionCyan,
        foregroundColor: tokens.isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: HorizonDimensions.borderDefault,
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          "Add",
          style: HorizonTypography.labelCaps.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: tokens.isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TransactionProvider provider) {
    final hasFilters =
        provider.searchQuery != null ||
        provider.selectedCategoryId != null ||
        provider.selectedType != null ||
        provider.selectedDateRange != null;

    return HorizonEmptyState(
      icon: hasFilters
          ? Icons.filter_alt_off_rounded
          : Icons.receipt_long_rounded,
      title: hasFilters ? "No matching transactions" : "No transactions yet",
      description: hasFilters
          ? "Try loosening your filters or searching for something else."
          : "Tap the Add button below to record your first transaction.",
      actionLabel: hasFilters ? "Reset Filters" : "New Transaction",
      onAction: () {
        if (hasFilters) {
          _debounce?.cancel();
          _searchController.clear();
          provider.clearFilters();
        } else {
          _showAddEditSheet();
        }
      },
    );
  }
}
