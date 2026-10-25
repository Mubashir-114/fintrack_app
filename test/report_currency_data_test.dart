import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/horizon/components/horizon_count_up_text.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/money_formatter.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/report_models.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/repositories/report_repository.dart';
import 'package:frontend/screens/accounts/widgets/money_text.dart';
import 'package:frontend/screens/reports/reports_screen.dart';

class _Repository extends ReportRepository {
  final requests = <String, List<(String?, String?)>>{};
  void record(String endpoint, String? from, String? to) =>
      requests.putIfAbsent(endpoint, () => []).add((from, to));
  @override
  Future<ApiResponse<ReportSummary>> getSummary({
    String? from,
    String? to,
  }) async {
    record('summary', from, to);
    return ApiResponse(
      success: true,
      message: 'Backend summary',
      data: ReportSummary(
        totalIncome: from == null ? 100 : 0,
        totalExpense: 13.10,
        netBalance: from == null ? 86.90 : -13.10,
        savingsRate: 0,
        totalTransactions: 1,
      ),
    );
  }

  @override
  Future<ApiResponse<List<MonthlyReport>>> getMonthly({
    String? from,
    String? to,
  }) async {
    record('monthly', from, to);
    return const ApiResponse(success: true, message: '', data: []);
  }

  @override
  Future<ApiResponse<List<CategoryReport>>> getCategory({
    String? from,
    String? to,
  }) async {
    record('category', from, to);
    return const ApiResponse(
      success: true,
      message: '',
      data: [
        CategoryReport(
          categoryId: 1,
          category: 'Food',
          budget: 20,
          spent: 13.10,
          remaining: 6.90,
          percentage: 65.5,
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<List<TrendsReport>>> getTrends({
    String? from,
    String? to,
  }) async {
    record('trends', from, to);
    return const ApiResponse(
      success: true,
      message: '',
      data: [
        TrendsReport(
          year: 2026,
          month: 10,
          monthName: 'October',
          income: 0,
          expense: 13.10,
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<List<CashflowReport>>> getCashflow({
    String? from,
    String? to,
  }) async {
    record('cashflow', from, to);
    return const ApiResponse(
      success: true,
      message: '',
      data: [
        CashflowReport(
          id: 1,
          title: 'Lunch',
          category: 'Food',
          amount: 13.10,
          type: 'expense',
          date: '2026-10-25',
          runningBalance: -13.10,
        ),
      ],
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'shared formatter preserves exact Dashboard decimals, grouping and signs',
    () {
      expect(MoneyFormatter.format('3486.90'), '₹3,486.90');
      expect(MoneyText.format('-13.10'), MoneyFormatter.format('-13.10'));
      expect(MoneyFormatter.amount(-13.10), '-₹13.10');
      expect(MoneyFormatter.amount(1842850.40), '₹18,42,850.40');
      expect(MoneyFormatter.format('1842850.40', 'USD'), r'$1,842,850.40');
      expect(MoneyFormatter.amount(13.10, showSign: true), '+₹13.10');
    },
  );

  test('saved currency preference survives provider recreation', () async {
    final currency = CurrencyProvider();
    await Future<void>.delayed(Duration.zero);
    expect(currency.currencyCode, 'INR');
    expect(currency.currencySymbol, '₹');
    expect(currency.format(-13.10), '-₹13.10');
    await currency.setCurrency('EUR');
    final restored = CurrencyProvider();
    await Future<void>.delayed(Duration.zero);
    expect(restored.currencyCode, 'EUR');
    expect(restored.format(13.10), '€13.10');
    currency.dispose();
    restored.dispose();
  });

  test(
    'Reports sends the same date scope to every endpoint and preserves All Time',
    () async {
      final repository = _Repository();
      final reports = ReportProvider(repository: repository);
      await reports.loadAllReports();
      expect(reports.summary!.netBalance, 86.90);
      for (final requests in repository.requests.values) {
        expect(requests.single, (null, null));
      }
      reports.setDateRange(
        DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 25),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      for (final requests in repository.requests.values) {
        expect(requests.last, ('2026-10-01', '2026-10-25'));
      }
      expect(
        reports.summary!.netBalance,
        closeTo(
          reports.summary!.totalIncome - reports.summary!.totalExpense,
          0.000001,
        ),
      );
      reports.clearDateRange();
      await Future<void>.delayed(Duration.zero);
      expect(reports.summary!.netBalance, 86.90);
      reports.clearSession();
      expect(reports.summary, isNull);
      expect(reports.selectedDateRange, isNull);
      reports.dispose();
    },
  );

  testWidgets(
    'Dashboard amount and every Reports subtab react to INR and currency changes',
    (tester) async {
      final currency = CurrencyProvider();
      final reports = ReportProvider(repository: _Repository());
      reports.setDateRange(
        DateTimeRange(start: DateTime(2026, 10), end: DateTime(2026, 10, 25)),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: currency),
            ChangeNotifierProvider.value(value: reports),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Column(
              children: [
                const HorizonCountUpAmount(amount: 3486.90, style: TextStyle()),
                const Expanded(child: ReportsScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('₹3,486.90'), findsOneWidget);
      expect(find.text('-₹13.10'), findsOneWidget);
      expect(find.text('Income: ₹0.00'), findsOneWidget);
      expect(find.text('Expense: ₹13.10'), findsOneWidget);
      for (final code in ['INR', 'USD', 'EUR', 'GBP']) {
        await currency.setCurrency(code);
        await tester.pumpAndSettle();
        expect(find.text(currency.format(3486.90)), findsOneWidget);
        for (final tab in ['Trends', 'Categories', 'Cashflow']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .toList();
          expect(
            texts.any((text) => text.contains(currency.format(13.10))),
            true,
            reason: '$code $tab',
          );
          if (code == 'INR') {
            expect(texts.any((text) => text.contains(r'$')), false);
          }
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      currency.dispose();
      reports.dispose();
    },
  );
}
