import SwiftUI

/// A contextual floating toolbar displayed near a selected edge.
///
/// Position the toolbar at the edge's midpoint using `EdgePathResult.labelX/labelY`.
///
/// ```swift
/// EdgeToolbar(isVisible: edge.selected, position: CGPoint(x: midX, y: midY)) {
///     Button("Delete") { removeEdge(edge.id) }
/// }
/// ```
public struct EdgeToolbar<Content: View>: View {
  /// The edge this toolbar belongs to.
  public var edgeId: String?
  /// Whether the toolbar is currently visible.
  public var isVisible: Bool
  /// The position of the toolbar in canvas coordinates.
  public var position: CGPoint
  /// Vertical offset from the position point (positive = above).
  public var offset: CGFloat
  /// The toolbar content.
  @ViewBuilder public var content: () -> Content

  public init(
    edgeId: String? = nil,
    isVisible: Bool = true,
    position: CGPoint = .zero,
    offset: CGFloat = 24,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.edgeId = edgeId
    self.isVisible = isVisible
    self.position = position
    self.offset = offset
    self.content = content
  }

  public var body: some View {
    if isVisible {
      content()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .fixedSize()
        .position(x: position.x, y: position.y - offset)
    }
  }
}
