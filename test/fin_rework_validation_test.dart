import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/profile/fin_settings_screen.dart';
import 'package:frontend/screens/profile/widgets/fin/fin_companion_widgets.dart';

class _MockAnalyticsRepo extends AnalyticsRepository {
  CompanionPreferences prefs = const CompanionPreferences();

  @override
  Future<ApiResponse<CompanionPreferences>> getCompanionPreferences() async {
    return ApiResponse(success: true, message: 'OK', data: prefs);
  }

  @override
  Future<ApiResponse<CompanionPreferences>> updateCompanionPreferences(
    CompanionPreferences p,
  ) async {
    prefs = p;
    return ApiResponse(success: true, message: 'Updated', data: p);
  }

  @override
  Future<ApiResponse<CompanionPreferences>> resetCompanionPreferences() async {
    prefs = const CompanionPreferences();
    return ApiResponse(success: true, message: 'Reset', data: prefs);
  }

  @override
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsCapability(
        supportedIntents: [],
        suggestedQuestions: [],
        maxDateRangeDays: 30,
        maxQuestionLength: 200,
        readOnly: false,
        privacyNotice: 'Private test notice',
      ),
    );
  }

  @override
  Future<ApiResponse<AnalyticsQueryResult>> queryAnalytics({
    String? question,
    String? intent,
    String? period,
    String? startDate,
    String? endDate,
    String? month,
    String? category,
    ConversationContext? conversationContext,
  }) async {
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsQueryResult(
        intent: 'total_spending',
        isRefusal: false,
        answer: 'Verified records',
        privacyNotice: 'Saved records only',
        characterState: 'idle',
        suggestions: [],
      ),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmAction(
    String capability,
    Map<String, dynamic> parameters,
  ) async {
    return const ApiResponse(success: true, message: 'OK', data: {});
  }

  @override
  Future<ApiResponse<List<SmartAlertItem>>> getProactiveAlerts({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
    AlertPreferences? preferences,
  }) async {
    return const ApiResponse(success: true, message: 'OK', data: []);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getInsights({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
  }) async {
    return const ApiResponse(success: true, message: 'OK', data: {});
  }
}

final _captureKey = GlobalKey();

void _setViewport(WidgetTester tester, Size size, {double textScale = 1.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    const dirPath = 'build/fin_redesign_screenshots';
    await Directory(dirPath).create(recursive: true);
    await File('$dirPath/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Widget _wrapScreen({
  required Widget child,
  required AnalyticsProvider provider,
  bool isDark = true,
  double textScale = 1.0,
  bool disableAnimations = true,
  Size size = const Size(393, 852),
}) {
  return ChangeNotifierProvider<AnalyticsProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RepaintBoundary(
            key: _captureKey,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final spaceGrotesk = File('assets/fonts/SpaceGrotesk.ttf');
    if (await spaceGrotesk.exists()) {
      final bytes = await spaceGrotesk.readAsBytes();
      final loader1 = FontLoader('Space Grotesk')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader1.load();
      final loader2 = FontLoader('SpaceGrotesk')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader2.load();
    }
    final plusJakarta = File('assets/fonts/PlusJakartaSans.ttf');
    if (await plusJakarta.exists()) {
      final bytes = await plusJakarta.readAsBytes();
      final loader = FontLoader('Plus Jakarta Sans')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
    try {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  group('FIN Live Motion System & Reusable Widgets', () {
    testWidgets('FinLiveCharacter renders across all 6 FinMotionStates without throwing', (
      tester,
    ) async {
      for (final motion in FinMotionState.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: FinLiveCharacter(
                  motionState: motion,
                  size: 120,
                  animationsEnabled: false,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(FinLiveCharacter), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('FinCharacterStage renders living character and interactive mood chips', (
      tester,
    ) async {
      FinMotionState selected = FinMotionState.idle;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: FinCharacterStage(
                currentMotion: selected,
                onMotionChanged: (m) => selected = m,
                animationsEnabled: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FinCharacterStage), findsOneWidget);
      expect(find.byType(FinLiveCharacter), findsOneWidget);

      // Verify all mood chips exist
      for (final motion in FinMotionState.values) {
        expect(find.text(motion.label), findsOneWidget);
      }

      // Tap Thinking chip
      await tester.tap(find.text('Thinking'));
      await tester.pumpAndSettle();
      expect(selected, FinMotionState.thinking);
    });

    testWidgets('FinStatusChip displays active, docked, and deactivated states', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Column(
              children: [
                FinStatusChip(isActive: true, isDocked: false, placement: 'Right Edge'),
                FinStatusChip(isActive: true, isDocked: true, placement: 'Dock Trigger'),
                FinStatusChip(isActive: false, isDocked: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ACTIVE & PRESENT'), findsOneWidget);
      expect(find.text('DOCKED REST'), findsOneWidget);
      expect(find.text('DEACTIVATED'), findsOneWidget);
      expect(find.text('RIGHT EDGE'), findsOneWidget);
    });

    testWidgets('FinSpeechPanel displays quotes and cycles on tap', (tester) async {
      int tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: FinSpeechPanel(
              quote: 'Testing financial wisdom',
              quoteIndex: 0,
              totalQuotes: 4,
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      expect(find.text('Testing financial wisdom'), findsOneWidget);
      expect(find.text('Tap to cycle'), findsOneWidget);

      await tester.tap(find.byType(FinSpeechPanel));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('FinPlacementSelector switches options and triggers reset anchor', (
      tester,
    ) async {
      String current = 'Right Edge';
      bool resetClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: FinPlacementSelector(
              placement: current,
              onPlacementChanged: (m) => current = m,
              onResetPosition: () => resetClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('RIGHT EDGE'), findsWidgets);
      expect(find.text('Left Edge'), findsOneWidget);
      expect(find.text('Dock Trigger'), findsOneWidget);

      await tester.tap(find.text('Left Edge'));
      await tester.pumpAndSettle();
      expect(current, 'Left Edge');

      await tester.tap(find.text('RESET ANCHOR'));
      await tester.pumpAndSettle();
      expect(resetClicked, true);
    });

    testWidgets('FinGuidanceStyleCard switches between helpful and minimal', (
      tester,
    ) async {
      String freq = 'standard';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: FinGuidanceStyleCard(
              frequency: freq,
              onFrequencyChanged: (f) => freq = f,
            ),
          ),
        ),
      );

      expect(find.text('Helpful Insights'), findsOneWidget);
      expect(find.text('Minimal Alerts'), findsOneWidget);

      await tester.tap(find.text('Minimal Alerts'));
      await tester.pumpAndSettle();
      expect(freq, 'minimal');
    });

    testWidgets('FinDataBoundaryPanel renders all 3 key safeguards without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: FinDataBoundaryPanel(),
          ),
        ),
      );

      expect(find.text('Data Boundaries & Privacy'), findsOneWidget);
      expect(find.text('Authorized records only'), findsOneWidget);
      expect(find.text('No direct bank account link'), findsOneWidget);
      expect(find.text('No inbox or SMS access'), findsOneWidget);
      expect(find.text('Bounded, deterministic backend analysis'), findsOneWidget);
    });
  });

  group('FinSettingsScreen Full Interaction & Visual Captures', () {
    testWidgets('Full flow: toggle presence, change placement, save preferences', (
      tester,
    ) async {
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Hero
      expect(find.text('FIN Companion'), findsOneWidget);
      expect(find.text('Companion Settings'), findsOneWidget);
      expect(find.text('ACTIVE & PRESENT'), findsOneWidget);

      // Verify Presence toggles
      expect(find.text('Show FIN on Home Dashboard'), findsOneWidget);
      expect(find.text('Show FIN in Budgets & Envelopes'), findsOneWidget);

      // Cycle quotes by tapping speech panel
      final initialQuote = find.textContaining('spending patterns');
      expect(initialQuote, findsOneWidget);
      await tester.tap(find.byType(FinSpeechPanel));
      await tester.pumpAndSettle();
      expect(find.textContaining('mid-month'), findsOneWidget);

      // Select 'Left Edge'
      await tester.ensureVisible(find.text('Left Edge'));
      await tester.tap(find.text('Left Edge'));
      await tester.pumpAndSettle();

      // Select 'Minimal Alerts'
      await tester.ensureVisible(find.text('Minimal Alerts'));
      await tester.tap(find.text('Minimal Alerts'));
      await tester.pumpAndSettle();

      // Tap Save Preferences
      await tester.ensureVisible(find.text('SAVE PREFERENCES'));
      await tester.tap(find.text('SAVE PREFERENCES'));
      await tester.pumpAndSettle();

      // Check SnackBar confirmation
      expect(find.text('Preferences Synchronized'), findsOneWidget);
      expect(repo.prefs.edgePosition, 'left');
      expect(repo.prefs.proactiveHints, false);

      // Scroll up to Deactivate
      await tester.ensureVisible(find.text('DEACTIVATE'));
      await tester.tap(find.text('DEACTIVATE'));
      await tester.pumpAndSettle();
      expect(find.text('RESTORE'), findsOneWidget);
      expect(find.text('DEACTIVATED'), findsOneWidget);

      // Restore FIN
      await tester.ensureVisible(find.text('RESTORE'));
      await tester.tap(find.text('RESTORE'));
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE & PRESENT'), findsOneWidget);
    });

    // ── Generate Screenshots for all required states ──────────────────────────
    testWidgets('Capture: FIN settings dark mode (393x852)', (tester) async {
      const size = Size(393, 852);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, '01_fin_settings_dark_393');
    });

    testWidgets('Capture: FIN settings light mode (393x852)', (tester) async {
      const size = Size(393, 852);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: false,
          size: size,
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, '02_fin_settings_light_393');
    });

    testWidgets('Capture: FIN settings compact width (320x568)', (tester) async {
      const size = Size(320, 568);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '03_fin_settings_compact_320');
    });

    testWidgets('Capture: FIN settings tablet width (1024x768)', (tester) async {
      const size = Size(1024, 768);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '04_fin_settings_tablet_1024');
    });

    testWidgets('Capture: FIN settings 2x text scale (393x852)', (tester) async {
      const size = Size(393, 852);
      _setViewport(tester, size, textScale: 2.0);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          textScale: 2.0,
          size: size,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '05_fin_settings_2x_text_scale');
    });

    testWidgets('Capture: FIN motion states gallery (Listening & Supportive)', (
      tester,
    ) async {
      const size = Size(393, 852);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Listening mood
      await tester.ensureVisible(find.text('Listening'));
      await tester.tap(find.text('Listening'));
      await tester.pumpAndSettle();
      await _capture(tester, '06_fin_motion_state_listening');

      // Switch to Supportive mood
      await tester.ensureVisible(find.text('Supportive'));
      await tester.tap(find.text('Supportive'));
      await tester.pumpAndSettle();
      await _capture(tester, '07_fin_motion_state_supportive');

      // Switch to Alert mood
      await tester.ensureVisible(find.text('Alert'));
      await tester.tap(find.text('Alert'));
      await tester.pumpAndSettle();
      await _capture(tester, '08_fin_motion_state_alert');
    });

    testWidgets('Capture: FIN deactivated / hidden state', (tester) async {
      const size = Size(393, 852);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();

      // Deactivate FIN
      await tester.ensureVisible(find.text('DEACTIVATE'));
      await tester.tap(find.text('DEACTIVATE'));
      await tester.pumpAndSettle();
      // Scroll back up to capture the deactivated hero state
      await tester.ensureVisible(find.text('FIN Companion'));
      await tester.pumpAndSettle();
      expect(find.text('DEACTIVATED'), findsOneWidget);
      await _capture(tester, '09_fin_settings_deactivated');
    });

    testWidgets('Capture: FIN save-preferences confirmation state', (tester) async {
      const size = Size(393, 852);
      _setViewport(tester, size);
      final repo = _MockAnalyticsRepo();
      final provider = AnalyticsProvider(repository: repo);

      await tester.pumpWidget(
        _wrapScreen(
          child: const FinSettingsScreen(),
          provider: provider,
          isDark: true,
          size: size,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.ensureVisible(find.text('SAVE PREFERENCES'));
      await tester.tap(find.text('SAVE PREFERENCES'));
      await tester.pump();
      await _capture(tester, '10_fin_settings_saved_feedback');
    });

    // ── Responsive viewports matrix verification ──────────────────────────────
    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(393, 852),
      const Size(600, 960),
      const Size(1024, 768),
    ]) {
      testWidgets('Responsive check: $size dark mode layout stability', (
        tester,
      ) async {
        _setViewport(tester, size);
        final repo = _MockAnalyticsRepo();
        final provider = AnalyticsProvider(repository: repo);

        await tester.pumpWidget(
          _wrapScreen(
            child: const FinSettingsScreen(),
            provider: provider,
            isDark: true,
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(FinSettingsScreen), findsOneWidget);
        expect(find.byType(FinCompanionHero), findsOneWidget);
        expect(find.byType(FinDataBoundaryPanel), findsOneWidget);
      });
    }
  });
}
