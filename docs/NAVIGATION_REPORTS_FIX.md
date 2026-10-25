# FinTrack navigation and Reports correction

Completed 25 October 2026. No emulator was launched; no commit or push was made.

## Findings and data paths

The currency mismatch came from separate display paths, rather than mock Reports data. Dashboard's Horizon amount widgets and `MoneyText` used INR, while Reports already called `CurrencyProvider.format`, whose unsaved default was USD. Dashboard also hard-coded INR in its badge, recent rows and chart labels. A saved display preference could therefore disagree with Dashboard.

Both screens now use `core/utils/money_formatter.dart`. It contains the existing Dashboard/account exact-decimal grouping implementation. `MoneyText`, Horizon amounts and `CurrencyProvider` delegate to it; Dashboard's badge and chart labels observe the same preference as Reports. The default is INR and saved USD/EUR/GBP/INR preferences remain supported. Account rows with an explicit account currency continue displaying that account's currency. Reports chart axes also use the centralized compact formatter. PDF export requires the selected symbol explicitly instead of having a USD fallback.

Dashboard's authoritative path is `DashboardScreen → DashboardProvider → DashboardRepository → GET /dashboard → dashboardController → dashboardModel.getDashboardAnalytics → config/db.js`. Period income/spending comes from this user's `transactions`. Account balances and net worth additionally use account openings, transactions, transfers and adjustments through `getDashboardAccountsData`; transfers and adjustments are not cash-flow income or expenses.

Reports independently uses `ReportsScreen → ReportProvider → ReportRepository → /reports/{summary,monthly,category,trends,cashflow} → reportController → reportModel → config/db.js`. It does not read Dashboard widget/provider state. Dashboard period rows and Reports SQL totals now share `backend/utils/cashFlow.js`, which aggregates exact integer minor units and derives net income minus expenses. API response shapes remain compatible.

Dashboard defaults to Current Month; Reports defaults to All Time. Both choices remain intact. Reports forwards one date scope to all five endpoints. A separate end-date defect was fixed: timestamp comparisons against an end-date string could omit transactions after midnight on the final date. Reports now compares inclusive calendar dates, matching Dashboard. Cashflow and exports retain uncategorized transactions through left joins.

## Navigation

Before: five routed screens replaced each other through `context.go`, recreating page state on tab changes.

After: the existing shell hosts one lazy `PrimaryPageView`/`PageController` in Home, Ledger, Budgets, Reports, Profile order. Dock taps animate for 280 ms with `easeOutCubic`; user drags use normal Flutter page physics. Reduced motion jumps immediately. `onPageChanged` synchronizes the route and dock without pushing a route per swipe. Long dock transitions do not initialize skipped destinations. Visited child widgets are retained with `AutomaticKeepAliveClientMixin`, and inactive page tickers are disabled. Repeated visits preserve controllers, scroll offsets, loaded data and Reports' selected subtab and date range.

The existing router remains responsible for deeper screens. The pager stays mounted offstage while a deep screen is visible. The shell observes the actual top route, including imperative pushes. Android back returns secondary primary destinations to Home; deeper routes keep normal pop behavior. The glass dock, tablet rail and FIN overlay remain single shell instances. FIN's content-bound measurement ignores offstage route content.

Gesture compromise: Trends, Categories and Cashflow remain available by tapping their existing TabBar. Their TabBarView does not consume horizontal page swipes, allowing the outer main pager to receive them. Charts keep their own normal touch arbitration, so a drag beginning on an interactive chart can belong to the chart. Vertical scrolling and FIN's separate overlay hit targets remain intact. No global gesture detector was added.

Categories headers and summary rows retain full-width alignment and wrap when necessary to fit narrow screens.

## Files changed for this task

Frontend implementation (relative to `frontend/`):

- `lib/core/utils/money_formatter.dart` (new)
- `lib/core/utils/pdf_exporter.dart`
- `lib/core/horizon/components/horizon_count_up_text.dart`
- `lib/core/horizon/tokens/horizon_formatters.dart`
- `lib/providers/currency_provider.dart`
- `lib/providers/report_provider.dart`
- `lib/routes/app_router.dart`
- `lib/screens/accounts/widgets/money_text.dart`
- `lib/screens/analytics/widgets/fin_content_bounds.dart`
- `lib/screens/analytics/widgets/global_fin_overlay.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/widgets/dashboard_recent_row.dart`
- `lib/screens/main_navigation_screen.dart`
- `lib/screens/primary_page_view.dart` (new)
- `lib/screens/reports/reports_screen.dart`
- `lib/screens/reports/widgets/cashflow_tab_view.dart`
- `lib/screens/reports/widgets/categories_tab_view.dart`
- `lib/screens/reports/widgets/trends_tab_view.dart`

Backend implementation (relative to `backend/`):

- `controllers/reportController.js`
- `models/dashboardModel.js`
- `models/reportModel.js`
- `utils/cashFlow.js` (new)

Tests and documentation:

- `frontend/test/primary_navigation_reports_test.dart` (new)
- `frontend/test/production_primary_navigation_test.dart` (new)
- `frontend/test/report_currency_data_test.dart` (new)
- `frontend/test/reports_interactive_redesign_test.dart` (updated old USD expectation)
- `backend/test/reportsConsistency.test.js` (new)
- `frontend/docs/NAVIGATION_REPORTS_FIX.md` (this report)

Pre-existing edits to authentication, registration, splash, text fields and their tests were preserved.

## Verification

- `dart format` on all 22 affected Dart files: passed.
- `flutter analyze --no-pub`: no issues found.
- Focused Flutter suite: 81 tests passed across primary navigation, production router, currency/provider data, Reports, Dashboard, Horizon foundation, account widgets, shell interactions and FIN regression suites.
- Final Reports layout rerun: 36 passed, covering the navigation width matrix, currency/provider tests and existing Reports tests.
- `node --import ./config/testEnv.js --test test/reportsConsistency.test.js test/dashboardAnalytics.test.js`: 10 passed.
- `git diff --check` in both repositories: passed.

New tests cover dock selection, swipes in both directions through all five destinations, route/page/index synchronization, retained report subtab/range/scroll state, deep-route restoration, Android back, no skipped-screen initialization, one initial data load per real destination, and widths 320/360/393/600. Currency tests cover shared formatting, exact strings, negative INR, Indian grouping, saved preferences and live changes across all Reports subtabs. Backend tests cover equal-filter Dashboard/Reports totals, distinct All Time totals, decimal arithmetic, inclusive end dates, user isolation, uncategorized timeline/export joins and running balances.

Tests use controlled repositories/database responses. Physical Android smoothness and live-account/backend behavior were not exercised in this headless run.
