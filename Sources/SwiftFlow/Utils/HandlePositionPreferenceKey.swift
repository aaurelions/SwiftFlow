import SwiftUI

public struct HandlePositionPreferenceKey: PreferenceKey {
  public static let defaultValue: [String: CGPoint] = [:]

  /// Safe delimiter that won't appear in node or handle IDs.
  static let delimiter = ":::"

  /// Creates a composite key from node, handle type, and handle IDs.
  /// Including the handle type allows source and target handles with the
  /// same id on the same node to coexist without collision.
  public static func makeKey(nodeId: String, handleId: String, type: HandleType? = nil) -> String {
    if let type {
      return "\(nodeId)\(delimiter)\(type.rawValue)\(delimiter)\(handleId)"
    }
    return "\(nodeId)\(delimiter)\(handleId)"
  }

  /// Parses a composite key back into node ID, handle ID, and optional type.
  public static func parseKey(_ key: String) -> (
    nodeId: String, handleId: String, handleType: HandleType?
  )? {
    let parts = key.components(separatedBy: delimiter)
    if parts.count == 3 {
      // nodeId:::type:::handleId
      let handleType = HandleType(rawValue: parts[1])
      return (nodeId: parts[0], handleId: parts[2], handleType: handleType)
    } else if parts.count == 2 {
      // Legacy: nodeId:::handleId
      return (nodeId: parts[0], handleId: parts[1], handleType: nil)
    }
    return nil
  }

  public static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
    value.merge(nextValue()) { current, _ in current }
  }
}
