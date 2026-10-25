import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../providers/currency_provider.dart';

/// Renders an exact decimal money string without any floating-point conversion.
///
/// The [decimalString] is the raw string from the API (e.g. "12500.00").
/// This widget formats it for display using string operations only — no
/// [double] arithmetic.
class MoneyText extends StatelessWidget {
  final String decimalString;
  final String? currencyCode;
  final TextStyle? style;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.decimalString,
    this.currencyCode,
    this.style,
    this.showSign = false,
  });

  static String getSymbol(String currencyCode) =>
      MoneyFormatter.getSymbol(currencyCode);

  static String format(
    String raw, [
    String currencyCode = 'INR',
    bool showSign = false,
  ]) => MoneyFormatter.format(raw, currencyCode, showSign);

  @override
  Widget build(BuildContext context) {
    return Text(
      format(
        decimalString,
        currencyCode ??
            context.watch<CurrencyProvider?>()?.currencyCode ??
            'INR',
        showSign,
      ),
      style: style,
    );
  }
}
