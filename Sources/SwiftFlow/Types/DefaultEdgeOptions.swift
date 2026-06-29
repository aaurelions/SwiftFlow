import Foundation

/// Default properties applied to newly created edges.
public struct DefaultEdgeOptions: Equatable, Sendable {
    public var type: EdgeType
    public var animated: Bool
    public var markerStart: EdgeMarker?
    public var markerEnd: EdgeMarker?

    public init(
        type: EdgeType = .default,
        animated: Bool = false,
        markerStart: EdgeMarker? = nil,
        markerEnd: EdgeMarker? = nil
    ) {
        self.type = type
        self.animated = animated
        self.markerStart = markerStart
        self.markerEnd = markerEnd
    }
}
