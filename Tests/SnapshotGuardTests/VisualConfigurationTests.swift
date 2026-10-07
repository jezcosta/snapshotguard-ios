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
