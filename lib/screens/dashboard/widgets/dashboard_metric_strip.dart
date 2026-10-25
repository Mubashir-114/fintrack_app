import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';

/// Income / expense / savings summary presented as an open strip.
///
/// Delegates to the reusable [HorizonMetricStrip] so the dashboard and the
/// money storage summary share one hairline-separated metric language.
class DashboardMetricStrip extends StatelessWidget {
  const DashboardMetricStrip({
    super.key,
    required this.income,
    required this.expense,
    required this.savings,
  });

  final double income;
  final double expense;
  final double savings;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return HorizonMetricStrip(
      metrics: [
        HorizonMetric(label: 'Income', value: income, accent: tokens.surplus),
        HorizonMetric(
          label: 'Expenses',
          value: expense,
          accent: tokens.outflow,
        ),
        HorizonMetric(label: 'Savings', value: savings, accent: tokens.ionCyan),
      ],
    );
  }
}
