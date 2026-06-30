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

  public var nodes: [Node<NodeData>]
  public var edges: [Edge<EdgeData>]

  // MARK: - Change Callbacks

  public var onNodesChange: (([NodeChange<NodeData>]) -> Void)?
  public var onEdgesChange: (([EdgeChange<EdgeData>]) -> Void)?
  public var onConnect: ((Connection) -> Void)?

  // MARK: - Interaction Props

  public var nodesDraggable: Bool
  public var nodesConnectable: Bool
  public var elementsSelectable: Bool
  public var panOnDrag: Bool
  public var panOnScroll: Bool
  public var panOnScrollMode: PanOnScrollMode
  public var zoomOnScroll: Bool
  public var zoomOnPinch: Bool
  public var zoomOnDoubleClick: Bool
  public var selectionOnDrag: Bool
  public var selectNodesOnDrag: Bool
  public var selectionMode: SelectionMode
  public var connectionMode: ConnectionMode
  public var connectionLineType: EdgeType

  // MARK: - Appearance

  public var backgroundVariant: BackgroundVariant?
  public var snapToGrid: Bool
  public var snapGrid: (x: CGFloat, y: CGFloat)
  public var theme: SwiftFlowTheme
  public var colorMode: ColorMode
  public var zIndexMode: ZIndexMode
  public var nodeOrigin: NodeOrigin

  // MARK: - Constraints

  public var coordinateExtent: CoordinateExtent
  public var fitView: Bool
  public var fitViewOptions: FitViewOptions?
  public var defaultEdgeOptions: DefaultEdgeOptions?
  public var keyboardShortcuts: KeyboardShortcuts
  public var accessibilityConfig: AccessibilityConfig

  // MARK: - Event Callbacks

  public var onPaneClick: (() -> Void)?
  public var onViewportChange: ((Viewport) -> Void)?
  public var onSelectionChange: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?
  public var isValidConnection: ((Connection) -> Bool)?
  public var onNodeDragStart: ((Node<NodeData>) -> Void)?
  public var onNodeDrag: ((Node<NodeData>) -> Void)?
  public var onNodeDragStop: ((Node<NodeData>) -> Void)?
  public var onConnectStart: ((OnConnectStartParams) -> Void)?
  public var onConnectEnd: (() -> Void)?
  public var onBeforeDelete:
    (([Node<NodeData>], [Edge<EdgeData>]) async -> BeforeDeleteResult<NodeData, EdgeData>?)?
  public var onNodesDelete: (([Node<NodeData>]) -> Void)?
  public var onEdgesDelete: (([Edge<EdgeData>]) -> Void)?
  public var onNodeClick: ((Node<NodeData>) -> Void)?
  public var onNodeDoubleClick: ((Node<NodeData>) -> Void)?
  public var onEdgeClick: ((Edge<EdgeData>) -> Void)?
  public var onEdgeDoubleClick: ((Edge<EdgeData>) -> Void)?
  public var onReconnect: ((Edge<EdgeData>, Connection) -> Void)?
  public var onMoveStart: ((Viewport) -> Void)?
  public var onMove: ((Viewport) -> Void)?
  public var onMoveEnd: ((Viewport) -> Void)?
  public var onInit: (() -> Void)?
  public var onError: ((String, String) -> Void)?
  public var connectionLineContent: ((Connection, CGPoint, CGPoint) -> AnyView)?
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

  public var onDelete: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?

  // MARK: - Custom Edge Content

  public var edgeContent: ((Edge<EdgeData>, EdgePathResult) -> AnyView)?

  // MARK: - Content Builders

  @ViewBuilder public var nodeContent: (Node<NodeData>) -> NodeContent
  @ViewBuilder public var overlay: () -> Overlay

  // MARK: - Internal State

  @StateObject private var flowState = SwiftFlowState()
  @Environment(\.colorScheme) private var systemColorScheme
  @State private var viewport = Viewport.identity
  @State private var viewSize: CGSize = .zero
  @State private var nodeSizes: [String: CGSize] = [:]
  @State private var handlePositions: [String: CGPoint] = [:]
  @State private var handleTypes: [String: HandleType] = [:]

  @State private var dragStartPositions: [String: XYPosition] = [:]
  @State private var viewportDragStart: Viewport?
  @State private var viewportZoomStart: CGFloat?
  @State private var draggingNodeId: String?

  @State private var draftingConnectionStart: CGPoint?
  @State private var draftingConnectionCurrent: CGPoint?
  @State private var draftingSourceInfo: (nodeId: String, handleId: String)?

  @State private var selectionBoxOrigin: CGPoint?
  @State private var selectionBoxCurrent: CGPoint?
  @State private var edgeDashPhase: CGFloat = 0
  @State private var edgeAnimationActive: Bool = false
  @State private var snapLines: [SnapLine] = []

  @State private var updatingEdge: (edgeId: String, endpointIsSource: Bool)?

  @State private var clipboard: (nodes: [Node<NodeData>], edges: [Edge<EdgeData>])?
  @State private var undoStack: [(nodes: [Node<NodeData>], edges: [Edge<EdgeData>])] = []
  @State private var redoStack: [(nodes: [Node<NodeData>], edges: [Edge<EdgeData>])] = []

  @State private var previousSelectedNodes: Set<String> = []
  @State private var previousSelectedEdges: Set<String> = []
  @State private var selectionDragStarted: Bool = false

  #if canImport(AppKit)
    @State private var shiftHeld = false
  #endif

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

  // MARK: - Computed Properties

  /// Absolute positions for all nodes, resolving parent chains with cycle detection.
  private var absolutePositionCache: [String: XYPosition] {
    var cache: [String: XYPosition] = [:]
    let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

    func resolve(_ nodeId: String, visited: inout Set<String>) -> XYPosition {
      if let cached = cache[nodeId] { return cached }
      if visited.contains(nodeId) {
        onError?("CYCLE_DETECTED", "Cyclic parent relationship at node \(nodeId)")
        return .zero
      }
      visited.insert(nodeId)
      guard let node = nodeMap[nodeId] else { return .zero }
      var pos = node.position
      if let pid = node.parentId {
        pos = pos + resolve(pid, visited: &visited)
      }
      cache[nodeId] = pos
      return pos
    }

    for node in nodes {
      var visited = Set<String>()
      _ = resolve(node.id, visited: &visited)
    }
    return cache
  }

  private var sortedNodes: [Node<NodeData>] {
    nodes.sorted { a, b in
      if a.type == "group" && b.type != "group" { return true }
      if a.type != "group" && b.type == "group" { return false }
      if a.parentId == nil && b.parentId != nil { return true }
      if a.parentId != nil && b.parentId == nil { return false }
      if zIndexMode != .manual {
        if a.zIndex != b.zIndex { return a.zIndex < b.zIndex }
        if zIndexMode == .auto && a.selected != b.selected { return !a.selected }
      }
      return false
    }
  }

  private var sortedEdges: [Edge<EdgeData>] {
    edges.sorted { $0.zIndex < $1.zIndex }
  }

  private var hasAnimatedEdges: Bool {
    edges.contains { $0.animated && !$0.hidden }
  }

  private var effectiveCanvasBackgroundColor: Color {
    if theme.canvasBackgroundColor != .clear {
      return theme.canvasBackgroundColor
    }

    switch colorMode {
    case .light:
      return Color(red: 0.98, green: 0.98, blue: 0.98)
    case .dark:
      return Color.swiftFlowBackground
    case .system:
      return systemColorScheme == .dark
        ? Color.swiftFlowBackground : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
  }

  // MARK: - Body

  public var body: some View {
    GeometryReader { proxy in
      let _ = updateViewSize(proxy.size)
      ZStack(alignment: .topLeading) {
        // Optional built-in background (for backward compatibility)
        if let bgVariant = backgroundVariant {
          Background(variant: bgVariant, color: theme.gridColor, gap: theme.gridSpacing)
            .environmentObject(flowState)
        }

        interactionLayer
        canvasContentLayer
        selectionBoxOverlay

        // Overlay components (Controls, MiniMap, Panel, etc.)
        overlay()
          .environmentObject(flowState)
      }
      .contentShape(Rectangle())
      #if canImport(AppKit)
        .onKeyDown { event in
          guard flowState.isInteractive && elementsSelectable else { return false }
          return handleKeyEvent(event)
        }
      #endif
    }
    .background(
      effectiveCanvasBackgroundColor
    )
    .clipped()
    .environmentObject(flowState)
    .environment(\.swiftFlowInstance, swiftFlowInstance)
    .environment(
      \.nodesInitialized,
      !nodes.isEmpty
        && nodes.allSatisfy {
          nodeSizes[$0.id] != nil
        }
    )
    .onAppear {
      syncFlowState()
      bindSwiftFlowInstance()
      onInit?()
      startEdgeAnimationIfNeeded()
      if fitView {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          withAnimation(.easeInOut(duration: fitViewOptions?.duration ?? 0.3)) {
            fitToContent(options: fitViewOptions)
          }
        }
      }
    }
    .onChange(of: viewport) { newViewport in
      onViewportChange?(newViewport)
      flowState.viewport = newViewport
      swiftFlowInstance?.viewport = newViewport
    }
    .onChange(of: nodes.map(\.selected)) { _ in checkSelectionChange() }
    .onChange(of: edges.map(\.selected)) { _ in checkSelectionChange() }
    .onChange(of: hasAnimatedEdges) { _ in startEdgeAnimationIfNeeded() }
    .onChange(of: nodes) { _ in syncFlowState() }
    .onChange(of: edges) { _ in syncFlowState() }
    .onChange(of: nodeSizes) { _ in syncFlowState() }
  }

  // MARK: - State Synchronization

  /// Syncs internal state to the shared SwiftFlowState for overlay components.
  private func syncFlowState() {
    flowState.viewport = viewport
    flowState.viewSize = viewSize
    flowState.nodeSizes = nodeSizes
    flowState.absolutePositions = absolutePositionCache
    flowState.handlePositions = handlePositions
    flowState.handleTypes = handleTypes
    flowState.nodes = nodes.map { AnyNodeSnapshot(from: $0) }
    flowState.edges = edges.map { AnyEdgeSnapshot(from: $0) }
    var connMap: [String: [Connection]] = [:]
    for edge in edges {
      let conn = Connection(
        source: edge.source, target: edge.target,
        sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle)
      connMap[edge.source, default: []].append(conn)
      connMap[edge.target, default: []].append(conn)
    }
    flowState.connectionsMap = connMap
    flowState.applyViewport = { vp, animated in
      if animated {
        withAnimation(.easeInOut(duration: 0.3)) { viewport = vp }
      } else {
        viewport = vp
      }
    }
  }

  private func startEdgeAnimationIfNeeded() {
    guard hasAnimatedEdges, !edgeAnimationActive else { return }
    edgeAnimationActive = true
    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
      edgeDashPhase = -12
    }
  }

  private func updateViewSize(_ size: CGSize) -> Bool {
    DispatchQueue.main.async {
      if viewSize != size {
        viewSize = size
        flowState.viewSize = size
        swiftFlowInstance?.viewSize = size
      }
    }
    return true
  }

  // MARK: - Interaction Layer

  private var interactionLayer: some View {
    Color.clear
      .contentShape(Rectangle())
      .flowCursor(.grab)
      .onTapGesture {
        guard flowState.isInteractive && elementsSelectable else { return }
        onPaneClick?()
        deselectAll()
      }
      .if(zoomOnDoubleClick) { view in
        view.onTapGesture(count: 2) {
          guard flowState.isInteractive else { return }
          withAnimation(.easeInOut(duration: 0.3)) {
            fitToContent()
          }
        }
      }
      .gesture(canvasDragGesture)
      .simultaneousGesture(flowState.isInteractive && zoomOnPinch ? magnificationGesture : nil)
      #if canImport(AppKit)
        .if(panOnScroll || zoomOnScroll) { view in
          view.onScrollWheel { delta, location in
            guard flowState.isInteractive else { return }
            if panOnScroll {
              panViewportByScroll(delta)
            } else if zoomOnScroll {
              zoomViewportByScroll(delta.height, at: location)
            }
          }
        }
      #endif
      .if(onPaneContextMenu != nil) { view in
        view.onSecondaryAction { [onPaneContextMenu] in
          onPaneContextMenu?()
        }
      }
  }

  // MARK: - Canvas Content Layer

  private var canvasContentLayer: some View {
    ZStack(alignment: .topLeading) {
      snapLinesLayer
      edgesLayer
      nodesLayer
      draftingEdgeLayer

      if flowState.isInteractive && nodesConnectable {
        handleHitTargets
      }
    }
    .coordinateSpace(name: "SwiftFlowCanvas")
    .scaleEffect(viewport.zoom, anchor: .topLeading)
    .offset(x: viewport.x, y: viewport.y)
    .if(coordinateExtent != .infinite) { view in
      view.mask(
        Rectangle()
          .frame(
            width: (coordinateExtent.maxX - coordinateExtent.minX) * viewport.zoom,
            height: (coordinateExtent.maxY - coordinateExtent.minY) * viewport.zoom
          )
          .offset(
            x: coordinateExtent.minX * viewport.zoom + viewport.x,
            y: coordinateExtent.minY * viewport.zoom + viewport.y
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      )
    }
    .onPreferenceChange(NodeSizePreferenceKey.self) { newSizes in
      if newSizes != nodeSizes {
        nodeSizes = newSizes
        swiftFlowInstance?.nodeSizes = newSizes
        flowState.nodeSizes = newSizes
      }
    }
    .onPreferenceChange(HandlePositionPreferenceKey.self) { newPositions in
      handlePositions = newPositions
      flowState.handlePositions = newPositions
    }
    .onPreferenceChange(HandleTypePreferenceKey.self) { newTypes in
      handleTypes = newTypes
      flowState.handleTypes = newTypes
    }
  }

  // MARK: - Nodes Layer

  private func isParentCollapsed(_ node: Node<NodeData>) -> Bool {
    guard let parentId = node.parentId else { return false }
    guard let parent = nodes.first(where: { $0.id == parentId }) else { return false }
    if parent.expandable && !parent.expanded { return true }
    return isParentCollapsed(parent)
  }

  @ViewBuilder
  private var nodesLayer: some View {
    let absPositions = absolutePositionCache
    ForEach(sortedNodes) { node in
      if !node.hidden && !isParentCollapsed(node) && (node.type != "group" || node.expanded) {
        let absPos = absPositions[node.id] ?? node.position
        let nodeSize = nodeSizes[node.id] ?? CGSize(width: 200, height: 100)
        if isNodeVisible(absPos, size: nodeSize) {
          // Use .position() (not .offset()) so the layout frame
          // moves with the visual rendering. This keeps NSView
          // overlays (onSecondaryAction, onHover) aligned with
          // the visible node, preventing "dead space" hit areas
          // at the canvas origin.
          ZStack(alignment: .topLeading) {
            nodeContent(node)
              .background(
                GeometryReader { geo in
                  Color.clear.preference(
                    key: NodeSizePreferenceKey.self, value: [node.id: geo.size])
                }
              )
              .if(node.width != nil && node.height != nil) { view in
                view.frame(width: node.width, height: node.height)
              }
          }
          .fixedSize()
          .contentShape(Rectangle())
          .gesture(
            flowState.isInteractive && nodesDraggable && node.draggable
              ? nodeDragGesture(node: node) : nil
          )
          .onTapGesture(count: 2) {
            if node.expandable {
              var toggled = node
              toggled.expanded.toggle()
              onNodesChange?([.replace(id: node.id, item: toggled)])
            }
            onNodeDoubleClick?(node)
          }
          .simultaneousGesture(
            TapGesture(count: 1).onEnded {
              guard flowState.isInteractive && elementsSelectable && node.selectable else { return }
              onNodeClick?(node)
              var changes = nodes.filter { $0.selected && $0.id != node.id }
                .map { NodeChange<NodeData>.selection(id: $0.id, selected: false) }
              changes.append(.selection(id: node.id, selected: true))
              onNodesChange?(changes)
            }
          )
          #if canImport(AppKit)
            .onHover { hovering in
              if hovering {
                onNodeMouseEnter?(node)
              } else {
                onNodeMouseLeave?(node)
              }
            }
          #endif
          .if(onNodeContextMenu != nil) { view in
            view.onSecondaryAction { [onNodeContextMenu] in
              onNodeContextMenu?(node)
            }
          }
          .flowCursor(.grab)
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Node \(node.id)")
          .accessibilityHint(node.selected ? "Selected" : "Double tap to select")
          .accessibilityAddTraits(node.selected ? .isSelected : [])
          .position(
            x: absPos.x + nodeSize.width / 2,
            y: absPos.y + nodeSize.height / 2
          )
        }
      }
    }
  }

  // MARK: - Edges Layer

  @ViewBuilder
  private var edgesLayer: some View {
    let absPositions = absolutePositionCache
    ForEach(sortedEdges) { edge in
      if !edge.hidden,
        let sPos = getHandlePos(
          nodeId: edge.source, handleId: edge.sourceHandle, isSource: true,
          absolutePositions: absPositions),
        let tPos = getHandlePos(
          nodeId: edge.target, handleId: edge.targetHandle, isSource: false,
          absolutePositions: absPositions)
      {

        let pathResult = getEdgePathResult(
          type: edge.type, sourceX: sPos.x, sourceY: sPos.y, targetX: tPos.x,
          targetY: tPos.y)
        let color =
          edge.style?.strokeColor ?? (edge.selected ? theme.edgeSelectedColor : theme.edgeColor)
        let width =
          edge.style?.strokeWidth ?? (edge.selected ? theme.edgeSelectedWidth : theme.edgeWidth)

        ZStack {
          // Hit-testing shape
          pathResult.path.stroke(Color.white.opacity(0.001), lineWidth: 20)
            .contentShape(pathResult.path.strokedPath(StrokeStyle(lineWidth: 20)))

          if let edgeContent = edgeContent {
            edgeContent(edge, pathResult)
              .allowsHitTesting(false)
          } else {
            pathResult.path.stroke(
              color, style: edgeStrokeStyle(edge: edge, width: width)
            )
            .allowsHitTesting(false)
          }

          if let m = edge.markerEnd {
            markerView(
              marker: m, position: tPos,
              angle: getEdgeAngleAtEnd(
                type: edge.type, sourceX: sPos.x, sourceY: sPos.y, targetX: tPos.x,
                targetY: tPos.y),
              color: color)
          }
          if let m = edge.markerStart {
            markerView(
              marker: m, position: sPos,
              angle: getEdgeAngleAtStart(
                type: edge.type, sourceX: sPos.x, sourceY: sPos.y, targetX: tPos.x,
                targetY: tPos.y) + .pi,
              color: color)
          }

          if let label = edge.label {
            Text(label)
              .font(theme.edgeLabelFont)
              .foregroundColor(theme.edgeLabelColor)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(theme.edgeLabelBackgroundColor.opacity(0.9))
              .cornerRadius(4)
              .position(x: pathResult.labelX, y: pathResult.labelY)
              .allowsHitTesting(false)
          }

          if flowState.isInteractive && edge.reconnectable && edge.selected && nodesConnectable {
            reconnectableEndpoints(edge: edge, sPos: sPos, tPos: tPos)
          }
        }
        .highPriorityGesture(
          TapGesture(count: 2).onEnded {
            guard flowState.isInteractive && elementsSelectable else { return }
            onEdgeDoubleClick?(edge)
            onEdgesChange?([.remove(id: edge.id)])
          }
        )
        .onTapGesture {
          guard flowState.isInteractive && elementsSelectable else { return }
          onEdgeClick?(edge)
          var changes: [EdgeChange<EdgeData>] = edges.filter {
            $0.selected && $0.id != edge.id
          }
          .map { .selection(id: $0.id, selected: false) }
          changes.append(.selection(id: edge.id, selected: true))
          onEdgesChange?(changes)
        }
        #if canImport(AppKit)
          .onHover { hovering in
            if hovering {
              onEdgeMouseEnter?(edge)
            } else {
              onEdgeMouseLeave?(edge)
            }
          }
        #endif
        .if(onEdgeContextMenu != nil) { view in
          view.onSecondaryAction { [onEdgeContextMenu] in
            onEdgeContextMenu?(edge)
          }
        }
        .accessibilityElement()
        .accessibilityLabel(
          "Edge from \(edge.source) to \(edge.target)\(edge.label.map { ", \($0)" } ?? "")"
        )
        .accessibilityAddTraits(edge.selected ? .isSelected : [])
      }
    }
  }

  private func edgeStrokeStyle(edge: Edge<EdgeData>, width: CGFloat) -> StrokeStyle {
    StrokeStyle(
      lineWidth: width,
      lineCap: .round,
      lineJoin: .round,
      dash: edge.animated ? [8, 4] : [],
      dashPhase: edge.animated ? edgeDashPhase : 0
    )
  }

  // MARK: - Edge Markers

  @ViewBuilder
  private func markerView(marker: EdgeMarker, position: CGPoint, angle: CGFloat, color: Color)
    -> some View
  {
    let markerPath = Path { p in
      p.move(to: CGPoint(x: -marker.width, y: -marker.height / 2))
      p.addLine(to: .zero)
      p.addLine(to: CGPoint(x: -marker.width, y: marker.height / 2))
      if marker.type == .arrowClosed { p.closeSubpath() }
    }

    if marker.type == .arrowClosed {
      markerPath
        .transform(CGAffineTransform(rotationAngle: angle))
        .fill(color)
        .offset(x: position.x, y: position.y)
        .allowsHitTesting(false)
    } else {
      markerPath
        .transform(CGAffineTransform(rotationAngle: angle))
        .stroke(color, lineWidth: 2)
        .offset(x: position.x, y: position.y)
        .allowsHitTesting(false)
    }
  }

  // MARK: - Reconnectable Edge Endpoints

  @ViewBuilder
  private func reconnectableEndpoints(edge: Edge<EdgeData>, sPos: CGPoint, tPos: CGPoint)
    -> some View
  {
    endpointHandle(edge: edge, position: sPos, isSource: true, otherPos: tPos)
    endpointHandle(edge: edge, position: tPos, isSource: false, otherPos: sPos)
  }

  private func endpointHandle(
    edge: Edge<EdgeData>, position: CGPoint, isSource: Bool, otherPos: CGPoint
  ) -> some View {
    Circle()
      .fill(Color.white)
      .frame(width: 14, height: 14)
      .overlay(Circle().stroke(theme.edgeSelectedColor, lineWidth: 2))
      .position(x: position.x, y: position.y)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if updatingEdge == nil {
              updatingEdge = (edgeId: edge.id, endpointIsSource: isSource)
              onEdgesChange?([.remove(id: edge.id)])
              draftingConnectionStart = otherPos
              let anchorNodeId = isSource ? edge.target : edge.source
              let anchorHandle =
                isSource ? (edge.targetHandle ?? "") : (edge.sourceHandle ?? "")
              draftingSourceInfo = (nodeId: anchorNodeId, handleId: anchorHandle)
            }
            let rawPos = CGPoint(
              x: position.x + value.translation.width,
              y: position.y + value.translation.height
            )
            let excludeNode = isSource ? edge.target : edge.source
            let anchorType =
              lookupHandleType(
                nodeId: draftingSourceInfo?.nodeId ?? "",
                handleId: draftingSourceInfo?.handleId ?? "") ?? .source
            var snappedTarget: (nodeId: String, handleId: String, handleType: HandleType?)?
            if let snapped = findClosestHandle(
              to: rawPos, threshold: 40, preferType: anchorType == .source ? .target : .source),
              snapped.nodeId != excludeNode
            {
              draftingConnectionCurrent = lookupHandlePos(
                nodeId: snapped.nodeId, handleId: snapped.handleId, type: snapped.handleType)
              snappedTarget = snapped
            } else {
              draftingConnectionCurrent = rawPos
            }
            if let sourceInfo = draftingSourceInfo {
              updateActiveConnection(
                sourceNodeId: sourceInfo.nodeId,
                sourceHandleId: sourceInfo.handleId,
                currentPos: draftingConnectionCurrent ?? rawPos,
                snappedTarget: snappedTarget)
            }
          }
          .onEnded { _ in
            finishDraftingConnection()
            flowState.activeConnection = nil
            updatingEdge = nil
          }
      )
  }

  // MARK: - Drafting Edge Layer

  @ViewBuilder
  private var draftingEdgeLayer: some View {
    if let start = draftingConnectionStart, let current = draftingConnectionCurrent {
      if let customContent = connectionLineContent, let sourceInfo = draftingSourceInfo {
        let conn = Connection(
          source: sourceInfo.nodeId, target: "", sourceHandle: sourceInfo.handleId)
        customContent(conn, start, current)
          .allowsHitTesting(false)
      } else {
        getEdgePath(
          type: connectionLineType, sourceX: start.x, sourceY: start.y,
          targetX: current.x, targetY: current.y
        )
        .stroke(
          Color.blue.opacity(0.8),
          style: StrokeStyle(
            lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 6])
        )
        .allowsHitTesting(false)
      }
    }
  }

  // MARK: - Handle Hit Targets

  @ViewBuilder
  private var handleHitTargets: some View {
    ForEach(Array(handlePositions.keys.sorted()), id: \.self) { key in
      if let pos = handlePositions[key],
        let parsed = HandlePositionPreferenceKey.parseKey(key)
      {
        let connectable =
          nodes.first(where: { $0.id == parsed.nodeId })?.connectable ?? true

        if connectable {
          Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 30, height: 30)
            .flowCursor(.crosshair)
            .position(x: pos.x, y: pos.y)
            .gesture(
              connectionDragGesture(
                nodeId: parsed.nodeId, handleId: parsed.handleId,
                handleType: parsed.handleType, handlePos: pos))
        }
      }
    }
  }

  // MARK: - Selection Box

  @ViewBuilder
  private var selectionBoxOverlay: some View {
    if let origin = selectionBoxOrigin, let current = selectionBoxCurrent {
      let rect = CGRect(
        x: min(origin.x, current.x), y: min(origin.y, current.y),
        width: abs(current.x - origin.x), height: abs(current.y - origin.y)
      )
      Rectangle()
        .fill(theme.selectionBoxColor)
        .overlay(Rectangle().stroke(theme.selectionBoxBorderColor, lineWidth: 1))
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }
  }

  // MARK: - Snap Lines Layer

  @ViewBuilder
  private var snapLinesLayer: some View {
    ForEach(snapLines.indices, id: \.self) { i in
      Path { p in
        p.move(to: snapLines[i].start)
        p.addLine(to: snapLines[i].end)
      }
      .stroke(
        theme.snapLineColor,
        style: StrokeStyle(lineWidth: theme.snapLineWidth, dash: [4, 4])
      )
      .allowsHitTesting(false)
    }
  }

  // MARK: - Gestures

  /// Unified canvas drag gesture that routes to either panning or selection box.
  ///
  /// When `selectionOnDrag` is false (default), dragging empty space pans the canvas.
  /// Hold Shift to draw a selection box instead. When `selectionOnDrag` is true,
  /// dragging creates a selection box and Shift+drag pans.
  private var canvasDragGesture: some Gesture {
    DragGesture(minimumDistance: 3)
      .onChanged { value in
        guard flowState.isInteractive else { return }
        let wantsSelection = shouldDrawSelectionBox()

        if wantsSelection && elementsSelectable {
          handleSelectionDrag(value)
        } else if panOnDrag {
          handlePanDrag(value)
        }
      }
      .onEnded { _ in
        // End panning
        if viewportDragStart != nil {
          viewportDragStart = nil
          onMoveEnd?(viewport)
        }
        // End selection box
        selectionBoxOrigin = nil
        selectionBoxCurrent = nil
      }
  }

  /// Determines whether the current drag should create a selection box.
  private func shouldDrawSelectionBox() -> Bool {
    #if canImport(AppKit)
      let shiftDown = NSEvent.modifierFlags.contains(.shift)
    #else
      let shiftDown = false
    #endif

    if selectionOnDrag {
      return !shiftDown
    } else {
      return shiftDown
    }
  }

  private func handlePanDrag(_ value: DragGesture.Value) {
    if viewportDragStart == nil {
      viewportDragStart = viewport
      onMoveStart?(viewport)
    }
    guard let start = viewportDragStart else { return }
    let mode = panOnScrollMode
    viewport.x = mode == .vertical ? start.x : start.x + value.translation.width
    viewport.y = mode == .horizontal ? start.y : start.y + value.translation.height
    onMove?(viewport)
  }

  private func panViewportByScroll(_ delta: CGSize) {
    let mode = panOnScrollMode
    viewport.x += mode == .vertical ? 0 : delta.width
    viewport.y += mode == .horizontal ? 0 : delta.height
    onMove?(viewport)
  }

  private func zoomViewportByScroll(_ deltaY: CGFloat, at location: CGPoint) {
    let factor = deltaY > 0 ? 1.05 : 0.95
    let newZoom = max(Viewport.minZoom, min(viewport.zoom * factor, Viewport.maxZoom))
    let currentZoom = max(viewport.zoom, Viewport.minZoom)
    let flowX = (location.x - viewport.x) / currentZoom
    let flowY = (location.y - viewport.y) / currentZoom
    viewport.zoom = newZoom
    viewport.x = location.x - flowX * newZoom
    viewport.y = location.y - flowY * newZoom
    onMove?(viewport)
  }

  private func handleSelectionDrag(_ value: DragGesture.Value) {
    selectionBoxOrigin = value.startLocation
    selectionBoxCurrent = value.location

    let boxRect = CGRect(
      x: min(value.startLocation.x, value.location.x),
      y: min(value.startLocation.y, value.location.y),
      width: abs(value.location.x - value.startLocation.x),
      height: abs(value.location.y - value.startLocation.y)
    )

    let absPositions = absolutePositionCache
    let zoom = max(viewport.zoom, Viewport.minZoom)
    var changes: [NodeChange<NodeData>] = []

    for node in nodes where !node.hidden && node.selectable {
      let absPos = absPositions[node.id] ?? node.position
      let size = nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
      let nodeRect = CGRect(
        x: absPos.x * zoom + viewport.x,
        y: absPos.y * zoom + viewport.y,
        width: size.width * zoom,
        height: size.height * zoom
      )

      let shouldSelect: Bool
      switch selectionMode {
      case .partial: shouldSelect = nodeRect.intersects(boxRect)
      case .full: shouldSelect = boxRect.contains(nodeRect)
      }

      if shouldSelect != node.selected {
        changes.append(.selection(id: node.id, selected: shouldSelect))
      }
    }

    if !changes.isEmpty { onNodesChange?(changes) }
  }

  private var magnificationGesture: some Gesture {
    MagnificationGesture()
      .onChanged { value in
        if viewportZoomStart == nil {
          viewportZoomStart = viewport.zoom
          onMoveStart?(viewport)
        }
        guard let start = viewportZoomStart else { return }
        let newZoom = max(Viewport.minZoom, min(start * value, Viewport.maxZoom))
        let centerX = viewSize.width / 2
        let centerY = viewSize.height / 2
        let currentZoom = max(viewport.zoom, Viewport.minZoom)
        let oldFlowX = (centerX - viewport.x) / currentZoom
        let oldFlowY = (centerY - viewport.y) / currentZoom
        viewport.zoom = newZoom
        viewport.x = centerX - oldFlowX * newZoom
        viewport.y = centerY - oldFlowY * newZoom
        onMove?(viewport)
      }
      .onEnded { _ in
        viewportZoomStart = nil
        onMoveEnd?(viewport)
      }
  }

  private func nodeDragGesture(node: Node<NodeData>) -> some Gesture {
    DragGesture(minimumDistance: 1, coordinateSpace: .global)
      .onChanged { value in
        if selectNodesOnDrag && !node.selected {
          var changes = nodes.filter(\.selected).map {
            NodeChange<NodeData>.selection(id: $0.id, selected: false)
          }
          changes.append(.selection(id: node.id, selected: true))
          applyImmediateNodeDragChanges(changes)
        }

        if draggingNodeId == nil {
          draggingNodeId = node.id
          onNodeDragStart?(node)
        }

        // `DragGesture` reports translation in screen points. Node positions
        // are stored in flow/canvas coordinates, so convert the drag delta
        // through the current zoom. Without this, dragging at any zoom other
        // than 1.0 moves the node faster/slower than the pointer, which feels
        // like jitter as SwiftUI continuously re-evaluates the moving view.
        let zoom = max(viewport.zoom, Viewport.minZoom)
        let translation = XYPosition(
          x: value.translation.width / zoom,
          y: value.translation.height / zoom
        )
        let nodesToDrag =
          node.selected ? nodes.filter { $0.selected && $0.draggable } : [node]

        snapLines = computeSnapLines(for: node, translation: translation)

        var changes: [NodeChange<NodeData>] = []
        for sNode in nodesToDrag {
          if dragStartPositions[sNode.id] == nil {
            dragStartPositions[sNode.id] = sNode.position
          }
          // Skip children whose parent is also being dragged (they move with parent)
          if let parentId = sNode.parentId,
            nodesToDrag.contains(where: { $0.id == parentId })
          {
            continue
          }
          if let startPos = dragStartPositions[sNode.id] {
            var newPos = startPos + translation
            if snapToGrid { newPos = newPos.snapped(to: snapGrid) }
            let extent = resolveExtent(for: sNode)
            newPos = extent.clamp(newPos)
            changes.append(.position(id: sNode.id, position: newPos))
          }
        }
        if !changes.isEmpty {
          applyImmediateNodeDragChanges(changes)
          onNodeDrag?(node)

          // Selection drag events
          let selectedNodes = nodes.filter(\.selected)
          if node.selected && selectedNodes.count > 1 {
            if !selectionDragStarted {
              selectionDragStarted = true
              onSelectionDragStart?(selectedNodes)
            }
            onSelectionDrag?(selectedNodes)
          }
        }
      }
      .onEnded { _ in
        if let dragId = draggingNodeId,
          let dragNode = nodes.first(where: { $0.id == dragId })
        {
          onNodeDragStop?(dragNode)
        }
        if selectionDragStarted {
          onSelectionDragStop?(nodes.filter(\.selected))
          selectionDragStarted = false
        }
        draggingNodeId = nil
        dragStartPositions.removeAll()
        snapLines.removeAll()
      }
  }

  private func applyImmediateNodeDragChanges(_ changes: [NodeChange<NodeData>]) {
    var transaction = Transaction(animation: nil)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      onNodesChange?(changes)
    }
  }

  private func connectionDragGesture(
    nodeId: String, handleId: String, handleType: HandleType? = nil, handlePos: CGPoint
  )
    -> some Gesture
  {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if draftingConnectionStart == nil {
          draftingConnectionStart = handlePos
          draftingSourceInfo = (nodeId: nodeId, handleId: handleId)
          let resolvedHandleType =
            handleType ?? lookupHandleType(nodeId: nodeId, handleId: handleId) ?? .source
          onConnectStart?(
            OnConnectStartParams(
              nodeId: nodeId, handleId: handleId, handleType: resolvedHandleType))
        }
        let rawPos = CGPoint(
          x: handlePos.x + value.translation.width,
          y: handlePos.y + value.translation.height
        )
        let sourceType =
          handleType ?? lookupHandleType(nodeId: nodeId, handleId: handleId) ?? .source
        var snappedTarget: (nodeId: String, handleId: String, handleType: HandleType?)?
        if let snapped = findClosestHandle(
          to: rawPos, threshold: 40, preferType: sourceType == .source ? .target : .source),
          snapped.nodeId != nodeId
        {
          draftingConnectionCurrent = lookupHandlePos(
            nodeId: snapped.nodeId, handleId: snapped.handleId, type: snapped.handleType)
          snappedTarget = snapped
        } else {
          draftingConnectionCurrent = rawPos
        }
        updateActiveConnection(
          sourceNodeId: nodeId, sourceHandleId: handleId,
          currentPos: draftingConnectionCurrent ?? rawPos,
          snappedTarget: snappedTarget)
      }
      .onEnded { _ in
        finishDraftingConnection()
        flowState.activeConnection = nil
        onConnectEnd?()
      }
  }

  private func updateActiveConnection(
    sourceNodeId: String, sourceHandleId: String,
    currentPos: CGPoint,
    snappedTarget: (nodeId: String, handleId: String, handleType: HandleType?)?
  ) {
    guard let sourceNode = nodes.first(where: { $0.id == sourceNodeId }) else { return }
    let handleType = lookupHandleType(nodeId: sourceNodeId, handleId: sourceHandleId) ?? .source
    let fromHandle = NodeHandle(
      id: sourceHandleId, type: handleType,
      position: sourceNode.sourcePosition ?? .right)
    let fromPos = draftingConnectionStart ?? currentPos

    var toHandle: NodeHandle?
    var toNode: AnyNodeSnapshot?
    var toPosition: Position = .left
    var isValid: Bool?

    if let target = snappedTarget {
      let targetHandleType = target.handleType ?? .target
      if let targetNode = nodes.first(where: { $0.id == target.nodeId }) {
        toNode = AnyNodeSnapshot(from: targetNode)
        toPosition = targetNode.targetPosition ?? .left
      }
      toHandle = NodeHandle(
        id: target.handleId, type: targetHandleType, position: toPosition)
      let conn = Connection(
        source: sourceNodeId, target: target.nodeId,
        sourceHandle: sourceHandleId, targetHandle: target.handleId)
      isValid = isValidConnection?(conn) ?? true
    }

    flowState.activeConnection = ConnectionState(
      isValid: isValid,
      from: fromPos,
      fromHandle: fromHandle,
      fromPosition: sourceNode.sourcePosition ?? .right,
      fromNode: AnyNodeSnapshot(from: sourceNode),
      to: currentPos,
      toHandle: toHandle,
      toPosition: toPosition,
      toNode: toNode
    )
  }

  private func finishDraftingConnection() {
    defer {
      draftingConnectionStart = nil
      draftingConnectionCurrent = nil
      draftingSourceInfo = nil
    }
    guard let source = draftingSourceInfo,
      let endPos = draftingConnectionCurrent
    else { return }
    let sourceType = lookupHandleType(nodeId: source.nodeId, handleId: source.handleId) ?? .source
    guard
      let target = findClosestHandle(
        to: endPos, threshold: 40, preferType: sourceType == .source ? .target : .source),
      target.nodeId != source.nodeId
    else { return }

    let targetType = target.handleType ?? .target
    let conn: Connection
    if let updatingEdge, updatingEdge.endpointIsSource {
      if connectionMode == .strict {
        guard targetType == .source && sourceType == .target else {
          onError?("CONNECTION_INVALID", "Strict mode requires source-to-target connections")
          return
        }
      }
      conn = Connection(
        source: target.nodeId, target: source.nodeId,
        sourceHandle: target.handleId, targetHandle: source.handleId)
    } else {
      if connectionMode == .strict {
        guard sourceType == .source && targetType == .target else {
          onError?("CONNECTION_INVALID", "Strict mode requires source-to-target connections")
          return
        }
      }
      conn = Connection(
        source: source.nodeId, target: target.nodeId,
        sourceHandle: source.handleId, targetHandle: target.handleId)
    }

    if isValidConnection?(conn) ?? true {
      if let updatingEdge, let originalEdge = edges.first(where: { $0.id == updatingEdge.edgeId }) {
        if let onReconnect {
          onReconnect(originalEdge, conn)
        } else {
          onConnect?(conn)
        }
      } else {
        onConnect?(conn)
      }
    }
  }

  // MARK: - Keyboard Handling

  #if canImport(AppKit)
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      let hasCmd = flags.contains(.command)
      let hasShift = flags.contains(.shift)

      switch (event.keyCode, hasCmd, hasShift) {
      case (keyboardShortcuts.deleteKeyCode, false, _),
        (keyboardShortcuts.forwardDeleteKeyCode, false, _):
        deleteSelected()
        return true
      case (_, true, false) where event.charactersIgnoringModifiers == "a":
        selectAll()
        return true
      case (_, true, false) where event.charactersIgnoringModifiers == "c":
        copySelected()
        return true
      case (_, true, false) where event.charactersIgnoringModifiers == "v":
        pasteClipboard()
        return true
      case (_, true, false) where event.charactersIgnoringModifiers == "z":
        undo()
        return true
      case (_, true, true) where event.charactersIgnoringModifiers == "z":
        redo()
        return true
      default: break
      }

      let nudge: CGFloat =
        hasShift ? keyboardShortcuts.shiftNudgeDistance : keyboardShortcuts.nudgeDistance
      switch event.keyCode {
      case 123:
        nudgeSelected(dx: -nudge, dy: 0)
        return true
      case 124:
        nudgeSelected(dx: nudge, dy: 0)
        return true
      case 125:
        nudgeSelected(dx: 0, dy: nudge)
        return true
      case 126:
        nudgeSelected(dx: 0, dy: -nudge)
        return true
      default: return false
      }
    }
  #endif

  // MARK: - Actions

  private func deselectAll() {
    let nc = nodes.filter(\.selected).map {
      NodeChange<NodeData>.selection(id: $0.id, selected: false)
    }
    if !nc.isEmpty { onNodesChange?(nc) }
    let ec: [EdgeChange<EdgeData>] = edges.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    if !ec.isEmpty { onEdgesChange?(ec) }
  }

  private func deleteSelected() {
    let nodesToDelete = nodes.filter { $0.selected && $0.deletable }
    let edgesToDelete = edges.filter { $0.selected && $0.deletable }
    guard !nodesToDelete.isEmpty || !edgesToDelete.isEmpty else { return }

    if let beforeDelete = onBeforeDelete {
      Task { @MainActor in
        if let result = await beforeDelete(nodesToDelete, edgesToDelete) {
          switch result {
          case .cancel:
            return
          case .delete(let filteredNodes, let filteredEdges):
            performDeletion(nodesToDelete: filteredNodes, edgesToDelete: filteredEdges)
          }
        } else {
          performDeletion(nodesToDelete: nodesToDelete, edgesToDelete: edgesToDelete)
        }
      }
    } else {
      performDeletion(nodesToDelete: nodesToDelete, edgesToDelete: edgesToDelete)
    }
  }

  private func performDeletion(
    nodesToDelete: [Node<NodeData>], edgesToDelete: [Edge<EdgeData>]
  ) {
    guard !nodesToDelete.isEmpty || !edgesToDelete.isEmpty else { return }
    pushUndoState()
    let nr = nodesToDelete.map { NodeChange<NodeData>.remove(id: $0.id) }
    let er: [EdgeChange<EdgeData>] = edgesToDelete.map { .remove(id: $0.id) }
    if !nr.isEmpty {
      onNodesChange?(nr)
      onNodesDelete?(nodesToDelete)
    }
    if !er.isEmpty {
      onEdgesChange?(er)
      onEdgesDelete?(edgesToDelete)
    }
    onDelete?(nodesToDelete, edgesToDelete)
  }

  private func selectAll() {
    let nc = nodes.filter { !$0.selected && $0.selectable }.map {
      NodeChange<NodeData>.selection(id: $0.id, selected: true)
    }
    let ec: [EdgeChange<EdgeData>] = edges.filter { !$0.selected }.map {
      .selection(id: $0.id, selected: true)
    }
    if !nc.isEmpty { onNodesChange?(nc) }
    if !ec.isEmpty { onEdgesChange?(ec) }
  }

  private func nudgeSelected(dx: CGFloat, dy: CGFloat) {
    let changes: [NodeChange<NodeData>] = nodes.filter(\.selected).map { node in
      var pos = node.position + XYPosition(x: dx, y: dy)
      if snapToGrid { pos = pos.snapped(to: snapGrid) }
      let extent = resolveExtent(for: node)
      pos = extent.clamp(pos)
      return .position(id: node.id, position: pos)
    }
    if !changes.isEmpty { onNodesChange?(changes) }
  }

  private func copySelected() {
    let selectedNodes = nodes.filter(\.selected)
    let ids = Set(selectedNodes.map(\.id))
    let selectedEdges = edges.filter { ids.contains($0.source) && ids.contains($0.target) }
    clipboard = (nodes: selectedNodes, edges: selectedEdges)
  }

  private func pasteClipboard() {
    guard let clip = clipboard else { return }
    pushUndoState()
    let offset: CGFloat = 50
    let idMap = Dictionary(
      uniqueKeysWithValues: clip.nodes.map {
        ($0.id, "\($0.id)-copy-\(UUID().uuidString.prefix(8))")
      })

    var nc: [NodeChange<NodeData>] = nodes.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    for node in clip.nodes {
      var n = node
      n.id = idMap[node.id]!
      n.position = n.position + XYPosition(x: offset, y: offset)
      n.selected = true
      if let pid = n.parentId { n.parentId = idMap[pid] ?? pid }
      nc.append(.add(item: n))
    }
    onNodesChange?(nc)

    var ec: [EdgeChange<EdgeData>] = edges.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    for edge in clip.edges {
      let newEdge = Edge<EdgeData>(
        id:
          "e-\(idMap[edge.source]!)-\(idMap[edge.target]!)-\(UUID().uuidString.prefix(8))",
        source: idMap[edge.source]!, target: idMap[edge.target]!,
        sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle,
        type: edge.type, selected: true,
        label: edge.label, animated: edge.animated,
        markerStart: edge.markerStart, markerEnd: edge.markerEnd
      )
      ec.append(.add(item: newEdge))
    }
    if !ec.isEmpty { onEdgesChange?(ec) }
  }

  // MARK: - Undo / Redo

  private func pushUndoState() {
    undoStack.append((nodes: nodes, edges: edges))
    redoStack.removeAll()
    if undoStack.count > 50 { undoStack.removeFirst() }
  }

  private func undo() {
    guard let prev = undoStack.popLast() else { return }
    redoStack.append((nodes: nodes, edges: edges))
    restoreState(prev)
  }

  private func redo() {
    guard let next = redoStack.popLast() else { return }
    undoStack.append((nodes: nodes, edges: edges))
    restoreState(next)
  }

  private func restoreState(_ state: (nodes: [Node<NodeData>], edges: [Edge<EdgeData>])) {
    onNodesChange?(nodes.map { .remove(id: $0.id) } + state.nodes.map { .add(item: $0) })
    let edgeChanges: [EdgeChange<EdgeData>] =
      edges.map { .remove(id: $0.id) } + state.edges.map { .add(item: $0) }
    onEdgesChange?(edgeChanges)
  }

  // MARK: - Snap Lines

  private func computeSnapLines(for node: Node<NodeData>, translation: XYPosition) -> [SnapLine] {
    let threshold: CGFloat = 5
    let draggedSize = nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
    let startPos = dragStartPositions[node.id] ?? node.position
    let dx = startPos.x + translation.x
    let dy = startPos.y + translation.y
    let draggedRight = dx + draggedSize.width
    let draggedBottom = dy + draggedSize.height
    let dcx = dx + draggedSize.width / 2
    let dcy = dy + draggedSize.height / 2

    let absPositions = absolutePositionCache

    // Track unique lines by position (deduplication)
    // Priority: edges > center
    var horizontalLines: [CGFloat: (y: CGFloat, x1: CGFloat, x2: CGFloat, priority: Int)] = [:]
    var verticalLines: [CGFloat: (x: CGFloat, y1: CGFloat, y2: CGFloat, priority: Int)] = [:]

    // Priority levels: 1 = center, 2 = edge
    // Higher priority wins when lines are close together

    for other in nodes where other.id != node.id && !other.hidden {
      let oPos = absPositions[other.id] ?? other.position
      let oSize = nodeSizes[other.id] ?? CGSize(width: 100, height: 50)
      let oRight = oPos.x + oSize.width
      let oBottom = oPos.y + oSize.height
      let ocx = oPos.x + oSize.width / 2
      let ocy = oPos.y + oSize.height / 2

      // === VERTICAL LINES (X alignment) ===

      // Left edge to left edge (priority 2)
      if abs(dx - oPos.x) < threshold {
        let x = oPos.x
        let key = round(x / threshold) * threshold
        let y1 = min(dy, oPos.y) - 20
        let y2 = max(draggedBottom, oBottom) + 20
        if verticalLines[key]?.priority ?? 0 < 2 {
          verticalLines[key] = (x: x, y1: y1, y2: y2, priority: 2)
        }
      }

      // Right edge to right edge (priority 2)
      if abs(draggedRight - oRight) < threshold {
        let x = oRight
        let key = round(x / threshold) * threshold
        let y1 = min(dy, oPos.y) - 20
        let y2 = max(draggedBottom, oBottom) + 20
        if verticalLines[key]?.priority ?? 0 < 2 {
          verticalLines[key] = (x: x, y1: y1, y2: y2, priority: 2)
        }
      }

      // Left edge to right edge (priority 2)
      if abs(dx - oRight) < threshold {
        let x = oRight
        let key = round(x / threshold) * threshold
        let y1 = min(dy, oPos.y) - 20
        let y2 = max(draggedBottom, oBottom) + 20
        if verticalLines[key]?.priority ?? 0 < 2 {
          verticalLines[key] = (x: x, y1: y1, y2: y2, priority: 2)
        }
      }

      // Right edge to left edge (priority 2)
      if abs(draggedRight - oPos.x) < threshold {
        let x = oPos.x
        let key = round(x / threshold) * threshold
        let y1 = min(dy, oPos.y) - 20
        let y2 = max(draggedBottom, oBottom) + 20
        if verticalLines[key]?.priority ?? 0 < 2 {
          verticalLines[key] = (x: x, y1: y1, y2: y2, priority: 2)
        }
      }

      // Center to center (priority 1 - lower, only if no edge alignment)
      if abs(dcx - ocx) < threshold {
        let x = ocx
        let key = round(x / threshold) * threshold
        let y1 = min(dy, oPos.y) - 20
        let y2 = max(draggedBottom, oBottom) + 20
        // Only add center alignment if no edge alignment exists at this position
        if verticalLines[key] == nil {
          verticalLines[key] = (x: x, y1: y1, y2: y2, priority: 1)
        }
      }

      // === HORIZONTAL LINES (Y alignment) ===

      // Top edge to top edge (priority 2)
      if abs(dy - oPos.y) < threshold {
        let y = oPos.y
        let key = round(y / threshold) * threshold
        let x1 = min(dx, oPos.x) - 20
        let x2 = max(draggedRight, oRight) + 20
        if horizontalLines[key]?.priority ?? 0 < 2 {
          horizontalLines[key] = (y: y, x1: x1, x2: x2, priority: 2)
        }
      }

      // Bottom edge to bottom edge (priority 2)
      if abs(draggedBottom - oBottom) < threshold {
        let y = oBottom
        let key = round(y / threshold) * threshold
        let x1 = min(dx, oPos.x) - 20
        let x2 = max(draggedRight, oRight) + 20
        if horizontalLines[key]?.priority ?? 0 < 2 {
          horizontalLines[key] = (y: y, x1: x1, x2: x2, priority: 2)
        }
      }

      // Top edge to bottom edge (priority 2)
      if abs(dy - oBottom) < threshold {
        let y = oBottom
        let key = round(y / threshold) * threshold
        let x1 = min(dx, oPos.x) - 20
        let x2 = max(draggedRight, oRight) + 20
        if horizontalLines[key]?.priority ?? 0 < 2 {
          horizontalLines[key] = (y: y, x1: x1, x2: x2, priority: 2)
        }
      }

      // Bottom edge to top edge (priority 2)
      if abs(draggedBottom - oPos.y) < threshold {
        let y = oPos.y
        let key = round(y / threshold) * threshold
        let x1 = min(dx, oPos.x) - 20
        let x2 = max(draggedRight, oRight) + 20
        if horizontalLines[key]?.priority ?? 0 < 2 {
          horizontalLines[key] = (y: y, x1: x1, x2: x2, priority: 2)
        }
      }

      // Center to center (priority 1 - lower, only if no edge alignment)
      if abs(dcy - ocy) < threshold {
        let y = ocy
        let key = round(y / threshold) * threshold
        let x1 = min(dx, oPos.x) - 20
        let x2 = max(draggedRight, oRight) + 20
        // Only add center alignment if no edge alignment exists at this position
        if horizontalLines[key] == nil {
          horizontalLines[key] = (y: y, x1: x1, x2: x2, priority: 1)
        }
      }
    }

    // Convert to SnapLine array
    var lines: [SnapLine] = []

    for (_, v) in verticalLines {
      lines.append(
        SnapLine(
          start: CGPoint(x: v.x, y: v.y1),
          end: CGPoint(x: v.x, y: v.y2)
        ))
    }

    for (_, h) in horizontalLines {
      lines.append(
        SnapLine(
          start: CGPoint(x: h.x1, y: h.y),
          end: CGPoint(x: h.x2, y: h.y)
        ))
    }

    return lines
  }

  // MARK: - Selection Change

  private func checkSelectionChange() {
    guard onSelectionChange != nil else { return }
    let sn = Set(nodes.filter(\.selected).map(\.id))
    let se = Set(edges.filter(\.selected).map(\.id))
    if sn != previousSelectedNodes || se != previousSelectedEdges {
      previousSelectedNodes = sn
      previousSelectedEdges = se
      onSelectionChange?(nodes.filter(\.selected), edges.filter(\.selected))
    }
  }

  private func bindSwiftFlowInstance() {
    swiftFlowInstance?.onViewportChange = { [onViewportChange] vp in onViewportChange?(vp) }
    swiftFlowInstance?._getEdges = { [edges] in edges as [Any] }
    swiftFlowInstance?._applyEdgeChanges = { [onEdgesChange] edgeIds in
      if let ids = edgeIds as? [String] {
        let changes: [EdgeChange<EdgeData>] = ids.map { .remove(id: $0) }
        onEdgesChange?(changes)
      }
    }
  }

  // MARK: - Viewport Culling

  private func isNodeVisible(_ absPos: XYPosition, size: CGSize) -> Bool {
    let zoom = max(viewport.zoom, Viewport.minZoom)
    let screenX = absPos.x * zoom + viewport.x
    let screenY = absPos.y * zoom + viewport.y
    let screenW = size.width * zoom
    let screenH = size.height * zoom
    let margin: CGFloat = 50
    return screenX + screenW + margin > 0
      && screenX - margin < viewSize.width
      && screenY + screenH + margin > 0
      && screenY - margin < viewSize.height
  }

  // MARK: - Extent Resolution

  private func resolveExtent(for node: Node<NodeData>) -> CoordinateExtent {
    guard let extent = node.extent else { return coordinateExtent }
    switch extent {
    case .parent:
      return parentExtent(for: node)
    case .coordinateExtent(let ce):
      return ce
    }
  }

  private func parentExtent(for node: Node<NodeData>) -> CoordinateExtent {
    guard let parentId = node.parentId,
      let parentSize = nodeSizes[parentId]
    else { return coordinateExtent }
    let nodeSize = nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
    return CoordinateExtent(
      minX: 0, minY: 0,
      maxX: parentSize.width - nodeSize.width,
      maxY: parentSize.height - nodeSize.height
    )
  }

  // MARK: - Geometry Helpers

  private var nodesBoundingBox: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
    let visibleNodes = nodes.filter { !$0.hidden }
    guard !visibleNodes.isEmpty else { return (0, 0, 0, 0) }
    let absPositions = absolutePositionCache
    var minX: CGFloat = .infinity
    var minY: CGFloat = .infinity
    var maxX: CGFloat = -.infinity
    var maxY: CGFloat = -.infinity
    for node in visibleNodes {
      let pos = absPositions[node.id] ?? node.position
      let size = nodeSizes[node.id] ?? CGSize(width: 200, height: 100)
      minX = min(minX, pos.x)
      minY = min(minY, pos.y)
      maxX = max(maxX, pos.x + size.width)
      maxY = max(maxY, pos.y + size.height)
    }
    if minX == .infinity { return (0, 0, 0, 0) }
    return (minX, minY, maxX, maxY)
  }

  private func fitToContent(options: FitViewOptions? = nil) {
    let b = nodesBoundingBox
    let cw = b.maxX - b.minX
    let ch = b.maxY - b.minY
    guard cw > 0, ch > 0 else { return }
    let pad = options?.padding ?? 80
    let maxZoom = options?.maxZoom ?? 1.5
    let minZoom = options?.minZoom ?? Viewport.minZoom
    let effectiveWidth = max(1, viewSize.width - pad * 2)
    let effectiveHeight = max(1, viewSize.height - pad * 2)
    let z = max(min(min(effectiveWidth / cw, effectiveHeight / ch), maxZoom), minZoom)
    viewport = Viewport(x: -(b.minX * z) + pad, y: -(b.minY * z) + pad, zoom: z)
  }

  private func getHandlePos(
    nodeId: String, handleId: String?, isSource: Bool,
    absolutePositions: [String: XYPosition]? = nil
  ) -> CGPoint? {
    let handleType: HandleType = isSource ? .source : .target
    let typedKey = HandlePositionPreferenceKey.makeKey(
      nodeId: nodeId, handleId: handleId ?? "", type: handleType)
    if let pos = handlePositions[typedKey] { return pos }
    // Fallback to legacy key without type
    let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId ?? "")
    if let pos = handlePositions[key] { return pos }
    guard let node = nodes.first(where: { $0.id == nodeId }) else { return nil }
    let absPositions = absolutePositions ?? absolutePositionCache
    let absPos = absPositions[node.id] ?? node.position
    let size = nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
    return isSource
      ? CGPoint(x: absPos.x + size.width, y: absPos.y + size.height / 2)
      : CGPoint(x: absPos.x, y: absPos.y + size.height / 2)
  }

  /// Looks up the handle type, trying typed keys first then legacy.
  private func lookupHandleType(nodeId: String, handleId: String) -> HandleType? {
    for t in [HandleType.source, HandleType.target] {
      let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId, type: t)
      if let found = handleTypes[key] { return found }
    }
    let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId)
    return handleTypes[key]
  }

  /// Looks up handle position, trying typed keys first then legacy.
  private func lookupHandlePos(nodeId: String, handleId: String, type: HandleType? = nil)
    -> CGPoint?
  {
    if let type {
      let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId, type: type)
      if let pos = handlePositions[key] { return pos }
    } else {
      for t in [HandleType.source, HandleType.target] {
        let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId, type: t)
        if let pos = handlePositions[key] { return pos }
      }
    }
    let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: handleId)
    return handlePositions[key]
  }

  private func findClosestHandle(
    to point: CGPoint, threshold: CGFloat, preferType: HandleType? = nil
  ) -> (
    nodeId: String, handleId: String, handleType: HandleType?
  )? {
    var best: (key: String, dist: CGFloat)?
    for (key, pos) in handlePositions {
      if let preferType = preferType {
        let handleType = handleTypes[key]
        if handleType != nil && handleType != preferType { continue }
      }
      let d = hypot(pos.x - point.x, pos.y - point.y)
      if d <= threshold && (best == nil || d < best!.dist) { best = (key, d) }
    }
    guard let match = best,
      let parsed = HandlePositionPreferenceKey.parseKey(match.key)
    else { return nil }
    return (nodeId: parsed.nodeId, handleId: parsed.handleId, handleType: parsed.handleType)
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
