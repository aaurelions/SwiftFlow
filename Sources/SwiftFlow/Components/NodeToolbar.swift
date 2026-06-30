import SwiftUI

/// A contextual floating toolbar displayed near a selected node.
///
/// Place custom buttons or controls inside the toolbar content:
///
/// ```swift
/// if node.selected {
///     NodeToolbar(position: .top) {
///         Button("Delete") { ... }
///         Button("Duplicate") { ... }
///     }
/// }
/// ```
public struct NodeToolbar<Content: View>: View {
  public var nodeId: String?
  public var isVisible: Bool
  public var position: ToolbarPosition
  public var align: ToolbarAlign
  public var offset: CGFloat
  @ViewBuilder public var content: () -> Content

  /// Placement of the toolbar relative to the node.
  public enum ToolbarPosition: Sendable {
    case top, bottom, left, right
  }

  /// Horizontal alignment of the toolbar relative to the node.
  public enum ToolbarAlign: Sendable {
    case start, center, end
  }

  public init(
    nodeId: String? = nil,
    isVisible: Bool = true,
    position: ToolbarPosition = .top,
    align: ToolbarAlign = .center,
    offset: CGFloat = 8,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.nodeId = nodeId
    self.isVisible = isVisible
    self.position = position
    self.align = align
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
    }
  }
}
