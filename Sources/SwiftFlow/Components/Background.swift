import SwiftUI

/// A configurable background pattern for the SwiftFlow canvas.
///
/// Place inside the `overlay` ViewBuilder of `SwiftFlow` to render a
/// dot, line, or cross pattern that tracks with viewport pan and zoom.
///
/// ```swift
/// SwiftFlow(nodes: nodes, edges: edges, ...) { node in
///     MyNodeView(node: node)
/// } overlay: {
///     Background(variant: .dots)
/// }
/// ```
public struct Background: View {
    @EnvironmentObject private var flowState: SwiftFlowState

    /// Optional identifier for layering multiple backgrounds.
    public var id: String?
    public var variant: BackgroundVariant
    public var color: Color
    public var gap: CGFloat
    public var size: CGFloat

    public init(
        id: String? = nil,
        variant: BackgroundVariant = .dots,
        color: Color = .gray.opacity(0.3),
        gap: CGFloat = 20,
        size: CGFloat = 1.5
    ) {
        self.id = id
        self.variant = variant
        self.color = color
        self.gap = gap
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let zoom = flowState.viewport.zoom
            let spacing = gap * zoom
            guard spacing > 2 else { return }
            let startX = flowState.viewport.x.truncatingRemainder(dividingBy: spacing)
            let startY = flowState.viewport.y.truncatingRemainder(dividingBy: spacing)

            switch variant {
            case .dots:
                var path = Path()
                let halfSize = size * zoom / 2
                for x in stride(from: startX, through: canvasSize.width, by: spacing) {
                    for y in stride(from: startY, through: canvasSize.height, by: spacing) {
                        path.addEllipse(in: CGRect(x: x - halfSize, y: y - halfSize, width: halfSize * 2, height: halfSize * 2))
                    }
                }
                context.fill(path, with: .color(color))

            case .lines:
                var path = Path()
                for x in stride(from: startX, through: canvasSize.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                }
                for y in stride(from: startY, through: canvasSize.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                }
                context.stroke(path, with: .color(color), lineWidth: 0.5)

            case .cross:
                let arm: CGFloat = 3 * zoom
                var path = Path()
                for x in stride(from: startX, through: canvasSize.width, by: spacing) {
                    for y in stride(from: startY, through: canvasSize.height, by: spacing) {
                        path.move(to: CGPoint(x: x - arm, y: y))
                        path.addLine(to: CGPoint(x: x + arm, y: y))
                        path.move(to: CGPoint(x: x, y: y - arm))
                        path.addLine(to: CGPoint(x: x, y: y + arm))
                    }
                }
                context.stroke(path, with: .color(color), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}
