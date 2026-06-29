# Custom Edges Example

Demonstrates custom edge rendering, animated edges, edge labels, markers, and reconnection.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct EdgeExampleData: Equatable, Sendable, Codable {
    var label: String
}

// MARK: - Content View

struct CustomEdgesExample: View {
    @State var nodes: [Node<EdgeExampleData>] = [
        Node(id: "1", position: XYPosition(x: 100, y: 200), data: EdgeExampleData(label: "Source")),
        Node(id: "2", position: XYPosition(x: 400, y: 100), data: EdgeExampleData(label: "Target A")),
        Node(id: "3", position: XYPosition(x: 400, y: 300), data: EdgeExampleData(label: "Target B")),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(
            id: "e1-2",
            source: "1", target: "2",
            type: .bezier,
            label: "Bezier",
            animated: true,
            markerEnd: EdgeMarker(type: .arrowClosed)
        ),
        Edge(
            id: "e1-3",
            source: "1", target: "3",
            type: .smoothstep,
            label: "Smoothstep",
            markerEnd: EdgeMarker(type: .arrow)
        ),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            onReconnect: { edge, connection in
                edges = reconnectEdge(edge, connection, edges)
            },
            defaultEdgeOptions: DefaultEdgeOptions(
                type: .smoothstep,
                markerEnd: EdgeMarker(type: .arrowClosed)
            ),
            // Custom edge rendering
            edgeContent: { edge, pathResult in
                AnyView(
                    ZStack {
                        // Glow effect for animated edges
                        if edge.animated {
                            pathResult.path.stroke(
                                .blue.opacity(0.15),
                                style: StrokeStyle(
                                    lineWidth: 8,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [8, 4]
                                )
                            )
                        }

                        // Main edge stroke
                        pathResult.path.stroke(
                            edge.selected ? .cyan : .blue.opacity(0.7),
                            style: StrokeStyle(
                                lineWidth: edge.selected ? 3.5 : 2.5,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: edge.animated ? [8, 4] : []
                            )
                        )
                    }
                )
            }
        ) { node in
            Text(node.data.label)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
        } overlay: {
            Background(variant: .dots, gap: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    CustomEdgesExample()
}
```

## What This Example Demonstrates

- **Custom edge rendering**: Using `edgeContent` to draw edges with multiple layers (glow effect for animated edges)
- **Animated edges**: The `bezier` edge uses an animated dash pattern with a glow effect
- **Edge reconnection**: `onReconnect` is configured so edges can be dragged to new targets
- **Edge labels**: Each edge has a label that appears at its midpoint
- **Edge markers**: Arrowheads at the target endpoints (closed arrow for one, open arrow for another)
- **Default edge options**: New connections get `smoothstep` style with arrowheads

## Edge Types Visual Comparison

| Type            | Description                              | Best Use Case              |
| --------------- | ---------------------------------------- | -------------------------- |
| `.bezier`       | Smooth S-curve                           | General flow diagrams      |
| `.straight`     | Direct line                              | Simple connections         |
| `.step`         | Right-angle steps (sharp corners)        | Circuit/organization charts|
| `.smoothstep`   | Right-angle steps (rounded)              | Clean orthogonal routing   |
| `.simplebezier` | Quadratic curve with one control point   | Simple curved connections  |

## Edge Properties for Interaction

| Property          | Type     | Default | Effect                                           |
| ----------------- | -------- | ------- | ------------------------------------------------ |
| `animated`        | `Bool`   | `false` | Dashed line with repeating animation             |
| `reconnectable`   | `Bool`   | `false` | Show endpoint handles on selection for reconnection |
| `interactionWidth`| `CGFloat`| `20`    | Width of invisible tap target area               |
