import SwiftUI

/// A container for rendering edge labels at a specific position in flow coordinates.
///
/// Labels are automatically scaled by the inverse of the viewport zoom so they
/// maintain a consistent screen size regardless of the current zoom level.
///
/// ```swift
/// EdgeLabelRenderer(position: midpoint) {
///     Button("Delete") { deleteEdge() }
///         .buttonStyle(.bordered)
/// }
/// ```
public struct EdgeLabelRenderer<Content: View>: View {
  public var position: CGPoint
  @ViewBuilder public var content: () -> Content

  @EnvironmentObject private var flowState: SwiftFlowState

  public init(
    position: CGPoint,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.position = position
    self.content = content
  }

  public var body: some View {
    let zoom = max(flowState.viewport.zoom, 0.01)
    content()
      .scaleEffect(1 / zoom)
      .position(x: position.x, y: position.y)
  }
}
