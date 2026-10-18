# Floating FIN layout regression fix

Completed 18 October 2026. No emulator installation or financial data changes were performed.

**Confirmed root cause**

The previous floating FIN redesign added a `ListenableBuilder` and conditional `Padding` around `mainLayout` in `MainNavigationScreen`. While FIN was visible, that padding reserved **44 logical pixels plus the chosen edge's system inset**. This reduced the actual constraints passed to every affected browsing page. The bottom navigation was outside this wrapper, explaining why it remained full-width.

Git diff identified this as an unstaged redesign change. The shell at HEAD (`5f631ac`) and the earlier FIN integration history (`f5dfd78`) did not reserve this gutter.

A widget reproducer measured the same page with FIN enabled and temporarily disabled through its real preference:

| 393-pixel viewport | Before fix | After fix |
| --- | ---: | ---: |
| FIN enabled | 349 px | 393 px |
| FIN disabled | 393 px | 393 px |

This confirmed the cause before changing the implementation. The original reproducer output remains in `fin-layout-before.log` (ignored diagnostic output).

**Architecture correction**

- Removed the FIN-dependent padding wrapper and the shell's associated width-allocation logic.
- Made the root body Stack expand to the available viewport. Page content and FIN are separate `Positioned.fill` siblings.
- Stretched the content Column across its available width. The existing offline banner and page remain in that content layer.
- Kept FIN's own Stack explicitly constrained to the overlay viewport. Its 44-pixel peek target is named `peekWidth` and allocates no page space.
- Retained safe-area positioning, keyboard and dialog suppression, repositioning, animation, mini-panel actions, dismissal, and conversation continuity.
- Retained the original tablet NavigationRail. On tablets, pages fill the space remaining after that existing navigation rail; FIN takes none of it.

No production MediaQuery dimensions are changed to accommodate FIN. There is no full-screen gesture blocker; only the peek handle or mini panel intercepts interaction. Taps outside the panel both dismiss it and reach the underlying control.

**Additional compact-screen findings**

Real-font checks found two small pre-existing overflows at 320 pixels. Both reproduced on standalone screens with no application shell or FIN:

- Budget month selector: 7.6-pixel overflow from its calendar/month/current-month badge Row. It now wraps within the same tappable month control.
- Reports chart header: 29-pixel overflow from its title and legend Row. The header now wraps the existing legend when space is insufficient.

These changes preserve the text, values, callbacks, financial calculations, chart behavior, and wide-screen arrangement. Dashboard implementation and design were not modified. Baseline diagnostic logs are preserved under `build/fin_layout_verification/`.

**Files changed for this fix**

| File | Purpose |
| --- | --- |
| `lib/screens/main_navigation_screen.dart` | Remove reserved FIN width; separate full-size content and overlay layers. |
| `lib/screens/analytics/widgets/global_fin_overlay.dart` | Explicit overlay constraints; rename peek hit-target width. |
| `lib/screens/budgets/widgets/budget_month_selector.dart` | Allow compact month/badge wrapping. |
| `lib/screens/reports/widgets/trends_tab_view.dart` | Allow compact chart-title/legend wrapping. |
| `test/fin_living_redesign_test.dart` | Replace the obsolete gutter assertion with full-width invariance. |
| `test/floating_fin_layout_regression_test.dart` | Enabled/disabled reproducer; mini-panel, outside-touch, safe-inset, edge-switch, and keyboard checks. |
| `test/floating_fin_screen_matrix_test.dart` | Real-screen width/theme matrix, MediaQuery checks, scrolling and navigation checks. |
| `FIN_REDESIGN.md` | Correct the superseded gutter documentation. |
| `FIN_LAYOUT_FIX.md` | Root-cause and verification report. |

Other unstaged files from the earlier redesign were preserved.

**Screens verified**

Dashboard; Activity/Transactions; Accounts & Wallets; Budgets; Reports; FIN Companion; Profile; Appearance settings; Security settings; Edit Profile.

Each was rendered in the real MainNavigationScreen at **320, 360, 393, 600, and 1024 logical pixels**, in **light and dark themes**: 100 screen/width/theme combinations. Each combination compares right-edge FIN, disabled FIN, and left-edge FIN. Tests assert unchanged page bounds, original viewport MediaQuery width, and containment of vertical scrolling regions. Additional checks exercise actual dashboard scrolling and bottom-navigation taps. Providers use isolated synthetic test fixtures; production financial records are not changed.

Forty native Flutter preview images cover the ten screens at 320 and 393 pixels in both themes. Representative previews were visually inspected for full-width content, margins, navigation, and clipping.

**Final verification**

| Check | Result |
| --- | --- |
| Flutter analyze | Passed, no issues. |
| Complete Flutter test suite | Passed, **264 tests**, including the local backend health check. |
| Screen matrix | Passed, 100 screen/width/theme combinations. |
| Android debug APK | Built successfully from the corrected production source in the isolated WSL verification copy. |
| Git diff whitespace check | Passed. |
| Dashboard source diff | Empty. |

Analysis/tests used Windows Flutter 3.44.6 / Dart 3.12.2. Android build used the existing WSL Flutter 3.47.7 / Dart 3.13.5 toolchain and existing signing configuration.

Artifacts:

- `build/fin_layout_verification/fintrack-layout-fix-debug.apk`
- `build/fin_layout_verification/analyze-final.log`
- `build/fin_layout_verification/test-final.log`
- `build/fin_layout_verification/build-final.log`
- `build/fin_layout_verification/previews/`

**Remaining limitations**

No remaining width regression or RenderFlex overflow was found in the tested matrix. FIN remains an overlay and can visually overlap content within its bounded footprint; repositioning, minimizing, and dismissal remain available. Physical-device and manufacturer-specific fold behavior were not manually re-tested. The screen matrix uses normal text scale; the existing FIN tests continue to cover reduced motion, keyboard behavior, and fold-safe companion positioning.
