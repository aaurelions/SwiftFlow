import Foundation

/// Camera state for the canvas, describing pan offset and zoom level.
public struct Viewport: Equatable, Sendable, Codable, Hashable {
    public var x: CGFloat
    public var y: CGFloat
    public var zoom: CGFloat

    public init(x: CGFloat = 0, y: CGFloat = 0, zoom: CGFloat = 1) {
        self.x = x
        self.y = y
        self.zoom = zoom
    }

    public static let identity = Viewport(x: 0, y: 0, zoom: 1)

    /// Clamps zoom to the allowed range.
    public static let minZoom: CGFloat = 0.1
    public static let maxZoom: CGFloat = 4.0

    public var clampedZoom: CGFloat {
        max(Self.minZoom, min(zoom, Self.maxZoom))
    }
}
