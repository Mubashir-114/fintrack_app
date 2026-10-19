import '../screens/profile/privacy_screen.dart';
import '../screens/profile/delete_account_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_motion.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/budgets/budgets_list_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/security_screen.dart';
import '../screens/profile/appearance_screen.dart';
import '../screens/transactions/sms_import_screen.dart';
import '../screens/accounts/accounts_list_screen.dart';
import '../screens/accounts/add_account_screen.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/accounts/edit_account_screen.dart';
import '../screens/transfers/transfer_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/analytics/widgets/global_fin_overlay.dart';
import '../screens/planning/planning_screen.dart';
import '../screens/planning/goal_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  observers: [FinOverlayObserver()],
  initialLocation: '/splash',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('FinTrack ? Page not found')),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'This page is unavailable. Return to FinTrack to continue.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(
                  context.read<AuthProvider>().isLoggedIn
                      ? '/dashboard'
                      : '/login',
                ),
                child: const Text('Return to FinTrack'),
              ),
            ],
          ),
        ),
      ),
    ),
  ),

  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;

    final isGoingToSplash = state.matchedLocation == '/splash';
    final isGoingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (isGoingToSplash) {
      return null;
    }

    if (state.matchedLocation == '/privacy') return null;

    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }

    if (isLoggedIn && (isGoingToAuth || isGoingToSplash)) {
      return '/dashboard';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // Full-screen account creation modal outside bottom-navigation shell
    GoRoute(
      path: '/accounts/add',
      builder: (context, state) => const AddAccountScreen(),
    ),
    GoRoute(
      path: '/accounts/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EditAccountScreen(accountId: id);
      },
    ),
    ShellRoute(
      observers: [FinOverlayObserver()],
      builder: (context, state, child) => MainNavigationScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.quick,
            reverseTransitionDuration: Duration.zero,
            child: const DashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsListScreen(),
        ),
        GoRoute(
          path: '/sms-import',
          builder: (context, state) => const SmsImportScreen(),
        ),
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) {
            final q = state.extra is String
                ? state.extra as String
                : state.uri.queryParameters['q'];
            return AnalyticsScreen(initialQuestion: q);
          },
        ),
        GoRoute(
          path: '/planning',
          builder: (context, state) => const PlanningScreen(),
        ),
        GoRoute(
          path: '/planning/goals/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return GoalDetailScreen(goalId: id);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/privacy',
          builder: (context, state) => const PrivacyScreen(),
        ),
        GoRoute(
          path: '/profile/delete',
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/security',
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          path: '/profile/appearance',
          builder: (context, state) => const AppearanceScreen(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsListScreen(),
        ),
        GoRoute(
          path: '/accounts/transfer',
          builder: (context, state) {
            final sourceId = int.tryParse(
              state.uri.queryParameters['sourceId'] ?? '',
            );
            return TransferScreen(initialSourceAccountId: sourceId);
          },
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return AccountDetailScreen(accountId: id);
          },
        ),
      ],
    ),
  ],
);
