# FinTrack premium UI upgrade

25 October 2026

## Baseline and sequence

Read the five requested installed Flutter skills before coding. The explicit
implementation request overrides the design-review skill's plan-only restriction.
Used the existing HORIZON tokens, typography, themes and controls.

Reviewed the approved local Stitch images for `auth_sign_in_experience`,
`profile_identity_command_deck` and `add_edit_transaction_experience` in the
sibling `stitch_fintrack_horizon_redesign` directory. Compared the saved Login
render in `build/screenshots/login_midnight_aurora.png` and the saved Android
Profile capture in `build/ui_modernization/emulator/final/13-profile.png`.
These historical captures are not evidence of a new emulator installation.

Completed Login's screenshot/refinement loop before changing Profile or the
transaction form.

## Changes visible in the renders

- Login: removed two background circles, the circular lock emblem and enclosing
  bordered card. The heading, supporting copy and flat fields now form a compact,
  left-aligned composition near the top. Registration is an inline action.
  Corrected placeholders that were previously hidden by field labels.
- Profile: replaced the tall centered identity stack and glow with an avatar/name
  row, readable email and membership text. Edit Profile and FIN Companion sit
  inside the account surface. Actions stack on narrow layouts or enlarged text.
  Removed enclosing borders from settings groups and constrained the page width.
- Add Transaction: removed the outlined amount card, competing category colors
  and redundant static FIN review message. A prominent amount and always-visible
  currency lead the form. Merchant precedes a compact category selector that
  expands to expose all categories and closes after selection. Account and date
  share a row when space permits. Save stays outside the scrolling fields.
- Added a reusable HORIZON pressable with keyboard activation, focus outline,
  selected semantics, reduced-motion support and tactile press feedback for the
  new interactions. Added an opt-in flat style to the existing text-field widget;
  other callers retain their current appearance.

All six collections retain both existing brightness modes. Authentication,
transaction submission, validation, account assignment, editing, dates, notes,
profile navigation and backend refresh paths retain their existing behavior.
Providers, repositories, models, routes, theme palettes and FIN were not changed.

## Visual verification

Open [the review gallery](../../../build/premium_ui/review.html) for 36 actual
Flutter renders: three screens, six collections and two brightness modes.
The capture test loads the bundled Space Grotesk, Plus Jakarta Sans and Material
Icons fonts. It uses synthetic profile/account fixtures, with no backend calls.

During inspection, corrected an expanding registration button, an undersized empty
amount and excessive space occupied by the full category grid.

The repeatable capture and layout harness is `test/premium_ui_capture_test.dart`.

## Checks

- 102 focused tests passed across the capture/layout harness, authentication
  screens/provider, profile/security, transaction categories and theme appearance.
- Layout checks cover 320, 600 and 1024 pixel widths and 740 × 360 landscape,
  normal/200% text and simulated keyboard insets. Actual modal-route tests verify
  Save remains above a 280 pixel keyboard and validation still displays errors.
- Flutter analysis: no issues.
- Git whitespace check: passed.
- Logs: `build/premium_ui/tests.log` and `build/premium_ui/analyze.log`.

## Remaining differences and limits

The Stitch references include unsupported or unrelated actions such as password
recovery, transfers, export and invented live audit claims. This change does not
add those actions or claims. The layout follows the reference hierarchy while
using actual FinTrack fields and six-theme tokens.

Current Android system insets, native keyboard behavior, photo avatars and FIN
overlay overlap were not visually rechecked on an installed build. The captures
are isolated widget renders, not current emulator screenshots. No emulator was
launched, APK rebuilt, application installed, changes staged, committed or pushed.
