# Callbacks

SwiftFlow emits events through closure callbacks. All callbacks are optional — only set the ones you need.

## Change Callbacks

These are the core callbacks for state mutation. They emit change descriptors that you apply to your state.

### onNodesChange

```swift
onNodesChange: (([NodeChange<NodeData>]) -> Void)?
```

Called when node positions, selections, or dimensions change. Apply changes with `applyNodeChanges(_:nodes:)`:

```swift
SwiftFlow(
    nodes: nodes, edges: edges,
    onNodesChange: { changes in
        nodes = applyNodeChanges(changes, nodes: nodes)
    }
) { ... }
```

### onEdgesChange

```swift
onEdgesChange: (([EdgeChange<EdgeData>]) -> Void)?
```

Called when edge selections change or edges are removed. Apply with `applyEdgeChanges(_:edges:)`:

```swift
onEdgesChange: { changes in
    edges = applyEdgeChanges(changes, edges: edges)
}
```

### onConnect

```swift
onConnect: ((Connection) -> Void)?
```

Called when a user completes a valid connection between two handles. Create an edge with `addEdge(_:edges:defaults:)`:

```swift
onConnect: { connection in
    edges = addEdge(connection, edges: edges)
}

// With default edge options
onConnect: { connection in
    edges = addEdge(connection, edges: edges,
                    defaults: DefaultEdgeOptions(type: .smoothstep, markerEnd: .arrowClosed))
}
```

### onReconnect

```swift
onReconnect: ((Edge<EdgeData>, Connection) -> Void)?
```

Called when a user drags a reconnectable edge endpoint to a new handle:

```swift
onReconnect: { edge, connection in
    edges = reconnectEdge(edge, connection, edges)
}
```

---

## Viewport Callbacks

### onViewportChange

```swift
onViewportChange: ((Viewport) -> Void)?
```

Fires on every viewport change (pan, zoom). Use to persist viewport state:

```swift
onViewportChange: { viewport in
    saveViewportToDisk(viewport)
}
```

### onMoveStart / onMove / onMoveEnd

```swift
onMoveStart: ((Viewport) -> Void)?
onMove: ((Viewport) -> Void)?
onMoveEnd: ((Viewport) -> Void)?
```

Fine-grained viewport movement tracking:

```swift
onMoveStart: { _ in showGrid = true },
onMove: { vp in updateCursorPosition(vp) },
onMoveEnd: { _ in showGrid = false }
```

---

## Selection Callbacks

### onSelectionChange

```swift
onSelectionChange: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?
```

Fires when the set of selected nodes or edges changes:

```swift
onSelectionChange: { selectedNodes, selectedEdges in
    showProperties = !selectedNodes.isEmpty
}
```

### onPaneClick

```swift
onPaneClick: (() -> Void)?
```

Called when the user taps empty canvas space:

```swift
onPaneClick: {
    selectedNodeId = nil
}
```

---

## Node Interaction Callbacks

### onNodeClick / onNodeDoubleClick

```swift
onNodeClick: ((Node<NodeData>) -> Void)?
onNodeDoubleClick: ((Node<NodeData>) -> Void)?
```

Called when a node is tapped or double-tapped:

```swift
onNodeClick: { node in
    openNodeEditor(for: node.id)
},
onNodeDoubleClick: { node in
    toggleNodeExpansion(node)
}
```

### onNodeDragStart / onNodeDrag / onNodeDragStop

```swift
onNodeDragStart: ((Node<NodeData>) -> Void)?
onNodeDrag: ((Node<NodeData>) -> Void)?
onNodeDragStop: ((Node<NodeData>) -> Void)?
```

Track individual node drag lifecycle:

```swift
onNodeDragStart: { _ in isDragging = true },
onNodeDrag: { node in updatePreview(node.position) },
onNodeDragStop: { _ in isDragging = false }
```

### onNodeMouseEnter / onNodeMouseLeave

```swift
onNodeMouseEnter: ((Node<NodeData>) -> Void)?
onNodeMouseLeave: ((Node<NodeData>) -> Void)?
```

**macOS only.** Fires when the mouse enters or leaves a node:

```swift
onNodeMouseEnter: { node in hoveredNodeId = node.id },
onNodeMouseLeave: { _ in hoveredNodeId = nil }
```

### onNodeContextMenu

```swift
onNodeContextMenu: ((Node<NodeData>) -> Void)?
```

Fires on right-click (macOS) or long-press (iOS) on a node:

```swift
onNodeContextMenu: { node in
    showContextMenu = true
    contextMenuNodeId = node.id
}
```

---

## Edge Interaction Callbacks

### onEdgeClick / onEdgeDoubleClick

```swift
onEdgeClick: ((Edge<EdgeData>) -> Void)?
onEdgeDoubleClick: ((Edge<EdgeData>) -> Void)?
```

Double-clicking an edge also deletes it by default (before the callback fires). You can prevent this by not allowing selection (`elementsSelectable: false`).

### onEdgeMouseEnter / onEdgeMouseLeave

**macOS only.** Same semantics as node hover events.

### onEdgeContextMenu

```swift
onEdgeContextMenu: ((Edge<EdgeData>) -> Void)?
```

Fires on right-click (macOS) or long-press (iOS) on an edge.

---

## Connection Drawing Callbacks

### onConnectStart / onConnectEnd

```swift
onConnectStart: ((OnConnectStartParams) -> Void)?
onConnectEnd: (() -> Void)?
```

Track the connection drawing lifecycle:

```swift
onConnectStart: { params in
    // params.nodeId, params.handleId, params.handleType
    showConnectHint = true
},
onConnectEnd: {
    showConnectHint = false
}
```

### isValidConnection

```swift
isValidConnection: ((Connection) -> Bool)?
```

Validate connections before they are created:

```swift
isValidConnection: { connection in
    // Prevent self-connections
    guard connection.source != connection.target else { return false }

    // Prevent duplicate edges
    let exists = edges.contains { existing in
        existing.source == connection.source
        && existing.target == connection.target
    }
    return !exists
}
```

---

## Deletion Callbacks

### onBeforeDelete

```swift
onBeforeDelete: (([Node<NodeData>], [Edge<EdgeData>]) async -> BeforeDeleteResult<NodeData, EdgeData>?)?
```

Async validation before deletion. Return `.cancel` to abort, or `.delete(nodes:edges:)` with a (possibly filtered) subset:

```swift
onBeforeDelete: { nodesToDelete, edgesToDelete in
    // Show confirmation dialog
    let confirmed = await showDeleteConfirmation(nodesToDelete)
    if confirmed {
        return .delete(nodes: nodesToDelete, edges: edgesToDelete)
    } else {
        return .cancel
    }
}
```

### onNodesDelete / onEdgesDelete

```swift
onNodesDelete: (([Node<NodeData>]) -> Void)?
onEdgesDelete: (([Edge<EdgeData>]) -> Void)?
```

Fires when nodes or edges are deleted:

```swift
onNodesDelete: { deletedNodes in
    undoManager.pushUndo(deletedNodes)
}
```

### onDelete

```swift
onDelete: (([Node<NodeData>], [Edge<EdgeData>]) -> Void)?
```

Fires after deletion completes, receiving both deleted nodes and edges:

```swift
onDelete: { deletedNodes, deletedEdges in
    saveToHistory(deletedNodes, deletedEdges)
}
```

---

## Selection Drag Callbacks

Fires during multi-node drag operations:

```swift
onSelectionDragStart: (([Node<NodeData>]) -> Void)?
onSelectionDrag: (([Node<NodeData>]) -> Void)?
onSelectionDragStop: (([Node<NodeData>]) -> Void)?
```

---

## Other Callbacks

### onInit

```swift
onInit: (() -> Void)?
```

Fires once when the canvas finishes initializing:

```swift
onInit: {
    loadSavedGraph()
}
```

### onError

```swift
onError: ((String, String) -> Void)?
```

Receives error code and message for internal errors:

```swift
onError: { code, message in
    print("[SwiftFlow Error \(code)] \(message)")
}
```

### onPaneContextMenu

```swift
onPaneContextMenu: (() -> Void)?
```

Fires on right-click (macOS) or long-press (iOS) on empty canvas space.
