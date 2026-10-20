import SwiftUI

// MARK: - SwiftFlow

/// The main interactive canvas for rendering and editing node graphs.
///
/// `SwiftFlow` renders nodes and edges, manages panning, zooming, selection,
/// connection drawing, and keyboard shortcuts. It accepts two `@ViewBuilder`
/// closures: one for rendering nodes, and one for composable overlay components
/// like `Controls`, `MiniMap`, `Background`, and `Panel`.
///
/// ```swift
/// SwiftFlow(
///     nodes: nodes,
///     edges: edges,
///     onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
///     onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
///     onConnect: { edges = addEdge($0, edges: edges) }
/// ) { node in
///     MyNodeView(node: node)
/// } overlay: {
///     Background(variant: .dots)
///     Controls()
///     MiniMap()
/// }
/// ```
public struct SwiftFlow<
  NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable, NodeContent: View,
  Overlay: View
>: View {

  // MARK: - Core Data

  /// Nodes to render. The canvas never mutates them; it reports edits through `onNodesChange`.
  public var nodes: [Node<NodeData>]
  /// Edges to render. The canvas reports edits through `onEdgesChange`.
  public var edges: [Edge<EdgeData>]

  // MARK: - Change Callbacks

  /// Receives node changes (drag, selection, removal, ...). Apply them with `applyNodeChanges`.
  public var onNodesChange: (([NodeChange<NodeData>]) -> Void)?
  /// Receives edge changes. Apply them with `applyEdgeChanges`.
  public var onEdgesChange: (([EdgeChange<EdgeData>]) -> Void)?
  /// Called when the user connects two handles. Add the edge with `addEdge`.
  public var onConnect: ((Connection) -> Void)?

  // MARK: - Interaction Props

  /// Whether nodes can be dragged. A node can also opt out with `Node.draggable`.
  public var nodesDraggable: Bool
  /// Whether handles accept new connections and edges can be reconnected.
  public var nodesConnectable: Bool
  /// Whether nodes and edges can be selected by tap, selection box, and keyboard.
  public var elementsSelectable: Bool
  /// Whether dragging the empty pane pans the viewport.
  public var panOnDrag: Bool
  /// Whether scrolling pans instead of zooming (macOS).
  public var panOnScroll: Bool
  /// Axis restriction for `panOnScroll`.
  public var panOnScrollMode: PanOnScrollMode
  /// Whether scrolling zooms around the pointer (macOS).
  public var zoomOnScroll: Bool
  /// Whether pinch gestures zoom.
  public var zoomOnPinch: Bool
  /// Whether double-tapping the pane zooms in by a factor of 2.
  public var zoomOnDoubleClick: Bool
  /// When `true`, dragging the pane draws a selection box (Shift+drag pans). When `false`,
  /// Shift+drag draws it.
  public var selectionOnDrag: Bool
  /// Whether dragging an unselected node selects it.
  public var selectNodesOnDrag: Bool
  /// Whether the selection box selects partially covered nodes or only fully covered ones.
  public var selectionMode: SelectionMode
  /// `.strict` connects sources to targets only; `.loose` also allows source↔source and
  /// target↔target.
  public var connectionMode: ConnectionMode
  /// Path type of the line drawn while connecting.
  public var connectionLineType: EdgeType

  // MARK: - Appearance

  /// Built-in grid drawn with the theme's `gridColor` and `gridSpacing`. Prefer a `Background`
  /// overlay for more control.
  public var backgroundVariant: BackgroundVariant?
  /// Whether dragged node positions snap to `snapGrid`.
  public var snapToGrid: Bool
  /// Grid used by `snapToGrid`, in flow points.
  public var snapGrid: (x: CGFloat, y: CGFloat)
  /// Visual theme for edges, handles, selection, and canvas chrome.
  public var theme: SwiftFlowTheme
  /// Canvas background color scheme used when the theme's `canvasBackgroundColor` is `.clear`.
  public var colorMode: ColorMode
  /// How selected nodes are elevated: `.basic` and `.auto` raise them; `.manual` uses `zIndex`
  /// only.
  public var zIndexMode: ZIndexMode
  /// Anchor of `Node.position` within the node for nodes that keep the default `origin`.
  public var nodeOrigin: NodeOrigin

  // MARK: - Constraints

  /// Bounds that dragged nodes cannot leave. Content outside is clipped.
  public var coordinateExtent: CoordinateExtent
  /// Whether to fit the view once all nodes are measured.
  public var fitView: Bool
  /// Options for the initial `fitView` and the `Controls` fit button.
  public var fitViewOptions: FitViewOptions?
  /// Defaults merged into rendered edges (see `DefaultEdgeOptions`).
  public var defaultEdgeOptions: DefaultEdgeOptions?
  /// Key codes and nudge distances for keyboard interaction (macOS).
  public var keyboardShortcuts: KeyboardShortcuts
  /// Accessibility labels and descriptions for canvas elements and overlays.
  public var accessibilityConfig: AccessibilityConfig

  // MARK: - Event Callbacks

  /// Called when the empty pane is tapped.
  public var onPaneClick: (() -> Void)?
  /// Called whenever the viewport changes.
  public var onViewportChange: ((Viewport) -> Void)?
  /// Called with the selected nodes and edges whenever the selection changes.
  public var onSelectionChange: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?
  /// Return `false` to reject a connection before `onConnect`/`onReconnect`.
  public var isValidConnection: ((Connection) -> Bool)?
  public var onNodeDragStart: ((Node<NodeData>) -> Void)?
  public var onNodeDrag: ((Node<NodeData>) -> Void)?
  public var onNodeDragStop: ((Node<NodeData>) -> Void)?
  public var onConnectStart: ((OnConnectStartParams) -> Void)?
  public var onConnectEnd: (() -> Void)?
  /// Called before deletion; return `.cancel`, a filtered `.delete(nodes:edges:)`, or `nil` to
  /// proceed.
  public var onBeforeDelete:
    (([Node<NodeData>], [Edge<EdgeData>]) async -> BeforeDeleteResult<NodeData, EdgeData>?)?
  public var onNodesDelete: (([Node<NodeData>]) -> Void)?
  public var onEdgesDelete: (([Edge<EdgeData>]) -> Void)?
  public var onNodeClick: ((Node<NodeData>) -> Void)?
  public var onNodeDoubleClick: ((Node<NodeData>) -> Void)?
  public var onEdgeClick: ((Edge<EdgeData>) -> Void)?
  public var onEdgeDoubleClick: ((Edge<EdgeData>) -> Void)?
  /// Called when a selected, reconnectable edge endpoint is dropped on a handle. Reconnect anchors
  /// are shown only when this is set. Update the edge with `reconnectEdge`.
  public var onReconnect: ((Edge<EdgeData>, Connection) -> Void)?
  public var onMoveStart: ((Viewport) -> Void)?
  public var onMove: ((Viewport) -> Void)?
  public var onMoveEnd: ((Viewport) -> Void)?
  public var onInit: (() -> Void)?
  /// Called with an error code and message, for example `CYCLE_DETECTED` for cyclic `parentId`
  /// chains.
  public var onError: ((String, String) -> Void)?
  /// Custom view for the in-progress connection line, given the connection and its start and end
  /// points.
  public var connectionLineContent: ((Connection, CGPoint, CGPoint) -> AnyView)?
  /// Instance to bind for imperative control (`fitView`, `setViewport`, `deleteElements`, ...).
  public var swiftFlowInstance: SwiftFlowInstance?

  // MARK: - Hover Events (macOS only)

  public var onNodeMouseEnter: ((Node<NodeData>) -> Void)?
  public var onNodeMouseLeave: ((Node<NodeData>) -> Void)?
  public var onEdgeMouseEnter: ((Edge<EdgeData>) -> Void)?
  public var onEdgeMouseLeave: ((Edge<EdgeData>) -> Void)?

  // MARK: - Context Menu Events

  public var onNodeContextMenu: ((Node<NodeData>) -> Void)?
  public var onEdgeContextMenu: ((Edge<EdgeData>) -> Void)?
  public var onPaneContextMenu: (() -> Void)?

  // MARK: - Selection Drag Events

  public var onSelectionDragStart: (([Node<NodeData>]) -> Void)?
  public var onSelectionDrag: (([Node<NodeData>]) -> Void)?
  public var onSelectionDragStop: (([Node<NodeData>]) -> Void)?

  // MARK: - Delete Event

  /// Called after nodes and/or edges were deleted.
  public var onDelete: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?

  // MARK: - Custom Edge Content

  /// Custom edge rendering. The canvas still draws markers, labels, and the hit area.
  public var edgeContent: ((Edge<EdgeData>, EdgePathResult) -> AnyView)?

  // MARK: - Content Builders

  @ViewBuilder public var nodeContent: (Node<NodeData>) -> NodeContent
  @ViewBuilder public var overlay: () -> Overlay

  // MARK: - Internal State
  //
  // Internal (not private) so the rendering, gesture, and action extensions in
  // the sibling `SwiftFlow+*.swift` files can access them.

  @StateObject var flowState = SwiftFlowState()
  @Environment(\.colorScheme) var systemColorScheme
  @State var viewport = Viewport.identity
  @State var viewSize: CGSize = .zero
  @State var nodeSizes: [String: CGSize] = [:]
  @State var handlePositions: [String: CGPoint] = [:]
  @State var handleTypes: [String: HandleType] = [:]
  @State var handleInfos: [String: HandleInfo] = [:]

  @State var dragStartPositions: [String: XYPosition] = [:]
  @State var viewportDragStart: Viewport?
  @State var viewportZoomStart: CGFloat?
  @State var draggingNodeId: String?

  /// The in-progress connection or reconnection drag.
  @State var connectionDraft: ConnectionDraft?

  @State var selectionBoxOrigin: CGPoint?
  @State var selectionBoxCurrent: CGPoint?
  @State var edgeDashPhase: CGFloat = 0
  @State var edgeAnimationActive: Bool = false
  @State var snapLines: [SnapLine] = []

  @State var clipboard: (nodes: [Node<NodeData>], edges: [Edge<EdgeData>])?
  @State var undoStack: [GraphSnapshot] = []
  @State var redoStack: [GraphSnapshot] = []

  @State var previousSelectedNodes: Set<String> = []
  @State var previousSelectedEdges: Set<String> = []
  @State var selectionDragStarted: Bool = false
  @State var didInitialFitView: Bool = false

  /// Element with canvas keyboard focus (macOS; Tab / Shift+Tab).
  @State var focusedElement: FocusedElement?
  /// Element with system keyboard focus (iOS hardware keyboards).
  @FocusState var systemFocus: FocusedElement?
  /// Node positions when the current resize started.
  @State var resizeStartPositions: [String: XYPosition] = [:]

  typealias GraphSnapshot = (nodes: [Node<NodeData>], edges: [Edge<EdgeData>])

  // MARK: - Init

  public init(
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>],
    onNodesChange: (([NodeChange<NodeData>]) -> Void)? = nil,
    onEdgesChange: (([EdgeChange<EdgeData>]) -> Void)? = nil,
    onConnect: ((Connection) -> Void)? = nil,
    nodesDraggable: Bool = true,
    nodesConnectable: Bool = true,
    elementsSelectable: Bool = true,
    panOnDrag: Bool = true,
    panOnScroll: Bool = false,
    panOnScrollMode: PanOnScrollMode = .free,
    zoomOnScroll: Bool = true,
    zoomOnPinch: Bool = true,
    zoomOnDoubleClick: Bool = true,
    selectionOnDrag: Bool = false,
    selectNodesOnDrag: Bool = true,
    selectionMode: SelectionMode = .partial,
    connectionMode: ConnectionMode = .strict,
    connectionLineType: EdgeType = .default,
    backgroundVariant: BackgroundVariant? = nil,
    snapToGrid: Bool = false,
    snapGrid: (x: CGFloat, y: CGFloat) = (x: 20, y: 20),
    theme: SwiftFlowTheme = .default,
    colorMode: ColorMode = .system,
    zIndexMode: ZIndexMode = .auto,
    nodeOrigin: NodeOrigin = .topLeft,
    coordinateExtent: CoordinateExtent = .infinite,
    fitView: Bool = false,
    fitViewOptions: FitViewOptions? = nil,
    defaultEdgeOptions: DefaultEdgeOptions? = nil,
    keyboardShortcuts: KeyboardShortcuts = .default,
    accessibilityConfig: AccessibilityConfig = .default,
    onPaneClick: (() -> Void)? = nil,
    onViewportChange: ((Viewport) -> Void)? = nil,
    onSelectionChange: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)? = nil,
    isValidConnection: ((Connection) -> Bool)? = nil,
    onNodeDragStart: ((Node<NodeData>) -> Void)? = nil,
    onNodeDrag: ((Node<NodeData>) -> Void)? = nil,
    onNodeDragStop: ((Node<NodeData>) -> Void)? = nil,
    onConnectStart: ((OnConnectStartParams) -> Void)? = nil,
    onConnectEnd: (() -> Void)? = nil,
    onBeforeDelete: (
      ([Node<NodeData>], [Edge<EdgeData>]) async -> BeforeDeleteResult<NodeData, EdgeData>?
    )? = nil,
    onNodesDelete: (([Node<NodeData>]) -> Void)? = nil,
    onEdgesDelete: (([Edge<EdgeData>]) -> Void)? = nil,
    onNodeClick: ((Node<NodeData>) -> Void)? = nil,
    onNodeDoubleClick: ((Node<NodeData>) -> Void)? = nil,
    onEdgeClick: ((Edge<EdgeData>) -> Void)? = nil,
    onEdgeDoubleClick: ((Edge<EdgeData>) -> Void)? = nil,
    onReconnect: ((Edge<EdgeData>, Connection) -> Void)? = nil,
    onMoveStart: ((Viewport) -> Void)? = nil,
    onMove: ((Viewport) -> Void)? = nil,
    onMoveEnd: ((Viewport) -> Void)? = nil,
    onInit: (() -> Void)? = nil,
    onError: ((String, String) -> Void)? = nil,
    connectionLineContent: ((Connection, CGPoint, CGPoint) -> AnyView)? = nil,
    swiftFlowInstance: SwiftFlowInstance? = nil,
    onNodeMouseEnter: ((Node<NodeData>) -> Void)? = nil,
    onNodeMouseLeave: ((Node<NodeData>) -> Void)? = nil,
    onEdgeMouseEnter: ((Edge<EdgeData>) -> Void)? = nil,
    onEdgeMouseLeave: ((Edge<EdgeData>) -> Void)? = nil,
    onNodeContextMenu: ((Node<NodeData>) -> Void)? = nil,
    onEdgeContextMenu: ((Edge<EdgeData>) -> Void)? = nil,
    onPaneContextMenu: (() -> Void)? = nil,
    onSelectionDragStart: (([Node<NodeData>]) -> Void)? = nil,
    onSelectionDrag: (([Node<NodeData>]) -> Void)? = nil,
    onSelectionDragStop: (([Node<NodeData>]) -> Void)? = nil,
    onDelete: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)? = nil,
    edgeContent: ((Edge<EdgeData>, EdgePathResult) -> AnyView)? = nil,
    @ViewBuilder nodeContent: @escaping (Node<NodeData>) -> NodeContent,
    @ViewBuilder overlay: @escaping () -> Overlay
  ) {
    self.nodes = nodes
    self.edges = edges
    self.onNodesChange = onNodesChange
    self.onEdgesChange = onEdgesChange
    self.onConnect = onConnect
    self.nodesDraggable = nodesDraggable
    self.nodesConnectable = nodesConnectable
    self.elementsSelectable = elementsSelectable
    self.panOnDrag = panOnDrag
    self.panOnScroll = panOnScroll
    self.panOnScrollMode = panOnScrollMode
    self.zoomOnScroll = zoomOnScroll
    self.zoomOnPinch = zoomOnPinch
    self.zoomOnDoubleClick = zoomOnDoubleClick
    self.selectionOnDrag = selectionOnDrag
    self.selectNodesOnDrag = selectNodesOnDrag
    self.selectionMode = selectionMode
    self.connectionMode = connectionMode
    self.connectionLineType = connectionLineType
    self.backgroundVariant = backgroundVariant
    self.snapToGrid = snapToGrid
    self.snapGrid = snapGrid
    self.theme = theme
    self.colorMode = colorMode
    self.zIndexMode = zIndexMode
    self.nodeOrigin = nodeOrigin
    self.coordinateExtent = coordinateExtent
    self.fitView = fitView
    self.fitViewOptions = fitViewOptions
    self.defaultEdgeOptions = defaultEdgeOptions
    self.keyboardShortcuts = keyboardShortcuts
    self.accessibilityConfig = accessibilityConfig
    self.onPaneClick = onPaneClick
    self.onViewportChange = onViewportChange
    self.onSelectionChange = onSelectionChange
    self.isValidConnection = isValidConnection
    self.onNodeDragStart = onNodeDragStart
    self.onNodeDrag = onNodeDrag
    self.onNodeDragStop = onNodeDragStop
    self.onConnectStart = onConnectStart
    self.onConnectEnd = onConnectEnd
    self.onBeforeDelete = onBeforeDelete
    self.onNodesDelete = onNodesDelete
    self.onEdgesDelete = onEdgesDelete
    self.onNodeClick = onNodeClick
    self.onNodeDoubleClick = onNodeDoubleClick
    self.onEdgeClick = onEdgeClick
    self.onEdgeDoubleClick = onEdgeDoubleClick
    self.onReconnect = onReconnect
    self.onMoveStart = onMoveStart
    self.onMove = onMove
    self.onMoveEnd = onMoveEnd
    self.onInit = onInit
    self.onError = onError
    self.connectionLineContent = connectionLineContent
    self.swiftFlowInstance = swiftFlowInstance
    self.onNodeMouseEnter = onNodeMouseEnter
    self.onNodeMouseLeave = onNodeMouseLeave
    self.onEdgeMouseEnter = onEdgeMouseEnter
    self.onEdgeMouseLeave = onEdgeMouseLeave
    self.onNodeContextMenu = onNodeContextMenu
    self.onEdgeContextMenu = onEdgeContextMenu
    self.onPaneContextMenu = onPaneContextMenu
    self.onSelectionDragStart = onSelectionDragStart
    self.onSelectionDrag = onSelectionDrag
    self.onSelectionDragStop = onSelectionDragStop
    self.onDelete = onDelete
    self.edgeContent = edgeContent
    self.nodeContent = nodeContent
    self.overlay = overlay
  }

  // MARK: - Body

  public var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        if let backgroundVariant {
          Background(variant: backgroundVariant, color: theme.gridColor, gap: theme.gridSpacing)
        }

        interactionLayer
        canvasContentLayer
        selectionBoxOverlay

        // Overlay components (Controls, MiniMap, Panel, etc.)
        overlay()
      }
      .contentShape(Rectangle())
      .onAppear { updateViewSize(proxy.size) }
      .onValueChange(of: proxy.size) { updateViewSize($0) }
      #if canImport(AppKit)
        .onKeyDown { event in
          guard flowState.isInteractive && elementsSelectable else { return false }
          return handleKeyEvent(event)
        }
      #endif
    }
    .background(effectiveCanvasBackgroundColor)
    .clipped()
    .environmentObject(flowState)
    .environment(\.swiftFlowInstance, swiftFlowInstance)
    .environment(\.swiftFlowTheme, theme)
    .environment(\.swiftFlowAccessibilityConfig, accessibilityConfig)
    .environment(\.nodesInitialized, nodesInitialized)
    .environment(\.swiftFlowNodeResize, applyNodeResize)
    .onAppear {
      syncFlowState()
      onInit?()
      startEdgeAnimationIfNeeded()
      fitViewOnInitIfNeeded()
    }
    .onValueChange(of: viewport) { newViewport in
      onViewportChange?(newViewport)
      flowState.viewport = newViewport
      swiftFlowInstance?.viewport = newViewport
    }
    .onValueChange(of: nodes.filter(\.selected).map(\.id)) { _ in checkSelectionChange() }
    .onValueChange(of: edges.filter(\.selected).map(\.id)) { _ in checkSelectionChange() }
    .onValueChange(of: hasAnimatedEdges) { _ in startEdgeAnimationIfNeeded() }
    .onValueChange(of: nodes) { _ in syncFlowState() }
    .onValueChange(of: edges) { _ in syncFlowState() }
    .onValueChange(of: nodeSizes) { _ in
      syncFlowState()
      fitViewOnInitIfNeeded()
    }
    .onValueChange(of: viewSize) { _ in fitViewOnInitIfNeeded() }
    .onDisappear {
      swiftFlowInstance?._applyViewport = nil
      swiftFlowInstance?._deleteElements = nil
      flowState.applyViewport = nil
    }
  }

  // MARK: - Derived State

  /// Top-left corner of every node in flow coordinates.
  var topLeftPositions: [String: XYPosition] {
    nodeTopLeftPositions(nodes: nodes, nodeSizes: nodeSizes, nodeOrigin: nodeOrigin)
  }

  /// Whether every visible node has been measured.
  private var nodesInitialized: Bool {
    let visible = nodes.filter { !$0.hidden }
    return !visible.isEmpty && visible.allSatisfy { nodeSizes[$0.id] != nil }
  }

  var hasAnimatedEdges: Bool {
    edges.contains { $0.animated && !$0.hidden }
      || (defaultEdgeOptions?.animated == true && edges.contains { !$0.hidden })
  }

  private var effectiveCanvasBackgroundColor: Color {
    if theme.canvasBackgroundColor != .clear {
      return theme.canvasBackgroundColor
    }
    let lightBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    switch colorMode {
    case .light:
      return lightBackground
    case .dark:
      return Color.swiftFlowBackground
    case .system:
      return systemColorScheme == .dark ? Color.swiftFlowBackground : lightBackground
    }
  }

  // MARK: - State Synchronization

  /// Copies canvas state into the shared `SwiftFlowState` read by overlay components.
  private func syncFlowState() {
    bindSwiftFlowInstance()
    var cyclicNodeIds: [String] = []
    let positions = nodeTopLeftPositions(
      nodes: nodes, nodeSizes: nodeSizes, nodeOrigin: nodeOrigin,
      onCycle: { cyclicNodeIds.append($0) })
    for id in Set(cyclicNodeIds).sorted() {
      onError?("CYCLE_DETECTED", "Cyclic parent relationship at node \(id)")
    }

    flowState.viewport = viewport
    flowState.viewSize = viewSize
    flowState.nodeSizes = nodeSizes
    flowState.absolutePositions = positions
    flowState.handlePositions = handlePositions
    flowState.handleTypes = handleTypes
    flowState.fitViewOptions = fitViewOptions ?? FitViewOptions()
    flowState.nodes = nodes.map { AnyNodeSnapshot(from: $0) }
    flowState.edges = edges.map { AnyEdgeSnapshot(from: $0) }
    var connections: [String: [Connection]] = [:]
    for edge in edges {
      let connection = Connection(
        source: edge.source, target: edge.target,
        sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle)
      connections[edge.source, default: []].append(connection)
      if edge.target != edge.source {
        connections[edge.target, default: []].append(connection)
      }
    }
    flowState.connectionsMap = connections
    flowState.applyViewport = { vp, animated in
      if animated {
        withAnimation(.easeInOut(duration: 0.3)) { viewport = vp }
      } else {
        viewport = vp
      }
    }
  }

  private func bindSwiftFlowInstance() {
    guard let instance = swiftFlowInstance else { return }
    instance.viewport = viewport
    instance.viewSize = viewSize
    instance.nodeSizes = nodeSizes
    instance._applyViewport = { [binding = $viewport] vp in
      binding.wrappedValue = vp
    }
    instance._deleteElements = { nodeIds, edgeIds in
      requestDeletion(nodeIds: nodeIds, edgeIds: edgeIds)
    }
  }

  private func updateViewSize(_ size: CGSize) {
    guard viewSize != size else { return }
    viewSize = size
    flowState.viewSize = size
    swiftFlowInstance?.viewSize = size
  }

  private func startEdgeAnimationIfNeeded() {
    guard hasAnimatedEdges, !edgeAnimationActive else { return }
    edgeAnimationActive = true
    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
      edgeDashPhase = -12
    }
  }

  /// Performs the initial `fitView` once the view has a size and the nodes are measured.
  private func fitViewOnInitIfNeeded() {
    guard fitView, !didInitialFitView, viewSize != .zero, nodesInitialized else { return }
    didInitialFitView = true
    let options = fitViewOptions ?? FitViewOptions()
    if let duration = options.duration, duration > 0 {
      withAnimation(.easeInOut(duration: duration)) { fitToContent(options: options) }
    } else {
      fitToContent(options: options)
    }
  }
}

// MARK: - Convenience Init (no overlay)

extension SwiftFlow where Overlay == EmptyView, EdgeData: Equatable & Sendable & Hashable {
  public init(
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>],
    onNodesChange: (([NodeChange<NodeData>]) -> Void)? = nil,
    onEdgesChange: (([EdgeChange<EdgeData>]) -> Void)? = nil,
    onConnect: ((Connection) -> Void)? = nil,
    nodesDraggable: Bool = true,
    nodesConnectable: Bool = true,
    elementsSelectable: Bool = true,
    panOnDrag: Bool = true,
    panOnScroll: Bool = false,
    panOnScrollMode: PanOnScrollMode = .free,
    zoomOnScroll: Bool = true,
    zoomOnPinch: Bool = true,
    zoomOnDoubleClick: Bool = true,
    selectionOnDrag: Bool = false,
    selectNodesOnDrag: Bool = true,
    selectionMode: SelectionMode = .partial,
    connectionMode: ConnectionMode = .strict,
    connectionLineType: EdgeType = .default,
    backgroundVariant: BackgroundVariant? = nil,
    snapToGrid: Bool = false,
    snapGrid: (x: CGFloat, y: CGFloat) = (x: 20, y: 20),
    theme: SwiftFlowTheme = .default,
    colorMode: ColorMode = .system,
    zIndexMode: ZIndexMode = .auto,
    nodeOrigin: NodeOrigin = .topLeft,
    coordinateExtent: CoordinateExtent = .infinite,
    fitView: Bool = false,
    fitViewOptions: FitViewOptions? = nil,
    defaultEdgeOptions: DefaultEdgeOptions? = nil,
    keyboardShortcuts: KeyboardShortcuts = .default,
    accessibilityConfig: AccessibilityConfig = .default,
    onPaneClick: (() -> Void)? = nil,
    onViewportChange: ((Viewport) -> Void)? = nil,
    onSelectionChange: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)? = nil,
    isValidConnection: ((Connection) -> Bool)? = nil,
    onNodeDragStart: ((Node<NodeData>) -> Void)? = nil,
    onNodeDrag: ((Node<NodeData>) -> Void)? = nil,
    onNodeDragStop: ((Node<NodeData>) -> Void)? = nil,
    onConnectStart: ((OnConnectStartParams) -> Void)? = nil,
    onConnectEnd: (() -> Void)? = nil,
    onBeforeDelete: (
      ([Node<NodeData>], [Edge<EdgeData>]) async -> BeforeDeleteResult<NodeData, EdgeData>?
    )? = nil,
    onNodesDelete: (([Node<NodeData>]) -> Void)? = nil,
    onEdgesDelete: (([Edge<EdgeData>]) -> Void)? = nil,
    onNodeClick: ((Node<NodeData>) -> Void)? = nil,
    onNodeDoubleClick: ((Node<NodeData>) -> Void)? = nil,
    onEdgeClick: ((Edge<EdgeData>) -> Void)? = nil,
    onEdgeDoubleClick: ((Edge<EdgeData>) -> Void)? = nil,
    onReconnect: ((Edge<EdgeData>, Connection) -> Void)? = nil,
    onMoveStart: ((Viewport) -> Void)? = nil,
    onMove: ((Viewport) -> Void)? = nil,
    onMoveEnd: ((Viewport) -> Void)? = nil,
    onInit: (() -> Void)? = nil,
    onError: ((String, String) -> Void)? = nil,
    connectionLineContent: ((Connection, CGPoint, CGPoint) -> AnyView)? = nil,
    swiftFlowInstance: SwiftFlowInstance? = nil,
    onNodeMouseEnter: ((Node<NodeData>) -> Void)? = nil,
    onNodeMouseLeave: ((Node<NodeData>) -> Void)? = nil,
    onEdgeMouseEnter: ((Edge<EdgeData>) -> Void)? = nil,
    onEdgeMouseLeave: ((Edge<EdgeData>) -> Void)? = nil,
    onNodeContextMenu: ((Node<NodeData>) -> Void)? = nil,
    onEdgeContextMenu: ((Edge<EdgeData>) -> Void)? = nil,
    onPaneContextMenu: (() -> Void)? = nil,
    onSelectionDragStart: (([Node<NodeData>]) -> Void)? = nil,
    onSelectionDrag: (([Node<NodeData>]) -> Void)? = nil,
    onSelectionDragStop: (([Node<NodeData>]) -> Void)? = nil,
    onDelete: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)? = nil,
    edgeContent: ((Edge<EdgeData>, EdgePathResult) -> AnyView)? = nil,
    @ViewBuilder nodeContent: @escaping (Node<NodeData>) -> NodeContent
  ) {
    self.init(
      nodes: nodes, edges: edges,
      onNodesChange: onNodesChange, onEdgesChange: onEdgesChange, onConnect: onConnect,
      nodesDraggable: nodesDraggable, nodesConnectable: nodesConnectable,
      elementsSelectable: elementsSelectable, panOnDrag: panOnDrag,
      panOnScroll: panOnScroll, panOnScrollMode: panOnScrollMode,
      zoomOnScroll: zoomOnScroll, zoomOnPinch: zoomOnPinch,
      zoomOnDoubleClick: zoomOnDoubleClick, selectionOnDrag: selectionOnDrag,
      selectNodesOnDrag: selectNodesOnDrag, selectionMode: selectionMode,
      connectionMode: connectionMode, connectionLineType: connectionLineType,
      backgroundVariant: backgroundVariant, snapToGrid: snapToGrid, snapGrid: snapGrid,
      theme: theme, colorMode: colorMode, zIndexMode: zIndexMode, nodeOrigin: nodeOrigin,
      coordinateExtent: coordinateExtent, fitView: fitView, fitViewOptions: fitViewOptions,
      defaultEdgeOptions: defaultEdgeOptions, keyboardShortcuts: keyboardShortcuts,
      accessibilityConfig: accessibilityConfig, onPaneClick: onPaneClick,
      onViewportChange: onViewportChange, onSelectionChange: onSelectionChange,
      isValidConnection: isValidConnection, onNodeDragStart: onNodeDragStart,
      onNodeDrag: onNodeDrag, onNodeDragStop: onNodeDragStop,
      onConnectStart: onConnectStart, onConnectEnd: onConnectEnd,
      onBeforeDelete: onBeforeDelete, onNodesDelete: onNodesDelete,
      onEdgesDelete: onEdgesDelete, onNodeClick: onNodeClick,
      onNodeDoubleClick: onNodeDoubleClick, onEdgeClick: onEdgeClick,
      onEdgeDoubleClick: onEdgeDoubleClick, onReconnect: onReconnect,
      onMoveStart: onMoveStart, onMove: onMove, onMoveEnd: onMoveEnd,
      onInit: onInit, onError: onError,
      connectionLineContent: connectionLineContent,
      swiftFlowInstance: swiftFlowInstance,
      onNodeMouseEnter: onNodeMouseEnter, onNodeMouseLeave: onNodeMouseLeave,
      onEdgeMouseEnter: onEdgeMouseEnter, onEdgeMouseLeave: onEdgeMouseLeave,
      onNodeContextMenu: onNodeContextMenu, onEdgeContextMenu: onEdgeContextMenu,
      onPaneContextMenu: onPaneContextMenu,
      onSelectionDragStart: onSelectionDragStart, onSelectionDrag: onSelectionDrag,
      onSelectionDragStop: onSelectionDragStop,
      onDelete: onDelete, edgeContent: edgeContent,
      nodeContent: nodeContent,
      overlay: { EmptyView() }
    )
  }
}
