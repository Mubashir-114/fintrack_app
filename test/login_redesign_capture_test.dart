import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

class _PendingAuthProvider extends AuthProvider {
  final completer = Completer<bool>();

  @override
  Future<bool> login({required String email, required String password}) {
    return completer.future;
  }
}

class _FailingAuthProvider extends AuthProvider {
  @override
  String? get errorMessage => 'Email or password did not match.';

  @override
  Future<bool> login({required String email, required String password}) async {
    return false;
  }
}

Widget _wrap(
  Widget child, {
  required Size size,
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  double keyboard = 0,
  AuthProvider? auth,
}) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => auth ?? AuthProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(ThemeCollection.midnightAurora, brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
      home: RepaintBoundary(key: _captureKey, child: child),
    ),
  );
}

final _captureKey = GlobalKey();

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 120));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/login_redesign');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final entry in {
      'Space Grotesk': 'SpaceGrotesk',
      'Plus Jakarta Sans': 'PlusJakartaSans',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            rootBundle.load(
              entry.key == 'MaterialIcons'
                  ? entry.value
                  : 'assets/fonts/${entry.value}.ttf',
            ),
          ))
          .load();
    }
  });

  testWidgets('captures baseline and redesigned 393dp login', (tester) async {
    _setViewport(tester, const Size(393, 852));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const _BaselineLoginFixture(), size: const Size(393, 852)),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'before_393_dark');

    await tester.pumpWidget(
      _wrap(const LoginScreen(), size: const Size(393, 852)),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'after_393_dark');
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(600, 960),
  ]) {
    testWidgets('renders ${size.width}x${size.height} login without overflow', (
      tester,
    ) async {
      _setViewport(tester, size);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(const LoginScreen(), size: size));
      await tester.pumpAndSettle();
      await _capture(
        tester,
        'after_${size.width.toInt()}x${size.height.toInt()}_dark',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders light mode, 2x text, and keyboard-open layout', (
    tester,
  ) async {
    const size = Size(393, 852);
    _setViewport(tester, size);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _wrap(
        const LoginScreen(),
        size: size,
        brightness: Brightness.light,
        textScale: 2,
        keyboard: 280,
      ),
    );
    await tester.pumpAndSettle();
    final emailField = find.byType(TextFormField).first;
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.pump();
    await _capture(tester, 'after_393_light_text2_keyboard');
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures validation and authentication error feedback', (
    tester,
  ) async {
    const size = Size(393, 852);
    _setViewport(tester, size);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const LoginScreen(), size: size));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    await _capture(tester, 'error_validation_393_dark');
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(const LoginScreen(), size: size, auth: _FailingAuthProvider()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    await _capture(tester, 'error_auth_393_dark');
    expect(find.text('Email or password did not match.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures sign-in loading feedback', (tester) async {
    const size = Size(393, 852);
    final auth = _PendingAuthProvider();
    _setViewport(tester, size);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const LoginScreen(), size: size, auth: auth));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    await _capture(tester, 'loading_393_dark');
    expect(find.byKey(const ValueKey('login-loading-message')), findsOneWidget);
    auth.completer.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _BaselineLoginFixture extends StatelessWidget {
  const _BaselineLoginFixture();

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        titleSpacing: HorizonDimensions.marginTablet,
        automaticallyImplyLeading: false,
        title: Text(
          'FINTRACK // HORIZON',
          style: HorizonTypography.labelMd.copyWith(
            color: tokens.ionCyan,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HorizonDimensions.marginTablet),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: HorizonDimensions.formMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign In',
                    style: HorizonTypography.headlineLg.copyWith(
                      color: tokens.textHigh,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: HorizonDimensions.spaceSM),
                  Text(
                    'Welcome back. Your finances, in focus.',
                    style: HorizonTypography.bodyMd.copyWith(
                      color: tokens.textMedium,
                    ),
                  ),
                  const SizedBox(height: HorizonDimensions.spaceXL),
                  const HorizonTextField(
                    flat: true,
                    label: 'Email address',
                    hintText: 'name@example.com',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 16),
                  const HorizonTextField(
                    flat: true,
                    label: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  const HorizonButton(
                    text: 'Sign In',
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: HorizonDimensions.spaceLG),
                  Text.rich(
                    TextSpan(
                      text: 'New to FinTrack? ',
                      style: HorizonTypography.bodySm.copyWith(
                        color: tokens.textMedium,
                      ),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: HorizonTypography.bodySm.copyWith(
                            color: tokens.ionCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
