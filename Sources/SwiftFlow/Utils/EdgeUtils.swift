import SwiftUI

// MARK: - Edge Creation

/// Returns the React Flow edge identifier for a connection:
/// `xy-edge__{source}{sourceHandle}-{target}{targetHandle}`.
func edgeId(for connection: Connection) -> String {
  "xy-edge__\(connection.source)\(connection.sourceHandle ?? "")"
    + "-\(connection.target)\(connection.targetHandle ?? "")"
}

/// Returns `true` when `edges` already contains an edge with the same source,
/// target, and handles. A `nil` handle and an empty handle ID are treated as equal.
func connectionExists<EdgeData>(_ connection: Connection, in edges: [Edge<EdgeData>]) -> Bool {
  edges.contains {
    $0.source == connection.source && $0.target == connection.target
      && ($0.sourceHandle ?? "") == (connection.sourceHandle ?? "")
      && ($0.targetHandle ?? "") == (connection.targetHandle ?? "")
  }
}

/// Creates an edge from a `Connection` and appends it, preventing duplicates.
///
/// Mirrors React Flow's `addEdge`: the connection is ignored when an edge with
/// the same source, target, `sourceHandle`, and `targetHandle` already exists.
/// Edges between the same nodes but different handles are allowed. The new
/// edge receives the React Flow identifier format
/// `xy-edge__{source}{sourceHandle}-{target}{targetHandle}`.
///
/// - Parameters:
///   - connection: The connection to convert into an edge.
///   - edges: The current edges.
///   - defaults: Options applied to the new edge (see ``DefaultEdgeOptions``).
/// - Returns: The edges with the new edge appended, or `edges` unchanged for duplicates.
public func addEdge<EdgeData: Equatable & Sendable & Hashable>(
  _ connection: Connection,
  edges: [Edge<EdgeData>],
  defaults: DefaultEdgeOptions? = nil
) -> [Edge<EdgeData>] {
  guard !connectionExists(connection, in: edges) else { return edges }
  var newEdge = Edge<EdgeData>(
    id: edgeId(for: connection),
    source: connection.source,
    target: connection.target,
    sourceHandle: connection.sourceHandle,
    targetHandle: connection.targetHandle
  )
  if let defaults { newEdge = defaults.applied(to: newEdge) }
  return edges + [newEdge]
}

/// Reconnects an existing edge to a new connection, preserving all other edge properties.
///
/// Use it in the `onReconnect` callback:
///
/// ```swift
/// onReconnect: { oldEdge, connection in
///     edges = reconnectEdge(oldEdge, connection, edges)
/// }
/// ```
///
/// - Returns: The updated edges, or `edges` unchanged when `oldEdge` is not present.
public func reconnectEdge<EdgeData: Equatable & Sendable & Hashable>(
  _ oldEdge: Edge<EdgeData>,
  _ newConnection: Connection,
  _ edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>] {
  var result = edges
  guard let index = result.firstIndex(where: { $0.id == oldEdge.id }) else { return result }
  result[index].source = newConnection.source
  result[index].target = newConnection.target
  result[index].sourceHandle = newConnection.sourceHandle
  result[index].targetHandle = newConnection.targetHandle
  return result
}

// MARK: - Path Geometry Helpers

/// Unit vector pointing away from the node for a handle on the given side.
func handleDirection(_ position: Position) -> CGPoint {
  switch position {
  case .left: return CGPoint(x: -1, y: 0)
  case .right: return CGPoint(x: 1, y: 0)
  case .top: return CGPoint(x: 0, y: -1)
  case .bottom: return CGPoint(x: 0, y: 1)
  }
}

/// The side opposite to `position` (React Flow's `oppositePosition`).
func oppositePosition(_ position: Position) -> Position {
  switch position {
  case .left: return .right
  case .right: return .left
  case .top: return .bottom
  case .bottom: return .top
  }
}

/// Center point between two coordinates and its offset from them
/// (React Flow's `getEdgeCenter`).
func getEdgeCenter(
  sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> (x: CGFloat, y: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let offsetX = abs(targetX - sourceX) / 2
  let offsetY = abs(targetY - sourceY) / 2
  let centerX = targetX < sourceX ? targetX + offsetX : targetX - offsetX
  let centerY = targetY < sourceY ? targetY + offsetY : targetY - offsetY
  return (centerX, centerY, offsetX, offsetY)
}

/// Point at `t = 0.5` on a cubic bezier, plus its offset from the source
/// (React Flow's `getBezierEdgeCenter`).
private func bezierEdgeCenter(
  source: CGPoint, sourceControl: CGPoint, targetControl: CGPoint, target: CGPoint
) -> (x: CGFloat, y: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let x = source.x * 0.125 + sourceControl.x * 0.375 + targetControl.x * 0.375 + target.x * 0.125
  let y = source.y * 0.125 + sourceControl.y * 0.375 + targetControl.y * 0.375 + target.y * 0.125
  return (x, y, abs(x - source.x), abs(y - source.y))
}

private func cubicPath(
  from source: CGPoint, _ sourceControl: CGPoint, _ targetControl: CGPoint, to target: CGPoint
) -> Path {
  var path = Path()
  path.move(to: source)
  path.addCurve(to: target, control1: sourceControl, control2: targetControl)
  return path
}

// MARK: - Bezier

/// Control-point distance used by React Flow: half the distance when the
/// target lies in front of the handle, otherwise a curvature-scaled loop.
private func calculateControlOffset(_ distance: CGFloat, curvature: CGFloat) -> CGFloat {
  distance >= 0 ? 0.5 * distance : curvature * 25 * sqrt(-distance)
}

private func controlWithCurvature(
  position: Position, from p1: CGPoint, to p2: CGPoint, curvature: CGFloat
) -> CGPoint {
  switch position {
  case .left:
    return CGPoint(x: p1.x - calculateControlOffset(p1.x - p2.x, curvature: curvature), y: p1.y)
  case .right:
    return CGPoint(x: p1.x + calculateControlOffset(p2.x - p1.x, curvature: curvature), y: p1.y)
  case .top:
    return CGPoint(x: p1.x, y: p1.y - calculateControlOffset(p1.y - p2.y, curvature: curvature))
  case .bottom:
    return CGPoint(x: p1.x, y: p1.y + calculateControlOffset(p2.y - p1.y, curvature: curvature))
  }
}

/// Returns a cubic bezier path whose control points follow the handle sides.
///
/// Port of React Flow's `getBezierPath`.
///
/// - Parameter curvature: How far the curve loops when the target is behind
///   the source handle (React Flow default `0.25`).
/// - Returns: The path, the label position, and the label offset from the source.
public func getBezierPath(
  sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
  targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
  curvature: CGFloat = 0.25
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let source = CGPoint(x: sourceX, y: sourceY)
  let target = CGPoint(x: targetX, y: targetY)
  let sourceControl = controlWithCurvature(
    position: sourcePosition, from: source, to: target, curvature: curvature)
  let targetControl = controlWithCurvature(
    position: targetPosition, from: target, to: source, curvature: curvature)
  let center = bezierEdgeCenter(
    source: source, sourceControl: sourceControl, targetControl: targetControl, target: target)
  return (
    cubicPath(from: source, sourceControl, targetControl, to: target),
    center.x, center.y, center.offsetX, center.offsetY
  )
}

// MARK: - Simple Bezier

private func simpleBezierControl(position: Position, from p1: CGPoint, to p2: CGPoint) -> CGPoint {
  switch position {
  case .left, .right: return CGPoint(x: 0.5 * (p1.x + p2.x), y: p1.y)
  case .top, .bottom: return CGPoint(x: p1.x, y: 0.5 * (p1.y + p2.y))
  }
}

/// Returns a cubic bezier path with control points at the midpoint along the
/// handle axis.
///
/// Port of React Flow's `getSimpleBezierPath`.
public func getSimpleBezierPath(
  sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
  targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let source = CGPoint(x: sourceX, y: sourceY)
  let target = CGPoint(x: targetX, y: targetY)
  let sourceControl = simpleBezierControl(position: sourcePosition, from: source, to: target)
  let targetControl = simpleBezierControl(position: targetPosition, from: target, to: source)
  let center = bezierEdgeCenter(
    source: source, sourceControl: sourceControl, targetControl: targetControl, target: target)
  return (
    cubicPath(from: source, sourceControl, targetControl, to: target),
    center.x, center.y, center.offsetX, center.offsetY
  )
}

// MARK: - Straight

/// Straight line with its midpoint as the label position (React Flow's
/// `getStraightPath`; the public `getStraightPath` returns only the `Path`).
func straightEdgePath(
  sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  var path = Path()
  path.move(to: CGPoint(x: sourceX, y: sourceY))
  path.addLine(to: CGPoint(x: targetX, y: targetY))
  let center = getEdgeCenter(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
  return (path, center.x, center.y, center.offsetX, center.offsetY)
}

// MARK: - Smooth Step

private func component(_ point: CGPoint, _ horizontal: Bool) -> CGFloat {
  horizontal ? point.x : point.y
}

private func withComponent(_ point: CGPoint, _ horizontal: Bool, _ value: CGFloat) -> CGPoint {
  horizontal ? CGPoint(x: value, y: point.y) : CGPoint(x: point.x, y: value)
}

private func stepDirection(source: CGPoint, sourcePosition: Position, target: CGPoint) -> CGPoint {
  switch sourcePosition {
  case .left, .right: return source.x < target.x ? CGPoint(x: 1, y: 0) : CGPoint(x: -1, y: 0)
  case .top, .bottom: return source.y < target.y ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: -1)
  }
}

/// Computes the orthogonal waypoints of a step edge (React Flow's `getPoints`).
private func smoothStepPoints(
  source: CGPoint, sourcePosition: Position,
  target: CGPoint, targetPosition: Position,
  centerX: CGFloat?, centerY: CGFloat?, offset: CGFloat
) -> (points: [CGPoint], labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let sourceDir = handleDirection(sourcePosition)
  let targetDir = handleDirection(targetPosition)
  let sourceGapped = CGPoint(x: source.x + sourceDir.x * offset, y: source.y + sourceDir.y * offset)
  let targetGapped = CGPoint(x: target.x + targetDir.x * offset, y: target.y + targetDir.y * offset)
  let dir = stepDirection(
    source: sourceGapped, sourcePosition: sourcePosition, target: targetGapped)
  let horizontal = dir.x != 0
  let currentDir = component(dir, horizontal)

  var points: [CGPoint]
  var sourceGapOffset = CGPoint.zero
  var targetGapOffset = CGPoint.zero
  let labelX: CGFloat
  let labelY: CGFloat
  let defaultCenter = getEdgeCenter(
    sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)

  if component(sourceDir, horizontal) * component(targetDir, horizontal) == -1 {
    // Opposite handle sides (default case): split the path at the center.
    labelX = centerX ?? defaultCenter.x
    labelY = centerY ?? defaultCenter.y
    let verticalSplit = [
      CGPoint(x: labelX, y: sourceGapped.y), CGPoint(x: labelX, y: targetGapped.y),
    ]
    let horizontalSplit = [
      CGPoint(x: sourceGapped.x, y: labelY), CGPoint(x: targetGapped.x, y: labelY),
    ]
    if component(sourceDir, horizontal) == currentDir {
      points = horizontal ? verticalSplit : horizontalSplit
    } else {
      points = horizontal ? horizontalSplit : verticalSplit
    }
  } else {
    // Same or perpendicular handle sides: route through a single corner.
    let sourceTarget = [CGPoint(x: sourceGapped.x, y: targetGapped.y)]
    let targetSource = [CGPoint(x: targetGapped.x, y: sourceGapped.y)]
    if horizontal {
      points = sourceDir.x == currentDir ? targetSource : sourceTarget
    } else {
      points = sourceDir.y == currentDir ? sourceTarget : targetSource
    }

    if sourcePosition == targetPosition {
      // Keep the corner from overlapping the gapped endpoints when the handles
      // are closer together than the offset.
      let diff = abs(component(source, horizontal) - component(target, horizontal))
      if diff <= offset {
        let gapOffset = min(offset - 1, offset - diff)
        if component(sourceDir, horizontal) == currentDir {
          let sign: CGFloat =
            component(sourceGapped, horizontal) > component(source, horizontal) ? -1 : 1
          sourceGapOffset = withComponent(sourceGapOffset, horizontal, sign * gapOffset)
        } else {
          let sign: CGFloat =
            component(targetGapped, horizontal) > component(target, horizontal) ? -1 : 1
          targetGapOffset = withComponent(targetGapOffset, horizontal, sign * gapOffset)
        }
      }
    } else {
      // Mixed handle sides such as right -> bottom.
      let opposite = !horizontal
      let isSameDir = component(sourceDir, horizontal) == component(targetDir, opposite)
      let sourceGreater = component(sourceGapped, opposite) > component(targetGapped, opposite)
      let sourceLess = component(sourceGapped, opposite) < component(targetGapped, opposite)
      let flip =
        component(sourceDir, horizontal) == 1
        ? (!isSameDir && sourceGreater) || (isSameDir && sourceLess)
        : (!isSameDir && sourceLess) || (isSameDir && sourceGreater)
      if flip {
        points = horizontal ? sourceTarget : targetSource
      }
    }

    // Place the label on the longest segment.
    let sourceGapPoint = CGPoint(
      x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y)
    let targetGapPoint = CGPoint(
      x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y)
    let maxXDistance = max(
      abs(sourceGapPoint.x - points[0].x), abs(targetGapPoint.x - points[0].x))
    let maxYDistance = max(
      abs(sourceGapPoint.y - points[0].y), abs(targetGapPoint.y - points[0].y))
    if maxXDistance >= maxYDistance {
      labelX = (sourceGapPoint.x + targetGapPoint.x) / 2
      labelY = points[0].y
    } else {
      labelX = points[0].x
      labelY = (sourceGapPoint.y + targetGapPoint.y) / 2
    }
  }

  let pathPoints =
    [
      source,
      CGPoint(x: sourceGapped.x + sourceGapOffset.x, y: sourceGapped.y + sourceGapOffset.y),
    ]
    + points
    + [
      CGPoint(x: targetGapped.x + targetGapOffset.x, y: targetGapped.y + targetGapOffset.y),
      target,
    ]
  return (pathPoints, labelX, labelY, defaultCenter.offsetX, defaultCenter.offsetY)
}

private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
  hypot(b.x - a.x, b.y - a.y)
}

/// Appends the corner at `b` (between `a` and `c`) rounded by up to `size` points.
private func addBend(to path: inout Path, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint, size: CGFloat) {
  let bendSize = min(distance(a, b) / 2, distance(b, c) / 2, size)
  if (a.x == b.x && b.x == c.x) || (a.y == b.y && b.y == c.y) {
    path.addLine(to: b)
    return
  }
  if a.y == b.y {
    // First segment is horizontal.
    let xDir: CGFloat = a.x < c.x ? -1 : 1
    let yDir: CGFloat = a.y < c.y ? 1 : -1
    path.addLine(to: CGPoint(x: b.x + bendSize * xDir, y: b.y))
    path.addQuadCurve(to: CGPoint(x: b.x, y: b.y + bendSize * yDir), control: b)
  } else {
    let xDir: CGFloat = a.x < c.x ? 1 : -1
    let yDir: CGFloat = a.y < c.y ? -1 : 1
    path.addLine(to: CGPoint(x: b.x, y: b.y + bendSize * yDir))
    path.addQuadCurve(to: CGPoint(x: b.x + bendSize * xDir, y: b.y), control: b)
  }
}

/// Returns an orthogonal path with rounded corners that leaves and enters the
/// nodes along their handle sides.
///
/// Port of React Flow's `getSmoothStepPath`.
///
/// - Parameters:
///   - borderRadius: Corner radius; `0` produces a sharp step edge.
///   - centerX: Optional x coordinate of the middle segment.
///   - centerY: Optional y coordinate of the middle segment.
///   - offset: Distance the path travels straight out of each handle before turning.
public func getSmoothStepPath(
  sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
  targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
  borderRadius: CGFloat = 5,
  centerX: CGFloat? = nil,
  centerY: CGFloat? = nil,
  offset: CGFloat = 20
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  let result = smoothStepPoints(
    source: CGPoint(x: sourceX, y: sourceY), sourcePosition: sourcePosition,
    target: CGPoint(x: targetX, y: targetY), targetPosition: targetPosition,
    centerX: centerX, centerY: centerY, offset: offset)
  let points = result.points
  var path = Path()
  path.move(to: points[0])
  for i in 1..<(points.count - 1) {
    addBend(to: &path, points[i - 1], points[i], points[i + 1], size: borderRadius)
  }
  path.addLine(to: points[points.count - 1])
  return (path, result.labelX, result.labelY, result.offsetX, result.offsetY)
}

/// Returns an orthogonal path with sharp corners.
///
/// Equivalent to React Flow's step edge, which is a smooth step edge with a
/// border radius of `0`.
public func getStepPath(
  sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
  targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  getSmoothStepPath(
    sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
    targetX: targetX, targetY: targetY, targetPosition: targetPosition,
    borderRadius: 0)
}

// MARK: - Dispatch by Edge Type

/// Returns the path for the given edge type, honoring the handle sides.
public func getEdgePath(
  type: EdgeType,
  sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
  targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
  switch type {
  case .straight:
    return straightEdgePath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
  case .step:
    return getStepPath(
      sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
      targetX: targetX, targetY: targetY, targetPosition: targetPosition)
  case .smoothstep:
    return getSmoothStepPath(
      sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
      targetX: targetX, targetY: targetY, targetPosition: targetPosition)
  case .simplebezier:
    return getSimpleBezierPath(
      sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
      targetX: targetX, targetY: targetY, targetPosition: targetPosition)
  case .default, .bezier:
    return getBezierPath(
      sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
      targetX: targetX, targetY: targetY, targetPosition: targetPosition)
  }
}

/// Builds the `EdgePathResult` for an edge type and handle sides.
func edgePathResult(
  type: EdgeType,
  source: CGPoint, sourcePosition: Position,
  target: CGPoint, targetPosition: Position
) -> EdgePathResult {
  let result = getEdgePath(
    type: type,
    sourceX: source.x, sourceY: source.y, sourcePosition: sourcePosition,
    targetX: target.x, targetY: target.y, targetPosition: targetPosition)
  return EdgePathResult(
    path: result.path, labelX: result.labelX, labelY: result.labelY,
    sourceX: source.x, sourceY: source.y, targetX: target.x, targetY: target.y)
}

// MARK: - Marker Angles

private func angle(of vector: CGPoint) -> CGFloat { atan2(vector.y, vector.x) }

/// Direction (radians) in which the path leaves the source endpoint.
func edgeStartAngle(
  type: EdgeType,
  source: CGPoint, sourcePosition: Position,
  target: CGPoint, targetPosition: Position
) -> CGFloat {
  switch type {
  case .straight:
    return angle(of: CGPoint(x: target.x - source.x, y: target.y - source.y))
  case .simplebezier:
    let control = simpleBezierControl(position: sourcePosition, from: source, to: target)
    let tangent = CGPoint(x: control.x - source.x, y: control.y - source.y)
    return tangent == .zero ? angle(of: handleDirection(sourcePosition)) : angle(of: tangent)
  case .default, .bezier, .step, .smoothstep:
    return angle(of: handleDirection(sourcePosition))
  }
}

/// Direction (radians) in which the path arrives at the target endpoint.
func edgeEndAngle(
  type: EdgeType,
  source: CGPoint, sourcePosition: Position,
  target: CGPoint, targetPosition: Position
) -> CGFloat {
  let inward = handleDirection(oppositePosition(targetPosition))
  switch type {
  case .straight:
    return angle(of: CGPoint(x: target.x - source.x, y: target.y - source.y))
  case .simplebezier:
    let control = simpleBezierControl(position: targetPosition, from: target, to: source)
    let tangent = CGPoint(x: target.x - control.x, y: target.y - control.y)
    return tangent == .zero ? angle(of: inward) : angle(of: tangent)
  case .default, .bezier, .step, .smoothstep:
    return angle(of: inward)
  }
}

// MARK: - Convenience Overloads (source on the right, target on the left)

/// Returns a cubic bezier `Path` from a right-side source to a left-side target.
public func getBezierPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat)
  -> Path
{
  getBezierPath(
    sourceX: sourceX, sourceY: sourceY, sourcePosition: .right,
    targetX: targetX, targetY: targetY, targetPosition: .left
  ).path
}

/// Returns a simple bezier `Path` from a right-side source to a left-side target.
public func getSimpleBezierPath(
  sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> Path {
  getSimpleBezierPath(
    sourceX: sourceX, sourceY: sourceY, sourcePosition: .right,
    targetX: targetX, targetY: targetY, targetPosition: .left
  ).path
}

/// Returns a straight line `Path` between two points.
public func getStraightPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat)
  -> Path
{
  straightEdgePath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY).path
}

/// Returns a sharp-cornered step `Path` from a right-side source to a left-side target.
public func getStepPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat)
  -> Path
{
  getStepPath(
    sourceX: sourceX, sourceY: sourceY, sourcePosition: .right,
    targetX: targetX, targetY: targetY, targetPosition: .left
  ).path
}

/// Returns a rounded step `Path` from a right-side source to a left-side target.
public func getSmoothStepPath(
  sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat, borderRadius: CGFloat = 5
) -> Path {
  getSmoothStepPath(
    sourceX: sourceX, sourceY: sourceY, sourcePosition: .right,
    targetX: targetX, targetY: targetY, targetPosition: .left,
    borderRadius: borderRadius
  ).path
}

/// Returns the `Path` for the given edge type from a right-side source to a left-side target.
public func getEdgePath(
  type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> Path {
  getEdgePath(
    type: type,
    sourceX: sourceX, sourceY: sourceY, sourcePosition: .right,
    targetX: targetX, targetY: targetY, targetPosition: .left
  ).path
}

/// Returns the `EdgePathResult` for the given edge type from a right-side
/// source to a left-side target.
public func getEdgePathResult(
  type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> EdgePathResult {
  edgePathResult(
    type: type,
    source: CGPoint(x: sourceX, y: sourceY), sourcePosition: .right,
    target: CGPoint(x: targetX, y: targetY), targetPosition: .left)
}

/// Returns the label position of an edge from a right-side source to a left-side target.
public func getEdgeMidpoint(
  type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> CGPoint {
  let result = getEdgePathResult(
    type: type, sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
  return CGPoint(x: result.labelX, y: result.labelY)
}

/// Returns the direction (radians) in which an edge from a right-side source to
/// a left-side target arrives at the target. Used to rotate end markers.
public func getEdgeAngleAtEnd(
  type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> CGFloat {
  edgeEndAngle(
    type: type,
    source: CGPoint(x: sourceX, y: sourceY), sourcePosition: .right,
    target: CGPoint(x: targetX, y: targetY), targetPosition: .left)
}

/// Returns the direction (radians) in which an edge from a right-side source to
/// a left-side target leaves the source. Used to rotate start markers.
public func getEdgeAngleAtStart(
  type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat
) -> CGFloat {
  edgeStartAngle(
    type: type,
    source: CGPoint(x: sourceX, y: sourceY), sourcePosition: .right,
    target: CGPoint(x: targetX, y: targetY), targetPosition: .left)
}
