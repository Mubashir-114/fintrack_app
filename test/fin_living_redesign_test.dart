import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/floating_bottom_navigation.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/analytics/widgets/fin_character.dart';
import 'package:frontend/screens/analytics/widgets/global_fin_overlay.dart';
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;

class _DelayedRepository extends MockPhase5FRepository {
  final response = Completer<ApiResponse<AnalyticsQueryResult>>();
  final action = Completer<ApiResponse<Map<String, dynamic>>>();
  int queryCount = 0;
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
  }) {
    queryCount++;
    return response.future;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmAction(
    String capability,
    Map<String, dynamic> parameters,
  ) => action.future;
}

const _preview = FinActionPreview(
  capability: 'create_goal',
  title: 'Goal',
  description: 'Review',
  parameters: {},
  impact: 'Creates a saved goal',
);
const _answer = ApiResponse(
  success: true,
  message: 'OK',
  data: AnalyticsQueryResult(
    intent: 'total_spending',
    isRefusal: false,
    answer: 'Saved-record analysis complete.',
    privacyNotice: 'Approved records only',
    characterState: 'explaining',
    suggestions: [],
  ),
);
final _captureKey = GlobalKey();

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  AnalyticsProvider provider, {
  bool dark = true,
  MediaQueryData Function(MediaQueryData)? media,
}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    observers: [FinOverlayObserver()],
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Scaffold(
          body: Stack(
            children: [
              Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(title: Text('Dialog above FIN')),
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
              const GlobalFinOverlay(),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (_, state) =>
            AnalyticsScreen(initialQuestion: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/budgets',
        builder: (_, _) => const Scaffold(body: Text('Real budgets route')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp.router(
      theme: AppTheme.buildTheme(
        ThemeCollection.graphiteChampagne,
        dark ? Brightness.dark : Brightness.light,
      ),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data:
            media?.call(MediaQuery.of(context)) ??
            MediaQuery.of(context).copyWith(disableAnimations: true),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
    ),
  );
}

Widget _shellApp(AnalyticsProvider provider) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    observers: [FinOverlayObserver()],
    routes: [
      ShellRoute(
        observers: [FinOverlayObserver()],
        builder: (_, _, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const Scaffold(
              key: ValueKey('financial_content'),
              body: Center(child: Text('Saved financial records')),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('FIN_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/fin_previews').create(recursive: true);
    await File(
      'build/fin_previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
    CacheService.setUserId(9001);
  });
  setUpAll(() async {
    if (!const bool.fromEnvironment('FIN_CAPTURE')) return;
    final fontPath = Platform.isWindows
        ? 'C:/Windows/Fonts/segoeui.ttf'
        : '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';
    final font = File(fontPath);
    if (await font.exists()) {
      final loader = FontLoader('Roboto')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(1024, 768),
  ]) {
    for (final dark in [true, false]) {
      testWidgets('mini panel fits $size in ${dark ? "dark" : "light"}', (
        tester,
      ) async {
        _viewport(tester, size);
        final provider = AnalyticsProvider(repository: MockPhase5FRepository());
        await tester.pumpWidget(_app(provider, dark: dark));
        await tester.pumpAndSettle();
        await _capture(
          tester,
          'peek_${size.width.toInt()}_${dark ? "dark" : "light"}',
        );
        await tester.tap(
          find.byKey(const ValueKey('global_fin_peeking_character')),
        );
        await tester.pumpAndSettle();
        final rect = tester.getRect(
          find.byKey(const ValueKey('global_fin_action_panel')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        await _capture(
          tester,
          'mini_${size.width.toInt()}_${dark ? "dark" : "light"}',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('keyboard removes hit targets and never reopens mini panel', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('global_fin_peeking_character')),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('global_fin_action_panel')), findsNothing);
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsNothing,
    );
    expect(provider.visualController.isPeekExpanded, false);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('global_fin_action_panel')), findsNothing);
  });

  testWidgets('dialogs suppress FIN until closed', (tester) async {
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog above FIN'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsNothing,
    );
    final context = tester.element(find.text('Dialog above FIN'));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsOneWidget,
    );
  });

  testWidgets(
    'drag, side switching and session dismissal remain under user control',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final provider = AnalyticsProvider(repository: MockPhase5FRepository());
      await tester.pumpWidget(_app(provider));
      await tester.pumpAndSettle();
      final handle = find.byKey(const ValueKey('global_fin_peeking_character'));
      final start = tester.getTopLeft(handle);
      await tester.drag(handle, const Offset(0, 130));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(handle).dy, greaterThan(start.dy));
      await tester.tap(handle);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('global_fin_edge_switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('global_fin_action_panel')), findsNothing);
      expect(tester.getTopLeft(handle).dx, 0);
      await _capture(tester, 'peek_left');
      await tester.tap(handle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('global_fin_dismiss')),
      );
      await tester.tap(find.byKey(const ValueKey('global_fin_dismiss')));
      await tester.pumpAndSettle();
      expect(handle, findsNothing);
      provider.visualController.onNavigation('/budgets');
      await tester.pumpAndSettle();
      expect(handle, findsNothing);
    },
  );

  testWidgets('fold hinge and large text keep mini panel in a safe region', (
    tester,
  ) async {
    _viewport(tester, const Size(1000, 700));
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    await tester.pumpWidget(
      _app(
        provider,
        media: (data) => data.copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(2),
          displayFeatures: [
            const ui.DisplayFeature(
              bounds: Rect.fromLTWH(490, 0, 20, 700),
              type: ui.DisplayFeatureType.hinge,
              state: ui.DisplayFeatureState.postureFlat,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('global_fin_peeking_character')),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(
      find.byKey(const ValueKey('global_fin_action_panel')),
    );
    expect(rect.left, greaterThanOrEqualTo(510));
    expect(rect.bottom, lessThan(700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded FIN retains history and the shared controller', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 844));
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    await provider.askQuestion('How much did I spend this month?');
    final messages = provider.messages.length;
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('global_fin_peeking_character')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_fin_action_talk')));
    await tester.pumpAndSettle();
    expect(provider.messages.length, messages);
    expect(
      find.byKey(const ValueKey('collapsed_companion_bar')),
      findsOneWidget,
    );
    final character = tester.widget<FinCharacter>(
      find.descendant(
        of: find.byKey(const ValueKey('collapsed_companion_bar')),
        matching: find.byType(FinCharacter),
      ),
    );
    expect(character.controller, same(provider.visualController));
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsNothing,
    );
  });

  testWidgets('request processing, focus and failure never imply success', (
    tester,
  ) async {
    final repo = _DelayedRepository();
    final provider = AnalyticsProvider(repository: repo);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();
    final work = provider.askQuestion('Review my saved spending');
    expect(provider.visualController.state, FinCharacterState.thinking);
    provider.visualController.onComposerFocused();
    expect(provider.visualController.state, FinCharacterState.thinking);
    await provider.askQuestion('Duplicate submission');
    expect(repo.queryCount, 1);
    repo.response.complete(
      ApiResponse(
        success: false,
        message: 'Could not review records',
        data: _answer.data,
      ),
    );
    await work;
    expect(provider.visualController.state, FinCharacterState.error);
    expect(
      provider.messages.where((m) => m.sender == MessageSender.assistant),
      isEmpty,
    );
    final action = provider.confirmPendingAction(_preview);
    expect(provider.visualController.state, FinCharacterState.thinking);
    repo.action.complete(
      const ApiResponse(
        success: false,
        message: 'Goal not saved',
        data: <String, dynamic>{},
      ),
    );
    expect(await action, false);
    expect(provider.visualController.state, FinCharacterState.error);
    expect(provider.actionSuccessMessage, isNull);
  });

  testWidgets(
    'successful completion updates the rig after the actual response',
    (tester) async {
      final repo = _DelayedRepository();
      final provider = AnalyticsProvider(repository: repo);
      final work = provider.askQuestion('Review approved records');
      expect(provider.visualController.state, FinCharacterState.thinking);
      repo.response.complete(_answer);
      await work;
      expect(provider.visualController.state, FinCharacterState.explaining);
      final action = provider.confirmPendingAction(_preview);
      repo.action.complete(
        const ApiResponse(success: true, message: 'Goal saved', data: {}),
      );
      expect(await action, true);
      expect(provider.visualController.state, FinCharacterState.celebrating);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('dedicated page and keyboard fit $size', (tester) async {
      _viewport(tester, size);
      final provider = AnalyticsProvider(repository: MockPhase5FRepository());
      await tester.pumpWidget(_app(provider));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('global_fin_action_talk')));
      await tester.pumpAndSettle();
      await _capture(tester, 'hero_${size.width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('assistant_query_field')));
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding(bottom: size.height * .45);
      await tester.pumpAndSettle();
      final fieldRect = tester.getRect(
        find.byKey(const ValueKey('assistant_query_field')),
      );
      expect(fieldRect.bottom, lessThanOrEqualTo(size.height * .55));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    });
  }

  testWidgets(
    'reduced motion stops tickers while keeping request expressions',
    (tester) async {
      final provider = AnalyticsProvider(repository: MockPhase5FRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinCharacter(
              controller: provider.visualController,
              size: 240,
              allowAnimationInTests: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      provider.visualController.onGreeting();
      await tester.pump(const Duration(milliseconds: 400));
      provider.visualController.onQuerySubmitted();
      provider.visualController.setAnimationsEnabled(false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        find.bySemanticsLabel('FIN financial companion, currently Thinking'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an action preview never celebrates an unexecuted action', (
    tester,
  ) async {
    final repo = MockPhase5FRepository();
    repo.mockQueryResult = const ApiResponse(
      success: true,
      message: 'Preview',
      data: AnalyticsQueryResult(
        intent: 'goal',
        isRefusal: false,
        answer: 'Review this goal before saving.',
        privacyNotice: 'Saved records only',
        characterState: 'celebrating',
        suggestions: [],
        actionPreview: _preview,
      ),
    );
    final provider = AnalyticsProvider(repository: repo);
    await provider.askQuestion('Prepare a goal');
    expect(provider.visualController.state, FinCharacterState.explaining);
    expect(provider.messages.last.characterState, 'explaining');
    expect(provider.actionSuccessMessage, isNull);
  });

  testWidgets('dedicated companion stays on one side of a fold hinge', (
    tester,
  ) async {
    _viewport(tester, const Size(1000, 700));
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    await tester.pumpWidget(
      _app(
        provider,
        media: (data) => data.copyWith(
          disableAnimations: true,
          displayFeatures: [
            const ui.DisplayFeature(
              bounds: Rect.fromLTWH(490, 0, 20, 700),
              type: ui.DisplayFeatureType.hinge,
              state: ui.DisplayFeatureState.postureFlat,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('global_fin_peeking_character')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('global_fin_action_talk')));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('assistant_query_field'))).right,
      lessThan(490),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('anatomy and every expression can be reviewed together', (
    tester,
  ) async {
    _viewport(tester, const Size(1120, 800));
    final states = [
      FinCharacterState.idle,
      FinCharacterState.greeting,
      FinCharacterState.listening,
      FinCharacterState.thinking,
      FinCharacterState.explaining,
      FinCharacterState.celebrating,
      FinCharacterState.caution,
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(
          ThemeCollection.graphiteChampagne,
          Brightness.dark,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: _captureKey,
            child: Wrap(
              children: [
                for (final state in states)
                  SizedBox(
                    width: 280,
                    height: 380,
                    child: Column(
                      children: [
                        FinCharacter(
                          size: 340,
                          state: state,
                          animationsEnabled: false,
                        ),
                        Text(state.label),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'pose_study');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'authenticated shell keeps full page width with FIN and after dismissal',
    (tester) async {
      _viewport(tester, const Size(390, 844));
      final provider = AnalyticsProvider(repository: MockPhase5FRepository());
      await tester.pumpWidget(_shellApp(provider));
      await tester.pumpAndSettle();
      final content = find.byKey(const ValueKey('financial_content'));
      final handle = find.byKey(const ValueKey('global_fin_peeking_character'));
      expect(tester.getRect(content).left, 0);
      expect(tester.getSize(content).width, 390);
      expect(
        tester.getRect(handle).bottom,
        lessThan(tester.getRect(find.byType(FloatingBottomNavigation)).top),
      );
      provider.visualController.dismissFloating();
      await tester.pumpAndSettle();
      expect(tester.getSize(content).width, 390);
      expect(handle, findsNothing);
    },
  );

  testWidgets('shell honors saved opt-out before displaying floating FIN', (
    tester,
  ) async {
    final repo = MockPhase5FRepository();
    repo.mockPreferences = const ApiResponse(
      success: true,
      message: 'Preferences',
      data: CompanionPreferences(showAcrossApp: false),
    );
    final provider = AnalyticsProvider(repository: repo);
    await tester.pumpWidget(_shellApp(provider));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('global_fin_peeking_character')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('financial_content')), findsOneWidget);
  });
}
