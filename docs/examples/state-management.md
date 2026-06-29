# State Management Example

Demonstrates using `SwiftFlowStore` with programmatic node/edge manipulation, viewport control, and serialization.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct TaskData: Equatable, Sendable, Codable {
    var name: String
    var assignee: String
    var status: String  // "pending", "active", "done"
}

struct TaskEdgeData: Equatable, Sendable, Codable, Hashable {
    var dependencyType: String  // "blocking", "sequential", "optional"
}

// MARK: - Content View

struct StateManagementExample: View {
    @StateObject var store = SwiftFlowStore<TaskData, TaskEdgeData>(
        nodes: [
            Node(
                id: "t1",
                position: XYPosition(x: 100, y: 100),
                data: TaskData(name: "Design API", assignee: "Alice", status: "done")
            ),
            Node(
                id: "t2",
                position: XYPosition(x: 400, y: 50),
                data: TaskData(name: "Implement Backend", assignee: "Bob", status: "active")
            ),
            Node(
                id: "t3",
                position: XYPosition(x: 400, y: 200),
                data: TaskData(name: "Build Frontend", assignee: "Charlie", status: "pending")
            ),
            Node(
                id: "t4",
                position: XYPosition(x: 700, y: 125),
                data: TaskData(name: "Integration Tests", assignee: "Alice", status: "pending")
            ),
        ],
        edges: [
            Edge(
                id: "e-t1-t2",
                source: "t1", target: "t2",
                data: TaskEdgeData(dependencyType: "blocking")
            ),
            Edge(
                id: "e-t1-t3",
                source: "t1", target: "t3",
                data: TaskEdgeData(dependencyType: "sequential")
            ),
            Edge(
                id: "e-t2-t4",
                source: "t2", target: "t4",
                data: TaskEdgeData(dependencyType: "blocking")
            ),
            Edge(
                id: "e-t3-t4",
                source: "t3", target: "t4",
                data: TaskEdgeData(dependencyType: "blocking")
            ),
        ]
    )

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Task Dependency Graph")
                    .font(.headline)

                Spacer()

                Button("Add Task") {
                    addRandomTask()
                }

                Button("Fit All") {
                    store.viewport = .identity  // reset first
                    // Fit is handled by MiniMap/Controls or instance
                }

                Button("Save") {
                    saveGraph()
                }
                .disabled(!store.nodesInitialized)

                Button("Load") {
                    loadGraph()
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Canvas
            SwiftFlow(
                nodes: store.nodes,
                edges: store.edges,
                onNodesChange: { store.onNodesChange($0) },
                onEdgesChange: { store.onEdgesChange($0) },
                onConnect: { connection in
                    store.onConnect(
                        connection,
                        defaults: DefaultEdgeOptions(
                            type: .smoothstep,
                            markerEnd: EdgeMarker(type: .arrowClosed)
                        )
                    )
                },
                onNodeContextMenu: { node in
                    store.deleteElements(nodeIds: [node.id], edgeIds: [])
                },
                onEdgeContextMenu: { edge in
                    store.deleteElements(nodeIds: [], edgeIds: [edge.id])
                },
                fitView: true,
                fitViewOptions: FitViewOptions(padding: 80, maxZoom: 1.5, duration: 0.5)
            ) { node in
                TaskNodeView(node: node)
            } overlay: {
                Background(variant: .dots, gap: 30)
                Controls(position: .bottomLeft)
                MiniMap(position: .bottomRight)

                // Status legend
                Panel(position: .topLeft) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Legend").font(.caption).bold()
                        HStack { Circle().fill(.green).frame(width: 8, height: 8); Text("Done").font(.caption) }
                        HStack { Circle().fill(.blue).frame(width: 8, height: 8); Text("Active").font(.caption) }
                        HStack { Circle().fill(.gray).frame(width: 8, height: 8); Text("Pending").font(.caption) }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Actions

    func addRandomTask() {
        let id = UUID().uuidString
        let names = ["Setup CI", "Write Tests", "Code Review", "Deploy", "Monitor"]
        let assignees = ["Alice", "Bob", "Charlie", "Diana"]
        let node = Node(
            id: id,
            position: XYPosition(
                x: CGFloat.random(in: 100...500),
                y: CGFloat.random(in: 50...300)
            ),
            data: TaskData(
                name: names.randomElement()!,
                assignee: assignees.randomElement()!,
                status: "pending"
            )
        )
        store.onNodesChange([.add(item: node)])
    }

    func saveGraph() {
        guard let data = try? toJSON(
            nodes: store.nodes,
            edges: store.edges,
            viewport: store.viewport
        ) else { return }
        UserDefaults.standard.set(data, forKey: "task-graph")
    }

    func loadGraph() {
        guard let data = UserDefaults.standard.data(forKey: "task-graph"),
              let doc = try? fromJSON(data) as SwiftFlowDocument<TaskData, TaskEdgeData>
        else { return }
        store.onNodesChange(
            store.nodes.map { NodeChange<TaskData>.remove(id: $0.id) }
                + doc.nodes.map { .add(item: $0) }
        )
        store.onEdgesChange(
            store.edges.map { EdgeChange<TaskEdgeData>.remove(id: $0.id) }
                + doc.edges.map { .add(item: $0) }
        )
        store.viewport = doc.viewport
    }
}

// MARK: - Task Node View

struct TaskNodeView: View {
    let node: Node<TaskData>

    private var statusColor: Color {
        switch node.data.status {
        case "done": return .green
        case "active": return .blue
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Handle(nodeId: node.id, id: "in", type: .target, position: .left, color: statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(node.data.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(node.data.assignee)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Handle(nodeId: node.id, id: "out", type: .source, position: .right, color: statusColor)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    node.selected ? Color.blue : Color.gray.opacity(0.3),
                    lineWidth: node.selected ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    StateManagementExample()
}
```

## What This Example Demonstrates

- **SwiftFlowStore**: Centralized state management with `ObservableObject`
- **Custom edge data**: `TaskEdgeData` with dependency type information
- **Programmatic node addition**: Add nodes with random data via button
- **Context menu deletion**: Right-click (macOS) or long-press (iOS) to delete nodes/edges
- **Fit view on load**: `fitView: true` with custom `FitViewOptions`
- **Panel overlay**: Status legend in top-left corner
- **Serialization**: Save and load complete graph state with JSON
- **Node status colors**: Visual distinction between done (green), active (blue), and pending (gray) tasks
- **Handle colors**: Handles match the node's status color
