import SwiftUI

/// Internal observable state shared between SwiftFlow and its overlay components.
///
/// SwiftFlow creates this object and injects it into the environment so that
/// `Controls`, `MiniMap`, `Background`, and `Panel` can access viewport,
/// node sizes, and other canvas state without explicit prop-drilling.
@MainActor
public class SwiftFlowState: ObservableObject {

  // MARK: - Viewport

  @Published public var viewport: Viewport = .identity
  @Published public var viewSize: CGSize = .zero

  // MARK: - Node Layout

  @Published public var nodeSizes: [String: CGSize] = [:]
  @Published public var absolutePositions: [String: XYPosition] = [:]
  @Published public var handlePositions: [String: CGPoint] = [:]
  @Published public var handleTypes: [String: HandleType] = [:]

  // MARK: - Graph Data (mirrors for overlay components)

  @Published public var nodes: [AnyNodeSnapshot] = []
  @Published public var edges: [AnyEdgeSnapshot] = []

  // MARK: - Connection State

  /// The current in-progress connection drag state, or `nil` when idle.
  @Published public var activeConnection: ConnectionState? = nil

  // MARK: - Connection Queries

  /// O(1) reactive lookup of connections per node.
  /// Maps node IDs to their connections (as source or target).
  @Published public var connectionsMap: [String: [Connection]] = [:]

  // MARK: - Interactivity

  /// Controls whether canvas gestures are currently enabled.
  ///
  /// Overlay components such as `Controls(showInteractive: true)` update this
  /// value, and `SwiftFlow` combines it with its own interaction flags.
  @Published public var isInteractive: Bool = true

  // MARK: - Viewport Mutation

  /// Callback set by SwiftFlow to apply viewport changes from overlay components.
  internal var applyViewport: ((Viewport, Bool) -> Void)?

  /// Requests a viewport change with optional animation.
  public func setViewport(_ vp: Viewport, animated: Bool = true) {
    applyViewport?(vp, animated)
  }

  /// Zooms in by 25%, preserving the center point.
  public func zoomIn(animated: Bool = true) {
    let newZoom = min(viewport.zoom * 1.25, Viewport.maxZoom)
    zoomTo(newZoom, animated: animated)
  }

  /// Zooms out by 25%, preserving the center point.
  public func zoomOut(animated: Bool = true) {
    let newZoom = max(viewport.zoom / 1.25, Viewport.minZoom)
    zoomTo(newZoom, animated: animated)
  }

  /// Sets zoom to a specific level, preserving the center point.
  public func zoomTo(_ zoom: CGFloat, animated: Bool = true) {
    let currentZoom = max(viewport.zoom, Viewport.minZoom)
    let centerX = (viewSize.width / 2 - viewport.x) / currentZoom
    let centerY = (viewSize.height / 2 - viewport.y) / currentZoom
    let z = max(Viewport.minZoom, min(zoom, Viewport.maxZoom))
    let vp = Viewport(
      x: viewSize.width / 2 - centerX * z,
      y: viewSize.height / 2 - centerY * z,
      zoom: z
    )
    setViewport(vp, animated: animated)
  }

  /// Fits all visible nodes into the viewport.
  public func fitView(padding: CGFloat = 80, maxZoom: CGFloat = 1.5, animated: Bool = true) {
    let visibleNodes = nodes.filter { !$0.hidden }
    guard !visibleNodes.isEmpty else { return }

    var minX: CGFloat = .infinity
    var minY: CGFloat = .infinity
    var maxX: CGFloat = -.infinity
    var maxY: CGFloat = -.infinity
    for node in visibleNodes {
      let pos = absolutePositions[node.id] ?? XYPosition(x: node.x, y: node.y)
      let size = nodeSizes[node.id] ?? CGSize(width: 200, height: 100)
      minX = min(minX, pos.x)
      minY = min(minY, pos.y)
      maxX = max(maxX, pos.x + size.width)
      maxY = max(maxY, pos.y + size.height)
    }
    guard minX < .infinity else { return }

    let cw = maxX - minX
    let ch = maxY - minY
    guard cw > 0, ch > 0 else { return }

    let effectiveWidth = max(1, viewSize.width - padding * 2)
    let effectiveHeight = max(1, viewSize.height - padding * 2)
    let z = max(Viewport.minZoom, min(min(effectiveWidth / cw, effectiveHeight / ch), maxZoom))
    let vp = Viewport(x: -(minX * z) + padding, y: -(minY * z) + padding, zoom: z)
    setViewport(vp, animated: animated)
  }

  public init() {}
}

// MARK: - Type-erased node snapshot for overlay components

/// A lightweight, type-erased snapshot of a node for use by overlay components
/// like MiniMap that don't need generic node data.
public struct AnyNodeSnapshot: Identifiable, Equatable, Sendable {
  public let id: String
  public let x: CGFloat
  public let y: CGFloat
  public let selected: Bool
  public let hidden: Bool
  public let type: String

  public init<T: Equatable & Sendable>(from node: Node<T>) {
    self.id = node.id
    self.x = node.position.x
    self.y = node.position.y
    self.selected = node.selected
    self.hidden = node.hidden
    self.type = node.type
  }
}

// MARK: - Type-erased edge snapshot for overlay components

/// A lightweight, type-erased snapshot of an edge for use by overlay components
/// like MiniMap that don't need generic edge data.
public struct AnyEdgeSnapshot: Identifiable, Sendable {
  public let id: String
  public let source: String
  public let target: String
  public let sourceHandle: String?
  public let targetHandle: String?
  public let type: EdgeType
  public let selected: Bool
  public let hidden: Bool
  public let label: String?
  public let animated: Bool
  public let markerStart: EdgeMarker?
  public let markerEnd: EdgeMarker?
  public let zIndex: Int
  public let reconnectable: Bool
  public let deletable: Bool

  public init<EdgeData: Equatable & Sendable & Hashable>(from edge: Edge<EdgeData>) {
    self.id = edge.id
    self.source = edge.source
    self.target = edge.target
    self.sourceHandle = edge.sourceHandle
    self.targetHandle = edge.targetHandle
    self.type = edge.type
    self.selected = edge.selected
    self.hidden = edge.hidden
    self.label = edge.label
    self.animated = edge.animated
    self.markerStart = edge.markerStart
    self.markerEnd = edge.markerEnd
    self.zIndex = edge.zIndex
    self.reconnectable = edge.reconnectable
    self.deletable = edge.deletable
  }
}
