# Change Utilities

SwiftFlow provides free functions for applying change descriptors to your state arrays.

## applyNodeChanges

```swift
public func applyNodeChanges<T: Sendable>(
    _ changes: [NodeChange<T>],
    nodes: [Node<T>]
) -> [Node<T>]
```

Applies an array of `NodeChange` descriptors to a node array, returning a new array. This is the primary state-update function:

```swift
@State var nodes: [Node<MyData>] = [...]

SwiftFlow(
    nodes: nodes,
    edges: edges,
    onNodesChange: { changes in
        nodes = applyNodeChanges(changes, nodes: nodes)
    }, ...
) { ... }
```

## applyEdgeChanges

```swift
public func applyEdgeChanges<EdgeData: Equatable & Sendable & Hashable>(
    _ changes: [EdgeChange<EdgeData>],
    edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>]
```

Same pattern for edges:

```swift
@State var edges: [Edge<EmptyEdgeData>] = [...]

SwiftFlow(
    nodes: nodes, edges: edges,
    onEdgesChange: { changes in
        edges = applyEdgeChanges(changes, edges: edges)
    }, ...
) { ... }
```

## addEdge

```swift
public func addEdge<EdgeData: Equatable & Sendable & Hashable>(
    _ connection: Connection,
    edges: [Edge<EdgeData>],
    defaults: DefaultEdgeOptions? = nil
) -> [Edge<EdgeData>]
```

Creates a new edge from a `Connection` and appends it to the edge array. Duplicate prevention: does not add if an edge with the same source-target-handle combination already exists.

```swift
onConnect: { connection in
    edges = addEdge(connection, edges: edges)
}

// With default options applied to new edges
onConnect: { connection in
    edges = addEdge(
        connection,
        edges: edges,
        defaults: DefaultEdgeOptions(type: .smoothstep, markerEnd: .arrowClosed)
    )
}
```

## reconnectEdge

```swift
public func reconnectEdge<EdgeData: Equatable & Sendable & Hashable>(
    _ edge: Edge<EdgeData>,
    _ connection: Connection,
    _ edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>]
```

Updates an existing edge's source/target and handle references:

```swift
onReconnect: { edge, connection in
    edges = reconnectEdge(edge, connection, edges)
}
```

---

## NodeChange

```swift
public enum NodeChange<NodeData: Equatable & Sendable>: Sendable {
    case position(id: String, position: XYPosition)
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(item: Node<NodeData>)
    case dimensions(id: String, width: CGFloat, height: CGFloat)
    case replace(id: String, item: Node<NodeData>)
}
```

### Programmatic Usage

You can create changes manually for programmatic graph mutations:

```swift
// Move a node
onNodesChange?([.position(id: "node-1", position: XYPosition(x: 200, y: 300))])

// Select a node
onNodesChange?([.selection(id: "node-1", selected: true)])

// Delete a node
onNodesChange?([.remove(id: "node-1")])

// Add a new node
let newNode = Node(id: "new", position: XYPosition(x: 0, y: 0), data: "Hello")
onNodesChange?([.add(item: newNode)])

// Resize a node
onNodesChange?([.dimensions(id: "node-1", width: 300, height: 200)])

// Replace a node entirely
onNodesChange?([.replace(id: "node-1", item: updatedNode)])
```

---

## EdgeChange

```swift
public enum EdgeChange<EdgeData: Equatable & Sendable & Hashable>: Sendable {
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(item: Edge<EdgeData>)
    case replace(id: String, item: Edge<EdgeData>)
}
```

### Programmatic Usage

```swift
// Select an edge
onEdgesChange?([.selection(id: "edge-1", selected: true)])

// Delete an edge
onEdgesChange?([.remove(id: "edge-1")])

// Add a new edge
let newEdge = Edge<EmptyEdgeData>(id: "e-new", source: "1", target: "2")
onEdgesChange?([.add(item: newEdge)])

// Replace an edge
onEdgesChange?([.replace(id: "edge-1", item: modifiedEdge)])
```

---

## Batch Changes

You can pass multiple changes at once:

```swift
// Deselect all nodes
let deselectChanges = nodes.filter(\.selected).map {
    NodeChange<MyData>.selection(id: $0.id, selected: false)
}
onNodesChange?(deselectChanges)

// Select a node and move it
onNodesChange?([
    .selection(id: "node-1", selected: true),
    .position(id: "node-1", position: XYPosition(x: 500, y: 300)),
])
```

### Custom Change Filtering

Since you own the change pipeline, you can filter changes:

```swift
onNodesChange: { changes in
    // Block changes to locked nodes
    let filtered = changes.filter { change in
        switch change {
        case .position(let id, _),
             .selection(let id, _),
             .dimensions(let id, _, _):
            return !lockedNodeIds.contains(id)
        case .remove(let id):
            return !lockedNodeIds.contains(id)
        default:
            return true
        }
    }
    nodes = applyNodeChanges(filtered, nodes: nodes)
}
```
