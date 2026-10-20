import SwiftUI

/// Zoom, fit-view, and interactivity buttons for the SwiftFlow canvas.
///
/// Reads viewport state from the environment and applies changes through
/// the shared `SwiftFlowState`. The fit-view button uses the canvas's
/// `fitViewOptions`. Place inside the `overlay` ViewBuilder.
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
  @Environment(\.swiftFlowAccessibilityConfig) private var accessibilityConfig

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
        .accessibilityLabel(accessibilityConfig.zoomInAriaLabel)
        Divider()
        Button {
          flowState.zoomTo(1.0)
        } label: {
          Text(Double(flowState.viewport.zoom), format: .percent.precision(.fractionLength(0)))
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .frame(width: 32, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          String(
            localized: "Reset zoom to 100 percent", bundle: .module,
            comment: "Label of the zoom level button"))
        Divider()
        ControlButton(action: { flowState.zoomOut() }) {
          Image(systemName: "minus")
            .font(.system(size: 14, weight: .medium))
        }
        .accessibilityLabel(accessibilityConfig.zoomOutAriaLabel)
      }
      if showFitView {
        if showZoom { Divider() }
        ControlButton(action: { flowState.fitView(options: flowState.fitViewOptions) }) {
          Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 12, weight: .medium))
        }
        .accessibilityLabel(accessibilityConfig.fitViewAriaLabel)
      }
      if showInteractive {
        if showZoom || showFitView { Divider() }
        ControlButton(action: { flowState.isInteractive.toggle() }) {
          Image(systemName: flowState.isInteractive ? "lock.open" : "lock")
            .font(.system(size: 12, weight: .medium))
        }
        .accessibilityLabel(accessibilityConfig.interactiveAriaLabel)
        .accessibilityAddTraits(flowState.isInteractive ? [] : .isSelected)
      }
      children()
    }
    .background(.ultraThinMaterial)
    .cornerRadius(8)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    .fixedSize()
    .accessibilityElement(children: .contain)
    .accessibilityLabel(accessibilityConfig.controlsAriaLabel)
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
  }
}
