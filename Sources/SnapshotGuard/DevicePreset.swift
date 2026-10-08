import CoreGraphics

/// A known device, described by the visual characteristics that matter for rendering it.
///
/// A preset is a convenience, not the rendering input: turn it into a ``VisualConfiguration`` with
/// ``VisualConfiguration/init(device:)``. Custom environments do not need a preset; create a
/// configuration directly.
///
/// ## What a preset contains
///
/// Only values that change what UIKit lays out or draws, and that are stable for a given device:
/// the viewport and scale, the safe area, the idiom and the size classes. Appearance and Dynamic
/// Type are not part of a device and will be separate dimensions.
///
/// ## Orientation
///
/// Every preset is **portrait** and describes the app using the full screen. Landscape, Split View
/// and Stage Manager are not modelled; landscape will be an explicit transformation later rather
/// than something inferred.
///
/// ## Naming
///
/// Presets use the marketing name without spaces and without a generation unless it is needed to
/// tell devices apart (iPads carry their screen size). A preset stands for *every device that shares
/// its screen metrics*, which is listed in each preset's documentation.
///
/// ## Where the values come from
///
/// Viewport, scale and size classes follow Apple's published specifications. Safe area insets were
/// measured with a probe app (a plain `UIWindow` and `UIViewController` filling the screen, portrait,
/// `view.safeAreaInsets`) on the iOS 26.2 simulator, except where noted. Insets can differ between
/// OS versions for the same hardware, so each preset records what it was taken from.
public struct DevicePreset: Equatable, Hashable, Sendable {
    /// The size, in points, of the full screen in portrait.
    public let viewport: CGSize

    /// The display scale.
    public let scale: CGFloat

    /// The safe area in portrait with the status bar visible.
    public let safeAreaInsets: SafeAreaInsets

    /// The device idiom.
    public let idiom: DeviceIdiom

    /// The horizontal size class of a full-screen app in portrait.
    public let horizontalSizeClass: SizeClass

    /// The vertical size class of a full-screen app in portrait.
    public let verticalSizeClass: SizeClass

    // Presets are a curated list, so there is no public initializer: every preset can be checked
    // once (see the tests) and `VisualConfiguration(device:)` can be non-throwing.
    init(
        viewport: CGSize,
        scale: CGFloat,
        safeAreaInsets: SafeAreaInsets,
        idiom: DeviceIdiom,
        horizontalSizeClass: SizeClass,
        verticalSizeClass: SizeClass
    ) {
        self.viewport = viewport
        self.scale = scale
        self.safeAreaInsets = safeAreaInsets
        self.idiom = idiom
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
    }
}

extension DevicePreset {
    /// iPhone SE (2nd and 3rd generation): 375 × 667 pt @2x, with a home button.
    ///
    /// The 20 pt top inset is the status bar height of iPhones without a notch. It was **not
    /// measured**: no simulator for this device is available in current Xcode releases.
    public static let iPhoneSE = DevicePreset(
        viewport: CGSize(width: 375, height: 667),
        scale: 2,
        safeAreaInsets: SafeAreaInsets(top: 20),
        idiom: .phone,
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular
    )

    /// iPhone 16 Pro: 402 × 874 pt @3x, with a Dynamic Island.
    ///
    /// Insets measured on the iPhone 17 Pro simulator, which has the same screen metrics, and
    /// consistent with published iPhone 16 Pro figures.
    public static let iPhone16Pro = DevicePreset(
        viewport: CGSize(width: 402, height: 874),
        scale: 3,
        safeAreaInsets: SafeAreaInsets(top: 62, bottom: 34),
        idiom: .phone,
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular
    )

    /// iPad Pro 13-inch (M4 and M5): 1032 × 1376 pt @2x.
    ///
    /// Insets measured on the iPad Pro 13-inch (M5) simulator running iPadOS 26.2, where the top
    /// inset includes the window controls area. Earlier iPadOS releases report smaller values.
    public static let iPadPro13 = DevicePreset(
        viewport: CGSize(width: 1032, height: 1376),
        scale: 2,
        safeAreaInsets: SafeAreaInsets(top: 32, bottom: 25),
        idiom: .pad,
        horizontalSizeClass: .regular,
        verticalSizeClass: .regular
    )
}
