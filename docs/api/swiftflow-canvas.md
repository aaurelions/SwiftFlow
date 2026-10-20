# SwiftFlow Canvas

The main interactive canvas component. Renders nodes and edges, handles panning, zooming, selection, connection drawing, and keyboard shortcuts.

## Signature

```swift
public struct SwiftFlow<
    NodeData: Equatable & Sendable,
    EdgeData: Equatable & Sendable & Hashable,
    NodeContent: View,
    Overlay: View
>: View
```

## Basic Usage

```swift
SwiftFlow(
    nodes: nodes,
    edges: edges,
    onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
    onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
    onConnect: { edges = addEdge($0, edges: edges) }
) { node in
    MyNodeView(node: node)
} overlay: {
    Background(variant: .dots)
    Controls()
    MiniMap()
}
```

## Core Data Parameters

| Parameter      | Type                  | Required | Description                            |
| -------------- | --------------------- | -------- | -------------------------------------- |
| `nodes`        | `[Node<NodeData>]`    | Yes      | Array of graph nodes                   |
| `edges`        | `[Edge<EdgeData>]`    | Yes      | Array of graph edges                   |
| `nodeContent`  | `(Node<NodeData>) -> NodeContent` | Yes | ViewBuilder for rendering each node |
| `overlay`      | `() -> Overlay`       | No       | ViewBuilder for overlay components     |

## Interaction Parameters

| Parameter             | Type              | Default     | Description                                           |
| --------------------- | ----------------- | ----------- | ----------------------------------------------------- |
| `nodesDraggable`      | `Bool`            | `true`      | Enable node dragging                                  |
| `nodesConnectable`    | `Bool`            | `true`      | Enable connection drawing from handles                |
| `elementsSelectable`  | `Bool`            | `true`      | Enable node and edge selection                        |
| `panOnDrag`           | `Bool`            | `true`      | Pan canvas on empty-space drag                        |
| `panOnScroll`         | `Bool`            | `false`     | Pan on scroll (macOS) instead of zoom                 |
| `panOnScrollMode`     | `PanOnScrollMode` | `.free`     | `.free`, `.vertical`, or `.horizontal`; restricts scroll panning only (drag panning is free) |
| `zoomOnScroll`        | `Bool`            | `true`      | Zoom with scroll wheel (macOS)                        |
| `zoomOnPinch`         | `Bool`            | `true`      | Zoom with pinch gesture (iOS)                         |
| `zoomOnDoubleClick`   | `Bool`            | `true`      | Double-tapping the pane zooms in by a factor of 2 around the view center |
| `selectionOnDrag`     | `Bool`            | `false`     | Draw selection box on drag (instead of panning)       |
| `selectNodesOnDrag`   | `Bool`            | `true`      | Auto-select a node when dragging it                   |
| `selectionMode`       | `SelectionMode`   | `.partial`  | `.partial` or `.full` containment for selection box   |
| `connectionMode`      | `ConnectionMode`  | `.strict`   | `.strict` (source→target) or `.loose` (any→any)      |
| `connectionLineType`  | `EdgeType`        | `.default`  | Visual style of in-progress connection line           |

## Appearance Parameters

| Parameter          | Type               | Default        | Description                                    |
| ------------------ | ------------------ | -------------- | ---------------------------------------------- |
| `backgroundVariant`| `BackgroundVariant?`| `nil`          | Built-in background pattern for backward compat |
| `snapToGrid`       | `Bool`             | `false`        | Snap node positions to grid during drag         |
| `snapGrid`         | `(x:CGFloat,y:CGFloat)`| `(20, 20)`  | Grid spacing for snap-to-grid                  |
| `theme`            | `SwiftFlowTheme`   | `.default`     | Visual theme                                    |
| `colorMode`        | `ColorMode`        | `.system`      | `.light`, `.dark`, or `.system`                 |
| `zIndexMode`       | `ZIndexMode`       | `.auto`        | `.auto`, `.basic`, or `.manual`                 |
| `nodeOrigin`       | `NodeOrigin`       | `.topLeft`     | Node anchor: node top-left = `position - origin * size`. `Node.origin` wins when it is not `.topLeft` |

## Constraint Parameters

| Parameter            | Type                 | Default       | Description                                         |
| -------------------- | -------------------- | ------------- | --------------------------------------------------- |
| `coordinateExtent`   | `CoordinateExtent`   | `.infinite`   | Boundary constraints for node dragging              |
| `fitView`            | `Bool`               | `false`       | Fit once when the canvas has a size and all visible nodes are measured (no fixed delay) |
| `fitViewOptions`     | `FitViewOptions?`    | `nil`         | Configuration for fit-view behavior; `padding`, `nodeIds`, and `includeHiddenNodes` are honored when auto-fitting on load |
| `defaultEdgeOptions` | `DefaultEdgeOptions?`| `nil`         | Defaults applied when rendering edges: a default fills a property only while the edge still has its initializer default (`type == .default`, `animated == false`, `markerStart`/`markerEnd == nil`) |
| `keyboardShortcuts`  | `KeyboardShortcuts`  | `.default`    | Keyboard shortcut key codes and nudge distances     |
| `accessibilityConfig`| `AccessibilityConfig`| `.default`    | Localized labels, hints, and VoiceOver announcements for nodes, edges, handles, Controls and the MiniMap |

## Convenience Initializer (No Overlay)

When you don't need overlay components, use the simplified initializer:

```swift
SwiftFlow(
    nodes: nodes, edges: edges,
    onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
    onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
    onConnect: { edges = addEdge($0, edges: edges) }
) { node in
    MyNodeView(node: node)
}
```

## Interaction Mode Details

### PanOnDrag

When `true` (default), dragging on empty canvas space pans the viewport. Hold **Shift** to draw a selection box instead.

When `selectionOnDrag` is `true`, the roles reverse: dragging creates a selection box, and **Shift+drag** pans.

### Selection

Tapping a node selects it and deselects all other nodes and edges (the same for edges). Holding **Command** (macOS) toggles the tapped element for multi-selection. `onNodeClick`, `onEdgeClick` and `onPaneClick` fire even when selection is disabled. Edge double-click only calls `onEdgeDoubleClick`; it does not delete the edge.

### Node Appearance

The canvas applies `Node.style` (background, falling back to `theme.nodeBackgroundColor`; border color/width; `borderRadius`; `opacity`). Selected nodes get an outline using `theme.nodeSelectedBorderColor` / `nodeSelectedBorderWidth` (set `nodeSelectedBorderWidth = 0` if your node views draw their own selection). Child positions are relative to the parent's top-left.

### Edge Rendering

Edges are drawn from each `Handle`'s `position` (node side), so top/bottom handles route correctly and markers follow the path ends. An edge with a `nil` `sourceHandle`/`targetHandle` attaches to the first handle of that type on the node; if the node has no rendered handle, it attaches to the center of the side given by `Node.sourcePosition`/`targetPosition` (defaults right/left). `Edge.interactionWidth` sets the hit area width and `EdgeStyle.opacity` is applied.

### Reconnection

Pass `onReconnect` and mark edges `reconnectable`. Endpoint anchors appear on a selected reconnectable edge when `nodesConnectable` is on. On a valid drop `onReconnect(oldEdge, newConnection)` is called with the original edge; apply it with `edges = reconnectEdge(oldEdge, connection, edges)`. Dropping elsewhere leaves the edge unchanged, and `onConnect` is not used as a fallback.

### Zoom Constraints

Zoom is clamped between `Viewport.minZoom` (0.1) and `Viewport.maxZoom` (4.0).

### Node Extent (Per-Node)

Individual nodes can have extent constraints that override the global `coordinateExtent`:

```swift
// Constrain within parent bounds
Node(id: "child", ..., parentId: "group", extent: .parent)

// Constrain within explicit region
Node(id: "bounded", ...,
     extent: .coordinateExtent(CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)))
```

## Custom Edge Content

Override edge rendering with the `edgeContent` parameter:

```swift
SwiftFlow(
    nodes: nodes, edges: edges,
    edgeContent: { edge, pathResult in
        AnyView(
            pathResult.path.stroke(
                edge.selected ? .cyan : .gray,
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
        )
    }
) { node in ... }
```

The closure receives the `Edge<EdgeData>` and an `EdgePathResult` containing the computed path, label position, and endpoint coordinates.

## Custom Connection Line

Override the in-progress connection line during edge drawing:

```swift
SwiftFlow(
    nodes: nodes, edges: edges,
    connectionLineContent: { connection, start, current in
        AnyView(
            Path { path in
                path.move(to: start)
                path.addLine(to: current)
            }
            .stroke(.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        )
    }
) { node in ... }
```

## SwiftFlowInstance Integration

Pass a `SwiftFlowInstance` for programmatic viewport control:

```swift
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(
    nodes: nodes, edges: edges,
    swiftFlowInstance: instance, ...
) { node in ... }

// Control the viewport imperatively
Button("Fit View") {
    instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
}
```

## Z-Index Modes

| Mode      | Description                                                       |
| --------- | ----------------------------------------------------------------- |
| `.auto`   | Selected nodes come to front                                      |
| `.basic`  | Selected nodes come to front                                      |
| `.manual` | Only `zIndex` is used; selection does not raise nodes             |

Use `.manual` when you need complete control over render order via the `zIndex` property on each node and edge.
