import Foundation

/// A 2D coordinate representing a position on the canvas.
public struct XYPosition: Equatable, Sendable, Codable, Hashable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public static let zero = XYPosition(x: 0, y: 0)
}

extension XYPosition {
    public static func + (lhs: XYPosition, rhs: XYPosition) -> XYPosition {
        XYPosition(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: XYPosition, rhs: XYPosition) -> XYPosition {
        XYPosition(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// Returns a new position snapped to the given grid.
    public func snapped(to grid: (x: CGFloat, y: CGFloat)) -> XYPosition {
        XYPosition(
            x: (x / grid.x).rounded() * grid.x,
            y: (y / grid.y).rounded() * grid.y
        )
    }
}
