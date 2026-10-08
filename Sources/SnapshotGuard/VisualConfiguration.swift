import CoreGraphics

/// The visual environment a screen is rendered in.
///
/// A configuration is the *resolved* input of a render: every value the renderer needs is explicit,
/// so rendering never depends on the device or simulator running it. It is a plain value, valid by
/// construction, cheap to copy and safe to share across threads.
///
/// Create one from a known device with ``init(device:)``, or describe a custom environment with
/// ``init(viewport:scale:safeAreaInsets:idiom:horizontalSizeClass:verticalSizeClass:)``:
///
/// ```swift
/// let known = VisualConfiguration(device: .iPhone16Pro)
///
/// let custom = try VisualConfiguration(
///     viewport: CGSize(width: 500, height: 700),
///     scale: 2
/// )
/// ```
public struct VisualConfiguration: Equatable, Hashable, Sendable {
    /// The size, in points, of the area the content is laid out in.
    public let viewport: CGSize

    /// The display scale: how many pixels make up one point.
    public let scale: CGFloat

    /// The safe area inside the viewport, as reported by `safeAreaInsets` and `safeAreaLayoutGuide`.
    public let safeAreaInsets: SafeAreaInsets

    /// The device idiom reported to the content.
    public let idiom: DeviceIdiom

    /// The horizontal size class reported to the content.
    public let horizontalSizeClass: SizeClass

    /// The vertical size class reported to the content.
    public let verticalSizeClass: SizeClass

    /// A 393 × 852 pt viewport at 3×, phone idiom, no safe area, compact × regular size classes.
    ///
    /// This is a neutral starting point, not a device preset: it does not model safe areas or any
    /// other hardware characteristic.
    public static let `default` = VisualConfiguration(
        validViewport: CGSize(width: 393, height: 852),
        scale: 3,
        safeAreaInsets: .zero,
        idiom: .phone,
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular
    )

    /// Creates a custom configuration.
    ///
    /// Nothing is inferred from the viewport: values you do not pass take the documented defaults,
    /// which describe a phone in portrait without a notch.
    ///
    /// - Parameters:
    ///   - viewport: The layout size in points. Width and height must be finite and greater than zero.
    ///   - scale: The display scale. Must be finite and greater than zero.
    ///   - safeAreaInsets: The safe area. Defaults to ``SafeAreaInsets/zero``. Each inset must be
    ///     finite and not negative, and the insets must leave a non-empty area inside the viewport.
    ///   - idiom: Defaults to ``DeviceIdiom/phone``.
    ///   - horizontalSizeClass: Defaults to ``SizeClass/compact``.
    ///   - verticalSizeClass: Defaults to ``SizeClass/regular``.
    /// - Throws: ``SnapshotGuardError/invalidViewport(_:)``, ``SnapshotGuardError/invalidScale(_:)``
    ///   or ``SnapshotGuardError/invalidSafeAreaInsets(_:)``.
    public init(
        viewport: CGSize,
        scale: CGFloat,
        safeAreaInsets: SafeAreaInsets = .zero,
        idiom: DeviceIdiom = .phone,
        horizontalSizeClass: SizeClass = .compact,
        verticalSizeClass: SizeClass = .regular
    ) throws {
        guard viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 0, viewport.height > 0 else {
            throw SnapshotGuardError.invalidViewport(viewport)
        }
        guard scale.isFinite, scale > 0 else {
            throw SnapshotGuardError.invalidScale(scale)
        }
        let insets = [safeAreaInsets.top, safeAreaInsets.left, safeAreaInsets.bottom, safeAreaInsets.right]
        guard insets.allSatisfy({ $0.isFinite && $0 >= 0 }),
              safeAreaInsets.left + safeAreaInsets.right < viewport.width,
              safeAreaInsets.top + safeAreaInsets.bottom < viewport.height else {
            throw SnapshotGuardError.invalidSafeAreaInsets(safeAreaInsets)
        }
        self.init(
            validViewport: viewport,
            scale: scale,
            safeAreaInsets: safeAreaInsets,
            idiom: idiom,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    /// Creates the configuration that renders a known device.
    ///
    /// Presets are curated and always valid, so this cannot fail.
    public init(device: DevicePreset) {
        self.init(
            validViewport: device.viewport,
            scale: device.scale,
            safeAreaInsets: device.safeAreaInsets,
            idiom: device.idiom,
            horizontalSizeClass: device.horizontalSizeClass,
            verticalSizeClass: device.verticalSizeClass
        )
    }

    private init(
        validViewport viewport: CGSize,
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
