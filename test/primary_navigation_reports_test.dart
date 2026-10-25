import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/floating_bottom_navigation.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/report_models.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/primary_page_view.dart';
import 'package:frontend/screens/reports/reports_screen.dart';
import 'package:frontend/screens/reports/widgets/trends_tab_view.dart';
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;

const _paths = ['/dashboard', '/ledger', '/budgets', '/reports', '/profile'];
const _names = ['Home', 'Ledger', 'Budgets', 'Reports', 'Profile'];

class _Reports extends ReportProvider {
  int loads = 0;
  @override
  Future<void> loadAllReports() async => loads++;
  @override
  ReportSummary get summary => const ReportSummary(
    totalIncome: 0,
    totalExpense: 13.10,
    netBalance: -13.10,
    savingsRate: 0,
    totalTransactions: 1,
  );
  @override
  List<TrendsReport> get trendsReports => const [
    TrendsReport(
      year: 2026,
      month: 10,
      monthName: 'October',
      income: 0,
      expense: 13.10,
    ),
  ];
  @override
  List<CategoryReport> get categoryReports => const [
    CategoryReport(
      categoryId: 1,
      category: 'Food',
      budget: 20,
      spent: 13.10,
      remaining: 6.90,
      percentage: 65.5,
    ),
  ];
  @override
  List<CashflowReport> get cashflowReports => const [
    CashflowReport(
      id: 1,
      title: 'Lunch',
      category: 'Food',
      amount: 13.10,
      type: 'expense',
      date: '2026-10-25',
      runningBalance: -13.10,
    ),
  ];
}

class _Harness {
  final reports = _Reports();
  final currency = CurrencyProvider();
  final builds = List.filled(5, 0);
  late final analytics = AnalyticsProvider(
    repository: MockPhase5FRepository()
      ..mockPreferences = const ApiResponse(
        success: true,
        message: 'OK',
        data: CompanionPreferences(showAcrossApp: false),
      ),
  );
  late final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (_, _, child) => MainNavigationScreen(
          primaryDestinations: List.generate(
            5,
            (index) => (context) {
              builds[index]++;
              return index == 3
                  ? const ReportsScreen()
                  : Scaffold(
                      body: ListView(
                        children: [
                          SizedBox(
                            height: 500,
                            child: Center(child: Text('Page ${_names[index]}')),
                          ),
                          TextButton(
                            onPressed: () => context.push('/details'),
                            child: const Text('Details'),
                          ),
                          const SizedBox(height: 1000),
                        ],
                      ),
                    );
            },
          ),
          child: child,
        ),
        routes: [
          for (final path in _paths)
            GoRoute(
              path: path,
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SizedBox.shrink(),
              ),
            ),
          GoRoute(
            path: '/details',
            builder: (_, _) => const Scaffold(body: Text('Deeper screen')),
          ),
        ],
      ),
    ],
  );

  Widget get app => MultiProvider(
    providers: [
      ChangeNotifierProvider<AnalyticsProvider>.value(value: analytics),
      ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
      ChangeNotifierProvider<ReportProvider>.value(value: reports),
    ],
    child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    analytics.dispose();
    currency.dispose();
    reports.dispose();
  }
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.dragFrom(const Offset(200, 210), Offset(dx, 0));
  await tester.pumpAndSettle();
}

void _expectIndex(WidgetTester tester, _Harness harness, int index) {
  expect(harness.router.routeInformationProvider.value.uri.path, _paths[index]);
  final pager = tester.widget<PageView>(
    find.byKey(const ValueKey('primary_page_view')),
  );
  expect(pager.controller!.page, closeTo(index.toDouble(), 0.001));
  final dock = find.byType(FloatingBottomNavigation);
  if (dock.evaluate().isNotEmpty) {
    expect(tester.widget<FloatingBottomNavigation>(dock).selectedIndex, index);
  } else {
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      index,
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<_Harness> start(WidgetTester tester, [double width = 393]) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = _Harness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    addTearDown(() => harness.dispose(tester));
    return harness;
  }

  testWidgets(
    'dock opens Reports without initializing intermediate destinations',
    (tester) async {
      final harness = await start(tester);
      expect(harness.builds, [1, 0, 0, 0, 0]);
      await tester.tap(
        find.byKey(const ValueKey('floating_navigation_reports')),
      );
      await tester.pumpAndSettle();
      _expectIndex(tester, harness, 3);
      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text('-₹13.10'), findsOneWidget);
      expect(harness.builds, [1, 0, 0, 1, 0]);
      expect(harness.reports.loads, 1);
    },
  );

  testWidgets('Home to Ledger and back synchronize dock and page', (
    tester,
  ) async {
    final harness = await start(tester);
    await _swipe(tester, -310);
    _expectIndex(tester, harness, 1);
    await _swipe(tester, 310);
    _expectIndex(tester, harness, 0);
    expect(harness.builds, [1, 1, 0, 0, 0]);
  });

  testWidgets(
    'all five pages synchronize in both directions with one load per visit',
    (tester) async {
      final harness = await start(tester);
      for (var i = 1; i < 5; i++) {
        await _swipe(tester, -310);
        _expectIndex(tester, harness, i);
      }
      for (var i = 3; i >= 0; i--) {
        await _swipe(tester, 310);
        _expectIndex(tester, harness, i);
      }
      expect(harness.builds, [1, 1, 1, 1, 1]);
      expect(harness.reports.loads, 1);
    },
  );

  testWidgets(
    'Reports keeps subtab, range and scroll state through main-page swipes',
    (tester) async {
      final harness = await start(tester);
      harness.router.go('/reports');
      await tester.pumpAndSettle();
      final range = DateTimeRange(
        start: DateTime(2026, 10),
        end: DateTime(2026, 10, 25),
      );
      harness.reports.setDateRange(range);
      await tester.pump();
      final trendsScrollable = find
          .descendant(
            of: find.byType(TrendsTabView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(trendsScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
      final offset = tester
          .state<ScrollableState>(trendsScrollable)
          .position
          .pixels;
      expect(offset, greaterThan(0));
      await tester.tap(find.text('Cashflow'));
      await tester.pumpAndSettle();
      final tabController = tester
          .widget<TabBar>(find.byType(TabBar))
          .controller!;
      await _swipe(tester, -310);
      _expectIndex(tester, harness, 4);
      await _swipe(tester, 310);
      _expectIndex(tester, harness, 3);
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller,
        same(tabController),
      );
      expect(tabController.index, 2);
      expect(harness.reports.selectedDateRange, range);
      expect(
        harness.reports.loads,
        2,
      ); // Initial load and explicit range change only.
      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(trendsScrollable).position.pixels,
        closeTo(offset, 0.1),
      );
    },
  );

  testWidgets('secondary primary tab handles Android back by returning Home', (
    tester,
  ) async {
    final harness = await start(tester);
    await _swipe(tester, -310);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectIndex(tester, harness, 0);
    expect(harness.router.canPop(), false);
  });

  testWidgets('deep routes pop normally and retain the main page', (
    tester,
  ) async {
    final harness = await start(tester);
    await _swipe(tester, -310);
    harness.router.push('/details');
    await tester.pumpAndSettle();
    expect(find.text('Deeper screen'), findsOneWidget);
    expect(find.byType(PrimaryPageView), findsNothing);
    harness.router.pop();
    await tester.pumpAndSettle();
    _expectIndex(tester, harness, 1);
    expect(harness.builds, [1, 1, 0, 0, 0]);
  });

  for (final width in [320.0, 360.0, 393.0, 600.0]) {
    testWidgets('main navigation and Reports subtabs fit width $width', (
      tester,
    ) async {
      final harness = await start(tester, width);
      for (var i = 0; i < 5; i++) {
        harness.router.go(_paths[i]);
        await tester.pumpAndSettle();
        _expectIndex(tester, harness, i);
        if (i == 3) {
          for (final tab in ['Categories', 'Cashflow', 'Trends']) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      }
    });
  }
}
