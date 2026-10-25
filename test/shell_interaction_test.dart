import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/notification_center_sheet.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/detected_transaction_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/money_storage/money_storage_screen.dart';

import 'dashboard_v2_test.dart' show MockAuthProvider, MockDashboardProvider;

class _NoopSms extends SmsProvider {
  @override
  List<DetectedTransactionModel> get detectedTransactions => const [];

  @override
  Future<void> loadDetectedTransactions({String status = "suggested"}) async {}
}

class _PendingSms extends SmsProvider {
  @override
  List<DetectedTransactionModel> get detectedTransactions => const [
    DetectedTransactionModel(
      id: 101,
      userId: 1,
      accountId: null,
      accountName: null,
      suggestedAccountId: 1,
      suggestedAccountName: 'HDFC Checking',
      isAccountAmbiguous: false,
      categoryId: 1,
      categoryName: 'Food & Dining',
      classification: 'expense',
      amount: '540.00',
      transactionDate: '2026-10-24',
      merchantRaw: 'Swiggy Bangalore IN',
      merchantClean: 'Swiggy',
      bank: 'HDFC Bank',
      smsHash: 'hash-mock-1',
      confidence: 0.95,
      status: 'suggested',
    ),
    DetectedTransactionModel(
      id: 102,
      userId: 1,
      accountId: null,
      accountName: null,
      suggestedAccountId: null,
      suggestedAccountName: null,
      isAccountAmbiguous: false,
      categoryId: 2,
      categoryName: 'Shopping',
      classification: 'expense',
      amount: '1299.00',
      transactionDate: '2026-10-23',
      merchantRaw: 'AMAZON PAY',
      merchantClean: 'Amazon',
      bank: 'HDFC Bank',
      smsHash: 'hash-mock-2',
      confidence: 0.8,
      status: 'suggested',
    ),
  ];

  @override
  Future<void> loadDetectedTransactions({String status = "suggested"}) async {}
}

class _Accounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'bank',
      subtype: 'savings',
      displayName: 'Everyday Savings',
      currencyCode: 'INR',
      openingAmount: '10000.00',
      isDefault: true,
      status: 'active',
    ),
    AccountModel(
      id: 2,
      type: 'wallet',
      subtype: 'wallet',
      displayName: 'Liquid Vault Wallet',
      currencyCode: 'INR',
      openingAmount: '2500.00',
      isDefault: false,
      status: 'active',
    ),
  ];

  @override
  AccountModel? get defaultAccount => accounts.first;
}

class _PlaceHolder extends StatelessWidget {
  const _PlaceHolder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const _PlaceHolder('Profile')),
    GoRoute(path: '/budgets', builder: (_, _) => const _PlaceHolder('Budgets')),
    GoRoute(path: '/sms-import', builder: (_, _) => const _PlaceHolder('SMS')),
    GoRoute(path: '/analytics', builder: (_, _) => const _PlaceHolder('FIN')),
    GoRoute(
      path: '/money-storage',
      builder: (_, _) => const MoneyStorageScreen(),
    ),
    GoRoute(
      path: '/accounts/add',
      builder: (_, _) => const _PlaceHolder('Add'),
    ),
    GoRoute(
      path: '/accounts/transfer',
      builder: (_, _) => const _PlaceHolder('Transfer'),
    ),
    GoRoute(
      path: '/accounts/:id',
      builder: (_, _) => const _PlaceHolder('One'),
    ),
  ],
);

Widget _dashboardApp({
  required GoRouter router,
  SmsProvider? sms,
  AuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth ?? MockAuthProvider(),
      ),
      ChangeNotifierProvider<DashboardProvider>.value(
        value: MockDashboardProvider(),
      ),
      ChangeNotifierProvider<SmsProvider>.value(value: sms ?? _NoopSms()),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
    ],
    child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );
}

void main() {
  group('shell header interactions', () {
    testWidgets('notification bell opens a usable update center', (
      tester,
    ) async {
      final router = _router('/dashboard');
      await tester.pumpWidget(_dashboardApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open updates'));
      await tester.pumpAndSettle();

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('You are all caught up'), findsOneWidget);

      // Closing returns to the dashboard without navigation side effects.
      await tester.tap(find.byTooltip('Close updates'));
      await tester.pumpAndSettle();
      expect(find.text('Updates'), findsNothing);
      expect(find.text('Hello, Alex'), findsOneWidget);
    });

    testWidgets('pending SMS candidates are listed and routable', (
      tester,
    ) async {
      final router = _router('/dashboard');
      await tester.pumpWidget(
        _dashboardApp(router: router, sms: _PendingSms()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open updates'));
      await tester.pumpAndSettle();

      expect(find.text('Updates'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NotificationCenterSheet),
          matching: find.text('2 SMS candidates to review'),
        ),
        findsOneWidget,
      );
      expect(find.text('FIN insight'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(NotificationCenterSheet),
          matching: find.text('2 SMS candidates to review'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SMS'), findsOneWidget);
    });

    testWidgets('profile entry opens the profile hub', (tester) async {
      final semantics = tester.ensureSemantics();
      final router = _router('/dashboard');
      await tester.pumpWidget(_dashboardApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Open profile'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('money storage interactions', () {
    testWidgets('filter rail narrows the node list', (tester) async {
      final router = _router('/money-storage');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(
              value: MockAuthProvider(),
            ),
            ChangeNotifierProvider<DashboardProvider>.value(
              value: MockDashboardProvider(),
            ),
            ChangeNotifierProvider<AccountProvider>.value(value: _Accounts()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Everyday Savings'), findsOneWidget);

      await tester.tap(find.text('Banking'));
      await tester.pumpAndSettle();
      expect(find.text('Everyday Savings'), findsOneWidget);
      expect(find.text('Liquid Vault Wallet'), findsNothing);

      await tester.tap(find.text('All Nodes (2)'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Liquid Vault Wallet'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Liquid Vault Wallet'), findsOneWidget);
    });

    testWidgets('add node action routes to the account form', (tester) async {
      final router = _router('/money-storage');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(
              value: MockAuthProvider(),
            ),
            ChangeNotifierProvider<DashboardProvider>.value(
              value: MockDashboardProvider(),
            ),
            ChangeNotifierProvider<AccountProvider>.value(value: _Accounts()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add node'));
      await tester.pumpAndSettle();
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
