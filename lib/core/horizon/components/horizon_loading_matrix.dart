import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';

/// Shimmer and skeleton loader components for FinTrack // HORIZON.
/// Conforms to Section A of the Systemwide Loading & FIN Character Matrix.
class HorizonSkeleton extends StatefulWidget {
  const HorizonSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<HorizonSkeleton> createState() => _HorizonSkeletonState();
}

class _HorizonSkeletonState extends State<HorizonSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final radius = widget.borderRadius ?? HorizonDimensions.borderSM;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.surface2.withValues(alpha: _animation.value),
            borderRadius: radius,
            border: Border.all(
              color: tokens.rimNeutral.withValues(
                alpha: _animation.value * 0.5,
              ),
              width: 1,
            ),
          ),
        );
      },
    );
  }
}

/// Pre-composed skeleton card for telemetry balance pods.
class HorizonSkeletonTelemetryCard extends StatelessWidget {
  const HorizonSkeletonTelemetryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(HorizonDimensions.marginMobile),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: HorizonDimensions.borderLG,
        border: Border.all(color: tokens.rimNeutral),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HorizonSkeleton(width: 80, height: 12),
          SizedBox(height: 12),
          HorizonSkeleton(width: 160, height: 28),
          SizedBox(height: 12),
          HorizonSkeleton(width: 110, height: 14),
        ],
      ),
    );
  }
}

/// Full loading indicator scene with telemetry status message.
class HorizonLoadingScene extends StatelessWidget {
  const HorizonLoadingScene({
    super.key,
    this.statusMessage = "SYNCING TELEMETRY STREAM...",
  });

  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.ionCyan),
            ),
          ),
          const SizedBox(height: HorizonDimensions.spaceLG),
          Text(
            statusMessage.toUpperCase(),
            style: HorizonTypography.labelCaps.copyWith(
              color: tokens.ionCyan,
              fontSize: 11,
              letterSpacing: 0.08 * 11,
            ),
          ),
        ],
      ),
    );
  }
}
