import CoreGraphics

/// The visual environment a screen is rendered in.
///
/// A configuration is a plain value: it is valid by construction, cheap to copy and safe to share
/// across threads. Rendering the same content with the same configuration is the unit of work that
/// future baselines and comparisons will be keyed on.
///
/// ```swift
/// let configuration = try VisualConfiguration(
///     viewport: CGSize(width: 393, height: 852),
///     scale: 3
/// )
/// ```
public struct VisualConfiguration: Equatable, Hashable, Sendable {
    /// The size, in points, of the area the content is laid out in.
    public let viewport: CGSize

    /// The display scale: how many pixels make up one point.
    public let scale: CGFloat

    /// A 393 × 852 pt viewport at 3×.
    ///
    /// This is a neutral starting point, not a device preset: it does not model safe areas or any
    /// other hardware characteristic.
    public static let `default` = VisualConfiguration(validViewport: CGSize(width: 393, height: 852), scale: 3)

    /// Creates a configuration.
    ///
    /// - Parameters:
    ///   - viewport: The layout size in points. Width and height must be finite and greater than zero.
    ///   - scale: The display scale. Must be finite and greater than zero.
    /// - Throws: ``SnapshotGuardError/invalidViewport(_:)`` or ``SnapshotGuardError/invalidScale(_:)``.
    public init(viewport: CGSize, scale: CGFloat) throws {
        guard viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 0, viewport.height > 0 else {
            throw SnapshotGuardError.invalidViewport(viewport)
        }
        guard scale.isFinite, scale > 0 else {
            throw SnapshotGuardError.invalidScale(scale)
        }
        self.init(validViewport: viewport, scale: scale)
    }

    private init(validViewport viewport: CGSize, scale: CGFloat) {
        self.viewport = viewport
        self.scale = scale
    }
}
