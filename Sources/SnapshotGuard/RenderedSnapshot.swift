#if canImport(UIKit)
import UIKit

/// The image produced by rendering a screen, together with how it was produced.
///
/// A snapshot is the artifact later stages of SnapshotGuard (baselines, comparison, diffs and
/// reports) will consume, so it keeps the configuration alongside the pixels.
public struct RenderedSnapshot: Sendable {
    /// The rendered image. Its `size` equals the configuration's viewport and its `scale` the
    /// configuration's scale.
    public let image: UIImage

    /// The configuration the image was rendered with.
    public let configuration: VisualConfiguration

    /// The width of the image in pixels.
    public let pixelWidth: Int

    /// The height of the image in pixels.
    public let pixelHeight: Int

    init(image: UIImage, configuration: VisualConfiguration, pixelWidth: Int, pixelHeight: Int) {
        self.image = image
        self.configuration = configuration
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
#endif
