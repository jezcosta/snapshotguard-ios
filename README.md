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

// A configuration is a plain value that is valid by construction.
let configuration = try VisualConfiguration(
    viewport: CGSize(width: 393, height: 852), // points
    scale: 3
)

// Render a view controller that has not been presented…
let snapshot = try SnapshotGuard.render(
    CheckoutViewController(),
    configuration: configuration
)

// …or a plain view. `configuration` defaults to `.default` (393 × 852 pt @3x).
let viewSnapshot = try SnapshotGuard.render(myView)

snapshot.image        // UIImage, 393 × 852 pt @3x
snapshot.pixelWidth   // 1179
snapshot.pixelHeight  // 2556
snapshot.configuration
```

Rendering is `@MainActor` and throws `SnapshotGuardError` for views that are already in a hierarchy
or bitmaps that cannot be allocated.

### Determinism, and what to expect

Rendering happens in a hidden, scene-less window created per call. The display scale comes from the
`VisualConfiguration`; until appearance and text size become part of it, they are pinned to **light**
and **`large`**, so results do not change with the simulator's settings. See the documentation on
`SnapshotGuard` for the full list of limitations. The important ones:

- Content composited outside the layer tree (`UIVisualEffectView` blurs, Metal, video, `WKWebView`)
  is not captured.
- Safe area insets are zero; size classes, layout direction and locale still come from the
  environment. Device presets will address this.
- Layout runs one `layoutIfNeeded()` pass. Settle asynchronous content before rendering.
- Pixels can differ across OS versions; record and verify on the same simulator runtime.

## Roadmap

Checked items exist today.

- [x] Core rendering architecture
- [x] `UIView` rendering
- [x] `UIViewController` rendering
- [x] `VisualConfiguration` foundation
- [ ] Device presets
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

To run the tests:

```sh
xcodebuild test \
  -scheme SnapshotGuard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## License

SnapshotGuard is released under the MIT License. See [LICENSE](LICENSE).
