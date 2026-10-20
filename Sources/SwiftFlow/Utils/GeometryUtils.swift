import Foundation

/// Type alias for bounding box rectangles.
public typealias Rect = CGRect

// MARK: - Node Geometry (internal)

/// Size used for nodes that are neither measured nor given an explicit `width`/`height`.
let defaultNodeSize = CGSize(width: 150, height: 50)

/// Returns a node's size: the measured size, else its explicit `width`/`height`,
/// else ``defaultNodeSize``.
func resolvedNodeSize<T>(_ node: Node<T>, nodeSizes: [String: CGSize]) -> CGSize {
  if let measured = nodeSizes[node.id] { return measured }
  return CGSize(
    width: node.width ?? defaultNodeSize.width, height: node.height ?? defaultNodeSize.height)
}

/// Returns the origin used to anchor `node`: its own `origin` when set to a
/// non-default value, otherwise the canvas-wide `nodeOrigin`.
func resolvedNodeOrigin<T>(_ node: Node<T>, nodeOrigin: NodeOrigin) -> NodeOrigin {
  node.origin != .topLeft ? node.origin : nodeOrigin
}

/// Computes the top-left corner of every node in flow coordinates.
///
/// Mirrors React Flow's absolute positioning: a child's `position` is relative
/// to its parent's top-left corner, and the node origin shifts the node by
/// `origin * size`.
///
/// - Parameter onCycle: Called with the ID of a node whose parent chain is cyclic.
///   The cyclic link is ignored.
func nodeTopLeftPositions<T>(
  nodes: [Node<T>],
  nodeSizes: [String: CGSize],
  nodeOrigin: NodeOrigin = .topLeft,
  onCycle: ((String) -> Void)? = nil
) -> [String: XYPosition] {
  var nodeMap: [String: Node<T>] = [:]
  for node in nodes { nodeMap[node.id] = node }
  var result: [String: XYPosition] = [:]

  func resolve(_ id: String, visiting: inout Set<String>) -> XYPosition? {
    if let cached = result[id] { return cached }
    guard let node = nodeMap[id] else { return nil }
    guard visiting.insert(id).inserted else {
      onCycle?(id)
      return nil
    }
    var position = node.position
    if let parentId = node.parentId, let parentTopLeft = resolve(parentId, visiting: &visiting) {
      position = position + parentTopLeft
    }
    let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
    let origin = resolvedNodeOrigin(node, nodeOrigin: nodeOrigin)
    position = position - XYPosition(x: origin.x * size.width, y: origin.y * size.height)
    result[id] = position
    return position
  }

  for node in nodes {
    var visiting = Set<String>()
    _ = resolve(node.id, visiting: &visiting)
  }
  return result
}

/// Returns the union of the rendered rectangles of `nodes`, or `nil` when empty.
func nodesBoundingRect<T>(
  nodes: [Node<T>],
  topLeftPositions: [String: XYPosition],
  nodeSizes: [String: CGSize]
) -> CGRect? {
  var bounds: CGRect?
  for node in nodes {
    let topLeft = topLeftPositions[node.id] ?? node.position
    let size = resolvedNodeSize(node, nodeSizes: nodeSizes)
    let rect = CGRect(x: topLeft.x, y: topLeft.y, width: size.width, height: size.height)
    bounds = bounds.map { $0.union(rect) } ?? rect
  }
  return bounds
}

// MARK: - Public Utilities

/// Returns the bounding box containing all visible nodes in flow coordinates.
///
/// Child positions are resolved relative to their parents when the parent is
/// part of `nodes`, and each node's `origin` is applied. Unmeasured nodes use
/// their explicit `width`/`height`, or 150 × 50 points.
///
/// - Returns: The bounds, or `.zero` when no node is visible.
public func getNodesBounds<T: Equatable & Sendable>(
  nodes: [Node<T>],
  nodeSizes: [String: CGSize]
) -> CGRect {
  visibleNodesBounds(nodes: nodes, nodeSizes: nodeSizes)
}

/// Shared implementation of `getNodesBounds`, callable from types that declare
/// a method with the same name.
func visibleNodesBounds<T>(nodes: [Node<T>], nodeSizes: [String: CGSize]) -> CGRect {
  let positions = nodeTopLeftPositions(nodes: nodes, nodeSizes: nodeSizes)
  let visible = nodes.filter { !$0.hidden }
  return nodesBoundingRect(nodes: visible, topLeftPositions: positions, nodeSizes: nodeSizes)
    ?? .zero
}

/// Returns the viewport that centers `bounds` within a view of `viewportSize`.
///
/// - Parameters:
///   - minZoom: Lower zoom limit.
///   - maxZoom: Upper zoom limit.
///   - padding: Space in points kept free on every side of the bounds.
public func getViewportForBounds(
  bounds: CGRect,
  viewportSize: CGSize,
  minZoom: CGFloat = Viewport.minZoom,
  maxZoom: CGFloat = Viewport.maxZoom,
  padding: CGFloat = 80
) -> Viewport {
  fittedViewport(
    fitting: bounds, in: viewportSize, minZoom: minZoom, maxZoom: maxZoom, padding: padding)
}

/// Shared implementation of `getViewportForBounds`.
func fittedViewport(
  fitting bounds: CGRect, in viewportSize: CGSize,
  minZoom: CGFloat, maxZoom: CGFloat, padding: CGFloat
) -> Viewport {
  let contentWidth = max(bounds.width, 1)
  let contentHeight = max(bounds.height, 1)
  let availableWidth = max(1, viewportSize.width - padding * 2)
  let availableHeight = max(1, viewportSize.height - padding * 2)
  let fittedZoom = min(availableWidth / contentWidth, availableHeight / contentHeight)
  let zoom = max(min(fittedZoom, maxZoom), minZoom)
  return Viewport(
    x: viewportSize.width / 2 - bounds.midX * zoom,
    y: viewportSize.height / 2 - bounds.midY * zoom,
    zoom: zoom
  )
}

/// Returns `true` when `element` is a `Node` with data of type `T`.
public func isNode<T: Equatable & Sendable>(_ element: Any, ofType: T.Type = T.self) -> Bool {
  element is Node<T>
}

/// Returns `true` when `element` is an `Edge` with data of type `EdgeData`.
public func isEdge<EdgeData: Equatable & Sendable & Hashable>(
  _ element: Any,
  ofType: EdgeData.Type
) -> Bool {
  element is Edge<EdgeData>
}

// MARK: - Viewport Math (internal)

extension Viewport {
  /// Returns a viewport at `zoom` (clamped to the allowed range) that keeps
  /// the flow point under `anchor` (a view coordinate) fixed on screen.
  func zoomed(to zoom: CGFloat, around anchor: CGPoint) -> Viewport {
    let currentZoom = max(self.zoom, Viewport.minZoom)
    let flowX = (anchor.x - x) / currentZoom
    let flowY = (anchor.y - y) / currentZoom
    let newZoom = max(Viewport.minZoom, min(zoom, Viewport.maxZoom))
    return Viewport(x: anchor.x - flowX * newZoom, y: anchor.y - flowY * newZoom, zoom: newZoom)
  }

  /// Returns a viewport that centers the flow point `center` in a view of `viewSize`.
  static func centered(on center: CGPoint, zoom: CGFloat, viewSize: CGSize) -> Viewport {
    Viewport(
      x: viewSize.width / 2 - center.x * zoom,
      y: viewSize.height / 2 - center.y * zoom,
      zoom: zoom)
  }
}

/// Returns the viewport that fits `bounds`, or `nil` when there is nothing to fit.
func fitViewport(bounds: CGRect?, viewSize: CGSize, options: FitViewOptions) -> Viewport? {
  guard let bounds, bounds.width > 0, bounds.height > 0, viewSize != .zero else { return nil }
  return fittedViewport(
    fitting: bounds, in: viewSize,
    minZoom: options.minZoom, maxZoom: options.maxZoom, padding: options.padding)
}

// MARK: - Expand Parent (internal)

/// React Flow's `expandParent`: grows the parents of moved nodes that set
/// `expandParent` so their children stay inside. A child moved past the
/// parent's top or left edge moves the parent instead, and the parent's
/// children shift so every node keeps its place in flow coordinates.
///
/// - Parameters:
///   - movedIds: IDs of the nodes being moved.
///   - positions: New parent-relative positions of the moved nodes.
/// - Returns: Parent dimension/position changes and position changes for
///   unmoved siblings (`changes`), plus the shift to add to each moved node's
///   new position (`shifts`).
func expandParentChanges<T>(
  nodes: [Node<T>],
  movedIds: [String],
  positions: [String: XYPosition],
  nodeSizes: [String: CGSize],
  nodeOrigin: NodeOrigin = .topLeft
) -> (changes: [NodeChange<T>], shifts: [String: XYPosition]) {
  var nodeById: [String: Node<T>] = [:]
  for node in nodes where nodeById[node.id] == nil { nodeById[node.id] = node }
  var childrenByParent: [String: [Node<T>]] = [:]
  for id in movedIds {
    guard let child = nodeById[id], child.expandParent, let parentId = child.parentId,
      nodeById[parentId] != nil
    else { continue }
    childrenByParent[parentId, default: []].append(child)
  }

  var changes: [NodeChange<T>] = []
  var shifts: [String: XYPosition] = [:]
  for (parentId, children) in childrenByParent.sorted(by: { $0.key < $1.key }) {
    guard let parent = nodeById[parentId] else { continue }
    let parentSize = resolvedNodeSize(parent, nodeSizes: nodeSizes)
    var bounds = CGRect(origin: .zero, size: parentSize)
    for child in children {
      guard let position = positions[child.id] else { continue }
      let size = resolvedNodeSize(child, nodeSizes: nodeSizes)
      let origin = resolvedNodeOrigin(child, nodeOrigin: nodeOrigin)
      bounds = bounds.union(
        CGRect(
          x: position.x - origin.x * size.width, y: position.y - origin.y * size.height,
          width: size.width, height: size.height))
    }
    guard bounds != CGRect(origin: .zero, size: parentSize) else { continue }

    changes.append(.dimensions(id: parentId, width: bounds.width, height: bounds.height))
    let parentOrigin = resolvedNodeOrigin(parent, nodeOrigin: nodeOrigin)
    let parentPosition =
      parent.position
      + XYPosition(
        x: bounds.minX + parentOrigin.x * (bounds.width - parentSize.width),
        y: bounds.minY + parentOrigin.y * (bounds.height - parentSize.height))
    if parentPosition != parent.position {
      changes.append(.position(id: parentId, position: parentPosition))
    }

    // The parent's top-left moved by `bounds.origin`; shift its children back.
    let shift = XYPosition(x: -bounds.minX, y: -bounds.minY)
    guard shift != .zero else { continue }
    for sibling in nodes where sibling.parentId == parentId {
      if positions[sibling.id] != nil {
        shifts[sibling.id] = shift
      } else {
        changes.append(.position(id: sibling.id, position: sibling.position + shift))
      }
    }
  }
  return (changes, shifts)
}
