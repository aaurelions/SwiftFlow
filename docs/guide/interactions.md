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

`panOnScrollMode` restricts the pan direction of scroll panning only (drag panning is always free):

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

Double-tapping empty canvas zooms in by a factor of 2 around the center of the view:

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
FlowEdge(id: "e1", source: "1", target: "2", reconnectable: true)
```

Endpoint anchors appear only when `onReconnect` is set, the edge is `reconnectable`, the edge is selected, and `nodesConnectable` is on. The edge is not removed when the drag starts. On a valid drop, `onReconnect` is called with the original edge and the new connection; dropping anywhere else leaves the edge unchanged. `onConnect` is not used as a fallback.

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    onReconnect: { edge, connection in
        edges = reconnectEdge(edge, connection, edges)
    }
) { ... }
```

## Selection

### Node and Edge Selection

Tapping a node selects it and deselects all other nodes and edges (the same applies when tapping an edge). Hold **Command** (macOS) while tapping to toggle the element for multi-selection. `onNodeClick`, `onEdgeClick` and `onPaneClick` fire even when selection is disabled.

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
| **Cmd+C / Cmd+V**    | Copy / paste selected nodes and the edges between them |
| **Cmd+Z**            | Undo (covers deletions and pastes)        |
| **Cmd+Shift+Z**      | Redo                                      |
| **Delete / Backspace** | Delete selected nodes and edges (deletable only; deleting a node also removes its deletable descendants via `parentId` and all connected edges) |
| **Arrow keys**       | Nudge selected nodes by 1pt (respects `nodesDraggable` and `Node.draggable`) |
| **Shift+Arrow**      | Nudge selected nodes by 10pt              |
| **Tab / Shift+Tab**  | Move keyboard focus between focusable nodes, then edges (an off-screen node is panned into view) |
| **Return / Space**   | Select the focused node or edge           |
| **Escape**           | Deselect all                              |

The canvas receives keys after a click inside it, and never while a text field (including one inside a node) is being edited. Clicking the empty pane ends text editing. Set `Node.focusable` / `Edge.focusable` to `false` to skip elements in the focus order. On iOS, focusable elements take system keyboard focus with a hardware keyboard, and Return/Space/Escape behave the same.

Pasted edges keep all of their properties (data, style, zIndex, ...). Pasted children of copied parents keep their relative position; other pasted nodes are offset by 50pt.

Customize keyboard shortcuts:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    keyboardShortcuts: KeyboardShortcuts(
        deleteKeyCode: KeyCode.backspace.rawValue,
        forwardDeleteKeyCode: KeyCode.forwardDelete.rawValue,
        nudgeDistance: 1,
        shiftNudgeDistance: 10
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
| `.auto`   | Selected nodes come to front (default)                         |
| `.basic`  | Selected nodes come to front                                   |
| `.manual` | Only `zIndex` is used; selection does not raise nodes          |

```swift
// Manual z-index per node
Node(id: "front", ..., zIndex: 10)
Node(id: "back", ..., zIndex: -5)
```

## Accessibility

SwiftFlow includes built-in accessibility support:

- VoiceOver labels for nodes and edges
- Keyboard navigation and activation
- Configurable labels and hints for nodes, edges, handles, Controls buttons and the MiniMap

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    accessibilityConfig: AccessibilityConfig(
        nodeRoleDescription: "Workflow step",
        edgeRoleDescription: "Workflow link",
        handleAriaLabel: "Drag to connect",
        zoomInAriaLabel: "Zoom in"
    )
) { ... }
```

### Announcements and Localization

While VoiceOver runs, the canvas announces selection changes (debounced, so a selection box announces once it settles) and new connections or reconnections. Turn them off with `announceSelectionChanges` / `announceConnectionEvents`.

All default labels and messages come from SwiftFlow's string catalog (`Sources/SwiftFlow/Resources/Localizable.xcstrings`, English with plural rules), so translations can be added to the package. To use your own wording or your app's translations, pass strings or message closures:

```swift
AccessibilityConfig(
    nodeRoleDescription: String(localized: "Workflow step"),
    selectionAnnouncement: { nodes, edges in
        String(localized: "\(nodes) steps and \(edges) links selected")
    },
    connectionAnnouncement: { connection in
        String(localized: "Linked \(connection.source) to \(connection.target)")
    }
)
```

Arguments left `nil` use the localized defaults. `==` compares the strings and flags; the closures are not compared.

## Expanding Parents

A child with `expandParent: true` grows its parent while being dragged past the parent's right or bottom edge. Dragging past the top or left edge moves the parent and shifts its other children so they keep their place. With `extent: .parent`, the child stays at or beyond the parent's top-left corner and the parent grows to the right and bottom.
