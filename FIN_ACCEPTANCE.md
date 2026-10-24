# FIN acceptance — 24 October 2026

Headless Flutter acceptance was performed against the current HORIZON working tree. Existing HORIZON changes were preserved. No emulator, staging, commit or push was used. This report supersedes the older visual/overlay descriptions in `FIN_REDESIGN.md` and `FIN_LAYOUT_FIX.md`.

## Visual evidence and findings

Actual Flutter raster captures, rather than illustrations or reference-image substitutes:

- [Conversation, 390 logical pixels](build/fin_acceptance/previews/conversation-final.png)
- [Settings preview, 393 logical pixels](build/fin_acceptance/previews/settings.png)
- [Resting, greeting, listening, thinking, explaining, celebrating and caution](build/fin_acceptance/previews/poses.png)
- [Left-edge peek](build/fin_acceptance/previews/peek-left.png)
- [Ledger with FIN in clear space](build/fin_acceptance/previews/ledger-final.png)
- [Dashboard with FIN yielding to content](build/fin_acceptance/previews/dashboard-final.png)
- [Settings in the real navigation shell](build/fin_acceptance/previews/settings-in-shell.png)

The approved references were opened and visually compared with these actual renders:

- [Stitch conversation](../stitch_fintrack_horizon_redesign/fin_companion_living_assistant/screen.png)
- [Stitch settings](../stitch_fintrack_horizon_redesign/fin_companion_settings/screen.png)
- [Stitch state matrix](../stitch_fintrack_horizon_redesign/systemwide_ux_states_loading_fin_character_matrix/screen.png)
- [Stitch dashboard](../stitch_fintrack_horizon_redesign/home_dashboard_cinematic_horizon/screen.png)

These references contain different character anatomies. The shared new Flutter rig follows the settings capsule, while retaining articulated limbs for conversation poses. It does not exactly reproduce the separate-headed conversation reference.

| Part | Actual comparison and acceptance result |
| --- | --- |
| Proportions | Tall capsule consistent with settings; narrower and more elongated than that reference. The conversation reference has a separate head and torso. This difference remains. |
| Visor | Rounded navy inset with glass sheen retained. Less volumetric than the conversation render; its smiling mouth is absent. |
| Eyes | Cyan glowing crescents now used at rest to better match settings. Round attentive/thinking eyes and amber caution eyes remain distinct. |
| Body | Cream/champagne gradient and rim lighting retained. Native vector shading does not reproduce reference materials, reflections or perspective. |
| Leaf | Gold upright leaf and small leaflet align with the settings motif; silhouette and lighting are simplified. |
| Chest | Gold upward arrow and dashed ring match settings. The conversation reference instead has a plant emblem. |
| Arms | Connected shoulder/elbow/hand segments support all poses. Corrected greeting elbow direction, thinking hand placement and explaining forearm. Hand pods remain simpler than the conversation reference's fingers. |
| Legs | Short connected struts and planted foot pods suit the capsule. They differ from the conversation reference's long legs and the settings reference's floating capsule. |
| Posture | Resting is planted; greeting raises its hand, thinking brings its hand inward, explaining presents outward, caution folds inward, celebration lifts one arm. Edge mode leans and grips the clipped edge. |

The seven-pose sheet and separate edge captures cover all eight requested poses; resting is the `idle` state. No claim of 100% visual fidelity or numerical image-similarity score is made.

## Behavior, obstruction and privacy

The shell now reports painted text, imagery, charts and semantic controls to FIN without changing page width. FIN seeks an unoccupied vertical position with clearance, yields entirely if none fits, and stays above the shell's bottom navigation. On transaction surfaces it uses the left edge, away from amounts and action controls. If a mini panel cannot fit without covering content, tapping FIN opens the dedicated conversation instead. Existing keyboard, popup, form-route, lifecycle, safe-area and fold suppression remains.

Bounds are reevaluated after rendered frames, including scrolling and content changes inside repaint boundaries. The observer requests no continuous frames itself. This is conservative avoidance based on Flutter paint/semantic bounds, not a guarantee for every future custom renderer or arbitrary animation. Rapid scrolling, frame timing and gesture feel still require physical-device checks.

Focused tests exercise actual animated pose transitions, OS reduced motion, disabled TickerMode, animation reactivation, unmount cleanup, and notifications after unmount. Existing tests cover saved motion preferences, shared controller state, request failures, confirmed success, keyboard entry, dialogs, dismissal, navigation and large-text/fold layouts. All four character animation controllers are disposed and shared-controller listeners are removed on unmount; the overlay cancels its greeting timer and removes its lifecycle observer.

Replaced the conversation's “View Guarantee”, ambiguous “Private & Read-Only” banner and absolute external-service assertion with backend-processing descriptions. Settings now explicitly names the FinTrack backend. No local-enclave, exclusively-on-device or hardware-backed-storage promise was introduced. Financial actions retain their existing confirmation flow.

## Verification

- Focused FIN, privacy, analytics and screen-layout run: **97 passed**, including the then-current two new acceptance tests. The complete app suite was not repeated.
- Subsequent capture/fallback run: **28 passed**, including all three acceptance tests and 25 FIN redesign/capture tests.
- Real-screen matrix: 16 screens × 7 widths × 2 themes = **224 combinations**, with enabled/disabled/left-edge checks, scrolling and navigation assertions. Widths: 320, 360, 393, 430, 600, 768 and 1024 logical pixels. Screens include FIN settings, Ledger, transactions, accounts, dashboard, budgets, reports, companion and profile/security/import surfaces.
- Final `flutter analyze`: **no issues**.
- `git diff --check`: passed.

Logs are under `build/fin_acceptance/`; the main focused log is `focused-tests.log`, the subsequent run is `final-captures.log`, and final analysis is `analyze-final.log`. Full generated screen captures remain under `build/fin_layout_verification/previews/` and `build/fin_previews/`. Preview fonts are loaded from bundled HORIZON assets; the chip screenshot harness explicitly loads its platform-default equivalent to avoid test-only Ahem glyphs.

## Android release

Built successfully with Flutter 3.44.6 / Dart 3.12.2 using the existing production signing configuration:

```text
flutter build apk --release --dart-define=BASE_URL=https://expense-manager-api-qn07.onrender.com/api/
```

| Check | Result |
| --- | --- |
| Output | `C:\folder\node+express\personal-Finance-Manager\frontend\build\app\outputs\flutter-apk\app-release.apk` |
| Package | `com.mkl.financemanager` |
| Version | `1.0.0`, code `1` (preserved) |
| Size | **72,250,651 bytes / 68.90 MiB** |
| APK SHA-256 | `5e6d013e7a683565750e5c834e767d88bc780b699fbd2f5e6b2fb913124c7089` |
| Signing | `apksigner verify --verbose --print-certs`: valid APK Signature Scheme v2, one signer |
| Existing signing identity | Matches the prior release certificate SHA-256: `bf68eb5f6fe9b38a8fdbc5eac2247dcaad4ae6c23a32c91ae79c021d0867cb7e` |
| ZIP integrity and alignment | All CRCs valid; `zipalign -c 4` passed |
| Compiled API and FIN | Production URL, FIN semantics and updated privacy text verified inside **all three** compiled `libapp.so` libraries: arm64-v8a, armeabi-v7a, x86_64 |
| Assets | Both HORIZON font files and all three branding PNGs are present and byte-identical to working-tree assets; Flutter asset/font manifests present |
| Signing credentials | Existing keystore and signing properties were used without modification; remain Git-ignored. No passwords were printed or added to reports, and no signing keystore, signing properties or `.env` was included in the APK |

FIN is drawn by native Flutter code, so no separate FIN raster asset is expected. The compiled-library checks and successful source build establish inclusion of the current implementation; they are not a substitute for an Android-device render check.

Evidence: [build log](build/fin_acceptance/build-release.log), [package metadata](build/fin_acceptance/package.txt), [signature verification](build/fin_acceptance/signature.txt), [asset/API/hash verification](build/fin_acceptance/apk-verification.json). The public signing-certificate fingerprint is safe to record; private signing material was not copied into these artifacts.

## Physical-device checks outstanding

Install/update on a real Android device; startup and production API authentication/requests; touch and drag behavior during rapid scrolling; sustained animation performance, battery use and frame timing; system reduced-motion behavior on device; keyboard/gesture-navigation and manufacturer-specific cutout/fold behavior. These were not simulated as completed. Package/signature verification does not establish backend availability or successful device installation.
