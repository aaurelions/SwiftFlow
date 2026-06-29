# Interactions

SwiftFlow provides a rich set of canvas interaction modes that you can customize through parameters on the `SwiftFlow` view.

## Panning

### Pan on Drag (Default)

By default (`panOnDrag: true`), dragging on empty canvas space pans the viewport. Hold **Shift** to draw a selection box instead.

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., panOnDrag: true) { ... }
```

### Selection on Drag

When `selectionOnDrag: true`, the roles reverse: dragging creates a selection box, and **Shift+drag** pans.

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., selectionOnDrag: true) { ... }
```

### Pan on Scroll (macOS)

On macOS, you can configure scroll-wheel behavior to pan instead of zoom:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    panOnScroll: true,
    zoomOnScroll: false
) { ... }
```

`panOnScrollMode` controls the pan direction:

| Mode          | Description                                   |
| ------------- | --------------------------------------------- |
| `.free`       | Pan freely in both directions (default)       |
| `.vertical`   | Pan only vertically on scroll                 |
| `.horizontal` | Pan only horizontally on scroll               |

## Zooming

### Scroll Zoom (macOS)

Zoom in/out using the scroll wheel (on by default):

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., zoomOnScroll: true) { ... }
```

### Pinch Zoom (iOS)

Enable two-finger pinch zoom (on by default):

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., zoomOnPinch: true) { ... }
```

### Double-Click Zoom

Double-click on empty canvas to fit all nodes into view:

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., zoomOnDoubleClick: true) { ... }
```

### Zoom Constraints

Zoom is clamped between `Viewport.minZoom` (0.1 / 10%) and `Viewport.maxZoom` (4.0 / 400%).

## Node Dragging

### Basic Drag

Nodes are draggable by default. Set `nodesDraggable: false` to disable:

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., nodesDraggable: false) { ... }
```

Per-node control:

```swift
Node(id: "locked", ..., draggable: false)  // This node cannot be dragged
```

### Snap to Grid

Enable grid snapping during drag:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    snapToGrid: true,
    snapGrid: (x: 20, y: 20)
) { ... }
```

### Selection Drag

When dragging a selected node, all other selected nodes move together. The `onSelectionDragStart`, `onSelectionDrag`, and `onSelectionDragStop` callbacks track multi-node drag operations.

### Drag Constraints

Limit where nodes can be dragged:

```swift
// Global constraint
SwiftFlow(nodes: nodes, edges: edges, ...,
    coordinateExtent: CoordinateExtent(minX: 0, minY: 0, maxX: 1000, maxY: 800)
) { ... }

// Per-node constraint (within parent bounds)
Node(id: "child", ..., parentId: "group", extent: .parent)

// Per-node constraint (within explicit region)
Node(id: "bounded", ...,
     extent: .coordinateExtent(CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)))
```

## Connection Drawing

### Creating Connections

Connections are drawn by dragging from a source handle to a target handle. This is enabled by default (`nodesConnectable: true`).

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., nodesConnectable: true) { ... }
```

Per-node control:

```swift
Node(id: "readonly", ..., connectable: false)  // Handles on this node are inactive
```

Per-handle control:

```swift
Handle(nodeId: node.id, id: "locked", ..., isConnectable: false)
```

### Connection Mode

Controls which handle types can connect:

```swift
// Only source-to-target connections (default)
SwiftFlow(..., connectionMode: .strict) { ... }

// Any-to-any connections
SwiftFlow(..., connectionMode: .loose) { ... }
```

### Connection Line Style

Customize the in-progress connection line:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    connectionLineType: .smoothstep
) { ... }
```

Or provide a fully custom rendering:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    connectionLineContent: { connection, start, current in
        AnyView(
            Path { path in
                path.move(to: start)
                path.addQuadCurve(to: current, control: CGPoint(
                    x: (start.x + current.x) / 2,
                    y: min(start.y, current.y) - 50
                ))
            }
            .stroke(.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        )
    }
) { ... }
```

### Connection Validation

Use `isValidConnection` to prevent invalid connections:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    isValidConnection: { connection in
        connection.source != connection.target &&
        !edges.contains { $0.source == connection.source && $0.target == connection.target }
    }
) { ... }
```

### Reconnecting Edges

Edges can be reconnected when `reconnectable: true` is set on the edge:

```swift
Edge(id: "e1", source: "1", target: "2", reconnectable: true)
```

When a reconnectable edge is selected, draggable endpoint handles appear. Configure `onReconnect` to handle the new connection:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    onReconnect: { edge, connection in
        edges = reconnectEdge(edge, connection, edges)
    }
) { ... }
```

## Selection

### Node and Edge Selection

Tap a node or edge to select it. Only one item is selected at a time in the default mode.

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., elementsSelectable: true) { ... }
```

### Selection Box

Draw a selection box (Shift+drag by default, or regular drag when `selectionOnDrag: true`) to select multiple nodes:

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., selectionMode: .partial) { ... }  // Partial overlap selects
SwiftFlow(nodes: nodes, edges: edges, ..., selectionMode: .full) { ... }     // Full containment required
```

### Auto-Select on Drag

When `selectNodesOnDrag: true` (default), dragging an unselected node auto-selects it and deselects others:

```swift
SwiftFlow(nodes: nodes, edges: edges, ..., selectNodesOnDrag: false) { ... }
```

## Keyboard Shortcuts (macOS)

| Shortcut             | Action                                    |
| -------------------- | ----------------------------------------- |
| **Cmd+A**            | Select all nodes and edges                |
| **Cmd+C / Cmd+V**    | Copy / paste selected nodes               |
| **Cmd+Z**            | Undo                                      |
| **Cmd+Shift+Z**      | Redo                                      |
| **Delete / Backspace** | Delete selected nodes and edges           |
| **Arrow keys**       | Nudge selected nodes by 1pt               |
| **Shift+Arrow**      | Nudge selected nodes by 10pt              |

Customize keyboard shortcuts:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    keyboardShortcuts: KeyboardShortcuts(
        selectAll: KeyCode(key: "a", modifier: .command),
        delete: KeyCode(key: .delete, modifier: []),
        undo: KeyCode(key: "z", modifier: .command),
        redo: KeyCode(key: "z", modifier: [.command, .shift]),
        copy: KeyCode(key: "c", modifier: .command),
        paste: KeyCode(key: "v", modifier: .command),
        arrowNudge: 1,
        shiftArrowNudge: 10
    )
) { ... }
```

## Context Menus

Right-click (macOS) or long-press (iOS) triggers context menu callbacks:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    onNodeContextMenu: { node in showNodeMenu(node) },
    onEdgeContextMenu: { edge in showEdgeMenu(edge) },
    onPaneContextMenu: { showCanvasMenu() }
) { ... }
```

## Node Z-Index

Control render order with `zIndexMode`:

| Mode      | Description                                                    |
| --------- | -------------------------------------------------------------- |
| `.auto`   | Selected items come to front; sub-flows managed automatically  |
| `.basic`  | Selected items come to front only                              |
| `.manual` | No automatic z-indexing; values are entirely user-controlled   |

```swift
// Manual z-index per node
Node(id: "front", ..., zIndex: 10)
Node(id: "back", ..., zIndex: -5)
```

## Accessibility

SwiftFlow includes built-in accessibility support:

- VoiceOver labels for nodes and edges
- Keyboard navigation and activation
- Configurable announcements for selection and connection events

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    accessibilityConfig: AccessibilityConfig(
        nodeSelectedMessage: "Node selected",
        edgeSelectedMessage: "Edge selected",
        connectionCreatedMessage: "Connection created"
    )
) { ... }
```
