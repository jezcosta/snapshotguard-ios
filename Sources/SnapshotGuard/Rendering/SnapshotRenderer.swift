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

        let window = OffscreenWindow.make(for: configuration)
        let originalFrame = view.frame
        let translatesAutoresizingMask = view.translatesAutoresizingMaskIntoConstraints
        var pinConstraints: [NSLayoutConstraint] = []

        window.addSubview(view)
        defer {
            NSLayoutConstraint.deactivate(pinConstraints)
            view.removeFromSuperview()
            view.translatesAutoresizingMaskIntoConstraints = translatesAutoresizingMask
            view.frame = originalFrame
        }

        if translatesAutoresizingMask {
            view.frame = window.bounds
        } else {
            pinConstraints = [
                view.topAnchor.constraint(equalTo: window.topAnchor),
                view.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                view.trailingAnchor.constraint(equalTo: window.trailingAnchor)
            ]
            NSLayoutConstraint.activate(pinConstraints)
        }

        return try capture(view, in: window, configuration: configuration)
    }

    @MainActor
    static func render(_ viewController: UIViewController, configuration: VisualConfiguration) throws -> RenderedSnapshot {
        guard viewController.parent == nil,
              viewController.presentingViewController == nil,
              viewController.viewIfLoaded?.superview == nil,
              viewController.viewIfLoaded?.window == nil else {
            throw SnapshotGuardError.alreadyInHierarchy
        }

        let window = OffscreenWindow.make(for: configuration)
        window.rootViewController = viewController
        defer { window.rootViewController = nil }

        return try capture(viewController.view, in: window, configuration: configuration)
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
