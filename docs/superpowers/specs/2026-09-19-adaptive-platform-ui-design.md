# Adaptive platform UI (native + Liquid Glass) — design

Branch: `experiment/adaptive-platform-ui` · Package: [`adaptive_platform_ui`](https://pub.dev/packages/adaptive_platform_ui) 1.0.0

## Goal
Experiment with native UI on iOS — Liquid Glass on iOS 26+ via UIKit platform
views, Cupertino on older iOS, Material 3 on Android — without a full rewrite.

## Scope (this pass)
Shell + core controls. Screens pick up the new look through the existing
shared wrappers; raw Material widgets in feature screens are out of scope.

## Approach
Swap implementations behind the existing wrappers so the package is imported in
few places and the experiment is cheap to revert.

1. **App root** — `lib/app.dart`: `MaterialApp.router` → `AdaptiveApp.router`.
   Keep the `builder` stack (DevicePreview, text scaler, NoConnectionOverlay,
   IncomingCallOverlay), themes, locale, `goRouterProvider`. Add a Cupertino
   theme derived from brand colors.
2. **Tab bar (native everywhere)** — `MainNavigationScreen` uses
   `AdaptiveScaffold` + `AdaptiveBottomNavigationBar`; keeps `IndexedStack`,
   `navTabProvider` and `initialTab`. SF Symbols: `house`, `hand.thumbsup`,
   dynamic third tab, `magnifyingglass`, `bell`. Brand navy tint.
   `AppBottomNav`/`AppNavItem` kept but unused. Check bottom insets since
   content scrolls under the glass bar.
3. **App bars** — `PlatformAppBar` delegates to `AdaptiveAppBar` on iOS 26+;
   custom boxed back chevron kept on older iOS / Android.
4. **Controls** — `PrimaryButton` → `AdaptiveButton` (filled = prominent glass,
   outlined = bordered; loading keeps the Zennyt loader); `ZennytSwitch` →
   `AdaptiveSwitch`; `AppDialog.*` → `AdaptiveAlertDialog`; new
   `showAppBottomSheet` helper.

## Out of scope / follow-ups
~150 raw `ElevatedButton`/`FilledButton`/`TextButton`, ~30 raw
`showModalBottomSheet`, direct `Scaffold`s in features.
`IOS26NativeSearchTabBar` (flagged experimental upstream).

## Risks
- Package is brand new (1.0.0).
- Platform views cost more than Flutter widgets (IndexedStack shell, lists).
- iOS stays on CocoaPods (Agora); target 15.0 is supported.

## Verification
`flutter analyze`, existing tests, iOS 26 simulator build with screenshots
(tab bar, app bar, dialog, button; light + dark), fallback check on
Android or older iOS.
