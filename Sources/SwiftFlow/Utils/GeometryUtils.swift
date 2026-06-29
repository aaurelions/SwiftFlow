import Foundation

/// Type alias for bounding box rectangles.
public typealias Rect = CGRect

/// Returns the bounding box containing all visible nodes.
public func getNodesBounds<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize]
) -> CGRect {
    let visible = nodes.filter { !$0.hidden }
    guard !visible.isEmpty else { return .zero }

    var minX: CGFloat = .infinity
    var minY: CGFloat = .infinity
    var maxX: CGFloat = -.infinity
    var maxY: CGFloat = -.infinity
    for node in visible {
        let size = nodeSizes[node.id] ?? CGSize(width: 200, height: 100)
        minX = min(minX, node.position.x)
        minY = min(minY, node.position.y)
        maxX = max(maxX, node.position.x + size.width)
        maxY = max(maxY, node.position.y + size.height)
    }
    if minX == .infinity { return .zero }
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

/// Returns the viewport needed to display the given bounds within a viewport size.
public func getViewportForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    minZoom: CGFloat = Viewport.minZoom,
    maxZoom: CGFloat = Viewport.maxZoom,
    padding: CGFloat = 80
) -> Viewport {
    let cw = max(bounds.width, 1)
    let ch = max(bounds.height, 1)
    let effectiveWidth = max(1, viewportSize.width - padding * 2)
    let effectiveHeight = max(1, viewportSize.height - padding * 2)
    let zoom = max(min(min(effectiveWidth / cw, effectiveHeight / ch), maxZoom), minZoom)
    return Viewport(
        x: -(bounds.minX * zoom) + padding,
        y: -(bounds.minY * zoom) + padding,
        zoom: zoom
    )
}

/// Type-check utility: returns true if the value is a Node.
public func isNode<T: Equatable & Sendable>(_ element: Any, ofType: T.Type = T.self) -> Bool {
    element is Node<T>
}

/// Type-check utility: returns true if the value is an Edge.
public func isEdge<EdgeData: Equatable & Sendable & Hashable>(
    _ element: Any,
    ofType: EdgeData.Type
) -> Bool {
    element is Edge<EdgeData>
}
