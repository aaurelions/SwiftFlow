# Auto Layout

SwiftFlow provides automatic layout algorithms for arranging nodes in a graph.

## computeAutoLayout

```swift
public func computeAutoLayout<NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable>(
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>],
    algorithm: LayoutAlgorithm
) -> [NodeChange<NodeData>]
```

Returns an array of `NodeChange.position` changes that can be applied with `applyNodeChanges`:

```swift
let changes = computeAutoLayout(
    nodes: nodes,
    edges: edges,
    algorithm: .tree(direction: .topToBottom, nodeSpacing: 50, levelSpacing: 150)
)
nodes = applyNodeChanges(changes, nodes: nodes)
```

## Async Variant

For large graphs (50+ nodes), use the async version to avoid blocking the main thread:

```swift
Task {
    let changes = await computeAutoLayoutAsync(
        nodes: nodes,
        edges: edges,
        algorithm: .forceDirected(iterations: 200)
    )
    nodes = applyNodeChanges(changes, nodes: nodes)
}
```

## LayoutAlgorithm

### Tree (Hierarchical)

Arranges nodes in a tree based on edge direction:

```swift
.tree(
    direction: LayoutDirection = .topToBottom,
    nodeSpacing: CGFloat = 50,
    levelSpacing: CGFloat = 150
)
```

```swift
// Top-to-bottom flow
let changes = computeAutoLayout(nodes: nodes, edges: edges,
    algorithm: .tree(direction: .topToBottom))

// Left-to-right flow
let changes = computeAutoLayout(nodes: nodes, edges: edges,
    algorithm: .tree(direction: .leftToRight))

// With custom spacing
let changes = computeAutoLayout(nodes: nodes, edges: edges,
    algorithm: .tree(direction: .topToBottom, nodeSpacing: 80, levelSpacing: 200))
```

### Force-Directed

Simulates physical forces to create a natural layout:

```swift
.forceDirected(
    iterations: Int = 100,
    idealLength: CGFloat = 200,
    repulsion: CGFloat = 5000
)
```

```swift
let changes = computeAutoLayout(nodes: nodes, edges: edges,
    algorithm: .forceDirected(iterations: 200, idealLength: 150, repulsion: 8000))
```

More iterations produce better layouts but take longer. The async variant is recommended for `forceDirected` with large graphs.

### Grid

Arranges nodes in a regular grid:

```swift
.grid(
    columns: Int = 4,
    nodeSpacing: CGFloat = 50
)
```

```swift
let changes = computeAutoLayout(nodes: nodes, edges: edges,
    algorithm: .grid(columns: 3, nodeSpacing: 60))
```

Nodes are placed in row-major order. Best for graphs without strong hierarchical structure.

## LayoutDirection

| Value           | Description              |
| --------------- | ------------------------ |
| `.topToBottom`  | Root at top, leaves below|
| `.bottomToTop`  | Root at bottom           |
| `.leftToRight`  | Root at left             |
| `.rightToLeft`  | Root at right            |

## Complete Example

```swift
struct FlowEditor: View {
    @State var nodes: [Node<String>] = [...]
    @State var edges: [Edge<EmptyEdgeData>] = [...]

    var body: some View {
        VStack {
            // Layout controls
            HStack {
                Button("Tree Layout") {
                    let changes = computeAutoLayout(
                        nodes: nodes, edges: edges,
                        algorithm: .tree(direction: .topToBottom)
                    )
                    nodes = applyNodeChanges(changes, nodes: nodes)
                }

                Button("Force Layout") {
                    Task {
                        let changes = await computeAutoLayoutAsync(
                            nodes: nodes, edges: edges,
                            algorithm: .forceDirected(iterations: 150)
                        )
                        nodes = applyNodeChanges(changes, nodes: nodes)
                    }
                }

                Button("Grid Layout") {
                    let changes = computeAutoLayout(
                        nodes: nodes, edges: edges,
                        algorithm: .grid(columns: 4)
                    )
                    nodes = applyNodeChanges(changes, nodes: nodes)
                }
            }

            SwiftFlow(
                nodes: nodes, edges: edges,
                onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
                onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
                onConnect: { edges = addEdge($0, edges: edges) }
            ) { node in
                Text(node.data)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))
            }
        }
    }
}
```

## Performance Notes

- `tree` layout is O(n + e) and suitable for graphs up to thousands of nodes
- `forceDirected` layout is O(iterations * n²) in the worst case; use the async variant for graphs with 50+ nodes
- `grid` layout is O(n) and suitable for any graph size
