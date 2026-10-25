import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

import '../horizon/theme/horizon_theme_tokens.dart';
import '../horizon/tokens/horizon_dimensions.dart';
import '../horizon/tokens/horizon_typography.dart';
import 'fin_track_theme_tokens.dart';
import 'theme_collection.dart';

/// Single authoritative global theme factory for FinTrack // HORIZON.
/// Completely bridges HorizonThemeTokens, FinTrackThemeTokens, Material-3 ThemeData,
/// and accessible platform status/navigation bar styling.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme =>
      buildTheme(ThemeCollection.midnightAurora, Brightness.light);

  static ThemeData get darkTheme =>
      buildTheme(ThemeCollection.midnightAurora, Brightness.dark);

  static ThemeData buildTheme(
    ThemeCollection collection,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final finTokens = FinTrackThemeTokens.resolve(collection, brightness);
    final hTokens = HorizonThemeTokens.resolve(collection, brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: hTokens.ionCyan,
      onPrimary: hTokens.onPrimary,
      primaryContainer: isDark ? hTokens.surface3 : hTokens.surface2,
      onPrimaryContainer: hTokens.textHigh,
      secondary: hTokens.electricIndigo,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF313EA0)
          : const Color(0xFFDFE0FF),
      onSecondaryContainer: hTokens.textHigh,
      tertiary: hTokens.luminousGold,
      onTertiary: Colors.black,
      tertiaryContainer: isDark
          ? const Color(0xFF74520C)
          : const Color(0xFFFFDEAB),
      onTertiaryContainer: hTokens.textHigh,
      error: hTokens.outflow,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: hTokens.textHigh,
      surface: hTokens.surface1,
      onSurface: hTokens.textHigh,
      onSurfaceVariant: hTokens.textMedium,
      outline: hTokens.rimNeutral,
      outlineVariant: hTokens.rimCyan,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF0E1626),
      onInverseSurface: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F8FC),
      inversePrimary: hTokens.ionCyan,
    );

    final textTheme = HorizonTypography.createTextTheme(
      hTokens.textHigh,
      hTokens.textMedium,
      hTokens.textLow,
    );

    OutlineInputBorder createInputBorder(
      Color borderColor, [
      double width = 1,
    ]) {
      return OutlineInputBorder(
        borderRadius: HorizonDimensions.borderDefault,
        borderSide: BorderSide(color: borderColor, width: width),
      );
    }

    final systemOverlay = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: hTokens.canvas,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: hTokens.canvas,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: hTokens.canvas,
      dividerColor: hTokens.rowDivider,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [finTokens, hTokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: hTokens.textHigh,
        systemOverlayStyle: systemOverlay,
        titleTextStyle: HorizonTypography.headlineSm.copyWith(
          color: hTokens.textHigh,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: hTokens.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: HorizonDimensions.borderLG,
          side: BorderSide(color: hTokens.rimNeutral),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: hTokens.surface1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HorizonDimensions.marginMobile,
          vertical: 16,
        ),
        border: createInputBorder(hTokens.rimNeutral),
        enabledBorder: createInputBorder(hTokens.rimNeutral),
        focusedBorder: createInputBorder(hTokens.ionCyan, 1.5),
        errorBorder: createInputBorder(hTokens.outflow),
        focusedErrorBorder: createInputBorder(hTokens.outflow, 1.5),
        labelStyle: HorizonTypography.bodyMd.copyWith(
          color: hTokens.textMedium,
        ),
        hintStyle: HorizonTypography.bodyMd.copyWith(color: hTokens.textLow),
        prefixStyle: HorizonTypography.headlineSm.copyWith(
          color: hTokens.ionCyan,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: hTokens.ionCyan,
          foregroundColor: hTokens.onPrimary,
          disabledBackgroundColor: hTokens.ionCyan.withValues(alpha: 0.35),
          disabledForegroundColor: hTokens.onPrimary.withValues(alpha: 0.5),
          minimumSize: const Size(88, HorizonDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: HorizonDimensions.borderDefault,
          ),
          textStyle: HorizonTypography.labelCaps.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
            color: hTokens.onPrimary,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hTokens.textHigh,
          backgroundColor: hTokens.surface2,
          minimumSize: const Size(88, HorizonDimensions.buttonHeight),
          side: BorderSide(color: hTokens.rimCyanActive),
          shape: RoundedRectangleBorder(
            borderRadius: HorizonDimensions.borderDefault,
          ),
          textStyle: HorizonTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: hTokens.textHigh,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: hTokens.ionCyan,
          textStyle: HorizonTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        backgroundColor: hTokens.ionCyan,
        foregroundColor: hTokens.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: HorizonDimensions.borderMD),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? hTokens.textLow
                : hTokens.textHigh,
          ),
          overlayColor: WidgetStatePropertyAll(
            hTokens.ionCyan.withValues(alpha: 0.1),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: hTokens.ionCyan,
        unselectedLabelColor: hTokens.textMedium,
        indicatorColor: hTokens.ionCyan,
        dividerColor: hTokens.rowDivider,
        labelStyle: HorizonTypography.labelCaps.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: HorizonTypography.labelCaps.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: hTokens.surface1,
        selectedColor: hTokens.surface2,
        side: BorderSide(color: hTokens.rimNeutral),
        shape: RoundedRectangleBorder(
          borderRadius: HorizonDimensions.borderDefault,
        ),
        labelStyle: HorizonTypography.bodySm.copyWith(
          color: hTokens.textMedium,
        ),
        secondaryLabelStyle: HorizonTypography.bodySm.copyWith(
          color: hTokens.ionCyan,
          fontWeight: FontWeight.w600,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hTokens.ionCyan;
          }
          return hTokens.textMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hTokens.ionCyan.withValues(alpha: 0.35);
          }
          return hTokens.rowDivider;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hTokens.ionCyan
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(hTokens.onPrimary),
        side: BorderSide(color: hTokens.rimNeutral, width: 1.4),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hTokens.ionCyan
              : hTokens.textMedium,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: hTokens.surface3,
        indicatorColor: hTokens.ionCyan.withValues(alpha: isDark ? 0.20 : 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? hTokens.ionCyan
                : hTokens.textMedium,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? hTokens.ionCyan
                : hTokens.textMedium,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: hTokens.surface1,
        elevation: 0,
        indicatorColor: hTokens.ionCyan.withValues(alpha: isDark ? 0.20 : 0.14),
        selectedLabelTextStyle: TextStyle(
          color: hTokens.ionCyan,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: hTokens.textMedium,
          fontSize: 11,
        ),
        selectedIconTheme: IconThemeData(color: hTokens.ionCyan),
        unselectedIconTheme: IconThemeData(color: hTokens.textMedium),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: hTokens.ionCyan,
        linearTrackColor: hTokens.surface3,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? hTokens.surface3 : hTokens.surface4,
        contentTextStyle: HorizonTypography.bodySm.copyWith(
          color: hTokens.textHigh,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: hTokens.rimNeutral),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: hTokens.surface2,
        elevation: 24,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: HorizonDimensions.borderLG,
          side: BorderSide(color: hTokens.rimCyan),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: hTokens.surface3,
        modalBackgroundColor: hTokens.surface3,
        showDragHandle: true,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HorizonDimensions.radiusXL),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hTokens.rowDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
