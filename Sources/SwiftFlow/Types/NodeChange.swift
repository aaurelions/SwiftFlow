import Foundation

/// Describes a mutation to a node in the graph.
///
/// Apply changes via `applyNodeChanges(_:nodes:)`.
public enum NodeChange<NodeData: Equatable & Sendable>: Sendable {
  case position(id: String, position: XYPosition)
  case selection(id: String, selected: Bool)
  case remove(id: String)
  case add(item: Node<NodeData>)
  case dimensions(id: String, width: CGFloat, height: CGFloat)
  case replace(id: String, item: Node<NodeData>)
}
