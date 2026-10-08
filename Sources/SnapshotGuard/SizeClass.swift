/// A size class, as in `UIUserInterfaceSizeClass`.
///
/// `UIKit` also has an `unspecified` value; it is deliberately absent here because a rendering
/// environment always has a definite size class.
public enum SizeClass: Equatable, Hashable, Sendable {
    case compact
    case regular
}
