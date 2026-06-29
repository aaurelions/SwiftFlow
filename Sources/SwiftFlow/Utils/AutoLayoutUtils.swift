import Foundation

// MARK: - Layout Types

/// Direction for hierarchical tree layouts.
public enum LayoutDirection: Sendable {
    case topToBottom
    case leftToRight
    case bottomToTop
    case rightToLeft
}

/// Algorithm selection for `computeAutoLayout()`.
public enum LayoutAlgorithm: Sendable {
    /// Hierarchical tree layout using BFS level assignment.
    case tree(direction: LayoutDirection = .topToBottom, nodeSpacing: CGFloat = 50, levelSpacing: CGFloat = 150)
    /// Physics-based force-directed layout.
    case forceDirected(iterations: Int = 100, idealLength: CGFloat = 200, repulsion: CGFloat = 5000)
    /// Simple grid arrangement.
    case grid(columns: Int = 3, nodeSpacing: CGFloat = 50)
}

// MARK: - Synchronous Entry Point

/// Computes layout changes for nodes using the specified algorithm.
///
/// Returns an array of `NodeChange.position` values that can be applied
/// via `applyNodeChanges`. This non-mutating API integrates cleanly
/// with undo/redo.
///
/// ```swift
/// let changes = computeAutoLayout(
///     nodes: nodes,
///     edges: edges,
///     algorithm: .tree(direction: .leftToRight)
/// )
/// nodes = applyNodeChanges(changes, nodes: nodes)
/// ```
public func computeAutoLayout<T: Equatable & Sendable, E: Equatable & Sendable & Hashable>(
    nodes: [Node<T>],
    edges: [Edge<E>],
    algorithm: LayoutAlgorithm,
    nodeSizes: [String: CGSize] = [:]
) -> [NodeChange<T>] {
    var mutableNodes = nodes
    switch algorithm {
    case .tree(let direction, let nodeSpacing, let levelSpacing):
        applyTreeLayout(nodes: &mutableNodes, edges: edges, direction: direction,
                        nodeSpacing: nodeSpacing, levelSpacing: levelSpacing, nodeSizes: nodeSizes)
    case .forceDirected(let iterations, let idealLength, let repulsion):
        applyForceDirectedLayout(nodes: &mutableNodes, edges: edges, iterations: iterations,
                                 idealLength: idealLength, repulsion: repulsion)
    case .grid(let columns, let nodeSpacing):
        applyGridLayout(nodes: &mutableNodes, columns: columns, nodeSpacing: nodeSpacing, nodeSizes: nodeSizes)
    }

    var changes: [NodeChange<T>] = []
    for i in 0..<nodes.count {
        if mutableNodes[i].position != nodes[i].position {
            changes.append(.position(id: nodes[i].id, position: mutableNodes[i].position))
        }
    }
    return changes
}

// MARK: - Async Entry Point

/// Computes layout changes on a background thread for large graphs.
///
/// Use this for graphs with 50+ nodes to avoid blocking the main thread.
///
/// ```swift
/// let changes = await computeAutoLayoutAsync(
///     nodes: nodes, edges: edges, algorithm: .forceDirected()
/// )
/// await MainActor.run { nodes = applyNodeChanges(changes, nodes: nodes) }
/// ```
public func computeAutoLayoutAsync<T: Equatable & Sendable, E: Equatable & Sendable & Hashable>(
    nodes: [Node<T>],
    edges: [Edge<E>],
    algorithm: LayoutAlgorithm,
    nodeSizes: [String: CGSize] = [:]
) async -> [NodeChange<T>] {
    let capturedNodes = nodes
    let capturedEdges = edges
    let capturedSizes = nodeSizes

    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            let result = computeAutoLayout(
                nodes: capturedNodes,
                edges: capturedEdges,
                algorithm: algorithm,
                nodeSizes: capturedSizes
            )
            continuation.resume(returning: result)
        }
    }
}

// MARK: - Tree Layout

private func applyTreeLayout<T: Equatable & Sendable, E: Equatable & Sendable & Hashable>(
    nodes: inout [Node<T>],
    edges: [Edge<E>],
    direction: LayoutDirection = .topToBottom,
    nodeSpacing: CGFloat = 50,
    levelSpacing: CGFloat = 150,
    nodeSizes: [String: CGSize] = [:]
) {
    guard !nodes.isEmpty else { return }

    var children: [String: [String]] = [:]
    var hasParent: Set<String> = []
    for edge in edges {
        children[edge.source, default: []].append(edge.target)
        hasParent.insert(edge.target)
    }

    let roots = nodes.filter { !hasParent.contains($0.id) }.map(\.id)
    guard !roots.isEmpty else { return }

    // BFS level assignment
    var levels: [String: Int] = [:]
    var queue = roots.map { ($0, 0) }
    var visited = Set(roots)

    while !queue.isEmpty {
        let (nodeId, level) = queue.removeFirst()
        levels[nodeId] = level
        for child in children[nodeId] ?? [] where !visited.contains(child) {
            visited.insert(child)
            queue.append((child, level + 1))
        }
    }

    // Disconnected nodes go to level 0
    for node in nodes where !visited.contains(node.id) {
        levels[node.id] = 0
    }

    // Group by level and position
    var levelNodes: [Int: [String]] = [:]
    for (id, level) in levels { levelNodes[level, default: []].append(id) }
    let maxLevel = levelNodes.keys.max() ?? 0

    for level in 0...maxLevel {
        guard let ids = levelNodes[level] else { continue }
        let count = CGFloat(ids.count)

        for (i, nodeId) in ids.enumerated() {
            guard let index = nodes.firstIndex(where: { $0.id == nodeId }) else { continue }
            let size = nodeSizes[nodeId] ?? CGSize(width: 150, height: 50)
            let pos = CGFloat(i)
            let totalWidth = count * (size.width + nodeSpacing) - nodeSpacing
            let offset = -totalWidth / 2

            switch direction {
            case .topToBottom:
                nodes[index].position = XYPosition(
                    x: offset + pos * (size.width + nodeSpacing),
                    y: CGFloat(level) * levelSpacing
                )
            case .leftToRight:
                nodes[index].position = XYPosition(
                    x: CGFloat(level) * levelSpacing,
                    y: offset + pos * (size.height + nodeSpacing)
                )
            case .bottomToTop:
                nodes[index].position = XYPosition(
                    x: offset + pos * (size.width + nodeSpacing),
                    y: CGFloat(maxLevel - level) * levelSpacing
                )
            case .rightToLeft:
                nodes[index].position = XYPosition(
                    x: CGFloat(maxLevel - level) * levelSpacing,
                    y: offset + pos * (size.height + nodeSpacing)
                )
            }
        }
    }
}

// MARK: - Force-Directed Layout

private func applyForceDirectedLayout<T: Equatable & Sendable, E: Equatable & Sendable & Hashable>(
    nodes: inout [Node<T>],
    edges: [Edge<E>],
    iterations: Int = 100,
    idealLength: CGFloat = 200,
    repulsion: CGFloat = 5000
) {
    guard nodes.count > 1 else { return }

    // Break symmetry when nodes overlap exactly
    for i in 0..<nodes.count {
        for j in (i + 1)..<nodes.count {
            if nodes[i].position.x == nodes[j].position.x &&
               nodes[i].position.y == nodes[j].position.y {
                nodes[j].position.x += CGFloat(j) * 0.1
                nodes[j].position.y += CGFloat(j) * 0.1
            }
        }
    }

    // Identify connected components
    let nodeIds = Set(nodes.map(\.id))
    let edgeNodeIds = Set(edges.flatMap { [$0.source, $0.target] }.filter { nodeIds.contains($0) })

    var velocities: [String: CGPoint] = [:]
    for node in nodes { velocities[node.id] = .zero }

    let damping: CGFloat = 0.9
    let dt: CGFloat = 0.1
    let centerAttraction: CGFloat = 0.01

    // Compute graph centroid for boundary attraction
    var cx: CGFloat = 0, cy: CGFloat = 0
    for node in nodes { cx += node.position.x; cy += node.position.y }
    cx /= CGFloat(nodes.count)
    cy /= CGFloat(nodes.count)

    for _ in 0..<iterations {
        // Repulsive forces (all pairs)
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let dx = nodes[j].position.x - nodes[i].position.x
                let dy = nodes[j].position.y - nodes[i].position.y
                let dist = max(hypot(dx, dy), 1)
                let f = repulsion / (dist * dist)
                let fx = (dx / dist) * f * dt
                let fy = (dy / dist) * f * dt

                velocities[nodes[i].id]!.x -= fx
                velocities[nodes[i].id]!.y -= fy
                velocities[nodes[j].id]!.x += fx
                velocities[nodes[j].id]!.y += fy
            }
        }

        // Attractive forces (edges)
        for edge in edges {
            guard let si = nodes.firstIndex(where: { $0.id == edge.source }),
                  let ti = nodes.firstIndex(where: { $0.id == edge.target }) else { continue }
            let dx = nodes[ti].position.x - nodes[si].position.x
            let dy = nodes[ti].position.y - nodes[si].position.y
            let dist = max(hypot(dx, dy), 1)
            let f = (dist - idealLength) * 0.1
            let fx = (dx / dist) * f * dt
            let fy = (dy / dist) * f * dt

            velocities[nodes[si].id]!.x += fx
            velocities[nodes[si].id]!.y += fy
            velocities[nodes[ti].id]!.x -= fx
            velocities[nodes[ti].id]!.y -= fy
        }

        // Central attraction for disconnected nodes
        for i in 0..<nodes.count where !edgeNodeIds.contains(nodes[i].id) {
            let dx = cx - nodes[i].position.x
            let dy = cy - nodes[i].position.y
            velocities[nodes[i].id]!.x += dx * centerAttraction * dt
            velocities[nodes[i].id]!.y += dy * centerAttraction * dt
        }

        // Apply velocities with damping
        for i in 0..<nodes.count where nodes[i].draggable {
            velocities[nodes[i].id]!.x *= damping
            velocities[nodes[i].id]!.y *= damping
            nodes[i].position.x += velocities[nodes[i].id]!.x
            nodes[i].position.y += velocities[nodes[i].id]!.y
        }
    }
}

// MARK: - Grid Layout

private func applyGridLayout<T: Equatable & Sendable>(
    nodes: inout [Node<T>],
    columns: Int = 3,
    nodeSpacing: CGFloat = 50,
    nodeSizes: [String: CGSize] = [:]
) {
    for (i, _) in nodes.enumerated() {
        let size = nodeSizes[nodes[i].id] ?? CGSize(width: 150, height: 50)
        nodes[i].position = XYPosition(
            x: CGFloat(i % columns) * (size.width + nodeSpacing),
            y: CGFloat(i / columns) * (size.height + nodeSpacing)
        )
    }
}
