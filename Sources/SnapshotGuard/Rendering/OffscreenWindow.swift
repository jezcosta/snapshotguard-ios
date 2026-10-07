#if canImport(UIKit)
import UIKit

/// Creates the offscreen window content is hosted in while it is rendered.
///
/// A window is what gives views a trait environment, so it is also where everything the
/// configuration controls (or that would otherwise leak in from the device) is pinned.
enum OffscreenWindow {
    /// Returns a hidden window sized to the configuration's viewport.
    ///
    /// The window is not attached to any scene and is never made key or visible, so it cannot
    /// affect the host application.
    @MainActor
    static func make(for configuration: VisualConfiguration) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: configuration.viewport))
        window.traitOverrides.displayScale = configuration.scale
        // Not yet part of VisualConfiguration. Pinned so results do not depend on the
        // appearance or text size selected on the device or simulator that happens to run them.
        window.traitOverrides.userInterfaceStyle = .light
        window.traitOverrides.preferredContentSizeCategory = .large
        return window
    }
}
#endif
