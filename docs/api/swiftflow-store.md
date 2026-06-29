# SwiftFlowStore

An `ObservableObject` that encapsulates all graph state — nodes, edges, and viewport — in one place. Use `SwiftFlowStore` for centralized state management, similar to React Flow's hook pattern.

## Basic Setup

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

## Published Properties

| Property          | Type             | Description                              |
| ----------------- | ---------------- | ---------------------------------------- |
| `nodes`           | `[Node<N>]`      | All graph nodes                          |
| `edges`           | `[Edge<E>]`      | All graph edges                          |
| `viewport`        | `Viewport`       | Current viewport state                   |
| `selectedNodeIds` | `Set<String>`    | IDs of currently selected nodes          |
| `selectedEdgeIds` | `Set<String>`    | IDs of currently selected edges          |

All properties are `@Published`, so SwiftUI views automatically re-render on changes.

## State Mutation Methods

### onNodesChange(\_:)

```swift
public func onNodesChange(_ changes: [NodeChange<NodeData>])
```

Applies an array of `NodeChange` descriptors to the store's node array. Automatically updates `selectedNodeIds`.

```swift
// Direct use in SwiftFlow callback
onNodesChange: { store.onNodesChange($0) }

// Programmatic changes
store.onNodesChange([.add(item: newNode)])
store.onNodesChange([.selection(id: "node-1", selected: true)])
store.onNodesChange(nodes.map { .remove(id: $0.id) })
```

### onEdgesChange(\_:)

```swift
public func onEdgesChange(_ changes: [EdgeChange<EdgeData>])
```

Same pattern for edges. Automatically updates `selectedEdgeIds`.

```swift
store.onEdgesChange([.remove(id: "edge-1")])
```

### onConnect(\_:defaults:)

```swift
public func onConnect(_ connection: Connection, defaults: DefaultEdgeOptions? = nil)
```

Creates a new edge from a `Connection` and adds it to the edge array. Prevents duplicates.

```swift
onConnect: { connection in
    store.onConnect(connection, defaults: DefaultEdgeOptions(
        type: .smoothstep,
        markerEnd: .arrowClosed
    ))
}
```

## Data Access Methods

### getNode(id:)

```swift
public func getNode(id: String) -> Node<NodeData>?
```

Returns a node by ID, or `nil` if not found.

```swift
if let node = store.getNode(id: "node-1") {
    print(node.data)
}
```

### getEdge(id:)

```swift
public func getEdge(id: String) -> Edge<EdgeData>?
```

Returns an edge by ID, or `nil` if not found.

### getNodesData(ids:)

```swift
public func getNodesData(ids: [String]) -> [(id: String, data: NodeData)]
```

Batch-fetches node data for multiple IDs.

```swift
let data = store.getNodesData(ids: ["node-1", "node-2"])
for (id, nodeData) in data {
    print("\(id): \(nodeData)")
}
```

### getNodeConnections(nodeId:handleType:)

```swift
public func getNodeConnections(
    nodeId: String,
    handleType: HandleType? = nil
) -> [Connection]
```

Returns all connections for a specific node. Filter by handle type for incoming or outgoing edges:

```swift
// All connections
let all = store.getNodeConnections(nodeId: "node-1")

// Incoming only (edges pointing to this node)
let incoming = store.getNodeConnections(nodeId: "node-1", handleType: .target)

// Outgoing only (edges from this node)
let outgoing = store.getNodeConnections(nodeId: "node-1", handleType: .source)
```

### nodesInitialized

```swift
public var nodesInitialized: Bool
```

Returns `true` when all nodes have been measured (all have non-nil `width` and `height`). Useful for preventing serialization before the canvas has finished layout.

### nodeDataPublisher(id:)

```swift
public func nodeDataPublisher(id: String) -> AnyPublisher<NodeData, Never>
```

Returns a Combine publisher that emits node data whenever the specified node's data changes. Enables fine-grained reactivity without re-rendering on every graph change.

```swift
store.nodeDataPublisher(id: "node-1")
    .sink { data in
        print("Node 1 data changed:", data)
    }
    .store(in: &cancellables)
```

### deleteElements(nodeIds:edgeIds:)

```swift
@discardableResult
public func deleteElements(
    nodeIds: [String] = [],
    edgeIds: [String] = []
) -> (nodes: [Node<NodeData>], edges: [Edge<EdgeData>])
```

Deletes nodes and edges by ID. Returns the deleted elements for undo/redo support.

```swift
let deleted = store.deleteElements(nodeIds: ["node-1"], edgeIds: ["edge-1"])
undoStack.push(deleted)
```

---

## SwiftFlowProvider

A view wrapper that creates a `SwiftFlowStore` and injects it into the environment via `@EnvironmentObject`. Use this to share graph state across multiple child views without manual prop drilling.

```swift
SwiftFlowProvider(nodes: initialNodes, edges: initialEdges) { store in
    VStack {
        FlowToolbar()  // Accesses store via @EnvironmentObject
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

Child views access the store:

```swift
struct FlowToolbar: View {
    @EnvironmentObject var store: SwiftFlowStore<MyData, EmptyEdgeData>

    var body: some View {
        Button("Add Node") {
            let node = Node(id: UUID().uuidString,
                position: XYPosition(x: 200, y: 200),
                data: MyData(label: "New"))
            store.onNodesChange([.add(item: node)])
        }
    }
}
```

---

## SwiftFlowState (Environment Object)

The canvas internally injects `SwiftFlowState` into the environment. Overlay components like `Controls`, `MiniMap`, and `Background` use it to read viewport and graph state:

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

            // Monitor active connection state
            if let conn = flowState.activeConnection {
                Text(conn.isValid == true ? "Valid target" : "Invalid target")
            }
        }
    }
}
```

### SwiftFlowState Properties

| Property           | Type                                           | Description                              |
| ------------------ | ---------------------------------------------- | ---------------------------------------- |
| `viewport`         | `Viewport`                                     | Current pan/zoom state                   |
| `viewSize`         | `CGSize`                                       | Canvas view size                         |
| `nodes`            | `[AnyNodeSnapshot]`                            | Type-erased node snapshots               |
| `edges`            | `[AnyEdgeSnapshot]`                            | Type-erased edge snapshots               |
| `nodeSizes`        | `[String: CGSize]`                             | Measured node sizes                      |
| `absolutePositions`| `[String: XYPosition]`                         | Resolved absolute positions              |
| `handlePositions`  | `[String: CGPoint]`                            | Handle positions in canvas coords        |
| `handleTypes`      | `[String: HandleType]`                         | Handle type map                          |
| `connectionsMap`   | `[String: [Connection]]`                       | Connections keyed by node ID             |
| `activeConnection` | `ConnectionState?`                             | In-progress connection drag state        |

### SwiftFlowState Methods

| Method                        | Description                               |
| ----------------------------- | ----------------------------------------- |
| `zoomIn()`                    | Zoom in by 25%                            |
| `zoomOut()`                   | Zoom out by 25%                           |
| `zoomTo(_:)`                  | Set exact zoom level                      |
| `fitView()`                   | Fit all nodes into viewport               |
| `setViewport(_:animated:)`    | Set viewport directly                     |
| `applyViewport`               | Closure set by `SwiftFlow` for viewport   |

---

## Choosing Between Manual State and SwiftFlowStore

| Approach          | Best For                                    |
| ----------------- | ------------------------------------------- |
| Manual `@State`   | Simple graphs, quick prototypes             |
| `SwiftFlowStore`  | Complex graphs, multiple child views, centralized undo/redo |
| `SwiftFlowProvider`| Graphs where deeply nested child views need access to state |
