import Foundation

/// Returns all visible nodes whose bounding boxes overlap `node`.
///
/// Positions are resolved in flow coordinates (child positions are relative to
/// their parent). Unmeasured nodes use their explicit `width`/`height`, or
/// 150 × 50 points.
public func getIntersectingNodes<T: Equatable & Sendable>(
  node: Node<T>,
  nodes: [Node<T>],
  nodeSizes: [String: CGSize] = [:]
) -> [Node<T>] {
  let positions = nodeTopLeftPositions(nodes: nodes + [node], nodeSizes: nodeSizes)
  let rect = nodeRect(node, positions: positions, nodeSizes: nodeSizes)
  return nodes.filter { other in
    guard other.id != node.id, !other.hidden else { return false }
    return rect.intersects(nodeRect(other, positions: positions, nodeSizes: nodeSizes))
  }
}

/// Returns whether the bounding boxes of two nodes overlap.
public func isNodeIntersecting<T: Equatable & Sendable>(
  node: Node<T>,
  otherNode: Node<T>,
  nodeSizes: [String: CGSize] = [:]
) -> Bool {
  let positions = nodeTopLeftPositions(nodes: [node, otherNode], nodeSizes: nodeSizes)
  return nodeRect(node, positions: positions, nodeSizes: nodeSizes)
    .intersects(nodeRect(otherNode, positions: positions, nodeSizes: nodeSizes))
}

private func nodeRect<T>(
  _ node: Node<T>, positions: [String: XYPosition], nodeSizes: [String: CGSize]
) -> CGRect {
  let topLeft = positions[node.id] ?? node.position
  let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
  return CGRect(x: topLeft.x, y: topLeft.y, width: size.width, height: size.height)
}
