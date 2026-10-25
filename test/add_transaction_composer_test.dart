import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/horizon/components/horizon_pressable.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';

class _Accounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'bank',
      subtype: 'savings',
      displayName: 'Everyday Savings',
      currencyCode: 'USD',
      openingAmount: '0.00',
      isDefault: true,
      status: 'active',
    ),
    AccountModel(
      id: 2,
      type: 'bank',
      subtype: 'current',
      displayName: 'Shared Household Current Account',
      currencyCode: 'USD',
      openingAmount: '0.00',
      isDefault: false,
      status: 'active',
    ),
  ];

  @override
  AccountModel? get defaultAccount => accounts.first;
}

class _RecordingTransactions extends TransactionProvider {
  int addCalls = 0;
  String? lastType;
  int? lastCategoryId;
  int? lastAccountId;
  double? lastAmount;

  @override
  Future<bool> addTransaction({
    required int categoryId,
    required String type,
    required String title,
    required double amount,
    required String transactionDate,
    String? note,
    int? accountId,
  }) async {
    addCalls++;
    lastType = type;
    lastCategoryId = categoryId;
    lastAccountId = accountId;
    lastAmount = amount;
    return false;
  }
}

Widget _app({
  required TransactionProvider transactions,
  AccountProvider? accounts,
  double textScale = 1,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransactionProvider>.value(value: transactions),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ChangeNotifierProvider<AccountProvider>(
        create: (_) => accounts ?? _Accounts(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(body: AddEditTransactionSheet()),
    ),
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required TransactionProvider transactions,
  AccountProvider? accounts,
  double textScale = 1,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(transactions: transactions, accounts: accounts, textScale: textScale),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('leads with amount, type switch, category rail and light rows', (
    tester,
  ) async {
    await _pumpSheet(tester, transactions: _RecordingTransactions());

    expect(find.text('New Transaction'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transaction-type-expense')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-type-income')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('transaction-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-merchant')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-note')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-save')), findsOneWidget);

    // Amount is the typographic focal point of the composer.
    final amount = tester.widget<TextField>(
      find.byKey(const ValueKey('transaction-amount')),
    );
    final title = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-merchant')),
        matching: find.byType(TextField),
      ),
    );
    expect(amount.style!.fontSize, 44);
    expect(title.style!.fontSize! < amount.style!.fontSize!, isTrue);

    expect(find.text('Amount spent'), findsOneWidget);
    expect(find.text('Outflow'), findsOneWidget);
    expect(find.text('ADD EXPENSE'), findsOneWidget);

    // Food is preselected without opening a menu.
    expect(
      tester
          .widget<HorizonPressable>(find.byKey(const ValueKey('cat_chip_3')))
          .selected,
      isTrue,
    );
  });

  testWidgets('income switches accent copy, categories and primary action', (
    tester,
  ) async {
    await _pumpSheet(tester, transactions: _RecordingTransactions());

    await tester.tap(find.byKey(const ValueKey('transaction-type-income')));
    await tester.pumpAndSettle();

    expect(find.text('Amount received'), findsOneWidget);
    expect(find.text('Inflow'), findsOneWidget);
    expect(find.text('ADD INCOME'), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_chip_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_chip_3')), findsNothing);
    expect(
      tester
          .widget<HorizonPressable>(find.byKey(const ValueKey('cat_chip_1')))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Amount spent'), findsOneWidget);
    expect(find.text('ADD EXPENSE'), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);
  });

  testWidgets('keeps validation and only submits valid input', (tester) async {
    final transactions = _RecordingTransactions();
    await _pumpSheet(tester, transactions: transactions);

    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();

    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(transactions.addCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();
    expect(find.text('Amount must be greater than zero'), findsOneWidget);
    expect(transactions.addCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '12.50',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-merchant')),
      'Corner cafe',
    );
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(transactions.addCalls, 1);
    expect(transactions.lastType, 'expense');
    expect(transactions.lastCategoryId, 3);
    expect(transactions.lastAmount, 12.5);
    expect(transactions.lastAccountId, isNull);

    // Let the failure snackbar timer finish so no timers leak.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('account picker keeps default behavior and explicit choice', (
    tester,
  ) async {
    final transactions = _RecordingTransactions();
    await _pumpSheet(tester, transactions: transactions);

    expect(find.text('Everyday Savings · default'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transaction-account')));
    await tester.pumpAndSettle();
    expect(find.text('Choose account'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account-option-2')));
    await tester.pumpAndSettle();
    expect(find.text('Shared Household Current Account'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transaction-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-option-default')));
    await tester.pumpAndSettle();
    expect(find.text('Everyday Savings · default'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '5.00',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-merchant')),
      'Bus',
    );
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(transactions.lastAccountId, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('stays usable on a compact phone with 2x text', (tester) async {
    await _pumpSheet(
      tester,
      transactions: _RecordingTransactions(),
      textScale: 2,
      size: const Size(320, 568),
    );

    expect(tester.takeException(), isNull);
    final save = find.byKey(const ValueKey('transaction-save'));
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(save).dx, lessThanOrEqualTo(320));
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(568));

    await tester.tap(find.byKey(const ValueKey('transaction-type-income')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ADD INCOME'), findsOneWidget);
  });
}
