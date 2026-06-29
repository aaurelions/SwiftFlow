import Foundation

/// Controls how the selection box determines which nodes are selected.
///
/// - `partial`: Nodes are selected if the selection box partially overlaps them.
/// - `full`: Nodes are selected only if fully contained within the selection box.
public enum SelectionMode: String, Equatable, Sendable, Codable, Hashable {
    case partial
    case full
}
