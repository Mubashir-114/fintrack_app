import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/floating_bottom_navigation.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/ledger/ledger_screen.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/screens/reports/reports_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;

class _Auth extends AuthProvider {
  @override
  bool get isLoggedIn => true;
  @override
  UserModel get currentUser =>
      const UserModel(id: 1, name: 'Tester', email: 'test@example.test');
}

class _Dashboard extends DashboardProvider {
  int loads = 0;
  @override
  Future<void> loadDashboardData() async {
    loads++;
  }
}

class _Ledger extends TransactionProvider {
  int loads = 0;
  @override
  Future<void> loadTransactions({bool loadMore = false}) async {
    loads++;
  }
}

class _Budgets extends BudgetProvider {
  int loads = 0;
  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    loads++;
  }

  @override
  Future<void> loadBudgetAlerts() async {}
}

class _Reports extends ReportProvider {
  int loads = 0;
  @override
  Future<void> loadAllReports() async {
    loads++;
  }
}

void main() {
  testWidgets(
    'production router swipes real pages without duplicate initial data loads',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _Auth();
      final dashboard = _Dashboard();
      final ledger = _Ledger();
      final budgets = _Budgets();
      final reports = _Reports();
      final currency = CurrencyProvider();
      final analytics = AnalyticsProvider(
        repository: MockPhase5FRepository()
          ..mockPreferences = const ApiResponse(
            success: true,
            message: '',
            data: CompanionPreferences(showAcrossApp: false),
          ),
      );
      appRouter.go('/dashboard');
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<TransactionProvider>.value(value: ledger),
            ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
            ChangeNotifierProvider<ReportProvider>.value(value: reports),
            ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
            ChangeNotifierProvider<AnalyticsProvider>.value(value: analytics),
          ],
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        [dashboard.loads, ledger.loads, budgets.loads, reports.loads],
        [1, 0, 0, 0],
      );
      final types = [
        DashboardScreen,
        LedgerScreen,
        BudgetsListScreen,
        ReportsScreen,
        ProfileScreen,
      ];
      for (final direction in [-1, 1]) {
        for (var step = 1; step <= 4; step++) {
          // Header area avoids any chart's intentional horizontal interaction.
          await tester.dragFrom(
            const Offset(210, 65),
            Offset(direction * 310.0, 0),
          );
          await tester.pumpAndSettle();
          final index = direction == -1 ? step : 4 - step;
          expect(find.byType(types[index]).hitTestable(), findsOneWidget);
          expect(
            tester
                .widget<FloatingBottomNavigation>(
                  find.byType(FloatingBottomNavigation),
                )
                .selectedIndex,
            index,
          );
          expect(tester.takeException(), isNull);
        }
      }
      expect(
        [dashboard.loads, ledger.loads, budgets.loads, reports.loads],
        [1, 1, 1, 1],
      );
      await tester.pumpWidget(const SizedBox.shrink());
      appRouter.dispose();
      for (final provider in [
        auth,
        dashboard,
        ledger,
        budgets,
        reports,
        currency,
        analytics,
      ]) {
        provider.dispose();
      }
    },
  );
}
