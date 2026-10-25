import 'package:flutter/material.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/providers/transaction_provider.dart';

// Isolated preview/test data. Never persisted or used by the production app.
final ledgerRecords = <TransactionModel>[
  const TransactionModel(
    id: 1,
    userId: 1,
    categoryId: 1,
    type: 'expense',
    title: 'Taxi',
    amount: 1200,
    transactionDate: '2026-10-24',
    category: 'Transport',
    accountName: 'Room Rental',
    source: 'sms',
  ),
  const TransactionModel(
    id: 2,
    userId: 1,
    categoryId: 2,
    type: 'income',
    title: 'Salary',
    amount: 210000,
    transactionDate: '2026-10-24',
    category: 'Salary',
    accountName: 'Everyday Savings',
    source: 'manual',
  ),
  const TransactionModel(
    id: 3,
    userId: 1,
    categoryId: 3,
    type: 'expense',
    title: 'Blue Tokai Coffee',
    amount: 280,
    transactionDate: '2026-10-23',
    category: 'Food & Dining',
    accountName: 'Everyday Savings',
    source: 'manual',
  ),
  const TransactionModel(
    id: 4,
    userId: 1,
    categoryId: 4,
    type: 'income',
    title: 'Studio retainer',
    amount: 85000,
    transactionDate: '2026-10-22',
    category: 'Freelance',
    accountName: 'Business Current',
    source: 'manual',
  ),
  const TransactionModel(
    id: 5,
    userId: 1,
    categoryId: 5,
    type: 'expense',
    title: 'Weekly groceries',
    amount: 700,
    transactionDate: '2026-10-22',
    category: 'Groceries',
    accountName: 'Everyday Savings',
    source: 'manual',
  ),
];

class LedgerFixtureProvider extends TransactionProvider {
  LedgerFixtureProvider({
    List<TransactionModel>? records,
    this.loading = false,
    this.loadingMore = false,
    this.failure,
    this.more = false,
  }) : records = records ?? ledgerRecords;
  final List<TransactionModel> records;
  bool loading;
  bool loadingMore;
  String? failure;
  bool more;
  int refreshes = 0;
  int pageRequests = 0;
  String? type;
  String? query;
  DateTimeRange? range;
  @override
  List<TransactionModel> get transactions => records.where((tx) {
    final date = DateTime.parse(tx.transactionDate);
    return (type == null || tx.type == type) &&
        (query == null ||
            '${tx.title} ${tx.category} ${tx.accountName}'
                .toLowerCase()
                .contains(query!.toLowerCase())) &&
        (range == null ||
            (!date.isBefore(range!.start) && !date.isAfter(range!.end)));
  }).toList();
  @override
  int get totalTransactions => transactions.length;
  @override
  bool get isLoading => loading;
  @override
  bool get isLoadingMore => loadingMore;
  @override
  bool get hasMore => more;
  @override
  String? get errorMessage => failure;
  @override
  String? get selectedType => type;
  @override
  String? get searchQuery => query;
  @override
  DateTimeRange? get selectedDateRange => range;
  @override
  void setType(String? value) {
    type = value;
    notifyListeners();
  }

  @override
  void setSearchQuery(String? value) {
    query = value;
    notifyListeners();
  }

  @override
  void setDateRange(DateTimeRange? value) {
    range = value;
    notifyListeners();
  }

  @override
  void clearFilters() {
    type = null;
    query = null;
    range = null;
    notifyListeners();
  }

  @override
  Future<void> loadTransactions({bool loadMore = false}) async {
    if (loadMore) {
      pageRequests++;
    } else {
      refreshes++;
    }
  }
}
