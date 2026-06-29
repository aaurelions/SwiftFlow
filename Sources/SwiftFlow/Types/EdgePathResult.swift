import SwiftUI

/// Result of an edge path computation, including the path and label positioning info.
///
/// Use with `getEdgePathResult(type:sourceX:sourceY:targetX:targetY:)` to get
/// both the renderable path and the ideal label position for any edge type.
public struct EdgePathResult: Sendable {
    /// The renderable path for the edge.
    public var path: Path
    /// X coordinate for label placement (midpoint of the path).
    public var labelX: CGFloat
    /// Y coordinate for label placement (midpoint of the path).
    public var labelY: CGFloat
    /// Source endpoint X coordinate.
    public var sourceX: CGFloat
    /// Source endpoint Y coordinate.
    public var sourceY: CGFloat
    /// Target endpoint X coordinate.
    public var targetX: CGFloat
    /// Target endpoint Y coordinate.
    public var targetY: CGFloat

    public init(path: Path, labelX: CGFloat, labelY: CGFloat, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) {
        self.path = path
        self.labelX = labelX
        self.labelY = labelY
        self.sourceX = sourceX
        self.sourceY = sourceY
        self.targetX = targetX
        self.targetY = targetY
    }
}
