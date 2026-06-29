import Foundation

/// Describes a handle's position and dimensions on a node.
///
/// Used for explicit handle positioning when geometry measurement isn't available,
/// for server-side rendering scenarios.
public struct NodeHandle: Equatable, Sendable, Hashable, Codable {
    public var id: String?
    public var type: HandleType
    public var position: Position
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat

    public init(
        id: String? = nil,
        type: HandleType = .source,
        position: Position = .right,
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 12,
        height: CGFloat = 12
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
