import 'package:flutter/material.dart';
import '../../../core/horizon/horizon.dart';
import '../../../models/transaction_model.dart';

bool ledgerIsInflow(TransactionModel transaction) =>
    transaction.type == 'income' || transaction.type == 'transfer_in';

class LedgerCashFlowSummary extends StatelessWidget {
  const LedgerCashFlowSummary({
    super.key,
    required this.transactions,
    this.compact = false,
  });
  final List<TransactionModel> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    // Preserve the Ledger's calculation and scope: the records currently loaded.
    final income = transactions
        .where(ledgerIsInflow)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expense = transactions
        .where((tx) => !ledgerIsInflow(tx))
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final net = income - expense;
    final volume = income.abs() + expense.abs();
    final proportion = volume == 0 ? 0.0 : income.abs() / volume;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? HorizonDimensions.spaceMD
            : HorizonDimensions.spaceLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Cash flow',
                  style: HorizonTypography.headlineSm.copyWith(
                    color: tokens.textHigh,
                  ),
                ),
              ),
              const SizedBox(width: HorizonDimensions.spaceSM),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${transactions.length} loaded',
                    textAlign: TextAlign.end,
                    style: HorizonTypography.bodySm.copyWith(
                      color: tokens.textMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: compact
                ? HorizonDimensions.spaceSM
                : HorizonDimensions.spaceLG,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final amountStyle =
                  constraints.maxWidth < HorizonDimensions.compactActionsWidth
                  ? HorizonTypography.tabularAmountSm
                  : HorizonTypography.tabularAmountMd;
              double measure(double amount) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: HorizonFormatters.formatInr(amount),
                    style: amountStyle,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              final columnWidth =
                  (constraints.maxWidth - HorizonDimensions.spaceMD) / 2;
              final stacked =
                  MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                  measure(income) > columnWidth ||
                  measure(expense) > columnWidth;
              final values = [
                _FlowValue(
                  label: 'Income',
                  amount: income,
                  color: income >= 0 ? tokens.surplus : tokens.outflow,
                  amountStyle: amountStyle,
                ),
                _FlowValue(
                  label: 'Expenses',
                  amount: expense,
                  color: expense >= 0 ? tokens.outflow : tokens.surplus,
                  amountStyle: amountStyle,
                ),
              ];
              return stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        values.first,
                        const SizedBox(height: HorizonDimensions.spaceMD),
                        values.last,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: values.first),
                        const SizedBox(width: HorizonDimensions.spaceMD),
                        Expanded(child: values.last),
                      ],
                    );
            },
          ),
          const SizedBox(height: HorizonDimensions.spaceMD),
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: proportion),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : HorizonMotion.quick,
              builder: (context, value, _) => SizedBox(
                height: HorizonDimensions.spaceXS,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: volume == 0
                              ? tokens.divider
                              : tokens.outflow.withValues(alpha: 0.5),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: constraints.maxWidth * value,
                          height: HorizonDimensions.spaceXS,
                          child: ColoredBox(
                            color: tokens.surplus.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceMD),
          LayoutBuilder(
            builder: (context, constraints) {
              final label = Text(
                'Net cash flow',
                style: HorizonTypography.bodySm.copyWith(
                  color: tokens.textMedium,
                ),
              );
              final amount = Text(
                HorizonFormatters.formatInr(net, showSign: true),
                key: const ValueKey('ledger-net'),
                style: HorizonTypography.tabularAmountMd.copyWith(
                  color: net >= 0 ? tokens.surplus : tokens.outflow,
                ),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: HorizonDimensions.spaceXS),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: amount,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: HorizonDimensions.spaceSM),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: amount,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FlowValue extends StatelessWidget {
  const _FlowValue({
    required this.label,
    required this.amount,
    required this.color,
    required this.amountStyle,
  });
  final String label;
  final double amount;
  final Color color;
  final TextStyle amountStyle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: HorizonTypography.bodySm.copyWith(
          color: HorizonThemeTokens.of(context).textMedium,
        ),
      ),
      const SizedBox(height: HorizonDimensions.spaceXS),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          HorizonFormatters.formatInr(amount),
          style: amountStyle.copyWith(color: color),
        ),
      ),
    ],
  );
}
