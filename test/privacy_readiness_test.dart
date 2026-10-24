import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:frontend/screens/profile/delete_account_screen.dart';
import 'package:frontend/screens/profile/privacy_screen.dart';

class _DeletionRepository extends AuthRepository {
  bool shouldFail = true;
  int calls = 0;
  @override
  Future<void> deleteAccount({required String password}) async {
    calls++;
    if (shouldFail) throw StateError('synthetic failure');
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  test(
    'local session is cleared only after backend confirms deletion',
    () async {
      final repository = _DeletionRepository();
      var removals = 0;
      final auth = AuthProvider(
        repository: repository,
        tokenRemover: () async {
          removals++;
        },
      );
      expect(await auth.deleteAccount(password: 'synthetic'), isFalse);
      expect(removals, 0);
      expect(auth.errorMessage, contains('Unable to confirm deletion'));
      repository.shouldFail = false;
      expect(await auth.deleteAccount(password: 'synthetic'), isTrue);
      expect(removals, 1);
      expect(repository.calls, 2);
    },
  );

  for (final dark in [false, true]) {
    for (final screen in [const PrivacyScreen(), const DeleteAccountScreen()]) {
      testWidgets(
        '${screen.runtimeType} reflows at 320 with 200% text in ${dark ? "dark" : "light"}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AuthProvider(),
              child: MaterialApp(
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: screen,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'deletion requires password and exact confirmation before contacting backend',
    (tester) async {
      final repository = _DeletionRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: repository),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DeleteAccountScreen(),
          ),
        ),
      );
      await tester.ensureVisible(find.text('DELETE ACCOUNT PERMANENTLY'));
      await tester.tap(find.text('DELETE ACCOUNT PERMANENTLY'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Type DELETE exactly'), findsOneWidget);
      expect(repository.calls, 0);
    },
  );

  testWidgets(
    'deletion can be cancelled at the final confirmation without a backend call',
    (tester) async {
      final repository = _DeletionRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: repository),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DeleteAccountScreen(),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'synthetic-password');
      await tester.enterText(fields.at(1), 'DELETE');
      await tester.ensureVisible(find.text('DELETE ACCOUNT PERMANENTLY'));
      await tester.tap(find.text('DELETE ACCOUNT PERMANENTLY'));
      await tester.pumpAndSettle();
      expect(find.text('Permanently delete your account?'), findsOneWidget);
      expect(repository.calls, 0);
      await tester.tap(find.text('Keep account'));
      await tester.pumpAndSettle();
      expect(repository.calls, 0);
    },
  );
}
