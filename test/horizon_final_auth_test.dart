import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/horizon/horizon.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/auth/register_screen.dart';
import 'package:frontend/screens/auth/otp_verification_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [320.0, 393.0]) {
    testWidgets(
      'unsupported OTP cannot authenticate or follow a destination at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: '/otp-verification',
          routes: [
            GoRoute(
              path: '/otp-verification',
              builder: (_, _) =>
                  const OtpVerificationScreen(destination: '/dashboard'),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('Password sign in')),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (_, _) =>
                  const Scaffold(body: Text('Authenticated dashboard')),
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(
            theme: HorizonTheme.darkTheme,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Email code verification is not available yet.'),
          findsOneWidget,
        );
        expect(
          tester
              .widgetList<TextField>(find.byType(TextField))
              .every((field) => field.enabled == false),
          isTrue,
        );
        expect(find.text('Authenticated dashboard'), findsNothing);
        await tester.tap(find.text('BACK TO SIGN IN'));
        await tester.pumpAndSettle();
        expect(find.text('Password sign in'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      },
    );
  }
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
  for (final width in [320.0, 360.0, 393.0, 600.0, 1024.0]) {
    for (final dark in [true, false]) {
      for (final register in [true, false]) {
        testWidgets(
          'auth $width dark=$dark register=$register validates and reveals password',
          (tester) async {
            tester.view.physicalSize = Size(width, 852);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? HorizonTheme.darkTheme : HorizonTheme.lightTheme,
                home: register ? const RegisterScreen() : const LoginScreen(),
              ),
            );
            final fields = find.byType(TextFormField);
            final password = fields.at(register ? 2 : 1);
            await tester.ensureVisible(password);
            await tester.enterText(password, 'secret123');
            expect(
              tester
                  .widget<EditableText>(
                    find.descendant(
                      of: password,
                      matching: find.byType(EditableText),
                    ),
                  )
                  .obscureText,
              isTrue,
            );
            final field = find.ancestor(
              of: password,
              matching: find.byType(HorizonTextField),
            );
            await tester.tap(
              find.descendant(of: field, matching: find.byType(IconButton)),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<EditableText>(
                    find.descendant(
                      of: password,
                      matching: find.byType(EditableText),
                    ),
                  )
                  .obscureText,
              isFalse,
            );
            tester.state<FormState>(find.byType(Form)).validate();
            await tester.pumpAndSettle();
            expect(find.text('Email is required'), findsOneWidget);
            expect(find.textContaining('STEP 01 OF 02'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
