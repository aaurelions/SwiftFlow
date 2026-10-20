import SwiftUI

// MARK: - Selection

extension SwiftFlow {

  /// Whether the multi-selection key (Command on macOS, React Flow's
  /// `multiSelectionKeyCode`) is held.
  private var isMultiSelectionActive: Bool {
    #if canImport(AppKit)
      NSEvent.modifierFlags.contains(.command)
    #else
      false
    #endif
  }

  /// Selects `node`. Without the multi-selection key, every other node and
  /// edge is deselected; with it, the node's selection is toggled.
  func selectNode(_ node: Node<NodeData>) {
    if isMultiSelectionActive {
      onNodesChange?([.selection(id: node.id, selected: !node.selected)])
      return
    }
    var nodeChanges = nodes.filter { $0.selected && $0.id != node.id }
      .map { NodeChange<NodeData>.selection(id: $0.id, selected: false) }
    if !node.selected { nodeChanges.append(.selection(id: node.id, selected: true)) }
    let edgeChanges: [EdgeChange<EdgeData>] = edges.filter(\.selected)
      .map { .selection(id: $0.id, selected: false) }
    if !nodeChanges.isEmpty { onNodesChange?(nodeChanges) }
    if !edgeChanges.isEmpty { onEdgesChange?(edgeChanges) }
  }

  /// Selects `edge`. Without the multi-selection key, every other edge and
  /// node is deselected; with it, the edge's selection is toggled.
  func selectEdge(_ edge: Edge<EdgeData>) {
    if isMultiSelectionActive {
      onEdgesChange?([.selection(id: edge.id, selected: !edge.selected)])
      return
    }
    var edgeChanges: [EdgeChange<EdgeData>] = edges.filter { $0.selected && $0.id != edge.id }
      .map { .selection(id: $0.id, selected: false) }
    if !edge.selected { edgeChanges.append(.selection(id: edge.id, selected: true)) }
    let nodeChanges = nodes.filter(\.selected)
      .map { NodeChange<NodeData>.selection(id: $0.id, selected: false) }
    if !edgeChanges.isEmpty { onEdgesChange?(edgeChanges) }
    if !nodeChanges.isEmpty { onNodesChange?(nodeChanges) }
  }

  func deselectAll() {
    let nodeChanges = nodes.filter(\.selected).map {
      NodeChange<NodeData>.selection(id: $0.id, selected: false)
    }
    if !nodeChanges.isEmpty { onNodesChange?(nodeChanges) }
    let edgeChanges: [EdgeChange<EdgeData>] = edges.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    if !edgeChanges.isEmpty { onEdgesChange?(edgeChanges) }
  }

  private func selectAll() {
    let nodeChanges = nodes.filter { !$0.selected && $0.selectable }.map {
      NodeChange<NodeData>.selection(id: $0.id, selected: true)
    }
    let edgeChanges: [EdgeChange<EdgeData>] = edges.filter { !$0.selected }.map {
      .selection(id: $0.id, selected: true)
    }
    if !nodeChanges.isEmpty { onNodesChange?(nodeChanges) }
    if !edgeChanges.isEmpty { onEdgesChange?(edgeChanges) }
  }

  /// Reports `onSelectionChange` and announces the selection when the
  /// selected IDs differ from the last report.
  func checkSelectionChange() {
    guard onSelectionChange != nil || accessibilityConfig.announceSelectionChanges else { return }
    let selectedNodes = nodes.filter(\.selected)
    let selectedEdges = edges.filter(\.selected)
    let nodeIds = Set(selectedNodes.map(\.id))
    let edgeIds = Set(selectedEdges.map(\.id))
    guard nodeIds != previousSelectedNodes || edgeIds != previousSelectedEdges else { return }
    previousSelectedNodes = nodeIds
    previousSelectedEdges = edgeIds
    onSelectionChange?(selectedNodes, selectedEdges)
    if accessibilityConfig.announceSelectionChanges {
      flowState.announcer.announce(
        accessibilityConfig.selectionAnnouncement(nodeIds.count, edgeIds.count),
        after: .milliseconds(400))
    }
  }
}

// MARK: - Keyboard (macOS)

#if canImport(AppKit)
  extension SwiftFlow {
    /// Handles canvas shortcuts. Returns `true` when the event was consumed.
    func handleKeyEvent(_ event: NSEvent) -> Bool {
      let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      let hasCommand = flags.contains(.command)
      let hasShift = flags.contains(.shift)
      // `charactersIgnoringModifiers` still applies Shift ("Z" for Shift+Z).
      let key = event.charactersIgnoringModifiers?.lowercased()

      if !hasCommand, let handled = handleFocusKey(event.keyCode, hasShift: hasShift) {
        return handled
      }

      if !hasCommand
        && (event.keyCode == keyboardShortcuts.deleteKeyCode
          || event.keyCode == keyboardShortcuts.forwardDeleteKeyCode)
      {
        deleteSelected()
        return true
      }

      if hasCommand {
        switch (key, hasShift) {
        case ("a", false): selectAll()
        case ("c", false): copySelected()
        case ("v", false): pasteClipboard()
        case ("z", false): undo()
        case ("z", true): redo()
        default: return false
        }
        return true
      }

      let nudge = hasShift ? keyboardShortcuts.shiftNudgeDistance : keyboardShortcuts.nudgeDistance
      switch event.keyCode {
      case KeyCode.leftArrow.rawValue: nudgeSelected(dx: -nudge, dy: 0)
      case KeyCode.rightArrow.rawValue: nudgeSelected(dx: nudge, dy: 0)
      case KeyCode.downArrow.rawValue: nudgeSelected(dx: 0, dy: nudge)
      case KeyCode.upArrow.rawValue: nudgeSelected(dx: 0, dy: -nudge)
      default: return false
      }
      return true
    }
  }
#endif

// MARK: - Keyboard Focus

extension SwiftFlow {
  /// A node or edge that can receive keyboard focus.
  enum FocusedElement: Hashable {
    case node(String)
    case edge(String)
  }

  /// Visible focusable elements in focus order: nodes, then edges.
  var focusOrder: [FocusedElement] {
    nodes.filter { !$0.hidden && $0.focusable }.map { .node($0.id) }
      + edges.filter { !$0.hidden && $0.focusable }.map { .edge($0.id) }
  }

  /// Handles React Flow's focus keys: Tab / Shift+Tab move focus, Enter and
  /// Space select the focused element, and Escape deselects.
  ///
  /// - Returns: Whether the key was consumed, or `nil` when it is not a focus key.
  func handleFocusKey(_ keyCode: UInt16, hasShift: Bool) -> Bool? {
    switch keyCode {
    case KeyCode.tab.rawValue:
      return moveFocus(backward: hasShift)
    case KeyCode.return.rawValue, KeyCode.space.rawValue:
      return activateFocusedElement()
    case KeyCode.escape.rawValue:
      let hadSelection = nodes.contains(where: \.selected) || edges.contains(where: \.selected)
      deselectAll()
      return hadSelection
    default:
      return nil
    }
  }

  /// Moves focus to the next (or previous) focusable element, wrapping around.
  /// Focusing a node outside the view pans it to the center.
  func moveFocus(backward: Bool) -> Bool {
    let order = focusOrder
    guard !order.isEmpty else { return false }
    let next: FocusedElement
    if let current = focusedElement, let index = order.firstIndex(of: current) {
      next = order[(index + (backward ? order.count - 1 : 1)) % order.count]
    } else {
      next = backward ? order[order.count - 1] : order[0]
    }
    focusedElement = next
    if case .node(let id) = next, let node = nodes.first(where: { $0.id == id }) {
      let topLeft = topLeftPositions[id] ?? node.position
      let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
      if !isNodeVisible(topLeft, size: size) {
        let center = CGPoint(x: topLeft.x + size.width / 2, y: topLeft.y + size.height / 2)
        withAnimation(.easeInOut(duration: 0.3)) {
          viewport = .centered(on: center, zoom: viewport.zoom, viewSize: viewSize)
        }
      }
    }
    return true
  }

  /// Selects the focused element. Returns `false` when nothing is focused.
  private func activateFocusedElement() -> Bool {
    guard flowState.isInteractive, elementsSelectable else { return false }
    switch focusedElement {
    case .node(let id):
      guard let node = nodes.first(where: { $0.id == id }), node.selectable else { return false }
      selectNode(node)
    case .edge(let id):
      guard let edge = edges.first(where: { $0.id == id }) else { return false }
      selectEdge(edge)
    case nil:
      return false
    }
    return true
  }
}

// MARK: - Editing

extension SwiftFlow {

  private func deleteSelected() {
    requestDeletion(
      nodeIds: nodes.filter(\.selected).map(\.id),
      edgeIds: edges.filter(\.selected).map(\.id))
  }

  /// Deletes elements after resolving descendants and connected edges and
  /// consulting `onBeforeDelete`.
  func requestDeletion(nodeIds: [String], edgeIds: [String]) {
    let (nodesToDelete, edgesToDelete) = elementsToDelete(
      nodes: nodes, edges: edges, nodeIds: nodeIds, edgeIds: edgeIds)
    guard !nodesToDelete.isEmpty || !edgesToDelete.isEmpty else { return }

    guard let onBeforeDelete else {
      performDeletion(nodesToDelete: nodesToDelete, edgesToDelete: edgesToDelete)
      return
    }
    Task { @MainActor in
      switch await onBeforeDelete(nodesToDelete, edgesToDelete) {
      case .cancel:
        return
      case .delete(let filteredNodes, let filteredEdges):
        performDeletion(nodesToDelete: filteredNodes, edgesToDelete: filteredEdges)
      case nil:
        performDeletion(nodesToDelete: nodesToDelete, edgesToDelete: edgesToDelete)
      }
    }
  }

  private func performDeletion(nodesToDelete: [Node<NodeData>], edgesToDelete: [Edge<EdgeData>]) {
    guard !nodesToDelete.isEmpty || !edgesToDelete.isEmpty else { return }
    pushUndoState()
    if !nodesToDelete.isEmpty {
      onNodesChange?(nodesToDelete.map { .remove(id: $0.id) })
      onNodesDelete?(nodesToDelete)
    }
    if !edgesToDelete.isEmpty {
      onEdgesChange?(edgesToDelete.map { .remove(id: $0.id) })
      onEdgesDelete?(edgesToDelete)
    }
    onDelete?(nodesToDelete, edgesToDelete)
  }

  /// Moves the selected draggable nodes by the given distance.
  private func nudgeSelected(dx: CGFloat, dy: CGFloat) {
    guard nodesDraggable else { return }
    let changes: [NodeChange<NodeData>] = nodes.filter { $0.selected && $0.draggable }.map {
      node in
      var position = node.position + XYPosition(x: dx, y: dy)
      if snapToGrid { position = position.snapped(to: snapGrid) }
      position = resolveExtent(for: node).clamp(position)
      return .position(id: node.id, position: position)
    }
    if !changes.isEmpty { onNodesChange?(changes) }
  }

  /// Copies the selected nodes and the edges between them.
  private func copySelected() {
    let selectedNodes = nodes.filter(\.selected)
    let ids = Set(selectedNodes.map(\.id))
    let selectedEdges = edges.filter { ids.contains($0.source) && ids.contains($0.target) }
    clipboard = (nodes: selectedNodes, edges: selectedEdges)
  }

  /// Adds copies of the clipboard with new IDs, offset by 50 points, and selects them.
  private func pasteClipboard() {
    guard let clip = clipboard, !clip.nodes.isEmpty else { return }
    pushUndoState()
    let offset = XYPosition(x: 50, y: 50)
    let suffix = UUID().uuidString.prefix(8)
    var idMap: [String: String] = [:]
    for node in clip.nodes { idMap[node.id] = "\(node.id)-copy-\(suffix)" }

    var nodeChanges: [NodeChange<NodeData>] = nodes.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    for node in clip.nodes {
      var copy = node
      copy.id = idMap[node.id] ?? node.id
      copy.selected = true
      if let parentId = node.parentId, let copiedParentId = idMap[parentId] {
        // Children of copied parents keep their relative position.
        copy.parentId = copiedParentId
      } else {
        copy.position = copy.position + offset
      }
      nodeChanges.append(.add(item: copy))
    }
    onNodesChange?(nodeChanges)

    var edgeChanges: [EdgeChange<EdgeData>] = edges.filter(\.selected).map {
      .selection(id: $0.id, selected: false)
    }
    for edge in clip.edges {
      guard let source = idMap[edge.source], let target = idMap[edge.target] else { continue }
      var copy = edge
      copy.id = "\(edge.id)-copy-\(suffix)"
      copy.source = source
      copy.target = target
      copy.selected = true
      edgeChanges.append(.add(item: copy))
    }
    if !edgeChanges.isEmpty { onEdgesChange?(edgeChanges) }
  }

  // MARK: Undo / Redo

  /// Records the graph before a deletion or paste (at most 50 steps).
  private func pushUndoState() {
    undoStack.append((nodes: nodes, edges: edges))
    redoStack.removeAll()
    if undoStack.count > 50 { undoStack.removeFirst() }
  }

  private func undo() {
    guard let previous = undoStack.popLast() else { return }
    redoStack.append((nodes: nodes, edges: edges))
    restoreState(previous)
  }

  private func redo() {
    guard let next = redoStack.popLast() else { return }
    undoStack.append((nodes: nodes, edges: edges))
    restoreState(next)
  }

  private func restoreState(_ state: GraphSnapshot) {
    onNodesChange?(nodes.map { .remove(id: $0.id) } + state.nodes.map { .add(item: $0) })
    onEdgesChange?(edges.map { .remove(id: $0.id) } + state.edges.map { .add(item: $0) })
  }
}

// MARK: - Snap Lines

extension SwiftFlow {

  /// Alignment guides between the dragged node and the other visible nodes,
  /// in flow coordinates. Edge alignments win over center alignments at the
  /// same position.
  func computeSnapLines(for node: Node<NodeData>, translation: XYPosition) -> [SnapLine] {
    let threshold: CGFloat = 5
    let overhang: CGFloat = 20
    let positions = topLeftPositions
    let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
    // Convert the parent-relative start position to flow coordinates.
    let toAbsolute = (positions[node.id] ?? node.position) - node.position
    let start = (dragStartPositions[node.id] ?? node.position) + toAbsolute + translation
    let dragged = CGRect(x: start.x, y: start.y, width: size.width, height: size.height)

    // Keyed by rounded coordinate to merge nearly identical lines.
    var vertical: [CGFloat: (line: SnapLine, isEdge: Bool)] = [:]
    var horizontal: [CGFloat: (line: SnapLine, isEdge: Bool)] = [:]

    func add(
      _ lines: inout [CGFloat: (line: SnapLine, isEdge: Bool)], at value: CGFloat,
      isEdge: Bool, line: SnapLine
    ) {
      let key = (value / threshold).rounded() * threshold
      if let existing = lines[key], existing.isEdge || !isEdge { return }
      lines[key] = (line, isEdge)
    }

    for other in nodes where other.id != node.id && !other.hidden {
      let topLeft = positions[other.id] ?? other.position
      let otherSize = resolvedNodeSize(other, nodeSizes: nodeSizes)
      let rect = CGRect(
        x: topLeft.x, y: topLeft.y, width: otherSize.width, height: otherSize.height)
      let y1 = min(dragged.minY, rect.minY) - overhang
      let y2 = max(dragged.maxY, rect.maxY) + overhang
      let x1 = min(dragged.minX, rect.minX) - overhang
      let x2 = max(dragged.maxX, rect.maxX) + overhang

      // Vertical lines (x alignment): edges first, then centers.
      for (draggedX, otherX) in [
        (dragged.minX, rect.minX), (dragged.maxX, rect.maxX),
        (dragged.minX, rect.maxX), (dragged.maxX, rect.minX),
      ] where abs(draggedX - otherX) < threshold {
        add(
          &vertical, at: otherX, isEdge: true,
          line: SnapLine(start: CGPoint(x: otherX, y: y1), end: CGPoint(x: otherX, y: y2)))
      }
      if abs(dragged.midX - rect.midX) < threshold {
        add(
          &vertical, at: rect.midX, isEdge: false,
          line: SnapLine(start: CGPoint(x: rect.midX, y: y1), end: CGPoint(x: rect.midX, y: y2)))
      }

      // Horizontal lines (y alignment): edges first, then centers.
      for (draggedY, otherY) in [
        (dragged.minY, rect.minY), (dragged.maxY, rect.maxY),
        (dragged.minY, rect.maxY), (dragged.maxY, rect.minY),
      ] where abs(draggedY - otherY) < threshold {
        add(
          &horizontal, at: otherY, isEdge: true,
          line: SnapLine(start: CGPoint(x: x1, y: otherY), end: CGPoint(x: x2, y: otherY)))
      }
      if abs(dragged.midY - rect.midY) < threshold {
        add(
          &horizontal, at: rect.midY, isEdge: false,
          line: SnapLine(start: CGPoint(x: x1, y: rect.midY), end: CGPoint(x: x2, y: rect.midY)))
      }
    }
    return vertical.values.map(\.line) + horizontal.values.map(\.line)
  }
}

// MARK: - Extents and Fitting

extension SwiftFlow {

  /// The extent a node's `position` is clamped to while dragging.
  func resolveExtent(for node: Node<NodeData>) -> CoordinateExtent {
    switch node.extent {
    case nil: return coordinateExtent
    case .coordinateExtent(let extent): return extent
    case .parent:
      // With `expandParent` the parent grows to the right and bottom instead.
      return node.expandParent
        ? CoordinateExtent(minX: 0, minY: 0, maxX: .infinity, maxY: .infinity)
        : parentExtent(for: node)
    }
  }

  /// Keeps a child inside its parent's bounds (positions are parent-relative).
  private func parentExtent(for node: Node<NodeData>) -> CoordinateExtent {
    guard let parentId = node.parentId, let parent = nodes.first(where: { $0.id == parentId })
    else { return coordinateExtent }
    let parentSize = resolvedNodeSize(parent, nodeSizes: nodeSizes)
    let nodeSize = resolvedNodeSize(node, nodeSizes: nodeSizes)
    return CoordinateExtent(
      minX: 0, minY: 0,
      maxX: max(0, parentSize.width - nodeSize.width),
      maxY: max(0, parentSize.height - nodeSize.height)
    )
  }

  /// Sets the viewport so the nodes selected by `options` fit the view.
  func fitToContent(options: FitViewOptions) {
    let idSet = options.nodeIds.map(Set.init)
    let targets = nodes.filter {
      (options.includeHiddenNodes || !$0.hidden) && (idSet?.contains($0.id) ?? true)
    }
    let bounds = nodesBoundingRect(
      nodes: targets, topLeftPositions: topLeftPositions, nodeSizes: nodeSizes)
    if let fitted = fitViewport(bounds: bounds, viewSize: viewSize, options: options) {
      viewport = fitted
    }
  }
}
