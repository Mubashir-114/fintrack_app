import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _phase = String.fromEnvironment('phase', defaultValue: 'after');

class MockBudgetCaptureProvider extends BudgetProvider {
  BudgetProgressResponseModel? _simProgress;
  BudgetAlertsResponseModel? _simAlerts;
  List<BudgetSuggestionModel> _simSuggestions = [];
  List<BudgetHistoryItemModel> _simHistory = [];
  bool _simLoading = false;
  String? _simError;
  int _simMonth = 10;
  int _simYear = 2026;

  void configure({
    BudgetProgressResponseModel? progress,
    BudgetAlertsResponseModel? alerts,
    List<BudgetSuggestionModel>? suggestions,
    List<BudgetHistoryItemModel>? history,
    bool isLoading = false,
    String? error,
    int month = 10,
    int year = 2026,
  }) {
    _simProgress = progress;
    _simAlerts = alerts;
    _simSuggestions = suggestions ?? [];
    _simHistory = history ?? [];
    _simLoading = isLoading;
    _simError = error;
    _simMonth = month;
    _simYear = year;
    notifyListeners();
  }

  @override
  int get selectedMonth => _simMonth;
  @override
  int get selectedYear => _simYear;
  @override
  BudgetProgressResponseModel? get progress => _simProgress;
  @override
  BudgetAlertsResponseModel? get alerts => _simAlerts;
  @override
  List<BudgetSuggestionModel> get suggestions => _simSuggestions;
  @override
  List<BudgetHistoryItemModel> get history => _simHistory;
  @override
  bool get isLoading => _simLoading;
  @override
  String? get errorMessage => _simError;

  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {}
  @override
  Future<void> loadBudgetSuggestions() async {}
  @override
  Future<void> loadBudgetHistory({int months = 6}) async {}
  @override
  void changeDate(int month, int year) {
    _simMonth = month;
    _simYear = year;
    notifyListeners();
  }
}

class MockReportCaptureProvider extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
}

BudgetProgressResponseModel createStandardProgress({
  String status = "approaching_limit",
}) {
  final isExceeded = status == "exceeded";
  return BudgetProgressResponseModel(
    month: 10,
    year: 2026,
    period: const BudgetPeriodModel(
      daysInMonth: 30,
      daysElapsed: 24,
      daysRemaining: 6,
      isCurrentPeriod: true,
      estimationMethod: "Linear Daily Burn-Rate",
    ),
    overall: BudgetOverallProgressModel(
      budgetLimit: "194000.00",
      actualSpending: isExceeded ? "205400.00" : "171650.00",
      remainingAmount: isExceeded ? "-11400.00" : "22350.00",
      utilizationPercentage: isExceeded ? "105.9" : "88.5",
      dailyBurnRate: "7152.08",
      projectedSpending: isExceeded ? "224500.00" : "212846.00",
      status: status,
      hasBudgetsDefined: true,
    ),
    categoryBudgets: [
      BudgetCategoryProgressModel(
        budgetId: 1,
        categoryId: 3,
        category: "Food",
        categoryType: "expense",
        budgetLimit: "25000.00",
        actualSpending: "450.00",
        remainingAmount: "24550.00",
        utilizationPercentage: "1.8",
        projectedSpending: "562.50",
        status: "on_track",
        daysRemaining: 6,
      ),
      BudgetCategoryProgressModel(
        budgetId: 2,
        categoryId: 1,
        category: "Housing",
        categoryType: "expense",
        budgetLimit: "150000.00",
        actualSpending: "120000.00",
        remainingAmount: "30000.00",
        utilizationPercentage: "80.0",
        projectedSpending: "150000.00",
        status: "approaching_limit",
        daysRemaining: 6,
      ),
      BudgetCategoryProgressModel(
        budgetId: 3,
        categoryId: 7,
        category: "Healthcare",
        categoryType: "expense",
        budgetLimit: "1000.00",
        actualSpending: isExceeded ? "1200.00" : "0.00",
        remainingAmount: isExceeded ? "-200.00" : "1000.00",
        utilizationPercentage: isExceeded ? "120.0" : "0.0",
        projectedSpending: isExceeded ? "1500.00" : "0.00",
        status: isExceeded ? "exceeded" : "on_track",
        daysRemaining: 6,
      ),
      BudgetCategoryProgressModel(
        budgetId: 4,
        categoryId: 8,
        category: "Entertainment",
        categoryType: "expense",
        budgetLimit: "1000.00",
        actualSpending: "0.00",
        remainingAmount: "1000.00",
        utilizationPercentage: "0.0",
        projectedSpending: "0.00",
        status: "on_track",
        daysRemaining: 6,
      ),
    ],
    uncategorizedSpending: "0.00",
    savings: const BudgetSavingsProgressModel(
      totalIncome: "250000.00",
      totalExpense: "171650.00",
      netSavings: "78350.00",
      projectedNetSavings: "37154.00",
      savingsTarget: "50000.00",
      progressPercentage: "156.7",
      isTargetAchieved: true,
    ),
  );
}

BudgetAlertsResponseModel createStandardAlerts({
  String status = "approaching_limit",
}) {
  final isExceeded = status == "exceeded";
  final exceededList = isExceeded
      ? [
          const BudgetAlertModel(
            categoryId: 7,
            category: "Healthcare",
            budgetLimit: "1000.00",
            actualSpending: "1200.00",
            utilizationPercentage: "120.0",
            severity: "critical",
            message: "Healthcare has exceeded its budget by ₹200",
          ),
        ]
      : const <BudgetAlertModel>[];
  final approachingList = const [
    BudgetAlertModel(
      categoryId: 1,
      category: "Housing",
      budgetLimit: "150000.00",
      actualSpending: "120000.00",
      utilizationPercentage: "80.0",
      severity: "warning",
      message: "Housing is approaching its limit (₹120,000 of ₹150,000 spent)",
    ),
  ];
  return BudgetAlertsResponseModel(
    month: 10,
    year: 2026,
    exceeded: exceededList,
    approachingLimit: approachingList,
    insights: const [
      BudgetInsightModel(
        type: "pacing",
        title: "Daily Spending Rate",
        message: "You're using your monthly budget faster than planned.",
      ),
    ],
    totalAlertsCount: exceededList.length + approachingList.length,
  );
}

final _captureKey = GlobalKey();

Widget _wrapScreen({
  required BudgetProvider budgetProvider,
  ThemeCollection collection = ThemeCollection.midnightAurora,
  Brightness brightness = Brightness.dark,
  double textScale = 1.0,
  double keyboard = 0.0,
  Widget? customChild,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
      ChangeNotifierProvider<ReportProvider>(
        create: (_) => MockReportCaptureProvider(),
      ),
      ChangeNotifierProvider<CurrencyProvider>(
        create: (_) => CurrencyProvider()..setCurrency('INR'),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(collection, brightness),
      builder: (context, child) => RepaintBoundary(
        key: _captureKey,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
      ),
      home: customChild ?? const BudgetsListScreen(),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/budget_redesign');
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
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();

    for (final entry in {
      'Space Grotesk': 'SpaceGrotesk',
      'Plus Jakarta Sans': 'PlusJakartaSans',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      try {
        await (FontLoader(entry.key)..addFont(
              rootBundle.load(
                entry.key == 'MaterialIcons'
                    ? entry.value
                    : 'assets/fonts/${entry.value}.ttf',
              ),
            ))
            .load();
      } catch (_) {}
    }
  });

  testWidgets('Capture 393_dark', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '393_dark');
  });

  testWidgets('Capture 393_light', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '393_light');
  });

  testWidgets('Capture 320_compact', (tester) async {
    _setViewport(tester, const Size(320, 568));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '320_compact');
  });

  testWidgets('Capture 600_tablet', (tester) async {
    _setViewport(tester, const Size(600, 960));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '600_tablet');
  });

  testWidgets('Capture 1024_desktop', (tester) async {
    _setViewport(tester, const Size(1024, 768));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '1024_desktop');
  });

  testWidgets('Capture 393_text2x', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, '393_text2x');
  });

  testWidgets('Capture approaching_limit', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'approaching_limit');
  });

  testWidgets('Capture exceeded', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "exceeded"),
      alerts: createStandardAlerts(status: "exceeded"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'exceeded');
  });

  testWidgets('Capture empty_state', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(progress: null, alerts: null);

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'empty_state');
  });

  testWidgets('Capture add_budget_sheet', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Budget button to open sheet
    await tester.tap(find.text("Add Budget"));
    await tester.pumpAndSettle();
    await _capture(tester, 'add_budget_sheet');
  });

  testWidgets('Capture add_budget_keyboard', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
        keyboard: 280.0,
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Budget button to open sheet with simulated keyboard
    await tester.tap(find.text("Add Budget"));
    await tester.pumpAndSettle();
    await _capture(tester, 'add_budget_keyboard');
  });

  testWidgets('Capture animated_arc_progress_frame', (tester) async {
    _setViewport(tester, const Size(393, 852));
    final provider = MockBudgetCaptureProvider();
    provider.configure(
      progress: createStandardProgress(status: "approaching_limit"),
      alerts: createStandardAlerts(status: "approaching_limit"),
    );

    await tester.pumpWidget(
      _wrapScreen(
        budgetProvider: provider,
        collection: ThemeCollection.midnightAurora,
        brightness: Brightness.dark,
      ),
    );
    // Pump 350ms to capture mid-flight animation
    await tester.pump(const Duration(milliseconds: 350));
    await _capture(tester, 'animated_arc_progress_frame');
  });
}
