import SwiftUI

/// Supported positions for overlay panels on the canvas.
public enum PanelPosition: String, Sendable {
  case topLeft = "top-left"
  case topCenter = "top-center"
  case topRight = "top-right"
  case centerLeft = "center-left"
  case center = "center"
  case centerRight = "center-right"
  case bottomLeft = "bottom-left"
  case bottomCenter = "bottom-center"
  case bottomRight = "bottom-right"
}

/// Positional overlay container for placing custom UI elements on the canvas.
///
/// ```swift
/// SwiftFlow(nodes: nodes, edges: edges, ...) { node in
///     MyNodeView(node: node)
/// } overlay: {
///     Panel(position: .topRight) {
///         Button("Reset") { ... }
///     }
/// }
/// ```
public struct Panel<Content: View>: View {
  public var position: PanelPosition
  @ViewBuilder public var content: () -> Content

  public init(
    position: PanelPosition = .topRight,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.position = position
    self.content = content
  }

  public var body: some View {
    content()
      .padding(8)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
  }

  private var alignment: Alignment {
    switch position {
    case .topLeft: return .topLeading
    case .topCenter: return .top
    case .topRight: return .topTrailing
    case .centerLeft: return .leading
    case .center: return .center
    case .centerRight: return .trailing
    case .bottomLeft: return .bottomLeading
    case .bottomCenter: return .bottom
    case .bottomRight: return .bottomTrailing
    }
  }
}
