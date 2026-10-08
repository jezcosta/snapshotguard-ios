import Testing
import UIKit
@testable import SnapshotGuard

/// Rendering against a device environment must not depend on the device or simulator running the
/// tests. Run this suite on an iPhone *and* an iPad simulator: each host is the "wrong" device for
/// some of the presets below, so every case has to hold on both.
@MainActor
@Suite("Device environment")
struct DeviceEnvironmentTests {
    nonisolated static let presets: [DevicePreset] = [.iPhoneSE, .iPhone16Pro, .iPadPro13]

    // MARK: Safe area

    @Test(arguments: presets)
    func safeAreaOfAViewControllerMatchesThePreset(_ preset: DevicePreset) throws {
        let controller = SafeAreaProbeViewController()

        let snapshot = try SnapshotGuard.render(controller, configuration: VisualConfiguration(device: preset))

        let insets = preset.safeAreaInsets
        #expect(controller.safeAreaInsetsAtLayout == UIEdgeInsets(insets))
        #expect(controller.safeAreaFrameAtLayout == CGRect(
            x: insets.left,
            y: insets.top,
            width: preset.viewport.width - insets.left - insets.right,
            height: preset.viewport.height - insets.top - insets.bottom
        ))

        // The bars are pinned to `safeAreaLayoutGuide`, so where they are drawn is the proof.
        let image = snapshot.image
        let centerX = preset.viewport.width / 2
        #expect(image.pixel(atPointX: centerX, y: insets.top + 5) == .green)
        #expect(image.pixel(atPointX: centerX, y: insets.top - 1) == .clear)
        #expect(image.pixel(atPointX: centerX, y: preset.viewport.height - insets.bottom - 5) == .blue)
        #expect(image.pixel(atPointX: centerX, y: preset.viewport.height - insets.bottom - 11) == .clear)
        if insets.bottom > 0 {
            #expect(image.pixel(atPointX: centerX, y: preset.viewport.height - insets.bottom + 1) == .clear)
        }
    }

    @Test(arguments: presets)
    func safeAreaOfAPlainViewMatchesThePreset(_ preset: DevicePreset) throws {
        let view = UIView()
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = .green
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 10),
        ])

        let snapshot = try SnapshotGuard.render(view, configuration: VisualConfiguration(device: preset))

        let top = preset.safeAreaInsets.top
        let centerX = preset.viewport.width / 2
        #expect(snapshot.image.pixel(atPointX: centerX, y: top + 5) == .green)
        #expect(snapshot.image.pixel(atPointX: centerX, y: top - 1) == .clear)
        #expect(snapshot.image.pixel(atPointX: centerX, y: top + 11) == .clear)
    }

    @Test func safeAreaIsTheSameWhenRenderingRepeatedly() throws {
        let configuration = VisualConfiguration(device: .iPhone16Pro)
        let first = SafeAreaProbeViewController()
        let second = SafeAreaProbeViewController()

        _ = try SnapshotGuard.render(first, configuration: configuration)
        _ = try SnapshotGuard.render(second, configuration: configuration)

        #expect(first.safeAreaInsetsAtLayout == second.safeAreaInsetsAtLayout)
        #expect(first.safeAreaInsetsAtLayout == UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0))
    }

    @Test func safeAreaInsetsTheControllerAlreadyHasAreKeptAndRestored() throws {
        let controller = SafeAreaProbeViewController()
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 3)
        let configuration = try VisualConfiguration(
            viewport: CGSize(width: 300, height: 500),
            scale: 2,
            safeAreaInsets: SafeAreaInsets(top: 20)
        )

        _ = try SnapshotGuard.render(controller, configuration: configuration)

        #expect(controller.safeAreaInsetsAtLayout == UIEdgeInsets(top: 25, left: 0, bottom: 0, right: 3))
        #expect(controller.additionalSafeAreaInsets == UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 3))
    }

    // MARK: Size classes and idiom

    @Test(arguments: presets)
    func traitsOfAViewControllerComeFromThePreset(_ preset: DevicePreset) throws {
        let controller = SafeAreaProbeViewController()

        _ = try SnapshotGuard.render(controller, configuration: VisualConfiguration(device: preset))

        #expect(controller.horizontalSizeClassAtLayout == UIUserInterfaceSizeClass(preset.horizontalSizeClass))
        #expect(controller.verticalSizeClassAtLayout == UIUserInterfaceSizeClass(preset.verticalSizeClass))
        #expect(controller.idiomAtLayout == UIUserInterfaceIdiom(preset.idiom))
    }

    @Test(arguments: presets)
    func layoutThatBranchesOnHorizontalSizeClassFollowsThePreset(_ preset: DevicePreset) throws {
        let view = AdaptivePanesView()

        let snapshot = try SnapshotGuard.render(view, configuration: VisualConfiguration(device: preset))

        let size = preset.viewport
        #expect(view.horizontalSizeClassAtLayout == UIUserInterfaceSizeClass(preset.horizontalSizeClass))
        #expect(view.idiomAtLayout == UIUserInterfaceIdiom(preset.idiom))
        switch preset.horizontalSizeClass {
        case .regular:
            // Side by side.
            #expect(snapshot.image.pixel(atPointX: size.width * 0.25, y: size.height / 2) == .red)
            #expect(snapshot.image.pixel(atPointX: size.width * 0.75, y: size.height / 2) == .blue)
        case .compact:
            // Stacked.
            #expect(snapshot.image.pixel(atPointX: size.width / 2, y: size.height * 0.25) == .red)
            #expect(snapshot.image.pixel(atPointX: size.width / 2, y: size.height * 0.75) == .blue)
        }
    }

    // MARK: Independence from the host

    @Test func presetOfTheOppositeDeviceIsNotAffectedByTheHost() throws {
        let hostIdiom = UIDevice.current.userInterfaceIdiom
        let opposite: DevicePreset = hostIdiom == .pad ? .iPhone16Pro : .iPadPro13
        let view = AdaptivePanesView()

        _ = try SnapshotGuard.render(view, configuration: VisualConfiguration(device: opposite))

        #expect(view.idiomAtLayout == UIUserInterfaceIdiom(opposite.idiom))
        #expect(view.idiomAtLayout != hostIdiom)
        #expect(view.horizontalSizeClassAtLayout == UIUserInterfaceSizeClass(opposite.horizontalSizeClass))
    }

    @Test func samePresetProducesTheSameEnvironmentInEveryRender() throws {
        let configuration = VisualConfiguration(device: .iPhone16Pro)

        let snapshots = try (0..<3).map { _ in
            try SnapshotGuard.render(SafeAreaProbeViewController(), configuration: configuration)
        }

        for snapshot in snapshots {
            #expect(snapshot.image.size == CGSize(width: 402, height: 874))
            #expect(snapshot.image.scale == 3)
            #expect(snapshot.pixelWidth == 1206)
            #expect(snapshot.pixelHeight == 2622)
            #expect(snapshot.configuration == configuration)
        }
    }

    // MARK: Custom configurations

    @Test func customEnvironmentIsReproducedToo() throws {
        let configuration = try VisualConfiguration(
            viewport: CGSize(width: 300, height: 500),
            scale: 2,
            safeAreaInsets: SafeAreaInsets(top: 10, left: 4, bottom: 20, right: 6),
            idiom: .pad,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let controller = SafeAreaProbeViewController()

        _ = try SnapshotGuard.render(controller, configuration: configuration)

        #expect(controller.safeAreaInsetsAtLayout == UIEdgeInsets(top: 10, left: 4, bottom: 20, right: 6))
        #expect(controller.safeAreaFrameAtLayout == CGRect(x: 4, y: 10, width: 290, height: 470))
        #expect(controller.idiomAtLayout == .pad)
        #expect(controller.horizontalSizeClassAtLayout == .regular)
        #expect(controller.verticalSizeClassAtLayout == .compact)
    }

    @Test func manualConfigurationWithoutEnvironmentValuesHasNoSafeAreaOnAnyHost() throws {
        let configuration = try VisualConfiguration(viewport: CGSize(width: 402, height: 874), scale: 3)
        let controller = SafeAreaProbeViewController()

        _ = try SnapshotGuard.render(controller, configuration: configuration)

        #expect(controller.safeAreaInsetsAtLayout == .zero)
        #expect(controller.horizontalSizeClassAtLayout == .compact)
        #expect(controller.verticalSizeClassAtLayout == .regular)
        #expect(controller.idiomAtLayout == .phone)
    }

    // MARK: Lifecycle

    @Test func viewControllerSeesAppearanceCallbacksInOrderAndIsLeftDetached() throws {
        let controller = SafeAreaProbeViewController()

        _ = try SnapshotGuard.render(controller, configuration: VisualConfiguration(device: .iPhone16Pro))

        #expect(controller.appearanceEvents == ["willAppear", "didAppear", "willDisappear", "didDisappear"])
        #expect(controller.view.window == nil)
        #expect(controller.view.superview == nil)
    }
}

// MARK: - Fixtures

private extension UIEdgeInsets {
    init(_ insets: SafeAreaInsets) {
        self.init(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
    }
}

private extension UIUserInterfaceSizeClass {
    init(_ sizeClass: SizeClass) {
        self = sizeClass == .compact ? .compact : .regular
    }
}

private extension UIUserInterfaceIdiom {
    init(_ idiom: DeviceIdiom) {
        self = idiom == .phone ? .phone : .pad
    }
}

/// A controller with a green 10 pt bar hanging from the top of the safe area and a blue one
/// resting on its bottom, which records the environment it was laid out in.
@MainActor
private final class SafeAreaProbeViewController: UIViewController {
    private(set) var safeAreaInsetsAtLayout: UIEdgeInsets = .zero
    private(set) var safeAreaFrameAtLayout: CGRect = .zero
    private(set) var horizontalSizeClassAtLayout: UIUserInterfaceSizeClass = .unspecified
    private(set) var verticalSizeClassAtLayout: UIUserInterfaceSizeClass = .unspecified
    private(set) var idiomAtLayout: UIUserInterfaceIdiom = .unspecified
    private(set) var appearanceEvents: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let top = UIView()
        top.translatesAutoresizingMaskIntoConstraints = false
        top.backgroundColor = .green
        let bottom = UIView()
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.backgroundColor = .blue
        view.addSubview(top)
        view.addSubview(bottom)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: guide.topAnchor),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            top.heightAnchor.constraint(equalToConstant: 10),
            bottom.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom.heightAnchor.constraint(equalToConstant: 10),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        safeAreaInsetsAtLayout = view.safeAreaInsets
        safeAreaFrameAtLayout = view.safeAreaLayoutGuide.layoutFrame
        horizontalSizeClassAtLayout = traitCollection.horizontalSizeClass
        verticalSizeClassAtLayout = traitCollection.verticalSizeClass
        idiomAtLayout = traitCollection.userInterfaceIdiom
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); appearanceEvents.append("willAppear") }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); appearanceEvents.append("didAppear") }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); appearanceEvents.append("willDisappear") }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); appearanceEvents.append("didDisappear") }
}

/// Two panes — red, then blue — arranged side by side in a regular width and stacked otherwise.
@MainActor
private final class AdaptivePanesView: UIView {
    private let first = UIView()
    private let second = UIView()
    private(set) var horizontalSizeClassAtLayout: UIUserInterfaceSizeClass = .unspecified
    private(set) var idiomAtLayout: UIUserInterfaceIdiom = .unspecified

    override init(frame: CGRect) {
        super.init(frame: frame)
        first.backgroundColor = .red
        second.backgroundColor = .blue
        addSubview(first)
        addSubview(second)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        horizontalSizeClassAtLayout = traitCollection.horizontalSizeClass
        idiomAtLayout = traitCollection.userInterfaceIdiom
        let b = bounds
        if traitCollection.horizontalSizeClass == .regular {
            first.frame = CGRect(x: 0, y: 0, width: b.width / 2, height: b.height)
            second.frame = CGRect(x: b.width / 2, y: 0, width: b.width / 2, height: b.height)
        } else {
            first.frame = CGRect(x: 0, y: 0, width: b.width, height: b.height / 2)
            second.frame = CGRect(x: 0, y: b.height / 2, width: b.width, height: b.height / 2)
        }
    }
}
