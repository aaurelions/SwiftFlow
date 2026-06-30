import SwiftUI

/// Programmatic controller for the canvas viewport and graph state queries.
///
/// Create a `SwiftFlowInstance` and pass it to `SwiftFlow` for imperative
/// control over viewport, nodes, and edges.
///
/// ```swift
/// @StateObject var instance = SwiftFlowInstance()
///
/// SwiftFlow(
///     nodes: nodes, edges: edges,
///     swiftFlowInstance: instance
/// ) { node in ... }
///
/// Button("Fit All") {
///     instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
/// }
/// ```
@MainActor
public class SwiftFlowInstance: ObservableObject {
  @Published public var viewport: Viewport = .identity
  @Published public var viewSize: CGSize = .zero
  @Published public var nodeSizes: [String: CGSize] = [:]

  public var onViewportChange: ((Viewport) -> Void)?

  // MARK: - Internal Closures (set by SwiftFlow)

  internal var _getNodes: (() -> [Any])?
  internal var _getEdges: (() -> [Any])?
  internal var _applyNodeChanges: (([Any]) -> Void)?
  internal var _applyEdgeChanges: (([Any]) -> Void)?

  public init() {}

  // MARK: - Viewport Control

  /// Returns the current viewport.
  public func getViewport() -> Viewport { viewport }

  /// Sets the viewport directly.
  public func setViewport(_ vp: Viewport, animated: Bool = true) {
    apply(vp, duration: animated ? 0.3 : nil)
  }

  /// Adjusts the viewport to frame all (or specific) nodes.
  public func fitView<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize],
    options: FitViewOptions = FitViewOptions()
  ) {
    let targetNodes: [Node<T>]
    if let ids = options.nodeIds {
      let idSet = Set(ids)
      targetNodes = nodes.filter { idSet.contains($0.id) }
    } else {
      targetNodes = options.includeHiddenNodes ? nodes : nodes.filter { !$0.hidden }
    }

    let bounds = computeBounds(
      nodes: targetNodes, nodeSizes: nodeSizes, includeHidden: options.includeHiddenNodes)
    let cw = bounds.maxX - bounds.minX
    let ch = bounds.maxY - bounds.minY
    guard cw > 0, ch > 0 else { return }

    let padding = options.padding
    let effectiveWidth = max(1, viewSize.width - padding * 2)
    let effectiveHeight = max(1, viewSize.height - padding * 2)
    let zoom = max(
      min(min(effectiveWidth / cw, effectiveHeight / ch), options.maxZoom), options.minZoom)

    let vp = Viewport(
      x: -(bounds.minX * zoom) + padding, y: -(bounds.minY * zoom) + padding, zoom: zoom)
    apply(vp, duration: options.duration)
  }

  /// Centers the viewport on a canvas coordinate.
  public func setCenter(x: CGFloat, y: CGFloat, zoom: CGFloat? = nil, animated: Bool = true) {
    let z = zoom ?? viewport.zoom
    apply(
      Viewport(
        x: -x * z + viewSize.width / 2,
        y: -y * z + viewSize.height / 2,
        zoom: z
      ), duration: animated ? 0.3 : nil)
  }

  /// Sets the zoom level, preserving the current center point.
  public func zoomTo(_ zoom: CGFloat, animated: Bool = true) {
    let currentZoom = max(viewport.zoom, Viewport.minZoom)
    let centerX = (viewSize.width / 2 - viewport.x) / currentZoom
    let centerY = (viewSize.height / 2 - viewport.y) / currentZoom
    let z = max(Viewport.minZoom, min(zoom, Viewport.maxZoom))
    apply(
      Viewport(
        x: viewSize.width / 2 - centerX * z,
        y: viewSize.height / 2 - centerY * z,
        zoom: z
      ), duration: animated ? 0.3 : nil)
  }

  /// Zooms in by 25%.
  public func zoomIn(animated: Bool = true) { zoomTo(viewport.zoom * 1.25, animated: animated) }

  /// Zooms out by 25%.
  public func zoomOut(animated: Bool = true) { zoomTo(viewport.zoom / 1.25, animated: animated) }

  /// Resets viewport to origin at 100% zoom.
  public func reset(animated: Bool = true) { apply(.identity, duration: animated ? 0.3 : nil) }

  // MARK: - Coordinate Conversion

  /// Converts a screen-space point to flow (canvas) coordinates.
  public func screenToFlowPosition(_ screenPoint: CGPoint) -> CGPoint {
    let zoom = max(viewport.zoom, Viewport.minZoom)
    return CGPoint(
      x: (screenPoint.x - viewport.x) / zoom,
      y: (screenPoint.y - viewport.y) / zoom
    )
  }

  /// Converts a flow (canvas) coordinate to screen-space point.
  public func flowToScreenPosition(_ flowPoint: CGPoint) -> CGPoint {
    CGPoint(
      x: flowPoint.x * viewport.zoom + viewport.x,
      y: flowPoint.y * viewport.zoom + viewport.y
    )
  }

  // MARK: - Graph State Access

  /// Deletes the specified nodes and edges by ID.
  public func deleteElements(nodeIds: [String] = [], edgeIds: [String] = []) {
    if !edgeIds.isEmpty {
      _applyEdgeChanges?(edgeIds)
    }
  }

  // MARK: - Bounds

  /// Returns bounding box for the given nodes.
  public func getNodesBounds<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize]
  ) -> CGRect {
    let b = computeBounds(nodes: nodes, nodeSizes: nodeSizes, includeHidden: false)
    return CGRect(x: b.minX, y: b.minY, width: b.maxX - b.minX, height: b.maxY - b.minY)
  }

  /// Returns the viewport needed to display the given bounds.
  public func getViewportForBounds(
    bounds: CGRect,
    minZoom: CGFloat = Viewport.minZoom,
    maxZoom: CGFloat = Viewport.maxZoom,
    padding: CGFloat = 80
  ) -> Viewport {
    let cw = max(bounds.width, 1)
    let ch = max(bounds.height, 1)
    let effectiveWidth = max(1, viewSize.width - padding * 2)
    let effectiveHeight = max(1, viewSize.height - padding * 2)
    let zoom = max(min(min(effectiveWidth / cw, effectiveHeight / ch), maxZoom), minZoom)
    return Viewport(
      x: -(bounds.minX * zoom) + padding,
      y: -(bounds.minY * zoom) + padding,
      zoom: zoom
    )
  }

  // MARK: - Private

  private func apply(_ vp: Viewport, duration: TimeInterval?) {
    if let duration, duration > 0 {
      withAnimation(.easeInOut(duration: duration)) { viewport = vp }
    } else {
      viewport = vp
    }
    onViewportChange?(viewport)
  }

  private func computeBounds<T: Equatable & Sendable>(
    nodes: [Node<T>], nodeSizes: [String: CGSize], includeHidden: Bool
  ) -> (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
    let filtered = includeHidden ? nodes : nodes.filter { !$0.hidden }
    guard !filtered.isEmpty else { return (0, 0, 0, 0) }
    var minX: CGFloat = .infinity
    var minY: CGFloat = .infinity
    var maxX: CGFloat = -.infinity
    var maxY: CGFloat = -.infinity
    for node in filtered {
      let size = nodeSizes[node.id] ?? CGSize(width: 200, height: 100)
      minX = min(minX, node.position.x)
      minY = min(minY, node.position.y)
      maxX = max(maxX, node.position.x + size.width)
      maxY = max(maxY, node.position.y + size.height)
    }
    if minX == .infinity { return (0, 0, 0, 0) }
    return (minX, minY, maxX, maxY)
  }
}
