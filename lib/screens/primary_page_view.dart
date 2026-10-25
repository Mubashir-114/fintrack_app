import 'package:flutter/material.dart';

/// Lazy primary destinations. Visited pages keep their controllers and data;
/// intermediate pages in a long dock animation do not start network work.
class PrimaryPageView extends StatefulWidget {
  const PrimaryPageView({
    super.key,
    required this.selectedIndex,
    required this.builders,
    required this.onPageChanged,
    this.active = true,
  });

  final int selectedIndex;
  final List<WidgetBuilder> builders;
  final ValueChanged<int> onPageChanged;
  final bool active;

  @override
  State<PrimaryPageView> createState() => _PrimaryPageViewState();
}

class _PrimaryPageViewState extends State<PrimaryPageView> {
  late final PageController _controller;
  late int _visibleIndex;
  int? _target;
  bool _dragging = false;
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _visibleIndex = widget.selectedIndex;
    _controller = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant PrimaryPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        (_target != null || widget.selectedIndex != _visibleIndex)) {
      _target = widget.selectedIndex;
      final generation = ++_animationGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || generation != _animationGeneration) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.jumpToPage(widget.selectedIndex);
        } else {
          await _controller.animateToPage(
            widget.selectedIndex,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
        if (mounted && generation == _animationGeneration) {
          setState(() => _target = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.depth != 0) return false;
      if (notification is ScrollStartNotification &&
          notification.dragDetails != null) {
        _animationGeneration++;
        setState(() {
          _target = null;
          _dragging = true;
        });
      } else if (notification is ScrollEndNotification && _dragging) {
        setState(() => _dragging = false);
        widget.onPageChanged(_visibleIndex);
      }
      return false;
    },
    child: PageView.builder(
      key: const ValueKey('primary_page_view'),
      controller: _controller,
      itemCount: widget.builders.length,
      onPageChanged: (index) {
        setState(() => _visibleIndex = index);
        // Dock animations may cross other pages. Only the requested destination
        // changes the route; user drags update it as soon as the page changes.
        if (_target == null) widget.onPageChanged(index);
      },
      itemBuilder: (context, index) => _RetainedDestination(
        key: ValueKey(index),
        initialize:
            _target == index ||
            (_target == null && (_dragging || _visibleIndex == index)),
        active: widget.active && _visibleIndex == index,
        builder: widget.builders[index],
      ),
    ),
  );
}

class _RetainedDestination extends StatefulWidget {
  const _RetainedDestination({
    super.key,
    required this.initialize,
    required this.active,
    required this.builder,
  });
  final bool initialize;
  final bool active;
  final WidgetBuilder builder;

  @override
  State<_RetainedDestination> createState() => _RetainedDestinationState();
}

class _RetainedDestinationState extends State<_RetainedDestination>
    with AutomaticKeepAliveClientMixin {
  Widget? _page;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.initialize) _page ??= widget.builder(context);
    return TickerMode(
      enabled: widget.active,
      child: _page ?? const SizedBox.expand(),
    );
  }
}
