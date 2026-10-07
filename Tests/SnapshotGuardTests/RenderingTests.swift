import Testing
import UIKit
@testable import SnapshotGuard

@MainActor
@Suite("Rendering")
struct RenderingTests {
    private func configuration(_ width: CGFloat, _ height: CGFloat, scale: CGFloat) throws -> VisualConfiguration {
        try VisualConfiguration(viewport: CGSize(width: width, height: height), scale: scale)
    }

    // MARK: UIView

    @Test(arguments: [
        (200 as CGFloat, 100 as CGFloat, 1 as CGFloat),
        (200, 100, 2),
        (393, 852, 3),
        (100.5, 50.5, 2),
    ])
    func viewIsRenderedAtViewportSizeAndScale(width: CGFloat, height: CGFloat, scale: CGFloat) throws {
        let configuration = try configuration(width, height, scale: scale)
        let view = UIView()
        view.backgroundColor = .red

        let snapshot = try SnapshotGuard.render(view, configuration: configuration)

        #expect(snapshot.image.size == CGSize(width: width, height: height))
        #expect(snapshot.image.scale == scale)
        #expect(snapshot.pixelWidth == Int(width * scale))
        #expect(snapshot.pixelHeight == Int(height * scale))
        #expect(snapshot.configuration == configuration)
    }

    @Test func viewFillsTheViewportWhateverItsOwnFrame() throws {
        let view = UIView(frame: CGRect(x: 40, y: 40, width: 10, height: 10))
        view.backgroundColor = .red

        let snapshot = try SnapshotGuard.render(view, configuration: try configuration(120, 80, scale: 2))

        #expect(snapshot.image.pixel(atPointX: 1, y: 1) == .red)
        #expect(snapshot.image.pixel(atPointX: 119, y: 79) == .red)
    }

    @Test func contentIsDrawnWhereItIsLaidOut() throws {
        let view = UIView()
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 100))
        left.backgroundColor = .red
        let right = UIView(frame: CGRect(x: 50, y: 0, width: 50, height: 100))
        right.backgroundColor = .blue
        view.addSubview(left)
        view.addSubview(right)

        let snapshot = try SnapshotGuard.render(view, configuration: try configuration(100, 100, scale: 2))

        #expect(snapshot.image.pixel(atPointX: 10, y: 50) == .red)
        #expect(snapshot.image.pixel(atPointX: 90, y: 50) == .blue)
    }

    @Test func areasWithoutContentAreTransparent() throws {
        let snapshot = try SnapshotGuard.render(UIView(), configuration: try configuration(20, 20, scale: 1))

        #expect(snapshot.image.pixel(atPointX: 10, y: 10) == .clear)
    }

    // MARK: Layout

    @Test func autoLayoutContentIsLaidOutBeforeCapture() throws {
        let root = UIView()
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .green
        let body = UIView()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.backgroundColor = .blue
        root.addSubview(header)
        root.addSubview(body)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 40),
            body.topAnchor.constraint(equalTo: header.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])

        let snapshot = try SnapshotGuard.render(root, configuration: try configuration(100, 200, scale: 2))

        #expect(snapshot.image.pixel(atPointX: 50, y: 20) == .green)
        #expect(snapshot.image.pixel(atPointX: 50, y: 39) == .green)
        #expect(snapshot.image.pixel(atPointX: 50, y: 41) == .blue)
        #expect(snapshot.image.pixel(atPointX: 50, y: 199) == .blue)
    }

    @Test func rootViewUsingAutoLayoutIsSizedToTheViewport() throws {
        let root = UIView()
        root.translatesAutoresizingMaskIntoConstraints = false
        root.backgroundColor = .red

        let snapshot = try SnapshotGuard.render(root, configuration: try configuration(80, 60, scale: 2))

        #expect(snapshot.image.pixel(atPointX: 1, y: 1) == .red)
        #expect(snapshot.image.pixel(atPointX: 79, y: 59) == .red)
    }

    // MARK: UIViewController

    @Test func unpresentedViewControllerIsRendered() throws {
        let controller = ProbeViewController()

        let snapshot = try SnapshotGuard.render(controller, configuration: try configuration(150, 300, scale: 2))

        #expect(snapshot.image.size == CGSize(width: 150, height: 300))
        #expect(controller.didLoadView)
        #expect(controller.didLayoutSubviews)
        #expect(controller.viewSizeAtLastLayout == CGSize(width: 150, height: 300))
        #expect(snapshot.image.pixel(atPointX: 75, y: 10) == .green)
        #expect(snapshot.image.pixel(atPointX: 75, y: 290) == .blue)
    }

    @Test func viewControllerIsDetachedAfterRendering() throws {
        let controller = ProbeViewController()

        _ = try SnapshotGuard.render(controller)

        #expect(controller.view.window == nil)
        #expect(controller.view.superview == nil)
        #expect(controller.parent == nil)
    }

    // MARK: Consumer state

    @Test func renderingDoesNotLeaveTheViewModified() throws {
        let view = UIView(frame: CGRect(x: 7, y: 9, width: 11, height: 13))
        let child = UIView()
        view.addSubview(child)
        let constraintsBefore = view.constraints

        _ = try SnapshotGuard.render(view)

        #expect(view.frame == CGRect(x: 7, y: 9, width: 11, height: 13))
        #expect(view.superview == nil)
        #expect(view.window == nil)
        #expect(view.translatesAutoresizingMaskIntoConstraints)
        #expect(view.constraints == constraintsBefore)
        #expect(view.subviews == [child])
    }

    @Test func autoLayoutRootViewIsRestoredToo() throws {
        let view = UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4))
        view.translatesAutoresizingMaskIntoConstraints = false

        _ = try SnapshotGuard.render(view)

        #expect(view.frame == CGRect(x: 1, y: 2, width: 3, height: 4))
        #expect(!view.translatesAutoresizingMaskIntoConstraints)
        #expect(view.superview == nil)
        #expect(view.constraints.isEmpty)
    }

    @Test func viewAlreadyInAHierarchyIsRejectedAndLeftUntouched() throws {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let view = UIView(frame: CGRect(x: 5, y: 5, width: 10, height: 10))
        parent.addSubview(view)

        #expect(throws: SnapshotGuardError.alreadyInHierarchy) {
            try SnapshotGuard.render(view)
        }
        #expect(view.superview === parent)
        #expect(view.frame == CGRect(x: 5, y: 5, width: 10, height: 10))
    }

    @Test func embeddedViewControllerIsRejected() throws {
        let parent = UIViewController()
        let child = UIViewController()
        parent.addChild(child)
        child.didMove(toParent: parent)

        #expect(throws: SnapshotGuardError.alreadyInHierarchy) {
            try SnapshotGuard.render(child)
        }
    }

    @Test func bitmapThatCannotBeAllocatedFailsAndLeavesTheViewUntouched() throws {
        let configuration = try configuration(100_000_000, 100_000_000, scale: 3)
        let view = UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4))

        #expect(throws: SnapshotGuardError.renderingFailed) {
            try SnapshotGuard.render(view, configuration: configuration)
        }
        #expect(view.superview == nil)
        #expect(view.frame == CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    // MARK: Determinism

    @Test func renderingTwiceProducesTheSameDimensionsAndContent() throws {
        let configuration = try configuration(160, 90, scale: 2)
        let view = UIView()
        let stripe = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 90))
        stripe.backgroundColor = .red
        view.addSubview(stripe)

        let first = try SnapshotGuard.render(view, configuration: configuration)
        let second = try SnapshotGuard.render(view, configuration: configuration)
        let third = try SnapshotGuard.render(view, configuration: configuration)

        for snapshot in [second, third] {
            #expect(snapshot.image.size == first.image.size)
            #expect(snapshot.image.scale == first.image.scale)
            #expect(snapshot.pixelWidth == first.pixelWidth)
            #expect(snapshot.pixelHeight == first.pixelHeight)
            #expect(snapshot.image.pixel(atPointX: 20, y: 45) == .red)
            #expect(snapshot.image.pixel(atPointX: 120, y: 45) == .clear)
        }
    }

    @Test(arguments: [1 as CGFloat, 2, 3])
    func traitEnvironmentFollowsTheConfiguration(scale: CGFloat) throws {
        let probe = TraitProbeView()

        let snapshot = try SnapshotGuard.render(probe, configuration: try configuration(40, 40, scale: scale))

        #expect(probe.displayScaleAtLayout == scale)
        #expect(probe.userInterfaceStyleAtLayout == .light)
        #expect(probe.contentSizeCategoryAtLayout == .large)
        // The dynamic color resolved against those traits is what ends up in the image.
        #expect(snapshot.image.pixel(atPointX: 20, y: 20) == .green)
    }

    @Test func dynamicColorsResolveAgainstTheConfiguredScale() throws {
        let view = UIView()
        view.backgroundColor = UIColor { traits in
            traits.displayScale == 2 ? .red : .blue
        }

        let at2x = try SnapshotGuard.render(view, configuration: try configuration(20, 20, scale: 2))
        let at3x = try SnapshotGuard.render(view, configuration: try configuration(20, 20, scale: 3))

        #expect(at2x.image.pixel(atPointX: 10, y: 10) == .red)
        #expect(at3x.image.pixel(atPointX: 10, y: 10) == .blue)
    }

    @Test func colorsResolvedWhileDrawingUseTheConfiguredTraits() throws {
        let view = DynamicFillView()

        let at2x = try SnapshotGuard.render(view, configuration: try configuration(20, 20, scale: 2))
        let at3x = try SnapshotGuard.render(view, configuration: try configuration(20, 20, scale: 3))

        #expect(at2x.image.pixel(atPointX: 10, y: 10) == .red)
        #expect(at3x.image.pixel(atPointX: 10, y: 10) == .blue)
    }
}

// MARK: - Fixtures

/// A controller with Auto Layout content, recording the callbacks it receives.
@MainActor
private final class ProbeViewController: UIViewController {
    private(set) var didLoadView = false
    private(set) var didLayoutSubviews = false
    private(set) var viewSizeAtLastLayout: CGSize = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        didLoadView = true

        let top = UIView()
        top.translatesAutoresizingMaskIntoConstraints = false
        top.backgroundColor = .green
        let bottom = UIView()
        bottom.translatesAutoresizingMaskIntoConstraints = false
        bottom.backgroundColor = .blue
        view.addSubview(top)
        view.addSubview(bottom)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: view.topAnchor),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            top.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            bottom.topAnchor.constraint(equalTo: top.bottomAnchor),
            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didLayoutSubviews = true
        viewSizeAtLastLayout = view.bounds.size
    }
}

/// A view that records the trait environment it is laid out in, and paints green when it is the
/// one SnapshotGuard promises (light, `large`) via a dynamic color.
@MainActor
private final class TraitProbeView: UIView {
    private(set) var displayScaleAtLayout: CGFloat = 0
    private(set) var userInterfaceStyleAtLayout: UIUserInterfaceStyle = .unspecified
    private(set) var contentSizeCategoryAtLayout: UIContentSizeCategory = .unspecified

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .light ? .green : .red
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        displayScaleAtLayout = traitCollection.displayScale
        userInterfaceStyleAtLayout = traitCollection.userInterfaceStyle
        contentSizeCategoryAtLayout = traitCollection.preferredContentSizeCategory
    }
}

/// Fills itself in `draw(_:)` with a color that is resolved at draw time, against
/// `UITraitCollection.current`.
@MainActor
private final class DynamicFillView: UIView {
    override func draw(_ rect: CGRect) {
        UIColor { traits in traits.displayScale == 2 ? .red : .blue }.setFill()
        UIRectFill(rect)
    }
}
