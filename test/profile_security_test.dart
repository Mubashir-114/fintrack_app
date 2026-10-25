import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/profile/security_screen.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _user;
  String? _errorMessage;
  bool updateProfileCalled = false;
  bool changePasswordCalled = false;
  String? lastUpdatedName;
  String? lastUpdatedEmail;

  _FakeAuthProvider({UserModel? initialUser}) : _user = initialUser;

  @override
  UserModel? get currentUser => _user;
  @override
  Uint8List? get avatarBytes => null;
  @override
  Future<void> loadAvatar() async {}
  @override
  Future<bool> saveAvatar(Uint8List? bytes) async => true;

  @override
  bool get isLoggedIn => _user != null;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  VoidCallback? get onSessionReset => null;

  @override
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    updateProfileCalled = true;
    lastUpdatedName = name;
    lastUpdatedEmail = email;
    _user = UserModel(id: _user?.id ?? 1, name: name, email: email);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    return true;
  }

  @override
  Future<bool> login({required String email, required String password}) async =>
      true;

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async => true;

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> loadCurrentUser() async => true;

  @override
  Future<bool> deleteAccount({required String password}) async => false;
}

Widget _wrapWithProviders({
  required Widget child,
  required _FakeAuthProvider authProvider,
  CurrencyProvider? currencyProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CurrencyProvider>.value(
        value: currencyProvider ?? CurrencyProvider(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

void main() {
  group('Graphite & Champagne Default Theme Token Specifications', () {
    test('Dark theme tokens match graphite and champagne specifications', () {
      expect(AppColors.darkScaffold, const Color(0xFF171B24));
      expect(AppColors.surfaceDark, const Color(0xFF252934));
      expect(AppColors.elevatedDark, const Color(0xFF30343F));
      expect(AppColors.primary, const Color(0xFFD6A668));
      expect(AppColors.primaryDeep, const Color(0xFFBE8F50));
      expect(AppColors.secondary, const Color(0xFFE6BE85));
      expect(AppColors.textLight, const Color(0xFFF4EFE7));
      expect(AppColors.textSecondaryDark, const Color(0xFFB5AFAB));
      expect(AppColors.dividerDark, const Color(0xFF393D48));
    });

    test('ThemeData reflects graphite surface and champagne primary', () {
      final darkTheme = AppTheme.buildTheme(
        ThemeCollection.graphiteChampagne,
        Brightness.dark,
      );
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF12151B));
      expect(darkTheme.colorScheme.primary, const Color(0xFFD6A668));
      expect(darkTheme.colorScheme.surface, const Color(0xFF1B1E26));
    });
  });

  group('ProfileScreen Layout & Read-Only Hierarchy', () {
    testWidgets(
      'renders editorial identity hero and flat settings sections without permanent form fields',
      (tester) async {
        final fakeAuth = _FakeAuthProvider(
          initialUser: const UserModel(
            id: 42,
            name: 'Elena Rostova',
            email: 'elena@fintrack.io',
          ),
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            child: const ProfileScreen(),
            authProvider: fakeAuth,
          ),
        );

        // Identity hero: avatar monogram, name, email, edit and FIN access
        expect(find.text('Elena Rostova'), findsOneWidget);
        expect(find.text('elena@fintrack.io'), findsOneWidget);
        expect(find.text('E'), findsOneWidget); // Monogram initial
        expect(find.text('Edit profile'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('profile-fin-presence')),
          findsOneWidget,
        );
        expect(find.text('FIN'), findsOneWidget);

        // No technical page branding or command-deck labels remain
        expect(find.textContaining('Command Deck'), findsNothing);
        expect(find.textContaining('Telemetry'), findsNothing);

        // Verify no permanent form fields are exposed on main screen
        expect(find.byType(TextFormField), findsNothing);

        // Verify flat settings sections
        expect(find.text('Preferences'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Accounts & money storage'), findsOneWidget);
        expect(find.text('Display currency'), findsOneWidget);

        expect(find.text('Security'), findsOneWidget);
        expect(find.text('Security & password'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);

        expect(find.text('FinTrack'), findsOneWidget);
        expect(find.text('SMS import'), findsOneWidget);

        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Log out'), findsOneWidget);
        expect(find.text('Delete account'), findsOneWidget);
      },
    );

    testWidgets('keeps identity actions from overlapping into 2x text', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(
          id: 42,
          name: 'Alexandra Konstantinopoulos-Rivera',
          email: 'alexandra.konstantinopoulos@very-long-domain.example.com',
        ),
      );

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
              ChangeNotifierProvider(create: (_) => CurrencyProvider()),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit profile'), findsOneWidget);
      final editRect = tester.getRect(
        find.byKey(const ValueKey('profile-edit')),
      );
      expect(editRect.left, greaterThanOrEqualTo(0));
      expect(editRect.right, lessThanOrEqualTo(320));
    });
  });

  group('ProfileScreen actions', () {
    Future<GoRouter> pumpProfileApp(
      WidgetTester tester,
      _FakeAuthProvider auth,
    ) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          for (final path in [
            '/profile/edit',
            '/profile/appearance',
            '/profile/security',
            '/profile/privacy',
            '/profile/delete',
            '/profile/fin',
            '/accounts',
            '/sms-import',
          ])
            GoRoute(
              path: path,
              builder: (context, state) =>
                  Scaffold(body: Center(child: Text('opened $path'))),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: ChangeNotifierProvider<CurrencyProvider>(
            create: (_) => CurrencyProvider(),
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('keeps every existing profile destination reachable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _FakeAuthProvider(
        initialUser: const UserModel(
          id: 7,
          name: 'Elena Rostova',
          email: 'elena@fintrack.io',
        ),
      );
      final router = await pumpProfileApp(tester, auth);

      final destinations = <String, String>{
        'Appearance': '/profile/appearance',
        'Accounts & money storage': '/accounts',
        'Security & password': '/profile/security',
        'Privacy': '/profile/privacy',
        'SMS import': '/sms-import',
        'Delete account': '/profile/delete',
      };

      for (final entry in destinations.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(
          find.text('opened ${entry.value}'),
          findsOneWidget,
          reason: '${entry.key} should open ${entry.value}',
        );
        router.go('/profile');
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const ValueKey('profile-edit')));
      await tester.pumpAndSettle();
      expect(find.text('opened /profile/edit'), findsOneWidget);
      router.go('/profile');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-fin-presence')));
      await tester.pumpAndSettle();
      expect(find.text('opened /profile/fin'), findsOneWidget);
      router.go('/profile');
      await tester.pumpAndSettle();

      await tester.tap(find.text('FIN companion'));
      await tester.pumpAndSettle();
      expect(find.text('opened /profile/fin'), findsOneWidget);
    });

    testWidgets('opens the currency picker and confirms logout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _FakeAuthProvider(
        initialUser: const UserModel(
          id: 7,
          name: 'Elena Rostova',
          email: 'elena@fintrack.io',
        ),
      );
      await pumpProfileApp(tester, auth);

      await tester.tap(find.text('Display currency'));
      await tester.pumpAndSettle();
      expect(find.text('USD (\$)'), findsOneWidget);
      expect(find.text('EUR (€)'), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('EUR (€)'), findsNothing);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsNothing);
      expect(find.text('Elena Rostova'), findsOneWidget);
    });
  });

  group('EditProfileScreen', () {
    testWidgets('initializes with current user and tracks change state', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(
          id: 10,
          name: 'Marcus Vance',
          email: 'marcus@vance.io',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: const EditProfileScreen(),
          authProvider: fakeAuth,
        ),
      );

      expect(find.text('Edit Personal Details'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Marcus Vance'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'marcus@vance.io'),
        findsOneWidget,
      );

      // Modify the name
      final nameField = find.widgetWithText(TextFormField, 'Marcus Vance');
      await tester.enterText(nameField, 'Marcus Vance Jr');
      await tester.pumpAndSettle();

      // Tap SAVE CHANGES
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(fakeAuth.updateProfileCalled, isTrue);
      expect(fakeAuth.lastUpdatedName, 'Marcus Vance Jr');
      expect(fakeAuth.lastUpdatedEmail, 'marcus@vance.io');
    });
  });

  group('SecurityScreen', () {
    testWidgets('validates required fields and minimum length', (tester) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(
          id: 10,
          name: 'User',
          email: 'user@test.com',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: const SecurityScreen(),
          authProvider: fakeAuth,
        ),
      );

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);

      // Tap update without entering passwords
      await tester.ensureVisible(find.text('UPDATE PASSWORD'));
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is required'), findsOneWidget);
      expect(fakeAuth.changePasswordCalled, isFalse);

      // Enter valid current, invalid new
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'oldpass123');
      await tester.enterText(textFields.at(1), '123');
      await tester.enterText(textFields.at(2), '123');
      await tester.ensureVisible(find.text('UPDATE PASSWORD'));
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      // Enter matching valid new passwords
      await tester.enterText(textFields.at(1), 'newsecret456');
      await tester.enterText(textFields.at(2), 'newsecret456');
      await tester.ensureVisible(find.text('UPDATE PASSWORD'));
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(fakeAuth.changePasswordCalled, isTrue);
    });
  });
}
