import SwiftUI

/// A floating toolbar placed next to a node.
///
/// Attach it as an overlay of the node view so it does not change the
/// node's measured size:
///
/// ```swift
/// MyNodeView(node: node)
///     .overlay {
///         NodeToolbar(isVisible: node.selected, position: .top) {
///             Button("Delete") { ... }
///             Button("Duplicate") { ... }
///         }
///     }
/// ```
///
/// The toolbar is placed outside the node on the `position` side, aligned
/// along that side by `align`, and separated from the node by `offset` points.
public struct NodeToolbar<Content: View>: View {
  /// The node the toolbar belongs to (informational; the toolbar is positioned
  /// relative to the view it overlays).
  public var nodeId: String?
  public var isVisible: Bool
  public var position: ToolbarPosition
  public var align: ToolbarAlign
  public var offset: CGFloat
  @ViewBuilder public var content: () -> Content

  /// The node side on which the toolbar appears.
  public enum ToolbarPosition: Sendable {
    case top, bottom, left, right
  }

  /// Alignment of the toolbar along the node side.
  public enum ToolbarAlign: Sendable {
    case start, center, end
  }

  public init(
    nodeId: String? = nil,
    isVisible: Bool = true,
    position: ToolbarPosition = .top,
    align: ToolbarAlign = .center,
    offset: CGFloat = 10,
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
    let gap = offset
    if isVisible {
      content()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .fixedSize()
        // Move the toolbar past the node edge: its far side aligns with the node side.
        .alignmentGuide(.top) { $0[.bottom] + gap }
        .alignmentGuide(.bottom) { $0[.top] - gap }
        .alignmentGuide(.leading) { $0[.trailing] + gap }
        .alignmentGuide(.trailing) { $0[.leading] - gap }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }
  }

  /// Alignment within the node's frame. The alignment guides above shift the
  /// toolbar outward along the axis given by `position`.
  private var frameAlignment: Alignment {
    switch position {
    case .top, .bottom:
      let vertical: VerticalAlignment = position == .top ? .top : .bottom
      switch align {
      case .start: return Alignment(horizontal: .leadingEdge, vertical: vertical)
      case .center: return Alignment(horizontal: .center, vertical: vertical)
      case .end: return Alignment(horizontal: .trailingEdge, vertical: vertical)
      }
    case .left, .right:
      let horizontal: HorizontalAlignment = position == .left ? .leading : .trailing
      switch align {
      case .start: return Alignment(horizontal: horizontal, vertical: .topEdge)
      case .center: return Alignment(horizontal: horizontal, vertical: .center)
      case .end: return Alignment(horizontal: horizontal, vertical: .bottomEdge)
      }
    }
  }
}

// Alignments that line a toolbar edge up with the matching node edge without
// the outward shift applied to `.leading`/`.trailing`/`.top`/`.bottom`.
extension HorizontalAlignment {
  private enum LeadingEdge: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.leading] }
  }
  private enum TrailingEdge: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.trailing] }
  }
  fileprivate static let leadingEdge = HorizontalAlignment(LeadingEdge.self)
  fileprivate static let trailingEdge = HorizontalAlignment(TrailingEdge.self)
}

extension VerticalAlignment {
  private enum TopEdge: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.top] }
  }
  private enum BottomEdge: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat { d[.bottom] }
  }
  fileprivate static let topEdge = VerticalAlignment(TopEdge.self)
  fileprivate static let bottomEdge = VerticalAlignment(BottomEdge.self)
}
