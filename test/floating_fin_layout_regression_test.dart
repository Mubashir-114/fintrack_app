import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
import 'phase5f_living_companion_test.dart' show MockPhase5FRepository;

void main() {
  testWidgets('floating FIN does not change page width when disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
    CacheService.setUserId(9301);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fin = AnalyticsProvider(repository: MockPhase5FRepository());
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainNavigationScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const Scaffold(
                key: ValueKey('page_bounds'),
                body: Text('Page content'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: fin,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final enabled = tester.getRect(find.byKey(const ValueKey('page_bounds')));
    await fin.updateCompanionPreferences(
      fin.companionPreferences.copyWith(showAcrossApp: false),
    );
    await tester.pumpAndSettle();
    final disabled = tester.getRect(find.byKey(const ValueKey('page_bounds')));
    debugPrint(
      'Page width: FIN enabled=${enabled.width}; FIN disabled=${disabled.width}; viewport=393',
    );
    expect(disabled.width, 393);
    expect(
      enabled,
      disabled,
      reason: 'Floating FIN must not allocate page width.',
    );
  });
  testWidgets(
    'peek and mini panel leave page bounds and outside touches intact',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await CacheService.initialize();
      CacheService.setUserId(9303);
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(left: 12, right: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
      var taps = 0;
      final fin = AnalyticsProvider(repository: MockPhase5FRepository());
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (_, _, child) => MainNavigationScreen(child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => Scaffold(
                  key: const ValueKey('page_bounds'),
                  body: Stack(
                    children: [
                      Positioned(
                        top: 96,
                        left: 24,
                        child: TextButton(
                          onPressed: () => taps++,
                          child: const Text('Underlying action'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fin,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final page = find.byKey(const ValueKey('page_bounds'));
      final before = tester.getRect(page);
      expect(before.width, 393);
      await tester.tap(find.text('Underlying action'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.tap(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('global_fin_action_panel')),
        findsOneWidget,
      );
      expect(tester.getRect(page), before);
      await tester.tap(find.text('Underlying action'));
      await tester.pumpAndSettle();
      expect(
        taps,
        2,
        reason: 'The overlay must not consume taps outside its panel.',
      );
      expect(
        find.byKey(const ValueKey('global_fin_action_panel')),
        findsNothing,
      );
      await fin.updateCompanionPreferences(
        fin.companionPreferences.copyWith(edgePosition: 'left'),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(page), before);
      final handle = tester.getRect(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      expect(handle.left, 12);
      expect(handle.right, lessThan(393 - 24));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.getSize(page).width, 393);
      expect(
        find.byKey(const ValueKey('global_fin_peeking_character')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a status-bar cutout must not hide FIN', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
    CacheService.setUserId(9307);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 49.5);
    tester.view.displayFeatures = [
      const ui.DisplayFeature(
        bounds: Rect.fromLTWH(0, 0, 49.5, 49.5),
        type: ui.DisplayFeatureType.cutout,
        state: ui.DisplayFeatureState.unknown,
      ),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetDisplayFeatures);
    final fin = AnalyticsProvider(repository: MockPhase5FRepository());
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainNavigationScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const Scaffold(
                key: ValueKey('page_bounds'),
                body: Text('Page content'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: fin,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final visual = tester.getRect(
      find.byKey(const ValueKey('global_fin_peeking_visual')),
    );
    expect(visual.height, greaterThan(120));
    expect(visual.right, lessThanOrEqualTo(393));
    expect(
      tester.getRect(find.byKey(const ValueKey('page_bounds'))).width,
      393,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'peeking FIN is large enough to read while keeping a tight hit area',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await CacheService.initialize();
      CacheService.setUserId(9305);
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fin = AnalyticsProvider(repository: MockPhase5FRepository());
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (_, _, child) => MainNavigationScreen(child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const Scaffold(
                  key: ValueKey('page_bounds'),
                  body: Text('Page content'),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fin,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final visual = tester.getRect(
        find.byKey(const ValueKey('global_fin_peeking_visual')),
      );
      final hit = tester.getRect(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      expect(visual.width, greaterThanOrEqualTo(80));
      expect(visual.height, greaterThanOrEqualTo(160));
      expect(visual.right, lessThanOrEqualTo(393));
      expect(hit.width, lessThanOrEqualTo(56));
      expect(hit.width, lessThan(visual.width));
      expect(
        tester.getRect(find.byKey(const ValueKey('page_bounds'))).width,
        393,
        reason: 'The wider FIN portrait is an overlay, never page width.',
      );

      await tester.tap(
        find.byKey(const ValueKey('global_fin_peeking_character')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('global_fin_panel_character')),
        findsOneWidget,
        reason: 'FIN must stay visible beside the expanded panel.',
      );
      expect(find.text('Spending Overview'), findsOneWidget);
      expect(find.text('Budget Check'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('global_fin_action_close')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('global_fin_peeking_visual')),
        findsOneWidget,
        reason: 'Minimizing returns FIN to the edge pose.',
      );
      expect(
        find.byKey(const ValueKey('global_fin_action_panel')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
