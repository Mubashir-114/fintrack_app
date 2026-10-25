import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/horizon/components/horizon_count_up_text.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/money_storage/money_storage_screen.dart';

import 'dashboard_v2_test.dart' show MockAuthProvider, MockDashboardProvider;

class _Accounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'bank',
      subtype: 'savings',
      displayName: 'Savings Vault',
      currencyCode: 'INR',
      openingAmount: '0.00',
      isDefault: true,
      status: 'active',
    ),
  ];

  @override
  AccountModel? get defaultAccount => accounts.first;
}

class _EmptySms extends SmsProvider {
  @override
  Future<void> loadDetectedTransactions({String status = "suggested"}) async {}
}

class _PlaceHolder extends StatelessWidget {
  const _PlaceHolder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

MockDashboardProvider _mockDashboard() {
  final provider = MockDashboardProvider();
  provider.setMockData(
    summary: DashboardSummary.fromJson({
      'overview': {
        'totalAssets': '50000.00',
        'totalLiabilities': '15000.00',
        'netWorth': '35000.00',
        'monthlyIncome': '25000.00',
        'monthlyExpenses': '8000.00',
        'monthlyNetSavings': '17000.00',
        'monthOverMonth': {
          'incomeChangePercent': '+12.0',
          'expenseChangePercent': '-4.5',
          'savingsChangePercent': '+20.0',
        },
      },
      'accounts': {
        'items': [
          {
            'id': 1,
            'displayName': 'Savings Vault',
            'type': 'bank',
            'subtype': 'savings',
            'currencyCode': 'INR',
            'currentBalance': '50000.00',
            'isDefault': true,
            'status': 'active',
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
          'message': 'Groceries was your highest expense category.',
        },
      ],
    }),
    monthly: const [
      MonthlySummary(month: '2026-09', income: 20000, expense: 15000),
      MonthlySummary(month: '2026-10', income: 25000, expense: 8000),
    ],
    recent: [
      const TransactionModel(
        id: 101,
        userId: 1,
        categoryId: 5,
        category: 'Groceries',
        type: 'expense',
        title: 'BigBasket Run',
        amount: 1500.0,
        transactionDate: '2026-10-05',
        source: 'manual',
      ),
    ],
  );
  return provider;
}

Widget _app({
  required GoRouter router,
  required MockDashboardProvider dashboard,
  bool reduceMotion = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: MockAuthProvider()),
      ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
      ChangeNotifierProvider<SmsProvider>.value(value: _EmptySms()),
      ChangeNotifierProvider<AccountProvider>.value(value: _Accounts()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      routerConfig: router,
    ),
  );
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/money-storage',
      builder: (_, _) => const MoneyStorageScreen(),
    ),
    GoRoute(path: '/analytics', builder: (_, _) => const _PlaceHolder('FIN')),
    GoRoute(path: '/ledger', builder: (_, _) => const _PlaceHolder('Ledger')),
    GoRoute(path: '/budgets', builder: (_, _) => const _PlaceHolder('Budgets')),
    GoRoute(
      path: '/accounts/:id',
      builder: (_, _) => const _PlaceHolder('Account detail'),
    ),
  ],
);

void main() {
  group('dashboard redesign', () {
    testWidgets('net worth renders as an exact count-up readout', (
      tester,
    ) async {
      final router = _router('/dashboard');
      final dashboard = _mockDashboard();
      await tester.pumpWidget(_app(router: router, dashboard: dashboard));
      await tester.pumpAndSettle();

      expect(find.byType(HorizonCountUpAmount), findsWidgets);
      expect(find.text('₹35,000.00'), findsOneWidget);
      expect(find.text('₹25,000.00'), findsOneWidget);
      expect(find.text('₹17,000.00'), findsOneWidget);
      // Real month-over-month value instead of a hardcoded figure.
      expect(find.text('+12.0% MoM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('range switcher changes the reporting period', (tester) async {
      final router = _router('/dashboard');
      final dashboard = _mockDashboard();
      await tester.pumpWidget(_app(router: router, dashboard: dashboard));
      await tester.pumpAndSettle();

      expect(dashboard.selectedPeriod, 'current_month');
      await tester.tap(find.text('Previous Month'));
      await tester.pumpAndSettle();
      expect(dashboard.selectedPeriod, 'previous_month');
      expect(tester.takeException(), isNull);
    });

    testWidgets('cash-flow trend opens a dismissible sheet', (tester) async {
      final router = _router('/dashboard');
      final dashboard = _mockDashboard();
      await tester.pumpWidget(_app(router: router, dashboard: dashboard));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cash-flow trend'));
      await tester.tap(find.text('Cash-flow trend'));
      await tester.pumpAndSettle();

      expect(
        find.text('Income against expenses for the selected period'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close cash-flow trend'));
      await tester.pumpAndSettle();
      expect(
        find.text('Income against expenses for the selected period'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('section actions navigate instead of dead-ending', (
      tester,
    ) async {
      final router = _router('/dashboard');
      final dashboard = _mockDashboard();
      await tester.pumpWidget(_app(router: router, dashboard: dashboard));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Manage (1)'));
      await tester.tap(find.text('Manage (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Money Storage'), findsOneWidget);

      router.go('/dashboard');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View all'));
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(find.text('Ledger'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders the dashboard statically', (
      tester,
    ) async {
      final router = _router('/dashboard');
      final dashboard = _mockDashboard();
      await tester.pumpWidget(
        _app(router: router, dashboard: dashboard, reduceMotion: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('₹35,000.00'), findsOneWidget);
      expect(find.byType(HorizonCountUpAmount), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
