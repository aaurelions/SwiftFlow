import SwiftUI

// MARK: - Connection Draft

extension SwiftFlow {
  /// State of an in-progress connection drag.
  ///
  /// A new connection starts at the dragged handle. A reconnection starts at
  /// the edge endpoint that stays attached (the anchor), so both cases produce
  /// connections the same way.
  struct ConnectionDraft {
    /// The handle the line starts from.
    var nodeId: String
    var handleId: String?
    var handleType: HandleType
    var position: Position
    var start: CGPoint
    /// The current end of the line (snapped to `target` when set).
    var current: CGPoint
    var toPosition: Position
    var target: (nodeId: String, handleId: String?, handleType: HandleType)?
    /// The edge being reconnected, or `nil` for a new connection.
    var reconnectingEdge: Edge<EdgeData>?
  }
}

// MARK: - Pane Gestures

extension SwiftFlow {

  /// Drag on the empty pane: pans the viewport or draws the selection box.
  ///
  /// When `selectionOnDrag` is `false` (default), dragging pans and Shift+drag
  /// draws a selection box. When it is `true`, the roles are swapped.
  var canvasDragGesture: some Gesture {
    DragGesture(minimumDistance: 3)
      .onChanged { value in
        guard flowState.isInteractive else { return }
        if shouldDrawSelectionBox() && elementsSelectable {
          handleSelectionDrag(value)
        } else if panOnDrag {
          handlePanDrag(value)
        }
      }
      .onEnded { _ in
        if viewportDragStart != nil {
          viewportDragStart = nil
          onMoveEnd?(viewport)
        }
        selectionBoxOrigin = nil
        selectionBoxCurrent = nil
      }
  }

  private func shouldDrawSelectionBox() -> Bool {
    #if canImport(AppKit)
      let shiftDown = NSEvent.modifierFlags.contains(.shift)
    #else
      let shiftDown = false
    #endif
    return selectionOnDrag ? !shiftDown : shiftDown
  }

  private func handlePanDrag(_ value: DragGesture.Value) {
    if viewportDragStart == nil {
      viewportDragStart = viewport
      onMoveStart?(viewport)
    }
    guard let start = viewportDragStart else { return }
    viewport.x = start.x + value.translation.width
    viewport.y = start.y + value.translation.height
    onMove?(viewport)
  }

  func panViewportByScroll(_ delta: CGSize) {
    viewport.x += panOnScrollMode == .vertical ? 0 : delta.width
    viewport.y += panOnScrollMode == .horizontal ? 0 : delta.height
    onMove?(viewport)
  }

  func zoomViewportByScroll(_ deltaY: CGFloat, at location: CGPoint) {
    let factor: CGFloat = deltaY > 0 ? 1.05 : 0.95
    viewport = viewport.zoomed(to: viewport.zoom * factor, around: location)
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
    let positions = topLeftPositions
    let zoom = max(viewport.zoom, Viewport.minZoom)
    var changes: [NodeChange<NodeData>] = []

    for node in nodes where !node.hidden && node.selectable {
      let topLeft = positions[node.id] ?? node.position
      let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
      let nodeRect = CGRect(
        x: topLeft.x * zoom + viewport.x,
        y: topLeft.y * zoom + viewport.y,
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

  var magnificationGesture: some Gesture {
    MagnificationGesture()
      .onChanged { value in
        if viewportZoomStart == nil {
          viewportZoomStart = viewport.zoom
          onMoveStart?(viewport)
        }
        guard let start = viewportZoomStart else { return }
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        viewport = viewport.zoomed(to: start * value, around: center)
        onMove?(viewport)
      }
      .onEnded { _ in
        viewportZoomStart = nil
        onMoveEnd?(viewport)
      }
  }
}

// MARK: - Node Dragging

extension SwiftFlow {

  func nodeDragGesture(node: Node<NodeData>) -> some Gesture {
    DragGesture(minimumDistance: 1, coordinateSpace: .global)
      .onChanged { value in
        if selectNodesOnDrag && !node.selected && node.selectable && elementsSelectable {
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

        // `DragGesture` reports translation in view points while node
        // positions are in flow coordinates, so divide by the zoom to keep
        // the node under the pointer.
        let zoom = max(viewport.zoom, Viewport.minZoom)
        let translation = XYPosition(
          x: value.translation.width / zoom,
          y: value.translation.height / zoom
        )
        let nodesToDrag =
          node.selected ? nodes.filter { $0.selected && $0.draggable } : [node]
        let draggedIds = Set(nodesToDrag.map(\.id))

        snapLines = computeSnapLines(for: node, translation: translation)

        var movedIds: [String] = []
        var newPositions: [String: XYPosition] = [:]
        for dragged in nodesToDrag {
          if dragStartPositions[dragged.id] == nil {
            dragStartPositions[dragged.id] = dragged.position
          }
          // Children of a dragged parent move with the parent.
          if let parentId = dragged.parentId, draggedIds.contains(parentId) { continue }
          guard let startPosition = dragStartPositions[dragged.id] else { continue }
          var newPosition = startPosition + translation
          if snapToGrid { newPosition = newPosition.snapped(to: snapGrid) }
          newPosition = resolveExtent(for: dragged).clamp(newPosition)
          movedIds.append(dragged.id)
          newPositions[dragged.id] = newPosition
        }
        guard !movedIds.isEmpty else { return }
        let parentChanges = expandParents(of: movedIds, positions: &newPositions)
        let changes =
          movedIds.compactMap { id in
            newPositions[id].map { NodeChange<NodeData>.position(id: id, position: $0) }
          } + parentChanges
        applyImmediateNodeDragChanges(changes)
        onNodeDrag?(node)

        let selectedNodes = nodes.filter(\.selected)
        if node.selected && selectedNodes.count > 1 {
          if !selectionDragStarted {
            selectionDragStarted = true
            onSelectionDragStart?(selectedNodes)
          }
          onSelectionDrag?(selectedNodes)
        }
      }
      .onEnded { _ in
        if let dragId = draggingNodeId, let dragNode = nodes.first(where: { $0.id == dragId }) {
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

  /// Applies `expandParent` to the moved nodes and keeps later drag steps
  /// relative to parents that moved (see `expandParentChanges`).
  private func expandParents(
    of movedIds: [String], positions: inout [String: XYPosition]
  ) -> [NodeChange<NodeData>] {
    let result = expandParentChanges(
      nodes: nodes, movedIds: movedIds, positions: positions,
      nodeSizes: nodeSizes, nodeOrigin: nodeOrigin)
    for (id, shift) in result.shifts {
      positions[id] = positions[id].map { $0 + shift }
      dragStartPositions[id] = dragStartPositions[id].map { $0 + shift }
    }
    return result.changes
  }

  /// Applies a resize step from `NodeResizeControl` (React Flow's resizer
  /// updates the node's dimensions, and its position for top/left handles).
  func applyNodeResize(_ event: NodeResizeEvent) {
    guard let node = nodes.first(where: { $0.id == event.nodeId }) else { return }
    switch event.phase {
    case .start:
      resizeStartPositions[node.id] = node.position
    case .change:
      break
    case .end:
      resizeStartPositions[node.id] = nil
      return
    }
    let start = resizeStartPositions[node.id] ?? node.position
    let offset = resizePositionOffset(
      for: event, origin: resolvedNodeOrigin(node, nodeOrigin: nodeOrigin))
    var changes: [NodeChange<NodeData>] = [
      .dimensions(id: node.id, width: event.size.width, height: event.size.height)
    ]
    let newPosition = start + offset
    if newPosition != node.position {
      changes.append(.position(id: node.id, position: newPosition))
    }
    applyImmediateNodeDragChanges(changes)
  }

  /// Reports drag changes without implicit animations so nodes track the pointer.
  private func applyImmediateNodeDragChanges(_ changes: [NodeChange<NodeData>]) {
    var transaction = Transaction(animation: nil)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      onNodesChange?(changes)
    }
  }
}

// MARK: - Connecting

extension SwiftFlow {

  /// Drag from a handle to create a new connection.
  func connectionDragGesture(key: String, handlePoint: CGPoint) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if connectionDraft == nil {
          guard let parsed = HandlePositionPreferenceKey.parseKey(key) else { return }
          let handleType = parsed.handleType ?? handleTypes[key] ?? .source
          let position = handleInfos[key]?.position ?? (handleType == .source ? .right : .left)
          connectionDraft = ConnectionDraft(
            nodeId: parsed.nodeId, handleId: handleIdOrNil(parsed.handleId),
            handleType: handleType, position: position,
            start: handlePoint, current: handlePoint, toPosition: oppositePosition(position))
          onConnectStart?(
            OnConnectStartParams(
              nodeId: parsed.nodeId, handleId: parsed.handleId, handleType: handleType))
        }
        updateConnectionDraft(
          to: CGPoint(
            x: handlePoint.x + value.translation.width,
            y: handlePoint.y + value.translation.height))
      }
      .onEnded { _ in
        finishConnectionDraft()
        onConnectEnd?()
      }
  }

  /// Drag of a reconnect anchor at one endpoint of a selected edge.
  func reconnectGesture(
    edge: Edge<EdgeData>, endpoint: HandleAnchor, anchor: HandleAnchor, isSourceEndpoint: Bool
  ) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        if connectionDraft == nil {
          // The line starts at the endpoint that stays attached.
          connectionDraft = ConnectionDraft(
            nodeId: isSourceEndpoint ? edge.target : edge.source,
            handleId: isSourceEndpoint ? edge.targetHandle : edge.sourceHandle,
            handleType: isSourceEndpoint ? .target : .source,
            position: anchor.position,
            start: anchor.point, current: endpoint.point, toPosition: endpoint.position,
            reconnectingEdge: edge)
        }
        updateConnectionDraft(
          to: CGPoint(
            x: endpoint.point.x + value.translation.width,
            y: endpoint.point.y + value.translation.height))
      }
      .onEnded { _ in
        finishConnectionDraft()
      }
  }

  /// Moves the draft end, snapping to the closest valid handle, and publishes
  /// the `ConnectionState`.
  private func updateConnectionDraft(to rawPoint: CGPoint) {
    guard var draft = connectionDraft else { return }
    if let snapped = findClosestHandle(to: rawPoint, for: draft) {
      draft.current = handlePositions[snapped.key] ?? rawPoint
      draft.toPosition = handleInfos[snapped.key]?.position ?? oppositePosition(draft.position)
      draft.target = (snapped.nodeId, snapped.handleId, snapped.handleType)
    } else {
      draft.current = rawPoint
      draft.toPosition = oppositePosition(draft.position)
      draft.target = nil
    }
    connectionDraft = draft
    publishConnectionState(draft)
  }

  private func publishConnectionState(_ draft: ConnectionDraft) {
    guard let fromNode = nodes.first(where: { $0.id == draft.nodeId }) else { return }
    var toHandle: NodeHandle?
    var toNode: AnyNodeSnapshot?
    var isValid: Bool?
    if let target = draft.target {
      toHandle = NodeHandle(
        id: target.handleId, type: target.handleType, position: draft.toPosition)
      toNode = nodes.first(where: { $0.id == target.nodeId }).map { AnyNodeSnapshot(from: $0) }
      isValid = connection(for: draft).map { isValidConnection?($0) ?? true } ?? false
    }
    flowState.activeConnection = ConnectionState(
      isValid: isValid,
      from: draft.start,
      fromHandle: NodeHandle(id: draft.handleId, type: draft.handleType, position: draft.position),
      fromPosition: draft.position,
      fromNode: AnyNodeSnapshot(from: fromNode),
      to: draft.current,
      toHandle: toHandle,
      toPosition: draft.toPosition,
      toNode: toNode
    )
  }

  /// The connection the draft would create. Dragging from a target handle
  /// produces a connection whose source is the dropped-on handle.
  private func connection(for draft: ConnectionDraft) -> Connection? {
    guard let target = draft.target else { return nil }
    if draft.handleType == .target {
      return Connection(
        source: target.nodeId, target: draft.nodeId,
        sourceHandle: target.handleId, targetHandle: draft.handleId)
    }
    return Connection(
      source: draft.nodeId, target: target.nodeId,
      sourceHandle: draft.handleId, targetHandle: target.handleId)
  }

  /// Completes the draft: calls `onConnect`, or `onReconnect` for reconnections,
  /// when the line ends on a valid handle.
  private func finishConnectionDraft() {
    defer {
      connectionDraft = nil
      flowState.activeConnection = nil
    }
    guard let draft = connectionDraft, let connection = connection(for: draft),
      isValidConnection?(connection) ?? true
    else { return }
    if let edge = draft.reconnectingEdge {
      guard let onReconnect else { return }
      onReconnect(edge, connection)
    } else {
      guard let onConnect else { return }
      onConnect(connection)
    }
    if accessibilityConfig.announceConnectionEvents {
      flowState.announcer.announce(accessibilityConfig.connectionAnnouncement(connection))
    }
  }

  /// The closest connectable handle within snapping distance that may
  /// complete `draft` under the current `connectionMode`.
  private func findClosestHandle(to point: CGPoint, for draft: ConnectionDraft) -> (
    key: String, nodeId: String, handleId: String?, handleType: HandleType
  )? {
    let threshold: CGFloat = 40
    let connectableNodes = Set(nodes.filter(\.connectable).map(\.id))
    var best: (key: String, distance: CGFloat, nodeId: String, handleId: String, type: HandleType)?
    for (key, position) in handlePositions {
      guard let parsed = HandlePositionPreferenceKey.parseKey(key),
        parsed.nodeId != draft.nodeId,
        connectableNodes.contains(parsed.nodeId),
        handleInfos[key]?.isConnectable ?? true
      else { continue }
      let type = parsed.handleType ?? handleTypes[key] ?? oppositeType(draft.handleType)
      if connectionMode == .strict && type == draft.handleType { continue }
      let distance = hypot(position.x - point.x, position.y - point.y)
      // Ties are broken by key so the result does not depend on dictionary order.
      if distance <= threshold
        && (best == nil || distance < best!.distance
          || (distance == best!.distance && key < best!.key))
      {
        best = (key, distance, parsed.nodeId, parsed.handleId, type)
      }
    }
    guard let best else { return nil }
    return (best.key, best.nodeId, handleIdOrNil(best.handleId), best.type)
  }

  private func oppositeType(_ type: HandleType) -> HandleType {
    type == .source ? .target : .source
  }

  /// Handles without an ID are represented as `nil`, like React Flow's `null`.
  private func handleIdOrNil(_ id: String) -> String? {
    id.isEmpty ? nil : id
  }
}
