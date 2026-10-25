# Dashboard, Money Storage and Transactions — batch closure

25 October 2026

## Files changed during closure

These changes continue the existing working tree. Earlier batch changes and
unrelated Budgets work were retained. Files below are relative to `frontend/`.

| File | Closure change |
| --- | --- |
| `lib/core/horizon/components/horizon_component_previews.dart` | Preview import, row constraints and interactive period selection |
| `lib/core/horizon/components/horizon_count_up_text.dart` | Dart formatting only |
| `lib/core/horizon/components/horizon_metric_strip.dart` | Stack financial metrics at enlarged text sizes |
| `lib/core/horizon/components/horizon_range_switcher.dart` | Wrap period labels at enlarged text sizes |
| `lib/core/horizon/components/horizon_transaction_row.dart` | Reflow narrow/enlarged rows so titles and figures remain readable |
| `lib/screens/dashboard/dashboard_screen.dart` | Reactive pending-alert badge and enlarged chart-axis spacing |
| `lib/screens/dashboard/widgets/dashboard_account_row.dart` | Reflow narrow/enlarged account balances |
| `lib/screens/dashboard/widgets/dashboard_metric_strip.dart` | Dart formatting only |
| `lib/screens/dashboard/widgets/dashboard_recent_row.dart` | Reflow narrow/enlarged recent transactions |
| `lib/screens/money_storage/widgets/liquidity_summary.dart` | Remove duplicate currency symbol |
| `lib/screens/money_storage/widgets/storage_action_row.dart` | Preserve action labels on narrow/enlarged layouts |
| `lib/screens/money_storage/widgets/storage_node_row.dart` | Stack identity and balance when horizontal space is insufficient |
| `lib/screens/money_storage/widgets/storage_previews.dart` | Supply required theme import and account fixture field |
| `lib/screens/transactions/transactions_list_screen.dart` | Reserve the Add area, cancel pending searches on reset, guard deferred initialization |
| `lib/screens/transfers/transfer_screen.dart` | Constrain account dropdowns with long names |
| `test/modernization_closure_test.dart` | Final shell captures, reusable preview checks and interaction regressions |
| `docs/improvements/design/modernization-closure.md` | Closure manifest and verification record |

The formatter was limited to 58 Dart files already changed in the relevant batch
areas. Its exact input list and logs are in
`build/modernization_final/format-files.txt` and `format*.log`.

## Rendered verification

[Open the final gallery](../../../build/modernization_final/review.html).

49 Flutter PNG captures use the bundled Space Grotesk, Plus Jakarta Sans,
Material Icons and SDK Roboto fonts. They render the actual
`MainNavigationScreen`, including the navigation dock/rail and FIN. Money Storage
intentionally follows the existing FIN route policy and does not show an edge
companion. Providers use deterministic test fixtures; no backend requests occur.

Each of Dashboard, Money Storage and Transactions has top, middle and bottom
captures at:

- 320 × 640, dark
- 393 × 852, dark
- 393 × 852, light
- 600 × 960, dark/tablet
- 320 × 640, dark, 200% text

Four additional captures verify Updates, cash-flow trend, transaction menu and
Add Transaction at 320dp and 200% text. The PNGs and the four `review_*.jpg`
contact sheets were inspected. The final chart labels remain on one line, and
the transaction list viewport ends above Add throughout scrolling. Financial
amounts reflow without clipping. Horizontal filter rails remain scrollable.
The real popup observer suppresses FIN while sheets and menus are open.

## Previews and interactions

All 14 requested reusable components have useful previews; 17 configurations
were exercised at their declared sizes. The range switcher preview supports
actual selection. Existing preview files were reused.

Verified Updates open/close; pending badge changes independently of FIN
insights; real Profile entry/back; current, previous and custom months;
cash-flow open/close; real account detail/back; all storage filters; Add Account
and Transfer forms; reconciliation refresh calls; default-account mutation;
transaction search and reset; income/expense, category and date filtering;
row Edit and confirmed Delete; Add Transaction and dismissal/back.

Account/transfer provider regressions cover repository delegation. UI checks
invoke actual widgets and callbacks with fixture providers; they do not prove
live backend persistence.

## Final quality gate

- One comprehensive relevant regression invocation: **190 passed, 0 failed**
  across 16 test files. Log: `build/modernization_final/regression.log`.
- After final visual inspection found the Add and chart-axis issues, their
  focused six-test check passed, followed by **70 affected tests passed**.
  Other passed suites were not repeated. Log:
  `build/modernization_final/affected-regression.log`.
- Current batch analysis: **no issues**. Log:
  `build/modernization_final/analyze-scoped.log`.
- Full `flutter analyze`: **11 unrelated Budgets diagnostics** (3 warnings,
  8 import infos), exit 1. These files were left untouched by this closure.
  Log: `build/modernization_final/analyze.log`.
- `git diff --check`: passed. Log:
  `build/modernization_final/diff-check.log`.

No native device/emulator, live backend, native keyboard or system-inset capture
was performed. No emulator was launched and no APK was built. Nothing was staged,
committed or pushed. Budgets implementation and unrelated working-tree changes
were not edited by this closure.
