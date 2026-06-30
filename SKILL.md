---
name: SwiftFlow
description: Comprehensive documentation and mapping between ReactFlow (TypeScript) and SwiftFlow (SwiftUI). Use this skill to translate ReactFlow concepts to SwiftFlow or to build native node-based graph editors in iOS and macOS using familiar ReactFlow patterns.
license: MIT
compatibility: iOS 16.0+, macOS 13.0+, Swift 6.1+
metadata:
  author: A.Aurelions
  version: "0.1.1"
---

# SwiftFlow Documentation

SwiftFlow is a native SwiftUI node-based graph editor whose architecture and API surface are inspired by [React Flow](https://reactflow.dev). This document provides a complete API reference, ReactFlow mapping tables, and practical usage examples.

Requirements: iOS 16.0+, macOS 13.0+, Swift 6.1+. Zero external dependencies.

---

## Quick Start (AI-Agent Flow)

```swift
import SwiftUI
import SwiftFlow

// 1. Define state
@State var nodes: [Node<String>] = [
    Node(id: "1", position: XYPosition(x: 0, y: 0), data: "Input"),
    Node(id: "2", position: XYPosition(x: 250, y: 100), data: "Output"),
]
@State var edges: [FlowEdge<EmptyEdgeData>] = [
    FlowEdge(id: "e1-2", source: "1", target: "2"),
]

// 2. Render canvas
SwiftFlow(
    nodes: nodes,
    edges: edges,
    onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
    onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
    onConnect: { edges = addEdge($0, edges: edges) }
) { node in
    Text(node.data).padding().background(.white).cornerRadius(8)
} overlay: {
    Background(variant: .dots)
    Controls()
    MiniMap()
}
```

Key imports: `SwiftFlow` (canvas), `XYPosition` (coordinates), `FlowEdge` (alias for `Edge` to avoid SwiftUI.Edge ambiguity). Use `EmptyEdgeData` when edges don't need custom data.

---

## SwiftFlow Canvas — Full Parameter Reference

All parameters with defaults (from actual `init`):

### Core Data
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nodes` | `[Node<NodeData>]` | — | Graph nodes |
| `edges` | `[Edge<EdgeData>]` | — | Graph edges |
| `onNodesChange` | `(([NodeChange<NodeData>]) -> Void)?` | `nil` | Node mutation callback |
| `onEdgesChange` | `(([EdgeChange<EdgeData>]) -> Void)?` | `nil` | Edge mutation callback |
| `onConnect` | `((Connection) -> Void)?` | `nil` | Connection created callback |

### Interaction
| Parameter | Type | Default |
|-----------|------|---------|
| `nodesDraggable` | `Bool` | `true` |
| `nodesConnectable` | `Bool` | `true` |
| `elementsSelectable` | `Bool` | `true` |
| `panOnDrag` | `Bool` | `true` |
| `panOnScroll` | `Bool` | `false` |
| `panOnScrollMode` | `PanOnScrollMode` | `.free` |
| `zoomOnScroll` | `Bool` | `true` |
| `zoomOnPinch` | `Bool` | `true` |
| `zoomOnDoubleClick` | `Bool` | `true` |
| `selectionOnDrag` | `Bool` | `false` |
| `selectNodesOnDrag` | `Bool` | `true` |
| `selectionMode` | `SelectionMode` | `.partial` |
| `connectionMode` | `ConnectionMode` | `.strict` |
| `connectionLineType` | `EdgeType` | `.default` |

### Appearance & Constraints
| Parameter | Type | Default |
|-----------|------|---------|
| `snapToGrid` | `Bool` | `false` |
| `snapGrid` | `(x: CGFloat, y: CGFloat)` | `(20, 20)` |
| `theme` | `SwiftFlowTheme` | `.default` |
| `colorMode` | `ColorMode` | `.system` |
| `zIndexMode` | `ZIndexMode` | `.auto` |
| `nodeOrigin` | `NodeOrigin` | `.topLeft` |
| `coordinateExtent` | `CoordinateExtent` | `.infinite` |
| `fitView` | `Bool` | `false` |
| `fitViewOptions` | `FitViewOptions?` | `nil` |
| `defaultEdgeOptions` | `DefaultEdgeOptions?` | `nil` |
| `keyboardShortcuts` | `KeyboardShortcuts` | `.default` |
| `accessibilityConfig` | `AccessibilityConfig` | `.default` |

### Event Callbacks (complete list)
| Callback | Signature | Trigger |
|----------|-----------|---------|
| `onPaneClick` | `() -> Void` | Canvas background tap |
| `onViewportChange` | `(Viewport) -> Void` | Camera moved |
| `onSelectionChange` | `([Node<T>], [Edge<E>]) -> Void` | Selection changed |
| `isValidConnection` | `(Connection) -> Bool` | Before accepting connection |
| `onNodeDragStart` | `(Node<T>) -> Void` | Node drag began |
| `onNodeDrag` | `(Node<T>) -> Void` | Node dragging |
| `onNodeDragStop` | `(Node<T>) -> Void` | Node drag ended |
| `onNodeClick` | `(Node<T>) -> Void` | Node tapped |
| `onNodeDoubleClick` | `(Node<T>) -> Void` | Node double-tapped |
| `onEdgeClick` | `(Edge<E>) -> Void` | Edge tapped |
| `onEdgeDoubleClick` | `(Edge<E>) -> Void` | Edge double-tapped |
| `onConnectStart` | `(OnConnectStartParams) -> Void` | Connection drag began |
| `onConnectEnd` | `() -> Void` | Connection drag ended |
| `onBeforeDelete` | `([Node<T>], [Edge<E>]) async -> BeforeDeleteResult?` | Pre-deletion validation |
| `onNodesDelete` | `([Node<T>]) -> Void` | Nodes deleted |
| `onEdgesDelete` | `([Edge<E>]) -> Void` | Edges deleted |
| `onDelete` | `([Node<T>], [Edge<E>]) -> Void` | After deletion completes |
| `onReconnect` | `(Edge<E>, Connection) -> Void` | Edge reconnected |
| `onMoveStart` | `(Viewport) -> Void` | Viewport move began |
| `onMove` | `(Viewport) -> Void` | Viewport moving |
| `onMoveEnd` | `(Viewport) -> Void` | Viewport move ended |
| `onInit` | `() -> Void` | Canvas initialized |
| `onNodeMouseEnter` | `(Node<T>) -> Void` | Mouse entered node (macOS) |
| `onNodeMouseLeave` | `(Node<T>) -> Void` | Mouse left node (macOS) |
| `onEdgeMouseEnter` | `(Edge<E>) -> Void` | Mouse entered edge (macOS) |
| `onEdgeMouseLeave` | `(Edge<E>) -> Void` | Mouse left edge (macOS) |
| `onNodeContextMenu` | `(Node<T>) -> Void` | Node secondary action |
| `onEdgeContextMenu` | `(Edge<E>) -> Void` | Edge secondary action |
| `onPaneContextMenu` | `() -> Void` | Pane secondary action |
| `onSelectionDragStart` | `([Node<T>]) -> Void` | Multi-node drag began |
| `onSelectionDrag` | `([Node<T>]) -> Void` | Multi-node dragging |
| `onSelectionDragStop` | `([Node<T>]) -> Void` | Multi-node drag ended |
| `connectionLineContent` | `(Connection, CGPoint, CGPoint) -> AnyView` | Custom drafting edge |
| `edgeContent` | `(Edge<E>, EdgePathResult) -> AnyView` | Custom edge rendering |

---

## Components Reference

### Handle
```swift
Handle(nodeId: String, id: String, type: HandleType = .source, position: Position,
       color: Color = .gray, isConnectable: Bool = true)
```
Place inside node views. `id` and `position` are required. `type`: `.source` or `.target`. `position`: `.top`, `.bottom`, `.left`, `.right`.

### Background
```swift
Background(id: String? = nil, variant: BackgroundVariant = .dots,
           color: Color = .gray.opacity(0.3), gap: CGFloat = 20, size: CGFloat = 1.5)
```
Variants: `.dots`, `.lines`, `.cross`. Place in `overlay` ViewBuilder.

### Controls
```swift
Controls(showZoom: Bool = true, showFitView: Bool = true, showInteractive: Bool = false,
         position: PanelPosition = .bottomLeft)
```
Place in `overlay`. Add custom buttons via trailing ViewBuilder.

### ControlButton
```swift
ControlButton(action: () -> Void) { content }  // Single control button
```

### MiniMap
```swift
MiniMap(nodeColor: = .gray.opacity(0.5), nodeColorMapper: ((MiniMapNodeProps) -> Color)? = nil,
        selectedNodeColor: = .blue, width: CGFloat = 150, height: CGFloat = 100,
        pannable: Bool = true, zoomable: Bool = false, position: PanelPosition = .bottomRight)
```
Supports `nodeColorMapper` for dynamic coloring, or a custom `nodeContent` ViewBuilder for per-node rendering.

### Panel
```swift
Panel(position: PanelPosition = .topRight) { content }
```
9 positions: `.topLeft`, `.topCenter`, `.topRight`, `.centerLeft`, `.center`, `.centerRight`, `.bottomLeft`, `.bottomCenter`, `.bottomRight`.

### NodeToolbar
```swift
NodeToolbar(nodeId: String? = nil, isVisible: Bool = true, position: ToolbarPosition = .top,
            align: ToolbarAlign = .center, offset: CGFloat = 8) { content }
```
`ToolbarPosition`: `.top`, `.bottom`, `.left`, `.right`. `ToolbarAlign`: `.start`, `.center`, `.end`.

### EdgeToolbar
```swift
EdgeToolbar(edgeId: String? = nil, isVisible: Bool = true, position: CGPoint = .zero,
            offset: CGFloat = 24) { content }
```

### NodeResizer
```swift
NodeResizer(nodeId: String, direction: ResizeDirection = .bottomRight,
            minWidth: CGFloat = 50, maxWidth: CGFloat = 1000,
            minHeight: CGFloat = 30, maxHeight: CGFloat = 1000,
            color: Color = .blue,
            onResize: ((CGFloat, CGFloat) -> Void)? = nil,
            onResizeStart: (() -> Void)? = nil, onResizeEnd: (() -> Void)? = nil,
            shouldResize: ((CGFloat, CGFloat) -> Bool)? = nil)
```
Single resize handle. 8 directions via `ResizeDirection`.

### NodeResizeControl
```swift
NodeResizeControl(nodeId: String, position: ResizeDirection = .bottomRight,
                  minWidth: = 50, maxWidth: = 1000, minHeight: = 30, maxHeight: = 1000,
                  color: = .blue, handleSize: CGFloat = 10, isVisible: Bool = true,
                  onResize: ((CGFloat, CGFloat) -> Void)? = nil,
                  onResizeStart: (() -> Void)? = nil, onResizeEnd: (() -> Void)? = nil,
                  shouldResize: ((CGFloat, CGFloat) -> Bool)? = nil)
```
Individual resize handle. Use multiple for custom configurations.

### ViewportPortal
```swift
ViewportPortal(viewport: Viewport) { content }
```
Renders content in canvas flow coordinates.

### EdgeLabelRenderer
```swift
EdgeLabelRenderer(position: CGPoint) { content }
```
Auto-scales to counteract viewport zoom.

### EdgeText
```swift
EdgeText(x: CGFloat, y: CGFloat, label: String,
         font: Font = .system(size: 11), foregroundColor: = .primary,
         showBackground: Bool = true, backgroundColor: = .white,
         backgroundPadding: EdgeInsets = .init(top: 2, leading: 6, bottom: 2, trailing: 6),
         backgroundCornerRadius: CGFloat = 4)
```

### BaseEdge
```swift
BaseEdge(path: Path, color: Color = .gray.opacity(0.6), width: CGFloat = 2,
         animated: Bool = false, dashPhase: CGFloat = 0,
         label: String? = nil, labelPosition: CGPoint? = nil,
         labelFont: = .system(size: 11), labelColor: = .primary, labelBackground: = .white)
```
Also has `init(pathResult: EdgePathResult, ...)` convenience init.

---

## Core Models

### Node
```swift
Node<NodeData: Equatable & Sendable>
```
Properties: `id`, `position` (XYPosition), `data`, `type` (default: `"default"`), `parentId`, `selected`, `hidden`, `width`, `height`, `draggable`, `selectable`, `connectable`, `deletable`, `expandable` (default: `false`), `expanded` (default: `true`), `expandParent`, `focusable`, `zIndex`, `origin` (NodeOrigin, default: `.topLeft`), `sourcePosition`, `targetPosition`, `extent` (NodeExtent?), `style` (NodeStyle?).

### Edge / FlowEdge
```swift
Edge<EdgeData: Equatable & Sendable & Hashable>
// FlowEdge = Edge (typealias; avoids SwiftUI.Edge ambiguity)
```
Properties: `id`, `source`, `target`, `sourceHandle`, `targetHandle`, `type` (EdgeType, default: `.default`), `selected`, `hidden`, `label`, `animated`, `markerStart`, `markerEnd`, `zIndex`, `reconnectable`, `deletable`, `focusable`, `interactionWidth` (default: `20`), `data` (EdgeData?), `style` (EdgeStyle?).

Use `EmptyEdgeData` when custom data isn't needed.

### Connection
```swift
Connection(source: String, target: String, sourceHandle: String? = nil, targetHandle: String? = nil)
```

### Viewport
```swift
Viewport(x: CGFloat = 0, y: CGFloat = 0, zoom: CGFloat = 1)
```
`Viewport.identity` = `Viewport(x: 0, y: 0, zoom: 1)`. Zoom range: `0.1...4.0`.

### XYPosition
```swift
XYPosition(x: CGFloat, y: CGFloat)  // .zero = XYPosition(x: 0, y: 0)
```
Supports `+`, `-` operators and `snapped(to: grid)`.

### EdgeType
`.default`, `.bezier` (alias), `.straight`, `.step`, `.smoothstep`, `.simplebezier`.

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

### Enums Reference
- **Position**: `.top`, `.bottom`, `.left`, `.right` (handle positions)
- **HandleType**: `.source`, `.target`
- **PanelPosition**: 9 values (`.topLeft`...`.bottomRight`)
- **SelectionMode**: `.partial`, `.full`
- **ConnectionMode**: `.strict`, `.loose`
- **BackgroundVariant**: `.dots`, `.lines`, `.cross`
- **ColorMode**: `.light`, `.dark`, `.system`
- **ZIndexMode**: `.auto`, `.basic`, `.manual`
- **PanOnScrollMode**: `.free`, `.vertical`, `.horizontal`
- **MarkerType**: `.arrow`, `.arrowClosed`
- **ResizeDirection**: 8 values (`.topLeft`...`.bottomRight`)
- **LayoutDirection**: `.topToBottom`, `.leftToRight`, `.bottomToTop`, `.rightToLeft`
- **LayoutAlgorithm**: `.tree(...)`, `.forceDirected(...)`, `.grid(...)`
- **NodeOrigin**: `.topLeft` `NodeOrigin(x:0,y:0)`, `.center` `NodeOrigin(x:0.5,y:0.5)`
- **NodeExtent**: `.parent`, `.coordinateExtent(CoordinateExtent)`
- **BeforeDeleteResult**: `.cancel`, `.delete(nodes, edges)`

---

## State Management

### Pattern 1: Direct @State (canonical)
```swift
@State var nodes: [Node<MyData>] = [...]
@State var edges: [FlowEdge<EmptyEdgeData>] = [...]
// Callbacks:
onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) }
onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) }
onConnect: { edges = addEdge($0, edges: edges) }
```

### Pattern 2: SwiftFlowStore (centralized)
```swift
@StateObject var store = SwiftFlowStore<MyData, EmptyEdgeData>(nodes: [...], edges: [...])
// Callbacks delegate to store:
onNodesChange: { store.onNodesChange($0) }
onEdgesChange: { store.onEdgesChange($0) }
onConnect: { store.onConnect($0) }
```
Store exposes: `nodes`, `edges`, `viewport`, `selectedNodeIds`, `selectedEdgeIds`, `getNode(id:)`, `getEdge(id:)`, `getNodesData(ids:)`, `getNodeConnections(nodeId:handleType:)`, `deleteElements(nodeIds:edgeIds:)`, `nodesInitialized`, `nodeDataPublisher(id:)`.

### Pattern 3: SwiftFlowProvider (environment injection)
```swift
SwiftFlowProvider(nodes: [...], edges: [...]) { store in
    SwiftFlow(nodes: store.nodes, edges: store.edges, ...) { node in ... }
}
```

### SwiftFlowInstance (programmatic viewport control)
```swift
@StateObject var instance = SwiftFlowInstance()
// Pass to SwiftFlow: swiftFlowInstance: instance
// Methods:
instance.zoomIn()
instance.zoomOut()
instance.zoomTo(1.5)
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes, options: FitViewOptions())
instance.setCenter(x: 100, y: 200, zoom: 1.0)
instance.setViewport(Viewport(x: 0, y: 0, zoom: 1))
instance.reset()
instance.screenToFlowPosition(screenPoint)
instance.flowToScreenPosition(flowPoint)
instance.getNodesBounds(nodes: nodes, nodeSizes: sizes)
instance.getViewportForBounds(bounds: rect, minZoom: 0.1, maxZoom: 1.5, padding: 80)
instance.deleteElements(nodeIds: [...], edgeIds: [...])
```
Also: `@Environment(\.swiftFlowInstance)` and `@Environment(\.nodesInitialized)`.

### SwiftFlowState (connection tracking)
```swift
@EnvironmentObject var flowState: SwiftFlowState
flowState.activeConnection  // ConnectionState? — nil when idle
flowState.viewport
flowState.nodeSizes
flowState.nodes / flowState.edges (type-erased AnyNodeSnapshot/AnyEdgeSnapshot)
flowState.connectionsMap   // [String: [Connection]]
flowState.zoomIn() / zoomOut() / zoomTo() / fitView() / setViewport()
```

---

## Utility Functions

### State Update
```swift
applyNodeChanges(_ changes: [NodeChange<T>], nodes: [Node<T>]) -> [Node<T>]
applyEdgeChanges(_ changes: [EdgeChange<E>], edges: [Edge<E>]) -> [Edge<E>]
addEdge(_ connection: Connection, edges: [Edge<E>], defaults: DefaultEdgeOptions? = nil) -> [Edge<E>]
reconnectEdge(_ oldEdge: Edge<E>, _ newConnection: Connection, _ edges: [Edge<E>]) -> [Edge<E>]
```

### Graph Queries
```swift
getIncomers(node: Node<T>, nodes: [Node<T>], edges: [Edge<E>]) -> [Node<T>]
getOutgoers(node: Node<T>, nodes: [Node<T>], edges: [Edge<E>]) -> [Node<T>]
getConnectedEdges(node: Node<T>, edges: [Edge<E>]) -> [Edge<E>]
getConnectedEdges(nodes: [Node<T>], edges: [Edge<E>]) -> [Edge<E>]
```

### Geometry & Intersection
```swift
getNodesBounds(nodes: [Node<T>], nodeSizes: [String: CGSize]) -> CGRect
getViewportForBounds(bounds: CGRect, viewportSize: CGSize, minZoom: CGFloat = 0.1, maxZoom: CGFloat = 4.0, padding: CGFloat = 80) -> Viewport
getIntersectingNodes(node: Node<T>, nodes: [Node<T>], nodeSizes: [String: CGSize] = [:]) -> [Node<T>]
isNodeIntersecting(node: Node<T>, otherNode: Node<T>, nodeSizes: [String: CGSize] = [:]) -> Bool
isNode(_ element: Any, ofType: T.Type = T.self) -> Bool
isEdge(_ element: Any, ofType: EdgeData.Type) -> Bool
```

### Edge Paths (simple variants)
```swift
getBezierPath(sourceX:, sourceY:, targetX:, targetY:) -> Path
getSimpleBezierPath(sourceX:, sourceY:, targetX:, targetY:) -> Path
getStraightPath(sourceX:, sourceY:, targetX:, targetY:) -> Path
getStepPath(sourceX:, sourceY:, targetX:, targetY:) -> Path
getSmoothStepPath(sourceX:, sourceY:, targetX:, targetY:, borderRadius: 5) -> Path
getEdgePath(type:, sourceX:, sourceY:, targetX:, targetY:) -> Path
getEdgePathResult(type:, sourceX:, sourceY:, targetX:, targetY:) -> EdgePathResult
getEdgeMidpoint(type:, sourceX:, sourceY:, targetX:, targetY:) -> CGPoint
getEdgeAngleAtEnd(type:, sourceX:, sourceY:, targetX:, targetY:) -> CGFloat
getEdgeAngleAtStart(type:, sourceX:, sourceY:, targetX:, targetY:) -> CGFloat
```

### Edge Paths (position-aware variants)
```swift
getBezierPath(sourceX:, sourceY:, sourcePosition:, targetX:, targetY:, targetPosition:, curvature: 0.25)
    -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
getSimpleBezierPath(sourceX:, sourceY:, sourcePosition:, targetX:, targetY:, targetPosition:)
    -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
getStepPath(sourceX:, sourceY:, sourcePosition:, targetX:, targetY:, targetPosition:)
    -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
getSmoothStepPath(sourceX:, sourceY:, sourcePosition:, targetX:, targetY:, targetPosition:, borderRadius: 5)
    -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
getEdgePath(type:, sourceX:, sourceY:, sourcePosition:, targetX:, targetY:, targetPosition:)
    -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
```

### Auto Layout
```swift
computeAutoLayout(nodes:, edges:, algorithm:, nodeSizes: [:]) -> [NodeChange<T>]
    // algorithm: .tree(direction:nodeSpacing:levelSpacing:)
    //            .forceDirected(iterations:idealLength:repulsion:)
    //            .grid(columns:nodeSpacing:)
computeAutoLayoutAsync(nodes:, edges:, algorithm:, nodeSizes: [:]) async -> [NodeChange<T>]
```

### Serialization
```swift
toJSON(nodes:, edges:, viewport: nil) throws -> Data
toJSONString(nodes:, edges:, viewport: nil) throws -> String
fromJSON<T: Codable, E: Codable>(_ data: Data) throws -> SwiftFlowDocument<T, E>
fromJSONString<T: Codable, E: Codable>(_ string: String) throws -> SwiftFlowDocument<T, E>
// SwiftFlowDocument.nodes, .edges, .viewport
```
Requires NodeData: Codable, EdgeData: Codable.

---

## Theming

```swift
SwiftFlow(..., theme: .dark) { ... }
SwiftFlow(..., theme: .light) { ... }
// Custom:
var t = SwiftFlowTheme.default
t.edgeColor = .blue; t.handleColor = .orange
SwiftFlow(..., theme: t) { ... }
```

Key theme properties: `edgeColor`, `edgeSelectedColor`, `edgeWidth`, `edgeSelectedWidth`, `nodeBackgroundColor`, `nodeSelectedBorderColor`, `nodeSelectedBorderWidth`, `handleColor`, `handleBorderColor`, `handleSize`, `selectionBoxColor`, `selectionBoxBorderColor`, `canvasBackgroundColor`, `gridColor`, `gridSpacing`, `minimapBackgroundOpacity`, `minimapNodeColor`, `minimapSelectedNodeColor`, `snapLineColor`, `snapLineWidth`, `edgeLabelFont`, `edgeLabelColor`, `edgeLabelBackgroundColor`.

---

## ReactFlow Mapping Tables

### Components
| ReactFlow | SwiftFlow | Notes |
|-----------|-----------|-------|
| `<ReactFlow>` | `SwiftFlow(nodes:edges:) { node in ... }` | Node rendering via ViewBuilder, not `nodeTypes` dict |
| `<Background variant="dots">` | `Background(variant: .dots)` | In overlay ViewBuilder |
| `<Controls>` | `Controls()` | In overlay; custom buttons via `ControlButton` |
| `<MiniMap>` | `MiniMap()` | `nodeColorMapper` or custom `nodeContent` closure |
| `<Panel position="top-right">` | `Panel(position: .topRight)` | 9 positions |
| `<Handle type="source" position={Right}>` | `Handle(nodeId:node.id, id:"h1", type:.source, position:.right)` | Requires `nodeId` |
| `<NodeToolbar>` | `NodeToolbar(position: .top) { ... }` | |
| `<EdgeToolbar>` | `EdgeToolbar(position: midpoint) { ... }` | |
| `<NodeResizer>` | `NodeResizer(nodeId:node.id, ...)` | Single handle, 8 directions |
| `<NodeResizeControl>` | `NodeResizeControl(nodeId:node.id, position:.bottomRight)` | |
| `<ViewportPortal>` | `ViewportPortal(viewport: viewport) { ... }` | |

### Hooks → SwiftUI Patterns
| ReactFlow Hook | SwiftFlow Equivalent |
|----------------|---------------------|
| `useNodesState(init)` | `@State var nodes` + `applyNodeChanges` callback |
| `useEdgesState(init)` | `@State var edges` + `applyEdgeChanges` callback |
| `useReactFlow()` | `SwiftFlowInstance` (passed as param) |
| `useStoreApi()` | `SwiftFlowStore` (@StateObject) |
| `useConnection()` | `@EnvironmentObject flowState.activeConnection` |
| `useViewport()` | `instance.getViewport()` or `flowState.viewport` |
| `useNodesInitialized()` | `@Environment(\.nodesInitialized)` |
| `useNodeId()` | Node passed directly to ViewBuilder |

### Props
| Category | ReactFlow | SwiftFlow |
|----------|-----------|-----------|
| Data | `nodes`, `edges` | same |
| Changes | `onNodesChange`, `onEdgesChange` | same |
| Connect | `onConnect`, `isValidConnection` | same |
| Interaction | `nodesDraggable`, `nodesConnectable`, `elementsSelectable` | same |
| Viewport | `panOnDrag`, `panOnScroll`, `panOnScrollMode`, `zoomOnScroll`, `zoomOnPinch`, `zoomOnDoubleClick` | same |
| Selection | `selectionOnDrag`, `selectNodesOnDrag`, `selectionMode` | same |
| Grid | `snapToGrid`, `snapGrid`, `fitView`, `fitViewOptions` | same (tuple: `(x:20, y:20)`) |
| Styling | `connectionLineType`, `defaultEdgeOptions` | same |
| Keyboard | `deleteKeyCode` | `keyboardShortcuts` struct |
| A11y | `ariaLabelConfig` | `accessibilityConfig` struct |

### Event Callbacks
| ReactFlow | SwiftFlow |
|-----------|-----------|
| `onNodeClick(event, node)` | `onNodeClick: { node in }` |
| `onNodeDoubleClick` | `onNodeDoubleClick: { node in }` |
| `onEdgeClick` | `onEdgeClick: { edge in }` |
| `onNodeDragStart` | `onNodeDragStart: { node in }` |
| `onNodeDrag/Stop` | `onNodeDrag/Stop: { node in }` |
| `onSelectionDragStart/Drag/Stop` | `onSelectionDragStart/Drag/Stop: { nodes in }` |
| `onSelectionChange` | `onSelectionChange: { nodes, edges in }` |
| `onConnectStart/End` | `onConnectStart: { params in }` / `onConnectEnd: { }` |
| `onMoveStart/Move/MoveEnd` | `onMoveStart/Move/MoveEnd: { viewport in }` |
| `onBeforeDelete` | `onBeforeDelete: { nodes, edges async -> BeforeDeleteResult? }` |

### Utilities
| ReactFlow | SwiftFlow |
|-----------|-----------|
| `addEdge(conn, edges)` | `addEdge(conn, edges: edges, defaults: nil)` |
| `applyNodeChanges(changes, nodes)` | `applyNodeChanges(changes, nodes: nodes)` |
| `applyEdgeChanges(changes, edges)` | `applyEdgeChanges(changes, edges: edges)` |
| `reconnectEdge(old, conn, edges)` | `reconnectEdge(old, conn, edges)` |
| `getIncomers(node, nodes, edges)` | `getIncomers(node: node, nodes: nodes, edges: edges)` |
| `getOutgoers(node, nodes, edges)` | `getOutgoers(node: node, nodes: nodes, edges: edges)` |
| `getConnectedEdges(node/nodes, edges)` | `getConnectedEdges(node: n/node: ns, edges: edges)` |
| `getIntersectingNodes` | `getIntersectingNodes(node: node, nodes: nodes, nodeSizes: sizes)` |
| `getNodesBounds` | `getNodesBounds(nodes: nodes, nodeSizes: sizes)` |
| `getViewportForBounds` | `getViewportForBounds(bounds: b, viewportSize: size)` |
| `getBezierPath` | `getBezierPath(sourceX:sy:sp:tx:ty:tp:)` (position-aware) |
| `getSmoothStepPath` | `getSmoothStepPath(...)` (position-aware) |
| `getEdgeMidpoint` | `getEdgeMidpoint(type:sx:sy:tx:ty:)` |

---

## Platform Notes

| Feature | macOS | iOS |
|---------|-------|-----|
| Scroll zoom | `onScrollWheel` (NSEvent monitor) | — |
| Hover events (`onNodeMouseEnter` etc.) | `onHover` | Not available |
| Context menu | Right-click | Long press |
| Keyboard shortcuts | Full support (NSEvent) | Limited |
| Cursor types (`flowCursor`) | NSCursor push/pop | No-op |

---

## Complete Example (ReactFlow vs SwiftFlow)

**ReactFlow:**
```tsx
const [nodes, setNodes] = useState(initialNodes);
const [edges, setEdges] = useState(initialEdges);
const onNodesChange = useCallback((ch) => setNodes(n => applyNodeChanges(ch, n)), []);
const onEdgesChange = useCallback((ch) => setEdges(e => applyEdgeChanges(ch, e)), []);
const onConnect = useCallback((p) => setEdges(e => addEdge(p, e)), []);

<ReactFlow nodes={nodes} edges={edges} onNodesChange={onNodesChange}
           onEdgesChange={onEdgesChange} onConnect={onConnect} fitView>
  <Background variant="dots" />
  <Controls />
</ReactFlow>
```

**SwiftFlow:**
```swift
@State var nodes: [Node<MyData>] = initialNodes
@State var edges: [FlowEdge<EmptyEdgeData>] = initialEdges

SwiftFlow(
    nodes: nodes, edges: edges,
    onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
    onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
    onConnect: { edges = addEdge($0, edges: edges) },
    fitView: true
) { node in
    MyNodeView(node: node)
        .overlay(Handle(nodeId: node.id, id: "out", type: .source, position: .right))
} overlay: {
    Background(variant: .dots)
    Controls()
}
```
