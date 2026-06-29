import Foundation

/// Configuration for the `fitView` operation.
public struct FitViewOptions: Equatable, Sendable {
    /// Padding around the fitted content in points.
    public var padding: CGFloat
    /// Whether hidden nodes should be included in bounds calculation.
    public var includeHiddenNodes: Bool
    /// Minimum zoom level after fitting.
    public var minZoom: CGFloat
    /// Maximum zoom level after fitting.
    public var maxZoom: CGFloat
    /// Animation duration in seconds. `nil` disables animation.
    public var duration: TimeInterval?
    /// Specific node IDs to fit. `nil` fits all nodes.
    public var nodeIds: [String]?

    public init(
        padding: CGFloat = 80,
        includeHiddenNodes: Bool = false,
        minZoom: CGFloat = Viewport.minZoom,
        maxZoom: CGFloat = 1.5,
        duration: TimeInterval? = 0.3,
        nodeIds: [String]? = nil
    ) {
        self.padding = padding
        self.includeHiddenNodes = includeHiddenNodes
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.duration = duration
        self.nodeIds = nodeIds
    }
}
