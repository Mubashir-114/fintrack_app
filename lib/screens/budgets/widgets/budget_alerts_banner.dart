import 'package:flutter/material.dart';
import '../../../models/budget_model.dart';
import 'budget_alert_summary.dart';

export 'budget_alert_summary.dart';

/// Legacy export wrapper forwarding to the redesigned [BudgetAlertSummary].
class BudgetAlertsBanner extends StatelessWidget {
  const BudgetAlertsBanner({super.key, required this.alerts});

  final BudgetAlertsResponseModel alerts;

  @override
  Widget build(BuildContext context) {
    return BudgetAlertSummary(alerts: alerts);
  }
}
