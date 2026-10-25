import 'package:flutter/material.dart';

/// FinTrack HORIZON — Animated Thin Hairline Progress Bar.
///
/// Smoothly sweeps from 0% to current utilization ratio without layout thrashing.
class AnimatedBudgetProgress extends StatefulWidget {
  const AnimatedBudgetProgress({
    super.key,
    required this.progressRatio,
    required this.color,
    required this.trackColor,
    this.height = 4.0,
    this.duration = const Duration(milliseconds: 450),
  });

  final double progressRatio;
  final Color color;
  final Color trackColor;
  final double height;
  final Duration duration;

  @override
  State<AnimatedBudgetProgress> createState() => _AnimatedBudgetProgressState();
}

class _AnimatedBudgetProgressState extends State<AnimatedBudgetProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedBudgetProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressRatio != widget.progressRatio) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final clampedTarget = widget.progressRatio.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            width: totalWidth,
            color: widget.trackColor,
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final ratio = reduceMotion
                    ? clampedTarget
                    : _animation.value * clampedTarget;
                return Container(
                  height: widget.height,
                  width: totalWidth * ratio,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
