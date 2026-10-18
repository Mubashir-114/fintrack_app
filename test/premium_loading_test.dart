import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/services/token_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/fin_track_theme_tokens.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/financial_chart.dart';
import 'package:frontend/core/widgets/fintrack_loading_scene.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/splash/splash_screen.dart';

class _Auth extends AuthProvider {
  int calls = 0;
  Completer<bool> response = Completer<bool>();
  @override
  Future<bool> loadCurrentUser() {
    calls++;
    return response.future;
  }
}

Future<GoRouter> _mount(WidgetTester tester, _Auth auth) async {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('Sign in destination')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => const Scaffold(body: Text('Dashboard destination')),
      ),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('UI_CAPTURE')) return;
    final fontDirectory =
        '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}/artifacts/material_fonts';
    final loader = FontLoader('Roboto');
    for (final variant in ['regular', 'medium', 'bold']) {
      final font = File('$fontDirectory/roboto-$variant.ttf');
      if (font.existsSync()) {
        loader.addFont(font.readAsBytes().then(ByteData.sublistView));
      }
    }
    await loader.load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('financial label colors meet text contrast on light surfaces', () {
    for (final collection in ThemeCollection.values) {
      final colors = FinTrackThemeTokens.resolve(collection, Brightness.light);
      for (final foreground in [
        colors.primary,
        colors.success,
        colors.danger,
        colors.warning,
      ]) {
        for (final background in [colors.surface, colors.elevated]) {
          final contrast =
              (background.computeLuminance() + .05) /
              (foreground.computeLuminance() + .05);
          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: '$collection $foreground on $background',
          );
        }
      }
    }
  });

  testWidgets('startup illustration stays on one side of a fold hinge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues({
      TokenService.accessTokenKey: 'test-only-token',
    });
    final auth = _Auth();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
              disableAnimations: true,
              displayFeatures: [
                ui.DisplayFeature(
                  bounds: Rect.fromLTWH(500, 0, 24, 768),
                  type: ui.DisplayFeatureType.hinge,
                  state: ui.DisplayFeatureState.postureFlat,
                ),
              ],
            ),
            child: const SplashScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getRect(find.byType(FinTrackLoadingScene)).right,
      lessThanOrEqualTo(500),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('startup without a token navigates immediately', (tester) async {
    final auth = _Auth();
    final router = await _mount(tester, auth);
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(auth.calls, 0);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    auth.dispose();
  });

  testWidgets(
    'cold start shows waiting status, failure retries, success does not wait for animation',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        TokenService.accessTokenKey: 'test-only-token',
      });
      final auth = _Auth();
      final router = await _mount(tester, auth);
      expect(auth.calls, 1);
      expect(find.text('Verifying your session…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.textContaining('Still waiting for the server'),
        findsOneWidget,
      );
      auth.response.complete(false);
      await tester.pump();
      await tester.pump();
      expect(find.text('Retry connection'), findsOneWidget);
      expect(await TokenService.getToken(), 'test-only-token');
      auth.response = Completer<bool>();
      await tester.tap(find.text('Retry connection'));
      await tester.pump();
      expect(auth.calls, 2);
      auth.response.complete(true);
      await tester.pump();
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      auth.dispose();
    },
  );

  testWidgets('expired session returns to sign in and cancels waiting timer', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      TokenService.accessTokenKey: 'test-only-token',
    });
    final auth = _Auth();
    final router = await _mount(tester, auth);
    await TokenService.removeToken();
    auth.response.complete(false);
    await tester.pump();
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    auth.dispose();
  });

  testWidgets('loading painting stops for reduced motion and hidden views', (
    tester,
  ) async {
    for (final reduced in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: reduced,
              child: const FinTrackLoadingScene(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'flow proportions expose no invented shares for empty or one-sided data',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: const [
              FinancialFlowBar(income: 0, expense: 0),
              FinancialFlowBar(income: 0, expense: 100),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('No recorded income or expense'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('income 0.0 percent, expense 100.0 percent'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'startup fits compact, landscape, and tablet with large text in both themes',
    (tester) async {
      for (final size in [
        const Size(320, 568),
        const Size(740, 320),
        const Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
          FlutterSecureStorage.setMockInitialValues({
            TokenService.accessTokenKey: 'test-only-token',
          });
          final auth = _Auth();
          final router = GoRouter(
            initialLocation: '/splash',
            routes: [
              GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
            ],
          );
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: auth,
              child: MaterialApp.router(
                theme: theme,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$size ${theme.brightness}',
          );
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          auth.dispose();
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('capture native loading animation frames', (tester) async {
    if (!const bool.fromEnvironment('UI_CAPTURE')) return;
    tester.view.physicalSize = const Size(393, 800);
    tester.view.devicePixelRatio = 1;
    for (final dark in [false, true]) {
      FlutterSecureStorage.setMockInitialValues({
        TokenService.accessTokenKey: 'test-only-token',
      });
      final auth = _Auth();
      final key = GlobalKey();
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pump();
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 360));
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/ui_modernization/loading')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/${dark ? "dark" : "light"}_$frame.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      auth.dispose();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
