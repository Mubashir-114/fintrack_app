import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/floating_bottom_navigation.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/ledger/ledger_screen.dart';
import 'package:frontend/screens/ledger/widgets/ledger_cash_flow_summary.dart';
import 'package:frontend/screens/ledger/widgets/ledger_transaction_row.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';
import 'support/ledger_fixture.dart';

Future<void> pumpLedger(
  WidgetTester tester,
  LedgerFixtureProvider provider, {
  Size size = const Size(393, 852),
  double scale = 1,
  ThemeCollection collection = ThemeCollection.midnightAurora,
  Brightness brightness = Brightness.dark,
  bool reduceMotion = true,
  double keyboard = 0,
  bool dock = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionProvider>.value(value: provider),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.buildTheme(collection, brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
            viewInsets: EdgeInsets.only(bottom: keyboard),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: const LedgerScreen(),
          bottomNavigationBar: dock && size.width < 600 && keyboard == 0
              ? FloatingBottomNavigation(
                  selectedIndex: 1,
                  onDestinationSelected: (_) {},
                )
              : null,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets(
    'single title, truthful totals, open rows and aligned amount column',
    (tester) async {
      final provider = LedgerFixtureProvider();
      await pumpLedger(tester, provider);
      expect(
        find.text('Ledger'),
        findsNWidgets(2),
      ); // Screen and unchanged dock.
      expect(find.text('October 2026 · 5 transactions'), findsOneWidget);
      expect(find.text('Records Deck'), findsNothing);
      expect(find.byType(HorizonSurface), findsNothing);
      expect(find.text('5 loaded'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('ledger-net'))).data,
        '+₹2,92,820.00',
      );
      final dayAmount = tester.getRect(find.text('+₹2,08,800.00'));
      final taxiAmount = tester.getRect(find.text('-₹1,200.00'));
      final salaryAmount = tester.getRect(find.text('+₹2,10,000.00'));
      expect(dayAmount.right, closeTo(taxiAmount.right, 1));
      expect(taxiAmount.right, closeTo(salaryAmount.right, 1));
      expect(find.byType(LedgerMetadata), findsWidgets);
    },
  );

  testWidgets('income and expense filters update rows and totals; All resets', (
    tester,
  ) async {
    final provider = LedgerFixtureProvider();
    await pumpLedger(tester, provider);
    await tester.tap(find.byKey(const ValueKey('ledger-filter-income')));
    await tester.pumpAndSettle();
    expect(provider.selectedType, 'income');
    expect(find.text('October 2026 · 2 transactions'), findsOneWidget);
    expect(find.text('Taxi'), findsNothing);
    expect(find.text('Salary'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('ledger-net'))).data,
      '+₹2,95,000.00',
    );
    await tester.tap(find.byKey(const ValueKey('ledger-filter-expense')));
    await tester.pumpAndSettle();
    expect(provider.selectedType, 'expense');
    expect(find.text('Salary'), findsNothing);
    expect(find.text('Taxi'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('ledger-net'))).data,
      '-₹2,180.00',
    );
    await tester.tap(find.byKey(const ValueKey('ledger-filter-all')));
    await tester.pumpAndSettle();
    expect(provider.selectedType, isNull);
    expect(find.text('October 2026 · 5 transactions'), findsOneWidget);
  });

  testWidgets(
    'search debounces, finds account metadata, and clear restores records',
    (tester) async {
      final provider = LedgerFixtureProvider();
      await pumpLedger(tester, provider);
      await tester.enterText(
        find.byKey(const ValueKey('ledger-search')),
        'Room Rental',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(provider.searchQuery, isNull);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(provider.searchQuery, 'Room Rental');
      expect(find.text('October 2026 · 1 transaction'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ledger-search-clear')));
      await tester.pumpAndSettle();
      expect(provider.searchQuery, isNull);
      expect(provider.transactions.length, 5);
    },
  );

  testWidgets('reset cancels a pending debounced search', (tester) async {
    final provider = LedgerFixtureProvider();
    await pumpLedger(tester, provider);
    await tester.enterText(find.byKey(const ValueKey('ledger-search')), 'Taxi');
    await tester.tap(find.byKey(const ValueKey('ledger-filter-all')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(provider.searchQuery, isNull);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ledger-search')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('date picker result reaches provider and filters the journal', (
    tester,
  ) async {
    final provider = LedgerFixtureProvider();
    await pumpLedger(tester, provider);
    await tester.tap(find.byKey(const ValueKey('ledger-filter-date')));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    final pickerContext = tester.element(find.byType(DateRangePickerDialog));
    Navigator.of(pickerContext).pop(
      DateTimeRange(start: DateTime(2026, 10, 24), end: DateTime(2026, 10, 24)),
    );
    await tester.pumpAndSettle();
    expect(provider.selectedDateRange!.start, DateTime(2026, 10, 24));
    expect(provider.transactions.length, 2);
    expect(
      find.text('24 Oct 2026 – 24 Oct 2026 · 2 transactions'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('ledger-filter-all')));
    await tester.pumpAndSettle();
    expect(provider.selectedDateRange, isNull);
  });

  testWidgets('empty results provide filter recovery', (tester) async {
    final provider = LedgerFixtureProvider();
    await pumpLedger(tester, provider);
    await tester.enterText(
      find.byKey(const ValueKey('ledger-search')),
      'no such merchant',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('No matching transactions'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(provider.transactions.length, 5);
    expect(find.text('No matching transactions'), findsNothing);
  });

  testWidgets('first use and full error states offer the appropriate action', (
    tester,
  ) async {
    await pumpLedger(tester, LedgerFixtureProvider(records: []));
    expect(find.text('Your ledger starts here'), findsOneWidget);
    final provider = LedgerFixtureProvider(
      records: [],
      failure: 'Sensitive server exception',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpLedger(tester, provider);
    expect(find.text('Ledger unavailable'), findsOneWidget);
    expect(find.textContaining('0 transactions'), findsNothing);
    expect(find.textContaining('Sensitive'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(provider.refreshes, 1);
  });

  testWidgets('loading and refresh failure retain intentional states', (
    tester,
  ) async {
    final provider = LedgerFixtureProvider(records: [], loading: true);
    await pumpLedger(tester, provider);
    expect(find.byType(HorizonSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpLedger(tester, LedgerFixtureProvider(failure: 'offline'));
    expect(find.text('Couldn’t refresh transactions'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('ledger-scroll')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('refresh and pagination retain their provider callbacks', (
    tester,
  ) async {
    final provider = LedgerFixtureProvider(more: true);
    await pumpLedger(tester, provider);
    await tester.drag(
      find.byKey(const ValueKey('ledger-scroll')),
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(provider.refreshes, greaterThan(0));
    await tester.drag(
      find.byKey(const ValueKey('ledger-scroll')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(provider.pageRequests, greaterThan(0));
    provider.pageRequests = 0;
    provider.loadingMore = true;
    provider.setType(null);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('ledger-scroll')),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(provider.pageRequests, 0);
    expect(find.text('Loading more transactions'), findsOneWidget);
  });

  testWidgets('last row and add action clear each other and the actual dock', (
    tester,
  ) async {
    await pumpLedger(tester, LedgerFixtureProvider());
    await tester.drag(
      find.byKey(const ValueKey('ledger-scroll')),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    final lastRow = tester.getRect(
      find.byKey(const ValueKey('ledger-transaction-5')),
    );
    final action = tester.getRect(
      find.byKey(const ValueKey('ledger-add-transaction')),
    );
    final dock = tester.getRect(find.byType(FloatingBottomNavigation));
    expect(lastRow.bottom, lessThanOrEqualTo(action.top));
    expect(action.bottom, lessThanOrEqualTo(dock.top));
    expect(action.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
    'add/edit sheet receives transaction and refreshes after dismissal',
    (tester) async {
      final provider = LedgerFixtureProvider();
      await pumpLedger(tester, provider);
      await tester.tap(find.byKey(const ValueKey('ledger-add-transaction')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<AddEditTransactionSheet>(
              find.byType(AddEditTransactionSheet),
            )
            .transaction,
        isNull,
      );
      Navigator.of(tester.element(find.byType(AddEditTransactionSheet))).pop();
      await tester.pumpAndSettle();
      expect(provider.refreshes, 1);
      await tester.tap(find.byKey(const ValueKey('ledger-transaction-1')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<AddEditTransactionSheet>(
              find.byType(AddEditTransactionSheet),
            )
            .transaction!
            .id,
        1,
      );
      Navigator.of(tester.element(find.byType(AddEditTransactionSheet))).pop();
      await tester.pumpAndSettle();
      expect(provider.refreshes, 2);
    },
  );

  testWidgets('existing manage and SMS routes remain available', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/ledger',
      routes: [
        GoRoute(path: '/ledger', builder: (_, _) => const LedgerScreen()),
        GoRoute(
          path: '/transactions',
          builder: (_, _) =>
              const Scaffold(body: Text('Management destination')),
        ),
        GoRoute(
          path: '/sms-import',
          builder: (_, _) => const Scaffold(body: Text('SMS destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<TransactionProvider>.value(
        value: LedgerFixtureProvider(),
        child: MaterialApp.router(
          routerConfig: router,
          theme: HorizonTheme.darkTheme,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ledger-manage')));
    await tester.pumpAndSettle();
    expect(find.text('Management destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ledger-import')));
    await tester.pumpAndSettle();
    expect(find.text('SMS destination'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(393, 852),
    const Size(600, 960),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long names, signed amounts and scroll at $size, scale $scale', (
        tester,
      ) async {
        final provider = LedgerFixtureProvider(
          records: [
            ledgerRecords.first.copyWith(
              title:
                  'An exceptionally long merchant name with a payment reference',
              accountName:
                  'Shared Household International Current Account with a long name',
              amount: 123456789.99,
            ),
            ledgerRecords[1].copyWith(amount: -98765.43),
          ],
        );
        await pumpLedger(tester, provider, size: size, scale: scale);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byKey(const ValueKey('ledger-scroll')),
          const Offset(0, -1600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('ledger-transaction-2')),
            matching: find.text('-₹98,765.43'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('--₹'), findsNothing);
        expect(
          tester.getSize(find.byKey(const ValueKey('ledger-scroll'))).width,
          lessThanOrEqualTo(760),
        );
      });
    }
  }

  for (final collection in ThemeCollection.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${collection.name} ${brightness.name} financial contrast and large text',
        (tester) async {
          final theme = AppTheme.buildTheme(collection, brightness);
          final tokens = theme.extension<HorizonThemeTokens>()!;
          for (final color in [
            tokens.textHigh,
            tokens.textMedium,
            tokens.surplus,
            tokens.outflow,
          ]) {
            final l1 = color.computeLuminance(),
                l2 = tokens.canvas.computeLuminance();
            final contrast =
                ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
            expect(
              contrast,
              greaterThanOrEqualTo(4.5),
              reason: 'Ledger text on canvas',
            );
          }
          await pumpLedger(
            tester,
            LedgerFixtureProvider(),
            collection: collection,
            brightness: brightness,
            scale: 2,
          );
          await tester.drag(
            find.byKey(const ValueKey('ledger-scroll')),
            const Offset(0, -1300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'filter motion is bounded, interruptible, and disabled for reduced motion',
    (tester) async {
      final provider = LedgerFixtureProvider();
      await pumpLedger(tester, provider, reduceMotion: false);
      await tester.tap(find.byKey(const ValueKey('ledger-filter-income')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('ledger-filter-expense')));
      await tester.pumpAndSettle();
      expect(provider.selectedType, 'expense');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpLedger(
        tester,
        LedgerFixtureProvider(),
        scale: 2,
        keyboard: 240,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('ledger-add-transaction')))
            .bottom,
        lessThanOrEqualTo(852 - 240),
      );
      final summary = find.byType(LedgerCashFlowSummary);
      expect(summary, findsOneWidget);
      final animations = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('ledger-filter-income')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        animations.every((widget) => widget.duration == Duration.zero),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
