import 'package:flutter/material.dart';
import '../../../../core/horizon/horizon.dart';

/// Reusable contextual speech bubble & insight presenter for FIN companion.
class FinSpeechPanel extends StatelessWidget {
  final String quote;
  final int quoteIndex;
  final int totalQuotes;
  final VoidCallback? onTap;

  const FinSpeechPanel({
    super.key,
    required this.quote,
    required this.quoteIndex,
    required this.totalQuotes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Semantics(
      button: onTap != null,
      label: 'FIN insight quote: $quote. Tap to cycle insights.',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.rimNeutral),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“',
                    style: TextStyle(
                      color: tokens.ionCyan.withValues(alpha: 0.65),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quote,
                      textAlign: TextAlign.center,
                      style: HorizonTypography.bodyMd.copyWith(
                        color: tokens.textHigh,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '”',
                    style: TextStyle(
                      color: tokens.ionCyan.withValues(alpha: 0.65),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quote dots and tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < totalQuotes; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == quoteIndex ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == quoteIndex
                            ? tokens.ionCyan
                            : tokens.textMedium.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to cycle',
                    style: HorizonTypography.labelCaps.copyWith(
                      color: tokens.textMedium,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
