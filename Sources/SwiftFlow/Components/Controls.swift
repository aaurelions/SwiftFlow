import SwiftUI

/// Zoom and fit-to-view control buttons for the SwiftFlow canvas.
///
/// Reads viewport state from the environment and applies changes through
/// the shared `SwiftFlowState`. Place inside the `overlay` ViewBuilder.
///
/// ```swift
/// SwiftFlow(nodes: nodes, edges: edges, ...) { node in
///     MyNodeView(node: node)
/// } overlay: {
///     Controls()
/// }
/// ```
public struct Controls<Children: View>: View {
  @EnvironmentObject private var flowState: SwiftFlowState

  public var showZoom: Bool
  public var showFitView: Bool
  public var showInteractive: Bool
  public var position: PanelPosition
  @ViewBuilder public var children: () -> Children

  public init(
    showZoom: Bool = true,
    showFitView: Bool = true,
    showInteractive: Bool = false,
    position: PanelPosition = .bottomLeft,
    @ViewBuilder children: @escaping () -> Children = { EmptyView() }
  ) {
    self.showZoom = showZoom
    self.showFitView = showFitView
    self.showInteractive = showInteractive
    self.position = position
    self.children = children
  }

  public var body: some View {
    VStack(spacing: 0) {
      if showZoom {
        ControlButton(action: { flowState.zoomIn() }) {
          Image(systemName: "plus")
            .font(.system(size: 14, weight: .medium))
        }
        Divider()
        Button {
          flowState.zoomTo(1.0)
        } label: {
          Text(String(format: "%.0f%%", flowState.viewport.zoom * 100))
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .frame(width: 32, height: 24)
        }
        .buttonStyle(.plain)
        Divider()
        ControlButton(action: { flowState.zoomOut() }) {
          Image(systemName: "minus")
            .font(.system(size: 14, weight: .medium))
        }
      }
      if showFitView {
        if showZoom { Divider() }
        ControlButton(action: { flowState.fitView() }) {
          Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 12, weight: .medium))
        }
      }
      if showInteractive {
        if showZoom || showFitView { Divider() }
        ControlButton(action: { flowState.isInteractive.toggle() }) {
          Image(systemName: flowState.isInteractive ? "lock.open" : "lock")
            .font(.system(size: 12, weight: .medium))
            .accessibilityLabel(
              flowState.isInteractive ? "Disable interactions" : "Enable interactions")
        }
      }
      children()
    }
    .background(.ultraThinMaterial)
    .cornerRadius(8)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    .fixedSize()
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: panelAlignment)
  }

  private var panelAlignment: Alignment {
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
