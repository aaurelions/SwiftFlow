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

/// Canvas theme propagated to handles and overlay components.
private struct SwiftFlowThemeKey: EnvironmentKey {
  static let defaultValue = SwiftFlowTheme.default
}

/// Canvas accessibility strings propagated to handles and overlay components.
private struct SwiftFlowAccessibilityConfigKey: EnvironmentKey {
  static let defaultValue = AccessibilityConfig.default
}

extension EnvironmentValues {
  /// The canvas's `SwiftFlowInstance`, if one was passed to `SwiftFlow`.
  public var swiftFlowInstance: SwiftFlowInstance? {
    get { self[SwiftFlowInstanceKey.self] }
    set { self[SwiftFlowInstanceKey.self] = newValue }
  }

  /// Whether every node has been measured (React Flow's `useNodesInitialized`).
  public var nodesInitialized: Bool {
    get { self[NodesInitializedKey.self] }
    set { self[NodesInitializedKey.self] = newValue }
  }

  var swiftFlowTheme: SwiftFlowTheme {
    get { self[SwiftFlowThemeKey.self] }
    set { self[SwiftFlowThemeKey.self] = newValue }
  }

  var swiftFlowAccessibilityConfig: AccessibilityConfig {
    get { self[SwiftFlowAccessibilityConfigKey.self] }
    set { self[SwiftFlowAccessibilityConfigKey.self] = newValue }
  }

}
