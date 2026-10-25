import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

/// `flutter test --dart-define=phase=before` records the pre-redesign screen,
/// the default run records the current implementation.
const String _phase = String.fromEnvironment('phase', defaultValue: 'after');

class _PreviewAuth extends AuthProvider {
  @override
  UserModel? get currentUser => const UserModel(
    id: 1,
    name: 'Alex Morgan',
    email: 'alex.morgan@example.com',
  );
}

class _LongAuth extends AuthProvider {
  @override
  UserModel? get currentUser => const UserModel(
    id: 1,
    name: 'Alexandra Konstantinopoulos-Rivera',
    email: 'alexandra.konstantinopoulos.rivera@very-long-domain.example.com',
  );
}

final _captureKey = GlobalKey();

Widget _wrap(
  Widget child, {
  ThemeCollection collection = ThemeCollection.midnightAurora,
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  AuthProvider? auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => auth ?? _PreviewAuth(),
      ),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(collection, brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: RepaintBoundary(key: _captureKey, child: child),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/profile_redesign');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/${_phase}_$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

  for (final size in [
    const Size(393, 852),
    const Size(320, 568),
    const Size(360, 640),
    const Size(600, 960),
    const Size(1024, 768),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('profile ${size.width}x${size.height} ${brightness.name}', (
        tester,
      ) async {
        _setViewport(tester, size);
        await tester.pumpWidget(
          _wrap(const ProfileScreen(), brightness: brightness),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          '${size.width.toInt()}x${size.height.toInt()}_${brightness.name}',
        );
      });
    }
  }

  for (final collection in ThemeCollection.values) {
    testWidgets('profile ${collection.name} both brightnesses', (tester) async {
      _setViewport(tester, const Size(393, 852));
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _wrap(
            const ProfileScreen(),
            collection: collection,
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, '393x852_${collection.name}_${brightness.name}');
      }
    });
  }

  for (final scale in [1.3, 2.0]) {
    for (final size in [const Size(393, 852), const Size(320, 568)]) {
      testWidgets('profile text scale $scale at ${size.width.toInt()}', (
        tester,
      ) async {
        _setViewport(tester, size);
        await tester.pumpWidget(_wrap(const ProfileScreen(), textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          '${size.width.toInt()}x${size.height.toInt()}_text${scale}x',
        );
      });
    }
  }

  testWidgets('profile long identity content at 320', (tester) async {
    _setViewport(tester, const Size(320, 568));
    await tester.pumpWidget(_wrap(const ProfileScreen(), auth: _LongAuth()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '320x568_long_identity');
  });

  testWidgets('profile long identity content at 2x text', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(
      _wrap(const ProfileScreen(), auth: _LongAuth(), textScale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '393x852_long_identity_text2x');
  });
}
