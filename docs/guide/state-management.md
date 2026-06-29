# State Management

SwiftFlow uses a **change-based** state model. The canvas does not own your data — it emits mutation descriptors through callbacks, and you control how they are applied.

## Manual State (Recommended for Simple Cases)

Manage graph state directly in a `@State` property:

```swift
@State var nodes: [Node<MyData>] = [...]
@State var edges: [Edge<EmptyEdgeData>] = [...]

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
    MyNodeView(node: node)
}
```

### Customizing Change Handling

Since you own the change pipeline, you can intercept, transform, or validate changes before applying them:

```swift
onNodesChange: { changes in
    // Filter out changes to locked nodes
    let filtered = changes.filter { change in
        switch change {
        case .position(let id, _), .selection(let id, _):
            return !lockedNodeIds.contains(id)
        default:
            return true
        }
    }
    nodes = applyNodeChanges(filtered, nodes: nodes)

    // Auto-save after each change
    saveToDisk(nodes, edges)
}
```

## SwiftFlowStore (Recommended for Complex Graphs)

For centralized state management, use `SwiftFlowStore` — an `ObservableObject` that encapsulates nodes, edges, and viewport state:

```swift
@StateObject var store = SwiftFlowStore<MyData, EmptyEdgeData>(
    nodes: initialNodes,
    edges: initialEdges
)

SwiftFlow(
    nodes: store.nodes,
    edges: store.edges,
    onNodesChange: { store.onNodesChange($0) },
    onEdgesChange: { store.onEdgesChange($0) },
    onConnect: { store.onConnect($0) }
) { node in
    MyNodeView(node: node)
}
```

### Accessing Store Data

The store provides reactive access to graph state:

```swift
// Published properties
store.nodes          // [Node<MyData>]
store.edges          // [Edge<EmptyEdgeData>]
store.viewport       // Viewport
store.selectedNodeIds // Set<String>
store.selectedEdgeIds // Set<String>
store.nodesInitialized // Bool

// Lookup methods
let node = store.getNode(id: "node-1")
let edge = store.getEdge(id: "edge-1")

// Get connections for a node
let incoming = store.getNodeConnections(nodeId: "node-2", handleType: .target)
let allConnections = store.getNodeConnections(nodeId: "node-2")

// Get node data by IDs
let data = store.getNodesData(ids: ["node-1", "node-2"])
```

### Fine-Grained Reactivity

Subscribe to individual node data changes without re-rendering on every graph change:

```swift
store.nodeDataPublisher(id: "node-1")
    .sink { data in
        print("Node 1 data changed:", data)
    }
    .store(in: &cancellables)
```

### Programmatic Deletion

```swift
let deleted = store.deleteElements(
    nodeIds: ["node-1", "node-2"],
    edgeIds: ["edge-1"]
)
// deleted.nodes contains removed nodes
// deleted.edges contains removed edges
```

## SwiftFlowProvider

Wrap the canvas with `SwiftFlowProvider` to inject the store into the environment, making it available to deeply nested child views:

```swift
SwiftFlowProvider(nodes: initialNodes, edges: initialEdges) { store in
    VStack {
        // Access store via environment in child views
        FlowToolbar()

        SwiftFlow(
            nodes: store.nodes,
            edges: store.edges,
            onNodesChange: { store.onNodesChange($0) },
            onEdgesChange: { store.onEdgesChange($0) },
            onConnect: { store.onConnect($0) }
        ) { node in
            MyNodeView(node: node)
        }
    }
}
```

Child views access the store via `@EnvironmentObject`:

```swift
struct FlowToolbar: View {
    @EnvironmentObject var store: SwiftFlowStore<MyData, EmptyEdgeData>

    var body: some View {
        HStack {
            Button("Add Node") {
                let newNode = Node(
                    id: UUID().uuidString,
                    position: XYPosition(x: CGFloat.random(in: 0...300), y: CGFloat.random(in: 0...300)),
                    data: MyData(label: "New Node")
                )
                store.onNodesChange([.add(item: newNode)])
            }
        }
    }
}
```

## Programmatic Viewport Control

Use `SwiftFlowInstance` to imperatively control the camera:

```swift
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(
    nodes: nodes, edges: edges,
    swiftFlowInstance: instance, ...
) { node in ... }

// Control methods
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
instance.zoomIn()
instance.zoomOut()
instance.setCenter(x: 200, y: 150, zoom: 1.0, animated: true)
instance.reset()

// Coordinate conversion
let screenPoint = CGPoint(x: 300, y: 200)
let flowPosition = instance.screenToFlowPosition(screenPoint)
```

### Accessing SwiftFlowInstance from Child Views

```swift
struct MyNodeView: View {
    let node: Node<MyData>
    @Environment(\.swiftFlowInstance) var instance

    var body: some View {
        VStack {
            Text(node.data.label)
            Button("Focus") {
                instance?.setCenter(x: node.position.x, y: node.position.y, zoom: 1)
            }
        }
    }
}
```

## SwiftFlowState (Environment Object)

The canvas injects `SwiftFlowState` into the environment, which overlay components like `Controls`, `MiniMap`, and `Background` use to read viewport and graph state:

```swift
struct CustomOverlay: View {
    @EnvironmentObject var flowState: SwiftFlowState

    var body: some View {
        VStack {
            Text("Zoom: \(String(format: "%.0f%%", flowState.viewport.zoom * 100))")
            Text("Nodes: \(flowState.nodes.count)")

            Button("Fit View") {
                flowState.fitView()
            }

            // Active connection state
            if let conn = flowState.activeConnection {
                Text("Connecting...")
                    .foregroundColor(conn.isValid == true ? .green : .red)
            }
        }
    }
}
```

## Undo / Redo

SwiftFlow has a built-in undo/redo stack on macOS. The canvas automatically pushes state before every mutation. Use `Cmd+Z` to undo and `Cmd+Shift+Z` to redo.

The undo stack has a maximum depth of 50 entries.

## Copy / Paste

Selected nodes (and edges between them) can be copied with `Cmd+C` and pasted with `Cmd+V`. Pasted nodes are offset by 50pt and assigned new unique IDs.
