import 'package:intl/intl.dart';

/// Shared exact-decimal display formatting for dashboard, accounts and reports.
class MoneyFormatter {
  MoneyFormatter._();

  static String getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currencyCode ';
    }
  }

  /// Formats the decimal string for display using string operations only — no double conversions.
  static String format(
    String raw, [
    String currencyCode = 'INR',
    bool showSign = false,
  ]) {
    final isNegative = raw.startsWith('-');
    final abs = isNegative ? raw.substring(1) : raw;
    final parts = abs.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final symbol = getSymbol(currencyCode);

    final String formatted;
    if (currencyCode == 'INR') {
      // Indian numbering: first group of 3 from right, then groups of 2
      final chars = intPart.split('').reversed.toList();
      final groups = <String>[];
      for (int i = 0; i < chars.length; i++) {
        if (i == 3 && chars.length > 3) {
          groups.add(',');
        } else if (i > 3 && (i - 3) % 2 == 0) {
          groups.add(',');
        }
        groups.add(chars[i]);
      }
      formatted = groups.reversed.join();
    } else {
      // Standard grouping in 3s
      final chars = intPart.split('').reversed.toList();
      final groups = <String>[];
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && i % 3 == 0) {
          groups.add(',');
        }
        groups.add(chars[i]);
      }
      formatted = groups.reversed.join();
    }

    final sign = isNegative ? '-' : (showSign ? '+' : '');
    return '$sign$symbol$formatted.$decPart';
  }

  static String amount(
    num value, {
    String currencyCode = 'INR',
    bool decimalDigits = true,
    bool showSign = false,
  }) {
    final raw = value.toStringAsFixed(decimalDigits ? 2 : 0);
    final formatted = format(raw, currencyCode, showSign);
    return decimalDigits ? formatted : formatted.split('.').first;
  }

  static String compact(num value, String currencyCode) =>
      NumberFormat.compactCurrency(
        locale: currencyCode == 'INR' ? 'en_IN' : 'en_US',
        symbol: getSymbol(currencyCode),
        decimalDigits: 0,
      ).format(value);
}
