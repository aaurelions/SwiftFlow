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
public func getConnectedEdges<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
    node: Node<NodeData>,
    edges: [Edge<EdgeData>]
) -> [Edge<EdgeData>]

// For multiple nodes
public func getConnectedEdges<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
    nodes: [Node<NodeData>],
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
    nodes: [Node<NodeData>],
    nodeSizes: [String: CGSize] = [:]
) -> [Node<NodeData>]
```

Returns visible nodes whose bounding rectangles overlap with the given node. Absolute positions are used (child positions are resolved relative to their parent). Unmeasured nodes use their explicit `width`/`height`, or 150×50.

### isNodeIntersecting

```swift
public func isNodeIntersecting<NodeData: Equatable & Sendable>(
    node: Node<NodeData>,
    otherNode: Node<NodeData>,
    nodeSizes: [String: CGSize] = [:]
) -> Bool
```

Returns `true` if the two nodes' bounding rectangles overlap.

---

## Edge Path Functions

The edge path functions port React Flow's algorithms exactly.

### Position-Aware Variants

These accept `sourcePosition` and `targetPosition` (the `Position` type: `.top`, `.bottom`, `.left`, `.right`, the node side of each handle) and return a tuple like React Flow: the path, the label position, and the offsets from the source/target to the label position:

```swift
func getBezierPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
    curvature: CGFloat = 0.25
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)

func getSimpleBezierPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)

func getSmoothStepPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position,
    borderRadius: CGFloat = 5,
    centerX: CGFloat? = nil,
    centerY: CGFloat? = nil,
    offset: CGFloat = 20
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)

// Equivalent to getSmoothStepPath with borderRadius: 0
func getStepPath(
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
```

- `getBezierPath`: the control offset is `0.5 * distance` along the handle axis, or `curvature * 25 * sqrt(-distance)` when the target lies behind the source handle.
- `getSimpleBezierPath`: a cubic curve with its control points at the axis midpoint.
- `getSmoothStepPath`: uses React Flow's routing for every combination of handle sides.

### Dispatcher

```swift
// Generic dispatcher by EdgeType
func getEdgePath(
    type: EdgeType,
    sourceX: CGFloat, sourceY: CGFloat, sourcePosition: Position,
    targetX: CGFloat, targetY: CGFloat, targetPosition: Position
) -> (path: Path, labelX: CGFloat, labelY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
```

For `.straight` the label is at the center of the line and the offsets are `abs(delta) / 2`.

### Overloads Without Positions

These assume the source handle is on the **right** and the target handle on the **left**, and return only a `Path` (or the noted type):

```swift
func getBezierPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path
func getSimpleBezierPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path
func getStraightPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path
func getStepPath(sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path
func getSmoothStepPath(
    sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat,
    borderRadius: CGFloat = 5
) -> Path

func getEdgePath(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> Path
func getEdgePathResult(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> EdgePathResult
func getEdgeMidpoint(type: EdgeType, sourceX: CGFloat, sourceY: CGFloat, targetX: CGFloat, targetY: CGFloat) -> CGPoint
```

### Full Result (EdgePathResult)

`getEdgePathResult` returns an `EdgePathResult` with the computed path and label positioning:

```swift
let result = getEdgePathResult(
    type: .bezier,
    sourceX: 0, sourceY: 50,
    targetX: 300, targetY: 20
)

// result.path  - renderable Path
// result.labelX, result.labelY - midpoint for label
// result.sourceX, result.sourceY - start point
// result.targetX, result.targetY - end point
```

### Angle Functions

Also assume a right-side source and a left-side target:

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

The canvas itself renders edges using each `Handle`'s `position`, so top/bottom handles route correctly and arrow markers follow the path ends.

---

## Geometry Functions

### getNodesBounds

```swift
func getNodesBounds<NodeData: Equatable & Sendable>(
    nodes: [Node<NodeData>],
    nodeSizes: [String: CGSize]
) -> CGRect
```

Returns the bounding rectangle containing all visible nodes. Parent-relative child positions are resolved to absolute positions, and `Node.origin` is applied. Unmeasured nodes use their explicit `width`/`height`, or 150×50.

### getViewportForBounds

```swift
func getViewportForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    minZoom: CGFloat = Viewport.minZoom,
    maxZoom: CGFloat = Viewport.maxZoom,
    padding: CGFloat = 80
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
func isNode<T: Equatable & Sendable>(_ element: Any, ofType: T.Type = T.self) -> Bool
func isEdge<EdgeData: Equatable & Sendable & Hashable>(_ element: Any, ofType: EdgeData.Type) -> Bool
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
