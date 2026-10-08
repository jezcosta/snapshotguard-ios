import CoreGraphics

/// The parts of the viewport covered by system UI such as the status bar, the Dynamic Island or the
/// home indicator, in points.
///
/// This is what `UIView.safeAreaInsets` reports. Insets are *physical* (left/right, not
/// leading/trailing) because layout direction is not configurable yet. Values are checked when a
/// ``VisualConfiguration`` is created.
public struct SafeAreaInsets: Equatable, Hashable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    /// No inset on any edge.
    public static let zero = SafeAreaInsets()

    /// Creates insets. Omitted edges are zero.
    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}
