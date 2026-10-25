import 'package:flutter/material.dart';
import '../tokens/horizon_dimensions.dart';
import '../tokens/horizon_typography.dart';
import '../theme/horizon_theme_tokens.dart';
import 'horizon_button.dart';
import 'horizon_surface.dart';

/// Systemwide empty state component for FinTrack // HORIZON.
/// Designed according to the Empty & Error UX Matrix specification.
class HorizonEmptyState extends StatelessWidget {
  const HorizonEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.auto_graph_rounded,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);
    final accent = accentColor ?? tokens.ionCyan;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HorizonDimensions.marginDesktop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Technical Telemetry Pod Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: HorizonDimensions.borderLG,
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(height: HorizonDimensions.spaceLG),

            // Headline
            Text(
              title,
              textAlign: TextAlign.center,
              style: HorizonTypography.headlineSm.copyWith(
                color: tokens.textHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HorizonDimensions.spaceSM),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: HorizonTypography.bodyMd.copyWith(
                color: tokens.textMedium,
                height: 1.45,
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HorizonDimensions.spaceLG),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: HorizonButton(
                  text: actionLabel!,
                  onPressed: onAction,
                  variant: HorizonButtonVariant.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Offline telemetry warning banner for FinTrack // HORIZON.
class HorizonOfflineBanner extends StatelessWidget {
  const HorizonOfflineBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: tokens.outflow.withValues(alpha: 0.92)),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "OFFLINE MODE // Displaying cached telemetry data. Modifications will sync when connection returns.",
              style: HorizonTypography.labelCaps.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05 * 10,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                "RETRY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state surface with telemetry error diagnostics.
class HorizonErrorCard extends StatelessWidget {
  const HorizonErrorCard({
    super.key,
    required this.title,
    required this.errorMessage,
    this.onRetry,
  });

  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return HorizonSurface(
      tier: HorizonSurfaceTier.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: tokens.outflow,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.outflow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: HorizonTypography.bodyMd.copyWith(color: tokens.textHigh),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: HorizonButton(
                text: "RETRY",
                onPressed: onRetry,
                variant: HorizonButtonVariant.secondary,
                height: 38,
                expandWidth: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
