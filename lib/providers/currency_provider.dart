import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/money_formatter.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _prefKey = 'user_currency_code';

  String _currencyCode = 'INR';

  String get currencyCode => _currencyCode;
  String get currencySymbol => MoneyFormatter.getSymbol(_currencyCode);
  String get selectedCurrencyString => '$_currencyCode ($currencySymbol)';

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
  };

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && currencySymbols.containsKey(savedCode)) {
        _currencyCode = savedCode;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setCurrency(String code) async {
    if (!currencySymbols.containsKey(code)) return;
    _currencyCode = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  String format(
    num amount, {
    bool decimalDigits = true,
    bool showSign = false,
  }) => MoneyFormatter.amount(
    amount,
    currencyCode: _currencyCode,
    decimalDigits: decimalDigits,
    showSign: showSign,
  );

  String formatCompact(num amount) =>
      MoneyFormatter.compact(amount, _currencyCode);
}
