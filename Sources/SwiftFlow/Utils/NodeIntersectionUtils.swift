import Foundation

/// Returns all nodes whose bounding boxes overlap with the given node.
public func getIntersectingNodes<T: Equatable & Sendable>(
    node: Node<T>,
    nodes: [Node<T>],
    nodeSizes: [String: CGSize] = [:]
) -> [Node<T>] {
    let rect = nodeRect(node, nodeSizes: nodeSizes)
    return nodes.filter { other in
        guard other.id != node.id, !other.hidden else { return false }
        return rect.intersects(nodeRect(other, nodeSizes: nodeSizes))
    }
}

/// Returns whether two nodes' bounding boxes overlap.
public func isNodeIntersecting<T: Equatable & Sendable>(
    node: Node<T>,
    otherNode: Node<T>,
    nodeSizes: [String: CGSize] = [:]
) -> Bool {
    nodeRect(node, nodeSizes: nodeSizes).intersects(nodeRect(otherNode, nodeSizes: nodeSizes))
}

private func nodeRect<T: Equatable & Sendable>(_ node: Node<T>, nodeSizes: [String: CGSize]) -> CGRect {
    let size = nodeSizes[node.id] ?? CGSize(width: 150, height: 50)
    return CGRect(
        x: node.position.x, y: node.position.y,
        width: node.width ?? size.width,
        height: node.height ?? size.height
    )
}
