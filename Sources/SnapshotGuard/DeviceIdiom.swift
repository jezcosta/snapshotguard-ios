/// The kind of device a screen is rendered for, as in `UIUserInterfaceIdiom`.
///
/// Only the idioms SnapshotGuard has presets or a use for are listed.
public enum DeviceIdiom: Equatable, Hashable, Sendable {
    case phone
    case pad
}
