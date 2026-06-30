import Foundation

/// Describes the extent constraint for a node's draggable area.
///
/// ReactFlow v12: `node.extent` can be `CoordinateExtent | 'parent' | null`.
/// - `.parent`: Constrains the node within its parent's bounds.
/// - `.coordinateExtent(...)`: Constrains the node within explicit coordinates.
public enum NodeExtent: Equatable, Sendable, Hashable, Codable {
  /// Constrains the node within its parent node's bounds.
  case parent
  /// Constrains the node within explicit coordinate bounds.
  case coordinateExtent(CoordinateExtent)
}
