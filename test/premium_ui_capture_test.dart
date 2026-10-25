import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';
import 'package:provider/provider.dart';

class _PreviewAuth extends AuthProvider {
  @override
  UserModel? get currentUser => const UserModel(
    id: 1,
    name: 'Alex Morgan',
    email: 'alex.morgan@example.com',
  );
}

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
  ];
}

Widget _wrap(
  Widget child, {
  ThemeCollection collection = ThemeCollection.midnightAurora,
  Brightness brightness = Brightness.dark,
  double scale = 1,
  double keyboard = 0,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _PreviewAuth()),
      ChangeNotifierProvider<AccountProvider>(
        create: (_) => _PreviewAccounts(),
      ),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ChangeNotifierProvider(create: (_) => TransactionProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.buildTheme(collection, brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Space Grotesk': 'assets/fonts/SpaceGrotesk.ttf',
      'Plus Jakarta Sans': 'assets/fonts/PlusJakartaSans.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  for (final screen in ['login', 'profile', 'transaction']) {
    for (final collection in ThemeCollection.values) {
      for (final brightness in Brightness.values) {
        testWidgets('$screen ${collection.name} ${brightness.name}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(393, 852);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          await tester.pumpWidget(
            _wrap(
              RepaintBoundary(
                key: key,
                child: switch (screen) {
                  'login' => const LoginScreen(),
                  'profile' => const ProfileScreen(),
                  _ => const Scaffold(body: AddEditTransactionSheet()),
                },
              ),
              collection: collection,
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(key),
            );
            final picture = await boundary.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('build/premium_ui');
            await dir.create(recursive: true);
            await File(
              '${dir.path}/${screen}_${collection.name}_${brightness.name}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  for (final size in [
    const Size(320, 640),
    const Size(600, 800),
    const Size(1024, 768),
    const Size(740, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('responsive $size text=$scale with keyboard', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final screen in [
          const LoginScreen(),
          const ProfileScreen(),
          const Scaffold(body: AddEditTransactionSheet()),
        ]) {
          await tester.pumpWidget(
            _wrap(
              screen,
              scale: scale,
              keyboard: size.height > 400 ? 260 : 120,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (screen is Scaffold) {
            final save = find.byKey(const ValueKey('transaction-save'));
            expect(save.hitTestable(), findsOneWidget);
            await tester.ensureVisible(
              find.byKey(const ValueKey('cat_chip_7')),
            );
            await tester.tap(find.byKey(const ValueKey('cat_chip_7')));
            await tester.pumpAndSettle();
            expect(find.text('Healthcare'), findsOneWidget);
            expect(save.hitTestable(), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }
  }
  for (final keyboard in [0.0, 280.0]) {
    testWidgets('real modal keeps save above keyboard $keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddEditTransactionSheet(),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
          keyboard: keyboard,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('transaction-save'));
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(640 - keyboard));
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Amount is required'));
      expect(find.text('Title is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
