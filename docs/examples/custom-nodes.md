# Custom Nodes Example

Demonstrates creating complex custom node views with multiple handles, resizing, and dynamic content.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct CustomNodeData: Equatable, Sendable, Codable {
    var title: String
    var subtitle: String
    var color: String  // "blue", "green", "orange", "purple"
    var inputCount: Int
    var outputCount: Int
}

// MARK: - Content View

struct CustomNodesExample: View {
    @State var nodes: [Node<CustomNodeData>] = [
        Node(
            id: "source",
            position: XYPosition(x: 50, y: 100),
            data: CustomNodeData(
                title: "Data Source",
                subtitle: "Reads data from API",
                color: "green",
                inputCount: 0,
                outputCount: 2
            ),
            sourcePosition: .right,
            targetPosition: .left
        ),
        Node(
            id: "transform",
            position: XYPosition(x: 350, y: 80),
            data: CustomNodeData(
                title: "Transformer",
                subtitle: "Maps and filters",
                color: "blue",
                inputCount: 2,
                outputCount: 2
            ),
            sourcePosition: .right,
            targetPosition: .left
        ),
        Node(
            id: "sink-1",
            position: XYPosition(x: 650, y: 40),
            data: CustomNodeData(
                title: "Database",
                subtitle: "Writes records",
                color: "purple",
                inputCount: 1,
                outputCount: 0
            ),
            sourcePosition: .right,
            targetPosition: .left
        ),
        Node(
            id: "sink-2",
            position: XYPosition(x: 650, y: 200),
            data: CustomNodeData(
                title: "Logger",
                subtitle: "Writes to console",
                color: "orange",
                inputCount: 1,
                outputCount: 0
            ),
            sourcePosition: .right,
            targetPosition: .left
        ),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = []

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            connectionMode: .strict,
            snapToGrid: true,
            snapGrid: (x: 15, y: 15)
        ) { node in
            CustomNodeView(node: node)
        } overlay: {
            Background(variant: .lines, color: .gray.opacity(0.1), gap: 40)
            Controls(position: .bottomLeft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Custom Node View

struct CustomNodeView: View {
    let node: Node<CustomNodeData>

    private var accentColor: Color {
        switch node.data.color {
        case "green":  return .green
        case "blue":   return .blue
        case "orange": return .orange
        case "purple": return .purple
        default:       return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            VStack(alignment: .leading, spacing: 2) {
                Text(node.data.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(node.data.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor)

            // Input handles
            if node.data.inputCount > 0 {
                Divider()
                inputHandles
            }

            // Output handles
            if node.data.outputCount > 0 {
                Divider()
                outputHandles
            }
        }
        .frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    node.selected ? accentColor : Color.gray.opacity(0.3),
                    lineWidth: node.selected ? 2 : 1
                )
        )
        .scaleEffect(node.selected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: node.selected)
    }

    @ViewBuilder
    private var inputHandles: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                ForEach(0..<node.data.inputCount, id: \.self) { index in
                    HStack {
                        Handle(
                            nodeId: node.id,
                            id: "in-\(index)",
                            type: .target,
                            position: .left,
                            color: accentColor
                        )
                        Text("Input \(index + 1)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var outputHandles: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(spacing: 6) {
                ForEach(0..<node.data.outputCount, id: \.self) { index in
                    HStack {
                        Text("Output \(index + 1)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Handle(
                            nodeId: node.id,
                            id: "out-\(index)",
                            type: .source,
                            position: .right,
                            color: accentColor
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Preview

#Preview {
    CustomNodesExample()
}
```

## What This Example Demonstrates

- **Multi-handle nodes**: Nodes with configurable numbers of input and output handles
- **Dynamic handle IDs**: Each handle has a unique ID (`in-0`, `in-1`, `out-0`, etc.) enabling precise edge routing
- **Accent colors**: Per-node color theming based on data
- **Selection animation**: Selected nodes scale up slightly with a spring animation
- **Structured nodes**: Header section with colored background, separate input/output sections
- **Strict connection mode**: Only source-to-target connections are allowed
