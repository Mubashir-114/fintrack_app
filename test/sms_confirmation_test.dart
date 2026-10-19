import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/detected_transaction_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/repositories/smart_transaction_repository.dart';
import 'package:frontend/screens/transactions/sms_import_screen.dart';

DetectedTransactionModel candidate(int id) => DetectedTransactionModel(
  id: id,
  userId: 1,
  accountId: 5,
  categoryId: 1,
  classification: 'expense',
  amount: '45.00',
  transactionDate: '2026-10-19',
  merchantRaw: 'Shop $id',
  merchantClean: 'Shop $id',
  smsHash: 'hash$id',
  confidence: 0.9,
  isAccountAmbiguous: false,
  status: 'suggested',
);

class SmartRepo extends SmartTransactionRepository {
  Object? loadError;
  List<DetectedTransactionModel> candidates = [];
  final List<List<int>> batches = [];
  final Set<int> failures = {};
  Completer<void>? gate;
  int confirmations = 0;
  Map<String, dynamic>? lastOverrides;
  @override
  Future<ApiResponse<List<DetectedTransactionModel>>> getDetectedTransactions({
    String status = 'suggested',
    String? classification,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    if (loadError != null) throw loadError!;
    return ApiResponse(
      success: true,
      message: '',
      data: candidates.skip((page - 1) * limit).take(limit).toList(),
    );
  }
  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmTransaction(
    int id, {
    Map<String, dynamic>? overrides,
  }) async {
    confirmations++;
    lastOverrides = overrides;
    await gate?.future;
    return ApiResponse(
      success: true,
      message: '',
      data: {
        'id': id,
        'status': 'confirmed',
        'confirmedTransactionId': id + 1000,
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> batchConfirm(
    List<Map<String, dynamic>> items,
  ) async {
    final ids = items.map((item) => item['id'] as int).toList();
    batches.add(ids);
    await gate?.future;
    return ApiResponse(
      success: true,
      message: '',
      data: {
        'confirmed': [
          for (final id in ids)
            if (!failures.contains(id)) {'id': id, 'status': 'confirmed'},
        ],
        'errors': [
          for (final id in ids)
            if (failures.contains(id))
              {'id': id, 'error': 'Choose an active account using Edit.'},
        ],
      },
    );
  }
}

class Accounts extends AccountProvider {
  int refreshes = 0;
  @override
  List<AccountModel> get accounts => [
    const AccountModel(
      id: 5,
      type: 'bank',
      subtype: 'savings',
      displayName: 'Savings',
      currencyCode: 'INR',
      openingAmount: '0',
      isDefault: true,
      status: 'active',
    ),
  ];
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {}
  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

class Transactions extends TransactionProvider {
  int refreshes = 0;
  @override
  Future<void> loadTransactions({bool loadMore = false}) async {
    refreshes++;
  }
}

class Dashboard extends DashboardProvider {
  int refreshes = 0;
  @override
  Future<void> loadDashboardData() async {
    refreshes++;
  }
}

class Reports extends ReportProvider {
  int refreshes = 0;
  @override
  Future<void> loadAllReports() async {
    refreshes++;
  }
}

class Budgets extends BudgetProvider {
  int refreshes = 0;
  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    expect(forceRefresh, isTrue);
    refreshes++;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize(memoryOnly: true);
  });

  test('pending review handles non-JSON server failures and can retry', () async {
    final request = RequestOptions(path: 'smart-transactions');
    final repo = SmartRepo()
      ..loadError = DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 503,
          data: 'Service unavailable',
        ),
        message: 'Server unavailable',
      );
    final sms = SmsProvider(smartRepo: repo);
    await sms.loadDetectedTransactions();
    expect(sms.detectedErrorMessage, 'Server unavailable');
    expect(sms.isLoadingDetected, isFalse);
    repo
      ..loadError = null
      ..candidates = [candidate(1)];
    await sms.loadDetectedTransactions();
    expect(sms.detectedErrorMessage, isNull);
    expect(sms.detectedCount, 1);
  });

  test(
    'Add All ignores selection, excludes invalid, duplicate and completed candidates',
    () async {
      final repo = SmartRepo()
        ..candidates = [
          candidate(1),
          candidate(2),
          candidate(3).copyWith(amount: 'NaN'),
          candidate(4).copyWith(smsHash: 'hash1'),
          candidate(5).copyWith(status: 'rejected'),
          candidate(6).copyWith(status: 'confirmed'),
          candidate(7).copyWith(isAccountAmbiguous: true),
          candidate(8).copyWith(transactionDate: '2026-02-31'),
        ];
      final sms = SmsProvider(smartRepo: repo);
      await sms.loadDetectedTransactions();
      sms.toggleSelectAllDetected(false);
      // An explicit account resolves ambiguity; no guessed account is required.
      expect(sms.eligibleDetectedCount, 3);
      expect(await sms.batchConfirmSelected(all: true), isFalse);
      expect(repo.batches.single, [1, 2, 7]);
      expect(sms.batchResult!.added, 3);
      expect(sms.batchResult!.needsAttention, 2);
      expect(sms.batchResult!.skipped, 3);
      expect(sms.detectedTransactions.map((tx) => tx.id), containsAll([3, 8]));
    },
  );

  test('Add Selected keeps unselected and failed candidates pending', () async {
    final repo = SmartRepo()
      ..candidates = [candidate(1), candidate(2), candidate(3)]
      ..failures.add(2);
    final sms = SmsProvider(smartRepo: repo);
    await sms.loadDetectedTransactions();
    sms.toggleDetectedSelection(3);
    expect(await sms.batchConfirmSelected(), isFalse);
    expect(repo.batches.single, [1, 2]);
    expect(sms.detectedTransactions.map((tx) => tx.id), [2, 3]);
    expect(sms.selectedDetectedIds, {2});
    expect(sms.confirmationErrors[2], contains('active account'));
    expect(sms.batchResult!.added, 1);
  });

  test(
    'missing and ambiguous accounts cannot be confirmed directly or in a batch',
    () async {
      final missing = DetectedTransactionModel.fromJson({
        ...candidate(1).toJson(),
        'accountId': null,
      });
      final ambiguous = DetectedTransactionModel.fromJson({
        ...candidate(2).toJson(),
        'accountId': null,
        'suggestedAccountId': 5,
        'isAccountAmbiguous': true,
      });
      final repo = SmartRepo()..candidates = [missing, ambiguous];
      final sms = SmsProvider(smartRepo: repo);
      await sms.loadDetectedTransactions();
      expect(await sms.confirmDetected(1), isFalse);
      expect(sms.detectedErrorMessage, contains('account using Edit'));
      expect(await sms.confirmDetected(2), isFalse);
      expect(repo.confirmations, 0);
      expect(await sms.batchConfirmSelected(all: true), isFalse);
      expect(repo.batches, isEmpty);
      expect(sms.batchResult!.needsAttention, 2);
      expect(sms.detectedCount, 2);
    },
  );

  test('Add All chunks large imports at the existing endpoint limit', () async {
    final repo = SmartRepo()
      ..candidates = List.generate(205, (i) => candidate(i + 1));
    final sms = SmsProvider(smartRepo: repo);
    await sms.loadDetectedTransactions();
    expect(await sms.batchConfirmSelected(all: true), isTrue);
    expect(repo.batches.map((b) => b.length), [100, 100, 5]);
    expect(sms.detectedCount, 0);
  });

  for (final mode in ['single', 'batch', 'partial batch']) {
    final batch = mode != 'single';
    final partial = mode == 'partial batch';
    testWidgets('$mode saves directly and refreshes every ledger provider', (
      tester,
    ) async {
      final repo = SmartRepo()
        ..candidates = [candidate(1), if (partial) candidate(2)]
        ..gate = Completer<void>();
      if (partial) repo.failures.add(2);
      final sms = SmsProvider(smartRepo: repo);
      final accounts = Accounts();
      final transactions = Transactions();
      final dashboard = Dashboard();
      final reports = Reports();
      final budgets = Budgets();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SmsProvider>.value(value: sms),
            ChangeNotifierProvider<AccountProvider>.value(value: accounts),
            ChangeNotifierProvider<TransactionProvider>.value(
              value: transactions,
            ),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<ReportProvider>.value(value: reports),
            ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: const MaterialApp(home: SmsImportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (find.text('Not now').evaluate().isNotEmpty) {
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
      }
      if (batch) sms.toggleSelectAllDetected(false);
      final action = find.text(
        batch ? 'Add All (${partial ? 2 : 1})' : 'Confirm',
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pump();
      expect(find.text('Correct transaction'), findsNothing);
      expect(sms.isOperating, isTrue);
      expect(transactions.refreshes, 0);
      expect(accounts.refreshes, 0);
      final button = tester.widget<FilledButton>(
        find.ancestor(of: action, matching: find.byType(FilledButton)),
      );
      expect(button.onPressed, isNull);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(sms.detectedCount, partial ? 1 : 0);
      if (partial) {
        expect(sms.detectedTransactions.single.id, 2);
        expect(
          sms.batchResult!.message,
          '1 added; 1 need correction or retry.',
        );
        expect(
          find.textContaining('1 added; 1 need correction or retry.'),
          findsWidgets,
        );
      }
      expect(transactions.refreshes, 1);
      expect(dashboard.refreshes, 1);
      expect(accounts.refreshes, 1);
      expect(reports.refreshes, 1);
      expect(budgets.refreshes, 1);
      expect(repo.lastOverrides, isNull);
      expect(find.text('Correct transaction'), findsNothing);
    });
  }

  testWidgets(
    'Edit exclusively opens correction dialog; invalid Confirm directs to Edit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = SmartRepo()
        ..candidates = [candidate(1).copyWith(amount: '0')];
      final sms = SmsProvider(smartRepo: repo);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SmsProvider>.value(value: sms),
            ChangeNotifierProvider<AccountProvider>(create: (_) => Accounts()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: const MaterialApp(home: SmsImportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      if (find.text('Not now').evaluate().isNotEmpty) {
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(repo.confirmations, 0);
      expect(find.text('Correct transaction'), findsNothing);
      expect(
        find.text('Enter a valid positive amount using Edit.'),
        findsWidgets,
      );
      await tester.ensureVisible(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Correct transaction'), findsOneWidget);
      expect(repo.confirmations, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
