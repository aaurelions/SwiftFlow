import Foundation

/// Controls how z-index values are managed for nodes and edges.
///
/// - `auto`: Automatically adjusts z-index for selections and sub-flows.
/// - `basic`: Only manages z-index for selections (selected nodes come to front).
/// - `manual`: No automatic z-indexing; all values are user-controlled.
public enum ZIndexMode: String, Equatable, Sendable, Codable, Hashable {
  case auto
  case basic
  case manual
}
