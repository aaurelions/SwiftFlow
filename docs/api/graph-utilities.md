# Graph & Geometry Utilities

## Graph Query Functions

### getIncomers

```swift
public func getIncomers<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
    node: Node<NodeData>,
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>]
) -> [Node<NodeData>]
```

Returns all nodes that have edges pointing **to** the given node (predecessors).

```swift
let predecessors = getIncomers(node: myNode, nodes: nodes, edges: edges)
print("\(myNode.id) has \(predecessors.count) incoming edges")
```

### getOutgoers

```swift
public func getOutgoers<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
    node: Node<NodeData>,
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>]
) -> [Node<NodeData>]
```

Returns all nodes that the given node has edges pointing **to** (successors).

```swift
let successors = getOutgoers(node: myNode, nodes: nodes, edges: edges)
```

### getConnectedEdges

```swift
// For a single node
public func getConnectedEdges<EdgeData>(
    node: Any,
    edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>]

// For multiple nodes
public func getConnectedEdges<EdgeData>(
    nodes: [Any],
    edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>]
```

Returns all edges connected to the given node(s). The first overload accepts a single node, the second accepts an array:

```swift
let connected = getConnectedEdges(node: myNode, edges: edges)
let allConnected = getConnectedEdges(nodes: selectedNodes, edges: edges)
```

---

## Node Intersection

### getIntersectingNodes

```swift
public func getIntersectingNodes<NodeData: Equatable & Sendable>(
    node: Node<NodeData>,
    nodes: [Node<NodeData>]
) -> [Node<NodeData>]
```

Returns nodes whose bounding rectangles overlap with the given node.

### isNodeIntersecting

```swift
public func isNodeIntersecting<NodeData: Equatable & Sendable>(
    node: Node<NodeData>,
    otherNode: Node<NodeData>
) -> Bool
```

Returns `true` if the two nodes' bounding rectangles overlap.

---

## Edge Path Functions

### Simple Variants

These return a `Path` for simple coordinate-based edge rendering:

```swift
// Cubic bezier curve
func getBezierPath(
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path

// Quadratic bezier curve
func getSimpleBezierPath(
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path

// Straight line
func getStraightPath(
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path

// Right-angle steps (sharp corners)
func getStepPath(
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path

// Right-angle steps (rounded corners)
func getSmoothStepPath(
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path
```

### Position-Aware Variants

These accept `sourcePosition` and `targetPosition` (the `Position` type: `.top`, `.bottom`, `.left`, `.right`) and return a tuple with the label position:

```swift
func getBezierPath(
    sourceX: CGFloat, sourceY: CGFloat,
    sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat,
    targetPosition: Position,
    curvature: CGFloat = 0.25
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetSourceX: CGFloat, offsetSourceY: CGFloat)

func getSimpleBezierPath(
    sourceX: CGFloat, sourceY: CGFloat,
    sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat,
    targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetSourceX: CGFloat, offsetSourceY: CGFloat)

func getSmoothStepPath(
    sourceX: CGFloat, sourceY: CGFloat,
    sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat,
    targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetSourceX: CGFloat, offsetSourceY: CGFloat)
```

### Dispatcher

```swift
// Generic dispatcher by EdgeType
func getEdgePath(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> Path
```

### Full Result (EdgePathResult)

```swift
func getEdgePathResult(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> EdgePathResult
```

Returns an `EdgePathResult` with the computed path and label positioning:

```swift
let result = getEdgePathResult(
    type: .bezier,
    sourceX: 0, sourceY: 50,
    targetX: 300, targetY: 20
)

// result.path  — renderable Path
// result.labelX, result.labelY — midpoint for label
// result.sourceX, result.sourceY — start point
// result.targetX, result.targetY — end point
```

### Angle Functions

```swift
// Marker rotation at target endpoint
func getEdgeAngleAtEnd(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> CGFloat

// Marker rotation at source endpoint
func getEdgeAngleAtStart(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat,
    targetX: CGFloat, targetY: CGFloat
) -> CGFloat
```

---

## Geometry Functions

### getNodesBounds

```swift
func getNodesBounds<NodeData: Equatable & Sendable>(
    nodes: [Node<NodeData>],
    nodeSizes: [String: CGSize]
) -> CGRect
```

Returns the bounding rectangle containing all visible nodes.

### getViewportForBounds

```swift
func getViewportForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    padding: CGFloat = 80,
    maxZoom: CGFloat = 1.5
) -> Viewport
```

Computes a viewport that would display the given bounds centered in the viewport:

```swift
let bounds = getNodesBounds(nodes: nodes, nodeSizes: instance.nodeSizes)
let optimalViewport = getViewportForBounds(bounds: bounds, viewportSize: viewSize)
instance.setViewport(optimalViewport)
```

### Type Checks

```swift
func isNode(_ element: Any, ofType nodeDataType: Any.Type) -> Bool
func isEdge(_ element: Any, ofType edgeDataType: Any.Type) -> Bool
```

Runtime type checks for distinguishing nodes from edges in mixed collections.

---

## Usage Example

```swift
// Highlight all nodes connected to the selected node
@State var connectedIds: Set<String> = []

func updateConnectedNodes() {
    guard let selected = nodes.first(where: \.selected) else { return }

    let incomers = getIncomers(node: selected, nodes: nodes, edges: edges)
    let outgoers = getOutgoers(node: selected, nodes: nodes, edges: edges)
    connectedIds = Set(incomers.map(\.id) + outgoers.map(\.id))
}
```
