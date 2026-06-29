import Foundation

/// The result of an `onBeforeDelete` callback, allowing the deletion to be
/// cancelled or modified before it takes effect.
public enum BeforeDeleteResult<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>: Sendable {
    /// Cancel the deletion entirely.
    case cancel
    /// Proceed with deleting the specified nodes and edges (which may be a
    /// subset of the originally selected items).
    case delete(nodes: [Node<NodeData>], edges: [Edge<EdgeData>])
}
