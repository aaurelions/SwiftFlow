import Foundation

/// Specifies whether a handle acts as a connection source or target.
///
/// Unlike inferring from position alone, explicitly setting the type
/// allows handles at any position to function as either source or target.
public enum HandleType: String, Equatable, Sendable, Codable, Hashable {
    case source
    case target
}
