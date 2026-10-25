import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/screens/auth/register_screen.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'Space Grotesk': 'SpaceGrotesk',
      'Plus Jakarta Sans': 'PlusJakartaSans',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}.ttf'))).load();
    }
  });
  for (final width in [320.0, 360.0, 393.0, 600.0]) {
    testWidgets('register grid and keyboard scrolling at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: HorizonTheme.darkTheme,
          home: const RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(HorizonTextField);
      final inputs = find.byType(TextFormField);
      final shells = find.descendant(
        of: fields,
        matching: find.byType(AnimatedContainer),
      );
      expect(fields, findsNWidgets(4));
      final initialSizes = List.generate(
        4,
        (i) => tester.getSize(shells.at(i)),
      );
      final initialOffsets = List.generate(
        4,
        (i) => tester.getTopLeft(shells.at(i)),
      );
      for (var i = 0; i < 4; i++) {
        expect(initialSizes[i].height, 74);
        expect(initialSizes[i], initialSizes.first);
        expect(initialOffsets[i].dx, initialOffsets.first.dx);
        expect(
          tester.getTopLeft(inputs.at(i)).dx,
          tester.getTopLeft(inputs.first).dx,
        );
      }
      final card = find.byType(HorizonSurface);
      final heading = find.descendant(
        of: find.byType(Form),
        matching: find.text('Create Account'),
      );
      expect(tester.getTopLeft(heading).dx, tester.getTopLeft(card).dx);
      final cta = find.byKey(const ValueKey('register-submit'));
      expect(tester.getSize(cta).height, 68);
      expect(tester.getTopLeft(cta).dx, initialOffsets.first.dx);
      final headingToCard =
          tester.getTopLeft(card).dy - tester.getTopLeft(heading).dy;

      await tester.ensureVisible(inputs.first);
      await tester.tap(inputs.first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        if (i > 0) {
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await tester.pumpAndSettle();
        }
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: inputs.at(i),
            matching: find.byType(EditableText),
          ),
        );
        expect(editable.focusNode.hasFocus, isTrue);
        expect(tester.getRect(inputs.at(i)).bottom, lessThanOrEqualTo(400));
        expect(tester.getSize(shells.at(i)), initialSizes[i]);
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      expect(cta.hitTestable(), findsOneWidget);
      expect(tester.getRect(cta).bottom, lessThanOrEqualTo(400));
      final footer = find.text('Already have an account? ');
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();
      expect(footer.hitTestable(), findsOneWidget);
      final signIn = find.text('Sign In');
      double baseline(Finder finder) {
        final box = tester.renderObject<RenderBox>(finder);
        return box
            .localToGlobal(
              Offset(
                0,
                box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!,
              ),
            )
            .dy;
      }

      expect(baseline(footer), closeTo(baseline(signIn), 0.01));
      FocusManager.instance.primaryFocus?.unfocus();
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(card).dy - tester.getTopLeft(heading).dy,
        headingToCard,
      );
      for (var i = 0; i < 4; i++) {
        expect(tester.getTopLeft(shells.at(i)), initialOffsets[i]);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
