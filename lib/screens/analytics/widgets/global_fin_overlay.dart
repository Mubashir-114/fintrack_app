import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/analytics_provider.dart';
import '../../../models/companion_model.dart';
import 'fin_character.dart';

/// Both navigators report popups so FIN cannot sit above a dialog or sheet.
class FinOverlayObserver extends NavigatorObserver {
  static final obscured = ValueNotifier<bool>(false);
  static final Set<Route<dynamic>> _popups = {};
  void _update() => obscured.value = _popups.isNotEmpty;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _popups.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _popups.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _popups.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _popups.remove(oldRoute);
    if (newRoute is PopupRoute) _popups.add(newRoute);
    _update();
  }
}

/// Restricted to browsing surfaces; forms, import and security stay unobstructed.
class GlobalFinOverlay extends StatefulWidget {
  const GlobalFinOverlay({super.key});
  static const peekWidth = 44.0;
  static bool supportsLocation(String location) => const {
    '/dashboard',
    '/transactions',
    '/budgets',
    '/reports',
    '/planning',
    '/profile',
    '/accounts',
  }.contains(location);
  @override
  State<GlobalFinOverlay> createState() => _GlobalFinOverlayState();
}

class _GlobalFinOverlayState extends State<GlobalFinOverlay>
    with WidgetsBindingObserver {
  double _vertical = .42;
  String? _location;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    // Scaffold may consume the keyboard inset without changing MediaQuery
    // below it. Rebuild from the view metrics even in that case.
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final controller = provider.visualController;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, FinOverlayObserver.obscured]),
      builder: (context, _) {
        final location = GoRouterState.of(context).matchedLocation;
        if (_location != location) {
          _location = location;
          // Route changes never reopen a mini panel.
          if (controller.isPeekExpanded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) controller.setPeekExpanded(false);
            });
          }
        }
        final prefs = provider.companionPreferences;
        final media = MediaQuery.of(context);
        final hidden =
            !_foreground ||
            !prefs.showAcrossApp ||
            controller.isFloatingDismissed ||
            controller.isFullCompanionOpen ||
            !GlobalFinOverlay.supportsLocation(location) ||
            (media.viewInsets.bottom > 0 ||
                View.of(context).viewInsets.bottom > 0) ||
            FinOverlayObserver.obscured.value;
        if (hidden) {
          if (controller.isPeekExpanded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) controller.setPeekExpanded(false);
            });
          }
          return const SizedBox.shrink();
        }
        final isLeft = prefs.edgePosition == 'left';
        final expanded = controller.isPeekExpanded;
        final colors = AppColors.of(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            // Work inside one unoccluded display region on a hinged device.
            var region = Rect.fromLTRB(
              media.padding.left,
              media.padding.top + 64,
              constraints.maxWidth - media.padding.right,
              constraints.maxHeight - media.padding.bottom - 16,
            );
            for (final feature in media.displayFeatures) {
              if (feature.bounds.height > feature.bounds.width &&
                  feature.bounds.height > 0) {
                region = isLeft
                    ? Rect.fromLTRB(
                        region.left,
                        region.top,
                        math.min(region.right, feature.bounds.left),
                        region.bottom,
                      )
                    : Rect.fromLTRB(
                        math.max(region.left, feature.bounds.right),
                        region.top,
                        region.right,
                        region.bottom,
                      );
              } else if (feature.bounds.width > 0) {
                region = Rect.fromLTRB(
                  region.left,
                  region.top,
                  region.right,
                  math.min(region.bottom, feature.bounds.top),
                );
              }
            }
            if (region.width < 180 || region.height < 120) {
              return const SizedBox.shrink();
            }
            const handleHeight = 104.0;
            final y = (region.top + (region.height - handleHeight) * _vertical)
                .clamp(region.top, region.bottom - handleHeight);
            final panelWidth = math.min(320.0, region.width - 16);
            final panelHeight = math.min(360.0, region.height);
            final panelTop = (y - 36).clamp(
              region.top,
              math.max(region.top, region.bottom - panelHeight),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                if (expanded)
                  Positioned(
                    left: isLeft
                        ? region.left + 8
                        : region.right - panelWidth - 8,
                    top: panelTop.toDouble(),
                    width: panelWidth,
                    child: TapRegion(
                      onTapOutside: (_) => controller.setPeekExpanded(false),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: media.disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset((isLeft ? -8 : 8) * (1 - value), 0),
                            child: child,
                          ),
                        ),
                        child: Material(
                          key: const ValueKey('global_fin_action_panel'),
                          elevation: 12,
                          shadowColor: colors.textPrimary.withValues(
                            alpha: .18,
                          ),
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(22),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: panelHeight),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      FinCharacter(
                                        size: 56,
                                        controller: controller,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'FIN is here',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        key: const ValueKey(
                                          'global_fin_edge_switch',
                                        ),
                                        tooltip:
                                            'Move FIN to the ${isLeft ? "right" : "left"} edge',
                                        onPressed: () =>
                                            provider.updateCompanionPreferences(
                                              prefs.copyWith(
                                                edgePosition: isLeft
                                                    ? 'right'
                                                    : 'left',
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.swap_horiz_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        key: const ValueKey(
                                          'global_fin_action_close',
                                        ),
                                        tooltip: 'Minimize FIN',
                                        onPressed: () =>
                                            controller.setPeekExpanded(false),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    prefs.enablePersonalizedGreetings &&
                                            (prefs.preferredName
                                                    ?.trim()
                                                    .isNotEmpty ??
                                                false)
                                        ? 'Hi, ${prefs.preferredName!.trim()}.'
                                        : 'Your money, a little clearer.',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.isLoading
                                        ? 'Reviewing your saved records…'
                                        : provider.activeAlerts.isNotEmpty
                                        ? provider.activeAlerts.first.title
                                        : 'Explore the records you have approved in FinTrack.',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _action(
                                    context,
                                    'global_fin_action_talk',
                                    Icons.chat_bubble_outline_rounded,
                                    'Talk to FIN',
                                    () {
                                      controller.setPeekExpanded(false);
                                      context.push('/analytics');
                                    },
                                  ),
                                  _action(
                                    context,
                                    'global_fin_action_spending',
                                    Icons.pie_chart_outline_rounded,
                                    'My spending',
                                    () {
                                      controller.setPeekExpanded(false);
                                      context.push(
                                        Uri(
                                          path: '/analytics',
                                          queryParameters: {
                                            'q':
                                                'How much did I spend this month?',
                                          },
                                        ).toString(),
                                      );
                                    },
                                  ),
                                  _action(
                                    context,
                                    'global_fin_action_budget',
                                    Icons.account_balance_wallet_outlined,
                                    'Budget check',
                                    () {
                                      controller.setPeekExpanded(false);
                                      context.go('/budgets');
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          key: const ValueKey(
                                            'global_fin_vertical_switch',
                                          ),
                                          onPressed: () {
                                            controller.setPeekExpanded(false);
                                            setState(
                                              () => _vertical = _vertical < .5
                                                  ? .85
                                                  : .15,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.height_rounded,
                                          ),
                                          label: const Text('Move up / down'),
                                        ),
                                      ),
                                      IconButton(
                                        key: const ValueKey(
                                          'global_fin_dismiss',
                                        ),
                                        tooltip: 'Dismiss FIN for this session',
                                        onPressed: controller.dismissFloating,
                                        icon: const Icon(
                                          Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!expanded)
                  Positioned(
                    left: isLeft
                        ? region.left
                        : region.right - GlobalFinOverlay.peekWidth,
                    top: y,
                    width: GlobalFinOverlay.peekWidth,
                    height: handleHeight,
                    child: Semantics(
                      button: true,
                      label: 'Open FIN mini companion',
                      hint:
                          'Drag up or down to reposition. Long press to dismiss.',
                      customSemanticsActions: {
                        CustomSemanticsAction(
                          label: 'Dismiss FIN for this session',
                        ): controller.dismissFloating,
                        CustomSemanticsAction(
                          label: 'Move FIN up or down',
                        ): () => setState(
                          () => _vertical = _vertical < .5 ? .85 : .15,
                        ),
                      },
                      child: GestureDetector(
                        key: const ValueKey('global_fin_peeking_character'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.setPeekExpanded(true);
                          if (!provider.isLoading &&
                              !provider.isExecutingAction &&
                              controller.state == FinCharacterState.idle) {
                            controller.onGreeting();
                          }
                        },
                        onLongPress: controller.dismissFloating,
                        onVerticalDragUpdate: (details) => setState(
                          () => _vertical =
                              (_vertical +
                                      details.delta.dy /
                                          math.max(
                                            1,
                                            region.height - handleHeight,
                                          ))
                                  .clamp(0, 1),
                        ),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: isLeft
                                ? Alignment.topRight
                                : Alignment.topLeft,
                            minWidth: 106,
                            maxWidth: 106,
                            minHeight: 148,
                            maxHeight: 148,
                            child: FinCharacter(
                              size: 148,
                              controller: controller,
                              isPeeking: true,
                              peekingOnLeft: isLeft,
                              animationsEnabled: prefs.animationsEnabled,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _action(
    BuildContext context,
    String key,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => ListTile(
    key: ValueKey(key),
    minTileHeight: 48,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: Icon(icon, color: AppColors.of(context).primary),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
    onTap: onTap,
  );
}
