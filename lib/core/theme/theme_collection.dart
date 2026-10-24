import 'package:flutter/material.dart';

/// Available curated theme collections in FinTrack // HORIZON.
enum ThemeCollection {
  midnightAurora(
    displayName: 'Midnight Aurora',
    storageKey: 'midnight_aurora',
    description: 'Deep navy, ion cyan & electric indigo telemetry',
    logoAssetPath: 'assets/branding/logo_arctic_blue.png',
  ),
  obsidianJade(
    displayName: 'Obsidian Jade',
    storageKey: 'obsidian_jade',
    description: 'Charcoal black, emerald jade & soft teal accents',
    logoAssetPath: 'assets/branding/logo_obsidian_jade.png',
  ),
  graphiteChampagne(
    displayName: 'Graphite Champagne',
    storageKey: 'graphite_champagne',
    description: 'Elegant graphite, champagne & muted gold highlights',
    logoAssetPath: 'assets/branding/logo_graphite_champagne.png',
  ),
  arcticBlue(
    displayName: 'Arctic Blue',
    storageKey: 'arctic_blue',
    description: 'Cool white, ice blue & midnight blue precision',
    logoAssetPath: 'assets/branding/logo_arctic_blue.png',
  ),
  ivorySand(
    displayName: 'Ivory Sand',
    storageKey: 'ivory_sand',
    description: 'Warm ivory, sandstone & bronze financial accents',
    logoAssetPath: 'assets/branding/logo_graphite_champagne.png',
  ),
  amethystPulse(
    displayName: 'Amethyst Pulse',
    storageKey: 'amethyst_pulse',
    description: 'Deep plum, soft violet & lavender highlights',
    logoAssetPath: 'assets/branding/logo_arctic_blue.png',
  );

  const ThemeCollection({
    required this.displayName,
    required this.storageKey,
    required this.description,
    required this.logoAssetPath,
  });

  final String displayName;
  final String storageKey;
  final String description;
  final String logoAssetPath;

  /// Stable key shared with the Android launcher activity aliases.
  String get launcherIconKey => storageKey;

  static ThemeCollection fromKey(String? key) {
    if (key == null) return ThemeCollection.midnightAurora;
    return ThemeCollection.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => ThemeCollection.midnightAurora,
    );
  }
}

/// Display mode preferences (System, Light, Dark).
enum AppDisplayMode {
  system(
    displayName: 'System default',
    storageKey: 'system',
    themeMode: ThemeMode.system,
    description: 'Matches your device system light or dark settings',
  ),
  dark(
    displayName: 'Dark mode',
    storageKey: 'dark',
    themeMode: ThemeMode.dark,
    description: 'Rich dark tones optimized for OLED/night telemetry',
  ),
  light(
    displayName: 'Light mode',
    storageKey: 'light',
    themeMode: ThemeMode.light,
    description: 'Crisp surfaces and institutional high contrast',
  );

  const AppDisplayMode({
    required this.displayName,
    required this.storageKey,
    required this.themeMode,
    required this.description,
  });

  final String displayName;
  final String storageKey;
  final ThemeMode themeMode;
  final String description;

  static AppDisplayMode fromKey(String? key) {
    if (key == null) return AppDisplayMode.system;
    return AppDisplayMode.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => AppDisplayMode.system,
    );
  }
}
