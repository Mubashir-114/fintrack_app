import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Give charts a complete textual equivalent for assistive technology.
class FinancialChart extends StatelessWidget {
  const FinancialChart({
    super.key,
    required this.description,
    required this.child,
  });
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: description,
    child: RepaintBoundary(child: child),
  );
}

/// Exact proportions: a zero amount gets no painted share, and no data is neutral.
class FinancialFlowBar extends StatelessWidget {
  const FinancialFlowBar({
    super.key,
    required this.income,
    required this.expense,
  });
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = income + expense;
    final share = total > 0 ? (income / total).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: total > 0
          ? 'Share of total flow: income ${(share * 100).toStringAsFixed(1)} percent, expense ${((1 - share) * 100).toStringAsFixed(1)} percent'
          : 'No recorded income or expense',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 6,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: colors.divider)),
                if (total > 0) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * share,
                    child: ColoredBox(color: colors.success),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * (1 - share),
                    child: ColoredBox(color: colors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keep a comparison's full monetary label above its proportional track.
class FinancialComparisonRow extends StatelessWidget {
  const FinancialComparisonRow({
    super.key,
    required this.label,
    required this.amount,
    required this.share,
    required this.color,
  });
  final String label;
  final String amount;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            Text(
              amount,
              softWrap: false,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$label share of total cash flow',
          value: '${(share * 100).toStringAsFixed(1)} percent',
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: colors.divider,
            ),
          ),
        ),
      ],
    );
  }
}
