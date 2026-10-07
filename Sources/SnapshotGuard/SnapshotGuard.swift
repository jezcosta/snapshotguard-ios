#if canImport(UIKit)
import UIKit

/// The entry point of SnapshotGuard.
///
/// `SnapshotGuard` is a namespace: it holds no state and cannot be instantiated. Today it renders
/// screens; verification against baselines will be added here in later releases.
///
/// ## Rendering model
///
/// Content is laid out inside a hidden, scene-less `UIWindow` created for each call and sized to
/// the configuration's viewport, so rendering does not depend on the application's windows. The
/// window pins the traits the configuration controls — display scale — and, until they become part
/// of ``VisualConfiguration``, the user interface style (light) and the content size category
/// (`large`). The result is drawn into an sRGB bitmap at the configured scale.
///
/// ## Limitations
///
/// - The layer tree is drawn with `CALayer.render(in:)`. Content composited outside it —
///   `UIVisualEffectView` blurs, Metal and video layers, `WKWebView` — is not captured.
/// - Safe area insets are zero, and the horizontal/vertical size classes, layout direction and
///   locale come from the environment the tests run in. Device presets will take over these.
/// - Layout runs a single `layoutIfNeeded()` pass. Content that needs asynchronous work to settle
///   (network images, animations, run-loop dependent updates) must be settled by the caller first.
/// - Fonts, and therefore pixels, can differ between simulator runtimes and between simulator and
///   device. Record and verify on the same OS version.
/// - Rendering must happen on the main actor.
public enum SnapshotGuard {
    /// Renders a view.
    ///
    /// The view is temporarily hosted in an offscreen window sized to the viewport, so it is
    /// laid out to fill it. The view's frame, superview and `translatesAutoresizingMaskIntoConstraints`
    /// are restored before this method returns.
    ///
    /// - Parameters:
    ///   - view: The view to render. It must not already be in a view hierarchy.
    ///   - configuration: The environment to render in. Defaults to ``VisualConfiguration/default``.
    /// - Returns: The rendered snapshot.
    /// - Throws: ``SnapshotGuardError/alreadyInHierarchy`` if `view` has a superview or window;
    ///   ``SnapshotGuardError/renderingFailed`` if the bitmap cannot be created.
    @MainActor
    public static func render(
        _ view: UIView,
        configuration: VisualConfiguration = .default
    ) throws -> RenderedSnapshot {
        try SnapshotRenderer.render(view, configuration: configuration)
    }

    /// Renders a view controller that is not presented.
    ///
    /// The controller becomes the root of an offscreen window sized to the viewport, so its view is
    /// loaded, sized and laid out, and it receives layout callbacks such as `viewDidLoad()` and
    /// `viewDidLayoutSubviews()`. Appearance callbacks (`viewWillAppear(_:)` and friends) are not sent
    /// because the window is never visible. The controller is detached from the window before this
    /// method returns; its view stays loaded.
    ///
    /// - Parameters:
    ///   - viewController: The controller to render. It must not be presented or embedded in a
    ///     parent controller.
    ///   - configuration: The environment to render in. Defaults to ``VisualConfiguration/default``.
    /// - Returns: The rendered snapshot.
    /// - Throws: ``SnapshotGuardError/alreadyInHierarchy`` if the controller is presented, has a
    ///   parent, or its view is in a hierarchy; ``SnapshotGuardError/renderingFailed`` if the
    ///   bitmap cannot be created.
    @MainActor
    public static func render(
        _ viewController: UIViewController,
        configuration: VisualConfiguration = .default
    ) throws -> RenderedSnapshot {
        try SnapshotRenderer.render(viewController, configuration: configuration)
    }
}
#endif
