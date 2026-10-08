#if canImport(UIKit)
import UIKit

/// The offscreen window content is hosted in while it is rendered.
///
/// A window is what gives views a trait environment, so it is also where everything the
/// configuration controls — or that would otherwise leak in from the device — is pinned.
///
/// The window is shown for the lifetime of the object. UIKit ignores `additionalSafeAreaInsets` and
/// leaves size classes unspecified for views in a hidden window, so a hidden one cannot reproduce a
/// device. It is never made key, is not attached to a scene, and is hidden again by ``tearDown()``
/// before the render returns, i.e. before the run loop could composite it.
@MainActor
final class OffscreenWindow {
    let window: UIWindow
    private let configuration: VisualConfiguration
    private var installed: (controller: UIViewController, additionalSafeAreaInsets: UIEdgeInsets)?

    init(configuration: VisualConfiguration) {
        self.configuration = configuration
        window = UIWindow(frame: CGRect(origin: .zero, size: configuration.viewport))

        window.traitOverrides.displayScale = configuration.scale
        window.traitOverrides.userInterfaceIdiom = UIUserInterfaceIdiom(configuration.idiom)
        window.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClass(configuration.horizontalSizeClass)
        window.traitOverrides.verticalSizeClass = UIUserInterfaceSizeClass(configuration.verticalSizeClass)
        // Not yet part of VisualConfiguration. Pinned so results do not depend on the
        // appearance or text size selected on the device or simulator that happens to run them.
        window.traitOverrides.userInterfaceStyle = .light
        window.traitOverrides.preferredContentSizeCategory = .large

        window.isHidden = false
    }

    /// Makes `viewController` the root of the window and gives it the configuration's safe area.
    ///
    /// Once visible, a window inherits the safe area of the screen it happens to be on, which is
    /// what the host device reports. That inherited value is read back and cancelled out with
    /// `additionalSafeAreaInsets`, so the controller sees exactly the configured insets on any
    /// device. Insets the controller already had in `additionalSafeAreaInsets` are kept on top.
    func install(_ viewController: UIViewController) {
        let original = viewController.additionalSafeAreaInsets
        installed = (viewController, original)

        window.rootViewController = viewController

        let inherited = window.safeAreaInsets
        let target = configuration.safeAreaInsets
        viewController.additionalSafeAreaInsets = UIEdgeInsets(
            top: original.top + target.top - inherited.top,
            left: original.left + target.left - inherited.left,
            bottom: original.bottom + target.bottom - inherited.bottom,
            right: original.right + target.right - inherited.right
        )
    }

    /// Detaches the controller, restores what was changed on it, and hides the window.
    func tearDown() {
        window.rootViewController = nil
        if let installed {
            installed.controller.additionalSafeAreaInsets = installed.additionalSafeAreaInsets
            self.installed = nil
        }
        window.isHidden = true
    }
}

extension UIUserInterfaceIdiom {
    fileprivate init(_ idiom: DeviceIdiom) {
        switch idiom {
        case .phone: self = .phone
        case .pad: self = .pad
        }
    }
}

extension UIUserInterfaceSizeClass {
    fileprivate init(_ sizeClass: SizeClass) {
        switch sizeClass {
        case .compact: self = .compact
        case .regular: self = .regular
        }
    }
}
#endif
