import SwiftUI

// MARK: - Layers

extension SwiftFlow {

  /// Transparent pane behind the content: pane taps, pan/zoom gestures, and scrolling.
  var interactionLayer: some View {
    Color.clear
      .contentShape(Rectangle())
      .flowCursor(.grab)
      .onTapGesture {
        endTextEditing()
        onPaneClick?()
        guard flowState.isInteractive && elementsSelectable else { return }
        deselectAll()
      }
      .if(zoomOnDoubleClick) { view in
        view.onTapGesture(count: 2) {
          guard flowState.isInteractive else { return }
          let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
          withAnimation(.easeInOut(duration: 0.3)) {
            viewport = viewport.zoomed(to: viewport.zoom * 2, around: center)
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

  /// Nodes, edges, and connection UI in flow coordinates, transformed by the viewport.
  var canvasContentLayer: some View {
    let positions = topLeftPositions
    let handles = HandleLookup(
      positions: handlePositions, types: handleTypes, infos: handleInfos)
    return ZStack(alignment: .topLeading) {
      snapLinesLayer
      edgesLayer(positions: positions, handles: handles)
      nodesLayer(positions: positions)
      connectionLineLayer

      if flowState.isInteractive && nodesConnectable {
        handleHitTargets
      }
    }
    .coordinateSpace(name: canvasCoordinateSpace)
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
    .onPreferenceChange(HandleInfoPreferenceKey.self) { newInfos in
      handleInfos = newInfos
    }
  }

  // MARK: Nodes

  /// Nodes in paint order: groups first, then root nodes, then children,
  /// then `zIndex`, with selected nodes raised unless `zIndexMode` is `.manual`.
  private var sortedNodes: [Node<NodeData>] {
    nodes.sorted { a, b in
      let aIsGroup = a.type == "group"
      let bIsGroup = b.type == "group"
      if aIsGroup != bIsGroup { return aIsGroup }
      if (a.parentId == nil) != (b.parentId == nil) { return a.parentId == nil }
      guard zIndexMode != .manual else { return false }
      if a.zIndex != b.zIndex { return a.zIndex < b.zIndex }
      if a.selected != b.selected { return !a.selected }
      return false
    }
  }

  private func isParentCollapsed(_ node: Node<NodeData>, visited: Set<String> = []) -> Bool {
    guard let parentId = node.parentId, !visited.contains(parentId),
      let parent = nodes.first(where: { $0.id == parentId })
    else { return false }
    if parent.expandable && !parent.expanded { return true }
    return isParentCollapsed(parent, visited: visited.union([node.id]))
  }

  @ViewBuilder
  private func nodesLayer(positions: [String: XYPosition]) -> some View {
    ForEach(sortedNodes) { node in
      if !node.hidden && !isParentCollapsed(node) && (node.type != "group" || node.expanded) {
        let topLeft = positions[node.id] ?? node.position
        let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
        if isNodeVisible(topLeft, size: size) {
          nodeView(node)
            // `.position` (not `.offset`) moves the layout frame with the
            // rendering, which keeps NSView overlays (secondary click, hover)
            // aligned with the visible node.
            .position(x: topLeft.x + size.width / 2, y: topLeft.y + size.height / 2)
        }
      }
    }
  }

  private func nodeView(_ node: Node<NodeData>) -> some View {
    let isDraggable = flowState.isInteractive && nodesDraggable && node.draggable
    let isSelectable = flowState.isInteractive && elementsSelectable && node.selectable
    return ZStack(alignment: .topLeading) {
      nodeContent(node)
        .if(node.width != nil && node.height != nil) { view in
          view.frame(width: node.width, height: node.height, alignment: .topLeading)
        }
        .modifier(NodeChrome(style: node.style, selected: node.selected, theme: theme))
        // Measure after the explicit frame so `nodeSizes` matches the rendered size.
        .background(
          GeometryReader { geo in
            Color.clear.preference(key: NodeSizePreferenceKey.self, value: [node.id: geo.size])
          }
        )
    }
    .fixedSize()
    .contentShape(Rectangle())
    .gesture(isDraggable ? nodeDragGesture(node: node) : nil)
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
        onNodeClick?(node)
        guard isSelectable else { return }
        selectNode(node)
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
    .if(isDraggable) { $0.flowCursor(.grab) }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(accessibilityConfig.nodeRoleDescription) \(node.id)")
    .accessibilityHint(
      isSelectable
        ? accessibilityConfig.nodeDescription : accessibilityConfig.nodeDescriptionKeyboardDisabled
    )
    .accessibilityAddTraits(node.selected ? .isSelected : [])
    .accessibilityAction {
      if isSelectable { selectNode(node) }
    }
    .overlay {
      if focusedElement == .node(node.id) {
        RoundedRectangle(cornerRadius: (node.style?.borderRadius ?? 0) + 3)
          .stroke(theme.nodeSelectedBorderColor.opacity(0.7), style: focusRingStyle)
          .padding(-4)
          .allowsHitTesting(false)
      }
    }
    #if os(iOS)
      .focusable(node.focusable && flowState.isInteractive)
      .focused($systemFocus, equals: .node(node.id))
      .onKeyPress(keys: [.return, .space]) { _ in
        guard isSelectable else { return .ignored }
        selectNode(node)
        return .handled
      }
      .onKeyPress(.escape) {
        deselectAll()
        return .handled
      }
    #endif
  }

  // MARK: Edges

  /// Edges in paint order with `defaultEdgeOptions` applied.
  private var renderedEdges: [Edge<EdgeData>] {
    let resolved = defaultEdgeOptions.map { defaults in edges.map { defaults.applied(to: $0) } }
    return (resolved ?? edges).sorted { $0.zIndex < $1.zIndex }
  }

  @ViewBuilder
  private func edgesLayer(positions: [String: XYPosition], handles: HandleLookup) -> some View {
    let nodeById = Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    let reconnectingId = connectionDraft?.reconnectingEdge?.id
    ForEach(renderedEdges) { edge in
      if !edge.hidden, edge.id != reconnectingId,
        let source = edgeAnchor(
          nodeId: edge.source, handleId: edge.sourceHandle, type: .source,
          handles: handles, nodeById: nodeById, positions: positions),
        let target = edgeAnchor(
          nodeId: edge.target, handleId: edge.targetHandle, type: .target,
          handles: handles, nodeById: nodeById, positions: positions)
      {
        edgeView(edge, source: source, target: target)
      }
    }
  }

  private func edgeView(_ edge: Edge<EdgeData>, source: HandleAnchor, target: HandleAnchor)
    -> some View
  {
    let pathResult = edgePathResult(
      type: edge.type,
      source: source.point, sourcePosition: source.position,
      target: target.point, targetPosition: target.position)
    let color =
      edge.style?.strokeColor ?? (edge.selected ? theme.edgeSelectedColor : theme.edgeColor)
    let width =
      edge.style?.strokeWidth ?? (edge.selected ? theme.edgeSelectedWidth : theme.edgeWidth)
    let isSelectable = flowState.isInteractive && elementsSelectable

    return ZStack {
      if focusedElement == .edge(edge.id) {
        pathResult.path
          .stroke(theme.edgeSelectedColor.opacity(0.5), style: focusRingStyle(width: width + 4))
          .allowsHitTesting(false)
      }

      // Invisible, wider stroke used as the hit area.
      pathResult.path.stroke(Color.white.opacity(0.001), lineWidth: edge.interactionWidth)
        .contentShape(pathResult.path.strokedPath(StrokeStyle(lineWidth: edge.interactionWidth)))

      Group {
        if let edgeContent {
          edgeContent(edge, pathResult)
        } else {
          pathResult.path.stroke(color, style: edgeStrokeStyle(edge: edge, width: width))
        }
      }
      .opacity(edge.style?.opacity ?? 1)
      .allowsHitTesting(false)

      if let marker = edge.markerEnd {
        markerView(
          marker: marker, position: target.point,
          angle: edgeEndAngle(
            type: edge.type,
            source: source.point, sourcePosition: source.position,
            target: target.point, targetPosition: target.position),
          color: color)
      }
      if let marker = edge.markerStart {
        markerView(
          marker: marker, position: source.point,
          angle: edgeStartAngle(
            type: edge.type,
            source: source.point, sourcePosition: source.position,
            target: target.point, targetPosition: target.position) + .pi,
          color: color)
      }

      if let label = edge.label {
        EdgeText(
          x: pathResult.labelX, y: pathResult.labelY, label: label,
          font: theme.edgeLabelFont, foregroundColor: theme.edgeLabelColor,
          backgroundColor: theme.edgeLabelBackgroundColor)
      }

      if flowState.isInteractive && nodesConnectable && onReconnect != nil
        && edge.reconnectable && edge.selected
      {
        reconnectAnchor(edge: edge, endpoint: source, anchor: target, isSourceEndpoint: true)
        reconnectAnchor(edge: edge, endpoint: target, anchor: source, isSourceEndpoint: false)
      }
    }
    .highPriorityGesture(
      TapGesture(count: 2).onEnded {
        onEdgeDoubleClick?(edge)
      }
    )
    .onTapGesture {
      onEdgeClick?(edge)
      guard isSelectable else { return }
      selectEdge(edge)
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
      String(
        localized:
          "\(accessibilityConfig.edgeRoleDescription) from \(edge.source) to \(edge.target)",
        bundle: .module, comment: "Edge label: role, source node ID, target node ID")
        + (edge.label.map { ", \($0)" } ?? "")
    )
    .accessibilityHint(isSelectable ? accessibilityConfig.edgeDescription : "")
    .accessibilityAddTraits(edge.selected ? .isSelected : [])
    .accessibilityAction {
      if isSelectable { selectEdge(edge) }
    }
    #if os(iOS)
      .focusable(edge.focusable && flowState.isInteractive)
      .focused($systemFocus, equals: .edge(edge.id))
      .onKeyPress(keys: [.return, .space]) { _ in
        guard isSelectable else { return .ignored }
        selectEdge(edge)
        return .handled
      }
      .onKeyPress(.escape) {
        deselectAll()
        return .handled
      }
    #endif
  }

  /// Dashed outline marking the element with keyboard focus.
  private var focusRingStyle: StrokeStyle { focusRingStyle(width: 2) }

  private func focusRingStyle(width: CGFloat) -> StrokeStyle {
    StrokeStyle(lineWidth: width, lineCap: .round, dash: [4, 3])
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

  /// Arrowhead with its tip at `position`, pointing in the direction `angle`.
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
    .transform(CGAffineTransform(rotationAngle: angle))

    Group {
      if marker.type == .arrowClosed {
        markerPath.fill(color)
      } else {
        markerPath.stroke(color, lineWidth: 2)
      }
    }
    .offset(x: position.x, y: position.y)
    .allowsHitTesting(false)
  }

  // MARK: Connection UI

  /// Draggable circle at an endpoint of a selected, reconnectable edge.
  private func reconnectAnchor(
    edge: Edge<EdgeData>, endpoint: HandleAnchor, anchor: HandleAnchor, isSourceEndpoint: Bool
  ) -> some View {
    Circle()
      .fill(Color.white)
      .frame(width: 14, height: 14)
      .overlay(Circle().stroke(theme.edgeSelectedColor, lineWidth: 2))
      .position(endpoint.point)
      .gesture(
        reconnectGesture(
          edge: edge, endpoint: endpoint, anchor: anchor, isSourceEndpoint: isSourceEndpoint))
  }

  /// The line drawn while the user drags a new connection.
  @ViewBuilder
  var connectionLineLayer: some View {
    if let draft = connectionDraft {
      if let connectionLineContent {
        let connection = Connection(
          source: draft.nodeId, target: draft.target?.nodeId ?? "",
          sourceHandle: draft.handleId, targetHandle: draft.target?.handleId)
        connectionLineContent(connection, draft.start, draft.current)
          .allowsHitTesting(false)
      } else {
        getEdgePath(
          type: connectionLineType,
          sourceX: draft.start.x, sourceY: draft.start.y, sourcePosition: draft.position,
          targetX: draft.current.x, targetY: draft.current.y, targetPosition: draft.toPosition
        )
        .path
        .stroke(
          theme.edgeSelectedColor.opacity(0.8),
          style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 6])
        )
        .allowsHitTesting(false)
      }
    }
  }

  /// Enlarged, invisible hit targets over every connectable handle.
  @ViewBuilder
  var handleHitTargets: some View {
    let connectableNodes = Set(nodes.filter(\.connectable).map(\.id))
    ForEach(Array(handlePositions.keys.sorted()), id: \.self) { key in
      if let point = handlePositions[key],
        let parsed = HandlePositionPreferenceKey.parseKey(key),
        connectableNodes.contains(parsed.nodeId),
        handleInfos[key]?.isConnectable ?? true
      {
        Circle()
          .fill(Color.white.opacity(0.001))
          .frame(width: 30, height: 30)
          .flowCursor(.crosshair)
          .position(x: point.x, y: point.y)
          .gesture(connectionDragGesture(key: key, handlePoint: point))
      }
    }
  }

  // MARK: Selection Box and Snap Lines

  @ViewBuilder
  var selectionBoxOverlay: some View {
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

  @ViewBuilder
  var snapLinesLayer: some View {
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

  // MARK: Geometry

  /// Returns whether a node rectangle (flow coordinates) intersects the view, with a margin.
  func isNodeVisible(_ topLeft: XYPosition, size: CGSize) -> Bool {
    let zoom = max(viewport.zoom, Viewport.minZoom)
    let screenX = topLeft.x * zoom + viewport.x
    let screenY = topLeft.y * zoom + viewport.y
    let margin: CGFloat = 50
    return screenX + size.width * zoom + margin > 0
      && screenX - margin < viewSize.width
      && screenY + size.height * zoom + margin > 0
      && screenY - margin < viewSize.height
  }

  /// Resolves where an edge attaches to a node: the rendered handle when
  /// available, otherwise the center of the node side given by
  /// `Node.sourcePosition`/`targetPosition` (right/left by default).
  func edgeAnchor(
    nodeId: String, handleId: String?, type: HandleType,
    handles: HandleLookup, nodeById: [String: Node<NodeData>], positions: [String: XYPosition]
  ) -> HandleAnchor? {
    let fallbackSide: Position
    if let node = nodeById[nodeId] {
      fallbackSide =
        (type == .source ? node.sourcePosition : node.targetPosition)
        ?? (type == .source ? .right : .left)
    } else {
      fallbackSide = type == .source ? .right : .left
    }
    if let key = handles.key(nodeId: nodeId, handleId: handleId, type: type),
      let point = handles.positions[key]
    {
      return HandleAnchor(point: point, position: handles.infos[key]?.position ?? fallbackSide)
    }
    guard let node = nodeById[nodeId] else { return nil }
    let topLeft = positions[nodeId] ?? node.position
    let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
    let rect = CGRect(x: topLeft.x, y: topLeft.y, width: size.width, height: size.height)
    return HandleAnchor(point: sidePoint(of: rect, side: fallbackSide), position: fallbackSide)
  }
}

// MARK: - Supporting Types

/// The point and side where an edge attaches to a node.
struct HandleAnchor {
  var point: CGPoint
  var position: Position
}

/// Center of the given side of `rect`.
func sidePoint(of rect: CGRect, side: Position) -> CGPoint {
  switch side {
  case .top: return CGPoint(x: rect.midX, y: rect.minY)
  case .bottom: return CGPoint(x: rect.midX, y: rect.maxY)
  case .left: return CGPoint(x: rect.minX, y: rect.midY)
  case .right: return CGPoint(x: rect.maxX, y: rect.midY)
  }
}

/// Resolves handle preference keys for edges.
///
/// Like React Flow, an edge without a handle ID attaches to the first handle
/// of the matching type on its node.
struct HandleLookup {
  let positions: [String: CGPoint]
  let infos: [String: HandleInfo]
  private let firstKeyByNodeAndType: [String: String]

  init(positions: [String: CGPoint], types: [String: HandleType], infos: [String: HandleInfo]) {
    self.positions = positions
    self.infos = infos
    var firstKeys: [String: String] = [:]
    for key in positions.keys.sorted() {
      guard let parsed = HandlePositionPreferenceKey.parseKey(key),
        let type = parsed.handleType ?? types[key]
      else { continue }
      let groupKey = HandlePositionPreferenceKey.makeKey(
        nodeId: parsed.nodeId, handleId: "", type: type)
      if firstKeys[groupKey] == nil { firstKeys[groupKey] = key }
    }
    firstKeyByNodeAndType = firstKeys
  }

  /// The preference key of the handle an edge endpoint attaches to, if rendered.
  func key(nodeId: String, handleId: String?, type: HandleType) -> String? {
    let id = handleId ?? ""
    let typedKey = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: id, type: type)
    if positions[typedKey] != nil { return typedKey }
    let legacyKey = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: id)
    if positions[legacyKey] != nil { return legacyKey }
    guard id.isEmpty else { return nil }
    return firstKeyByNodeAndType[typedKey]
  }
}

/// Library-drawn node decoration: `Node.style` background/border/opacity and
/// the theme's selection outline.
struct NodeChrome: ViewModifier {
  let style: NodeStyle?
  let selected: Bool
  let theme: SwiftFlowTheme

  func body(content: Content) -> some View {
    let shape = RoundedRectangle(cornerRadius: style?.borderRadius ?? 0)
    let borderColor = selected ? theme.nodeSelectedBorderColor : style?.borderColor
    let borderWidth =
      selected
      ? theme.nodeSelectedBorderWidth : (style?.borderColor == nil ? 0 : style?.borderWidth ?? 1)
    content
      .background {
        if let style {
          shape.fill(style.backgroundColor ?? theme.nodeBackgroundColor)
        }
      }
      .overlay {
        if let borderColor, borderWidth > 0 {
          shape.stroke(borderColor, lineWidth: borderWidth)
        }
      }
      .opacity(style?.opacity ?? 1)
  }
}
