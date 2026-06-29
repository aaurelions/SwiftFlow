# Connection Validation Example

Demonstrates connection validation rules: preventing self-connections, duplicate edges, type-based restrictions, and connection mode configuration.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct ConnExampleNodeData: Equatable, Sendable, Codable {
    var label: String
    var nodeRole: String  // "input", "process", "output"
}

// MARK: - Content View

struct ConnectionValidationExample: View {
    @State var nodes: [Node<ConnExampleNodeData>] = [
        Node(
            id: "in1",
            position: XYPosition(x: 50, y: 100),
            data: ConnExampleNodeData(label: "User Input", nodeRole: "input"),
            type: "input",
            sourcePosition: .right
        ),
        Node(
            id: "in2",
            position: XYPosition(x: 50, y: 250),
            data: ConnExampleNodeData(label: "Config File", nodeRole: "input"),
            type: "input",
            sourcePosition: .right
        ),
        Node(
            id: "proc1",
            position: XYPosition(x: 350, y: 80),
            data: ConnExampleNodeData(label: "Validator", nodeRole: "process"),
            type: "process",
            sourcePosition: .right,
            targetPosition: .left
        ),
        Node(
            id: "proc2",
            position: XYPosition(x: 350, y: 230),
            data: ConnExampleNodeData(label: "Transformer", nodeRole: "process"),
            type: "process",
            sourcePosition: .right,
            targetPosition: .left
        ),
        Node(
            id: "out1",
            position: XYPosition(x: 650, y: 150),
            data: ConnExampleNodeData(label: "Report", nodeRole: "output"),
            type: "output",
            targetPosition: .left
        ),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(id: "e1", source: "in1", target: "proc1",
             type: .smoothstep, markerEnd: .arrowClosed),
        Edge(id: "e2", source: "in2", target: "proc2",
             type: .smoothstep, markerEnd: .arrowClosed),
        Edge(id: "e3", source: "proc1", target: "out1",
             type: .smoothstep, markerEnd: .arrowClosed),
        Edge(id: "e4", source: "proc2", target: "out1",
             type: .smoothstep, markerEnd: .arrowClosed),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            connectionMode: .strict,
            connectionLineType: .smoothstep,
            isValidConnection: { connection in
                validateConnection(connection)
            }
        ) { node in
            ConnectionNodeView(node: node)
        } overlay: {
            Background(variant: .dots, gap: 25)
            Controls()

            Panel(position: .topRight) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Validation Rules")
                        .font(.caption.bold())
                    Text("• No self-connections")
                        .font(.caption2)
                    Text("• No duplicate edges")
                        .font(.caption2)
                    Text("• Inputs → Process → Outputs only")
                        .font(.caption2)
                    Text("• Outputs cannot be sources")
                        .font(.caption2)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Validation Logic

    func validateConnection(_ connection: Connection) -> Bool {
        // 1. Prevent self-connections
        guard connection.source != connection.target else {
            return false
        }

        // 2. Prevent duplicate edges (same source-target pair)
        let isDuplicate = edges.contains { existing in
            existing.source == connection.source &&
            existing.target == connection.target
        }
        if isDuplicate {
            return false
        }

        // 3. Get source and target nodes
        guard let sourceNode = nodes.first(where: { $0.id == connection.source }),
              let targetNode = nodes.first(where: { $0.id == connection.target })
        else {
            return false
        }

        // 4. Outputs cannot be sources (they are endpoints)
        if sourceNode.data.nodeRole == "output" {
            return false
        }

        // 5. Inputs cannot be targets (they only produce data)
        if targetNode.data.nodeRole == "input" {
            return false
        }

        // 6. Process-to-process is allowed
        // All rules pass
        return true
    }
}

// MARK: - Node View

struct ConnectionNodeView: View {
    let node: Node<ConnExampleNodeData>

    private var roleColor: Color {
        switch node.data.nodeRole {
        case "input":  return .green
        case "process": return .blue
        case "output": return .orange
        default:       return .gray
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Input handles (for process and output nodes)
            if node.data.nodeRole != "input" {
                Handle(
                    nodeId: node.id,
                    id: "in",
                    type: .target,
                    position: .left,
                    color: roleColor
                )
            }

            VStack(spacing: 2) {
                Text(node.data.label)
                    .font(.system(size: 12, weight: .semibold))
                Text(node.data.nodeRole.uppercased())
                    .font(.system(size: 9))
                    .foregroundColor(roleColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Output handles (for input and process nodes)
            if node.data.nodeRole != "output" {
                Handle(
                    nodeId: node.id,
                    id: "out",
                    type: .source,
                    position: .right,
                    color: roleColor
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(node.selected ? Color.blue : Color.gray.opacity(0.3),
                        lineWidth: node.selected ? 2 : 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ConnectionValidationExample()
}
```

## What This Example Demonstrates

- **Self-connection prevention**: Guards against connecting a node to itself
- **Duplicate edge detection**: Prevents multiple edges between the same source-target pair
- **Role-based validation**: Restricts connections based on node roles (input → process → output)
- **Direction rules**: Outputs can't be sources, inputs can't be targets
- **Connection mode**: Uses `.strict` to enforce source-to-target handle typing
- **Smoothstep edges**: New connections use smoothstep path style with arrowheads
- **Rules panel**: An overlay showing active validation rules to the user
- **Role-colored handles**: Handles match the node's role color (green=input, blue=process, orange=output)
