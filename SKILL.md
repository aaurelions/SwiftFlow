---
name: SwiftFlow
description: Comprehensive documentation and mapping between ReactFlow (TypeScript) and SwiftFlow (SwiftUI). Use this skill to translate ReactFlow concepts to SwiftFlow or to build native node-based graph editors in iOS and macOS using familiar ReactFlow patterns.
license: MIT
compatibility: iOS 16.0+, macOS 13.0+, Swift 6.1+
metadata:
  author: swiftflow-community
  version: "0.1.0"
---

# SwiftFlow & ReactFlow Documentation Bridge

SwiftFlow is a native SwiftUI node-based graph editor whose architecture and API surface are inspired by [React Flow](https://reactflow.dev). This document maps the core ReactFlow concepts, components, types, and utilities to their SwiftFlow equivalents where they exist today (release 0.1.0).

If you are familiar with ReactFlow, the tables below help you translate those patterns into idiomatic SwiftFlow code. Note that this is an early release; some ReactFlow features are not yet implemented or differ in SwiftUI-native form.

---

## 1. Core Components

ReactFlow uses React functional components and JSX. SwiftFlow uses SwiftUI Views.

| ReactFlow (TypeScript)                                   | SwiftFlow (SwiftUI)                                                    | Notes                                                                                                                |
| :------------------------------------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------- |
| `<ReactFlow nodes={n} edges={e} />`                      | `SwiftFlow(nodes: n, edges: e) { node in ... }`                        | SwiftFlow requires a trailing closure (`ViewBuilder`) for custom node rendering instead of a `nodeTypes` dictionary. |
| `<Background variant="dots" gap={20} />`                 | `Background(variant: .dots, gap: 20)`                                  | Placed inside the `overlay` ViewBuilder in `SwiftFlow`.                                                              |
| `<Controls showZoom={true} />`                           | `Controls(showZoom: true)`                                             | Placed inside `overlay`. Custom buttons use `ControlButton`.                                                         |
| `<MiniMap pannable zoomable />`                          | `MiniMap(pannable: true, zoomable: true)`                              | Supports `nodeColorMapper` or a custom `nodeContent` closure.                                                        |
| `<Panel position="top-right">`                           | `Panel(position: .topRight) { ... }`                                   | 9 positions supported (`.topLeft` to `.bottomRight`).                                                                |
| `<Handle type="source" position={Position.Right} />`     | `Handle(nodeId: node.id, id: "h1", type: .source, position: .right)`   | SwiftFlow requires `nodeId` in the Handle.                                                                           |
| `<BaseEdge path={p} ... />`                              | `BaseEdge(path: p, ...)`                                               | Primitive edge component. Supports animated dash phases.                                                             |
| `<EdgeLabelRenderer>`                                    | `EdgeLabelRenderer(position: midpoint) { ... }`                        | Auto-scales the label to counteract viewport zoom.                                                                   |
| `<EdgeText x={x} y={y} label="text" />`                  | `EdgeText(x: x, y: y, label: "text")`                                  | Standard label renderer for custom edges.                                                                            |
| `<NodeToolbar isVisible={true} position={Position.Top}>` | `NodeToolbar(nodeId: id, isVisible: true, position: .top) { ... }`     | Floating contextual toolbar.                                                                                         |
| `<EdgeToolbar isVisible={true} position={midpoint}>`     | `EdgeToolbar(edgeId: id, isVisible: true, position: midpoint) { ... }` | Floating toolbar for edges.                                                                                          |
| `<NodeResizer minWidth={100} />`                         | `NodeResizer(nodeId: node.id, minWidth: 100, ...)`                     | Generates 8 resize handles.                                                                                          |
| `<NodeResizeControl position="bottom-right">`            | `NodeResizeControl(nodeId: node.id, position: .bottomRight)`           | A single resize handle for custom placements.                                                                        |
| `<ViewportPortal>`                                       | `ViewportPortal(viewport: viewport) { ... }`                           | Renders content in canvas flow coordinates.                                                                          |

---

## 2. State Management & Hooks

ReactFlow relies heavily on React hooks. SwiftFlow uses SwiftUI's `@State`, `@Environment`, `@StateObject`, and an optional `SwiftFlowStore` wrapper.

| ReactFlow Hook (TypeScript)                                    | SwiftFlow Equivalent (Swift)                                                           |
| :------------------------------------------------------------- | :------------------------------------------------------------------------------------- |
| `const [nodes, setNodes, onNodesChange] = useNodesState(init)` | `@State var nodes = init` + `applyNodeChanges` in callback                             |
| `const[edges, setEdges, onEdgesChange] = useEdgesState(init)`  | `@State var edges = init` + `applyEdgeChanges` in callback                             |
| `const instance = useReactFlow()`                              | `@StateObject var instance = SwiftFlowInstance()` (passed as param)                    |
| `const store = useStoreApi()`                                  | `@StateObject var store = SwiftFlowStore(...)`                                         |
| `const connection = useConnection()`                           | `@EnvironmentObject var flowState: SwiftFlowState`<br>`flowState.activeConnection`     |
| `const viewport = useViewport()`                               | `instance.getViewport()` OR `@EnvironmentObject var flowState`<br>`flowState.viewport` |
| `const nodesInit = useNodesInitialized()`                      | `@Environment(\.nodesInitialized) var nodesInitialized`                                |
| `const id = useNodeId()`                                       | Passed directly to the node `ViewBuilder` closure in SwiftFlow.                        |

### Using `SwiftFlowInstance`

```swift
// Swift equivalent to useReactFlow()
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(nodes: nodes, edges: edges, swiftFlowInstance: instance) { node in ... }

// Usage
instance.zoomIn()
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
instance.setCenter(x: 100, y: 100)
let pos = instance.screenToFlowPosition(CGPoint(x: 50, y: 50))
```

---

## 3. Core Types

ReactFlow types seamlessly map to Swift equivalents (often utilizing generics for custom Data).

| ReactFlow Type           | SwiftFlow Type                                                           |
| :----------------------- | :----------------------------------------------------------------------- |
| `Node<Data>`             | `Node<NodeData: Equatable & Sendable>`                                   |
| `Edge<Data>`             | `Edge<EdgeData: Equatable & Sendable & Hashable>`                        |
| `Connection`             | `Connection`                                                             |
| `Viewport`               | `Viewport`                                                               |
| `XYPosition`             | `XYPosition`                                                             |
| `CoordinateExtent`       | `CoordinateExtent`                                                       |
| `NodeChange`             | `NodeChange<NodeData>` (enum with `.position`, `.add`, `.remove`, etc.)  |
| `EdgeChange`             | `EdgeChange<EdgeData>`                                                   |
| `ConnectionMode.Strict`  | `ConnectionMode.strict`                                                  |
| `SelectionMode.Partial`  | `SelectionMode.partial`                                                  |
| `PanOnScrollMode.Free`   | `PanOnScrollMode.free`                                                   |
| `MarkerType.ArrowClosed` | `MarkerType.arrowClosed`                                                 |
| `EdgeType` (string)      | `EdgeType` (enum: `.default`, `.straight`, `.step`, `.smoothstep`, etc.) |

---

## 4. Main Component Parameters (Props)

`SwiftFlow` supports all `<ReactFlow>` props with identical names (adapted to Swift camelCase conventions).

| Prop Category     | ReactFlow                                                                                         | SwiftFlow                                                                                         |
| :---------------- | :------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------ |
| **Data**          | `nodes`, `edges`                                                                                  | `nodes`, `edges`                                                                                  |
| **Changes**       | `onNodesChange`, `onEdgesChange`                                                                  | `onNodesChange`, `onEdgesChange`                                                                  |
| **Connections**   | `onConnect`, `isValidConnection`                                                                  | `onConnect`, `isValidConnection`                                                                  |
| **Interaction**   | `nodesDraggable`, `nodesConnectable`, `elementsSelectable`                                        | `nodesDraggable`, `nodesConnectable`, `elementsSelectable`                                        |
| **Viewport**      | `panOnDrag`, `panOnScroll`, `panOnScrollMode`, `zoomOnScroll`, `zoomOnPinch`, `zoomOnDoubleClick` | `panOnDrag`, `panOnScroll`, `panOnScrollMode`, `zoomOnScroll`, `zoomOnPinch`, `zoomOnDoubleClick` |
| **Selection**     | `selectionOnDrag`, `selectNodesOnDrag`, `selectionMode`                                           | `selectionOnDrag`, `selectNodesOnDrag`, `selectionMode`                                           |
| **Grid & Fit**    | `snapToGrid`, `snapGrid={[15,15]}`, `fitView`, `fitViewOptions`                                   | `snapToGrid`, `snapGrid: (x: 15, y: 15)`, `fitView`, `fitViewOptions`                             |
| **Styling**       | `connectionLineType`, `defaultEdgeOptions`                                                        | `connectionLineType`, `defaultEdgeOptions`                                                        |
| **Keyboard**      | `deleteKeyCode={51}`, `multiSelectionKeyCode`                                                     | `keyboardShortcuts: KeyboardShortcuts(deleteKeyCode: 51, ...)`                                    |
| **Accessibility** | `ariaLabelConfig`                                                                                 | `accessibilityConfig: AccessibilityConfig(...)`                                                   |

### Event Callback Mapping

| ReactFlow                       | SwiftFlow                                                         |
| :------------------------------ | :---------------------------------------------------------------- |
| `onNodeClick(event, node)`      | `onNodeClick: { node in }`                                        |
| `onNodeDoubleClick`             | `onNodeDoubleClick: { node in }`                                  |
| `onEdgeClick`                   | `onEdgeClick: { edge in }`                                        |
| `onNodeDragStart(event, node)`  | `onNodeDragStart: { node in }`                                    |
| `onNodeDrag`                    | `onNodeDrag: { node in }`                                         |
| `onNodeDragStop`                | `onNodeDragStop: { node in }`                                     |
| `onSelectionDragStart`          | `onSelectionDragStart: { nodes in }`                              |
| `onSelectionChange`             | `onSelectionChange: { nodes, edges in }`                          |
| `onConnectStart(event, params)` | `onConnectStart: { params in }`                                   |
| `onConnectEnd(event)`           | `onConnectEnd: { }`                                               |
| `onMoveStart(event, viewport)`  | `onMoveStart: { viewport in }`                                    |
| `onMove(event, viewport)`       | `onMove: { viewport in }`                                         |
| `onMoveEnd(event, viewport)`    | `onMoveEnd: { viewport in }`                                      |
| `onBeforeDelete`                | `onBeforeDelete: { nodes, edges async -> BeforeDeleteResult in }` |

---

## 5. Utility Functions

SwiftFlow provides ReactFlow-inspired utility functions for edges, bounding boxes, and graph lookups, with Swift argument labels and generic constraints.

| ReactFlow (TypeScript)               | SwiftFlow (Swift)                                                  |
| :----------------------------------- | :----------------------------------------------------------------- |
| `addEdge(conn, edges)`               | `addEdge(conn, edges: edges)`                                      |
| `applyNodeChanges(changes, nodes)`   | `applyNodeChanges(changes, nodes: nodes)`                          |
| `applyEdgeChanges(changes, edges)`   | `applyEdgeChanges(changes, edges: edges)`                          |
| `reconnectEdge(old, conn, edges)`    | `reconnectEdge(old, conn, edges)`                                  |
| `getIncomers(node, nodes, edges)`    | `getIncomers(node: node, nodes: nodes, edges: edges)`              |
| `getOutgoers(node, nodes, edges)`    | `getOutgoers(node: node, nodes: nodes, edges: edges)`              |
| `getConnectedEdges(nodes, edges)`    | `getConnectedEdges(nodes: nodes, edges: edges)`                    |
| `getIntersectingNodes(node, nodes)`  | `getIntersectingNodes(node: node, nodes: nodes, nodeSizes: sizes)` |
| `isNodeIntersecting(n1, n2)`         | `isNodeIntersecting(node: n1, otherNode: n2)`                      |
| `getNodesBounds(nodes)`              | `getNodesBounds(nodes: nodes, nodeSizes: sizes)`                   |
| `getViewportForBounds(bounds, w, h)` | `getViewportForBounds(bounds: bounds, viewportSize: size)`         |
| `isNode(element)`                    | `isNode(element)`                                                  |
| `isEdge(element)`                    | `isEdge(element, ofType: EdgeData.self)`                           |

### Path Calculation Functions

SwiftFlow's path functions return standard SwiftUI `Path` objects and include position-aware variants identical to React Flow.

| ReactFlow Path Utils          | SwiftFlow Equivalent                                                                 |
| :---------------------------- | :----------------------------------------------------------------------------------- |
| `getBezierPath(params)`       | `getBezierPath(sourceX: sourceY: sourcePosition: targetX: targetY: targetPosition:)` |
| `getSimpleBezierPath(params)` | `getSimpleBezierPath(...)`                                                           |
| `getSmoothStepPath(params)`   | `getSmoothStepPath(...)`                                                             |
| `getStepPath(params)`         | `getStepPath(...)`                                                                   |
| `getStraightPath(params)`     | `getStraightPath(...)`                                                               |
| `getEdgeMidpoint(params)`     | `getEdgeMidpoint(...)`                                                               |

---

## 6. SwiftFlow Exclusives (AutoLayout & Serialization)

SwiftFlow includes features native to Swift environments that normally require extra plugins in React.

### AutoLayout

Included Layout algorithms: Tree, Force-Directed, and Grid.

```swift
let changes = computeAutoLayout(
    nodes: nodes,
    edges: edges,
    algorithm: .tree(direction: .topToBottom, nodeSpacing: 50, levelSpacing: 150)
)
nodes = applyNodeChanges(changes, nodes: nodes)

// For large graphs:
let changes = await computeAutoLayoutAsync(nodes: nodes, edges: edges, algorithm: .forceDirected())
```

### Serialization

Provided `NodeData` and `EdgeData` conform to `Codable`, the entire graph can be serialized.

```swift
let jsonString = try toJSONString(nodes: nodes, edges: edges, viewport: viewport)
let document: SwiftFlowDocument<MyNodeData, MyEdgeData> = try fromJSONString(jsonString)
```

---

## 7. Complete Example Comparison

### ReactFlow (TypeScript)

```tsx
import { useState, useCallback } from "react";
import {
  ReactFlow,
  applyNodeChanges,
  applyEdgeChanges,
  addEdge,
  Background,
  Controls,
} from "@xyflow/react";

export default function Flow() {
  const [nodes, setNodes] = useState(initialNodes);
  const [edges, setEdges] = useState(initialEdges);

  const onNodesChange = useCallback(
    (changes) => setNodes((nds) => applyNodeChanges(changes, nds)),
    [],
  );
  const onEdgesChange = useCallback(
    (changes) => setEdges((eds) => applyEdgeChanges(changes, eds)),
    [],
  );
  const onConnect = useCallback(
    (params) => setEdges((eds) => addEdge(params, eds)),
    [],
  );

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={onConnect}
      fitView
    >
      <Background variant="dots" />
      <Controls />
    </ReactFlow>
  );
}
```

### SwiftFlow (SwiftUI)

```swift
import SwiftUI
import SwiftFlow

struct FlowView: View {
    @State var nodes: [Node<String>] = initialNodes
    @State var edges: [Edge<EmptyEdgeData>] = initialEdges
    @StateObject var instance = SwiftFlowInstance()

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            fitView: true,
            swiftFlowInstance: instance
        ) { node in
            // Custom node rendering closure (replaces nodeTypes mapping)
            Text(node.data)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black))
                // Handles are declared inside the Node ViewBuilder
                .overlay(Handle(nodeId: node.id, id: "out", type: .source, position: .right))
        } overlay: {
            Background(variant: .dots)
            Controls()
        }
    }
}
```
