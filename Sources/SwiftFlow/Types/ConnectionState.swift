import Foundation

/// The current state of an in-progress connection drag.
///
/// Mirrors ReactFlow v12's `ConnectionState` from the `useConnection` hook.
/// When no connection is in progress, the value is `nil`.
public struct ConnectionState: Equatable, Sendable {
    /// Whether the connection target is valid. `nil` = unknown (not over a handle),
    /// `true` = valid target, `false` = invalid target.
    public var isValid: Bool?
    /// Start position in canvas coordinates.
    public var from: CGPoint
    /// The source handle.
    public var fromHandle: NodeHandle
    /// The source handle direction.
    public var fromPosition: Position
    /// Type-erased source node.
    public var fromNode: AnyNodeSnapshot
    /// Current drag position in canvas coordinates.
    public var to: CGPoint
    /// Target handle if snapped to one.
    public var toHandle: NodeHandle?
    /// Target handle direction.
    public var toPosition: Position
    /// Target node if snapped to one.
    public var toNode: AnyNodeSnapshot?

    public init(
        isValid: Bool? = nil,
        from: CGPoint,
        fromHandle: NodeHandle,
        fromPosition: Position,
        fromNode: AnyNodeSnapshot,
        to: CGPoint,
        toHandle: NodeHandle? = nil,
        toPosition: Position = .right,
        toNode: AnyNodeSnapshot? = nil
    ) {
        self.isValid = isValid
        self.from = from
        self.fromHandle = fromHandle
        self.fromPosition = fromPosition
        self.fromNode = fromNode
        self.to = to
        self.toHandle = toHandle
        self.toPosition = toPosition
        self.toNode = toNode
    }
}
