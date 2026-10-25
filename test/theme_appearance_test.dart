import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/theme/fin_track_theme_tokens.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/profile/appearance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Six Premium Theme Identities Tokens', () {
    test('Midnight Aurora default dark tokens match specification', () {
      final tokens = FinTrackThemeTokens.midnightAuroraDark;
      expect(tokens.background, const Color(0xFF080D17));
      expect(tokens.surface, const Color(0xFF0E1626));
      expect(tokens.primary, const Color(0xFF75DEED));
      expect(tokens.secondary, const Color(0xFF8996FC));
    });

    test('Graphite & Champagne dark tokens match specification', () {
      final tokens = FinTrackThemeTokens.graphiteChampagneDark;
      expect(tokens.background, const Color(0xFF171B24));
      expect(tokens.surface, const Color(0xFF252934));
      expect(tokens.primary, const Color(0xFFD6A668));
      expect(tokens.secondary, const Color(0xFFE6BE85));
      expect(tokens.textPrimary, const Color(0xFFF4EFE7));
      expect(tokens.textSecondary, const Color(0xFFB5AFAB));
    });

    test('Semantic colors are preserved across all 6 themes', () {
      for (final collection in ThemeCollection.values) {
        final dark = FinTrackThemeTokens.resolve(collection, Brightness.dark);
        final light = FinTrackThemeTokens.resolve(collection, Brightness.light);

        expect(dark.danger, isNotNull);
        expect(dark.success, isNotNull);
        expect(dark.warning, isNotNull);
        expect(light.danger, isNotNull);
        expect(light.success, isNotNull);
        expect(light.warning, isNotNull);
      }
    });

    test('Preserves original FinTrack brand logo aurora gradient', () {
      expect(
        AppColors.auroraGradient.colors,
        containsAllInOrder([
          const Color(0xFF38D5B0),
          const Color(0xFF2DD4BF),
          const Color(0xFF159B82),
        ]),
      );
    });

    test('All 6 themes resolve correctly in dark and light mode', () {
      expect(ThemeCollection.values.length, 6);
      for (final col in ThemeCollection.values) {
        final dark = FinTrackThemeTokens.resolve(col, Brightness.dark);
        final light = FinTrackThemeTokens.resolve(col, Brightness.light);
        expect(dark.background, isNotNull);
        expect(light.background, isNotNull);
        expect(dark.primary, isNotNull);
        expect(light.primary, isNotNull);
      }
    });
  });

  group('ThemeProvider State & Immediate Switching', () {
    test('Initializes with Midnight Aurora by default for new installs', () {
      final provider = ThemeProvider();
      expect(provider.collection, ThemeCollection.midnightAurora);
      expect(provider.displayMode, AppDisplayMode.system);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('Switches theme collection immediately without restart', () async {
      final provider = ThemeProvider();
      await provider.initialize();

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setCollection(ThemeCollection.arcticBlue);
      expect(provider.collection, ThemeCollection.arcticBlue);
      expect(notifyCount, greaterThanOrEqualTo(1));

      // ThemeData updates immediately
      expect(
        provider.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF0B111E),
      );
      expect(provider.darkTheme.colorScheme.primary, const Color(0xFF4FA3F7));

      // Check persistence
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'arctic_blue',
      );
    });

    test('Switches display mode immediately and persists', () async {
      final provider = ThemeProvider();
      await provider.setDisplayMode(AppDisplayMode.dark);

      expect(provider.displayMode, AppDisplayMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeProvider.prefDisplayModeKey), 'dark');
    });
  });

  group('AppearanceScreen Widget Integration', () {
    testWidgets(
      'renders all 6 theme collections, preview, and switches theme',
      (tester) async {
        final themeProvider = ThemeProvider();
        final currencyProvider = CurrencyProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
              ChangeNotifierProvider<CurrencyProvider>.value(
                value: currencyProvider,
              ),
            ],
            child: MaterialApp(
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              home: const AppearanceScreen(),
            ),
          ),
        );

        // Verify title & sections
        expect(find.text('Appearance Preferences'), findsOneWidget);
        expect(find.text('HORIZON // PROTOCOL'), findsOneWidget);
        expect(find.text('THEME COLLECTION'), findsOneWidget);

        // Verify all 6 themes are rendered
        expect(find.text('Midnight Aurora'), findsWidgets);
        expect(find.text('Obsidian Jade'), findsWidgets);
        expect(find.text('Graphite Champagne'), findsWidgets);
        expect(find.text('Arctic Blue'), findsWidgets);
        expect(find.text('Ivory Sand'), findsWidgets);
        expect(find.text('Amethyst Pulse'), findsWidgets);

        // Verify display mode pills
        expect(find.text('System default'), findsWidgets);
        expect(find.text('Dark mode'), findsWidgets);
        expect(find.text('Light mode'), findsWidgets);

        // Tap to switch to Obsidian Jade
        await tester.tap(find.text('Obsidian Jade').first);
        await tester.pumpAndSettle();

        expect(themeProvider.collection, ThemeCollection.obsidianJade);

        // Tap to switch display mode to Dark
        await tester.tap(find.text('Dark mode').first);
        await tester.pumpAndSettle();

        expect(themeProvider.displayMode, AppDisplayMode.dark);
      },
    );
  });
}
