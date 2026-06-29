# Basic Graph Example

A complete working example of a basic flowchart editor with nodes, edges, handles, and overlay components.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct FlowNodeData: Equatable, Sendable, Codable {
    var label: String
}

// MARK: - Content View

struct BasicFlowExample: View {
    @State var nodes: [Node<FlowNodeData>] = [
        Node(
            id: "1",
            position: XYPosition(x: 100, y: 150),
            data: FlowNodeData(label: "Start")
        ),
        Node(
            id: "2",
            position: XYPosition(x: 350, y: 50),
            data: FlowNodeData(label: "Process A")
        ),
        Node(
            id: "3",
            position: XYPosition(x: 350, y: 250),
            data: FlowNodeData(label: "Process B")
        ),
        Node(
            id: "4",
            position: XYPosition(x: 600, y: 150),
            data: FlowNodeData(label: "End")
        ),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(id: "e1-2", source: "1", target: "2", markerEnd: .arrowClosed),
        Edge(id: "e1-3", source: "1", target: "3", markerEnd: .arrowClosed),
        Edge(id: "e2-4", source: "2", target: "4", markerEnd: .arrowClosed),
        Edge(id: "e3-4", source: "3", target: "4", markerEnd: .arrowClosed),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { changes in
                nodes = applyNodeChanges(changes, nodes: nodes)
            },
            onEdgesChange: { changes in
                edges = applyEdgeChanges(changes, edges: edges)
            },
            onConnect: { connection in
                let defaults = DefaultEdgeOptions(
                    type: .smoothstep,
                    markerEnd: EdgeMarker(type: .arrowClosed)
                )
                edges = addEdge(connection, edges: edges, defaults: defaults)
            },
            snapToGrid: false,
            snapGrid: (x: 20, y: 20)
        ) { node in
            FlowNodeView(node: node)
        } overlay: {
            Background(variant: .dots, gap: 25, size: 1.5)
            Controls(position: .bottomLeft)
            MiniMap(position: .bottomRight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Node View

struct FlowNodeView: View {
    let node: Node<FlowNodeData>

    var body: some View {
        HStack(spacing: 0) {
            Handle(
                nodeId: node.id,
                id: "input",
                type: .target,
                position: .left,
                color: node.selected ? .blue : .gray
            )

            VStack(spacing: 4) {
                Text(node.data.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(node.selected ? .blue : .primary)

                if node.selected {
                    Text("Selected")
                        .font(.system(size: 9))
                        .foregroundColor(.blue.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Handle(
                nodeId: node.id,
                id: "output",
                type: .source,
                position: .right,
                color: node.selected ? .blue : .gray
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)
                .shadow(color: .black.opacity(node.selected ? 0.15 : 0.08), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    node.selected ? Color.blue : Color.gray.opacity(0.4),
                    lineWidth: node.selected ? 2 : 1.5
                )
        )
    }
}

// MARK: - Preview

#Preview {
    BasicFlowExample()
}
```

## What This Example Demonstrates

- **Custom node data**: `FlowNodeData` with a label property
- **Connection handles**: Input (target) on the left, output (source) on the right
- **Selection styling**: Nodes show a blue border and shadow when selected
- **Edge creation**: New connections use `smoothstep` edges with arrowhead markers
- **Overlays**: Dot grid background, zoom controls, and minimap
- **Snap-to-grid**: Optional grid snapping during node drag (disabled here)
