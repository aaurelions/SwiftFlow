# Models

## Node

A graph node with generic user data, position, and interaction properties.

```swift
public struct Node<NodeData: Equatable & Sendable>: Identifiable, Equatable, Sendable
```

### Properties

| Property         | Type          | Default     | Description                                       |
| ---------------- | ------------- | ----------- | ------------------------------------------------- |
| `id`             | `String`      | —           | Unique identifier (required)                      |
| `position`       | `XYPosition`  | —           | Position on canvas (required)                     |
| `data`           | `NodeData`    | —           | User-defined data (required)                      |
| `type`           | `String`      | `"default"` | Node type for styling and filtering               |
| `parentId`       | `String?`     | `nil`       | Parent node ID for grouping and sub-flows         |
| `selected`       | `Bool`        | `false`     | Whether the node is currently selected            |
| `hidden`         | `Bool`        | `false`     | Whether the node is hidden                        |
| `width`          | `CGFloat?`    | `nil`       | Explicit width; `nil` = measured from content     |
| `height`         | `CGFloat?`    | `nil`       | Explicit height; `nil` = measured from content    |
| `draggable`      | `Bool`        | `true`      | Whether the node can be dragged                   |
| `selectable`     | `Bool`        | `true`      | Whether the node can be selected                  |
| `connectable`    | `Bool`        | `true`      | Whether handles on this node accept connections   |
| `deletable`      | `Bool`        | `true`      | Whether the node can be deleted (keyboard or `deleteElements`)      |
| `expandable`     | `Bool`        | `false`     | Whether the node can expand/collapse sub-nodes    |
| `expanded`       | `Bool`        | `true`      | Current expanded state (if expandable)            |
| `expandParent`   | `Bool`        | `false`     | Grow the parent while dragging this child past its edges |
| `focusable`      | `Bool`        | `true`      | Whether the node can receive keyboard focus (Tab) |
| `zIndex`         | `Int`         | `0`         | Render order (higher = on top)                    |
| `origin`         | `NodeOrigin`  | `.topLeft`  | Anchor point: node top-left = `position - origin * size`. Wins over the canvas `nodeOrigin` when not `.topLeft`. Child positions are relative to the parent's top-left |
| `sourcePosition` | `Position?`   | `nil`       | Side edges attach to when the node has no rendered source handle (default right) |
| `targetPosition` | `Position?`   | `nil`       | Side edges attach to when the node has no rendered target handle (default left) |
| `extent`         | `NodeExtent?` | `nil`       | Drag constraint (`.parent` or `.coordinateExtent`)|
| `style`          | `NodeStyle?`  | `nil`       | Per-node visual style applied by the canvas (background, border, radius, opacity) |

### Initialization

```swift
let node = Node(
    id: "node-1",
    position: XYPosition(x: 100, y: 200),
    data: "My Node Data",
    type: "custom",
    selected: false,
    draggable: true,
    selectable: true,
    connectable: true
)
```

### Codable Support

`Node` becomes `Codable` when `NodeData` conforms to `Codable`. This enables full graph serialization.

---

## Edge

A connection between two nodes with visual style, labels, markers, and animation.

```swift
public struct Edge<EdgeData: Equatable & Sendable & Hashable>: Identifiable, Equatable, Sendable, Hashable
```

### Properties

| Property          | Type          | Default     | Description                                        |
| ----------------- | ------------- | ----------- | -------------------------------------------------- |
| `id`              | `String`      | —           | Unique identifier (required)                       |
| `source`          | `String`      | —           | Source node ID (required)                          |
| `target`          | `String`      | —           | Target node ID (required)                          |
| `sourceHandle`    | `String?`     | `nil`       | Source handle ID (for multi-handle nodes)          |
| `targetHandle`    | `String?`     | `nil`       | Target handle ID (for multi-handle nodes)          |
| `type`            | `EdgeType`    | `.default`  | Path style                                         |
| `selected`        | `Bool`        | `false`     | Selection state                                    |
| `hidden`          | `Bool`        | `false`     | Visibility                                         |
| `label`           | `String?`     | `nil`       | Text label displayed at edge midpoint              |
| `animated`        | `Bool`        | `false`     | Animated dash pattern                              |
| `markerStart`     | `EdgeMarker?` | `nil`       | Start endpoint marker                              |
| `markerEnd`       | `EdgeMarker?` | `nil`       | End endpoint marker                                |
| `zIndex`          | `Int`         | `0`         | Render order                                       |
| `reconnectable`   | `Bool`        | `false`     | Whether endpoints can be dragged to reconnect (also requires `onReconnect`, selection and `nodesConnectable`) |
| `deletable`       | `Bool`        | `true`      | Deletable via keyboard or `deleteElements`                             |
| `focusable`       | `Bool`        | `true`      | Whether the edge can receive keyboard focus (Tab)  |
| `interactionWidth`| `CGFloat`     | `20`        | Width of the invisible hit area used for selection and clicks |
| `data`            | `EdgeData?`   | `nil`       | User-defined data                                  |
| `style`           | `EdgeStyle?`  | `nil`       | Per-edge visual style overrides (stroke color, width, opacity) |

### EdgeType

| Value                    | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `.default` / `.bezier`   | Smooth cubic bezier curve                      |
| `.straight`              | Direct straight line                           |
| `.step`                  | Right-angle path with sharp corners            |
| `.smoothstep`            | Right-angle path with rounded corners          |
| `.simplebezier`          | Cubic curve with control points at the axis midpoint     |

### EdgeMarker

```swift
public struct EdgeMarker: Equatable, Sendable, Codable, Hashable {
    var type: MarkerType   // .arrow or .arrowClosed
    var width: CGFloat     // default: 12
    var height: CGFloat    // default: 12

    static let arrow       // Open arrowhead
    static let arrowClosed // Filled arrowhead
}
```

### MarkerType

| Value          | Description                  |
| -------------- | ---------------------------- |
| `.arrow`       | Open arrowhead (stroke only) |
| `.arrowClosed` | Filled arrowhead (triangle)  |

### Creating Edges

```swift
// Basic edge
let edge = FlowEdge<EmptyEdgeData>(id: "e1", source: "1", target: "2")

// Styled edge with arrowhead and label
let edge = FlowEdge<EmptyEdgeData>(
    id: "e1-2",
    source: "1", target: "2",
    sourceHandle: "out", targetHandle: "in",
    type: .smoothstep,
    label: "flows to",
    animated: true,
    markerEnd: EdgeMarker(type: .arrowClosed)
)

// Edge with custom data
struct FlowData: Equatable, Sendable, Codable, Hashable {
    var weight: Double
}
let edge = Edge<FlowData>(
    id: "e1", source: "1", target: "2",
    data: FlowData(weight: 1.0)
)
```

### EmptyEdgeData

Use `EmptyEdgeData` when edges don't need custom data:

```swift
@State var edges: [FlowEdge<EmptyEdgeData>] = [
    FlowEdge(id: "e1", source: "1", target: "2")
]
```

### FlowEdge Type Alias

When SwiftFlow and SwiftUI share the same namespace, use `FlowEdge`:

```swift
let edges: [FlowEdge<EmptyEdgeData>] = [...]
```

### Codable Support

`Edge` becomes `Codable` when `EdgeData` conforms to `Codable`.

---

## Connection

Represents a pending connection request between two handles.

```swift
public struct Connection: Equatable, Sendable, Codable, Hashable {
    var source: String        // Source node ID
    var target: String        // Target node ID
    var sourceHandle: String? // Source handle ID
    var targetHandle: String? // Target handle ID
}
```

Passed to `onConnect` and `isValidConnection` callbacks during interactive edge drawing.

---

## Viewport

Camera state describing pan offset and zoom level.

```swift
public struct Viewport: Equatable, Sendable, Codable, Hashable {
    var x: CGFloat       // Horizontal pan offset
    var y: CGFloat       // Vertical pan offset
    var zoom: CGFloat    // Zoom level (0.1 ... 4.0)

    static let identity  // x: 0, y: 0, zoom: 1.0
    static let minZoom: CGFloat = 0.1
    static let maxZoom: CGFloat = 4.0
}
```

---

## XYPosition

A 2D coordinate on the canvas.

```swift
public struct XYPosition: Equatable, Sendable, Codable, Hashable {
    var x: CGFloat
    var y: CGFloat

    static let zero  // (0, 0)

    // Arithmetic operators
    static func + (lhs:, rhs:) -> XYPosition
    static func - (lhs:, rhs:) -> XYPosition

    // Grid snapping
    func snapped(to grid: (x: CGFloat, y: CGFloat)) -> XYPosition
}
```
