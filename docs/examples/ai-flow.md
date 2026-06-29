# AI Flow — Project Setup & ContentView Demo

Build an interactive AI workflow editor with SwiftFlow. This example walks through creating a new SwiftUI project that depends on SwiftFlow and writing a complete `ContentView.swift` with nodes, edges, handles, and overlay components.

![AI Flow Demo Screenshot](/screenshot.png)

## Project Setup

### Add the SwiftFlow Package

Add SwiftFlow to your project via Xcode: **File → Add Package Dependencies...** and paste:

```
https://github.com/aaurelions/SwiftFlow.git
```

Choose version `0.1.0` or the latest release.

Alternatively, add it to your `Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "AI_FLOW",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/aaurelions/SwiftFlow.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "AI_FLOW",
            dependencies: ["SwiftFlow"]
        )
    ]
)
```

## ContentView.swift

Create `ContentView.swift` with the following code. This builds an AI request flow editor with classified outputs:

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct FlowNodeData: Equatable, Sendable, Codable {
    var label: String
    var nodeType: NodeCategory

    enum NodeCategory: String, Equatable, Sendable, Codable {
        case input
        case process
        case output
    }

    var icon: String {
        switch nodeType {
        case .input:  return "arrow.down.circle.fill"
        case .process: return "cpu.fill"
        case .output:  return "arrow.up.circle.fill"
        }
    }

    var tintColor: Color {
        switch nodeType {
        case .input:  return .blue
        case .process: return .purple
        case .output:  return .green
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State var nodes: [Node<FlowNodeData>] = [
        Node(
            id: "1",
            position: XYPosition(x: 100, y: 200),
            data: FlowNodeData(label: "User Input", nodeType: .input)
        ),
        Node(
            id: "2",
            position: XYPosition(x: 400, y: 80),
            data: FlowNodeData(label: "Prompt Enrichment", nodeType: .process)
        ),
        Node(
            id: "3",
            position: XYPosition(x: 400, y: 220),
            data: FlowNodeData(label: "LLM Inference", nodeType: .process)
        ),
        Node(
            id: "4",
            position: XYPosition(x: 400, y: 360),
            data: FlowNodeData(label: "Safety Filter", nodeType: .process)
        ),
        Node(
            id: "5",
            position: XYPosition(x: 700, y: 120),
            data: FlowNodeData(label: "Safe Output", nodeType: .output)
        ),
        Node(
            id: "6",
            position: XYPosition(x: 700, y: 280),
            data: FlowNodeData(label: "Flagged Output", nodeType: .output)
        ),
    ]

    // Use FlowEdge (type alias) to avoid ambiguity with SwiftUI.Edge.
    // Alternatively, qualify as SwiftFlow.Edge<EmptyEdgeData>.
    @State var edges: [FlowEdge<EmptyEdgeData>] = [
        FlowEdge(id: "e1-2", source: "1", target: "2", markerEnd: .arrowClosed),
        FlowEdge(id: "e1-3", source: "1", target: "3", markerEnd: .arrowClosed),
        FlowEdge(id: "e1-4", source: "1", target: "4", markerEnd: .arrowClosed),
        FlowEdge(id: "e2-5", source: "2", target: "5", markerEnd: .arrowClosed),
        FlowEdge(id: "e3-5", source: "3", target: "5", markerEnd: .arrowClosed),
        FlowEdge(id: "e4-6", source: "4", target: "6", markerEnd: .arrowClosed),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges,
                defaults: DefaultEdgeOptions(type: .smoothstep, markerEnd: .arrowClosed)) },
            connectionLineType: .smoothstep
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
            // Target handle (receives connections)
            Handle(
                nodeId: node.id,
                id: "input",
                type: .target,
                position: .left,
                color: node.selected ? node.data.tintColor : .gray
            )

            VStack(spacing: 4) {
                Image(systemName: node.data.icon)
                    .font(.system(size: 20))
                    .foregroundColor(node.selected
                        ? node.data.tintColor
                        : node.data.tintColor.opacity(0.7))

                Text(node.data.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(node.data.nodeType.rawValue.capitalized)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 120)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Source handle (initiates connections)
            Handle(
                nodeId: node.id,
                id: "output",
                type: .source,
                position: .right,
                color: node.selected ? node.data.tintColor : .gray
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(
                    color: .black.opacity(node.selected ? 0.15 : 0.06),
                    radius: node.selected ? 8 : 3,
                    y: node.selected ? 4 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    node.selected ? node.data.tintColor : Color.gray.opacity(0.3),
                    lineWidth: node.selected ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
```

## Key Concepts Demonstrated

- **`import SwiftFlow`** — Required alongside `import SwiftUI` for all SwiftFlow types.
- **`FlowEdge<EmptyEdgeData>`** — The canonical type alias for `Edge`. When both `SwiftUI` and `SwiftFlow` are imported, the module `SwiftFlow` and the struct `SwiftFlow` (the canvas view) share the same name, making `Edge` ambiguous with `SwiftUI.Edge`. Use `FlowEdge<EmptyEdgeData>` or fully qualify as `SwiftFlow.Edge<EmptyEdgeData>`.
- **Node data model** — Typed `FlowNodeData` with an enum `NodeCategory` for per-node styling and icon selection.
- **Connection handles** — Every node declares a `.target` (input) handle on the left and a `.source` (output) handle on the right.
- **Selection styling** — Nodes show a colored border and enhanced shadow when selected; handles glow in the node's tint color.
- **Overlay components** — Dot-grid background, zoom/fit controls (bottom-left), and interactive minimap (bottom-right).
- **Default edge options** — New connections use `smoothstep` paths with filled arrowheads.

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 16.0+           |
| macOS    | 13.0+           |
| Swift    | 6.1+            |

SwiftFlow is a **zero-dependency** library — no third-party packages beyond Apple's frameworks.
