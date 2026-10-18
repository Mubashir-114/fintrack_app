# FIN living character redesign

Implemented in the existing Flutter frontend on 18 October 2026. No emulator installation was performed.

**Character and shared state**

FIN now uses one native Flutter rig across the dedicated hero, conversation header, result cards, and floating presence. The rig retains the cream/champagne shell, navy visor, cyan eyes, gold joints, growth emblem, and paired leaf ornament. It has articulated shoulders, elbows, wrists, hips, knees, and planted feet. Breathing affects the upper body; the entire character no longer bounces.

Idle, greeting, listening, thinking, explaining, success, warning, empty-data, and error expressions share the same anatomy. Pose changes interpolate smoothly. The greeting wave finishes after one short gesture. Head movement, shoulder motion, leaf movement, gaze, and blinking remain restrained. Animation preferences, reduced motion, and TickerMode are honored.

The dedicated screen and floating presence use AnalyticsProvider's existing FinVisualController. Focus, submitted requests, responses, confirmed actions, and failures drive actual reactions. Duplicate submissions are blocked while work is in flight. An action preview uses an explaining pose until execution succeeds; failures never produce a success pose or confirmation message.

**Completed interactions**

- Tap an edge-peeking FIN to open its compact contextual panel.
- Open the full companion with existing conversation history and context intact.
- Open the existing spending question or navigate to the existing budgets page.
- Switch between left and right edges using the existing saved preference.
- Drag vertically or use the accessible move control to select another edge location.
- Minimize the panel, tap outside it, or dismiss FIN for the session. Long press and custom accessibility actions also support dismissal.
- Hide FIN during keyboard entry, dialogs, sheets, inactive app states, and the full companion screen. Browsing routes support the overlay; editing, security, and import routes do not display it.
- Honor saved visibility preferences before displaying FIN at authenticated shell startup.

The peeking character is an independent overlay with a bounded 44 logical pixel interactive footprint. It reserves no page space, and showing, moving, minimizing, or dismissing FIN does not change page width. The original gutter was removed after the regression investigation documented in `FIN_LAYOUT_FIX.md`. The requested mini panel floats over content without a modal backdrop; outside interactions can continue. Short landscape panels scroll. Safe areas and display features constrain positioning. The dedicated companion uses one display region on hinged layouts and keeps its composer above the keyboard.

The hero has a larger standing character, simpler introduction, theme-based surfaces, readable privacy banner, and accessible suggested-question targets. The conversation is width-constrained on large screens and scrolls after responses arrive.

**Modified files**

| File | Change |
| --- | --- |
| `lib/screens/analytics/widgets/fin_character.dart` | Shared articulated rig, native shading, expressions, interpolated poses, finite greeting wave, reduced-motion support. |
| `lib/screens/analytics/widgets/fin_visual_controller.dart` | Shared presence/dismissal state and request-aware focus/navigation reactions. |
| `lib/screens/analytics/widgets/global_fin_overlay.dart` | Responsive peeking and mini modes, repositioning, accessible controls, popup and keyboard suppression. |
| `lib/screens/analytics/analytics_screen.dart` | Redesigned hero, shared controller, fold-aware layout, composer and conversation refinements. |
| `lib/providers/analytics_provider.dart` | Complete request/action lifecycle synchronization, truthful previews, duplicate-submit guards, local preference fallback. |
| `lib/screens/main_navigation_screen.dart` | Preference loading at startup and independent full-size content/overlay layers. |
| `lib/routes/app_router.dart` | Root and shell popup observers. |
| `test/fin_living_redesign_test.dart` | 23 new tests and optional native Flutter visual captures. |
| `test/private_assistant_test.dart` | Wait for the typed-input frame before tapping the enabled Send button. |
| `FIN_REDESIGN.md` | Implementation and verification report. |

**Privacy and functionality**

The existing financial repositories, endpoints, navigation destinations, privacy guarantee, and backend outbound-data guards remain in use. No dependencies, bank connections, FIN SMS access, external AI integrations, reference-image financial amounts, or mock production dashboard actions were introduced. Existing separately approved financial actions retain their confirmation and real success/failure handling.

**Final verification**

| Check | Result |
| --- | --- |
| Flutter analyze | Passed, no issues. |
| Complete Flutter test suite | Passed, **252 tests**, including the real local backend health check. |
| New redesign tests | Passed, **23 tests**. |
| Android debug APK | Built successfully from the final source in an isolated WSL copy. |
| Diff whitespace check | Passed. |

Tests ran on Windows Flutter 3.44.6 / Dart 3.12.2. Final analysis and Android build also passed on WSL Flutter 3.47.7 / Dart 3.13.5. The full suite runs on Windows where the local backend is available; WSL's separate localhost initially refused that integration connection. The final Windows suite passed without skipping or mocking the backend health test.

Coverage includes actual compact phone, phone, landscape, and tablet viewports; light/dark mini panels; large text; fold hinges; keyboard hiding and composer visibility; dialogs; history continuity; repositioning and dismissal; full-width shell/navigation behavior; saved opt-out; reduced motion; request failure; confirmed success; and unexecuted previews. The subsequent layout correction passed 264 tests and a 100-combination real-screen matrix; see `FIN_LAYOUT_FIX.md` for the latest verification.

Generated verification artifacts (ignored build output):

- `build/fin_verification/fintrack-fin-redesign-debug.apk`
- `build/fin_verification/analyze-final.log`
- `build/fin_verification/test-final.log`
- `build/fin_verification/build-final.log`
- `build/fin_previews/pose_study.png`
- `build/fin_previews/hero_390.png`
- `build/fin_previews/mini_320_dark.png`
- `build/fin_previews/mini_320_light.png`
- `build/fin_previews/peek_left.png`

**Visual limitations**

The character uses stylized vector-based 2.5D shading. It does not reproduce the reference's photorealistic materials, volumetric lighting, or perspective. Only part of the face, shoulder, and connected gripping arm is visible in edge mode. Vertical positioning is session-local; the left/right choice persists. Narrow hero layouts stack and scroll. The mini panel can cover content while explicitly open; minimizing or dismissing it restores the unobstructed interface.

Visual previews were rendered and inspected in Flutter tests. Physical-device frame timing, touch feel, and manufacturer-specific fold behavior have not been manually measured. Preview typography uses a locally available font for readable captures; production retains the app's existing theme typography.
