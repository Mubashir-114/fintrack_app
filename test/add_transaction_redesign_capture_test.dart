import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';
import 'package:provider/provider.dart';

/// `flutter test --dart-define=phase=before` records the pre-redesign sheet,
/// the default run records the current implementation.
const String _phase = String.fromEnvironment('phase', defaultValue: 'after');

class _PreviewAccounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'bank',
      subtype: 'savings',
      displayName: 'Everyday Savings',
      currencyCode: 'USD',
      openingAmount: '0.00',
      isDefault: true,
      status: 'active',
    ),
    AccountModel(
      id: 2,
      type: 'bank',
      subtype: 'current',
      displayName: 'Shared Household Current Account',
      currencyCode: 'USD',
      openingAmount: '0.00',
      isDefault: false,
      status: 'active',
    ),
  ];
}

final _captureKey = GlobalKey();

Widget _wrap({
  ThemeCollection collection = ThemeCollection.midnightAurora,
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  double keyboard = 0,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ChangeNotifierProvider<AccountProvider>(
        create: (_) => _PreviewAccounts(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(collection, brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _captureKey,
        child: const Scaffold(body: AddEditTransactionSheet()),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  Duration settle = const Duration(milliseconds: 400),
}) async {
  if (settle > Duration.zero) await tester.pump(settle);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/add_transaction_redesign');
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
      testWidgets('sheet ${size.width.toInt()}x${size.height.toInt()} '
          '${brightness.name}', (tester) async {
        _setViewport(tester, size);
        await tester.pumpWidget(_wrap(brightness: brightness));
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
    for (final brightness in Brightness.values) {
      testWidgets('sheet ${collection.name} ${brightness.name}', (
        tester,
      ) async {
        _setViewport(tester, const Size(393, 852));
        await tester.pumpWidget(
          _wrap(collection: collection, brightness: brightness),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, '393x852_${collection.name}_${brightness.name}');
      });
    }
  }

  testWidgets('sheet keyboard open 393 dark', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(_wrap(keyboard: 300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '393x852_keyboard_dark');
  });

  testWidgets('sheet keyboard open 320 light', (tester) async {
    _setViewport(tester, const Size(320, 568));
    await tester.pumpWidget(_wrap(keyboard: 260, brightness: Brightness.light));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '320x568_keyboard_light');
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('sheet text scale $scale', (tester) async {
      _setViewport(tester, const Size(393, 852));
      await tester.pumpWidget(_wrap(textScale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, '393x852_text${scale}x');
    });
  }

  testWidgets('sheet income mode', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-type-income')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '393x852_income_dark');
  });

  testWidgets('sheet finishing companion animation', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-type-income')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 230));
    await _capture(
      tester,
      '393x852_income_coin_midflight',
      settle: Duration.zero,
    );
  });

  testWidgets('sheet long account selection', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-option-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '393x852_long_account');
  });

  testWidgets('sheet validation errors', (tester) async {
    _setViewport(tester, const Size(393, 852));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, '393x852_validation_dark');
  });
}
