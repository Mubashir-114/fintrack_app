import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/floating_bottom_navigation.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/ledger/ledger_screen.dart';
import 'package:provider/provider.dart';
import 'support/ledger_fixture.dart';

const phase = String.fromEnvironment('phase', defaultValue: 'after');

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final font in {
      'Space Grotesk': 'SpaceGrotesk',
      'Plus Jakarta Sans': 'PlusJakartaSans',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}.ttf'))).load();
    }
  });

  final cases = <String, (Size, double, Brightness, String?)>{
    '393_all': (const Size(393, 852), 1, Brightness.dark, null),
    if (phase != 'before') ...{
      '393_income': (const Size(393, 852), 1, Brightness.dark, 'income'),
      '393_expenses': (const Size(393, 852), 1, Brightness.dark, 'expense'),
      '320_all': (const Size(320, 568), 1, Brightness.dark, null),
      '360_all': (const Size(360, 640), 1, Brightness.dark, null),
      '600_all': (const Size(600, 960), 1, Brightness.dark, null),
      '1024_all': (const Size(1024, 768), 1, Brightness.dark, null),
      '393_light': (const Size(393, 852), 1, Brightness.light, null),
      '393_text2x': (const Size(393, 852), 2, Brightness.dark, null),
      '393_empty': (const Size(393, 852), 1, Brightness.dark, 'empty'),
      '393_loading': (const Size(393, 852), 1, Brightness.dark, 'loading'),
      '393_loading_more': (const Size(393, 852), 1, Brightness.dark, 'more'),
      '320_scrolled': (const Size(320, 568), 1, Brightness.dark, 'scrolled'),
      '393_text2x_scrolled': (
        const Size(393, 852),
        2,
        Brightness.dark,
        'scrolled',
      ),
      for (final collection in ThemeCollection.values)
        'theme_${collection.name}': (
          const Size(393, 852),
          1,
          Brightness.dark,
          null,
        ),
    },
  };
  for (final entry in cases.entries) {
    testWidgets('capture $phase ${entry.key}', (tester) async {
      final (size, scale, brightness, state) = entry.value;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = LedgerFixtureProvider(
        records: state == 'empty' || state == 'loading' ? [] : null,
        loading: state == 'loading',
        loadingMore: state == 'more',
      );
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildTheme(
              entry.key.startsWith('theme_')
                  ? ThemeCollection.values.firstWhere(
                      (collection) => entry.key == 'theme_${collection.name}',
                    )
                  : ThemeCollection.midnightAurora,
              brightness,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: captureKey,
              child: Scaffold(
                body: const LedgerScreen(),
                bottomNavigationBar: size.width < 600
                    ? FloatingBottomNavigation(
                        selectedIndex: 1,
                        onDestinationSelected: (_) {},
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      if (state == 'income' || state == 'expense') provider.setType(state);
      await tester.pump(const Duration(seconds: 1));
      if (state == 'scrolled' || state == 'more') {
        await tester.drag(
          find.byKey(const ValueKey('ledger-scroll')),
          const Offset(0, -650),
        );
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(captureKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(
          'docs/improvements/design/ledger/screenshots',
        );
        await directory.create(recursive: true);
        await File(
          '${directory.path}/${phase}_${entry.key}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }
}
