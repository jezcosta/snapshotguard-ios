import CoreGraphics
import Testing
@testable import SnapshotGuard

@Suite("VisualConfiguration")
struct VisualConfigurationTests {
    @Test func storesViewportAndScale() throws {
        let configuration = try VisualConfiguration(viewport: CGSize(width: 393, height: 852), scale: 3)

        #expect(configuration.viewport == CGSize(width: 393, height: 852))
        #expect(configuration.scale == 3)
    }

    @Test func defaultIsAValidConfiguration() throws {
        let rebuilt = try VisualConfiguration(
            viewport: VisualConfiguration.default.viewport,
            scale: VisualConfiguration.default.scale
        )

        #expect(rebuilt == .default)
    }

    @Test(arguments: [
        CGSize(width: 0, height: 100),
        CGSize(width: 100, height: 0),
        CGSize(width: -1, height: 100),
        CGSize(width: 100, height: -1),
        CGSize(width: CGFloat.nan, height: 100),
        CGSize(width: 100, height: CGFloat.nan),
        CGSize(width: CGFloat.infinity, height: 100),
        CGSize(width: 100, height: -CGFloat.infinity),
    ])
    func rejectsInvalidViewport(_ viewport: CGSize) {
        do {
            _ = try VisualConfiguration(viewport: viewport, scale: 2)
            Issue.record("Expected \(viewport) to be rejected")
        } catch SnapshotGuardError.invalidViewport {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(arguments: [0, -1, CGFloat.nan, CGFloat.infinity, -CGFloat.infinity])
    func rejectsInvalidScale(_ scale: CGFloat) {
        do {
            _ = try VisualConfiguration(viewport: CGSize(width: 100, height: 100), scale: scale)
            Issue.record("Expected scale \(scale) to be rejected")
        } catch SnapshotGuardError.invalidScale {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(arguments: [
        SafeAreaInsets(top: -1),
        SafeAreaInsets(left: -0.5),
        SafeAreaInsets(bottom: -10),
        SafeAreaInsets(right: -1),
        SafeAreaInsets(top: .nan),
        SafeAreaInsets(left: .infinity),
        SafeAreaInsets(top: 60, bottom: 40),   // fills the whole 100 pt height
        SafeAreaInsets(left: 50, right: 50),   // fills the whole 100 pt width
        SafeAreaInsets(top: 500),
    ])
    func rejectsInvalidSafeAreaInsets(_ insets: SafeAreaInsets) {
        do {
            _ = try VisualConfiguration(viewport: CGSize(width: 100, height: 100), scale: 2, safeAreaInsets: insets)
            Issue.record("Expected \(insets) to be rejected")
        } catch SnapshotGuardError.invalidSafeAreaInsets {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func acceptsInsetsThatLeaveRoomInsideTheViewport() throws {
        let insets = SafeAreaInsets(top: 49, left: 49, bottom: 49, right: 49)

        let configuration = try VisualConfiguration(viewport: CGSize(width: 100, height: 100), scale: 2, safeAreaInsets: insets)

        #expect(configuration.safeAreaInsets == insets)
    }

    @Test func environmentValuesParticipateInEquality() throws {
        let size = CGSize(width: 320, height: 568)
        let base = try VisualConfiguration(viewport: size, scale: 2)

        #expect(try VisualConfiguration(viewport: size, scale: 2, safeAreaInsets: SafeAreaInsets(top: 1)) != base)
        #expect(try VisualConfiguration(viewport: size, scale: 2, idiom: .pad) != base)
        #expect(try VisualConfiguration(viewport: size, scale: 2, horizontalSizeClass: .regular) != base)
        #expect(try VisualConfiguration(viewport: size, scale: 2, verticalSizeClass: .compact) != base)
    }

    @Test func invalidViewportErrorCarriesTheOffendingValue() {
        let viewport = CGSize(width: 0, height: 10)

        #expect(throws: SnapshotGuardError.invalidViewport(viewport)) {
            try VisualConfiguration(viewport: viewport, scale: 2)
        }
    }

    @Test func equalConfigurationsAreEqualAndHashEqually() throws {
        let a = try VisualConfiguration(viewport: CGSize(width: 320, height: 568), scale: 2)
        let b = try VisualConfiguration(viewport: CGSize(width: 320, height: 568), scale: 2)
        let c = try VisualConfiguration(viewport: CGSize(width: 320, height: 568), scale: 3)

        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(a != c)
        #expect(Set([a, b, c]).count == 2)
    }
}
