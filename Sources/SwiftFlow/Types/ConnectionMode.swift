import Foundation

/// Controls how connections are validated between handles.
///
/// - `strict`: Connections are only allowed between source and target handles.
/// - `loose`: Connections can be made between any two handles.
public enum ConnectionMode: String, Equatable, Sendable, Codable, Hashable {
    /// Only allows source-to-target connections.
    case strict
    /// Allows connections between any handles.
    case loose
}
