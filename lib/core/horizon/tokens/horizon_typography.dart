import 'package:flutter/material.dart';
import 'horizon_colors.dart';

/// Typography tokens for FinTrack // HORIZON.
///
/// Pairs technical, engineered Space Grotesk for metrics and telemetry readouts
/// with clear Plus Jakarta Sans for operational UI readability.
class HorizonTypography {
  HorizonTypography._();

  static const String spaceGrotesk = 'Space Grotesk';
  static const List<String> spaceGroteskFallbacks = [
    'Space Grotesk',
    'SpaceGrotesk',
    'Roboto Mono',
    'monospace',
    'sans-serif',
  ];

  static const String plusJakartaSans = 'Plus Jakarta Sans';
  static const List<String> plusJakartaSansFallbacks = [
    'Plus Jakarta Sans',
    'PlusJakartaSans',
    'Inter',
    'Roboto',
    'sans-serif',
  ];

  /// Standard font features ensuring exact column alignment for numbers.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // ---------------------------------------------------------------------------
  // Dark Mode Typography Presets
  // ---------------------------------------------------------------------------

  /// Display Hero: 38px / 44px, w700, -0.03em
  static const TextStyle displayHero = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    height: 44 / 38,
    letterSpacing: -0.03 * 38,
    color: HorizonColors.textHigh,
    fontFeatures: tabularFigures,
  );

  /// Headline Lg: 30px / 36px, w600, -0.02em
  static const TextStyle headlineLg = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 36 / 30,
    letterSpacing: -0.02 * 30,
    color: HorizonColors.textHigh,
  );

  /// Headline Md: 24px / 30px, w600, -0.015em
  static const TextStyle headlineMd = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 30 / 24,
    letterSpacing: -0.015 * 24,
    color: HorizonColors.textHigh,
  );

  /// Headline Sm: 19px / 25px, w600, -0.01em
  static const TextStyle headlineSm = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 25 / 19,
    letterSpacing: -0.01 * 19,
    color: HorizonColors.textHigh,
  );

  /// Tabular Amount Lg: 28px / 34px, w700, -0.02em, tabular numerals
  static const TextStyle tabularAmountLg = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.02 * 28,
    color: HorizonColors.textHigh,
    fontFeatures: tabularFigures,
  );

  /// Tabular Amount Md: 20px / 26px, w600, -0.01em, tabular numerals
  static const TextStyle tabularAmountMd = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 26 / 20,
    letterSpacing: -0.01 * 20,
    color: HorizonColors.textHigh,
    fontFeatures: tabularFigures,
  );

  /// Tabular Amount Sm: 14px / 18px, w600, 0em, tabular numerals
  static const TextStyle tabularAmountSm = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0,
    color: HorizonColors.textHigh,
    fontFeatures: tabularFigures,
  );

  /// Label Caps: 10px / 14px, w600, 0.08em tracking (cockpit status clusters)
  static const TextStyle labelCaps = TextStyle(
    fontFamily: spaceGrotesk,
    fontFamilyFallback: spaceGroteskFallbacks,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 14 / 10,
    letterSpacing: 0.08 * 10,
    color: HorizonColors.textMedium,
  );

  /// Label Md: 12px / 16px, w500, 0.02em
  static const TextStyle labelMd = TextStyle(
    fontFamily: plusJakartaSans,
    fontFamilyFallback: plusJakartaSansFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
    color: HorizonColors.textMedium,
  );

  /// Body Lg: 16px / 24px, w400, 0em
  static const TextStyle bodyLg = TextStyle(
    fontFamily: plusJakartaSans,
    fontFamilyFallback: plusJakartaSansFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: HorizonColors.textHigh,
  );

  /// Body Md: 14px / 20px, w400, 0.005em
  static const TextStyle bodyMd = TextStyle(
    fontFamily: plusJakartaSans,
    fontFamilyFallback: plusJakartaSansFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.005 * 14,
    color: HorizonColors.textHigh,
  );

  /// Body Sm: 12px / 16px, w400, 0.01em
  static const TextStyle bodySm = TextStyle(
    fontFamily: plusJakartaSans,
    fontFamilyFallback: plusJakartaSansFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.01 * 12,
    color: HorizonColors.textMedium,
  );

  /// Generates a TextTheme for ThemeData integration.
  static TextTheme createTextTheme(Color high, Color medium, Color low) {
    return TextTheme(
      displayLarge: displayHero.copyWith(color: high),
      displayMedium: headlineLg.copyWith(color: high),
      displaySmall: headlineMd.copyWith(color: high),
      headlineMedium: headlineSm.copyWith(color: high),
      headlineSmall: tabularAmountLg.copyWith(color: high),
      titleLarge: headlineSm.copyWith(color: high),
      titleMedium: tabularAmountMd.copyWith(color: high),
      titleSmall: tabularAmountSm.copyWith(color: high),
      bodyLarge: bodyLg.copyWith(color: high),
      bodyMedium: bodyMd.copyWith(color: high),
      bodySmall: bodySm.copyWith(color: medium),
      labelLarge: bodyMd.copyWith(fontWeight: FontWeight.w600, color: high),
      labelMedium: labelMd.copyWith(color: medium),
      labelSmall: labelCaps.copyWith(color: low),
    );
  }
}
