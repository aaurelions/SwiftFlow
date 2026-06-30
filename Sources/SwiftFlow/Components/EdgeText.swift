import SwiftUI

/// A positioned text label for use within custom edge rendering.
///
/// `EdgeText` renders a label at a specific canvas position, typically at the
/// midpoint of an edge. It supports background styling and padding.
///
/// ```swift
/// EdgeText(x: labelX, y: labelY, label: "42 requests/s")
/// ```
public struct EdgeText: View {
  public var x: CGFloat
  public var y: CGFloat
  public var label: String
  public var font: Font
  public var foregroundColor: Color
  public var showBackground: Bool
  public var backgroundColor: Color
  public var backgroundPadding: EdgeInsets
  public var backgroundCornerRadius: CGFloat

  public init(
    x: CGFloat,
    y: CGFloat,
    label: String,
    font: Font = .system(size: 11),
    foregroundColor: Color = .primary,
    showBackground: Bool = true,
    backgroundColor: Color = Color.white,
    backgroundPadding: EdgeInsets = EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6),
    backgroundCornerRadius: CGFloat = 4
  ) {
    self.x = x
    self.y = y
    self.label = label
    self.font = font
    self.foregroundColor = foregroundColor
    self.showBackground = showBackground
    self.backgroundColor = backgroundColor
    self.backgroundPadding = backgroundPadding
    self.backgroundCornerRadius = backgroundCornerRadius
  }

  public var body: some View {
    Text(label)
      .font(font)
      .foregroundColor(foregroundColor)
      .padding(backgroundPadding)
      .if(showBackground) { view in
        view.background(
          RoundedRectangle(cornerRadius: backgroundCornerRadius)
            .fill(backgroundColor.opacity(0.9))
        )
      }
      .position(x: x, y: y)
      .allowsHitTesting(false)
  }
}
