import SwiftUI

/// Imperative access to a `SwiftFlow` canvas, the counterpart of React Flow's
/// `ReactFlowInstance` (`useReactFlow`).
///
/// Create an instance, pass it to `SwiftFlow`, and use it to control the
/// viewport, convert coordinates, or delete elements.
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
///
/// Nested views can read the instance with `@Environment(\.swiftFlowInstance)`.
@MainActor
public class SwiftFlowInstance: ObservableObject {
  /// The current viewport, kept in sync with the canvas.
  @Published public var viewport: Viewport = .identity
  /// The size of the canvas view in points.
  @Published public var viewSize: CGSize = .zero
  /// Measured node sizes keyed by node ID.
  @Published public var nodeSizes: [String: CGSize] = [:]

  /// Called after each viewport change requested through this instance.
  public var onViewportChange: ((Viewport) -> Void)?

  // MARK: - Canvas Bindings (set by SwiftFlow)

  internal var _applyViewport: ((Viewport) -> Void)?
  internal var _deleteElements: (([String], [String]) -> Void)?

  /// Default animation duration for viewport commands, in seconds.
  private static let animationDuration: TimeInterval = 0.3
  /// Zoom step used by `zoomIn` and `zoomOut` (React Flow uses 1.2).
  static let zoomStep: CGFloat = 1.2

  public init() {}

  // MARK: - Viewport Control

  /// Returns the current viewport.
  public func getViewport() -> Viewport { viewport }

  /// Sets the viewport.
  public func setViewport(_ vp: Viewport, animated: Bool = true) {
    apply(vp, duration: animated ? Self.animationDuration : nil)
  }

  /// Adjusts the viewport so that all visible nodes (or `options.nodeIds`) fit in the view.
  ///
  /// Child positions are resolved relative to their parent nodes.
  public func fitView<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize],
    options: FitViewOptions = FitViewOptions()
  ) {
    let positions = nodeTopLeftPositions(nodes: nodes, nodeSizes: nodeSizes)
    let idSet = options.nodeIds.map(Set.init)
    let targets = nodes.filter {
      (options.includeHiddenNodes || !$0.hidden) && (idSet?.contains($0.id) ?? true)
    }
    let bounds = nodesBoundingRect(
      nodes: targets, topLeftPositions: positions, nodeSizes: nodeSizes)
    guard let vp = fitViewport(bounds: bounds, viewSize: viewSize, options: options) else {
      return
    }
    apply(vp, duration: options.duration)
  }

  /// Centers the viewport on a flow coordinate.
  ///
  /// - Parameter zoom: The new zoom level; the current zoom is kept when `nil`.
  public func setCenter(x: CGFloat, y: CGFloat, zoom: CGFloat? = nil, animated: Bool = true) {
    let vp = Viewport.centered(
      on: CGPoint(x: x, y: y), zoom: zoom ?? viewport.zoom, viewSize: viewSize)
    apply(vp, duration: animated ? Self.animationDuration : nil)
  }

  /// Sets the zoom level, keeping the center of the view fixed.
  public func zoomTo(_ zoom: CGFloat, animated: Bool = true) {
    let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
    apply(
      viewport.zoomed(to: zoom, around: center),
      duration: animated ? Self.animationDuration : nil)
  }

  /// Zooms in by a factor of 1.2.
  public func zoomIn(animated: Bool = true) {
    zoomTo(viewport.zoom * Self.zoomStep, animated: animated)
  }

  /// Zooms out by a factor of 1.2.
  public func zoomOut(animated: Bool = true) {
    zoomTo(viewport.zoom / Self.zoomStep, animated: animated)
  }

  /// Resets the viewport to the origin at 100% zoom.
  public func reset(animated: Bool = true) {
    apply(.identity, duration: animated ? Self.animationDuration : nil)
  }

  // MARK: - Coordinate Conversion

  /// Converts a point in the canvas view's coordinate space to flow coordinates.
  public func screenToFlowPosition(_ screenPoint: CGPoint) -> CGPoint {
    let zoom = max(viewport.zoom, Viewport.minZoom)
    return CGPoint(
      x: (screenPoint.x - viewport.x) / zoom,
      y: (screenPoint.y - viewport.y) / zoom
    )
  }

  /// Converts a flow coordinate to the canvas view's coordinate space.
  public func flowToScreenPosition(_ flowPoint: CGPoint) -> CGPoint {
    CGPoint(
      x: flowPoint.x * viewport.zoom + viewport.x,
      y: flowPoint.y * viewport.zoom + viewport.y
    )
  }

  // MARK: - Graph Mutation

  /// Deletes nodes and edges by ID through the canvas.
  ///
  /// The canvas applies the same rules as keyboard deletion: non-deletable
  /// elements are skipped, children of deleted nodes and connected edges are
  /// removed, and `onBeforeDelete` can cancel or filter the request.
  public func deleteElements(nodeIds: [String] = [], edgeIds: [String] = []) {
    _deleteElements?(nodeIds, edgeIds)
  }

  // MARK: - Bounds

  /// Returns the bounding box of the given visible nodes in flow coordinates.
  public func getNodesBounds<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize]
  ) -> CGRect {
    visibleNodesBounds(nodes: nodes, nodeSizes: nodeSizes)
  }

  /// Returns the viewport that centers `bounds` within the current view size.
  public func getViewportForBounds(
    bounds: CGRect,
    minZoom: CGFloat = Viewport.minZoom,
    maxZoom: CGFloat = Viewport.maxZoom,
    padding: CGFloat = 80
  ) -> Viewport {
    fittedViewport(
      fitting: bounds, in: viewSize, minZoom: minZoom, maxZoom: maxZoom, padding: padding)
  }

  // MARK: - Private

  private func apply(_ vp: Viewport, duration: TimeInterval?) {
    if let duration, duration > 0 {
      withAnimation(.easeInOut(duration: duration)) {
        viewport = vp
        _applyViewport?(vp)
      }
    } else {
      viewport = vp
      _applyViewport?(vp)
    }
    onViewportChange?(viewport)
  }
}
