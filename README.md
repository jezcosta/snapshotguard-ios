# SnapshotGuard

**Visual regression testing for iOS, built for teams and CI.**

> ⚠️ **Early development.** Only the rendering foundation exists today. Verification, baselines,
> comparison, diffs, reports and the CLI are on the [roadmap](#roadmap) and **are not implemented yet**.

## Why SnapshotGuard

Most snapshot libraries answer one question: *"does this view still look like the image I saved?"*
SnapshotGuard is aiming at a bigger one:

> *"Does this screen still look right on every device, appearance and text size we ship — and can
> developers, QA and designers review the differences without reading a diff of PNGs?"*

The goal is **not** to provide yet another `assertSnapshot`. The goal is to treat *visual regression
verification* as the domain: a screen is rendered across a **matrix** of configurations, compared
against **baselines**, and the outcome is a **report** people can review — locally and in CI.

## Vision

```
Screen
  ↓
Visual Matrix
  ↓
Render
  ↓
Baseline
  ↓
Comparison
  ↓
Visual Diff
  ↓
Report
```

Each stage is meant to be a first-class concept with its own small API, so that teams can adopt the
pieces they need and CI can consume the results.

### Planned API (concept — not implemented)

The snippet below is a **design sketch** of where the project is heading. **It does not compile
today.**

```swift
// ⚠️ Roadmap / concept only — SnapshotGuard.verify does not exist yet.
try SnapshotGuard.verify(
    CheckoutViewController(),
    matrix: .init(
        devices: [.iPhoneSE, .iPhone16Pro, .iPadPro],
        appearances: [.light, .dark],
        dynamicType: [.default, .accessibilityXXXL]
    )
)
```

That single statement would expand to 3 devices × 2 appearances × 2 Dynamic Type sizes =
**12 visual regression checks**.

## Requirements

- iOS 17.0+
- Xcode 16+ (Swift 6.0 toolchain)
- No third-party dependencies

iOS 17 is the floor because SnapshotGuard pins the trait environment of the content it renders with
`UIView.traitOverrides`, which arrived in iOS 17.

## Installation

Add SnapshotGuard with Swift Package Manager. In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<owner>/snapshotguard-ios.git", branch: "main")
],
targets: [
    .testTarget(
        name: "MyAppTests",
        dependencies: [.product(name: "SnapshotGuard", package: "snapshotguard-ios")]
    )
]
```

Or in Xcode: **File ▸ Add Package Dependencies…** and enter the repository URL. Replace
`<owner>` with the account that hosts the repository; no tagged release exists yet.

SnapshotGuard needs UIKit, so build and test it for an iOS Simulator destination — `swift build` on
macOS compiles an empty module.

## Basic usage (what works today)

Today SnapshotGuard renders a `UIView` or an unpresented `UIViewController` into an image, in an
explicitly described environment.

```swift
import SnapshotGuard

let configuration = VisualConfiguration(device: .iPhone16Pro)

// Render a view controller that has not been presented…
let snapshot = try SnapshotGuard.render(
    CheckoutViewController(),
    configuration: configuration
)

// …or a plain view. `configuration` defaults to `.default` (393 × 852 pt @3x).
let viewSnapshot = try SnapshotGuard.render(myView)

snapshot.image        // UIImage, 402 × 874 pt @3x
snapshot.pixelWidth   // 1206
snapshot.pixelHeight  // 2622
snapshot.configuration
```

Rendering is `@MainActor` and throws `SnapshotGuardError` for views that are already in a hierarchy
or bitmaps that cannot be allocated.

### Device presets

A `DevicePreset` describes a known device by the characteristics that change what UIKit lays out and
draws: viewport, display scale, safe area, idiom and size classes. Presets encapsulate them so a
render is **deterministic and independent of the simulator running it** — rendering `.iPhone16Pro`
on an iPad simulator gives a view the same safe area, size classes and idiom as on an iPhone one.

| Preset          | Viewport (pt) | Scale | Safe area (top / left / bottom / right) | Size classes (H × V) | Idiom |
| --------------- | ------------- | ----- | --------------------------------------- | -------------------- | ----- |
| `.iPhoneSE`     | 375 × 667     | 2×    | 20 / 0 / 0 / 0                          | compact × regular    | phone |
| `.iPhone16Pro`  | 402 × 874     | 3×    | 62 / 0 / 34 / 0                         | compact × regular    | phone |
| `.iPadPro13`    | 1032 × 1376   | 2×    | 32 / 0 / 25 / 0                         | regular × regular    | pad   |

All presets are **portrait, full-screen** apps. Landscape, Split View and Stage Manager are not
modelled yet. The values and where they come from are documented on each preset. Safe area insets
can differ between OS versions for the same hardware; the `iPadPro13` insets are those of iPadOS 26.

A preset is a convenience, not a requirement. A `VisualConfiguration` can describe any environment:

```swift
let configuration = try VisualConfiguration(
    viewport: CGSize(width: 500, height: 700),
    scale: 2,
    safeAreaInsets: SafeAreaInsets(top: 20, bottom: 10) // optional
)
```

Nothing is inferred from the viewport: values you leave out default to *no safe area, phone idiom,
compact × regular size classes*.

### Determinism, and what to expect

Rendering happens in an offscreen window created per call. Everything the `VisualConfiguration`
describes is pinned; until appearance and text size become part of it, they are pinned to **light**
and **`large`**, so results do not change with the simulator's settings. See the documentation on
`SnapshotGuard` for the full list of limitations. The important ones:

- Content composited outside the layer tree (`UIVisualEffectView` blurs, Metal, video, `WKWebView`)
  is not captured.
- Layout direction and locale still come from the environment.
- Layout runs one `layoutIfNeeded()` pass. Settle asynchronous content before rendering.
- Pixels can differ across OS versions; record and verify on the same simulator runtime.
- The offscreen window is briefly shown, so view controllers receive appearance callbacks. This has
  been validated in test bundles without a host application only.

## Roadmap

Checked items exist today.

- [x] Core rendering architecture
- [x] `UIView` rendering
- [x] `UIViewController` rendering
- [x] `VisualConfiguration` foundation
- [x] Device presets
- [ ] Visual Matrix
- [ ] Baseline recording
- [ ] Pixel comparison
- [ ] Perceptual comparison
- [ ] Visual diff generation
- [ ] Verification API
- [ ] Light/Dark Mode matrix
- [ ] Dynamic Type matrix
- [ ] SwiftUI support
- [ ] JSON reports
- [ ] HTML reports
- [ ] CLI
- [ ] XCTest integration
- [ ] Swift Testing integration
- [ ] CI integrations

## Contributing

Contribution guidelines are coming. Until then, issues and design discussion are welcome. Please
keep changes small and focused: the project is built incrementally and each step is meant to be easy
to review.

To run the tests, on an iPhone **and** an iPad simulator — the device-environment tests are meant to
hold on both:

```sh
xcodebuild test -scheme SnapshotGuard -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme SnapshotGuard -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

## License

SnapshotGuard is released under the MIT License. See [LICENSE](LICENSE).
