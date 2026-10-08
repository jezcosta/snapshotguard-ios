import CoreGraphics
import Testing
@testable import SnapshotGuard

@Suite("DevicePreset")
struct DevicePresetTests {
    struct Expectation: CustomTestStringConvertible {
        var name: String
        var preset: DevicePreset
        var viewport: CGSize
        var scale: CGFloat
        var safeArea: SafeAreaInsets
        var idiom: DeviceIdiom
        var horizontal: SizeClass
        var vertical: SizeClass
        var testDescription: String { name }
    }

    // Written out literally on purpose: these are the documented values of each preset.
    static let expectations = [
        Expectation(
            name: "iPhoneSE", preset: .iPhoneSE,
            viewport: CGSize(width: 375, height: 667), scale: 2,
            safeArea: SafeAreaInsets(top: 20, left: 0, bottom: 0, right: 0),
            idiom: .phone, horizontal: .compact, vertical: .regular
        ),
        Expectation(
            name: "iPhone16Pro", preset: .iPhone16Pro,
            viewport: CGSize(width: 402, height: 874), scale: 3,
            safeArea: SafeAreaInsets(top: 62, left: 0, bottom: 34, right: 0),
            idiom: .phone, horizontal: .compact, vertical: .regular
        ),
        Expectation(
            name: "iPadPro13", preset: .iPadPro13,
            viewport: CGSize(width: 1032, height: 1376), scale: 2,
            safeArea: SafeAreaInsets(top: 32, left: 0, bottom: 25, right: 0),
            idiom: .pad, horizontal: .regular, vertical: .regular
        ),
    ]

    @Test(arguments: expectations)
    func presetHasTheDocumentedValues(_ expected: Expectation) {
        #expect(expected.preset.viewport == expected.viewport)
        #expect(expected.preset.scale == expected.scale)
        #expect(expected.preset.safeAreaInsets == expected.safeArea)
        #expect(expected.preset.idiom == expected.idiom)
        #expect(expected.preset.horizontalSizeClass == expected.horizontal)
        #expect(expected.preset.verticalSizeClass == expected.vertical)
    }

    @Test(arguments: expectations)
    func configurationFromPresetResolvesEveryValue(_ expected: Expectation) {
        let configuration = VisualConfiguration(device: expected.preset)

        #expect(configuration.viewport == expected.viewport)
        #expect(configuration.scale == expected.scale)
        #expect(configuration.safeAreaInsets == expected.safeArea)
        #expect(configuration.idiom == expected.idiom)
        #expect(configuration.horizontalSizeClass == expected.horizontal)
        #expect(configuration.verticalSizeClass == expected.vertical)
    }

    /// `VisualConfiguration(device:)` does not validate; this is what makes that safe.
    @Test(arguments: expectations)
    func everyPresetPassesTheValidationCustomConfigurationsGoThrough(_ expected: Expectation) throws {
        let validated = try VisualConfiguration(
            viewport: expected.preset.viewport,
            scale: expected.preset.scale,
            safeAreaInsets: expected.preset.safeAreaInsets,
            idiom: expected.preset.idiom,
            horizontalSizeClass: expected.preset.horizontalSizeClass,
            verticalSizeClass: expected.preset.verticalSizeClass
        )

        #expect(validated == VisualConfiguration(device: expected.preset))
    }

    @Test func presetsAreDistinct() {
        let presets = Self.expectations.map(\.preset)

        #expect(Set(presets).count == presets.count)
    }

    @Test func customConfigurationsDoNotNeedAPreset() throws {
        let configuration = try VisualConfiguration(viewport: CGSize(width: 500, height: 700), scale: 2)

        #expect(configuration.viewport == CGSize(width: 500, height: 700))
        #expect(configuration.scale == 2)
    }

    @Test func customConfigurationDefaultsAreExplicitAndDoNotDependOnTheViewport() throws {
        let phoneSized = try VisualConfiguration(viewport: CGSize(width: 390, height: 844), scale: 3)
        let padSized = try VisualConfiguration(viewport: CGSize(width: 1024, height: 1366), scale: 2)

        for configuration in [phoneSized, padSized, .default] {
            #expect(configuration.safeAreaInsets == .zero)
            #expect(configuration.idiom == .phone)
            #expect(configuration.horizontalSizeClass == .compact)
            #expect(configuration.verticalSizeClass == .regular)
        }
    }
}
