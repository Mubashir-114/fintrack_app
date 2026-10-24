import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_collection.dart';
import 'horizon_theme_tokens.dart';

/// Legacy interface bridging into the unified authoritative [AppTheme].
class HorizonTheme {
  HorizonTheme._();

  static ThemeData get darkTheme => AppTheme.buildTheme(
        ThemeCollection.midnightAurora,
        Brightness.dark,
      );

  static ThemeData get lightTheme => AppTheme.buildTheme(
        ThemeCollection.midnightAurora,
        Brightness.light,
      );

  static ThemeData buildTheme(
    Brightness brightness, [
    ThemeCollection collection = ThemeCollection.midnightAurora,
  ]) {
    return AppTheme.buildTheme(collection, brightness);
  }

  static HorizonThemeTokens tokensOf(BuildContext context) {
    return HorizonThemeTokens.of(context);
  }
}
