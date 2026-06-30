import SwiftUI

/// Visual style overrides for an individual node.
///
/// Set properties to `nil` to use the theme defaults. Only non-nil values
/// override the default appearance.
public struct NodeStyle: Equatable, Sendable, Hashable, Codable {
  public var backgroundColor: Color?
  public var borderColor: Color?
  public var borderWidth: CGFloat?
  public var borderRadius: CGFloat?
  public var opacity: Double?

  public init(
    backgroundColor: Color? = nil,
    borderColor: Color? = nil,
    borderWidth: CGFloat? = nil,
    borderRadius: CGFloat? = nil,
    opacity: Double? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.borderRadius = borderRadius
    self.opacity = opacity
  }

  private enum CodingKeys: String, CodingKey {
    case backgroundColor, borderColor, borderWidth, borderRadius, opacity
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    backgroundColor = try container.decodeIfPresent(CodableColor.self, forKey: .backgroundColor)?
      .color
    borderColor = try container.decodeIfPresent(CodableColor.self, forKey: .borderColor)?.color
    borderWidth = try container.decodeIfPresent(CGFloat.self, forKey: .borderWidth)
    borderRadius = try container.decodeIfPresent(CGFloat.self, forKey: .borderRadius)
    opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let backgroundColor {
      try container.encode(try CodableColor(backgroundColor), forKey: .backgroundColor)
    }
    if let borderColor {
      try container.encode(try CodableColor(borderColor), forKey: .borderColor)
    }
    try container.encodeIfPresent(borderWidth, forKey: .borderWidth)
    try container.encodeIfPresent(borderRadius, forKey: .borderRadius)
    try container.encodeIfPresent(opacity, forKey: .opacity)
  }
}
