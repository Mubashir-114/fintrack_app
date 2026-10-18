import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/models/report_models.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/accounts/accounts_list_screen.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';
import 'package:frontend/screens/analytics/widgets/global_fin_overlay.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/profile/appearance_screen.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/profile/security_screen.dart';
import 'package:frontend/screens/reports/reports_screen.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';
import 'dashboard_v2_test.dart' show MockDashboardProvider, MockAuthProvider;
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;
import 'smart_budgets_test.dart' show MockBudgetProvider;

const _transaction = TransactionModel(
  id: 1,
  userId: 1,
  categoryId: 1,
  type: 'expense',
  title: 'Test purchase',
  amount: 25,
  transactionDate: '2026-10-18',
  category: 'Food',
  source: 'manual',
);

class _Accounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'cash',
      subtype: 'wallet',
      isDefault: true,
      displayName: 'Test wallet',
      currencyCode: 'INR',
      openingAmount: '100.00',
      status: 'active',
    ),
  ];
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {}
}

class _Transactions extends TransactionProvider {
  @override
  List<TransactionModel> get transactions => const [_transaction];
  @override
  Future<void> loadTransactions({bool loadMore = false}) async {}
}

class _Reports extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
  @override
  ReportSummary? get summary => const ReportSummary(
    totalIncome: 750,
    totalExpense: 200,
    netBalance: 550,
    savingsRate: 73.3,
    totalTransactions: 1,
  );
  @override
  List<TrendsReport> get trendsReports => const [
    TrendsReport(
      year: 2026,
      month: 9,
      monthName: 'September',
      income: 700,
      expense: 250,
    ),
    TrendsReport(
      year: 2026,
      month: 10,
      monthName: 'October',
      income: 750,
      expense: 200,
    ),
  ];
}

const _screens = <String, Widget>{
  '/dashboard': DashboardScreen(),
  '/transactions': TransactionsListScreen(),
  '/accounts': AccountsListScreen(),
  '/budgets': BudgetsListScreen(),
  '/reports': ReportsScreen(),
  '/analytics': AnalyticsScreen(),
  '/profile': ProfileScreen(),
  '/profile/appearance': AppearanceScreen(),
  '/profile/security': SecurityScreen(),
  '/profile/edit': EditProfileScreen(),
};
final _captureKey = GlobalKey();

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('FIN_LAYOUT_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(
      'build/fin_layout_verification/previews',
    ).create(recursive: true);
    await File(
      'build/fin_layout_verification/previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the SDK's production font metrics, rather than test-only Ahem glyphs.
    final fontDirectory =
        '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}/artifacts/material_fonts';
    final loader = FontLoader('Roboto');
    for (final variant in ['regular', 'medium', 'bold', 'black']) {
      final font = File('$fontDirectory/roboto-$variant.ttf');
      if (await font.exists()) {
        loader.addFont(font.readAsBytes().then(ByteData.sublistView));
      }
    }
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
    CacheService.setUserId(9302);
  });
  for (final width in [320.0, 360.0, 393.0, 600.0, 1024.0]) {
    for (final dark in [true, false]) {
      testWidgets(
        'full-width screen matrix at $width, ${dark ? "dark" : "light"}',
        (tester) async {
          tester.view.physicalSize = Size(width, 852);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final fin = AnalyticsProvider(repository: MockPhase5FRepository());
          final auth = MockAuthProvider()
            ..setMockUser(
              UserModel(id: 1, name: 'Test User', email: 'test@example.test'),
            );
          final dashboard = MockDashboardProvider()
            ..setMockData(
              summary: DashboardSummary.fromJson({
                'overview': {
                  'totalAssets': '100.00',
                  'totalLiabilities': '0.00',
                  'netWorth': '100.00',
                  'monthlyIncome': '750.00',
                  'monthlyExpenses': '200.00',
                  'monthlyNetSavings': '550.00',
                },
              }),
              recent: [_transaction],
            );
          final budgets = MockBudgetProvider()
            ..setMockData(
              progress: BudgetProgressResponseModel.fromJson({
                'month': 10,
                'year': 2026,
                'overall': {
                  'budgetLimit': '1000.00',
                  'spent': '200.00',
                  'remaining': '800.00',
                },
              }),
            );
          final mediaWidths = <String, double>{};
          final router = GoRouter(
            initialLocation: '/dashboard',
            observers: [FinOverlayObserver()],
            routes: [
              ShellRoute(
                observers: [FinOverlayObserver()],
                builder: (_, _, child) => MainNavigationScreen(child: child),
                routes: [
                  for (final entry in _screens.entries)
                    GoRoute(
                      path: entry.key,
                      builder: (context, _) {
                        mediaWidths[entry.key] = MediaQuery.sizeOf(
                          context,
                        ).width;
                        return SizedBox.expand(
                          key: const ValueKey('page_bounds'),
                          child: entry.value,
                        );
                      },
                    ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AnalyticsProvider>.value(value: fin),
                ChangeNotifierProvider<AuthProvider>.value(value: auth),
                ChangeNotifierProvider<DashboardProvider>.value(
                  value: dashboard,
                ),
                ChangeNotifierProvider<AccountProvider>(
                  create: (_) => _Accounts(),
                ),
                ChangeNotifierProvider<TransactionProvider>(
                  create: (_) => _Transactions(),
                ),
                ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
                ChangeNotifierProvider<ReportProvider>(
                  create: (_) => _Reports(),
                ),
                ChangeNotifierProvider<CurrencyProvider>(
                  create: (_) => CurrencyProvider(),
                ),
                ChangeNotifierProvider<ThemeProvider>(
                  create: (_) => ThemeProvider(),
                ),
                ChangeNotifierProvider<SmsProvider>(
                  create: (_) => SmsProvider(),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: RepaintBoundary(key: _captureKey, child: child!),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final path in _screens.keys) {
            await fin.updateCompanionPreferences(
              fin.companionPreferences.copyWith(
                showAcrossApp: true,
                edgePosition: 'right',
              ),
            );
            router.go(path);
            await tester.pumpAndSettle();
            final page = find.byKey(const ValueKey('page_bounds'));
            final original = tester.getRect(page);
            expect(original.right, width, reason: '$path right edge');
            if (width < 600) {
              expect(original.left, 0, reason: '$path left edge');
            }
            expect(
              mediaWidths[path],
              width,
              reason: '$path MediaQuery must retain viewport width',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$path enabled layout',
            );
            if (width == 320 || width == 393) {
              await _capture(
                tester,
                '${path.substring(1).replaceAll('/', '_')}_${width.toInt()}_${dark ? "dark" : "light"}',
              );
            }
            await fin.updateCompanionPreferences(
              fin.companionPreferences.copyWith(showAcrossApp: false),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getRect(page),
              original,
              reason: '$path FIN disabled',
            );
            await fin.updateCompanionPreferences(
              fin.companionPreferences.copyWith(
                showAcrossApp: true,
                edgePosition: 'left',
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.getRect(page), original, reason: '$path FIN on left');
            expect(
              tester.takeException(),
              isNull,
              reason: '$path after toggling FIN',
            );
            final scrolls = find.descendant(
              of: page,
              matching: find.byType(Scrollable),
            );
            for (final element in scrolls.evaluate()) {
              final scroll = element.widget as Scrollable;
              if (scroll.axisDirection != AxisDirection.down) continue;
              final rect = tester.getRect(find.byWidget(scroll));
              expect(
                rect.left,
                greaterThanOrEqualTo(original.left - .1),
                reason: '$path scroll left',
              );
              expect(
                rect.right,
                lessThanOrEqualTo(original.right + .1),
                reason: '$path scroll right',
              );
            }
          }
          router.go('/dashboard');
          await tester.pumpAndSettle();
          final verticalScroll = find
              .descendant(
                of: find.byType(DashboardScreen),
                matching: find.byType(Scrollable),
              )
              .evaluate()
              .where(
                (element) =>
                    (element.widget as Scrollable).axisDirection ==
                    AxisDirection.down,
              )
              .first;
          final scrollFinder = find.byWidget(verticalScroll.widget);
          final position = tester.state<ScrollableState>(scrollFinder).position;
          expect(position.maxScrollExtent, greaterThan(0));
          await tester.drag(scrollFinder, const Offset(0, -120));
          await tester.pumpAndSettle();
          expect(
            position.pixels,
            greaterThan(0),
            reason: 'FIN must preserve page scrolling',
          );
          if (width < 600) {
            expect(tester.getSize(find.byType(NavigationBar)).width, width);
            await tester.tap(find.text('Activity'));
            await tester.pumpAndSettle();
            expect(find.byType(TransactionsListScreen), findsOneWidget);
            expect(
              tester.getRect(find.byKey(const ValueKey('page_bounds'))).width,
              width,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}
