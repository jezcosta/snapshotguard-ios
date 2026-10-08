#if canImport(UIKit)
import UIKit

/// The entry point of SnapshotGuard.
///
/// `SnapshotGuard` is a namespace: it holds no state and cannot be instantiated. Today it renders
/// screens; verification against baselines will be added here in later releases.
///
/// ## Rendering model
///
/// Content is laid out inside an offscreen `UIWindow` created for each call and sized to the
/// configuration's viewport, so rendering does not depend on the application's windows. The window
/// is not attached to a scene, is never made key, and is hidden again before the call returns.
///
/// The window pins the whole environment the ``VisualConfiguration`` describes — display scale,
/// idiom, size classes and safe area — so a render looks the same on an iPhone and on an iPad
/// simulator. Until they become part of ``VisualConfiguration``, the user interface style (light)
/// and the content size category (`large`) are pinned too. The result is drawn into an sRGB bitmap
/// at the configured scale.
///
/// ## Limitations
///
/// - The layer tree is drawn with `CALayer.render(in:)`. Content composited outside it —
///   `UIVisualEffectView` blurs, Metal and video layers, `WKWebView` — is not captured.
/// - Layout direction and locale still come from the environment the tests run in.
/// - The safe area is reproduced as insets. Parts of UIKit that read the real screen, such as the
///   status bar or `UIScreen.main`, still see the host device.
/// - Layout runs a single `layoutIfNeeded()` pass. Content that needs asynchronous work to settle
///   (network images, animations, run-loop dependent updates) must be settled by the caller first.
/// - Fonts, and therefore pixels, can differ between simulator runtimes and between simulator and
///   device. Record and verify on the same OS version.
/// - The window is shown briefly, so a view controller receives its appearance callbacks, and the
///   window is visible to the process while the call runs. This has only been validated in
///   test bundles without a host application.
/// - Rendering must happen on the main actor.
public enum SnapshotGuard {
    /// Renders a view.
    ///
    /// The view is temporarily hosted in an offscreen window sized to the viewport, so it is
    /// laid out to fill it, with the configuration's safe area. The view's frame, superview and
    /// `translatesAutoresizingMaskIntoConstraints` are restored before this method returns.
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
    /// loaded, sized and laid out, and it receives `viewDidLoad()`, `viewDidLayoutSubviews()` and the
    /// appearance callbacks (`viewWillAppear(_:)` through `viewDidDisappear(_:)`). The configuration's
    /// safe area is applied through `additionalSafeAreaInsets`, on top of any insets the controller
    /// already has, and the original value is restored. The controller is detached from the window
    /// before this method returns; its view stays loaded.
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
