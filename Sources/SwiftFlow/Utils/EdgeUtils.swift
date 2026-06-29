import SwiftUI

// MARK: - Edge Creation

/// Creates an edge from a `Connection` and appends it, preventing duplicates.
///
/// Duplicate detection mirrors React Flow: an edge is considered a duplicate
/// only when source, target, sourceHandle, *and* targetHandle all match
/// (treating `nil` handles as matching any other `nil` handle). Multiple
/// edges between the same nodes but different handles are allowed.
public func addEdge<EdgeData: Equatable & Sendable & Hashable>(
    _ connection: Connection,
    edges: [Edge<EdgeData>],
    defaults: DefaultEdgeOptions? = nil
) -> [Edge<EdgeData>] {
    if edges.contains(where: {
        $0.source == connection.source &&
        $0.target == connection.target &&
        ($0.sourceHandle == connection.sourceHandle || ($0.sourceHandle == nil && connection.sourceHandle == nil)) &&
        ($0.targetHandle == connection.targetHandle || ($0.targetHandle == nil && connection.targetHandle == nil))
    }) {
        return edges
    }
    let suffix = UUID().uuidString.prefix(8)
    let newEdge = Edge<EdgeData>(
        id: "e-\(connection.source)-\(connection.target)-\(suffix)",
        source: connection.source,
        target: connection.target,
        sourceHandle: connection.sourceHandle,
        targetHandle: connection.targetHandle,
        type: defaults?.type ?? .default,
        animated: defaults?.animated ?? false,
        markerStart: defaults?.markerStart,
        markerEnd: defaults?.markerEnd
    )
    return edges + [newEdge]
}

/// Reconnects an existing edge with a new connection, preserving edge properties.
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

// MARK: - Edge Path Generation

/// Returns a smooth cubic bezier `Path` between two points.
public func getBezierPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    let controlOffset = max(abs(targetX - sourceX) / 2, 50)
    path.addCurve(
        to: CGPoint(x: targetX, y: targetY),
        control1: CGPoint(x: sourceX + controlOffset, y: sourceY),
        control2: CGPoint(x: targetX - controlOffset, y: targetY)
    )
    return path
}

/// Returns a simple quadratic bezier `Path` with a single control point.
public func getSimpleBezierPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    let controlX = (sourceX + targetX) / 2
    let controlY = (sourceY + targetY) / 2
    path.addQuadCurve(
        to: CGPoint(x: targetX, y: targetY),
        control: CGPoint(x: controlX, y: controlY)
    )
    return path
}

/// Returns a straight line `Path` between two points.
public func getStraightPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    path.addLine(to: CGPoint(x: targetX, y: targetY))
    return path
}

/// Returns a right-angle step `Path` with sharp corners.
public func getStepPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    let midX = (sourceX + targetX) / 2
    path.addLine(to: CGPoint(x: midX, y: sourceY))
    path.addLine(to: CGPoint(x: midX, y: targetY))
    path.addLine(to: CGPoint(x: targetX, y: targetY))
    return path
}

/// Returns a right-angle step `Path` with rounded corners.
public func getSmoothStepPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat, borderRadius: CGFloat = 5) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))

    let midX = (sourceX + targetX) / 2
    let r = min(borderRadius, abs(midX - sourceX), abs(targetY - sourceY) / 2)

    guard abs(targetY - sourceY) >= 1 else {
        path.addLine(to: CGPoint(x: targetX, y: targetY))
        return path
    }

    let goingDown = targetY > sourceY
    let goingRight = midX > sourceX
    let targetGoingRight = targetX > midX

    path.addLine(to: CGPoint(x: midX - (goingRight ? r : -r), y: sourceY))
    path.addQuadCurve(
        to: CGPoint(x: midX, y: sourceY + (goingDown ? r : -r)),
        control: CGPoint(x: midX, y: sourceY)
    )
    path.addLine(to: CGPoint(x: midX, y: targetY - (goingDown ? r : -r)))
    path.addQuadCurve(
        to: CGPoint(x: midX + (targetGoingRight ? r : -r), y: targetY),
        control: CGPoint(x: midX, y: targetY)
    )
    path.addLine(to: CGPoint(x: targetX, y: targetY))
    return path
}

/// Returns the appropriate `Path` for the given edge type.
public func getEdgePath(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path {
    switch type {
    case .straight:
        return getStraightPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    case .step:
        return getStepPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    case .smoothstep:
        return getSmoothStepPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    case .simplebezier:
        return getSimpleBezierPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    case .default, .bezier:
        return getBezierPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    }
}

// MARK: - Position-Aware Edge Path Generation

/// Returns the control point offset direction for a handle position.
private func controlPointOffset(for position: Position, distance: CGFloat) -> (dx: CGFloat, dy: CGFloat) {
    switch position {
    case .top:    return (0, -distance)
    case .bottom: return (0, distance)
    case .left:   return (-distance, 0)
    case .right:  return (distance, 0)
    }
}

/// Returns a smooth cubic bezier `Path` with control points based on handle positions.
///
/// Unlike the basic `getBezierPath`, this version calculates control point offsets
/// based on the direction each handle faces, producing correct curves regardless
/// of whether handles are on the top, bottom, left, or right of nodes.
///
/// Returns a tuple with the path, label position, and control point offsets.
public func getBezierPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
    curvature: CGFloat = 0.25
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    let dist = hypot(targetX - sourceX, targetY - sourceY)
    let offset = max(dist * curvature, 50)

    let s = controlPointOffset(for: sourcePosition, distance: offset)
    let t = controlPointOffset(for: targetPosition, distance: offset)

    let c1 = CGPoint(x: sourceX + s.dx, y: sourceY + s.dy)
    let c2 = CGPoint(x: targetX + t.dx, y: targetY + t.dy)

    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    path.addCurve(to: CGPoint(x: targetX, y: targetY), control1: c1, control2: c2)

    // Cubic bezier midpoint at t=0.5
    let mx = 0.125 * sourceX + 0.375 * c1.x + 0.375 * c2.x + 0.125 * targetX
    let my = 0.125 * sourceY + 0.375 * c1.y + 0.375 * c2.y + 0.125 * targetY
    let ox = mx - (sourceX + targetX) / 2
    let oy = my - (sourceY + targetY) / 2

    return (path: path, labelX: mx, labelY: my, offsetX: ox, offsetY: oy)
}

/// Returns a simple quadratic bezier `Path` with control point based on handle positions.
public func getSimpleBezierPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    let midX = (sourceX + targetX) / 2
    let midY = (sourceY + targetY) / 2

    // Offset control point based on source/target positions
    let isHorizontalSource = sourcePosition == .left || sourcePosition == .right
    let isHorizontalTarget = targetPosition == .left || targetPosition == .right

    let controlX: CGFloat
    let controlY: CGFloat
    if isHorizontalSource && isHorizontalTarget {
        controlX = midX
        controlY = midY
    } else if isHorizontalSource {
        controlX = midX
        controlY = sourceY
    } else if isHorizontalTarget {
        controlX = midX
        controlY = targetY
    } else {
        controlX = sourceX
        controlY = midY
    }

    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))
    path.addQuadCurve(to: CGPoint(x: targetX, y: targetY),
                      control: CGPoint(x: controlX, y: controlY))

    // Quadratic bezier midpoint at t=0.5
    let lx = 0.25 * sourceX + 0.5 * controlX + 0.25 * targetX
    let ly = 0.25 * sourceY + 0.5 * controlY + 0.25 * targetY

    return (path: path, labelX: lx, labelY: ly, offsetX: lx - midX, offsetY: ly - midY)
}

/// Returns a step path with control based on source/target handle positions.
public func getStepPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    let isSourceHorizontal = sourcePosition == .left || sourcePosition == .right
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))

    if isSourceHorizontal {
        let midX = (sourceX + targetX) / 2
        path.addLine(to: CGPoint(x: midX, y: sourceY))
        path.addLine(to: CGPoint(x: midX, y: targetY))
        path.addLine(to: CGPoint(x: targetX, y: targetY))
    } else {
        let midY = (sourceY + targetY) / 2
        path.addLine(to: CGPoint(x: sourceX, y: midY))
        path.addLine(to: CGPoint(x: targetX, y: midY))
        path.addLine(to: CGPoint(x: targetX, y: targetY))
    }

    let lx = (sourceX + targetX) / 2
    let ly = (sourceY + targetY) / 2
    return (path: path, labelX: lx, labelY: ly, offsetX: 0, offsetY: 0)
}

/// Returns a smooth step path with rounded corners based on source/target handle positions.
public func getSmoothStepPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
    borderRadius: CGFloat = 5
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    let isSourceHorizontal = sourcePosition == .left || sourcePosition == .right
    var path = Path()
    path.move(to: CGPoint(x: sourceX, y: sourceY))

    if isSourceHorizontal {
        let midX = (sourceX + targetX) / 2
        let r = min(borderRadius, abs(midX - sourceX), abs(targetY - sourceY) / 2)

        guard abs(targetY - sourceY) >= 1 else {
            path.addLine(to: CGPoint(x: targetX, y: targetY))
            let lx = (sourceX + targetX) / 2
            return (path: path, labelX: lx, labelY: sourceY, offsetX: 0, offsetY: 0)
        }

        let goingDown = targetY > sourceY
        let goingRight = midX > sourceX
        let targetGoingRight = targetX > midX

        path.addLine(to: CGPoint(x: midX - (goingRight ? r : -r), y: sourceY))
        path.addQuadCurve(to: CGPoint(x: midX, y: sourceY + (goingDown ? r : -r)),
                          control: CGPoint(x: midX, y: sourceY))
        path.addLine(to: CGPoint(x: midX, y: targetY - (goingDown ? r : -r)))
        path.addQuadCurve(to: CGPoint(x: midX + (targetGoingRight ? r : -r), y: targetY),
                          control: CGPoint(x: midX, y: targetY))
        path.addLine(to: CGPoint(x: targetX, y: targetY))
    } else {
        let midY = (sourceY + targetY) / 2
        let r = min(borderRadius, abs(midY - sourceY), abs(targetX - sourceX) / 2)

        guard abs(targetX - sourceX) >= 1 else {
            path.addLine(to: CGPoint(x: targetX, y: targetY))
            let ly = (sourceY + targetY) / 2
            return (path: path, labelX: sourceX, labelY: ly, offsetX: 0, offsetY: 0)
        }

        let goingRight = targetX > sourceX
        let goingDown = midY > sourceY
        let targetGoingDown = targetY > midY

        path.addLine(to: CGPoint(x: sourceX, y: midY - (goingDown ? r : -r)))
        path.addQuadCurve(to: CGPoint(x: sourceX + (goingRight ? r : -r), y: midY),
                          control: CGPoint(x: sourceX, y: midY))
        path.addLine(to: CGPoint(x: targetX - (goingRight ? r : -r), y: midY))
        path.addQuadCurve(to: CGPoint(x: targetX, y: midY + (targetGoingDown ? r : -r)),
                          control: CGPoint(x: targetX, y: midY))
        path.addLine(to: CGPoint(x: targetX, y: targetY))
    }

    let lx = (sourceX + targetX) / 2
    let ly = (sourceY + targetY) / 2
    return (path: path, labelX: lx, labelY: ly, offsetX: 0, offsetY: 0)
}

/// Returns the appropriate path with full position awareness for the given edge type.
public func getEdgePath(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    switch type {
    case .straight:
        let path = getStraightPath(sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
        let lx = (sourceX + targetX) / 2
        let ly = (sourceY + targetY) / 2
        return (path: path, labelX: lx, labelY: ly, offsetX: 0, offsetY: 0)
    case .step:
        return getStepPath(sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
                           targetX: targetX, targetY: targetY, targetPosition: targetPosition)
    case .smoothstep:
        return getSmoothStepPath(sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
                                 targetX: targetX, targetY: targetY, targetPosition: targetPosition)
    case .simplebezier:
        return getSimpleBezierPath(sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
                                   targetX: targetX, targetY: targetY, targetPosition: targetPosition)
    case .default, .bezier:
        return getBezierPath(sourceX: sourceX, sourceY: sourceY, sourcePosition: sourcePosition,
                             targetX: targetX, targetY: targetY, targetPosition: targetPosition)
    }
}

// MARK: - Edge Path Result

/// Returns the appropriate `EdgePathResult` for the given edge type, including label position.
public func getEdgePathResult(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> EdgePathResult {
    let path = getEdgePath(type: type, sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    let mid = getEdgeMidpoint(type: type, sourceX: sourceX, sourceY: sourceY, targetX: targetX, targetY: targetY)
    return EdgePathResult(
        path: path,
        labelX: mid.x,
        labelY: mid.y,
        sourceX: sourceX,
        sourceY: sourceY,
        targetX: targetX,
        targetY: targetY
    )
}

// MARK: - Edge Geometry

/// Returns the midpoint of an edge path, used for positioning labels.
public func getEdgeMidpoint(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> CGPoint {
    switch type {
    case .straight, .step, .smoothstep, .simplebezier:
        return CGPoint(x: (sourceX + targetX) / 2, y: (sourceY + targetY) / 2)
    case .default, .bezier:
        let controlOffset = max(abs(targetX - sourceX) / 2, 50)
        let t: CGFloat = 0.5
        let mt: CGFloat = 0.5
        let x = mt * mt * mt * sourceX
            + 3 * mt * mt * t * (sourceX + controlOffset)
            + 3 * mt * t * t * (targetX - controlOffset)
            + t * t * t * targetX
        let y = mt * mt * mt * sourceY
            + 3 * mt * mt * t * sourceY
            + 3 * mt * t * t * targetY
            + t * t * t * targetY
        return CGPoint(x: x, y: y)
    }
}

/// Returns the angle of the edge path at the target endpoint (for marker rotation).
public func getEdgeAngleAtEnd(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> CGFloat {
    switch type {
    case .straight, .simplebezier:
        return atan2(targetY - sourceY, targetX - sourceX)
    case .step, .smoothstep:
        let midX = (sourceX + targetX) / 2
        return atan2(0, targetX - midX)
    case .default, .bezier:
        let controlOffset = max(abs(targetX - sourceX) / 2, 50)
        return atan2(0, controlOffset * 3)
    }
}

/// Returns the angle of the edge path at the source endpoint (for marker rotation).
public func getEdgeAngleAtStart(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> CGFloat {
    switch type {
    case .straight, .simplebezier:
        return atan2(targetY - sourceY, targetX - sourceX)
    case .step, .smoothstep:
        return 0
    case .default, .bezier:
        let controlOffset = max(abs(targetX - sourceX) / 2, 50)
        return atan2(0, controlOffset * 3)
    }
}
