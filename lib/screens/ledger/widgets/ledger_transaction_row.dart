import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/transaction_model.dart';
import 'ledger_cash_flow_summary.dart';

class LedgerDateHeader extends StatelessWidget {
  const LedgerDateHeader({super.key, required this.date, required this.net});
  final String date;
  final double net;
  String get _label {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final relative = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : DateFormat('EEEE').format(parsed);
    return '$relative · ${DateFormat('d MMM').format(parsed)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final label = Text(
      _label,
      style: HorizonTypography.bodySm.copyWith(
        color: tokens.textMedium,
        fontWeight: FontWeight.w600,
      ),
    );
    final amount = Text(
      HorizonFormatters.formatInr(net, showSign: true),
      style: HorizonTypography.tabularAmountSm.copyWith(
        color: net >= 0 ? tokens.surplus : tokens.outflow,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: HorizonDimensions.spaceLG,
        bottom: HorizonDimensions.spaceSM,
      ),
      child: MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: HorizonDimensions.spaceXS),
                Align(alignment: Alignment.centerRight, child: amount),
              ],
            )
          : Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: HorizonDimensions.spaceSM),
                Flexible(
                  child: Align(alignment: Alignment.centerRight, child: amount),
                ),
              ],
            ),
    );
  }
}

class LedgerTransactionIcon extends StatelessWidget {
  const LedgerTransactionIcon({super.key, required this.transaction});
  final TransactionModel transaction;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final tint = ledgerIsInflow(transaction)
        ? tokens.surplus
        : tokens.textMedium;
    return ExcludeSemantics(
      child: Container(
        width: HorizonDimensions.spaceXL + HorizonDimensions.spaceXS,
        height: HorizonDimensions.spaceXL + HorizonDimensions.spaceXS,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getCategoryIcon(transaction.category),
          color: tint,
          size: HorizonDimensions.spaceLG,
        ),
      ),
    );
  }
}

class LedgerMetadata extends StatelessWidget {
  const LedgerMetadata({super.key, required this.transaction});
  final TransactionModel transaction;
  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final account = transaction.accountName?.trim();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: transaction.category),
          if (account != null &&
              account.isNotEmpty &&
              account != transaction.category)
            TextSpan(
              text: ' · $account',
              style: TextStyle(color: tokens.textMedium),
            ),
        ],
      ),
      maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.4 ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: HorizonTypography.bodySm.copyWith(color: tokens.textMedium),
    );
  }
}

class LedgerTransactionRow extends StatefulWidget {
  const LedgerTransactionRow({
    super.key,
    required this.transaction,
    required this.onPressed,
  });
  final TransactionModel transaction;
  final VoidCallback onPressed;
  @override
  State<LedgerTransactionRow> createState() => _LedgerTransactionRowState();
}

class _LedgerTransactionRowState extends State<LedgerTransactionRow> {
  bool _hovered = false;
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final tokens = HorizonThemeTokens.of(context);
    final inflow = ledgerIsInflow(tx);
    // Reverse entries retain their original signed effect; never produce "--".
    final signedAmount = inflow ? tx.amount : -tx.amount;
    final amountLabel = HorizonFormatters.formatInr(
      signedAmount,
      showSign: true,
    );
    final amountStyle = HorizonTypography.tabularAmountSm.copyWith(
      color: signedAmount >= 0 ? tokens.surplus : tokens.outflow,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: HorizonPressable(
          key: ValueKey('ledger-transaction-${tx.id}'),
          label:
              '${tx.title}, ${tx.category}, ${tx.accountName ?? ''}, $amountLabel${tx.source.toLowerCase().contains('sms') ? ', imported from SMS' : ''}',
          onPressed: widget.onPressed,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : HorizonMotion.press,
            decoration: BoxDecoration(
              color: _hovered || _pressed ? tokens.surface1 : tokens.canvas,
              border: Border(bottom: BorderSide(color: tokens.divider)),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: HorizonDimensions.marginMobile,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final amountMeasure = TextPainter(
                  text: TextSpan(text: amountLabel, style: amountStyle),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final stackAmount =
                    MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                    amountMeasure.width > constraints.maxWidth * 0.48;
                amountMeasure.dispose();
                final title = Text(
                  tx.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HorizonTypography.bodyMd.copyWith(
                    color: tokens.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                );
                final amount = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(amountLabel, style: amountStyle, maxLines: 1),
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LedgerTransactionIcon(transaction: tx),
                    const SizedBox(width: HorizonDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stackAmount)
                            title
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: title),
                                const SizedBox(
                                  width: HorizonDimensions.spaceMD,
                                ),
                                amount,
                              ],
                            ),
                          const SizedBox(height: HorizonDimensions.spaceXS),
                          LedgerMetadata(transaction: tx),
                          if (stackAmount) ...[
                            const SizedBox(height: HorizonDimensions.spaceSM),
                            Align(
                              alignment: Alignment.centerRight,
                              child: amount,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
