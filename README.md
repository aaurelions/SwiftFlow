# SwiftFlow

<img align="center" src="https://github.com/aaurelions/SwiftFlow/raw/main/docs/public/screenshot.png" width="800"/>

A SwiftUI-native node-based graph editor inspired by [ReactFlow](https://reactflow.dev). Build interactive flow diagrams, workflow editors, mind maps, and visual programming interfaces on iOS and macOS.

## Features

- **Interactive Canvas** — Pan, zoom (scroll, pinch, double-click), and navigate with keyboard shortcuts
- **Node Dragging** — Drag nodes with optional snap-to-grid and coordinate extent constraints
- **Edge Drawing** — Connect nodes by dragging from handles; supports validation callbacks
- **Selection** — Click, shift-click, or drag a selection box with partial/full containment modes
- **Multiple Edge Types** — Bezier, straight, step, smooth step, and simple bezier paths
- **Customizable Nodes** — Bring your own SwiftUI views via `@ViewBuilder`
- **Overlay Components** — Background patterns, minimap, controls panel, toolbars, and more
- **Undo / Redo** — Built-in undo/redo support on macOS
- **Auto Layout** — Tree, force-directed, and grid layout algorithms
- **Serialization** — JSON import/export with `Codable` support <img align="right" src="https://github.com/aaurelions/SwiftFlow/raw/main/docs/public/mascot.png" alt="SwiftFlow SwiftUI Node Graph Editor" width="120" />
- **Accessibility** — VoiceOver labels and keyboard navigation
- **Theming** — Light, dark, and custom themes
- **Zero Dependencies** — Pure SwiftUI, no third-party packages

## Requirements

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 16.0+           |
| macOS    | 13.0+           |
| Swift    | 6.1+            |

## Installation

### Swift Package Manager

Add SwiftFlow to your project via Xcode:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select version rules and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aaurelions/SwiftFlow.git", from: "0.1.0")
]
```

Then add `"SwiftFlow"` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["SwiftFlow"])
```

---

## Documentation

Full documentation with guides, API reference, and examples is available on the
[SwiftFlow documentation site](https://aaurelions.github.io/SwiftFlow/).

| Section | Description |
| ------- | ----------- |
| [Getting Started](https://aaurelions.github.io/SwiftFlow/guide/getting-started.html) | Installation, requirements, and first graph |
| [SwiftFlow Canvas](https://aaurelions.github.io/SwiftFlow/api/swiftflow-canvas.html) | Main canvas: parameters, callbacks, interactions |
| [Models](https://aaurelions.github.io/SwiftFlow/api/models.html) | `Node`, `Edge`, `Connection`, and `Viewport` types |
| [Callbacks](https://aaurelions.github.io/SwiftFlow/api/callbacks.html) | All event callbacks and their signatures |
| [Handle](https://aaurelions.github.io/SwiftFlow/api/handle.html) | Connection handles inside node views |
| [Background](https://aaurelions.github.io/SwiftFlow/api/background.html) | Grid patterns (dots, lines, cross) |
| [Controls](https://aaurelions.github.io/SwiftFlow/api/controls.html) | Zoom, fit-view, and custom control buttons |
| [MiniMap](https://aaurelions.github.io/SwiftFlow/api/minimap.html) | Interactive overview minimap |
| [Panel & Overlays](https://aaurelions.github.io/SwiftFlow/api/panel-overlays.html) | Positional containers, toolbars, edge labels |
| [Change Utilities](https://aaurelions.github.io/SwiftFlow/api/change-utilities.html) | `applyNodeChanges`, `applyEdgeChanges`, `addEdge` |
| [Graph & Geometry](https://aaurelions.github.io/SwiftFlow/api/graph-utilities.html) | `getIncomers`, `getOutgoers`, bounding boxes, intersection tests |
| [Auto Layout](https://aaurelions.github.io/SwiftFlow/api/auto-layout.html) | Tree, force-directed, and grid layout algorithms |
| [Serialization](https://aaurelions.github.io/SwiftFlow/api/serialization.html) | JSON import/export with `Codable` support |
| [Types Reference](https://aaurelions.github.io/SwiftFlow/api/types-reference.html) | Complete reference of all public types and enums |

---

## Quick Start

```swift
import SwiftUI
import SwiftFlow

struct ContentView: View {
    @State var nodes: [Node<String>] = [
        Node(id: "1", position: XYPosition(x: 0, y: 0), data: "Input"),
        Node(id: "2", position: XYPosition(x: 250, y: 100), data: "Output"),
    ]
    @State var edges: [FlowEdge<EmptyEdgeData>] = [
        FlowEdge(id: "e1-2", source: "1", target: "2"),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) }
        ) { node in
            Text(node.data)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))
        } overlay: {
            Background(variant: .dots)
            Controls()
            MiniMap()
        }
    }
}
```

> **Tip:** Use `FlowEdge` (a type alias for `Edge`) to avoid ambiguity with
> `SwiftUI.Edge`:
> ```swift
> @State var edges: [FlowEdge<EmptyEdgeData>] = [
>     FlowEdge(id: "e1-2", source: "1", target: "2"),
> ]
> ```

---

## Architecture

### State Management

SwiftFlow uses a **change-based** state model. The canvas does not own your data — instead, it emits arrays of `NodeChange` or `EdgeChange` values through callbacks, and you apply them to your state:

```swift
// You own the state
@State var nodes: [Node<MyData>] = [...]
@State var edges: [Edge<EmptyEdgeData>] = [...]

// SwiftFlow emits changes, you apply them
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
) { node in ... }
```

For centralized state, use **`SwiftFlowStore`**:

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
) { node in ... }
```

For programmatic viewport control, use **`SwiftFlowInstance`**:

```swift
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(
    nodes: nodes, edges: edges,
    swiftFlowInstance: instance,
    ...
) { node in ... }

Button("Fit View") {
    instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
}
```

---

## Components

### SwiftFlow (Main Canvas)

The primary component. Renders nodes and edges, handles interactions.

```swift
SwiftFlow(
    nodes: nodes,
    edges: edges,
    onNodesChange: { ... },
    onEdgesChange: { ... },
    onConnect: { ... },

    // Interaction options
    nodesDraggable: true,
    nodesConnectable: true,
    elementsSelectable: true,
    panOnDrag: true,
    zoomOnScroll: true,
    zoomOnPinch: true,
    selectionOnDrag: false,
    connectionMode: .strict,

    // Appearance
    snapToGrid: false,
    snapGrid: (x: 20, y: 20),
    theme: .default,

    // Callbacks
    onNodeClick: { node in ... },
    onEdgeClick: { edge in ... },
    onViewportChange: { viewport in ... },
    isValidConnection: { connection in true }
) { node in
    // Your custom node view
} overlay: {
    // Overlay components
}
```

#### Interaction Properties

| Property             | Type              | Default    | Description                       |
| -------------------- | ----------------- | ---------- | --------------------------------- |
| `nodesDraggable`     | `Bool`            | `true`     | Enable node dragging              |
| `nodesConnectable`   | `Bool`            | `true`     | Enable connection drawing         |
| `elementsSelectable` | `Bool`            | `true`     | Enable selection                  |
| `panOnDrag`          | `Bool`            | `true`     | Pan canvas on drag                |
| `panOnScroll`        | `Bool`            | `false`    | Pan on scroll instead of zoom     |
| `panOnScrollMode`    | `PanOnScrollMode` | `.free`    | Scroll panning direction          |
| `zoomOnScroll`       | `Bool`            | `true`     | Zoom with scroll wheel            |
| `zoomOnPinch`        | `Bool`            | `true`     | Zoom with pinch gesture           |
| `zoomOnDoubleClick`  | `Bool`            | `true`     | Zoom on double-click              |
| `selectionOnDrag`    | `Bool`            | `false`    | Draw selection box on drag        |
| `selectNodesOnDrag`  | `Bool`            | `true`     | Select nodes when dragging        |
| `selectionMode`      | `SelectionMode`   | `.partial` | `.partial` or `.full` containment |
| `connectionMode`     | `ConnectionMode`  | `.strict`  | `.strict` or `.loose`             |
| `connectionLineType` | `EdgeType`        | `.default` | Style for in-progress connections |

#### Appearance Properties

| Property           | Type                       | Default     | Description            |
| ------------------ | -------------------------- | ----------- | ---------------------- |
| `snapToGrid`       | `Bool`                     | `false`     | Snap positions to grid |
| `snapGrid`         | `(x: CGFloat, y: CGFloat)` | `(20, 20)`  | Grid spacing           |
| `theme`            | `SwiftFlowTheme`           | `.default`  | Visual theme           |
| `colorMode`        | `ColorMode`                | `.system`   | Light/dark/system      |
| `zIndexMode`       | `ZIndexMode`               | `.auto`     | Z-ordering strategy    |
| `nodeOrigin`       | `NodeOrigin`               | `.topLeft`  | Node anchor point      |
| `fitView`          | `Bool`                     | `false`     | Auto-fit on load       |
| `coordinateExtent` | `CoordinateExtent`         | `.infinite` | Panning boundaries     |

#### Event Callbacks

| Callback               | Parameters             | Description                                |
| ---------------------- | ---------------------- | ------------------------------------------ |
| `onNodesChange`        | `[NodeChange<T>]`      | Node mutations                             |
| `onEdgesChange`        | `[EdgeChange<E>]`      | Edge mutations                             |
| `onConnect`            | `Connection`           | New connection made                        |
| `onNodeClick`          | `Node<T>`              | Node tapped                                |
| `onNodeDoubleClick`    | `Node<T>`              | Node double-tapped                         |
| `onEdgeClick`          | `Edge<E>`              | Edge tapped                                |
| `onEdgeDoubleClick`    | `Edge<E>`              | Edge double-tapped                         |
| `onPaneClick`          | —                      | Background tapped                          |
| `onViewportChange`     | `Viewport`             | Camera changed                             |
| `onSelectionChange`    | `[Node<T>], [Edge<E>]` | Selection changed                          |
| `onNodeDragStart`      | `Node<T>`              | Drag began                                 |
| `onNodeDrag`           | `Node<T>`              | Drag in progress                           |
| `onNodeDragStop`       | `Node<T>`              | Drag ended                                 |
| `onConnectStart`       | `OnConnectStartParams` | Connection drawing began                   |
| `onConnectEnd`         | —                      | Connection drawing ended                   |
| `onBeforeDelete`       | `[Node<T>], [Edge<E>]` | Deletion validation (async)                |
| `onNodesDelete`        | `[Node<T>]`            | Nodes deleted                              |
| `onEdgesDelete`        | `[Edge<E>]`            | Edges deleted                              |
| `onDelete`             | `[Node<T>], [Edge<E>]` | Fires after deletion completes             |
| `onReconnect`          | `Edge<E>, Connection`  | Edge reconnected                           |
| `onMoveStart`          | `Viewport`             | Viewport move began                        |
| `onMove`               | `Viewport`             | Viewport moving                            |
| `onMoveEnd`            | `Viewport`             | Viewport move ended                        |
| `onNodeMouseEnter`     | `Node<T>`              | Mouse entered node (macOS)                 |
| `onNodeMouseLeave`     | `Node<T>`              | Mouse left node (macOS)                    |
| `onEdgeMouseEnter`     | `Edge<E>`              | Mouse entered edge (macOS)                 |
| `onEdgeMouseLeave`     | `Edge<E>`              | Mouse left edge (macOS)                    |
| `onNodeContextMenu`    | `Node<T>`              | Node context menu (right-click/long-press) |
| `onEdgeContextMenu`    | `Edge<E>`              | Edge context menu                          |
| `onPaneContextMenu`    | —                      | Pane context menu                          |
| `onSelectionDragStart` | `[Node<T>]`            | Multi-node drag began                      |
| `onSelectionDrag`      | `[Node<T>]`            | Multi-node drag in progress                |
| `onSelectionDragStop`  | `[Node<T>]`            | Multi-node drag ended                      |
| `onInit`               | —                      | Canvas initialized                         |
| `isValidConnection`    | `Connection` → `Bool`  | Validate new connections                   |

---

### Handle

Connection endpoints on nodes. Place inside your node view.

```swift
// Source handle on the right
Handle(nodeId: node.id, id: "output", type: .source, position: .right)

// Target handle on the left
Handle(nodeId: node.id, id: "input", type: .target, position: .left)
```

| Property        | Type         | Default     | Description                          |
| --------------- | ------------ | ----------- | ------------------------------------ |
| `nodeId`        | `String`     | —           | Parent node ID (required)            |
| `id`            | `String`     | —           | Handle identifier (required)         |
| `type`          | `HandleType` | `.source`   | `.source` or `.target`               |
| `position`      | `Position`   | —           | `.top`, `.bottom`, `.left`, `.right` |
| `color`         | `Color`      | `.gray`     | Handle fill color                    |
| `isConnectable` | `Bool`       | `true`      | Enable connections                   |

---

### Background

Canvas grid pattern. Supports dots, lines, and crosshairs.

```swift
// Dots (default)
Background(variant: .dots, color: .gray.opacity(0.3), gap: 20, size: 1.5)

// Grid lines
Background(variant: .lines, color: .gray.opacity(0.2), gap: 25)

// Cross pattern
Background(variant: .cross, gap: 30)

// Multiple backgrounds with ids
Background(id: "small-grid", variant: .dots, gap: 10, size: 0.5)
Background(id: "large-grid", variant: .lines, gap: 100)
```

| Property  | Type                | Default              | Description                                  |
| --------- | ------------------- | -------------------- | -------------------------------------------- |
| `id`      | `String?`           | `nil`                | Identifier for layering multiple backgrounds |
| `variant` | `BackgroundVariant` | `.dots`              | Pattern type                                 |
| `color`   | `Color`             | `.gray.opacity(0.3)` | Pattern color                                |
| `gap`     | `CGFloat`           | `20`                 | Spacing between elements                     |
| `size`    | `CGFloat`           | `1.5`                | Size of elements (dots/crosses)              |

---

### Controls

Zoom and fit-view buttons.

```swift
Controls(
    showZoom: true,
    showFitView: true,
    showInteractive: false,
    position: .bottomLeft
)

// With custom buttons
Controls(position: .bottomLeft) {
    ControlButton(systemImage: "arrow.clockwise") {
        // Custom action
    }
}
```

| Property          | Type            | Default       | Description             |
| ----------------- | --------------- | ------------- | ----------------------- |
| `showZoom`        | `Bool`          | `true`        | Show +/- buttons        |
| `showFitView`     | `Bool`          | `true`        | Show fit-view button    |
| `showInteractive` | `Bool`          | `false`       | Show interactive toggle |
| `position`        | `PanelPosition` | `.bottomLeft` | Panel position          |

---

### MiniMap

Interactive overview map showing all nodes and the current viewport.

```swift
// Default
MiniMap()

// With color mapping function (like ReactFlow)
MiniMap(nodeColorMapper: { props in
    props.type == "input" ? .green : .pink
})

// With custom node rendering
MiniMap { props in
    Circle()
        .fill(props.selected ? .blue : .gray)
}
```

| Property            | Type                          | Default              | Description           |
| ------------------- | ----------------------------- | -------------------- | --------------------- |
| `nodeColor`         | `Color`                       | `.gray.opacity(0.5)` | Default node color    |
| `nodeColorMapper`   | `(MiniMapNodeProps) -> Color` | `nil`                | Dynamic node color    |
| `selectedNodeColor` | `Color`                       | `.blue`              | Selected node color   |
| `nodeStrokeColor`   | `Color`                       | `.clear`             | Node border color     |
| `nodeStrokeWidth`   | `CGFloat`                     | `0`                  | Node border width     |
| `nodeBorderRadius`  | `CGFloat`                     | `1`                  | Node corner radius    |
| `width`             | `CGFloat`                     | `150`                | MiniMap width         |
| `height`            | `CGFloat`                     | `100`                | MiniMap height        |
| `pannable`          | `Bool`                        | `true`               | Click to pan viewport |
| `zoomable`          | `Bool`                        | `false`              | Scroll to zoom        |
| `position`          | `PanelPosition`               | `.bottomRight`       | Panel position        |
| `nodeContent`       | `(MiniMapNodeProps) -> View`  | `nil`                | Custom node view      |

---

### Panel

Positional container for custom overlay content.

```swift
Panel(position: .topRight) {
    Button("Reset") { instance.reset() }
}
```

| Position Values |                 |
| --------------- | --------------- | -------------- |
| `.topLeft`      | `.topCenter`    | `.topRight`    |
| `.centerLeft`   | `.center`       | `.centerRight` |
| `.bottomLeft`   | `.bottomCenter` | `.bottomRight` |

---

### NodeToolbar

Floating toolbar near a selected node.

```swift
if node.selected {
    NodeToolbar(position: .top) {
        Button("Delete") { ... }
        Button("Duplicate") { ... }
    }
}
```

---

### EdgeToolbar

Floating toolbar near a selected edge.

```swift
EdgeToolbar(isVisible: edge.selected, position: CGPoint(x: midX, y: midY)) {
    Button("Delete") { removeEdge(edge.id) }
}
```

---

### NodeResizer / NodeResizeControl

Resize handles for nodes.

```swift
// Full resizer with all handles
NodeResizer(
    nodeId: node.id,
    direction: .bottomRight,
    minWidth: 100, maxWidth: 500,
    minHeight: 50, maxHeight: 400,
    onResize: { width, height in
        onNodesChange?([.dimensions(id: node.id, width: width, height: height)])
    }
)

// Individual resize control (single handle)
NodeResizeControl(
    nodeId: node.id,
    position: .bottomRight,
    onResize: { width, height in
        onNodesChange?([.dimensions(id: node.id, width: width, height: height)])
    }
)
```

---

### BaseEdge

Low-level edge rendering primitive for custom edge types.

```swift
BaseEdge(
    path: myPath,
    color: .blue,
    width: 2,
    animated: true,
    label: "Label",
    labelPosition: CGPoint(x: midX, y: midY)
)
```

---

### ViewportPortal

Renders content in flow (canvas) coordinates.

```swift
ViewportPortal(viewport: viewport) {
    Text("Annotation")
        .position(x: 100, y: 200)
}
```

---

### EdgeLabelRenderer

Renders edge labels at a position, automatically counter-scaling for zoom.

```swift
EdgeLabelRenderer(position: midpoint) {
    Button("Delete") { deleteEdge() }
        .buttonStyle(.bordered)
}
```

---

## Models

### Node

```swift
public struct Node<NodeData: Equatable & Sendable>: Identifiable {
    var id: String
    var position: XYPosition
    var data: NodeData
    var type: String                    // default: "default"
    var parentId: String?
    var selected: Bool                  // default: false
    var hidden: Bool                    // default: false
    var width: CGFloat?
    var height: CGFloat?
    var draggable: Bool                 // default: true
    var selectable: Bool                // default: true
    var connectable: Bool               // default: true
    var deletable: Bool                 // default: true
    var focusable: Bool                 // default: true
    var expandable: Bool                // default: false
    var expanded: Bool                  // default: true
    var expandParent: Bool              // default: false
    var zIndex: Int                     // default: 0
    var origin: NodeOrigin              // default: .topLeft
    var sourcePosition: Position?
    var targetPosition: Position?
    var extent: NodeExtent?             // .parent or .coordinateExtent(...)
    var style: NodeStyle?
}
```

### Edge

```swift
public struct Edge<EdgeData: Equatable & Sendable & Hashable>: Identifiable {
    var id: String
    var source: String
    var target: String
    var sourceHandle: String?
    var targetHandle: String?
    var type: EdgeType                  // default: .default
    var selected: Bool                  // default: false
    var hidden: Bool                    // default: false
    var label: String?
    var animated: Bool                  // default: false
    var markerStart: EdgeMarker?
    var markerEnd: EdgeMarker?
    var zIndex: Int                     // default: 0
    var reconnectable: Bool             // default: false
    var deletable: Bool                 // default: true
    var focusable: Bool                 // default: true
    var interactionWidth: CGFloat       // default: 20
    var data: EdgeData?
    var style: EdgeStyle?
}
```

Use `EmptyEdgeData` when you don't need custom data on edges:

```swift
@State var edges: [Edge<EmptyEdgeData>] = [
    Edge(id: "e1", source: "1", target: "2")
]
```

### Connection

```swift
public struct Connection: Equatable, Sendable {
    var source: String
    var target: String
    var sourceHandle: String?
    var targetHandle: String?
}
```

### Viewport

```swift
public struct Viewport: Equatable, Sendable {
    var x: CGFloat      // horizontal pan offset
    var y: CGFloat      // vertical pan offset
    var zoom: CGFloat   // zoom level (0.1 ... 4.0)

    static let identity // x: 0, y: 0, zoom: 1.0
}
```

### EdgeType

| Value                  | Description                                |
| ---------------------- | ------------------------------------------ |
| `.default` / `.bezier` | Smooth cubic bezier curve                  |
| `.straight`            | Direct line                                |
| `.step`                | Right-angle path with sharp corners        |
| `.smoothstep`          | Right-angle path with rounded corners      |
| `.simplebezier`        | Quadratic bezier with single control point |

### NodeChange / EdgeChange

```swift
enum NodeChange<T> {
    case position(id: String, position: XYPosition)
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(item: Node<T>)
    case dimensions(id: String, width: CGFloat, height: CGFloat)
    case replace(id: String, item: Node<T>)
}

enum EdgeChange<E> {
    case selection(id: String, selected: Bool)
    case remove(id: String)
    case add(item: Edge<E>)
    case replace(id: String, item: Edge<E>)
}
```

---

## Utility Functions

### State Update Functions

```swift
// Apply node changes to a node array
let newNodes = applyNodeChanges(changes, nodes: nodes)

// Apply edge changes to an edge array
let newEdges = applyEdgeChanges(changes, edges: edges)

// Create an edge from a connection (prevents duplicates)
let newEdges = addEdge(connection, edges: edges, defaults: DefaultEdgeOptions(...))

// Reconnect an existing edge
let newEdges = reconnectEdge(oldEdge, newConnection, edges)
```

### Graph Query Functions

```swift
// Get nodes with edges pointing to a node (predecessors)
let predecessors = getIncomers(node: myNode, nodes: nodes, edges: edges)

// Get nodes a node points to (successors)
let successors = getOutgoers(node: myNode, nodes: nodes, edges: edges)

// Get all edges connected to a node
let connected = getConnectedEdges(node: myNode, edges: edges)

// Get all edges connected to any of the given nodes
let connected = getConnectedEdges(nodes: selectedNodes, edges: edges)

// Get intersecting nodes
let overlapping = getIntersectingNodes(node: myNode, nodes: nodes)

// Check if two nodes overlap
let overlaps = isNodeIntersecting(node: nodeA, otherNode: nodeB)
```

### Edge Path Functions

All path functions come in two variants: a simple version and a position-aware version that accounts for handle placement.

```swift
// Simple (source/target coordinates only)
let path = getBezierPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)

// Position-aware (includes handle positions, returns label position)
let (path, labelX, labelY, offsetX, offsetY) = getBezierPath(
    sourceX: 0, sourceY: 0, sourcePosition: .right,
    targetX: 200, targetY: 100, targetPosition: .left
)

// Generic dispatcher
let path = getEdgePath(type: .smoothstep, sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)

// Full result with label positioning
let result = getEdgePathResult(type: .bezier, sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
// result.path, result.labelX, result.labelY
```

| Function                | Description                     |
| ----------------------- | ------------------------------- |
| `getBezierPath()`       | Cubic bezier curve              |
| `getSimpleBezierPath()` | Quadratic bezier curve          |
| `getStraightPath()`     | Straight line                   |
| `getStepPath()`         | Right-angle steps (sharp)       |
| `getSmoothStepPath()`   | Right-angle steps (rounded)     |
| `getEdgePath()`         | Dispatcher by `EdgeType`        |
| `getEdgePathResult()`   | Full result with label position |
| `getEdgeMidpoint()`     | Label position for edge         |
| `getEdgeAngleAtEnd()`   | Marker rotation at target       |
| `getEdgeAngleAtStart()` | Marker rotation at source       |

### Geometry Functions

```swift
// Bounding box of visible nodes
let bounds = getNodesBounds(nodes: nodes, nodeSizes: sizes)

// Viewport to display bounds
let viewport = getViewportForBounds(bounds: rect, viewportSize: size)

// Type checks
if isNode(element, ofType: MyData.self) { ... }
if isEdge(element, ofType: MyEdgeData.self) { ... }
```

### Auto Layout

```swift
// Tree layout (hierarchical)
let changes = computeAutoLayout(
    nodes: nodes, edges: edges,
    algorithm: .tree(direction: .topToBottom, nodeSpacing: 50, levelSpacing: 150)
)
nodes = applyNodeChanges(changes, nodes: nodes)

// Force-directed layout
let changes = computeAutoLayout(
    nodes: nodes, edges: edges,
    algorithm: .forceDirected(iterations: 100, idealLength: 200, repulsion: 5000)
)

// Grid layout
let changes = computeAutoLayout(
    nodes: nodes, edges: edges,
    algorithm: .grid(columns: 3, nodeSpacing: 50)
)

// Async version for large graphs (50+ nodes)
let changes = await computeAutoLayoutAsync(
    nodes: nodes, edges: edges,
    algorithm: .forceDirected()
)
```

### Serialization

```swift
// Export to JSON
let jsonData = try toJSON(nodes: nodes, edges: edges, viewport: viewport)
let jsonString = try toJSONString(nodes: nodes, edges: edges)

// Import from JSON
let doc: SwiftFlowDocument<MyData, MyEdgeData> = try fromJSON(data)
let doc: SwiftFlowDocument<MyData, MyEdgeData> = try fromJSONString(string)
// doc.nodes, doc.edges, doc.viewport
```

> **Note:** Serialization requires `NodeData` and `EdgeData` to conform to `Codable`.

---

## SwiftFlowStore

Centralized state management class. Use it for simpler state handling.

```swift
@StateObject var store = SwiftFlowStore<MyData, EmptyEdgeData>(
    nodes: [...], edges: [...]
)
```

| Method / Property                        | Description                          |
| ---------------------------------------- | ------------------------------------ |
| `nodes`                                  | Published node array                 |
| `edges`                                  | Published edge array                 |
| `viewport`                               | Published viewport                   |
| `selectedNodeIds`                        | Currently selected node IDs          |
| `selectedEdgeIds`                        | Currently selected edge IDs          |
| `onNodesChange(_:)`                      | Apply node changes                   |
| `onEdgesChange(_:)`                      | Apply edge changes                   |
| `onConnect(_:)`                          | Create edge from connection          |
| `getNode(id:)`                           | Look up node by ID                   |
| `getEdge(id:)`                           | Look up edge by ID                   |
| `deleteElements(nodeIds:edgeIds:)`       | Delete elements by ID                |
| `getNodesData(ids:)`                     | Get data for specific node IDs       |
| `getNodeConnections(nodeId:handleType:)` | Get connections for a node           |
| `nodesInitialized`                       | Whether all nodes have been measured |

---

## SwiftFlowInstance

Programmatic viewport and graph control.

```swift
@StateObject var instance = SwiftFlowInstance()
```

| Method                              | Description                       |
| ----------------------------------- | --------------------------------- |
| `getViewport()`                     | Current viewport                  |
| `setViewport(_:animated:)`          | Set viewport directly             |
| `fitView(nodes:nodeSizes:options:)` | Fit nodes in view                 |
| `setCenter(x:y:zoom:animated:)`     | Center on coordinates             |
| `zoomTo(_:animated:)`               | Set zoom level                    |
| `zoomIn(animated:)`                 | Zoom in 25%                       |
| `zoomOut(animated:)`                | Zoom out 25%                      |
| `reset(animated:)`                  | Reset to origin at 100% zoom      |
| `screenToFlowPosition(_:)`          | Convert screen → flow coordinates |
| `flowToScreenPosition(_:)`          | Convert flow → screen coordinates |
| `getNodesBounds(nodes:nodeSizes:)`  | Bounding box of nodes             |
| `getViewportForBounds(bounds:...)`  | Viewport to display bounds        |
| `deleteElements(nodeIds:edgeIds:)`  | Delete elements programmatically  |

---

## Theming

```swift
// Use a preset
SwiftFlow(..., theme: .dark) { ... }

// Customize
var theme = SwiftFlowTheme.default
theme.edgeColor = .blue
theme.nodeBackgroundColor = .white
theme.handleColor = .orange
theme.selectionBoxColor = .blue.opacity(0.1)
SwiftFlow(..., theme: theme) { ... }
```

Key theme properties:

| Property                                              | Description         |
| ----------------------------------------------------- | ------------------- |
| `edgeColor` / `edgeSelectedColor`                     | Edge colors         |
| `edgeWidth` / `edgeSelectedWidth`                     | Edge widths         |
| `nodeBackgroundColor`                                 | Node background     |
| `nodeSelectedBorderColor` / `nodeSelectedBorderWidth` | Selection indicator |
| `handleColor` / `handleBorderColor` / `handleSize`    | Handle styling      |
| `selectionBoxColor` / `selectionBoxBorderColor`       | Selection box       |
| `canvasBackgroundColor`                               | Canvas background   |
| `snapLineColor` / `snapLineWidth`                     | Snap guides         |
| `edgeLabelFont` / `edgeLabelColor`                    | Edge labels         |

Presets: `.default`, `.light`, `.dark`

---

## Types Reference

| Type                      | Description                                             |
| ------------------------- | ------------------------------------------------------- |
| `Node<NodeData>`          | Graph node with generic data                            |
| `Edge<EdgeData>`          | Graph edge with generic data                            |
| `FlowEdge`                | Type alias for `Edge` (avoids `SwiftUI.Edge` ambiguity) |
| `EmptyEdgeData`           | Empty data type for edges without custom data           |
| `Connection`              | Pending connection between handles                      |
| `Viewport`                | Camera state (pan + zoom)                               |
| `XYPosition`              | 2D coordinate                                           |
| `Position`                | Handle position: `.top`, `.bottom`, `.left`, `.right`   |
| `PanelPosition`           | 9-position enum for overlay placement                   |
| `HandleType`              | `.source` or `.target`                                  |
| `EdgeType`                | Path style enum                                         |
| `EdgeMarker`              | Endpoint marker config                                  |
| `MarkerType`              | `.arrow` or `.arrowClosed`                              |
| `NodeChange<T>`           | Node mutation descriptor                                |
| `EdgeChange<E>`           | Edge mutation descriptor                                |
| `SelectionMode`           | `.partial` or `.full`                                   |
| `ConnectionMode`          | `.strict` or `.loose`                                   |
| `BackgroundVariant`       | `.dots`, `.lines`, `.cross`                             |
| `ColorMode`               | `.light`, `.dark`, `.system`                            |
| `ZIndexMode`              | `.auto`, `.basic`, `.manual`                            |
| `PanOnScrollMode`         | `.free`, `.vertical`, `.horizontal`                     |
| `FitViewOptions`          | Fit configuration                                       |
| `NodeOrigin`              | Node anchor point (0–1 normalized)                      |
| `NodeExtent`              | `.parent` or `.coordinateExtent(...)` extent constraint |
| `CoordinateExtent`        | Boundary constraints                                    |
| `ConnectionState`         | In-progress connection drag state                       |
| `Rect`                    | Type alias for `CGRect`                                 |
| `KeyCode`                 | Platform-agnostic key code constants                    |
| `KeyboardShortcuts`       | Keyboard shortcut configuration                         |
| `DefaultEdgeOptions`      | Default properties for new edges                        |
| `EdgePathResult`          | Path + label position result                            |
| `NodeStyle`               | Optional node visual overrides                          |
| `EdgeStyle`               | Optional edge visual overrides                          |
| `SwiftFlowTheme`          | Comprehensive theme configuration                       |
| `AccessibilityConfig`     | VoiceOver configuration                                 |
| `InternalNode<T>`         | Extended node with computed layout                      |
| `MiniMapNodeProps`        | Properties for custom MiniMap nodes                     |
| `BeforeDeleteResult`      | `.cancel` or `.delete(nodes, edges)`                    |
| `OnConnectStartParams`    | Connection start event data                             |
| `ResizeDirection`         | 8-direction resize handle placement                     |
| `LayoutAlgorithm`         | `.tree`, `.forceDirected`, `.grid`                      |
| `LayoutDirection`         | `.topToBottom`, `.leftToRight`, etc.                    |
| `SwiftFlowDocument<N, E>` | Serializable graph snapshot                             |
| `IsValidConnection`       | `(Connection) -> Bool` type alias                       |

---

## Custom Edge Content

Render custom edge views using the `edgeContent` parameter:

```swift
SwiftFlow(
    nodes: nodes, edges: edges,
    edgeContent: { edge, pathResult in
        AnyView(
            pathResult.path.stroke(
                edge.selected ? .blue : .green,
                style: StrokeStyle(lineWidth: 3, dash: [5, 3])
            )
        )
    }
) { node in ... }
```

The closure receives the `Edge` and an `EdgePathResult` (containing the path, label position, and endpoints). Return `AnyView` wrapping your custom rendering. Hit-testing, markers, labels, and interaction modifiers are still applied automatically.

---

## Active Connection State

Access the in-progress connection state via `SwiftFlowState.activeConnection`:

```swift
@EnvironmentObject var flowState: SwiftFlowState

if let conn = flowState.activeConnection {
    // conn.from, conn.to — start/end positions
    // conn.fromNode, conn.toNode — source/target nodes
    // conn.isValid — nil (unknown), true, or false
}
```

`activeConnection` is `nil` when no connection drag is in progress.

---

## Node Extent

Constrain node dragging with the `extent` property:

```swift
// Constrain within parent bounds
Node(id: "child", position: .zero, data: ..., parentId: "group", extent: .parent)

// Constrain within explicit coordinates
Node(id: "bounded", position: .zero, data: ...,
     extent: .coordinateExtent(CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)))
```

When `extent` is `.parent`, the node cannot be dragged outside its parent node's bounds.

---

## Platform-Specific Behavior

| Feature                                 | macOS                         | iOS           |
| --------------------------------------- | ----------------------------- | ------------- |
| Hover events (`onNodeMouseEnter`, etc.) | Supported via `onHover`       | Not available |
| Context menu trigger                    | Right-click (secondary click) | Long press    |
| Keyboard shortcuts                      | Full support                  | Limited       |

---

## ReactFlow Compatibility

SwiftFlow adapts familiar ReactFlow concepts to SwiftUI-native APIs. Release 0.1.0 focuses on the core canvas, nodes, edges, handles, overlays, callbacks, graph utilities, serialization, theming, and auto layout; some ReactFlow-specific browser APIs are intentionally different or not applicable on Apple platforms.

### Key Differences

| ReactFlow                                | SwiftFlow                            | Why                              |
| ---------------------------------------- | ------------------------------------ | -------------------------------- |
| React hooks (`useReactFlow`, `useNodes`) | `SwiftFlowStore` + `@Published`      | SwiftUI reactivity model         |
| `className` / `style` props              | SwiftUI view modifiers               | Different styling system         |
| Zustand store                            | `@StateObject` / `ObservableObject`  | SwiftUI state management         |
| ARIA attributes                          | `AccessibilityConfig`                | Native VoiceOver API             |
| Browser keyboard events                  | macOS `NSEvent` / iOS `UIKeyCommand` | Platform keyboard handling       |
| `useNodeId()` hook                       | Node passed directly to ViewBuilder  | No context needed                |
| `useUpdateNodeInternals()`               | Not needed                           | SwiftUI re-renders automatically |

### Feature Parity

| Category               | SwiftFlow 0.1.0 Status |
| ---------------------- | ---------------------- |
| Components             | Core canvas, handles, controls, minimap, backgrounds, panels, toolbars, resize controls, and edge label helpers |
| State Patterns         | Change callbacks, `SwiftFlowStore`, `SwiftFlowProvider`, and `SwiftFlowInstance` |
| Types & Models         | Generic `Node`, `FlowEdge`/`Edge`, `Connection`, `Viewport`, style, accessibility, keyboard, and selection types |
| Utility Functions      | Change helpers, graph queries, geometry/intersection helpers, edge paths, auto layout, and serialization |
| Event Callbacks        | Node, edge, selection, connection, viewport, deletion, hover, and context-menu callbacks |

---

## License

See [LICENSE](LICENSE) for details.
