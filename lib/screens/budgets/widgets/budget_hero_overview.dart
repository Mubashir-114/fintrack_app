import 'package:flutter/material.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';
import 'monthly_budget_hero.dart';

export 'monthly_budget_hero.dart';

/// Legacy export wrapper forwarding to the redesigned [MonthlyBudgetHero].
class BudgetHeroOverview extends StatelessWidget {
  const BudgetHeroOverview({
    super.key,
    required this.overall,
    required this.period,
    required this.currency,
  });

  final BudgetOverallProgressModel overall;
  final BudgetPeriodModel period;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    return MonthlyBudgetHero(
      overall: overall,
      period: period,
      currency: currency,
    );
  }
}
