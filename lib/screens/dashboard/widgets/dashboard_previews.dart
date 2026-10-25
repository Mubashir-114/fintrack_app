import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_collection.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/transaction_model.dart';
import 'dashboard_account_row.dart';
import 'dashboard_category_row.dart';
import 'dashboard_fin_insight.dart';
import 'dashboard_hero.dart';
import 'dashboard_recent_row.dart';

Widget _previewSurface(
  Widget child, {
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

const _overview = FinancialOverview(
  totalAssets: '500000.00',
  totalLiabilities: '120000.00',
  netWorth: '380000.00',
  monthlyIncome: '84500.00',
  monthlyExpenses: '32400.00',
  monthlyNetSavings: '52100.00',
  savingsRate: '61.6',
  incomeChangePercent: '+12.0',
);

@Preview(
  name: 'Dashboard hero — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 520),
  brightness: Brightness.dark,
)
Widget dashboardHeroPreview() => _previewSurface(
  DashboardHero(
    overview: _overview,
    sparkValues: const [4, 9, 6, 12, 8, 15, 11, 18],
    flowCaption: 'Daily recorded flow',
    onShowCashFlow: () {},
  ),
);

@Preview(
  name: 'Dashboard hero — Light',
  group: 'FinTrack // HORIZON',
  size: Size(393, 520),
  brightness: Brightness.light,
)
Widget dashboardHeroLightPreview() => _previewSurface(
  DashboardHero(
    overview: _overview,
    sparkValues: const [4, 9, 6, 12, 8, 15, 11, 18],
    flowCaption: 'Daily recorded flow',
    onShowCashFlow: () {},
  ),
  brightness: Brightness.light,
);

@Preview(
  name: 'FIN insight row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 110),
  brightness: Brightness.dark,
)
Widget dashboardFinInsightPreview() => _previewSurface(
  DashboardFinInsight(
    message: 'Groceries was your highest expense category this month.',
    onTap: () {},
  ),
);

@Preview(
  name: 'Account row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 130),
  brightness: Brightness.dark,
)
Widget dashboardAccountRowPreview() => _previewSurface(
  DashboardAccountRow(
    account: const DashboardAccountItem(
      id: 1,
      displayName: 'HDFC Priority Checking',
      type: 'bank',
      subtype: 'savings',
      currentBalance: '124580.00',
      isDefault: true,
    ),
    onTap: () {},
  ),
);

@Preview(
  name: 'Category row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 130),
  brightness: Brightness.dark,
)
Widget dashboardCategoryRowPreview() => _previewSurface(
  const DashboardCategoryRow(
    category: CategorySummary(
      id: 5,
      name: 'Groceries',
      total: 6000,
      totalString: '6000.00',
      percentage: '75.0',
    ),
  ),
);

@Preview(
  name: 'Recent transaction row — Dark',
  group: 'FinTrack // HORIZON',
  size: Size(393, 120),
  brightness: Brightness.dark,
)
Widget dashboardRecentRowPreview() => _previewSurface(
  DashboardRecentRow(
    transaction: const TransactionModel(
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
    dateString: 'Oct 05, 2026',
    onTap: () {},
  ),
);
