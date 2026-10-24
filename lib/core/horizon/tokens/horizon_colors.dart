import 'package:flutter/material.dart';

/// Canonical color tokens for FinTrack // HORIZON.
///
/// ### Resolution of Conflicting Stitch Token Values:
/// The exported Stitch redesign contains two conflicting color specifications:
/// 1. The Tailwind config in HTML headers/YAML frontmatter has auto-generated
///    Material-3 tokens (e.g. `surface: #0e131e`, `primary: #b8f5ff`,
///    `secondary: #bcc2ff`, `tertiary: #ffe7c6`, `error: #ffb4ab`).
/// 2. Section 2 ("Palette Architecture") and Section 5 ("Elevation & Depth") of
///    `DESIGN.md` define the curated, intentional FinTrack HORIZON identity:
///    - Base Canvas Void: `#080D17`
///    - Surface Level 1: `#0E1626`
///    - Surface Level 2: `#172338`
///    - Surface Level 3: `#1F2F4A`
///    - Ion Cyan Primary: `#75DEED`
///    - Electric Indigo: `#8996FC`
///    - Luminous Gold: `#E5B76A`
///    - Semantic Surplus: `#34D399`
///    - Semantic Outflow: `#F87171`
///
/// **Resolution**: Section 2 represents the intentional cockpit instrumentation
/// design language. We adopt Section 2 as the canonical source of truth for
/// production tokens, providing crisp contrast ratios, deep architectural voids,
/// and laser-sharp luminescence.
class HorizonColors {
  HorizonColors._();

  // ---------------------------------------------------------------------------
  // Canonical Dark Void Palette (Primary HORIZON Identity)
  // ---------------------------------------------------------------------------

  /// Level 0 Canvas Void: The primary deep space background.
  static const Color voidCanvas = Color(0xFF080D17);

  /// Surface Level 1: Base container cards, recessed lists, grouped view panels.
  static const Color surface1 = Color(0xFF0E1626);

  /// Surface Level 2: Elevated sheets, dynamic interactive cards, modals.
  static const Color surface2 = Color(0xFF172338);

  /// Surface Level 3: Telemetry dock, active inputs, pressed states, pinned headers.
  static const Color surface3 = Color(0xFF1F2F4A);

  /// Surface Level 4: Highest elevation touch targets and active pills.
  static const Color surface4 = Color(0xFF253858);

  /// Ion Cyan: Primary system driver; represents capital flow, active telemetry,
  /// primary actions, and key liquidity metrics.
  static const Color ionCyan = Color(0xFF75DEED);

  /// Ion Cyan Pressed / Focused: Dimmed state for tactile feedback.
  static const Color ionCyanDim = Color(0xFF6CD6E4);

  /// Electric Indigo: Secondary driver; designates long-term investments,
  /// structural buckets, and predictive financial vectors.
  static const Color electricIndigo = Color(0xFF8996FC);

  /// Luminous Warm Gold: Companion reserve; signifies wealth milestones,
  /// yield dividends, and verified liquid reserves.
  static const Color luminousGold = Color(0xFFE5B76A);

  /// Semantic Surplus: Inflow, balance gains, positive delta.
  static const Color surplus = Color(0xFF34D399);

  /// Semantic Outflow: Incurred expense, drawdown, debit allocations.
  static const Color outflow = Color(0xFFF87171);

  /// Semantic Warning / Caution: Alert threshold or pending item.
  static const Color warning = Color(0xFFFBBF24);

  /// Semantic Neutral / Info: Informational badge or telemetry node.
  static const Color info = Color(0xFF60A5FA);

  // High-density Typography & Border Tiers (Dark Mode)
  static const Color textHigh = Color(0xFFF5F8FC);
  static const Color textMedium = Color(0xFF8E9BAE);
  static const Color textLow = Color(0xFF5A6B82);

  /// Directional hairline precision rim (`rgba(117, 222, 237, 0.12)`).
  static const Color rimCyan = Color(0x1F75DEED);

  /// High-emphasis rim for active modules (`rgba(117, 222, 237, 0.20)`).
  static const Color rimCyanActive = Color(0x3375DEED);

  /// Telemetry dock hairline rim (`rgba(117, 222, 237, 0.18)`).
  static const Color rimDock = Color(0x2E75DEED);

  /// Structural neutral hairline rim (`rgba(142, 155, 174, 0.10)`).
  static const Color rimNeutral = Color(0x1A8E9BAE);

  /// Inner top rim highlight (`rgba(245, 248, 252, 0.08)`).
  static const Color rimTopHighlight = Color(0x14F5F8FC);

  /// Sub-divider line (`rgba(117, 222, 237, 0.06)`).
  static const Color rowDivider = Color(0x0F75DEED);

  // ---------------------------------------------------------------------------
  // Canonical Light Horizon Palette (Daylight Institutional Telemetry)
  // ---------------------------------------------------------------------------

  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSurface1 = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF1F5F9);
  static const Color lightSurface3 = Color(0xFFE2E8F0);
  static const Color lightSurface4 = Color(0xFFCBD5E1);

  static const Color lightIonCyan = Color(0xFF006874);
  static const Color lightElectricIndigo = Color(0xFF313EA0);
  static const Color lightLuminousGold = Color(0xFF8A6100);

  static const Color lightSurplus = Color(0xFF047857);
  static const Color lightOutflow = Color(0xFFB91C1C);
  static const Color lightWarning = Color(0xFF92400E);
  static const Color lightInfo = Color(0xFF2563EB);

  static const Color lightTextHigh = Color(0xFF0F172A);
  static const Color lightTextMedium = Color(0xFF475569);
  static const Color lightTextLow = Color(0xFF94A3B8);
  static const Color lightRimNeutral = Color(0x1E0F172A);
  static const Color lightRimCyan = Color(0x28006874);
  static const Color lightRowDivider = Color(0x120F172A);

  // ---------------------------------------------------------------------------
  // Cinematic Gradients
  // ---------------------------------------------------------------------------

  /// Top-down linear card gradient falling from Surface 2 to Surface 1.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface2, Color(0xFF0F1726)],
  );

  /// Primary Ion Charge gradient.
  static const LinearGradient ionChargeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF93F1FF), ionCyan, Color(0xFF4AC7D8)],
  );

  /// Electric Indigo trajectory gradient.
  static const LinearGradient indigoTrajectoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAEB8FF), electricIndigo, Color(0xFF5E6EE0)],
  );

  /// Radial accent light for investment summary cards (top-right anchor).
  static RadialGradient cornerAccentLight(Color accent) => RadialGradient(
        center: Alignment.topRight,
        radius: 0.9,
        colors: [
          accent.withValues(alpha: 0.08),
          accent.withValues(alpha: 0.0),
        ],
      );
}
