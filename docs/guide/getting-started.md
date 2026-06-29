# Getting Started

This guide walks through creating your first interactive node graph with SwiftFlow.

## Basic Setup

Create a SwiftUI view that owns graph state and renders the canvas:

```swift
import SwiftUI
import SwiftFlow

struct FlowEditor: View {
    @State var nodes: [Node<String>] = [
        Node(id: "1", position: XYPosition(x: 100, y: 100), data: "Start"),
        Node(id: "2", position: XYPosition(x: 300, y: 100), data: "Process"),
        Node(id: "3", position: XYPosition(x: 500, y: 100), data: "End"),
    ]
    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(id: "e1-2", source: "1", target: "2"),
        Edge(id: "e2-3", source: "2", target: "3"),
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
                edges = addEdge(connection, edges: edges)
            }
        ) { node in
            Text(node.data)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.1), radius: 2)
        }
    }
}
```

## The Change-Based State Model

SwiftFlow does not own your data. Instead, it emits change arrays through callbacks, and you apply them to your state:

| Callback          | Emitted Type          | Utility to Apply               |
| ----------------- | --------------------- | ------------------------------ |
| `onNodesChange`   | `[NodeChange<T>]`     | `applyNodeChanges(_:nodes:)`   |
| `onEdgesChange`   | `[EdgeChange<E>]`     | `applyEdgeChanges(_:edges:)`   |
| `onConnect`       | `Connection`          | `addEdge(_:edges:defaults:)`   |
| `onReconnect`     | `Edge<E>, Connection` | `reconnectEdge(_:_:_:)`        |

This pattern gives you full control over state — you can filter, transform, or persist changes before applying them.

## Adding Connection Handles

To make nodes connectable, add `Handle` views inside your node builder:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    HStack(spacing: 0) {
        Handle(nodeId: node.id, id: "input", type: .target, position: .left)

        Text(node.data)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

        Handle(nodeId: node.id, id: "output", type: .source, position: .right)
    }
    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))
}
```

Now users can drag from an output handle to an input handle to create edges.

## Adding Overlays

Place overlay components in the `overlay` closure to add background grids, controls, minimap, and custom panels:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    // node view
} overlay: {
    Background(variant: .dots, gap: 20)
    Controls(position: .bottomLeft)
    MiniMap(position: .bottomRight)

    Panel(position: .topRight) {
        VStack {
            Button("Add Node") { /* ... */ }
            Button("Reset View") { /* ... */ }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
```

## Enabling Edge Options

Set `defaultEdgeOptions` to configure newly created edges:

```swift
SwiftFlow(
    nodes: nodes, edges: edges, ...,
    defaultEdgeOptions: DefaultEdgeOptions(
        type: .smoothstep,
        animated: false,
        markerEnd: EdgeMarker(type: .arrowClosed)
    )
) { node in ... }
```

## Connection Validation

Use `isValidConnection` to reject connections dynamically:

```swift
SwiftFlow(
    nodes: nodes, edges: edges, ...,
    isValidConnection: { connection in
        // Prevent self-connections
        connection.source != connection.target
    }
) { node in ... }
```

## Next Steps

- **[Installation](/guide/installation)** — Add SwiftFlow to your project
- **[State Management](/guide/state-management)** — Centralized state with SwiftFlowStore
- **[Theming](/guide/theming)** — Customize colors and appearance
- **[SwiftFlow Canvas API](/api/swiftflow-canvas)** — Complete parameter reference
