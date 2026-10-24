import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/models/companion_model.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'package:frontend/screens/analytics/widgets/fin_character.dart';
import 'package:frontend/screens/analytics/widgets/fin_visual_controller.dart';
import 'package:frontend/screens/analytics/widgets/global_fin_overlay.dart';
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;

void main() {
  testWidgets(
    'mini panel opens full FIN when no unobstructed panel space exists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await CacheService.initialize();
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = AnalyticsProvider(repository: MockPhase5FRepository());
      final occupied = ValueNotifier([const Rect.fromLTWH(0, 300, 393, 200)]);
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) =>
                Scaffold(body: GlobalFinOverlay(contentBounds: occupied)),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, _) =>
                const Scaffold(body: Text('Full FIN conversation')),
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final peek = find.byKey(const ValueKey('global_fin_peeking_visual'));
      expect(tester.getRect(peek).overlaps(occupied.value.single), false);
      await tester.tap(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Full FIN conversation'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('global_fin_action_panel')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      provider.dispose();
      occupied.dispose();
    },
  );
  testWidgets('FIN yields to full-page controls and returns in clear space', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final blocked = ValueNotifier(true);
    final provider = AnalyticsProvider(repository: MockPhase5FRepository());
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainNavigationScreen(child: child),
          routes: [
            GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => Scaffold(
                body: ValueListenableBuilder(
                  valueListenable: blocked,
                  builder: (_, value, _) => value
                      ? SizedBox.expand(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Transaction control'),
                          ),
                        )
                      : const Center(child: Text('Saved content')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final peek = find.byKey(const ValueKey('global_fin_peeking_character'));
    expect(
      peek,
      findsNothing,
      reason: 'FIN must yield to underlying controls.',
    );
    blocked.value = false;
    await tester.pumpAndSettle();
    expect(peek, findsOneWidget);
    final visual = tester.getRect(
      find.byKey(const ValueKey('global_fin_peeking_visual')),
    );
    expect(visual.overlaps(tester.getRect(find.text('Saved content'))), false);
    blocked.value = true;
    await tester.pumpAndSettle();
    expect(peek, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    provider.dispose();
    blocked.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all body poses transition with motion, OS reduction and ticker cleanup',
    (tester) async {
      final controller = FinVisualController();
      Widget scene({bool reduced = false, bool active = true}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: active,
            child: Center(
              child: FinCharacter(
                controller: controller,
                size: 240,
                allowAnimationInTests: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene());
      for (final state in [
        FinCharacterState.greeting,
        FinCharacterState.listening,
        FinCharacterState.thinking,
        FinCharacterState.explaining,
        FinCharacterState.caution,
        FinCharacterState.celebrating,
        FinCharacterState.idle,
      ]) {
        controller.setState(state);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 190));
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(scene(reduced: true));
      controller.onGreeting();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(scene(active: false));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      controller.onQuerySubmitted();
      await tester.pump(const Duration(seconds: 5));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );
}
