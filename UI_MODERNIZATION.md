# FinTrack premium UI refinement

## Prerequisite — 18 October 2026

The current Floating FIN checkpoint (`c0466fc`) was built with the existing WSL
toolchain and installed with `adb install -r` on emulator-5554. Existing app data
was preserved. The authenticated dashboard, visible portrait, open action panel,
and minimized portrait were inspected using Android screen captures. FIN-specific
regression tests passed. The screen matrix reproduced the checkpoint's known
29-pixel Reports overflow at 320 pixels in both themes; wider layouts passed.

## Initial component classification

| Area | Decision | Planned work |
| --- | --- | --- |
| FIN rig, bounded overlay, shell navigation | Keep as-is | Preserve anatomy, footprint, lifecycle, actions, and full-width page constraints. |
| Theme collections and semantic colors | Refine | Retain saved appearance and dark palettes; strengthen light-theme financial text contrast. |
| Shared summary/metric cards | Refine | Consistent surfaces, quieter elevation, compact spacing, reusable icon and card treatments. |
| Dashboard | Refine | Shared cards, readable amounts, baseline and labels for financial charts, loading transition. |
| Accounts and credit cards | Refine | Theme-aware cards, compact balance presentation, accessible utilization. |
| Transactions and filters | Refine | Preserve recent layout improvements; use consistent control and loading treatments. |
| Budgets and savings | Refine | Shared surfaces/progress, wrapping headers, reduced motion. |
| Reports and insights | Refine | Fix compact header overflow, truthful zero-data presentation, chart semantics and reduced motion. |
| Settings, forms and dialogs | Refine | Shared surface and icon treatments; maintain validation and existing actions. |
| Empty states | Refine | Static native illustration, readable explanation and accessible action. |
| Startup loading | Redesign | Native wallet/rupee/data-path/growth illustration, real connection status, retry, no artificial delay. |
| Localized skeletons | Refine | Pause hidden animations; neutral placeholders without implied financial values. |

## Boundaries

Financial calculations, repositories, backend contracts, cache freshness/privacy,
and FIN behavior remain outside the implementation scope. No dependency additions,
staging, commits, or pushes are planned. Verification artifacts are kept under
`build/ui_modernization/` (ignored build output).

## Implemented changes

- Added shared `FinSurface`, `FinIconTile`, and `FinReveal` widgets. Dashboard,
  account, budget and settings components reuse these surfaces. Removed the
  summary-card glow painting/controller and softened card elevation.
- Account names and amounts adapt to compact widths and large text. Financial
  amounts still use the existing decimal-string formatter.
- Financial charts retain the actual repository data. Income/expense graphs use
  a zero baseline, labeled monetary axes, straight segments without spline
  overshoot, and complete accessible data descriptions. Category charts and
  report transitions respect reduced motion.
- Reports headers wrap at compact widths. Secondary metrics show savings rate
  and activity instead of repeating income/expense totals. Zero-data flow bars
  have no invented 50/50 distribution or minimum nonzero share. Zero and balanced
  periods no longer claim an expenditure deficit. Single-month comparisons keep
  full amounts above proportional tracks rather than squeezing them into a
  fixed-width column.
- Light-theme financial ink keeps the same color families and meets at least
  4.5:1 contrast against surface and elevated backgrounds for primary, success,
  danger and warning labels in all three collections.
- Added the native wallet, rupee coin, data-path and growth-leaf startup scene.
  It uses controller-driven `CustomPainter` repainting inside a `RepaintBoundary`;
  layout does not rebuild on animation frames. The rupee is drawn as a vector
  path and has no font fallback dependency.
- Startup begins verification immediately and navigates immediately when ready.
  Removed the previous 150 ms and one-second artificial waits. Connection text
  describes actual waiting without claiming a confirmed cold start or showing
  percentages. Errors keep a retry action; session expiration follows the
  existing token invalidation behavior. No cache rules were changed.
- Loading supports reduced motion, hidden routes, compact landscape, large text,
  and fold-hinge avoidance. A brief dashboard fade replaces an abrupt entrance.
- Skeletons pause when hidden; chart placeholders are neutral blocks. Native
  form buttons provide keyboard focus and feedback. Transaction type filters
  expose selected state to accessibility services.

## Visual review artifacts

Open [the before/after gallery](build/ui_modernization/review.html). It includes
dashboard, accounts, transactions, budgets, Reports, settings and FIN companion
screens in both themes, plus four sampled frames of the loading animation.

The native Flutter comparison previews use explicitly isolated synthetic test
fixtures, not production financial results. Authenticated Android captures use
the emulator's existing authorized records and are kept separately in
`build/ui_modernization/emulator/`. The former startup was captured on Android.
Some baseline control labels use the test font fallback; actual Android captures
show production typography.

## Verification scope

The real-screen matrix covers ten screens at 320, 360, 393, 600 and 1024 logical
pixels, in both themes. It compares page bounds with FIN visible, disabled, and
on either edge and exercises scrolling/navigation. Loading also has large-text,
landscape, reduced-motion, hidden-route and fold-hinge checks. Dedicated
regressions cover the INR axis unit and full single-month monetary labels at
320 pixels. Existing tests continue to cover credit cards, transactions,
budgets, provider isolation and FIN interactions.

Physical-device frame timing and manufacturer-specific fold behavior were not
measured. FIN retains its existing bounded visual overlap and user controls;
the companion and shell implementations were not changed.

## Final verification — 18 October 2026

| Check | Result |
| --- | --- |
| Flutter analysis | Passed, no issues. |
| Comprehensive Flutter suite | 277 tests passed; the sole health-check failure was HTTP 429 from the running local backend. |
| Real backend health retry | Passed after honoring its 299-second `Retry-After` window. All 278 tests verified across the full run and targeted retry. |
| Screen matrix | Passed: ten screens, five widths, two themes, with unchanged page bounds for FIN visibility and edge changes. |
| Native Android debug APK | Built successfully with the existing WSL SDK/signing key; production Dart source compared equal to the workspace. |
| Android installation | Updated emulator-5554 using `install -r`; existing app data preserved. |
| Protected source review | Providers, repositories, models, FIN rig/overlay and navigation shell have no source changes. |
| Git whitespace/staging | Whitespace check passed; no changes staged, committed, or pushed. |

Windows checks used Flutter 3.44.6 / Dart 3.12.2. Android compilation used the
existing WSL toolchain. The local backend rate limit was not changed or bypassed.

Verification logs: `analyze-final.log`, `test-final.log`, `health-retry.log`, and
`build-final.log`, all inside `build/ui_modernization/`. The rate-limited suite
log is retained; its health-check failure is not hidden or replaced by a mock.
