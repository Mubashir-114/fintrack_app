import 'package:flutter/material.dart';
import '../../theme/theme_collection.dart';
import '../tokens/horizon_colors.dart';

/// Semantic ThemeExtension providing access to all HORIZON design tokens.
/// Dynamically resolves against any of the 6 curated [ThemeCollection] identities
/// and dark/light display modes.
@immutable
class HorizonThemeTokens extends ThemeExtension<HorizonThemeTokens> {
  const HorizonThemeTokens({
    required this.collection,
    required this.isDark,
    required this.canvas,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.surface4,
    required this.ionCyan,
    required this.electricIndigo,
    required this.luminousGold,
    required this.onPrimary,
    required this.surplus,
    required this.outflow,
    required this.warning,
    required this.info,
    required this.textHigh,
    required this.textMedium,
    required this.textLow,
    required this.rimCyan,
    required this.rimCyanActive,
    required this.rimDock,
    required this.rimNeutral,
    required this.rimTopHighlight,
    required this.rowDivider,
    required this.cardGradient,
  });

  final ThemeCollection collection;
  final bool isDark;
  final Color canvas;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color surface4;

  /// Primary driver accent (e.g. Ion Cyan, Emerald Jade, Champagne, etc.)
  final Color ionCyan;

  /// Secondary driver accent (e.g. Electric Indigo, Soft Teal, Soft Gold, etc.)
  final Color electricIndigo;

  /// Tertiary / milestone accent (e.g. Luminous Gold, Frost Cyan, etc.)
  final Color luminousGold;

  /// High-contrast label color on top of primary button / accent fills
  final Color onPrimary;

  final Color surplus;
  final Color outflow;
  final Color warning;
  final Color info;
  final Color textHigh;
  final Color textMedium;
  final Color textLow;

  /// Primary hairline rim with subtle glow
  final Color rimCyan;

  /// Active / focused hairline rim
  final Color rimCyanActive;

  /// Floating dock rim
  final Color rimDock;

  /// Structural neutral hairline rim
  final Color rimNeutral;

  /// Inner top rim highlight
  final Color rimTopHighlight;

  /// Sub-divider line
  final Color rowDivider;

  final LinearGradient cardGradient;

  /// Semantic Aliases
  Color get primary => ionCyan;
  Color get secondary => electricIndigo;
  Color get tertiary => luminousGold;
  Color get background => canvas;
  Color get divider => rowDivider;

  // ---------------------------------------------------------------------------
  // Canonical Midnight Aurora (Default Curated HORIZON Identity)
  // ---------------------------------------------------------------------------

  static const HorizonThemeTokens dark = HorizonThemeTokens(
    collection: ThemeCollection.midnightAurora,
    isDark: true,
    canvas: HorizonColors.voidCanvas, // 0xFF080D17
    surface1: HorizonColors.surface1, // 0xFF0E1626
    surface2: HorizonColors.surface2, // 0xFF172338
    surface3: HorizonColors.surface3, // 0xFF1F2F4A
    surface4: HorizonColors.surface4, // 0xFF253858
    ionCyan: HorizonColors.ionCyan, // 0xFF75DEED
    electricIndigo: HorizonColors.electricIndigo, // 0xFF8996FC
    luminousGold: HorizonColors.luminousGold, // 0xFFE5B76A
    onPrimary: HorizonColors.voidCanvas,
    surplus: HorizonColors.surplus, // 0xFF34D399
    outflow: HorizonColors.outflow, // 0xFFF87171
    warning: HorizonColors.warning, // 0xFFFBBF24
    info: HorizonColors.info, // 0xFF60A5FA
    textHigh: HorizonColors.textHigh, // 0xFFF5F8FC
    textMedium: HorizonColors.textMedium, // 0xFF8E9BAE
    textLow: HorizonColors.textLow, // 0xFF5A6B82
    rimCyan: HorizonColors.rimCyan,
    rimCyanActive: HorizonColors.rimCyanActive,
    rimDock: HorizonColors.rimDock,
    rimNeutral: HorizonColors.rimNeutral,
    rimTopHighlight: HorizonColors.rimTopHighlight,
    rowDivider: HorizonColors.rowDivider,
    cardGradient: HorizonColors.cardGradient,
  );

  static const HorizonThemeTokens light = HorizonThemeTokens(
    collection: ThemeCollection.midnightAurora,
    isDark: false,
    canvas: HorizonColors.lightCanvas, // 0xFFF8FAFC
    surface1: HorizonColors.lightSurface1, // 0xFFFFFFFF
    surface2: HorizonColors.lightSurface2, // 0xFFF1F5F9
    surface3: HorizonColors.lightSurface3, // 0xFFE2E8F0
    surface4: HorizonColors.lightSurface4, // 0xFFCBD5E1
    ionCyan: HorizonColors.lightIonCyan, // 0xFF006874
    electricIndigo: HorizonColors.lightElectricIndigo, // 0xFF313EA0
    luminousGold: HorizonColors.lightLuminousGold, // 0xFF8A6100
    onPrimary: Colors.white,
    surplus: HorizonColors.lightSurplus, // 0xFF047857
    outflow: HorizonColors.lightOutflow, // 0xFFB91C1C
    warning: HorizonColors.lightWarning, // 0xFF92400E
    info: HorizonColors.lightInfo, // 0xFF2563EB
    textHigh: HorizonColors.lightTextHigh, // 0xFF0F172A
    textMedium: HorizonColors.lightTextMedium, // 0xFF475569
    textLow: HorizonColors.lightTextLow, // 0xFF94A3B8
    rimCyan: HorizonColors.lightRimCyan,
    rimCyanActive: Color(0x38006874),
    rimDock: HorizonColors.lightRimNeutral,
    rimNeutral: HorizonColors.lightRimNeutral,
    rimTopHighlight: Colors.transparent,
    rowDivider: HorizonColors.lightRowDivider,
    cardGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [HorizonColors.lightSurface2, HorizonColors.lightSurface1],
    ),
  );

  // ---------------------------------------------------------------------------
  // 6-Theme Resolution Factory
  // ---------------------------------------------------------------------------

  static HorizonThemeTokens resolve(
    ThemeCollection collection,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    switch (collection) {
      case ThemeCollection.midnightAurora:
        return isDark ? dark : light;

      case ThemeCollection.obsidianJade:
        return isDark
            ? const HorizonThemeTokens(
                collection: ThemeCollection.obsidianJade,
                isDark: true,
                canvas: Color(0xFF090D0D),
                surface1: Color(0xFF0F1716),
                surface2: Color(0xFF152220),
                surface3: Color(0xFF1C2E2B),
                surface4: Color(0xFF243A36),
                ionCyan: Color(0xFF38D5B0), // Emerald Jade
                electricIndigo: Color(0xFF2DD4BF), // Soft Teal
                luminousGold: Color(0xFFE2C37A),
                onPrimary: Color(0xFF090D0D),
                surplus: Color(0xFF38D5B0),
                outflow: Color(0xFFFF6B81),
                warning: Color(0xFFFFB84D),
                info: Color(0xFF5AB0FF),
                textHigh: Color(0xFFF0FAF7),
                textMedium: Color(0xFF8BA39E),
                textLow: Color(0xFF566E69),
                rimCyan: Color(0x2438D5B0),
                rimCyanActive: Color(0x3D38D5B0),
                rimDock: Color(0x3338D5B0),
                rimNeutral: Color(0x1A8BA39E),
                rimTopHighlight: Color(0x14F0FAF7),
                rowDivider: Color(0x1238D5B0),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF152220), Color(0xFF0F1716)],
                ),
              )
            : const HorizonThemeTokens(
                collection: ThemeCollection.obsidianJade,
                isDark: false,
                canvas: Color(0xFFF2F9F7),
                surface1: Color(0xFFFFFFFF),
                surface2: Color(0xFFE3F2EE),
                surface3: Color(0xFFD2E8E2),
                surface4: Color(0xFFC0DDD6),
                ionCyan: Color(0xFF056A55), // High-contrast Jade ink
                electricIndigo: Color(0xFF0F766E),
                luminousGold: Color(0xFF854D0E),
                onPrimary: Colors.white,
                surplus: Color(0xFF047857),
                outflow: Color(0xFFB91C1C),
                warning: Color(0xFF92400E),
                info: Color(0xFF0284C7),
                textHigh: Color(0xFF061D17),
                textMedium: Color(0xFF3D5952),
                textLow: Color(0xFF6D8B84),
                rimCyan: Color(0x28056A55),
                rimCyanActive: Color(0x3D056A55),
                rimDock: Color(0x1E061D17),
                rimNeutral: Color(0x1A061D17),
                rimTopHighlight: Colors.transparent,
                rowDivider: Color(0x14061D17),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2EE), Color(0xFFFFFFFF)],
                ),
              );

      case ThemeCollection.graphiteChampagne:
        return isDark
            ? const HorizonThemeTokens(
                collection: ThemeCollection.graphiteChampagne,
                isDark: true,
                canvas: Color(0xFF12151B),
                surface1: Color(0xFF1B1E26),
                surface2: Color(0xFF242833),
                surface3: Color(0xFF2E3340),
                surface4: Color(0xFF383E4E),
                ionCyan: Color(0xFFD6A668), // Champagne
                electricIndigo: Color(0xFFE6BE85), // Soft Gold
                luminousGold: Color(0xFFE6BE85),
                onPrimary: Color(0xFF12151B),
                surplus: Color(0xFF38D5B0),
                outflow: Color(0xFFFF6B81),
                warning: Color(0xFFFFB84D),
                info: Color(0xFF5AB0FF),
                textHigh: Color(0xFFF8F5EE),
                textMedium: Color(0xFFB0ABA1),
                textLow: Color(0xFF6F6B64),
                rimCyan: Color(0x24D6A668),
                rimCyanActive: Color(0x3DD6A668),
                rimDock: Color(0x33D6A668),
                rimNeutral: Color(0x1AB0ABA1),
                rimTopHighlight: Color(0x14F8F5EE),
                rowDivider: Color(0x12D6A668),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF242833), Color(0xFF1B1E26)],
                ),
              )
            : const HorizonThemeTokens(
                collection: ThemeCollection.graphiteChampagne,
                isDark: false,
                canvas: Color(0xFFFAF8F5),
                surface1: Color(0xFFFFFFFF),
                surface2: Color(0xFFF3EFE7),
                surface3: Color(0xFFE7E1D4),
                surface4: Color(0xFFDCD4C4),
                ionCyan: Color(0xFF805421), // Champagne ink
                electricIndigo: Color(0xFF9A692C),
                luminousGold: Color(0xFF713F12),
                onPrimary: Colors.white,
                surplus: Color(0xFF047857),
                outflow: Color(0xFFB91C1C),
                warning: Color(0xFF92400E),
                info: Color(0xFF2563EB),
                textHigh: Color(0xFF1C1917),
                textMedium: Color(0xFF57534E),
                textLow: Color(0xFF8B857E),
                rimCyan: Color(0x28805421),
                rimCyanActive: Color(0x3D805421),
                rimDock: Color(0x1E1C1917),
                rimNeutral: Color(0x1A1C1917),
                rimTopHighlight: Colors.transparent,
                rowDivider: Color(0x141C1917),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3EFE7), Color(0xFFFFFFFF)],
                ),
              );

      case ThemeCollection.arcticBlue:
        return isDark
            ? const HorizonThemeTokens(
                collection: ThemeCollection.arcticBlue,
                isDark: true,
                canvas: Color(0xFF0B111E),
                surface1: Color(0xFF121A2C),
                surface2: Color(0xFF1A243C),
                surface3: Color(0xFF222F4C),
                surface4: Color(0xFF2A3A5D),
                ionCyan: Color(0xFF4FA3F7), // Ice Blue
                electricIndigo: Color(0xFF818CF8), // Midnight Blue
                luminousGold: Color(0xFF38BDF8),
                onPrimary: Color(0xFF0B111E),
                surplus: Color(0xFF34D399),
                outflow: Color(0xFFF87171),
                warning: Color(0xFFFBBF24),
                info: Color(0xFF60A5FA),
                textHigh: Color(0xFFF0F6FF),
                textMedium: Color(0xFF8DA2C0),
                textLow: Color(0xFF576C8A),
                rimCyan: Color(0x244FA3F7),
                rimCyanActive: Color(0x3D4FA3F7),
                rimDock: Color(0x334FA3F7),
                rimNeutral: Color(0x1A8DA2C0),
                rimTopHighlight: Color(0x14F0F6FF),
                rowDivider: Color(0x124FA3F7),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A243C), Color(0xFF121A2C)],
                ),
              )
            : const HorizonThemeTokens(
                collection: ThemeCollection.arcticBlue,
                isDark: false,
                canvas: Color(0xFFF0F6FE),
                surface1: Color(0xFFFFFFFF),
                surface2: Color(0xFFE2EDFC),
                surface3: Color(0xFFD1E2FA),
                surface4: Color(0xFFBFD6F6),
                ionCyan: Color(0xFF1D4ED8), // Deep ice blue
                electricIndigo: Color(0xFF4338CA),
                luminousGold: Color(0xFF0284C7),
                onPrimary: Colors.white,
                surplus: Color(0xFF047857),
                outflow: Color(0xFFB91C1C),
                warning: Color(0xFF92400E),
                info: Color(0xFF2563EB),
                textHigh: Color(0xFF0F172A),
                textMedium: Color(0xFF334155),
                textLow: Color(0xFF64748B),
                rimCyan: Color(0x281D4ED8),
                rimCyanActive: Color(0x3D1D4ED8),
                rimDock: Color(0x1E0F172A),
                rimNeutral: Color(0x1A0F172A),
                rimTopHighlight: Colors.transparent,
                rowDivider: Color(0x140F172A),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE2EDFC), Color(0xFFFFFFFF)],
                ),
              );

      case ThemeCollection.ivorySand:
        return isDark
            ? const HorizonThemeTokens(
                collection: ThemeCollection.ivorySand,
                isDark: true,
                canvas: Color(0xFF161311),
                surface1: Color(0xFF201B17),
                surface2: Color(0xFF2B241E),
                surface3: Color(0xFF372E26),
                surface4: Color(0xFF43382F),
                ionCyan: Color(0xFFD4A373), // Sandstone Bronze
                electricIndigo: Color(0xFFE07A5F), // Warm Terracotta
                luminousGold: Color(0xFFCCD5AE),
                onPrimary: Color(0xFF161311),
                surplus: Color(0xFF34D399),
                outflow: Color(0xFFF87171),
                warning: Color(0xFFFBBF24),
                info: Color(0xFF60A5FA),
                textHigh: Color(0xFFFAF7F2),
                textMedium: Color(0xFFB3A99E),
                textLow: Color(0xFF746B62),
                rimCyan: Color(0x24D4A373),
                rimCyanActive: Color(0x3DD4A373),
                rimDock: Color(0x33D4A373),
                rimNeutral: Color(0x1AB3A99E),
                rimTopHighlight: Color(0x14FAF7F2),
                rowDivider: Color(0x12D4A373),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B241E), Color(0xFF201B17)],
                ),
              )
            : const HorizonThemeTokens(
                collection: ThemeCollection.ivorySand,
                isDark: false,
                canvas: Color(0xFFFBF9F5),
                surface1: Color(0xFFFFFFFF),
                surface2: Color(0xFFF3EFE6),
                surface3: Color(0xFFE6DFD2),
                surface4: Color(0xFFD8CFBF),
                ionCyan: Color(0xFF8C531B), // Bronze
                electricIndigo: Color(0xFFA04026),
                luminousGold: Color(0xFF586438),
                onPrimary: Colors.white,
                surplus: Color(0xFF047857),
                outflow: Color(0xFFB91C1C),
                warning: Color(0xFF92400E),
                info: Color(0xFF2563EB),
                textHigh: Color(0xFF1E1B18),
                textMedium: Color(0xFF544C44),
                textLow: Color(0xFF8C8174),
                rimCyan: Color(0x288C531B),
                rimCyanActive: Color(0x3D8C531B),
                rimDock: Color(0x1E1E1B18),
                rimNeutral: Color(0x1A1E1B18),
                rimTopHighlight: Colors.transparent,
                rowDivider: Color(0x141E1B18),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3EFE6), Color(0xFFFFFFFF)],
                ),
              );

      case ThemeCollection.amethystPulse:
        return isDark
            ? const HorizonThemeTokens(
                collection: ThemeCollection.amethystPulse,
                isDark: true,
                canvas: Color(0xFF130D1A),
                surface1: Color(0xFF1D1427),
                surface2: Color(0xFF281C36),
                surface3: Color(0xFF342546),
                surface4: Color(0xFF412E57),
                ionCyan: Color(0xFFC084FC), // Soft Violet
                electricIndigo: Color(0xFFE879F9), // Lavender
                luminousGold: Color(0xFFF472B6),
                onPrimary: Color(0xFF130D1A),
                surplus: Color(0xFF34D399),
                outflow: Color(0xFFF87171),
                warning: Color(0xFFFBBF24),
                info: Color(0xFF60A5FA),
                textHigh: Color(0xFFFAF5FF),
                textMedium: Color(0xFFAC9DBA),
                textLow: Color(0xFF6C5F79),
                rimCyan: Color(0x24C084FC),
                rimCyanActive: Color(0x3DC084FC),
                rimDock: Color(0x33C084FC),
                rimNeutral: Color(0x1AAC9DBA),
                rimTopHighlight: Color(0x14FAF5FF),
                rowDivider: Color(0x12C084FC),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF281C36), Color(0xFF1D1427)],
                ),
              )
            : const HorizonThemeTokens(
                collection: ThemeCollection.amethystPulse,
                isDark: false,
                canvas: Color(0xFFFAF5FF),
                surface1: Color(0xFFFFFFFF),
                surface2: Color(0xFFF3E8FF),
                surface3: Color(0xFFE9D5FF),
                surface4: Color(0xFFD8B4FE),
                ionCyan: Color(0xFF6B21A8), // Deep Violet
                electricIndigo: Color(0xFF86198F),
                luminousGold: Color(0xFF9333EA),
                onPrimary: Colors.white,
                surplus: Color(0xFF047857),
                outflow: Color(0xFFB91C1C),
                warning: Color(0xFF92400E),
                info: Color(0xFF2563EB),
                textHigh: Color(0xFF1A0B2E),
                textMedium: Color(0xFF4C346B),
                textLow: Color(0xFF7E639E),
                rimCyan: Color(0x286B21A8),
                rimCyanActive: Color(0x3D6B21A8),
                rimDock: Color(0x1E1A0B2E),
                rimNeutral: Color(0x1A1A0B2E),
                rimTopHighlight: Colors.transparent,
                rowDivider: Color(0x141A0B2E),
                cardGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3E8FF), Color(0xFFFFFFFF)],
                ),
              );
    }
  }

  /// Convenience lookup from active BuildContext.
  static HorizonThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<HorizonThemeTokens>() ??
        resolve(
          ThemeCollection.midnightAurora,
          Theme.of(context).brightness,
        );
  }

  @override
  ThemeExtension<HorizonThemeTokens> copyWith({
    ThemeCollection? collection,
    bool? isDark,
    Color? canvas,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? surface4,
    Color? ionCyan,
    Color? electricIndigo,
    Color? luminousGold,
    Color? onPrimary,
    Color? surplus,
    Color? outflow,
    Color? warning,
    Color? info,
    Color? textHigh,
    Color? textMedium,
    Color? textLow,
    Color? rimCyan,
    Color? rimCyanActive,
    Color? rimDock,
    Color? rimNeutral,
    Color? rimTopHighlight,
    Color? rowDivider,
    LinearGradient? cardGradient,
  }) {
    return HorizonThemeTokens(
      collection: collection ?? this.collection,
      isDark: isDark ?? this.isDark,
      canvas: canvas ?? this.canvas,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      surface4: surface4 ?? this.surface4,
      ionCyan: ionCyan ?? this.ionCyan,
      electricIndigo: electricIndigo ?? this.electricIndigo,
      luminousGold: luminousGold ?? this.luminousGold,
      onPrimary: onPrimary ?? this.onPrimary,
      surplus: surplus ?? this.surplus,
      outflow: outflow ?? this.outflow,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      textHigh: textHigh ?? this.textHigh,
      textMedium: textMedium ?? this.textMedium,
      textLow: textLow ?? this.textLow,
      rimCyan: rimCyan ?? this.rimCyan,
      rimCyanActive: rimCyanActive ?? this.rimCyanActive,
      rimDock: rimDock ?? this.rimDock,
      rimNeutral: rimNeutral ?? this.rimNeutral,
      rimTopHighlight: rimTopHighlight ?? this.rimTopHighlight,
      rowDivider: rowDivider ?? this.rowDivider,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  ThemeExtension<HorizonThemeTokens> lerp(
    covariant ThemeExtension<HorizonThemeTokens>? other,
    double t,
  ) {
    if (other is! HorizonThemeTokens) return this;
    return HorizonThemeTokens(
      collection: t < 0.5 ? collection : other.collection,
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      surface4: Color.lerp(surface4, other.surface4, t)!,
      ionCyan: Color.lerp(ionCyan, other.ionCyan, t)!,
      electricIndigo: Color.lerp(electricIndigo, other.electricIndigo, t)!,
      luminousGold: Color.lerp(luminousGold, other.luminousGold, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surplus: Color.lerp(surplus, other.surplus, t)!,
      outflow: Color.lerp(outflow, other.outflow, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textMedium: Color.lerp(textMedium, other.textMedium, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      rimCyan: Color.lerp(rimCyan, other.rimCyan, t)!,
      rimCyanActive: Color.lerp(rimCyanActive, other.rimCyanActive, t)!,
      rimDock: Color.lerp(rimDock, other.rimDock, t)!,
      rimNeutral: Color.lerp(rimNeutral, other.rimNeutral, t)!,
      rimTopHighlight: Color.lerp(rimTopHighlight, other.rimTopHighlight, t)!,
      rowDivider: Color.lerp(rowDivider, other.rowDivider, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
    );
  }
}
