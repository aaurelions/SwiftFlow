import Foundation

/// The position of a handle relative to its node.
public enum Position: String, Equatable, Sendable, Codable, Hashable {
  case top
  case bottom
  case left
  case right
}
