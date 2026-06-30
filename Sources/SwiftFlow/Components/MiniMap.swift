import SwiftUI

/// Properties passed to a custom minimap node view.
public struct MiniMapNodeProps: Sendable {
  public let id: String
  public let x: CGFloat
  public let y: CGFloat
  public let width: CGFloat
  public let height: CGFloat
  public let selected: Bool
  public let type: String
}

/// An interactive overview of the graph showing the current viewport position.
///
/// Reads node positions, sizes, and viewport from the environment.
/// Supports click-and-drag to pan the main viewport. Place inside the
/// `overlay` ViewBuilder of `SwiftFlow`.
///
/// ```swift
/// // Default rendering
/// MiniMap()
///
/// // With color mapper
/// MiniMap(nodeColorMapper: { props in
///     props.type == "input" ? .green : .pink
/// })
///
/// // With custom node content
/// MiniMap { props in
///     Circle().fill(props.selected ? .blue : .gray)
/// }
/// ```
public struct MiniMap<NodeContent: View>: View {
  @EnvironmentObject private var flowState: SwiftFlowState

  public var nodeColor: Color
  public var nodeColorMapper: ((MiniMapNodeProps) -> Color)?
  public var selectedNodeColor: Color
  public var nodeStrokeColor: Color
  public var nodeStrokeWidth: CGFloat
  public var nodeBorderRadius: CGFloat
  public var maskColor: Color
  public var width: CGFloat
  public var height: CGFloat
  public var pannable: Bool
  public var zoomable: Bool
  public var position: PanelPosition
  public var nodeContent: ((MiniMapNodeProps) -> NodeContent)?

  /// Creates a MiniMap with custom node rendering.
  public init(
    nodeColor: Color = .gray.opacity(0.5),
    nodeColorMapper: ((MiniMapNodeProps) -> Color)? = nil,
    selectedNodeColor: Color = .blue,
    nodeStrokeColor: Color = .clear,
    nodeStrokeWidth: CGFloat = 0,
    nodeBorderRadius: CGFloat = 1,
    maskColor: Color = .gray.opacity(0.1),
    width: CGFloat = 150,
    height: CGFloat = 100,
    pannable: Bool = true,
    zoomable: Bool = false,
    position: PanelPosition = .bottomRight,
    @ViewBuilder nodeContent: @escaping (MiniMapNodeProps) -> NodeContent
  ) {
    self.nodeColor = nodeColor
    self.nodeColorMapper = nodeColorMapper
    self.selectedNodeColor = selectedNodeColor
    self.nodeStrokeColor = nodeStrokeColor
    self.nodeStrokeWidth = nodeStrokeWidth
    self.nodeBorderRadius = nodeBorderRadius
    self.maskColor = maskColor
    self.width = width
    self.height = height
    self.pannable = pannable
    self.zoomable = zoomable
    self.position = position
    self.nodeContent = nodeContent
  }

  // MARK: - Node Props Helper

  private func nodeProps(for node: AnyNodeSnapshot) -> MiniMapNodeProps {
    let absPos = flowState.absolutePositions[node.id] ?? XYPosition(x: node.x, y: node.y)
    let size = flowState.nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
    return MiniMapNodeProps(
      id: node.id, x: absPos.x, y: absPos.y,
      width: size.width, height: size.height,
      selected: node.selected, type: node.type
    )
  }

  // MARK: - Computed Layout

  private var visibleNodes: [AnyNodeSnapshot] {
    flowState.nodes.filter { !$0.hidden }
  }

  private var bounds: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
    guard !visibleNodes.isEmpty else {
      return (0, 0, max(flowState.viewSize.width, 1), max(flowState.viewSize.height, 1))
    }
    var minX: CGFloat = .infinity
    var minY: CGFloat = .infinity
    var maxX: CGFloat = -.infinity
    var maxY: CGFloat = -.infinity
    for node in visibleNodes {
      let pos = flowState.absolutePositions[node.id] ?? XYPosition(x: node.x, y: node.y)
      let size = flowState.nodeSizes[node.id] ?? CGSize(width: 100, height: 50)
      minX = min(minX, pos.x)
      minY = min(minY, pos.y)
      maxX = max(maxX, pos.x + size.width)
      maxY = max(maxY, pos.y + size.height)
    }
    if minX == .infinity {
      return (0, 0, max(flowState.viewSize.width, 1), max(flowState.viewSize.height, 1))
    }
    return (minX, minY, maxX, maxY)
  }

  private var pad: CGFloat { 20 }

  private var scale: CGFloat {
    let b = bounds
    let cw = max(b.maxX - b.minX, 1)
    let ch = max(b.maxY - b.minY, 1)
    return min((width - pad * 2) / cw, (height - pad * 2) / ch, 1.0)
  }

  // MARK: - Body

  public var body: some View {
    let s = scale
    let b = bounds

    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 6)
        .fill(maskColor.opacity(0.9))
        .overlay(
          RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))

      nodesLayer(scale: s, bounds: b)
      edgesLayer(scale: s, bounds: b)
      viewportIndicator(scale: s, bounds: b)
    }
    .frame(width: width, height: height)
    .contentShape(Rectangle())
    .gesture(pannable ? minimapDragGesture(scale: s, bounds: b) : nil)
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: panelAlignment)
  }

  // MARK: - Subviews

  private func nodesLayer(
    scale s: CGFloat, bounds b: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)
  ) -> some View {
    ForEach(visibleNodes) { node in
      let props = nodeProps(for: node)
      let scaledSize = CGSize(
        width: max(props.width * s, 4), height: max(props.height * s, 3))

      if let customContent = nodeContent {
        customContent(props)
          .frame(width: scaledSize.width, height: scaledSize.height)
          .offset(
            x: pad + (props.x - b.minX) * s,
            y: pad + (props.y - b.minY) * s
          )
      } else {
        let fillColor: Color =
          if let mapper = nodeColorMapper {
            mapper(props)
          } else {
            node.selected ? selectedNodeColor : nodeColor
          }

        RoundedRectangle(cornerRadius: nodeBorderRadius)
          .fill(fillColor)
          .if(nodeStrokeWidth > 0) { view in
            view.overlay(
              RoundedRectangle(cornerRadius: nodeBorderRadius)
                .stroke(nodeStrokeColor, lineWidth: nodeStrokeWidth)
            )
          }
          .frame(width: scaledSize.width, height: scaledSize.height)
          .offset(
            x: pad + (props.x - b.minX) * s,
            y: pad + (props.y - b.minY) * s
          )
      }
    }
  }

  private func miniMapEdgePath(
    edge: AnyEdgeSnapshot, scale s: CGFloat,
    bounds b: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)
  ) -> Path? {
    guard !edge.hidden,
      let sNode = visibleNodes.first(where: { $0.id == edge.source }),
      let tNode = visibleNodes.first(where: { $0.id == edge.target })
    else { return nil }
    let sP = flowState.absolutePositions[sNode.id] ?? XYPosition(x: sNode.x, y: sNode.y)
    let tP = flowState.absolutePositions[tNode.id] ?? XYPosition(x: tNode.x, y: tNode.y)
    let sS = flowState.nodeSizes[sNode.id] ?? CGSize(width: 100, height: 50)
    let tS = flowState.nodeSizes[tNode.id] ?? CGSize(width: 100, height: 50)
    var p = Path()
    p.move(
      to: CGPoint(
        x: pad + (sP.x + sS.width / 2 - b.minX) * s,
        y: pad + (sP.y + sS.height / 2 - b.minY) * s
      ))
    p.addLine(
      to: CGPoint(
        x: pad + (tP.x + tS.width / 2 - b.minX) * s,
        y: pad + (tP.y + tS.height / 2 - b.minY) * s
      ))
    return p
  }

  private func edgesLayer(
    scale s: CGFloat, bounds b: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)
  ) -> some View {
    ForEach(flowState.edges) { edge in
      if let path = miniMapEdgePath(edge: edge, scale: s, bounds: b) {
        path.stroke(Color.gray.opacity(0.3), lineWidth: 1)
      }
    }
  }

  private func viewportIndicator(
    scale s: CGFloat, bounds b: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)
  ) -> some View {
    let zoom = max(flowState.viewport.zoom, Viewport.minZoom)
    let vpX = pad + (-flowState.viewport.x / zoom - b.minX) * s
    let vpY = pad + (-flowState.viewport.y / zoom - b.minY) * s
    let vpW = (flowState.viewSize.width / zoom) * s
    let vpH = (flowState.viewSize.height / zoom) * s

    return RoundedRectangle(cornerRadius: 2)
      .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
      .frame(width: max(vpW, 1), height: max(vpH, 1))
      .offset(x: vpX, y: vpY)
  }

  /// Continuous drag gesture for panning the viewport via the minimap.
  private func minimapDragGesture(
    scale: CGFloat, bounds: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)
  ) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let canvasX = (value.location.x - pad) / scale + bounds.minX
        let canvasY = (value.location.y - pad) / scale + bounds.minY
        let zoom = flowState.viewport.zoom
        let newViewport = Viewport(
          x: -canvasX * zoom + flowState.viewSize.width / 2,
          y: -canvasY * zoom + flowState.viewSize.height / 2,
          zoom: zoom
        )
        flowState.setViewport(newViewport, animated: false)
      }
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

// MARK: - Convenience Init (no custom node content)

extension MiniMap where NodeContent == EmptyView {
  /// Creates a MiniMap with default (rectangle) node rendering.
  public init(
    nodeColor: Color = .gray.opacity(0.5),
    nodeColorMapper: ((MiniMapNodeProps) -> Color)? = nil,
    selectedNodeColor: Color = .blue,
    nodeStrokeColor: Color = .clear,
    nodeStrokeWidth: CGFloat = 0,
    nodeBorderRadius: CGFloat = 1,
    maskColor: Color = .gray.opacity(0.1),
    width: CGFloat = 150,
    height: CGFloat = 100,
    pannable: Bool = true,
    zoomable: Bool = false,
    position: PanelPosition = .bottomRight
  ) {
    self.nodeColor = nodeColor
    self.nodeColorMapper = nodeColorMapper
    self.selectedNodeColor = selectedNodeColor
    self.nodeStrokeColor = nodeStrokeColor
    self.nodeStrokeWidth = nodeStrokeWidth
    self.nodeBorderRadius = nodeBorderRadius
    self.maskColor = maskColor
    self.width = width
    self.height = height
    self.pannable = pannable
    self.zoomable = zoomable
    self.position = position
    self.nodeContent = nil
  }
}
