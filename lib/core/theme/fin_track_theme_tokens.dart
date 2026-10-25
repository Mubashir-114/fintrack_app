import 'package:flutter/material.dart';
import 'theme_collection.dart';

/// Centralized semantic design tokens for FinTrack // HORIZON.
/// Implemented as a [ThemeExtension] so any widget can easily inspect
/// the active theme tokens via `Theme.of(context).extension<FinTrackThemeTokens>()`.
@immutable
class FinTrackThemeTokens extends ThemeExtension<FinTrackThemeTokens> {
  const FinTrackThemeTokens({
    required this.collection,
    required this.isDark,
    required this.primary,
    required this.primaryDeep,
    required this.secondary,
    required this.highlight,
    required this.background,
    required this.surface,
    required this.elevated,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.transfer,
    required this.cardBorder,
    required this.midnightGradient,
    required this.cardGradient,
  });

  final ThemeCollection collection;
  final bool isDark;
  final Color primary;
  final Color primaryDeep;
  final Color secondary;
  final Color highlight;
  final Color background;
  final Color surface;
  final Color elevated;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color transfer;
  final Color cardBorder;
  final LinearGradient midnightGradient;
  final LinearGradient cardGradient;

  // ===========================================================================
  // 1. Midnight Aurora (Default Curated HORIZON Identity)
  // ===========================================================================

  static const FinTrackThemeTokens midnightAuroraDark = FinTrackThemeTokens(
    collection: ThemeCollection.midnightAurora,
    isDark: true,
    primary: Color(0xFF75DEED), // Ion Cyan
    primaryDeep: Color(0xFF4AC7D8),
    secondary: Color(0xFF8996FC), // Electric Indigo
    highlight: Color(0xFFE5B76A), // Luminous Gold
    background: Color(0xFF080D17), // Void Canvas
    surface: Color(0xFF0E1626), // Surface 1
    elevated: Color(0xFF172338), // Surface 2
    divider: Color(0xFF1F2F4A), // Surface 3 / Divider
    textPrimary: Color(0xFFF5F8FC),
    textSecondary: Color(0xFF8E9BAE),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    transfer: Color(0xFF8996FC),
    cardBorder: Color(0x1F75DEED),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF172338), Color(0xFF0E1626), Color(0xFF080D17)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF172338), Color(0xFF0F1726)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const FinTrackThemeTokens midnightAuroraLight = FinTrackThemeTokens(
    collection: ThemeCollection.midnightAurora,
    isDark: false,
    primary: Color(0xFF006874), // Accessible deep cyan ink
    primaryDeep: Color(0xFF004F58),
    secondary: Color(0xFF313EA0),
    highlight: Color(0xFF8A6100),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF1F5F9),
    divider: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF313EA0),
    cardBorder: Color(0x28006874),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // 2. Obsidian Jade
  // ===========================================================================

  static const FinTrackThemeTokens obsidianJadeDark = FinTrackThemeTokens(
    collection: ThemeCollection.obsidianJade,
    isDark: true,
    primary: Color(0xFF38D5B0), // Emerald Jade
    primaryDeep: Color(0xFF2BB594),
    secondary: Color(0xFF2DD4BF), // Soft Teal
    highlight: Color(0xFFE2C37A),
    background: Color(0xFF0B111A), // Charcoal Black
    surface: Color(0xFF151F2B),
    elevated: Color(0xFF1C2B3C),
    divider: Color(0xFF25374C),
    textPrimary: Color(0xFFF0FAF7),
    textSecondary: Color(0xFF8BA39E),
    success: Color(0xFF38D5B0),
    danger: Color(0xFFFF6B81),
    warning: Color(0xFFFFB84D),
    info: Color(0xFF5AB0FF),
    transfer: Color(0xFF2DD4BF),
    cardBorder: Color(0x3338D5B0),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF1C2B3C), Color(0xFF151F2B), Color(0xFF0B111A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF151F2B), Color(0xFF0F1822)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const FinTrackThemeTokens obsidianJadeLight = FinTrackThemeTokens(
    collection: ThemeCollection.obsidianJade,
    isDark: false,
    primary: Color(0xFF056A55), // High-contrast deep jade
    primaryDeep: Color(0xFF034D3D),
    secondary: Color(0xFF0F766E),
    highlight: Color(0xFF854D0E),
    background: Color(0xFFF2F9F7),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE3F2EE),
    divider: Color(0xFFD2E8E2),
    textPrimary: Color(0xFF061D17),
    textSecondary: Color(0xFF3D5952),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF0284C7),
    transfer: Color(0xFF0F766E),
    cardBorder: Color(0x26056A55),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFE3F2EE), Color(0xFFD2E8E2), Color(0xFFF2F9F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFE3F2EE), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // 3. Graphite & Champagne
  // ===========================================================================

  static const FinTrackThemeTokens graphiteChampagneDark = FinTrackThemeTokens(
    collection: ThemeCollection.graphiteChampagne,
    isDark: true,
    primary: Color(0xFFD6A668), // Champagne
    primaryDeep: Color(0xFFBE8F50),
    secondary: Color(0xFFE6BE85), // Soft Gold
    highlight: Color(0xFFE6BE85),
    background: Color(0xFF171B24), // Graphite
    surface: Color(0xFF252934),
    elevated: Color(0xFF30343F),
    divider: Color(0xFF393D48),
    textPrimary: Color(0xFFF4EFE7),
    textSecondary: Color(0xFFB5AFAB),
    success: Color(0xFF38D5B0),
    danger: Color(0xFFFF6B81),
    warning: Color(0xFFFFB84D),
    info: Color(0xFF5AB0FF),
    transfer: Color(0xFF88A0BF),
    cardBorder: Color(0xFF393D48),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF30343F), Color(0xFF252934), Color(0xFF171B24)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF252934), Color(0xFF1F232D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const FinTrackThemeTokens graphiteChampagneLight = FinTrackThemeTokens(
    collection: ThemeCollection.graphiteChampagne,
    isDark: false,
    primary: Color(0xFF805421), // Champagne ink
    primaryDeep: Color(0xFF9E6E30),
    secondary: Color(0xFFD6A668),
    highlight: Color(0xFFD6A668),
    background: Color(0xFFF8F6F1), // Warm Ivory
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0EBE1),
    divider: Color(0xFFE3DDD2),
    textPrimary: Color(0xFF1C1E24),
    textSecondary: Color(0xFF6B6760),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF6B5E4F),
    cardBorder: Color(0x26805421),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF0EBE1), Color(0xFFE3DDD2), Color(0xFFF8F6F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFF0EBE1), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // 4. Arctic Blue
  // ===========================================================================

  static const FinTrackThemeTokens arcticBlueDark = FinTrackThemeTokens(
    collection: ThemeCollection.arcticBlue,
    isDark: true,
    primary: Color(0xFF4FA3F7), // Ice Blue
    primaryDeep: Color(0xFF2B82DE),
    secondary: Color(0xFF7DD3FC), // Cyan Frost
    highlight: Color(0xFF38BDF8),
    background: Color(0xFF0E1726), // Midnight Navy
    surface: Color(0xFF162338),
    elevated: Color(0xFF1F304B),
    divider: Color(0xFF2A4165),
    textPrimary: Color(0xFFF0F6FF),
    textSecondary: Color(0xFF8DA2C0),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    transfer: Color(0xFF818CF8),
    cardBorder: Color(0x264FA3F7),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF1F304B), Color(0xFF162338), Color(0xFF0E1726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF162338), Color(0xFF101B2C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const FinTrackThemeTokens arcticBlueLight = FinTrackThemeTokens(
    collection: ThemeCollection.arcticBlue,
    isDark: false,
    primary: Color(0xFF1D4ED8), // Deep cobalt
    primaryDeep: Color(0xFF1E40AF),
    secondary: Color(0xFF0284C7),
    highlight: Color(0xFF0369A1),
    background: Color(0xFFF0F6FE),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE2EDFC),
    divider: Color(0xFFD1E2FA),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF4338CA),
    cardBorder: Color(0x261D4ED8),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFE2EDFC), Color(0xFFD1E2FA), Color(0xFFF0F6FE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFE2EDFC), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // 5. Ivory Sand
  // ===========================================================================

  static const FinTrackThemeTokens ivorySandDark = FinTrackThemeTokens(
    collection: ThemeCollection.ivorySand,
    isDark: true,
    primary: Color(0xFFD4A373), // Sandstone Bronze
    primaryDeep: Color(0xFFB88554),
    secondary: Color(0xFFE07A5F), // Warm Terracotta
    highlight: Color(0xFFCCD5AE),
    background: Color(0xFF161311), // Warm Earth
    surface: Color(0xFF201B17),
    elevated: Color(0xFF2B241E),
    divider: Color(0xFF372E26),
    textPrimary: Color(0xFFFAF7F2),
    textSecondary: Color(0xFFB3A99E),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    transfer: Color(0xFFE07A5F),
    cardBorder: Color(0x26D4A373),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF2B241E), Color(0xFF201B17), Color(0xFF161311)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF201B17), Color(0xFF181412)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const FinTrackThemeTokens ivorySandLight = FinTrackThemeTokens(
    collection: ThemeCollection.ivorySand,
    isDark: false,
    primary: Color(0xFF8C531B), // Deep bronze
    primaryDeep: Color(0xFF704012),
    secondary: Color(0xFFA04026),
    highlight: Color(0xFF586438),
    background: Color(0xFFFBF9F5),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF3EFE6),
    divider: Color(0xFFE6DFD2),
    textPrimary: Color(0xFF1E1B18),
    textSecondary: Color(0xFF544C44),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF2563EB),
    transfer: Color(0xFFA04026),
    cardBorder: Color(0x268C531B),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF3EFE6), Color(0xFFE6DFD2), Color(0xFFFBF9F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFF3EFE6), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // 6. Amethyst Pulse
  // ===========================================================================

  static const FinTrackThemeTokens amethystPulseDark = FinTrackThemeTokens(
    collection: ThemeCollection.amethystPulse,
    isDark: true,
    primary: Color(0xFFC084FC), // Soft Violet
    primaryDeep: Color(0xFFA855F7),
    secondary: Color(0xFFE879F9), // Lavender Highlight
    highlight: Color(0xFFF472B6),
    background: Color(0xFF130D1A), // Deep Plum
    surface: Color(0xFF1D1427),
    elevated: Color(0xFF281C36),
    divider: Color(0xFF342546),
    textPrimary: Color(0xFFFAF5FF),
    textSecondary: Color(0xFFAC9DBA),
    success: Color(0xFF34D399),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    transfer: Color(0xFFE879F9),
    cardBorder: Color(0x26C084FC),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF281C36), Color(0xFF1D1427), Color(0xFF130D1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1D1427), Color(0xFF170E20)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const FinTrackThemeTokens amethystPulseLight = FinTrackThemeTokens(
    collection: ThemeCollection.amethystPulse,
    isDark: false,
    primary: Color(0xFF6B21A8), // Deep plum violet
    primaryDeep: Color(0xFF581C87),
    secondary: Color(0xFF86198F),
    highlight: Color(0xFF9333EA),
    background: Color(0xFFFAF5FF),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF3E8FF),
    divider: Color(0xFFE9D5FF),
    textPrimary: Color(0xFF1A0B2E),
    textSecondary: Color(0xFF4C346B),
    success: Color(0xFF047857),
    danger: Color(0xFFB91C1C),
    warning: Color(0xFF92400E),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF86198F),
    cardBorder: Color(0x266B21A8),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF), Color(0xFFFAF5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFF3E8FF), Color(0xFFFFFFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ===========================================================================
  // Token Resolution Engine
  // ===========================================================================

  static FinTrackThemeTokens resolve(
    ThemeCollection collection,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    switch (collection) {
      case ThemeCollection.midnightAurora:
        return dark ? midnightAuroraDark : midnightAuroraLight;
      case ThemeCollection.obsidianJade:
        return dark ? obsidianJadeDark : obsidianJadeLight;
      case ThemeCollection.graphiteChampagne:
        return dark ? graphiteChampagneDark : graphiteChampagneLight;
      case ThemeCollection.arcticBlue:
        return dark ? arcticBlueDark : arcticBlueLight;
      case ThemeCollection.ivorySand:
        return dark ? ivorySandDark : ivorySandLight;
      case ThemeCollection.amethystPulse:
        return dark ? amethystPulseDark : amethystPulseLight;
    }
  }

  @override
  ThemeExtension<FinTrackThemeTokens> copyWith({
    ThemeCollection? collection,
    bool? isDark,
    Color? primary,
    Color? primaryDeep,
    Color? secondary,
    Color? highlight,
    Color? background,
    Color? surface,
    Color? elevated,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? transfer,
    Color? cardBorder,
    LinearGradient? midnightGradient,
    LinearGradient? cardGradient,
  }) {
    return FinTrackThemeTokens(
      collection: collection ?? this.collection,
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      secondary: secondary ?? this.secondary,
      highlight: highlight ?? this.highlight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      transfer: transfer ?? this.transfer,
      cardBorder: cardBorder ?? this.cardBorder,
      midnightGradient: midnightGradient ?? this.midnightGradient,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  ThemeExtension<FinTrackThemeTokens> lerp(
    covariant ThemeExtension<FinTrackThemeTokens>? other,
    double t,
  ) {
    if (other is! FinTrackThemeTokens) return this;
    return FinTrackThemeTokens(
      collection: t < 0.5 ? collection : other.collection,
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      midnightGradient: LinearGradient.lerp(
        midnightGradient,
        other.midnightGradient,
        t,
      )!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
    );
  }
}
