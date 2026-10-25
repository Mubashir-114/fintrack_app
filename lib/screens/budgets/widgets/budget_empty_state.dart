import 'package:flutter/material.dart';

import '../../../core/horizon/horizon.dart';
import '../../../core/horizon/components/horizon_pressable.dart';
import '../../../models/companion_model.dart';
import '../../analytics/widgets/fin_character.dart';

/// FinTrack HORIZON — Modern Premium Budget Empty State.
///
/// Features friendly FIN presence, clear onboarding direction,
/// and high-contrast primary CTA without duplicate floating buttons.
class BudgetEmptyState extends StatelessWidget {
  const BudgetEmptyState({
    super.key,
    required this.selectedMonthName,
    required this.selectedYear,
    required this.onCreateBudget,
    required this.onExploreSuggestions,
  });

  final String selectedMonthName;
  final int selectedYear;
  final VoidCallback onCreateBudget;
  final VoidCallback onExploreSuggestions;

  @override
  Widget build(BuildContext context) {
    final tokens = HorizonThemeTokens.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tasteful FIN Presence with gentle halo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tokens.surface2,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.ionCyan.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokens.ionCyan.withValues(alpha: 0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const FinCharacter(
                size: 56,
                state: FinCharacterState.emptyData,
              ),
            ),
            const SizedBox(height: 20),

            // Headline matching test contracts and new design
            Text(
              "Shape Your Living Budget",
              textAlign: TextAlign.center,
              style: HorizonTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                color: tokens.textHigh,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "No budgets yet",
              style: HorizonTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: tokens.ionCyan,
              ),
            ),
            const SizedBox(height: 8),

            // Body
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                "Create a monthly or category budget to keep your spending plan visible for $selectedMonthName $selectedYear.",
                textAlign: TextAlign.center,
                style: HorizonTypography.bodyMd.copyWith(
                  fontSize: 13,
                  color: tokens.textMedium,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Primary CTA: Create Budget
            ElevatedButton.icon(
              onPressed: onCreateBudget,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Create Budget"),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.ionCyan,
                foregroundColor: tokens.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HorizonDimensions.radiusMD),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Action: Explore Suggestions
            HorizonPressable(
              label: "Explore suggestions",
              onPressed: onExploreSuggestions,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "Explore Suggestions",
                  style: HorizonTypography.labelCaps.copyWith(
                    color: tokens.ionCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
