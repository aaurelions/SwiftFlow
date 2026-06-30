import Foundation

/// Returns nodes that have edges pointing to the given node (predecessors).
public func getIncomers<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
  node: Node<NodeData>,
  nodes: [Node<NodeData>],
  edges: [Edge<EdgeData>]
) -> [Node<NodeData>] {
  let sourceIds = Set(edges.filter { $0.target == node.id }.map(\.source))
  return nodes.filter { sourceIds.contains($0.id) }
}

/// Returns nodes that the given node has edges pointing to (successors).
public func getOutgoers<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
  node: Node<NodeData>,
  nodes: [Node<NodeData>],
  edges: [Edge<EdgeData>]
) -> [Node<NodeData>] {
  let targetIds = Set(edges.filter { $0.source == node.id }.map(\.target))
  return nodes.filter { targetIds.contains($0.id) }
}

/// Returns all edges connected to the given node (as source or target).
public func getConnectedEdges<
  NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable
>(
  node: Node<NodeData>,
  edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>] {
  edges.filter { $0.source == node.id || $0.target == node.id }
}

/// Returns all edges connected to any of the given nodes.
public func getConnectedEdges<
  NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable
>(
  nodes: [Node<NodeData>],
  edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>] {
  let nodeIds = Set(nodes.map(\.id))
  return edges.filter { nodeIds.contains($0.source) || nodeIds.contains($0.target) }
}
