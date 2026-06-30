import SwiftUI

/// Environment key for accessing a `SwiftFlowInstance` from deeply nested views.
///
/// ```swift
/// @Environment(\.swiftFlowInstance) var instance
/// ```
private struct SwiftFlowInstanceKey: EnvironmentKey {
  static let defaultValue: SwiftFlowInstance? = nil
}

/// Environment key indicating whether all nodes have been measured.
///
/// ```swift
/// @Environment(\.nodesInitialized) var nodesInitialized
/// ```
private struct NodesInitializedKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  public var swiftFlowInstance: SwiftFlowInstance? {
    get { self[SwiftFlowInstanceKey.self] }
    set { self[SwiftFlowInstanceKey.self] = newValue }
  }

  public var nodesInitialized: Bool {
    get { self[NodesInitializedKey.self] }
    set { self[NodesInitializedKey.self] = newValue }
  }
}
