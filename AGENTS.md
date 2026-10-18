# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`PolarisGuideKit` is a lightweight UIKit-based onboarding/coach-marks library for iOS 12+. It is published both as a Swift Package (`Package.swift`) and a CocoaPods pod (`PolarisGuideKit.podspec`). All library sources live under `Sources/`; the only test surface is the manual demo app under `Example/`.

## Build / run / test

There is **no XCTest target** in either `Package.swift` or the example project. Verification is visual, via the demo app's 8 demo cases (root table in `Example/PolarisGuideKitDemo/ViewController.swift`).

The demo project references the package as a **local** Swift package at relative path `../../PolarisGuideKit` (resolved from the `.xcodeproj` location), so it always builds the in-tree sources — no `pod install` needed for library development.

```sh
# Build the demo for a simulator (no signing needed for build)
xcodebuild -project Example/PolarisGuideKitDemo.xcodeproj \
  -scheme PolarisGuideKitDemo \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build

# Open the demo to run/interact
open Example/PolarisGuideKitDemo.xcodeproj
```

To validate the SPM package in isolation (no Xcode project): `swift build` from the repo root.

There is no linter or formatter configured.

## Architecture

The system is a small orchestrator plus a four-class view hierarchy. Reading order for understanding: `GuideController` → `GuideStep` → `GuideOverlayView` → `GuideBuddyView` → `FocusStyle` → `GuidePlugin` / `GuideAutoCompleter`.

### Flow of control

`GuideController` is the single entry point. `show()` pins a transparent `GuideContainerView` onto the resolved `hostView` (or the key window via `PolarisKeyWindowProvider`), installs a `BlockAllGestureRecognizer` on that host to swallow external gestures (navigation swipe-back, ancestor scroll views), then calls `showStep(at:)`. `showStep` tears down the previous step (`buddyView.removeFromSuperview()`, `completer.disable()`, plugin events) and configures the new one: sets the overlay's step (which rebuilds the shadow view + mask), enables the completer, wires the buddy view's `onAction` to `next`/`skip`, and lays the buddy view out against the focus style's layout guide. Each transition dispatches `stepWillShow`→configure→`stepDidShow` plugin events.

**Dynamic focus views:** For `UITableView`/`UICollectionView` cells that may be reused after `reloadData`, set `step.focusViewProvider` directly instead of `focusView`. The provider closure is called on each layout update, ensuring the correct cell is always highlighted. The convenience `focusView` property wraps a weak reference and is suitable for static views only.

### View hierarchy

`GuideContainerView` (transparent, pinned to host bounds) contains:
- `GuideOverlayView` (subclass of `MaskOverlayView`): a full-frame view whose `layer.mask` is a `CAShapeLayer` with **`.evenOdd` fill rule**. The mask path = a rect covering the overlay bounds, minus the focus view's cutout (from `FocusStyle.highlightPath`) and any `additionalHighlightPaths`. A `GuideShadowView` is added as a subview and constrained to match the focus view's frame — it provides `frameLayoutGuide` for buddy-view layout and **self-removes** when its master view leaves the hierarchy.
- `GuideBuddyView` (one per active step): companion view (instructions/arrows/buttons). Pinned to container edges; positioned via `updateLayout(referenceLayoutGuide:focusView:)` using the layout guide returned by `focusStyle.buddyLayoutGuide`.

### Mask refresh and animation

`GuideOverlayView.layoutSubviews` triggers `refreshMask(animated:)` on the next runloop tick (deferred to avoid re-entrancy during a transition). `refreshMask` captures the **presentation-layer path** of the old mask before swapping layers, so an in-flight animation can be interrupted and resumed from the displayed state — never reassign `layer.mask` directly outside `refreshMask`. When `animated: true` and `step.canShowTransitionAnimation()` (focus view in hierarchy or extra paths present), a `CABasicAnimation` on `path` runs from the captured path to the new path. `isInTransitionAnimation` / `needsRefreshAfterAnimation` guard against layout-triggered refreshes mid-animation.

### Touch forwarding and gesture blocking

This is the trickiest area — read `GuideController`'s `UIGestureRecognizerDelegate` extension and `GuideOverlayView.hitTest` together:

- `BlockAllGestureRecognizer` (added to hostView) enters `.began` on any touch. Its delegate methods force **external** gestures (on views that are not the container/focus view subtree and not in `step.gestureRecognizerWhitelist`) to require the blocker to fail — i.e., they can't recognize while the guide is up. Internal/whitelisted gestures recognize simultaneously.
- `GuideGestureGate` supplies an explicit failure requirement for each recognizer on the host/focus ancestor chains. Each gate checks the current step at touch start: it begins to block its target or fails to allow an internal/whitelisted target. Never make every external recognizer permanently depend on the shared blocker; that prevents later steps from whitelisting individual gestures. Gates do not prevent unrelated gestures, and are disabled, detached, and released on hide. Container layout/window changes and focus refreshes update their coverage.
- `GuideOverlayView.hitTest` returns the focus view's `hitTest` result when `forwardsTouchEventsToFocusView == true` and the touch falls inside the focus view; otherwise the overlay absorbs the touch (or calls `onOutsideTap` if `dismissesOnOutsideTap`).
- `GuideBuddyView.hitTest` returns `nil` when the only responder is itself and it has no gesture recognizers — so the buddy view's transparent area doesn't block the overlay's touch logic. Its `backgroundColor` setter is final and forces `.clear`; don't try to give a buddy view a background.
- `MaskOverlayView`'s tap gesture only fires for taps directly on the mask view, not its subviews (see `shouldReceive(touch:)`).

When a new external gesture view matters (e.g., a scroll view that should remain pannable), add it to `step.gestureRecognizerWhitelist` rather than disabling the blocker.

### Completers

`GuideAutoCompleter` is the base; `trigger()` calls `onTrigger`, which `GuideController` wires to `performDismiss(reason: .completerTriggered)`. **Triggering a completer dismisses the entire guide, not just the current step** — so completers are typically configured only on the final step (or single-step guides). Built-in: `ControlEventCompleter` (UIControl target-action) and `GestureRecognizerCompleter` (any `UIGestureRecognizer`, defaults to tap). When the control/gesture view is also the step's `focusView`, set `step.forwardsTouchEventsToFocusView = true` so the underlying view actually receives touches through the overlay. Subclasses **must** override `enable()`/`disable()`; the base implementations `fatalError` in DEBUG.

### Plugins and attachments

`GuidePlugin.handle(_:context:)` receives 8 lifecycle events. Note the ordering nuance documented in `GuidePlugin.swift`: `stepDidShow` fires after the step is configured (mask/buddy/completer ready), but `guideDidShow` fires only after the overlay's fade-in animation completes (or immediately if `show(animated: false)`). Plugins that need the UI fully visible (e.g., starting audio) should key off `guideDidShow`, not `stepDidShow` — see `AudioGuidePlugin` which uses `stepDidShow` and is the reference example for attachment-driven behavior.

`GuideStepAttachment` is a marker protocol; `GuideStep.addAttachment` / `attachment(ofType:)` / `attachments(ofType:)` / `removeAttachments` are the typed accessors. Plugins read attachments from `context.step` — `AudioGuidePlugin` looks up `GuideAudioAttachment` to decide whether to start playback. A buddy view that wants plugin callbacks adopts the plugin's event-receiving protocol (e.g., `GuideAudioEventReceiving`) — the plugin holds a weak reference to the buddy view and forwards events.

### DEBUG-only assertions

Two `fatalError`s are gated behind `#if DEBUG`:
1. `GuideController.init(hostView:steps:plugins:)` — any focus view that is not a descendant of the resolved host (or is the host itself) is rejected. In Release, the same step is silently filtered out.
2. `GuideAutoCompleter.enable()` / `disable()` base — triggers only if a subclass forgets to override.

## Conventions specific to this repo

- The library is iOS-only UIKit. Do not introduce `#if os(macOS)` / AppKit / SwiftUI paths into `Sources/`.
- `GuideContainerView`, `GuideBuddyView`, and `GuideShadowView` all force `backgroundColor = .clear` and/or `isUserInteractionEnabled = false`. Don't work around these overrides — they're load-bearing for touch forwarding and mask correctness.
- The mask path must use the `.evenOdd` fill rule (set in `createLayerMask()`). Custom `FocusStyle.highlightPath` implementations should produce closed paths that read correctly under even-odd (a single closed shape per cutout is the safe default).
- `GuideBuddyView.backgroundColor` is a final `var` that always returns `.clear`. Subclass it and use subviews/gestures for any visual or interactive behavior; don't try to paint the buddy view itself.
- Public API surface is intentionally narrow and doc-commented in English (the README is bilingual zh/en, but inline docs are English). Match the existing doc style (`///` with `- Parameter:` / `- Returns:` / `- Important:`) when extending public types.
- `PolarisKeyWindowProvider` handles multi-scene resolution. When the demo or a host app passes `hostView: nil`, the key window is used; for multi-window apps always pass an explicit `hostView`.

## Importing from other AI agents

A user-level OpenAI Codex config (`~/.codex/config.toml`) and a Gemini CLI config (`~/.gemini/settings.json`) exist. To inspect and import their contents into Claude Code, reply `/import` — it will scan and list what's importable (MCP servers, slash commands, subagents, skills, instructions), then `/import --yes=<digest>` (the scan output names the digest) applies the user-level items. Don't read those foreign-agent config files directly; the deterministic import applies the same safe-name and path-traversal guards as the terminal picker.
