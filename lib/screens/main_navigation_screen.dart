import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/horizon/horizon.dart';
import '../core/services/connectivity_service.dart';
import '../core/widgets/floating_bottom_navigation.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/report_provider.dart';
import '../providers/account_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/analytics_provider.dart';
import 'analytics/widgets/global_fin_overlay.dart';
import 'analytics/widgets/fin_content_bounds.dart';
import 'primary_page_view.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;
  final List<WidgetBuilder>? primaryDestinations;

  const MainNavigationScreen({
    super.key,
    required this.child,
    this.primaryDestinations,
  }) : assert(primaryDestinations == null || primaryDestinations.length == 5);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _hasMountedPrimary = false;
  int _primaryIndex = 0;
  GoRouterDelegate? _routerDelegate;
  static const _primaryRoutes = [
    "/dashboard",
    "/ledger",
    "/budgets",
    "/reports",
    "/profile",
  ];
  final _finContentBounds = ValueNotifier<List<Rect>>([Rect.largest]);

  @override
  void initState() {
    super.initState();
    // FIN is mounted immediately with the default (visible) preferences so a
    // slow or failed preference request can never hide the companion entirely.
    // Saved preferences are applied as soon as they arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsProvider>().loadCompanionPreferences();
    });
    _connectivitySubscription = ConnectivityService.connectionStream.listen((
      isOnline,
    ) {
      if (isOnline && _wasOffline) {
        _syncData();
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.of(context).routerDelegate;
    if (delegate == _routerDelegate) return;
    _routerDelegate?.removeListener(_onRouteChanged);
    _routerDelegate = delegate..addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  String get _location =>
      _routerDelegate!.currentConfiguration.last.matchedLocation;

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onRouteChanged);
    _finContentBounds.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _syncData() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.sync_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text("Connection restored. Syncing latest data..."),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.read<DashboardProvider>().loadDashboardData();
    context.read<TransactionProvider>().loadTransactions();
    context.read<BudgetProvider>().loadBudgetStatus();
    context.read<ReportProvider>().loadAllReports();
    context.read<AccountProvider>().loadAccounts();
    context.read<GoalProvider>().loadGoals();
  }

  int _getSelectedIndex(BuildContext context) {
    final String location = _location;
    if (location.startsWith('/dashboard')) return 0;
    // `/transactions` remains a compatible deep link to transaction
    // management. It belongs to the Ledger destination in the new IA.
    if (location.startsWith('/ledger') ||
        location.startsWith('/transactions')) {
      return 1;
    }
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    String route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/ledger';
        break;
      case 2:
        route = '/budgets';
        break;
      case 3:
        route = '/reports';
        break;
      case 4:
        route = '/profile';
        break;
      default:
        route = '/dashboard';
    }
    context.read<AnalyticsProvider>().visualController.onNavigation(route);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final horizon = HorizonThemeTokens.of(context);
    final colors = AppColors.of(context);
    final media = MediaQuery.of(context);
    final isTablet = media.size.width >= 600 && media.size.height >= 520;

    final location = _location;
    final isPrimary = _primaryRoutes.contains(location);
    if (isPrimary) _primaryIndex = selectedIndex;
    _hasMountedPrimary |= isPrimary && widget.primaryDestinations != null;
    final content = widget.primaryDestinations == null
        ? widget.child
        : Stack(
            fit: StackFit.expand,
            children: [
              if (_hasMountedPrimary)
                Offstage(
                  offstage: !isPrimary,
                  child: PrimaryPageView(
                    selectedIndex: _primaryIndex,
                    builders: widget.primaryDestinations!,
                    active: isPrimary,
                    onPageChanged: (index) => _onItemTapped(index, context),
                  ),
                ),
              Offstage(offstage: isPrimary, child: widget.child),
            ],
          );

    Widget mainLayout;

    if (isTablet) {
      // Tablet/Desktop responsive layout: Use Navigation Rail
      mainLayout = Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            backgroundColor: horizon.surface1,
            indicatorColor: horizon.ionCyan.withValues(alpha: 0.14),
            selectedLabelTextStyle: TextStyle(
              color: horizon.ionCyan,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(
                  Icons.grid_view_rounded,
                  color: horizon.ionCyan,
                ),
                label: const Text('Home'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.receipt_long_rounded),
                selectedIcon: Icon(
                  Icons.receipt_long_rounded,
                  color: horizon.ionCyan,
                ),
                label: const Text('Ledger'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.account_balance_wallet_rounded),
                selectedIcon: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: horizon.ionCyan,
                ),
                label: const Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(
                  Icons.bar_chart_rounded,
                  color: horizon.ionCyan,
                ),
                label: const Text('Reports'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.person_rounded),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: horizon.ionCyan,
                ),
                label: const Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: content),
        ],
      );
    } else {
      // Mobile standard layout: Bottom Navigation Bar
      mainLayout = content;
    }

    final screenTitle = switch (location) {
      '/dashboard' => 'Dashboard',
      '/transactions' => 'Transactions',
      '/ledger' => 'Ledger',
      '/income-details' => 'Income details',
      '/money-storage' => 'Money storage',
      '/sms-import' => 'SMS import',
      '/budgets' => 'Budgets',
      '/reports' => 'Reports',
      '/analytics' => 'FIN',
      '/planning' => 'Planning',
      '/profile' => 'Profile',
      '/profile/edit' => 'Edit profile',
      '/profile/security' => 'Security',
      '/profile/privacy' => 'Privacy & data controls',
      '/profile/delete' => 'Delete account',
      '/profile/appearance' => 'Appearance',
      _ => location.startsWith('/accounts') ? 'Accounts' : 'FinTrack',
    };
    return PopScope(
      canPop:
          widget.primaryDestinations == null ||
          !isPrimary ||
          selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isPrimary && selectedIndex != 0) {
          _onItemTapped(0, context);
        }
      },
      child: Title(
        title: '$screenTitle | FinTrack',
        color: colors.primary,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FinContentBounds(
                  bounds: _finContentBounds,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StreamBuilder<bool>(
                        stream: ConnectivityService.connectionStream,
                        initialData: ConnectivityService.isOnline,
                        builder: (context, snapshot) {
                          final isOnline = snapshot.data ?? true;
                          if (isOnline) return const SizedBox.shrink();
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: 12,
                            ),
                            color: AppColors.danger.withValues(alpha: .94),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Offline · Showing saved data. Changes need a connection.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Expanded(child: mainLayout),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: GlobalFinOverlay(
                  contentBounds: _finContentBounds,
                  location: location,
                ),
              ),
            ],
          ),
          // The shell reserves this height, so scrollable screen content never
          // sits beneath the floating card. Hide it while a keyboard is open so
          // fields retain the full visible area.
          bottomNavigationBar: !isTablet && media.viewInsets.bottom == 0
              ? FloatingBottomNavigation(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                )
              : null,
        ),
      ),
    );
  }
}
