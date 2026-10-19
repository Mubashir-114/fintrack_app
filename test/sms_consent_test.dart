import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/transactions/sms_import_screen.dart';

class _ConsentProvider extends SmsProvider {
  int scans = 0;
  @override
  Future<void> scanAndDetectSmartTransactions({
    bool userConsented = false,
  }) async {
    if (userConsented) scans++;
  }
}

class _Accounts extends AccountProvider {
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {}
}

void main() {
  for (final choice in ['decline', 'dismiss', 'accept']) {
    testWidgets(
      'SMS notice $choice controls scanning; retries require a fresh choice',
      (tester) async {
        final provider = _ConsentProvider();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SmsProvider>.value(value: provider),
              ChangeNotifierProvider<AccountProvider>(
                create: (_) => _Accounts(),
              ),
              ChangeNotifierProvider(create: (_) => CurrencyProvider()),
              ChangeNotifierProvider(create: (_) => DashboardProvider()),
              ChangeNotifierProvider(create: (_) => TransactionProvider()),
            ],
            child: const MaterialApp(home: SmsImportScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Optional SMS import'), findsOneWidget);
        expect(provider.scans, 0);
        if (choice == 'dismiss') {
          await tester.tapAt(const Offset(4, 4));
        } else {
          await tester.tap(
            find.text(choice == 'accept' ? 'Continue to scan' : 'Not now'),
          );
        }
        await tester.pumpAndSettle();
        expect(provider.scans, choice == 'accept' ? 1 : 0);
        await tester.tap(find.byTooltip('Rescan SMS'));
        await tester.pumpAndSettle();
        expect(find.text('Optional SMS import'), findsOneWidget);
        expect(provider.scans, choice == 'accept' ? 1 : 0);
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(provider.scans, choice == 'accept' ? 1 : 0);
      },
    );
  }
}
