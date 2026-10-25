import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';

/// Supported semantic threshold levels in FinTrack HORIZON Budgets.
enum BudgetThresholdLevel {
  normal,
  watch,
  approachingLimit,
  exceeded;

  static BudgetThresholdLevel fromRatio(double ratio, {bool isExplicitExceeded = false}) {
    if (isExplicitExceeded || ratio >= 1.0) return BudgetThresholdLevel.exceeded;
    if (ratio >= 0.85) return BudgetThresholdLevel.approachingLimit;
    if (ratio >= 0.70) return BudgetThresholdLevel.watch;
    return BudgetThresholdLevel.normal;
  }
}

/// FinTrack HORIZON — Reusable Semantic Budget Status Label.
///
/// Small semantic badge that communicates budget state without screaming colors.
class BudgetStatusLabel extends StatelessWidget {
  const BudgetStatusLabel({
    super.key,
    required this.level,
    this.customText,
  });

  final BudgetThresholdLevel level;
  final String? customText;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    Color color;
    String text;

    switch (level) {
      case BudgetThresholdLevel.exceeded:
        color = tokens.outflow;
        text = customText ?? "EXCEEDED";
        break;
      case BudgetThresholdLevel.approachingLimit:
        color = tokens.warning;
        text = customText ?? "APPROACHING LIMIT";
        break;
      case BudgetThresholdLevel.watch:
        color = tokens.warning;
        text = customText ?? "WATCH";
        break;
      case BudgetThresholdLevel.normal:
        color = tokens.surplus;
        text = customText ?? "ON TRACK";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HorizonDimensions.radiusSM),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: HorizonTypography.labelCaps.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
