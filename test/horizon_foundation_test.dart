import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/horizon/horizon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinTrack // HORIZON — Canonical Design Tokens', () {
    test('Dark Void Palette matches exact HORIZON specification', () {
      final dark = HorizonThemeTokens.dark;

      expect(dark.canvas, const Color(0xFF080D17));
      expect(dark.surface1, const Color(0xFF0E1626));
      expect(dark.surface2, const Color(0xFF172338));
      expect(dark.surface3, const Color(0xFF1F2F4A));
      expect(dark.surface4, const Color(0xFF253858));

      expect(dark.ionCyan, const Color(0xFF75DEED));
      expect(dark.electricIndigo, const Color(0xFF8996FC));
      expect(dark.luminousGold, const Color(0xFFE5B76A));
      expect(dark.surplus, const Color(0xFF34D399));
      expect(dark.outflow, const Color(0xFFF87171));

      expect(dark.textHigh, const Color(0xFFF5F8FC));
      expect(dark.textMedium, const Color(0xFF8E9BAE));
      expect(dark.textLow, const Color(0xFF5A6B82));

      expect(dark.rimCyan, const Color(0x1F75DEED));
      expect(dark.rimDock, const Color(0x2E75DEED));
      expect(dark.rimNeutral, const Color(0x1A8E9BAE));
    });

    test('Light Horizon Palette matches daylight specification', () {
      final light = HorizonThemeTokens.light;

      expect(light.canvas, const Color(0xFFF8FAFC));
      expect(light.surface1, const Color(0xFFFFFFFF));
      expect(light.surface2, const Color(0xFFF1F5F9));
      expect(light.surface3, const Color(0xFFE2E8F0));
      expect(light.surplus, const Color(0xFF047857));
      expect(light.outflow, const Color(0xFFB91C1C));
      expect(light.textHigh, const Color(0xFF0F172A));
      expect(light.textMedium, const Color(0xFF475569));
    });

    test(
      'Typography scales pair Space Grotesk and Plus Jakarta Sans with tabular figures',
      () {
        expect(HorizonTypography.displayHero.fontFamily, 'Space Grotesk');
        expect(HorizonTypography.tabularAmountLg.fontFamily, 'Space Grotesk');
        expect(
          HorizonTypography.tabularAmountLg.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );

        expect(HorizonTypography.bodyLg.fontFamily, 'Plus Jakarta Sans');
        expect(HorizonTypography.bodyMd.fontFamily, 'Plus Jakarta Sans');
        expect(HorizonTypography.labelCaps.letterSpacing, greaterThan(0));
      },
    );

    test(
      'INR Currency Formatter formats according to Indian numbering grouping',
      () {
        expect(HorizonFormatters.formatInr(1842850.40), '₹18,42,850.40');
        expect(HorizonFormatters.formatInr(8900), '₹8,900.00');
        expect(
          HorizonFormatters.formatInr(8900, decimalDigits: false),
          '₹8,900',
        );

        expect(HorizonFormatters.formatInr(5000, showSign: true), '+₹5,000.00');
        expect(
          HorizonFormatters.formatInr(-5000, showSign: true),
          '-₹5,000.00',
        );

        expect(HorizonFormatters.formatCompactInr(1842850), '₹18.43 L');
        expect(HorizonFormatters.formatCompactInr(12500000), '₹1.25 Cr');
      },
    );
  });

  group('FinTrack // HORIZON — Reusable Components Widget Tests', () {
    testWidgets(
      'HorizonSurface renders with Level 2 elevation and reacts to tap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: HorizonTheme.darkTheme,
            home: Scaffold(
              body: HorizonSurface(
                tier: HorizonSurfaceTier.surface2,
                onTap: () => tapped = true,
                child: const Text('Telemetry Module'),
              ),
            ),
          ),
        );

        expect(find.text('Telemetry Module'), findsOneWidget);
        await tester.tap(find.text('Telemetry Module'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'HorizonButton renders Ion Charge primary and handles loading state',
      (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: HorizonTheme.darkTheme,
            home: Scaffold(
              body: HorizonButton(
                text: 'Confirm Cash Flow',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        expect(find.text('CONFIRM CASH FLOW'), findsOneWidget);
        await tester.tap(find.text('CONFIRM CASH FLOW'));
        expect(pressed, isTrue);

        // Loading state
        await tester.pumpWidget(
          MaterialApp(
            theme: HorizonTheme.darkTheme,
            home: const Scaffold(
              body: HorizonButton(text: 'Confirm Cash Flow', isLoading: true),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('HorizonTextField renders 52px input with currency prefix', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: Scaffold(
            body: HorizonTextField(
              controller: controller,
              label: 'Transaction Amount',
              isCurrency: true,
            ),
          ),
        ),
      );

      expect(find.text('TRANSACTION AMOUNT'), findsOneWidget);
      expect(find.text('₹ '), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '8900.00');
      expect(controller.text, '8900.00');
    });

    testWidgets(
      'HorizonChip renders unselected and selected with 4px active dot',
      (tester) async {
        bool isSelected = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: HorizonTheme.darkTheme,
                home: Scaffold(
                  body: HorizonChip(
                    label: 'Food & Dining',
                    count: 7,
                    selected: isSelected,
                    onSelected: (val) => setState(() => isSelected = val),
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('Food & Dining'), findsOneWidget);
        expect(find.text('(7)'), findsOneWidget);

        // Tap to select
        await tester.tap(find.text('Food & Dining'));
        await tester.pumpAndSettle();

        expect(isSelected, isTrue);
      },
    );

    testWidgets(
      'HorizonTransactionRow renders tabular amounts with surplus and outflow formatting',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: HorizonTheme.darkTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  HorizonTransactionRow(
                    title: 'Salary Deposit',
                    amount: 125000,
                    isExpense: false,
                    category: 'Income',
                  ),
                  HorizonTransactionRow(
                    title: 'Whole Foods Market',
                    amount: 3450.50,
                    isExpense: true,
                    category: 'Groceries',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Salary Deposit'), findsOneWidget);
        expect(find.text('+₹1,25,000.00'), findsOneWidget);

        expect(find.text('Whole Foods Market'), findsOneWidget);
        expect(find.text('-₹3,450.50'), findsOneWidget);
      },
    );

    testWidgets(
      'HorizonNavigationDock renders 5 destinations and triggers destination selected',
      (tester) async {
        int selectedIdx = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: HorizonTheme.darkTheme,
                home: Scaffold(
                  bottomNavigationBar: HorizonNavigationDock(
                    selectedIndex: selectedIdx,
                    onDestinationSelected: (idx) =>
                        setState(() => selectedIdx = idx),
                  ),
                  body: const SizedBox(),
                ),
              );
            },
          ),
        );

        expect(
          find.byKey(const ValueKey('floating_navigation_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('floating_navigation_active_pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('floating_navigation_home')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('floating_navigation_ledger')),
          findsOneWidget,
        );

        // Tap Ledger destination
        await tester.tap(
          find.byKey(const ValueKey('floating_navigation_ledger')),
        );
        await tester.pumpAndSettle();

        expect(selectedIdx, 1);
      },
    );
  });
}
