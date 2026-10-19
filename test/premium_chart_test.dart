import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'dashboard_v2_test.dart' show MockAuthProvider, MockDashboardProvider;

void main() {
  testWidgets(
    'monthly chart retains the INR unit and exposes exact source values',
    (tester) async {
      final dashboard = MockDashboardProvider()
        ..setMockData(
          summary: DashboardSummary.fromJson({
            'overview': {
              'monthlyIncome': '6000.00',
              'monthlyExpenses': '800.00',
            },
          }),
          monthly: const [
            MonthlySummary(month: '2026-10', income: 6000, expense: 800),
          ],
        );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => MockAuthProvider(),
            ),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<SmsProvider>(create: (_) => SmsProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cash-flow trend'));
      await tester.tap(find.text('Cash-flow trend'));
      await tester.pumpAndSettle();
      expect(find.text('\u20B90', skipOffstage: false), findsOneWidget);
      expect(find.text('?0', skipOffstage: false), findsNothing);
      final description = find.bySemanticsLabel(
        RegExp(
          r'Monthly income and expenses, zero baseline.*2026-10: income.*6,000.00, expense.*800.00',
        ),
      );
      expect(description, findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      dashboard.dispose();
    },
  );
}
