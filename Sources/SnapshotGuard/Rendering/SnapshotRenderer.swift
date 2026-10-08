#if canImport(UIKit)
import UIKit

/// Renders views and view controllers into ``RenderedSnapshot``s.
///
/// Content is hosted in an offscreen window for the duration of the call and restored to its
/// original state afterwards. See ``SnapshotGuard`` for the public contract and its limitations.
enum SnapshotRenderer {
    @MainActor
    static func render(_ view: UIView, configuration: VisualConfiguration) throws -> RenderedSnapshot {
        guard view.superview == nil, view.window == nil else {
            throw SnapshotGuardError.alreadyInHierarchy
        }

        let offscreen = OffscreenWindow(configuration: configuration)
        defer { offscreen.tearDown() }

        // A view has no safe area of its own: it takes it from the controller it sits in.
        let host = UIViewController()
        offscreen.install(host)

        let originalFrame = view.frame
        let translatesAutoresizingMask = view.translatesAutoresizingMaskIntoConstraints
        var pinConstraints: [NSLayoutConstraint] = []

        host.view.addSubview(view)
        defer {
            NSLayoutConstraint.deactivate(pinConstraints)
            view.removeFromSuperview()
            view.translatesAutoresizingMaskIntoConstraints = translatesAutoresizingMask
            view.frame = originalFrame
        }

        if translatesAutoresizingMask {
            view.frame = offscreen.window.bounds
        } else {
            pinConstraints = [
                view.topAnchor.constraint(equalTo: host.view.topAnchor),
                view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
                view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor)
            ]
            NSLayoutConstraint.activate(pinConstraints)
        }

        return try capture(view, in: offscreen.window, configuration: configuration)
    }

    @MainActor
    static func render(_ viewController: UIViewController, configuration: VisualConfiguration) throws -> RenderedSnapshot {
        guard viewController.parent == nil,
              viewController.presentingViewController == nil,
              viewController.viewIfLoaded?.superview == nil,
              viewController.viewIfLoaded?.window == nil else {
            throw SnapshotGuardError.alreadyInHierarchy
        }

        let offscreen = OffscreenWindow(configuration: configuration)
        defer { offscreen.tearDown() }
        offscreen.install(viewController)

        return try capture(viewController.view, in: offscreen.window, configuration: configuration)
    }

    /// Lays out `view` inside `window` and draws it.
    ///
    /// The layer tree is drawn with `CALayer.render(in:)` rather than `drawHierarchy`: it needs
    /// neither a visible window nor a scene, and it draws model values, so animations in flight do
    /// not make the result depend on timing. The trade-off is that content composited outside the
    /// layer tree is not captured (see ``SnapshotGuard``).
    @MainActor
    private static func capture(_ view: UIView, in window: UIWindow, configuration: VisualConfiguration) throws -> RenderedSnapshot {
        window.layoutIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        format.opaque = false
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: configuration.viewport, format: format)
        let image = renderer.image { context in
            view.layer.render(in: context.cgContext)
        }

        guard let cgImage = image.cgImage else {
            throw SnapshotGuardError.renderingFailed
        }
        return RenderedSnapshot(
            image: image,
            configuration: configuration,
            pixelWidth: cgImage.width,
            pixelHeight: cgImage.height
        )
    }
}
#endif
