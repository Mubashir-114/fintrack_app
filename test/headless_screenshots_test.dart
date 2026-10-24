import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/models/detected_transaction_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/money_storage/money_storage_screen.dart';
import 'package:frontend/screens/profile/appearance_screen.dart';
import 'package:frontend/screens/transactions/sms_import_screen.dart';

final _captureKey = GlobalKey();

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/screenshots');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    await File(
      'build/screenshots/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _MockAccounts extends AccountProvider {
  @override
  List<AccountModel> get accounts => const [
    AccountModel(
      id: 1,
      type: 'bank',
      subtype: 'checking',
      isDefault: true,
      displayName: 'HDFC Priority Checking',
      institutionName: 'HDFC Bank',
      currencyCode: 'INR',
      openingAmount: '124580.00',
      maskedLast4: '4192',
      status: 'active',
    ),
    AccountModel(
      id: 2,
      type: 'wallet',
      subtype: 'digital_wallet',
      isDefault: false,
      displayName: 'Paytm Liquid Vault',
      institutionName: 'Paytm Payments',
      currencyCode: 'INR',
      openingAmount: '18400.00',
      status: 'active',
    ),
  ];
  @override
  Future<void> loadAccounts({bool loadMore = false}) async {}
}

class _MockDashboard extends DashboardProvider {
  @override
  DashboardSummary? get summary => const DashboardSummary(
    totalIncome: 85000.0,
    totalExpense: 32400.0,
    balance: 142980.0,
    smsImportedToday: 2,
    totalSmsImported: 45,
  );
  @override
  List<DashboardAccountItem> get accounts => const [
    DashboardAccountItem(
      id: 1,
      displayName: 'HDFC Priority Checking',
      type: 'bank',
      currentBalance: '124580.00',
      currencyCode: 'INR',
    ),
    DashboardAccountItem(
      id: 2,
      displayName: 'Paytm Liquid Vault',
      type: 'wallet',
      currentBalance: '18400.00',
      currencyCode: 'INR',
    ),
  ];
  @override
  Future<void> loadDashboardData() async {}
}

class _MockSms extends SmsProvider {
  @override
  List<DetectedTransactionModel> get detectedTransactions => const [
    DetectedTransactionModel(
      id: 101,
      userId: 1,
      accountId: null,
      accountName: null,
      suggestedAccountId: 1,
      suggestedAccountName: 'HDFC Priority Checking',
      isAccountAmbiguous: false,
      categoryId: 1,
      categoryName: 'Food & Dining',
      classification: 'expense',
      amount: '540.00',
      transactionDate: '2026-10-24',
      merchantRaw: 'Swiggy Bangalore IN',
      merchantClean: 'Swiggy',
      bank: 'HDFC Bank',
      smsHash: 'hash-mock-1',
      confidence: 0.95,
      status: 'suggested',
    ),
    DetectedTransactionModel(
      id: 102,
      userId: 1,
      accountId: null,
      accountName: null,
      suggestedAccountId: null,
      suggestedAccountName: null,
      isAccountAmbiguous: true,
      categoryId: 2,
      categoryName: 'Shopping',
      classification: 'expense',
      amount: '1250.00',
      transactionDate: '2026-10-23',
      merchantRaw: 'Amazon Retail',
      merchantClean: 'Amazon',
      bank: 'Bank Alert',
      smsHash: 'hash-mock-2',
      confidence: 0.88,
      status: 'suggested',
    ),
  ];
  @override
  Future<void> loadDetectedTransactions({String status = 'suggested'}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontDirectory =
        '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}/artifacts/material_fonts';
    final loader = FontLoader('Roboto');
    for (final variant in ['regular', 'medium', 'bold', 'black']) {
      final font = File('$fontDirectory/roboto-$variant.ttf');
      if (await font.exists()) {
        loader.addFont(font.readAsBytes().then(ByteData.sublistView));
      }
    }
    await loader.load();
    for (final entry in {
      'Space Grotesk': 'SpaceGrotesk',
      'Plus Jakarta Sans': 'PlusJakartaSans',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.mkl.financemanager/launcher_icon'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getCurrentLauncherIcon') {
              return 'midnight_aurora';
            }
            if (methodCall.method == 'setLauncherIcon') return true;
            return null;
          },
        );
  });

  group('Headless Screenshots Verification', () {
    testWidgets(
      'Capture Login Screen in Midnight Aurora and Graphite Champagne',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final theme = ThemeProvider();
        await tester.runAsync(
          () => theme.setCollection(ThemeCollection.midnightAurora),
        );
        final auth = AuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: theme),
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ],
            child: MaterialApp(
              theme: theme.darkTheme,
              home: RepaintBoundary(
                key: _captureKey,
                child: const LoginScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await _capture(tester, 'login_midnight_aurora');

        // Switch to Graphite Champagne
        await tester.runAsync(
          () => theme.setCollection(ThemeCollection.graphiteChampagne),
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: theme),
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ],
            child: MaterialApp(
              theme: theme.darkTheme,
              home: RepaintBoundary(
                key: _captureKey,
                child: const LoginScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await _capture(tester, 'login_graphite_champagne');
      },
    );

    testWidgets('Capture Appearance Preferences across all 6 themes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final theme = ThemeProvider();
      final currency = CurrencyProvider();

      for (final collection in ThemeCollection.values) {
        await tester.runAsync(() => theme.setCollection(collection));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: theme),
              ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
            ],
            child: MaterialApp(
              theme: theme.darkTheme,
              home: RepaintBoundary(
                key: _captureKey,
                child: const AppearanceScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await _capture(tester, 'appearance_${collection.storageKey}');
      }
    });

    testWidgets('Capture Money Storage Screen and SMS Import Screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final theme = ThemeProvider();
      final accounts = _MockAccounts();
      final dashboard = _MockDashboard();
      final sms = _MockSms();
      final currency = CurrencyProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<AccountProvider>.value(value: accounts),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<SmsProvider>.value(value: sms),
            ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
          ],
          child: MaterialApp(
            theme: theme.darkTheme,
            home: RepaintBoundary(
              key: _captureKey,
              child: const MoneyStorageScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await _capture(tester, 'money_storage_midnight_aurora');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<AccountProvider>.value(value: accounts),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
            ChangeNotifierProvider<SmsProvider>.value(value: sms),
            ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
          ],
          child: MaterialApp(
            theme: theme.darkTheme,
            home: RepaintBoundary(
              key: _captureKey,
              child: const SmsImportScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      if (find.text('Not now').evaluate().isNotEmpty) {
        await tester.tap(find.text('Not now'));
        await tester.pump();
      }
      await _capture(tester, 'sms_import_midnight_aurora');
    });
  });
}
