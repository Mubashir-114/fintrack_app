import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/core/horizon/components/horizon_component_previews.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/account_balance_model.dart';
import 'package:frontend/models/account_activity_model.dart';
import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/accounts/account_detail_screen.dart';
import 'package:frontend/screens/accounts/add_account_screen.dart';
import 'package:frontend/screens/analytics/widgets/global_fin_overlay.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/dashboard/widgets/dashboard_previews.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/money_storage/money_storage_screen.dart';
import 'package:frontend/screens/money_storage/widgets/storage_previews.dart';
import 'package:frontend/screens/money_storage/widgets/storage_node_row.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/core/widgets/notification_center_sheet.dart';
import 'package:frontend/core/widgets/profile_avatar.dart';
import 'package:frontend/screens/transfers/transfer_screen.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';

import 'dashboard_v2_test.dart' show MockAuthProvider, MockDashboardProvider;
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;
import 'support/ledger_fixture.dart';

class _Accounts extends AccountProvider {
  int refreshes = 0;
  int? defaultId;
  @override
  List<AccountModel> get accounts => [
    for (final (id, type, name, amount) in [
      (1, 'bank', 'Everyday Savings', '382450.75'),
      (2, 'wallet', 'Travel Wallet', '14890.25'),
      (3, 'credit_card', 'Platinum Rewards', '25000.00'),
    ])
      AccountModel(
        id: id,
        type: type,
        subtype: 'savings',
        displayName: name,
        institutionName: 'HDFC Bank',
        maskedLast4: '4821',
        currencyCode: 'INR',
        openingAmount: amount,
        isDefault: id == (defaultId ?? 1),
        status: 'active',
      ),
  ];
  @override
  AccountModel? get defaultAccount => accounts.firstWhere((a) => a.isDefault);
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {}
  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<bool> setDefault(int id) async {
    defaultId = id;
    notifyListeners();
    return true;
  }

  @override
  Future<AccountBalanceModel?> getAccountBalance(int id) async => null;
  @override
  Future<AccountActivityListResponse?> getAccountActivity(
    int id, {
    int page = 1,
    int limit = 20,
  }) async => null;
}

class _Dashboard extends MockDashboardProvider {
  int refreshes = 0;
  _Dashboard() {
    setMockData(
      summary: DashboardSummary.fromJson({
        'overview': {
          'totalAssets': '397341.00',
          'totalLiabilities': '25000.00',
          'netWorth': '372341.00',
          'monthlyIncome': '295000.00',
          'monthlyExpenses': '32400.00',
          'monthlyNetSavings': '262600.00',
          'savingsRate': '89.0',
          'monthOverMonth': {'incomeChangePercent': '+12.0'},
        },
        'accounts': {
          'items': [
            for (final a in _Accounts().accounts)
              {
                'id': a.id,
                'displayName': a.displayName,
                'type': a.type,
                'subtype': a.subtype,
                'currencyCode': a.currencyCode,
                'currentBalance': a.openingAmount,
                if (a.type == 'credit_card') 'outstandingDebt': a.openingAmount,
                'isDefault': a.isDefault,
                'status': a.status,
              },
          ],
        },
        'spending': {
          'byCategory': [
            {
              'id': 5,
              'name': 'Groceries',
              'total': '6000.00',
              'percentage': '75.0',
            },
          ],
          'topMerchants': [],
        },
        'insights': [
          {
            'type': 'highest_category',
            'message':
                'Groceries was your highest expense category this month.',
          },
        ],
      }),
      recent: ledgerRecords,
      monthly: [
        const MonthlySummary(month: '2026-10', income: 295000, expense: 32400),
        const MonthlySummary(month: '2026-09', income: 263000, expense: 37000),
        const MonthlySummary(month: '2026-08', income: 245000, expense: 41000),
        const MonthlySummary(month: '2026-07', income: 251000, expense: 35000),
        const MonthlySummary(month: '2026-06', income: 220000, expense: 43000),
        const MonthlySummary(month: '2026-05', income: 235000, expense: 39000),
      ],
    );
  }
  @override
  Future<void> loadDashboardData() async {
    refreshes++;
    notifyListeners();
  }
}

class _Sms extends SmsProvider {
  @override
  Future<void> loadDetectedTransactions({String status = 'suggested'}) async {}
}

class _Transactions extends LedgerFixtureProvider {
  _Transactions() : super(records: List.of(ledgerRecords));
  int? category;
  int? deleted;
  @override
  int? get selectedCategoryId => category;
  @override
  get transactions => super.transactions
      .where((tx) => category == null || tx.categoryId == category)
      .toList();
  @override
  void setCategoryId(int? value) {
    category = value;
    notifyListeners();
  }

  @override
  void clearFilters() {
    category = null;
    super.clearFilters();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    deleted = id;
    records.removeWhere((tx) => tx.id == id);
    notifyListeners();
    return true;
  }
}

class _Reports extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
}

class _Budgets extends BudgetProvider {
  BudgetAlertsResponseModel? _alerts;
  @override
  BudgetAlertsResponseModel? get alerts => _alerts;
  void publishAlerts(int count) {
    _alerts = BudgetAlertsResponseModel(
      month: 10,
      year: 2026,
      approachingLimit: const [],
      insights: const [],
      exceeded: [
        for (var i = 0; i < count; i++)
          const BudgetAlertModel(
            severity: 'critical',
            message: 'Spending exceeded the saved limit.',
          ),
      ],
      totalAlertsCount: count,
    );
    notifyListeners();
  }

  @override
  Future<void> loadBudgetAlerts() async {}
  @override
  Future<void> loadBudgetStatus({bool forceRefresh = false}) async {}
}

Future<
  ({
    GoRouter router,
    _Accounts accounts,
    _Dashboard dashboard,
    _Transactions transactions,
  })
>
_pump(
  WidgetTester tester,
  String path, {
  Size size = const Size(393, 852),
  double scale = 1,
  Brightness brightness = Brightness.dark,
  GlobalKey? captureKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final accounts = _Accounts();
  final dashboard = _Dashboard();
  final transactions = _Transactions();
  final fin = AnalyticsProvider(repository: MockPhase5FRepository());
  final router = GoRouter(
    initialLocation: path,
    observers: [FinOverlayObserver()],
    routes: [
      ShellRoute(
        observers: [FinOverlayObserver()],
        builder: (_, _, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/money-storage',
            builder: (_, _) => const MoneyStorageScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, _) => const TransactionsListScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: '/accounts/add',
            builder: (_, _) => const AddAccountScreen(),
          ),
          GoRoute(
            path: '/accounts/transfer',
            builder: (_, _) => const TransferScreen(),
          ),
          GoRoute(
            path: '/accounts/:id',
            builder: (_, state) => AccountDetailScreen(
              accountId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => MockAuthProvider()
            ..setMockUser(
              const UserModel(
                id: 1,
                name: 'Alex Morgan',
                email: 'alex@example.test',
              ),
            ),
        ),
        ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
        ChangeNotifierProvider<AccountProvider>.value(value: accounts),
        ChangeNotifierProvider<TransactionProvider>.value(value: transactions),
        ChangeNotifierProvider<AnalyticsProvider>.value(value: fin),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(),
        ),
        ChangeNotifierProvider<SmsProvider>(create: (_) => _Sms()),
        ChangeNotifierProvider<BudgetProvider>(create: (_) => _Budgets()),
        ChangeNotifierProvider<ReportProvider>(create: (_) => _Reports()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: captureKey, child: child!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    accounts.dispose();
    dashboard.dispose();
    transactions.dispose();
    fin.dispose();
  });
  return (
    router: router,
    accounts: accounts,
    dashboard: dashboard,
    transactions: transactions,
  );
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final picture = await tester
        .renderObject<RenderRepaintBoundary>(find.byKey(key))
        .toImage(pixelRatio: 1.5);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/modernization_final');
    await dir.create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    final fontDirectory =
        '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final variant in ['regular', 'medium', 'bold', 'black']) {
      final file = File('$fontDirectory/roboto-$variant.ttf');
      if (await file.exists()) {
        roboto.addFont(file.readAsBytes().then(ByteData.sublistView));
      }
    }
    await roboto.load();
    for (final (name, path) in [
      ('Space Grotesk', 'assets/fonts/SpaceGrotesk.ttf'),
      ('Plus Jakarta Sans', 'assets/fonts/PlusJakartaSans.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(name)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final screen in ['dashboard', 'money-storage', 'transactions']) {
    for (final (name, size, scale, brightness) in [
      ('320_dark', const Size(320, 640), 1.0, Brightness.dark),
      ('393_dark', const Size(393, 852), 1.0, Brightness.dark),
      ('393_light', const Size(393, 852), 1.0, Brightness.light),
      ('600_dark', const Size(600, 960), 1.0, Brightness.dark),
      ('320_text2x', const Size(320, 640), 2.0, Brightness.dark),
    ]) {
      testWidgets('final render $screen $name', (tester) async {
        final key = GlobalKey();
        await _pump(
          tester,
          '/$screen',
          size: size,
          scale: scale,
          brightness: brightness,
          captureKey: key,
        );
        await _capture(tester, key, '${screen}_$name');
        final scrollable = find
            .byType(Scrollable)
            .evaluate()
            .where(
              (e) =>
                  (e.widget as Scrollable).axisDirection == AxisDirection.down,
            )
            .first;
        final state = (scrollable as StatefulElement).state as ScrollableState;
        state.position.jumpTo(state.position.maxScrollExtent / 2);
        await tester.pumpAndSettle();
        await _capture(tester, key, '${screen}_${name}_middle');
        for (var i = 0; i < 3; i++) {
          state.position.jumpTo(state.position.maxScrollExtent);
          await tester.pumpAndSettle();
        }
        await _capture(tester, key, '${screen}_${name}_bottom');
        if (screen == 'transactions') {
          final fab = find.byType(FloatingActionButton);
          expect(fab.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(find.byType(ListView).first).bottom,
            lessThanOrEqualTo(tester.getRect(fab).top),
          );
          final last = find.byType(HorizonTransactionRow).last;
          expect(
            tester.getRect(last).bottom,
            lessThan(tester.getRect(fab).top),
          );
        }
      });
    }
  }
  final previews = <String, (Widget Function(), Size)>{
    'range': (horizonRangeSwitcherPreview, const Size(360, 110)),
    'custom_range': (horizonRangeSwitcherCustomPreview, const Size(360, 110)),
    'metrics': (horizonMetricStripPreview, const Size(360, 170)),
    'section': (horizonSectionHeaderPreview, const Size(360, 90)),
    'amount': (horizonCountUpPreview, const Size(360, 100)),
    'trend': (horizonTrendLinePreview, const Size(360, 130)),
    'icon': (horizonIconButtonPreview, const Size(360, 100)),
    'row': (horizonTransactionRowPreview, const Size(360, 160)),
    'hero': (dashboardHeroPreview, const Size(393, 520)),
    'hero_light': (dashboardHeroLightPreview, const Size(393, 520)),
    'insight': (dashboardFinInsightPreview, const Size(393, 110)),
    'account': (dashboardAccountRowPreview, const Size(393, 130)),
    'recent': (dashboardRecentRowPreview, const Size(393, 120)),
    'liquidity': (liquiditySummaryPreview, const Size(393, 420)),
    'storage_actions': (storageActionRowPreview, const Size(393, 110)),
    'storage_node': (storageNodeRowPreview, const Size(393, 160)),
    'storage_node_light': (storageNodeRowLightPreview, const Size(393, 160)),
  };
  for (final entry in previews.entries) {
    testWidgets('preview ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(entry.value.$1());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (entry.key == 'range') {
        await tester.tap(find.text('Previous Month'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<HorizonRangeSwitcher>(find.byType(HorizonRangeSwitcher))
              .selectedIndex,
          1,
        );
      }
    });
  }
  testWidgets('storage real forms, reconcile, default and back', (
    tester,
  ) async {
    final fixture = await _pump(tester, '/money-storage');
    await tester.tap(find.byTooltip('Add node'));
    await tester.pumpAndSettle();
    expect(find.byType(AddAccountScreen), findsOneWidget);
    fixture.router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reconcile'));
    await tester.tap(find.text('Reconcile'));
    await tester.pumpAndSettle();
    expect(fixture.accounts.refreshes, 1);
    expect(fixture.dashboard.refreshes, greaterThan(0));
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(find.byType(TransferScreen), findsOneWidget);
    fixture.router.pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Travel Wallet'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    final row = find.ancestor(
      of: find.text('Travel Wallet'),
      matching: find.byType(StorageNodeRow),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('Account Actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set as Default'));
    await tester.pumpAndSettle();
    expect(fixture.accounts.defaultId, 2);
    expect(fixture.accounts.defaultAccount!.id, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dashboard account preview opens real detail and returns', (
    tester,
  ) async {
    final fixture = await _pump(tester, '/dashboard');
    await tester.scrollUntilVisible(
      find.text('Everyday Savings').first,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Everyday Savings').first);
    await tester.pumpAndSettle();
    expect(find.byType(AccountDetailScreen), findsOneWidget);
    expect(
      tester
          .widget<AccountDetailScreen>(find.byType(AccountDetailScreen))
          .accountId,
      1,
    );
    fixture.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'live budget badge counts only pending alerts and profile opens real hub',
    (tester) async {
      final fixture = await _pump(tester, '/dashboard');
      HorizonIconButton bell() => tester.widget<HorizonIconButton>(
        find.byType(HorizonIconButton).first,
      );
      expect(
        bell().badgeCount,
        0,
        reason: 'FIN insights do not create a pending badge',
      );
      final budgets =
          tester.element(find.byType(DashboardScreen)).read<BudgetProvider>()
              as _Budgets;
      budgets.publishAlerts(2);
      await tester.pumpAndSettle();
      expect(bell().badgeCount, 2);
      await tester.tap(find.byTooltip('Open updates'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationCenterSheet), findsOneWidget);
      expect(find.text('Budget exceeded'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Close updates'));
      await tester.pumpAndSettle();
      budgets.publishAlerts(0);
      await tester.pumpAndSettle();
      expect(bell().badgeCount, 0);
      await tester.tap(find.byType(ProfileAvatar).first);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      fixture.router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reset cancels pending transaction search', (tester) async {
    final fixture = await _pump(tester, '/transactions');
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Taxi');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Clear Filters'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(fixture.transactions.searchQuery, isNull);
    expect(fixture.transactions.selectedType, isNull);
    expect(fixture.transactions.transactions.length, ledgerRecords.length);
  });
  testWidgets('dashboard current, previous and custom months reach provider', (
    tester,
  ) async {
    final fixture = await _pump(tester, '/dashboard');
    await tester.tap(find.text('Previous Month'));
    await tester.pumpAndSettle();
    expect(fixture.dashboard.selectedPeriod, 'previous_month');
    await tester.tap(find.text('Current Month'));
    await tester.pumpAndSettle();
    expect(fixture.dashboard.selectedPeriod, 'current_month');
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(
      tester.element(find.byType(DatePickerDialog)),
    ).pop(DateTime(2026, 9, 1));
    await tester.pumpAndSettle();
    expect(fixture.dashboard.selectedMonth, '2026-09');
    expect(fixture.dashboard.selectedPeriod, 'custom');
    expect(find.text('2026-09'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('storage banking, treasury, liabilities and all filters', (
    tester,
  ) async {
    await _pump(tester, '/money-storage');
    await tester.tap(find.text('Banking'));
    await tester.pumpAndSettle();
    expect(find.text('Everyday Savings'), findsOneWidget);
    expect(find.text('Travel Wallet'), findsNothing);
    await tester.ensureVisible(find.text('Liabilities'));
    await tester.tap(find.text('Liabilities'));
    await tester.pumpAndSettle();
    expect(find.text('Platinum Rewards'), findsOneWidget);
    expect(find.text('Everyday Savings'), findsNothing);
    await tester.tap(find.text('Treasury'));
    await tester.pumpAndSettle();
    expect(find.text('No Nodes in Filter'), findsOneWidget);
    await tester.ensureVisible(find.text('All Nodes (3)'));
    await tester.tap(find.text('All Nodes (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Everyday Savings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('320dp enlarged text keeps sheets and menus usable', (
    tester,
  ) async {
    final key = GlobalKey();
    final fixture = await _pump(
      tester,
      '/dashboard',
      size: const Size(320, 640),
      scale: 2,
      captureKey: key,
    );
    await tester.tap(find.byTooltip('Open updates'));
    await tester.pumpAndSettle();
    await _capture(tester, key, 'dashboard_320_text2x_updates');
    await tester.tap(find.byTooltip('Close updates'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cash-flow trend'));
    await tester.tap(find.text('Cash-flow trend'));
    await tester.pumpAndSettle();
    await _capture(tester, key, 'dashboard_320_text2x_cash_flow');
    await tester.tap(find.byTooltip('Close cash-flow trend'));
    await tester.pumpAndSettle();
    fixture.router.go('/transactions');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(FinOverlayObserver.obscured.value, isTrue);
    await _capture(tester, key, 'transactions_320_text2x_menu');
    fixture.router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await _capture(tester, key, 'transactions_320_text2x_add');
    expect(
      find.byKey(const ValueKey('transaction-save')).hitTestable(),
      findsOneWidget,
    );
    fixture.router.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'transaction search, types, category, dates, edit, delete, add and back',
    (tester) async {
      final fixture = await _pump(tester, '/transactions');
      final p = fixture.transactions;
      await tester.enterText(find.byType(TextField).first, 'Taxi');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(p.transactions.single.title, 'Taxi');
      await tester.tap(find.byTooltip('Clear Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      expect(p.transactions.every((t) => t.type == 'income'), isTrue);
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(p.transactions.every((t) => t.type == 'expense'), isTrue);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-450, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Housing').last);
      await tester.pumpAndSettle();
      expect(p.selectedCategoryId, 5);
      await tester.tap(find.byTooltip('Clear Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Date Range'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      Navigator.of(tester.element(find.byType(DateRangePickerDialog))).pop(
        DateTimeRange(
          start: DateTime(2026, 10, 24),
          end: DateTime(2026, 10, 24),
        ),
      );
      await tester.pumpAndSettle();
      expect(p.transactions.length, 2);
      await tester.tap(find.byTooltip('Clear Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditTransactionSheet), findsOneWidget);
      expect(
        tester
            .widget<AddEditTransactionSheet>(
              find.byType(AddEditTransactionSheet),
            )
            .transaction!
            .id,
        1,
      );
      expect(FinOverlayObserver.obscured.value, isTrue);
      fixture.router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();
      expect(p.deleted, 1);
      expect(find.text('Taxi'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AddEditTransactionSheet>(
              find.byType(AddEditTransactionSheet),
            )
            .transaction,
        isNull,
      );
      fixture.router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
