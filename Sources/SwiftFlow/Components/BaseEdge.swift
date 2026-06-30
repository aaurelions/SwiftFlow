import SwiftUI

/// A building block for creating custom edge views.
///
/// `BaseEdge` renders a path with configurable stroke style, and optionally
/// shows a label at the midpoint. Use it inside custom edge view builders:
///
/// ```swift
/// BaseEdge(path: path, color: .red, width: 3, label: "Error")
/// ```
public struct BaseEdge: View {
  public var path: Path
  public var color: Color
  public var width: CGFloat
  public var animated: Bool
  public var dashPhase: CGFloat
  public var label: String?
  public var labelPosition: CGPoint?
  public var labelFont: Font
  public var labelColor: Color
  public var labelBackground: Color

  public init(
    path: Path,
    color: Color = .gray.opacity(0.6),
    width: CGFloat = 2,
    animated: Bool = false,
    dashPhase: CGFloat = 0,
    label: String? = nil,
    labelPosition: CGPoint? = nil,
    labelFont: Font = .system(size: 11),
    labelColor: Color = .primary,
    labelBackground: Color = .white
  ) {
    self.path = path
    self.color = color
    self.width = width
    self.animated = animated
    self.dashPhase = dashPhase
    self.label = label
    self.labelPosition = labelPosition
    self.labelFont = labelFont
    self.labelColor = labelColor
    self.labelBackground = labelBackground
  }

  /// Creates a `BaseEdge` from an `EdgePathResult`, using the computed label position.
  public init(
    pathResult: EdgePathResult,
    color: Color = .gray.opacity(0.6),
    width: CGFloat = 2,
    animated: Bool = false,
    dashPhase: CGFloat = 0,
    label: String? = nil,
    labelFont: Font = .system(size: 11),
    labelColor: Color = .primary,
    labelBackground: Color = .white
  ) {
    self.path = pathResult.path
    self.color = color
    self.width = width
    self.animated = animated
    self.dashPhase = dashPhase
    self.label = label
    self.labelPosition = CGPoint(x: pathResult.labelX, y: pathResult.labelY)
    self.labelFont = labelFont
    self.labelColor = labelColor
    self.labelBackground = labelBackground
  }

  public var body: some View {
    ZStack {
      path.stroke(color, style: strokeStyle)
        .allowsHitTesting(false)

      if let label {
        let midpoint =
          labelPosition
          ?? {
            let bounds = path.boundingRect
            return CGPoint(x: bounds.midX, y: bounds.midY)
          }()
        Text(label)
          .font(labelFont)
          .foregroundColor(labelColor)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(labelBackground.opacity(0.9))
          .cornerRadius(4)
          .position(x: midpoint.x, y: midpoint.y)
          .allowsHitTesting(false)
      }
    }
  }

  private var strokeStyle: StrokeStyle {
    StrokeStyle(
      lineWidth: width,
      lineCap: .round,
      lineJoin: .round,
      dash: animated ? [8, 4] : [],
      dashPhase: animated ? dashPhase : 0
    )
  }
}
