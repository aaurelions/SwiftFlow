import Foundation

/// Applies an array of node changes to a node array and returns the new array.
///
/// This is the primary state-update function for nodes. Use it in your
/// `onNodesChange` callback:
///
/// ```swift
/// onNodesChange: { changes in
///     nodes = applyNodeChanges(changes, nodes: nodes)
/// }
/// ```
public func applyNodeChanges<T: Sendable>(_ changes: [NodeChange<T>], nodes: [Node<T>]) -> [Node<T>] {
    var result = nodes
    for change in changes {
        switch change {
        case .position(let id, let position):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i].position = position
            }
        case .selection(let id, let selected):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i].selected = selected
            }
        case .remove(let id):
            result.removeAll { $0.id == id }
        case .add(let item):
            if !result.contains(where: { $0.id == item.id }) {
                result.append(item)
            }
        case .dimensions(let id, let width, let height):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i].width = width
                result[i].height = height
            }
        case .replace(let id, let item):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i] = item
            }
        }
    }
    return result
}

/// Applies an array of edge changes to an edge array and returns the new array.
///
/// This is the primary state-update function for edges. Use it in your
/// `onEdgesChange` callback:
///
/// ```swift
/// onEdgesChange: { changes in
///     edges = applyEdgeChanges(changes, edges: edges)
/// }
/// ```
public func applyEdgeChanges<EdgeData: Equatable & Sendable & Hashable>(
    _ changes: [EdgeChange<EdgeData>],
    edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>] {
    var result = edges
    for change in changes {
        switch change {
        case .selection(let id, let selected):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i].selected = selected
            }
        case .remove(let id):
            result.removeAll { $0.id == id }
        case .add(let item):
            if !result.contains(where: { $0.id == item.id }) {
                result.append(item)
            }
        case .replace(let id, let item):
            if let i = result.firstIndex(where: { $0.id == id }) {
                result[i] = item
            }
        }
    }
    return result
}
