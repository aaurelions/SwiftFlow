import Foundation

/// Parameters passed to the `onConnectStart` callback when a user begins
/// dragging a new connection from a handle.
public struct OnConnectStartParams: Equatable, Sendable {
    public var nodeId: String
    public var handleId: String
    public var handleType: HandleType

    public init(nodeId: String, handleId: String, handleType: HandleType) {
        self.nodeId = nodeId
        self.handleId = handleId
        self.handleType = handleType
    }
}
