import SwiftUI

/// Visual style overrides for an individual edge.
///
/// Set properties to `nil` to use the theme defaults. Only non-nil values
/// override the default appearance.
public struct EdgeStyle: Equatable, Sendable, Hashable, Codable {
  public var strokeColor: Color?
  public var strokeWidth: CGFloat?
  public var opacity: Double?

  public init(
    strokeColor: Color? = nil,
    strokeWidth: CGFloat? = nil,
    opacity: Double? = nil
  ) {
    self.strokeColor = strokeColor
    self.strokeWidth = strokeWidth
    self.opacity = opacity
  }

  private enum CodingKeys: String, CodingKey {
    case strokeColor, strokeWidth, opacity
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    strokeColor = try container.decodeIfPresent(CodableColor.self, forKey: .strokeColor)?.color
    strokeWidth = try container.decodeIfPresent(CGFloat.self, forKey: .strokeWidth)
    opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let strokeColor {
      try container.encode(try CodableColor(strokeColor), forKey: .strokeColor)
    }
    try container.encodeIfPresent(strokeWidth, forKey: .strokeWidth)
    try container.encodeIfPresent(opacity, forKey: .opacity)
  }
}
