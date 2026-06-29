# Viewport Controls Example

Demonstrates programmatic viewport control using `SwiftFlowInstance`: fit-to-view, zoom, center, coordinate conversion, and auto-fit on load.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct VPNodeData: Equatable, Sendable, Codable {
    var label: String
}

// MARK: - Content View

struct ViewportControlsExample: View {
    @State var nodes: [Node<VPNodeData>] = [
        Node(id: "1", position: XYPosition(x: -200, y: -100), data: VPNodeData(label: "Top-Left")),
        Node(id: "2", position: XYPosition(x: 400, y: -100), data: VPNodeData(label: "Top-Right")),
        Node(id: "3", position: XYPosition(x: -200, y: 300), data: VPNodeData(label: "Bottom-Left")),
        Node(id: "4", position: XYPosition(x: 400, y: 300), data: VPNodeData(label: "Bottom-Right")),
        Node(id: "5", position: XYPosition(x: 100, y: 100), data: VPNodeData(label: "Center")),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(id: "e1", source: "5", target: "1", type: .bezier, markerEnd: .arrowClosed),
        Edge(id: "e2", source: "5", target: "2", type: .bezier, markerEnd: .arrowClosed),
        Edge(id: "e3", source: "5", target: "3", type: .bezier, markerEnd: .arrowClosed),
        Edge(id: "e4", source: "5", target: "4", type: .bezier, markerEnd: .arrowClosed),
    ]

    @StateObject var instance = SwiftFlowInstance()
    @State var hoverFlowPoint: String = "—"
    @State var flowToScreenInfo: String = "—"

    var body: some View {
        VStack(spacing: 0) {
            // Viewport control toolbar
            HStack(spacing: 6) {
                Button("Fit All") {
                    instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
                }
                .buttonStyle(.bordered)

                Button("Fit Center") {
                    let options = FitViewOptions(
                        padding: 100,
                        maxZoom: 3.0,
                        duration: 0.6,
                        nodeIds: ["5"]
                    )
                    instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes, options: options)
                }
                .buttonStyle(.bordered)

                Divider().frame(height: 20)

                Button(action: { instance.zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.bordered)

                Button(action: { instance.zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.bordered)

                Text(String(format: "%.0f%%", instance.viewport.zoom * 100))
                    .font(.caption.monospaced())
                    .frame(minWidth: 40)

                Divider().frame(height: 20)

                Button(action: { instance.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Spacer()

                // Coordinate info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Flow → Screen: \(flowToScreenInfo)")
                        .font(.system(size: 9, design: .monospaced))
                    Text("Hover Flow: \(hoverFlowPoint)")
                        .font(.system(size: 9, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)

            SwiftFlow(
                nodes: nodes,
                edges: edges,
                onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
                onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
                onConnect: { edges = addEdge($0, edges: edges) },
                swiftFlowInstance: instance,
                fitView: true,
                fitViewOptions: FitViewOptions(padding: 80, maxZoom: 1.5, duration: 0.5)
            ) { node in
                Text(node.data.label)
                    .font(.system(size: 13))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            } overlay: {
                Background(variant: .dots, gap: 25)
                Controls(position: .bottomLeft)
                MiniMap()

                // Display node positions in flow coords
                Panel(position: .topLeft) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Node Positions").font(.caption2).bold()
                        ForEach(nodes.prefix(5), id: \.id) { node in
                            Text("\(node.id): (x:\(Int(node.position.x)), y:\(Int(node.position.y)))")
                                .font(.system(size: 9, design: .monospaced))
                        }
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let flowPos = instance.screenToFlowPosition(location)
                    hoverFlowPoint = String(format: "(%.0f, %.0f)", flowPos.x, flowPos.y)

                    let screenPos = instance.flowToScreenPosition(flowPos)
                    flowToScreenInfo = String(format: "(%.0f, %.0f)", screenPos.x, screenPos.y)
                case .ended:
                    hoverFlowPoint = "—"
                    flowToScreenInfo = "—"
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ViewportControlsExample()
}
```

## What This Example Demonstrates

- **SwiftFlowInstance setup**: Creating and passing an instance for imperative viewport control
- **Fit all nodes**: `fitView(nodes:nodeSizes:)` to frame all visible nodes
- **Fit specific nodes**: Using `FitViewOptions.nodeIds` to only frame the center node
- **Zoom in/out**: `zoomIn()` and `zoomOut()` for incremental zoom changes
- **Reset viewport**: `reset()` to return to origin at 100% zoom
- **Auto-fit on load**: `fitView: true` with `FitViewOptions` to auto-frame on first render
- **Coordinate conversion**: `screenToFlowPosition` and `flowToScreenPosition` for real-time coordinate display
- **Hover tracking**: Using `onContinuousHover` to display flow coordinates under the cursor
- **Zoom percentage display**: Real-time zoom level shown in the toolbar
- **Overlay integration**: Controls, MiniMap, and custom position panels alongside viewport toolbar
