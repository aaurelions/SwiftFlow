# Auto Layout Example

Demonstrates all three layout algorithms (tree, force-directed, grid) with live switching.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct LayoutNodeData: Equatable, Sendable, Codable {
    var label: String
}

// MARK: - Content View

struct AutoLayoutExample: View {
    @State var nodes: [Node<LayoutNodeData>] = makeInitialNodes()
    @State var edges: [Edge<EmptyEdgeData>] = makeInitialEdges()
    @State var activeLayout: String = "tree"

    var body: some View {
        VStack(spacing: 0) {
            // Layout selector
            HStack(spacing: 8) {
                Text("Layout:")
                    .font(.caption).foregroundColor(.secondary)

                layoutButton("Tree", "tree")
                layoutButton("Force", "force")
                layoutButton("Grid", "grid")
                layoutButton("L→R", "leftright")

                Spacer()

                Button("Reset") {
                    nodes = makeInitialNodes()
                    edges = makeInitialEdges()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            SwiftFlow(
                nodes: nodes,
                edges: edges,
                onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
                onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
                onConnect: { edges = addEdge($0, edges: edges,
                    defaults: DefaultEdgeOptions(
                        type: .smoothstep,
                        markerEnd: .arrowClosed
                    ))
                },
                fitView: true,
                fitViewOptions: FitViewOptions(padding: 60, maxZoom: 2.0, duration: 0.4)
            ) { node in
                HStack(spacing: 0) {
                    Handle(nodeId: node.id, id: "in", type: .target, position: .left)
                    Text(node.data.label)
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    Handle(nodeId: node.id, id: "out", type: .source, position: .right)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(node.selected ? .blue : .gray.opacity(0.3), lineWidth: 1)
                )
            } overlay: {
                Background(variant: .dots, gap: 30)
                Controls(position: .bottomLeft)
                MiniMap()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Layout Buttons

    func layoutButton(_ title: String, _ id: String) -> some View {
        Button(title) {
            activeLayout = id
            applyLayout(id)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .tint(activeLayout == id ? .blue : .gray.opacity(0.3))
    }

    func applyLayout(_ id: String) {
        let algorithm: LayoutAlgorithm
        switch id {
        case "tree":
            algorithm = .tree(direction: .topToBottom, nodeSpacing: 60, levelSpacing: 120)
        case "force":
            algorithm = .forceDirected(iterations: 120, idealLength: 200, repulsion: 6000)
        case "grid":
            algorithm = .grid(columns: 4, nodeSpacing: 80)
        case "leftright":
            algorithm = .tree(direction: .leftToRight, nodeSpacing: 60, levelSpacing: 150)
        default:
            return
        }

        let changes = computeAutoLayout(
            nodes: nodes,
            edges: edges,
            algorithm: algorithm
        )
        nodes = applyNodeChanges(changes, nodes: nodes)
    }
}

// MARK: - Initial Graph

func makeInitialNodes() -> [Node<LayoutNodeData>] {
    [
        Node(id: "root",  position: .zero, data: LayoutNodeData(label: "Root")),
        Node(id: "a1",   position: .zero, data: LayoutNodeData(label: "Child A1")),
        Node(id: "a2",   position: .zero, data: LayoutNodeData(label: "Child A2")),
        Node(id: "a3",   position: .zero, data: LayoutNodeData(label: "Child A3")),
        Node(id: "b1",   position: .zero, data: LayoutNodeData(label: "Child B1")),
        Node(id: "b2",   position: .zero, data: LayoutNodeData(label: "Child B2")),
        Node(id: "c1",   position: .zero, data: LayoutNodeData(label: "Leaf C1")),
        Node(id: "c2",   position: .zero, data: LayoutNodeData(label: "Leaf C2")),
        Node(id: "c3",   position: .zero, data: LayoutNodeData(label: "Leaf C3")),
        Node(id: "orphan", position: .zero, data: LayoutNodeData(label: "Orphan")),
    ]
}

func makeInitialEdges() -> [Edge<EmptyEdgeData>] {
    [
        Edge(id: "e-r-a1", source: "root", target: "a1",
             markerEnd: .arrowClosed),
        Edge(id: "e-r-a2", source: "root", target: "a2",
             markerEnd: .arrowClosed),
        Edge(id: "e-r-a3", source: "root", target: "a3",
             markerEnd: .arrowClosed),
        Edge(id: "e-a1-b1", source: "a1", target: "b1",
             markerEnd: .arrowClosed),
        Edge(id: "e-a1-b2", source: "a1", target: "b2",
             markerEnd: .arrowClosed),
        Edge(id: "e-b1-c1", source: "b1", target: "c1",
             markerEnd: .arrowClosed),
        Edge(id: "e-b1-c2", source: "b1", target: "c2",
             markerEnd: .arrowClosed),
        Edge(id: "e-b2-c3", source: "b2", target: "c3",
             markerEnd: .arrowClosed),
    ]
}

// MARK: - Preview

#Preview {
    AutoLayoutExample()
}
```

## What This Example Demonstrates

- **Tree layout (top-to-bottom)**: Hierarchical arrangement using BFS level assignment
- **Tree layout (left-to-right)**: Same algorithm with horizontal flow direction
- **Force-directed layout**: Physics simulation with repulsion/attraction forces
- **Grid layout**: Simple row-major grid arrangement
- **computeAutoLayout**: Returns `[NodeChange]` for clean integration with the change pipeline
- **Orphan nodes**: The "Orphan" node has no edges — it's placed at level 0 in tree layout and gravitates to center in force layout
- **Live switching**: Change layouts at runtime without rebuilding the graph
- **Fit view**: Auto-fits all nodes after layout changes with smooth animation
