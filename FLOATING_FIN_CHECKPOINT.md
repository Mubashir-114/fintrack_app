# Floating FIN development checkpoint

Checkpointed on 18 October 2026 as unfinished development work. This is not a
feature-completion or release sign-off.

## Current work

- Refine the FIN peek portrait so more of the character is visible while the
  overlay keeps a narrower interactive hit target and does not allocate page
  width.
- Position the portrait against the usable screen edge and avoid treating
  display cutouts as fold hinges.
- Add a brief greeting wave, relax the character after the greeting, and keep
  the character visible beside the expanded action panel.
- Mount the overlay while saved companion preferences load so a delayed
  preference request does not delay its appearance.
- Add regression coverage for a status-bar cutout, portrait visibility, hit
  target size, and expanded/minimized panel behavior.

These changes are a checkpoint for ongoing refinement; their behavior has not
been fully validated across devices or layouts.

## Known open issue

Reports may still show a **29-pixel RenderFlex overflow at 320 logical pixels**.
This remains open for the next development session. It was not fixed or
revalidated as part of this checkpoint; the previous layout report's wrapping
change does not constitute confirmation that the reported overflow is gone.

## Verification context

Before these latest uncommitted changes, `flutter analyze` reported no issues
and the relevant FIN, Reports, and Transactions test runs passed. Those results
apply to the previously committed code, not to this new checkpoint. No new
analyzer, test, device, or visual run was initiated for the latest changes.

No feature-completion claim is made.
