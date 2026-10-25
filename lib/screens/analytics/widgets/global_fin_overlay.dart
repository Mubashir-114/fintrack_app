import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;
import 'package:flutter/foundation.dart';
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
  const GlobalFinOverlay({super.key, this.contentBounds, this.location});
  final String? location;

  final ValueListenable<List<Rect>>? contentBounds;

  /// Transparent hit target at the edge. The painted portrait is wider but
  /// allocates no page space.
  static const peekWidth = 56.0;
  static bool supportsLocation(String location) => const {
    '/dashboard',
    '/transactions',
    '/ledger',
    '/budgets',
    '/reports',
    '/planning',
    // `/profile` renders FIN inside its identity hero, so the edge peek is
    // omitted there to avoid a second, viewport-clipped FIN over the identity.
    '/profile/fin',
    '/accounts',
  }.contains(location);
  @override
  State<GlobalFinOverlay> createState() => _GlobalFinOverlayState();
}

class _GlobalFinOverlayState extends State<GlobalFinOverlay>
    with WidgetsBindingObserver {
  /// Height of the peeking character as rendered (the lower body is clipped).
  static const double _peekVisualHeight = 196;
  static const double _peekHitWidth = GlobalFinOverlay.peekWidth;
  static const double _peekHitHeight = 124;
  static const double _peekPanelCharacterSize = 68;

  double _vertical = .42;
  String? _location;
  bool _foreground = true;
  Timer? _greetingTimer;
  bool _panelFits = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// A short one-off wave while FIN leans in, never a permanent raised arm.
  void _greetThenRelax(AnalyticsProvider provider) {
    if (!_panelFits) {
      context.go('/analytics');
      return;
    }
    final controller = provider.visualController;
    controller.setPeekExpanded(true);
    controller.onGreeting();
    _greetingTimer?.cancel();
    _greetingTimer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted && controller.state == FinCharacterState.greeting) {
        controller.onIdle();
      }
    });
  }

  void _minimize(AnalyticsProvider provider) {
    _greetingTimer?.cancel();
    provider.visualController
      ..setPeekExpanded(false)
      ..onIdle();
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
    _greetingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final controller = provider.visualController;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        FinOverlayObserver.obscured,
        widget.contentBounds,
      ]),
      builder: (context, _) {
        final location =
            widget.location ?? GoRouterState.of(context).matchedLocation;
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
        // Transaction amounts and action menus are right-aligned. On both
        // transaction surfaces FIN peeks from the opposite edge so its visual
        // layer cannot obscure those controls.
        final isTransactionSurface =
            location == '/transactions' || location == '/ledger';
        final isLeft = isTransactionSurface
            ? true
            : prefs.edgePosition == 'left';
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
            // Only a real fold/hinge may divide the usable area. Cutouts and
            // notches are already covered by safe-area padding; treating one
            // as a fold collapsed this region to zero and hid FIN entirely on
            // normal phones.
            for (final feature in media.displayFeatures) {
              if (feature.type != DisplayFeatureType.fold &&
                  feature.type != DisplayFeatureType.hinge) {
                continue;
              }
              final bounds = feature.bounds;
              if (bounds.width <= 0 ||
                  bounds.height <= 0 ||
                  !region.overlaps(bounds)) {
                continue;
              }
              final vertical = bounds.height > bounds.width;
              final candidate = vertical
                  ? (isLeft
                        ? Rect.fromLTRB(
                            region.left,
                            region.top,
                            math.min(region.right, bounds.left),
                            region.bottom,
                          )
                        : Rect.fromLTRB(
                            math.max(region.left, bounds.right),
                            region.top,
                            region.right,
                            region.bottom,
                          ))
                  : Rect.fromLTRB(
                      region.left,
                      region.top,
                      region.right,
                      math.min(region.bottom, bounds.top),
                    );
              if (candidate.width < 180 || candidate.height < 120) continue;
              region = candidate;
            }
            if (region.width < 180 || region.height < 120) {
              return const SizedBox.shrink();
            }
            // FIN's visible sliver: enough for head, shoulder, torso and a
            // gripping hand on every supported width. This is painted above
            // content, it never reserves page width.
            final peekWindow = math.min(
              math.min(96.0, region.width),
              math.max(80.0, region.width * .22),
            );
            var y =
                (region.top + (region.height - _peekVisualHeight) * _vertical)
                    .clamp(
                      region.top,
                      math.max(region.top, region.bottom - _peekVisualHeight),
                    )
                    .toDouble();
            final panelWidth = math.min(320.0, region.width - 16);
            final panelHeight = math.min(360.0, region.height);
            var panelTop = (y - 24).clamp(
              region.top,
              math.max(region.top, region.bottom - panelHeight),
            );
            // Find blank space instead of covering records or controls. If a
            // panel cannot fit, tapping FIN opens the dedicated conversation.
            // The shell's content observer and overlay are full-size siblings.
            const origin = Offset.zero;
            final occupied = widget.contentBounds?.value ?? const <Rect>[];
            double? freeTop(
              double x,
              double width,
              double height,
              double preferred,
            ) {
              final maxTop = region.bottom - height;
              final candidates =
                  <double>[
                    preferred,
                    region.top,
                    maxTop,
                    for (final rect in occupied) rect.bottom - origin.dy,
                  ]..sort(
                    (a, b) =>
                        (a - preferred).abs().compareTo((b - preferred).abs()),
                  );
              for (final top in candidates) {
                if (top < region.top || top > maxTop) continue;
                final footprint = Rect.fromLTWH(
                  x,
                  top,
                  width,
                  height,
                ).shift(origin);
                if (!occupied.any(footprint.overlaps)) return top;
              }
              return null;
            }

            final safeY = freeTop(
              isLeft ? region.left : region.right - peekWindow,
              peekWindow,
              _peekVisualHeight,
              y,
            );
            if (safeY == null) return const SizedBox.shrink();
            y = safeY;
            final safePanelTop = freeTop(
              isLeft ? region.left + 8 : region.right - panelWidth - 8,
              panelWidth,
              panelHeight,
              panelTop.toDouble(),
            );
            _panelFits = safePanelTop != null;
            if (safePanelTop != null) panelTop = safePanelTop;
            if (expanded && !_panelFits) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && controller.isPeekExpanded) {
                  controller.setPeekExpanded(false);
                  context.go('/analytics');
                }
              });
              return const SizedBox.shrink();
            }
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
                                        key: const ValueKey(
                                          'global_fin_panel_character',
                                        ),
                                        size: _peekPanelCharacterSize,
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
                                        onPressed: () => _minimize(provider),
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
                                    'Spending Overview',
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
                                    'Budget Check',
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
                                        tooltip: 'Hide FIN for this session',
                                        onPressed: () {
                                          _greetingTimer?.cancel();
                                          controller.dismissFloating();
                                        },
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
                if (!expanded) ...[
                  // Painted portrait layer. The character is wider than the
                  // window; its far side is clipped by the screen edge so FIN
                  // reads as leaning out from it.
                  Positioned(
                    left: isLeft ? region.left : null,
                    right: isLeft
                        ? null
                        : math.max(0.0, constraints.maxWidth - region.right),
                    top: y,
                    width: peekWindow,
                    height: _peekVisualHeight,
                    child: IgnorePointer(
                      child: ClipRect(
                        key: const ValueKey('global_fin_peeking_visual'),
                        child: OverflowBox(
                          alignment: isLeft
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          minWidth: _peekVisualHeight * .72,
                          maxWidth: _peekVisualHeight * .72,
                          minHeight: _peekVisualHeight,
                          maxHeight: _peekVisualHeight,
                          child: FinCharacter(
                            size: _peekVisualHeight,
                            controller: controller,
                            isPeeking: true,
                            peekingOnLeft: isLeft,
                            peekReveal: (peekWindow / (_peekVisualHeight * .72))
                                .clamp(.5, 1)
                                .toDouble(),
                            animationsEnabled: prefs.animationsEnabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tight hit region over the visible head/hand only.
                  Positioned(
                    left: isLeft ? region.left : null,
                    right: isLeft
                        ? null
                        : math.max(0.0, constraints.maxWidth - region.right),
                    top: y + 24,
                    width: _peekHitWidth,
                    height: _peekHitHeight,
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
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _greetThenRelax(provider),
                        onLongPress: () {
                          _greetingTimer?.cancel();
                          controller.dismissFloating();
                        },
                        onVerticalDragUpdate: (details) => setState(
                          () => _vertical =
                              (_vertical +
                                      details.delta.dy /
                                          math.max(
                                            1,
                                            region.height - _peekVisualHeight,
                                          ))
                                  .clamp(0, 1),
                        ),
                      ),
                    ),
                  ),
                ],
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
