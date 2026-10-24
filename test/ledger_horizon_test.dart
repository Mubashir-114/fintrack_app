import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/ledger/ledger_screen.dart';

class MockTransactionProvider extends TransactionProvider {
  List<TransactionModel> _mockTransactions = [];
  bool _mockLoading = false;
  bool _mockLoadingMore = false;
  String? _mockError;
  String? _mockType;
  DateTimeRange? _mockDateRange;
  String? _mockSearch;

  void setMockData({
    List<TransactionModel>? transactions,
    bool isLoading = false,
    bool isLoadingMore = false,
    String? error,
  }) {
    _mockTransactions = transactions ?? [];
    _mockLoading = isLoading;
    _mockLoadingMore = isLoadingMore;
    _mockError = error;
    notifyListeners();
  }

  @override
  List<TransactionModel> get transactions => _mockTransactions;

  @override
  int get totalTransactions => _mockTransactions.length;

  @override
  bool get isLoading => _mockLoading;

  @override
  bool get isLoadingMore => _mockLoadingMore;

  @override
  String? get errorMessage => _mockError;

  @override
  String? get selectedType => _mockType;

  @override
  DateTimeRange? get selectedDateRange => _mockDateRange;

  @override
  String? get searchQuery => _mockSearch;

  @override
  void setType(String? type) {
    _mockType = type;
    notifyListeners();
  }

  @override
  void setDateRange(DateTimeRange? range) {
    _mockDateRange = range;
    notifyListeners();
  }

  @override
  void setSearchQuery(String? query) {
    _mockSearch = query;
    notifyListeners();
  }

  @override
  void clearFilters() {
    _mockType = null;
    _mockDateRange = null;
    _mockSearch = null;
    notifyListeners();
  }

  @override
  Future<void> loadTransactions({bool loadMore = false}) async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  final testTransactions = [
    const TransactionModel(
      id: 1,
      userId: 1,
      categoryId: 1,
      category: 'Income',
      type: 'income',
      title: 'VentureStudio Retainer',
      amount: 125000.0,
      transactionDate: '2026-10-24',
      source: 'manual',
      accountName: 'Main Vault',
    ),
    const TransactionModel(
      id: 2,
      userId: 1,
      categoryId: 2,
      category: 'Electronics',
      type: 'expense',
      title: 'Apple Developer Program',
      amount: 8900.0,
      transactionDate: '2026-10-24',
      source: 'sms',
      accountName: 'Credit Card',
    ),
    const TransactionModel(
      id: 3,
      userId: 1,
      categoryId: 3,
      category: 'Dining',
      type: 'expense',
      title: 'Blue Tokai Coffee',
      amount: 420.0,
      transactionDate: '2026-10-23',
      source: 'manual',
      accountName: 'UPI',
    ),
  ];

  group('FinTrack // HORIZON — Ledger Screen Functionality', () {
    testWidgets('renders Records Deck header, telemetry eyebrow, and entries count', (tester) async {
      final mockProvider = MockTransactionProvider();
      mockProvider.setMockData(transactions: testTransactions);

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: mockProvider,
            child: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEDGER // TELEMETRY'), findsOneWidget);
      expect(find.text('Records Deck'), findsOneWidget);
      expect(find.text('3 ENTRIES'), findsOneWidget);
    });

    testWidgets('renders Cash Flow Velocity Band and Dual Bento Pods', (tester) async {
      final mockProvider = MockTransactionProvider();
      mockProvider.setMockData(transactions: testTransactions);

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: mockProvider,
            child: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('CASH FLOW VELOCITY'), findsOneWidget);
      expect(find.text('INFLOWS'), findsOneWidget);
      expect(find.text('1 CREDITS'), findsOneWidget);
      expect(find.text('+₹1,25,000.00'), findsNWidgets(2)); // Velocity + Transaction row

      expect(find.text('OUTFLOWS'), findsOneWidget);
      expect(find.text('2 DEBITS'), findsOneWidget);
      expect(find.text('-₹9,320.00'), findsOneWidget); // Outflow pod
      expect(find.text('+₹1,16,100.00'), findsOneWidget); // Day sum for 2026-10-24

      expect(find.text('Net Free Liquidity Generated'), findsOneWidget);
      expect(find.text('+₹1,15,680.00'), findsOneWidget);
    });

    testWidgets('renders Date-Grouped Transaction rows with Horizon styling', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockProvider = MockTransactionProvider();
      mockProvider.setMockData(transactions: testTransactions);

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: mockProvider,
            child: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VentureStudio Retainer'), findsOneWidget);
      expect(find.text('Apple Developer Program'), findsOneWidget);
      expect(find.text('Blue Tokai Coffee'), findsOneWidget);
      expect(find.text('-₹8,900.00'), findsOneWidget);
      expect(find.text('-₹420.00'), findsNWidgets(2)); // Row amount + day net sum
    });

    testWidgets('renders empty state when no transactions exist', (tester) async {
      final mockProvider = MockTransactionProvider();
      mockProvider.setMockData(transactions: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: mockProvider,
            child: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ledger entries yet'), findsOneWidget);
      expect(find.text('RECORD TRANSACTION'), findsOneWidget);
    });

    testWidgets('renders error state when fetch fails', (tester) async {
      final mockProvider = MockTransactionProvider();
      mockProvider.setMockData(error: 'Network connection failed');

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: mockProvider,
            child: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEDGER UNAVAILABLE'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
    });

    for (final width in [320.0, 840.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'ledger responsive layout width $width dark $dark scaled keyboard',
          (tester) async {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final mockProvider = MockTransactionProvider();
            mockProvider.setMockData(transactions: testTransactions);

            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<TransactionProvider>.value(
                    value: mockProvider,
                  ),
                ],
                child: MaterialApp(
                  theme: dark ? HorizonTheme.darkTheme : HorizonTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true,
                      viewInsets: const EdgeInsets.only(bottom: 200),
                    ),
                    child: child!,
                  ),
                  home: const LedgerScreen(),
                ),
              ),
            );

            await tester.pumpAndSettle();
            expect(tester.takeException(), null);

            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -600),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), null);
          },
        );
      }
    }
  });
}
