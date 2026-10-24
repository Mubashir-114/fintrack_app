import 'package:flutter/material.dart';

/// Spacing, corner radius, safe area, and breakpoint tokens for FinTrack // HORIZON.
class HorizonDimensions {
  HorizonDimensions._();

  // ---------------------------------------------------------------------------
  // Spacing Grid
  // ---------------------------------------------------------------------------
  static const double spaceXS = 4; // 0.25rem
  static const double spaceSM = 8; // 0.5rem
  static const double spaceMD = 12; // 0.75rem
  static const double spaceLG = 20; // 1.25rem
  static const double spaceXL = 32; // 2.0rem

  static const double marginMobile = 16;
  static const double marginTablet = 24;
  static const double marginDesktop = 32;

  static const double gutterMobile = 12;
  static const double gutterTablet = 16;

  // ---------------------------------------------------------------------------
  // Safe Area & Navigation Clearance Anchors
  // ---------------------------------------------------------------------------
  /// Minimum top safe area clearance for telemetry headers.
  static const double minTopSafePadding = 44;

  /// Strict floating dock clearance from the home indicator / viewport bottom.
  static const double bottomDockClearance = 24;

  /// Standard height of the primary HORIZON action button.
  static const double buttonHeight = 48;

  /// Standard height of the HORIZON cockpit input field.
  static const double inputHeight = 52;

  /// Standard height of the HORIZON floating bottom navigation dock.
  static const double dockHeight = 64;

  /// Total bottom clearance above viewport floor for floating navigation dock (height + padding).
  static const double dockClearance = 88;

  // ---------------------------------------------------------------------------
  // Corner Radii
  // ---------------------------------------------------------------------------
  static const double radiusSM = 4; // 0.25rem (system alerts, micro chips)
  static const double radiusDefault = 8; // 0.5rem (primary form controls, metric chips)
  static const double radiusMD = 12; // 0.75rem
  static const double radiusLG = 16; // 1.0rem (balance overview cards, ledger groups)
  static const double radiusXL = 24; // 1.5rem (primary modal sheets, persistent hero shields)
  static const double radiusFull = 9999; // full pill (binary state toggles, filter pills, dock)

  static final BorderRadius borderSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderDefault = BorderRadius.circular(radiusDefault);
  static final BorderRadius borderMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderFull = BorderRadius.circular(radiusFull);

  // ---------------------------------------------------------------------------
  // Responsive Breakpoints
  // ---------------------------------------------------------------------------
  static const double breakpointTablet = 600;
  static const double breakpointDesktop = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointTablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= breakpointTablet && width < breakpointDesktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointDesktop;

  /// Returns 4 for mobile, 8 for tablet, and 12 for desktop.
  static int columnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpointTablet) return 4;
    if (width < breakpointDesktop) return 8;
    return 12;
  }
}
