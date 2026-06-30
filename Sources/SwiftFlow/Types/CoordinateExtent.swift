import Foundation

/// Defines boundary constraints for node dragging.
///
/// Nodes cannot be dragged outside these bounds.
/// Use `.infinite` for no constraints (default).
public struct CoordinateExtent: Equatable, Sendable, Hashable, Codable {
  public var minX: CGFloat
  public var minY: CGFloat
  public var maxX: CGFloat
  public var maxY: CGFloat

  public init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
    self.minX = minX
    self.minY = minY
    self.maxX = maxX
    self.maxY = maxY
  }

  /// Clamps a position to within the extent bounds.
  public func clamp(_ position: XYPosition) -> XYPosition {
    XYPosition(
      x: max(minX, min(position.x, maxX)),
      y: max(minY, min(position.y, maxY))
    )
  }

  /// Creates a `CoordinateExtent` from a pair of coordinate arrays.
  public init(_ extent: [[CGFloat]]) {
    precondition(
      extent.count == 2 && extent[0].count == 2 && extent[1].count == 2,
      "CoordinateExtent requires [[minX, minY], [maxX, maxY]]")
    self.init(minX: extent[0][0], minY: extent[0][1], maxX: extent[1][0], maxY: extent[1][1])
  }

  /// No boundary constraints (default).
  public static let infinite = CoordinateExtent(
    minX: -.infinity, minY: -.infinity,
    maxX: .infinity, maxY: .infinity
  )
}
