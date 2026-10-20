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

/// Resolves the elements removed by a deletion request (React Flow's
/// `getElementsToRemove`).
///
/// - Deletable requested nodes are removed together with their deletable
///   descendants (nodes whose `parentId` chain leads to a removed node).
/// - Every edge connected to a removed node is removed, so deletions never
///   leave dangling connections.
/// - Requested edges are removed when they are deletable.
internal func elementsToDelete<N: Equatable & Sendable, E: Equatable & Sendable & Hashable>(
  nodes: [Node<N>], edges: [Edge<E>], nodeIds: [String], edgeIds: [String]
) -> (nodes: [Node<N>], edges: [Edge<E>]) {
  let requestedNodes = Set(nodeIds)
  let requestedEdges = Set(edgeIds)
  var deletedIds = Set(nodes.filter { requestedNodes.contains($0.id) && $0.deletable }.map(\.id))
  // Cascade to descendants until no more children are found.
  var foundChildren = true
  while foundChildren {
    foundChildren = false
    for node in nodes where node.deletable && !deletedIds.contains(node.id) {
      if let parentId = node.parentId, deletedIds.contains(parentId) {
        deletedIds.insert(node.id)
        foundChildren = true
      }
    }
  }
  let deletedNodes = nodes.filter { deletedIds.contains($0.id) }
  let deletedEdges = edges.filter {
    (requestedEdges.contains($0.id) && $0.deletable)
      || deletedIds.contains($0.source) || deletedIds.contains($0.target)
  }
  return (deletedNodes, deletedEdges)
}
