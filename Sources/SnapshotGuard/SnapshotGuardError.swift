import CoreGraphics
import Foundation

/// An error thrown by SnapshotGuard.
public enum SnapshotGuardError: Error, Equatable, Sendable {
    /// The viewport is not usable: its width or height is not a finite number greater than zero.
    case invalidViewport(CGSize)

    /// The scale is not a finite number greater than zero.
    case invalidScale(CGFloat)

    /// The view, or the view controller's view, is already part of a view hierarchy.
    ///
    /// SnapshotGuard has to host the view in its own offscreen window to lay it out. Moving a view
    /// out of an existing hierarchy would discard its constraints with the old superview and cannot
    /// be undone, so such views are rejected instead of being mutated.
    case alreadyInHierarchy

    /// The bitmap for the requested viewport and scale could not be created, typically because it
    /// is too large to allocate.
    case renderingFailed
}

extension SnapshotGuardError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidViewport(let size):
            return "Invalid viewport \(size.width) × \(size.height): width and height must be finite and greater than zero."
        case .invalidScale(let scale):
            return "Invalid scale \(scale): scale must be finite and greater than zero."
        case .alreadyInHierarchy:
            return "The view is already part of a view hierarchy. Render a view that has no superview, or a view controller that is neither presented nor embedded."
        case .renderingFailed:
            return "The snapshot bitmap could not be created for the requested viewport and scale."
        }
    }
}
