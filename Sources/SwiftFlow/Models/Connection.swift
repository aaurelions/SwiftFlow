import Foundation

/// Represents a pending connection request between two handles.
///
/// Created during interactive edge drawing and passed to `onConnect`
/// and `isValidConnection` callbacks.
public struct Connection: Equatable, Sendable, Codable, Hashable {
  public var source: String
  public var target: String
  public var sourceHandle: String?
  public var targetHandle: String?

  public init(
    source: String, target: String, sourceHandle: String? = nil, targetHandle: String? = nil
  ) {
    self.source = source
    self.target = target
    self.sourceHandle = sourceHandle
    self.targetHandle = targetHandle
  }
}

/// Type alias for connection validation functions.
public typealias IsValidConnection = (Connection) -> Bool
