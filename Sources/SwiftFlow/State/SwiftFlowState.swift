import SwiftUI

/// Observable canvas state shared between `SwiftFlow` and its overlay components.
///
/// `SwiftFlow` owns this object and injects it into the environment so that
/// `Controls`, `MiniMap`, `Background`, and `EdgeLabelRenderer` can
/// read the viewport, node layout, and connection state without explicit
/// prop drilling. Read it in custom overlays with
/// `@EnvironmentObject var flowState: SwiftFlowState`.
@MainActor
public class SwiftFlowState: ObservableObject {

  // MARK: - Viewport

  @Published public var viewport: Viewport = .identity
  @Published public var viewSize: CGSize = .zero

  // MARK: - Node Layout

  /// Measured node sizes keyed by node ID.
  @Published public var nodeSizes: [String: CGSize] = [:]
  /// Top-left corner of each rendered node in flow coordinates, with parent
  /// offsets and node origins resolved.
  @Published public var absolutePositions: [String: XYPosition] = [:]
  /// Handle centers in flow coordinates, keyed by `HandlePositionPreferenceKey.makeKey`.
  @Published public var handlePositions: [String: CGPoint] = [:]
  /// Handle types keyed like `handlePositions`.
  @Published public var handleTypes: [String: HandleType] = [:]

  // MARK: - Graph Data (snapshots for overlay components)

  @Published public var nodes: [AnyNodeSnapshot] = []
  @Published public var edges: [AnyEdgeSnapshot] = []

  // MARK: - Connection State

  /// The in-progress connection drag, or `nil` when idle
  /// (React Flow's `useConnection`).
  @Published public var activeConnection: ConnectionState? = nil

  /// Connections per node ID, including edges where the node is the source or target.
  @Published public var connectionsMap: [String: [Connection]] = [:]

  // MARK: - Interactivity

  /// Whether canvas gestures are enabled.
  ///
  /// `Controls(showInteractive: true)` toggles this value, and `SwiftFlow`
  /// combines it with its own interaction flags.
  @Published public var isInteractive: Bool = true

  // MARK: - Canvas Configuration (set by SwiftFlow)

  /// Options used when an overlay (such as `Controls`) fits the view.
  internal var fitViewOptions = FitViewOptions()
  /// Posts VoiceOver announcements for selection and connection events.
  internal let announcer = AccessibilityAnnouncer()

  // MARK: - Viewport Mutation

  /// Callback set by SwiftFlow to apply viewport changes from overlay components.
  internal var applyViewport: ((Viewport, Bool) -> Void)?

  /// Requests a viewport change, optionally animated.
  public func setViewport(_ vp: Viewport, animated: Bool = true) {
    applyViewport?(vp, animated)
  }

  /// Zooms in by a factor of 1.2, keeping the center of the view fixed.
  public func zoomIn(animated: Bool = true) {
    zoomTo(viewport.zoom * SwiftFlowInstance.zoomStep, animated: animated)
  }

  /// Zooms out by a factor of 1.2, keeping the center of the view fixed.
  public func zoomOut(animated: Bool = true) {
    zoomTo(viewport.zoom / SwiftFlowInstance.zoomStep, animated: animated)
  }

  /// Sets the zoom level (clamped to the allowed range), keeping the center of the view fixed.
  public func zoomTo(_ zoom: CGFloat, animated: Bool = true) {
    let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
    setViewport(viewport.zoomed(to: zoom, around: center), animated: animated)
  }

  /// Fits all visible nodes into the view.
  public func fitView(padding: CGFloat = 80, maxZoom: CGFloat = 1.5, animated: Bool = true) {
    var options = fitViewOptions
    options.padding = padding
    options.maxZoom = maxZoom
    fitView(options: options, animated: animated)
  }

  /// Fits the nodes selected by `options` into the view.
  internal func fitView(options: FitViewOptions, animated: Bool = true) {
    let idSet = options.nodeIds.map(Set.init)
    var bounds: CGRect?
    for node in nodes
    where (options.includeHiddenNodes || !node.hidden) && (idSet?.contains(node.id) ?? true) {
      let topLeft = absolutePositions[node.id] ?? XYPosition(x: node.x, y: node.y)
      let size = nodeSizes[node.id] ?? defaultNodeSize
      let rect = CGRect(x: topLeft.x, y: topLeft.y, width: size.width, height: size.height)
      bounds = bounds.map { $0.union(rect) } ?? rect
    }
    guard let vp = fitViewport(bounds: bounds, viewSize: viewSize, options: options) else {
      return
    }
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
