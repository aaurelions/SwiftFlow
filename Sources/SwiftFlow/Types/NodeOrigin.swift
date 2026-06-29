import Foundation

/// Defines the anchor point for node positioning.
///
/// `(0, 0)` means top-left (default), `(0.5, 0.5)` means center.
public struct NodeOrigin: Equatable, Sendable, Codable, Hashable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat = 0, y: CGFloat = 0) {
        self.x = x
        self.y = y
    }

    /// Top-left corner (default).
    public static let topLeft = NodeOrigin(x: 0, y: 0)
    /// Center of the node.
    public static let center = NodeOrigin(x: 0.5, y: 0.5)
}
