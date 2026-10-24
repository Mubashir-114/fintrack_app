import 'package:intl/intl.dart';

/// Financial numerical formatting for FinTrack // HORIZON.
///
/// Ensures exact Indian numbering system grouping (lakhs/crores) and
/// equal-weight Rupee symbols to eliminate vertical drift in dense lists.
class HorizonFormatters {
  HorizonFormatters._();

  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrNumberOnly = NumberFormat.decimalPattern('en_IN');

  /// Formats amount in INR with Rupee symbol and Indian numbering:
  /// e.g. 1842850.40 -> "₹18,42,850.40"
  static String formatInr(num amount, {bool decimalDigits = true, bool showSign = false}) {
    final absAmount = amount.abs();
    final base = decimalDigits
        ? _inrWithDecimals.format(absAmount)
        : _inrCompact.format(absAmount);

    if (showSign) {
      if (amount > 0) return '+$base';
      if (amount < 0) return '-$base';
    }
    return amount < 0 ? '-$base' : base;
  }

  /// Returns only the number portion formatted with Indian grouping, without symbol:
  /// e.g. 1842850.40 -> "18,42,850.40"
  static String formatInrNumeral(num amount, {bool decimalDigits = true}) {
    if (decimalDigits) {
      final whole = amount.floor();
      final fraction = ((amount.abs() - whole.abs()) * 100).round().toString().padLeft(2, '0');
      return '${_inrNumberOnly.format(whole)}.$fraction';
    }
    return _inrNumberOnly.format(amount.round());
  }

  /// Compact telemetry balance for space-constrained badges:
  /// e.g. 1842850 -> "₹18.43 L", 12500000 -> "₹1.25 Cr"
  static String formatCompactInr(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 10000000) {
      return '$sign₹${(abs / 10000000).toStringAsFixed(2)} Cr';
    } else if (abs >= 100000) {
      return '$sign₹${(abs / 100000).toStringAsFixed(2)} L';
    } else if (abs >= 1000) {
      return '$sign₹${(abs / 1000).toStringAsFixed(1)} k';
    }
    return '$sign₹${abs.toStringAsFixed(0)}';
  }
}
