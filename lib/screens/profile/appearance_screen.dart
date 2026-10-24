import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/horizon/horizon.dart';
import '../../core/theme/theme_collection.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';

/// FinTrack // HORIZON — Appearance Preferences Screen.
/// Provides real-time theme collection switching across 6 curated identities
/// and dark/light display modes with a live interactive telemetry preview.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = HorizonThemeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.watch<CurrencyProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: tokens.textHigh),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.ionCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'HORIZON // PROTOCOL',
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Text(
              'Appearance Preferences',
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, HorizonDimensions.dockClearance),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Live Miniature Telemetry Preview
                _LiveMiniaturePreview(
                  tokens: tokens,
                  collection: themeProvider.collection,
                  displayMode: themeProvider.displayMode,
                  isDark: isDark,
                  currencySymbol: currency.currencySymbol,
                ),
                const SizedBox(height: 20),

                // 2. Display Mode Selector
                Text(
                  'DISPLAY MODE',
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.textMedium,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _DisplayModeSelector(
                  selectedMode: themeProvider.displayMode,
                  tokens: tokens,
                  onSelect: (mode) => themeProvider.setDisplayMode(mode),
                ),
                const SizedBox(height: 24),

                // 3. Curated Themes Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'THEME COLLECTION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.textMedium,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.ionCyan.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '6 PALETTES',
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.ionCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your financial instrumentation identity and accents.',
                  style: HorizonTypography.bodySm.copyWith(color: tokens.textMedium),
                ),
                const SizedBox(height: 12),

                // 4. Six Curated Theme Cards
                if (isWide)
                  _WideThemeGrid(
                    currentCollection: themeProvider.collection,
                    isDark: isDark,
                    tokens: tokens,
                    onSelect: (collection) => themeProvider.setCollection(collection),
                  )
                else
                  _MobileThemeList(
                    currentCollection: themeProvider.collection,
                    isDark: isDark,
                    tokens: tokens,
                    onSelect: (collection) => themeProvider.setCollection(collection),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact live cockpit preview reflecting the active theme in real time.
class _LiveMiniaturePreview extends StatelessWidget {
  const _LiveMiniaturePreview({
    required this.tokens,
    required this.collection,
    required this.displayMode,
    required this.isDark,
    required this.currencySymbol,
  });

  final HorizonThemeTokens tokens;
  final ThemeCollection collection;
  final AppDisplayMode displayMode;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: HorizonDimensions.borderLG,
        border: Border.all(color: tokens.rimNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Eyebrow + Active Identity Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tokens.ionCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'FinTrack Theme Preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: tokens.textHigh,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tokens.rimCyan),
                ),
                child: Text(
                  collection.displayName.toUpperCase(),
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Miniature Cockpit Hero Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surface2,
              borderRadius: HorizonDimensions.borderMD,
              border: Border.all(color: tokens.rimCyanActive),
              gradient: isDark ? tokens.cardGradient : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL NET LIQUIDITY',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: tokens.textMedium,
                        fontSize: 9,
                      ),
                    ),
                    Icon(Icons.shield_outlined, size: 14, color: tokens.ionCyan),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol 124,580.00',
                  style: HorizonTypography.tabularAmountLg.copyWith(
                    color: tokens.textHigh,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                // Sparkline bar preview
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.ionCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.electricIndigo,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.luminousGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Inflow / Outflow Telemetry Ticker
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 12, color: tokens.surplus),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'INFLOW',
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 8,
                                color: tokens.textMedium,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '+$currencySymbol 18,400',
                                style: HorizonTypography.tabularAmountSm.copyWith(
                                  color: tokens.surplus,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.rimNeutral),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 12, color: tokens.outflow),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'OUTFLOW',
                              style: HorizonTypography.labelCaps.copyWith(
                                fontSize: 8,
                                color: tokens.textMedium,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '-$currencySymbol 6,250',
                                style: HorizonTypography.tabularAmountSm.copyWith(
                                  color: tokens.outflow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Display Mode (System, Dark, Light) selector.
class _DisplayModeSelector extends StatelessWidget {
  const _DisplayModeSelector({
    required this.selectedMode,
    required this.tokens,
    required this.onSelect,
  });

  final AppDisplayMode selectedMode;
  final HorizonThemeTokens tokens;
  final ValueChanged<AppDisplayMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppDisplayMode.values.map((mode) {
        final isSelected = selectedMode == mode;
        final icon = mode == AppDisplayMode.system
            ? Icons.brightness_auto_rounded
            : mode == AppDisplayMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? tokens.surface3 : tokens.surface1,
                  borderRadius: HorizonDimensions.borderMD,
                  border: Border.all(
                    color: isSelected ? tokens.rimCyanActive : tokens.rimNeutral,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? tokens.ionCyan : tokens.textMedium,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        mode.displayName,
                        style: HorizonTypography.labelCaps.copyWith(
                          color: isSelected ? tokens.textHigh : tokens.textMedium,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Swatch and data definition for each of the 6 themes.
class _ThemeCardSpec {
  const _ThemeCardSpec({
    required this.collection,
    required this.swatches,
    this.isDefault = false,
  });

  final ThemeCollection collection;
  final List<Color> swatches; // Canvas, Surface, Primary, Secondary
  final bool isDefault;
}

const List<_ThemeCardSpec> _allThemes = [
  _ThemeCardSpec(
    collection: ThemeCollection.midnightAurora,
    isDefault: true,
    swatches: [
      Color(0xFF080D17), // Deep Navy Void
      Color(0xFF172338), // Surface 2
      Color(0xFF75DEED), // Ion Cyan
      Color(0xFF8996FC), // Electric Indigo
    ],
  ),
  _ThemeCardSpec(
    collection: ThemeCollection.obsidianJade,
    swatches: [
      Color(0xFF090D0D), // Charcoal Black
      Color(0xFF152220), // Surface 2
      Color(0xFF38D5B0), // Emerald Jade
      Color(0xFF2DD4BF), // Soft Teal
    ],
  ),
  _ThemeCardSpec(
    collection: ThemeCollection.graphiteChampagne,
    swatches: [
      Color(0xFF12151B), // Graphite
      Color(0xFF242833), // Surface 2
      Color(0xFFD6A668), // Champagne
      Color(0xFFE6BE85), // Soft Gold
    ],
  ),
  _ThemeCardSpec(
    collection: ThemeCollection.arcticBlue,
    swatches: [
      Color(0xFF0B111E), // Midnight Navy
      Color(0xFF1A243C), // Surface 2
      Color(0xFF4FA3F7), // Ice Blue
      Color(0xFF818CF8), // Midnight Indigo
    ],
  ),
  _ThemeCardSpec(
    collection: ThemeCollection.ivorySand,
    swatches: [
      Color(0xFF161311), // Warm Earth
      Color(0xFF2B241E), // Surface 2
      Color(0xFFD4A373), // Sandstone Bronze
      Color(0xFFE07A5F), // Terracotta
    ],
  ),
  _ThemeCardSpec(
    collection: ThemeCollection.amethystPulse,
    swatches: [
      Color(0xFF130D1A), // Deep Plum
      Color(0xFF281C36), // Surface 2
      Color(0xFFC084FC), // Soft Violet
      Color(0xFFE879F9), // Lavender
    ],
  ),
];

class _MobileThemeList extends StatelessWidget {
  const _MobileThemeList({
    required this.currentCollection,
    required this.isDark,
    required this.tokens,
    required this.onSelect,
  });

  final ThemeCollection currentCollection;
  final bool isDark;
  final HorizonThemeTokens tokens;
  final ValueChanged<ThemeCollection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _allThemes.map((spec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SelectableThemeCard(
            spec: spec,
            isSelected: spec.collection == currentCollection,
            tokens: tokens,
            onTap: () => onSelect(spec.collection),
          ),
        );
      }).toList(),
    );
  }
}

class _WideThemeGrid extends StatelessWidget {
  const _WideThemeGrid({
    required this.currentCollection,
    required this.isDark,
    required this.tokens,
    required this.onSelect,
  });

  final ThemeCollection currentCollection;
  final bool isDark;
  final HorizonThemeTokens tokens;
  final ValueChanged<ThemeCollection> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allThemes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final spec = _allThemes[index];
            return _SelectableThemeCard(
              spec: spec,
              isSelected: spec.collection == currentCollection,
              tokens: tokens,
              onTap: () => onSelect(spec.collection),
            );
          },
        );
      },
    );
  }
}

class _SelectableThemeCard extends StatelessWidget {
  const _SelectableThemeCard({
    required this.spec,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final _ThemeCardSpec spec;
  final bool isSelected;
  final HorizonThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = spec.swatches[2];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? tokens.surface2 : tokens.surface1,
          borderRadius: HorizonDimensions.borderLG,
          border: Border.all(
            color: isSelected ? primaryColor : tokens.rimNeutral,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Title, Badges, Radio Indicator
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          spec.collection.displayName,
                          style: HorizonTypography.bodyMd.copyWith(
                            color: tokens.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (spec.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: tokens.surface3,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tokens.rimNeutral),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: HorizonTypography.labelCaps.copyWith(
                              fontSize: 8,
                              color: tokens.textMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primaryColor : tokens.rimNeutral,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              spec.collection.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HorizonTypography.bodySm.copyWith(
                color: tokens.textMedium,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),

            // 4 Color Swatches
            Row(
              children: [
                for (int i = 0; i < spec.swatches.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: spec.swatches[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.rimNeutral,
                        width: 1,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: HorizonTypography.labelCaps.copyWith(
                        color: primaryColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
