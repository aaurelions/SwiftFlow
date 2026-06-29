# MiniMap

An interactive overview of the graph showing all nodes, edges, and the current viewport position. Click and drag to pan the main viewport.

## Basic Usage

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    MyNodeView(node: node)
} overlay: {
    MiniMap()
}
```

## Color Mapping

Assign colors dynamically based on node properties:

```swift
MiniMap(nodeColorMapper: { props in
    switch props.type {
    case "input":    return .green
    case "output":   return .orange
    case "process":  return .blue
    default:         return .gray
    }
})
```

## Custom Node Rendering

Provide a custom view for each node in the minimap:

```swift
MiniMap { props in
    Circle()
        .fill(props.selected ? .blue : .gray)
        .overlay(
            Circle()
                .stroke(props.selected ? .white : .clear, lineWidth: 1)
        )
}
```

## Customization

```swift
MiniMap(
    nodeColor: .gray.opacity(0.4),
    selectedNodeColor: .cyan,
    nodeStrokeColor: .white.opacity(0.5),
    nodeStrokeWidth: 1,
    nodeBorderRadius: 2,
    maskColor: .black.opacity(0.5),
    width: 200,
    height: 150,
    pannable: true,
    zoomable: false,
    position: .bottomLeft
)
```

## Parameters

| Parameter          | Type                              | Default              | Description                      |
| ------------------ | --------------------------------- | -------------------- | -------------------------------- |
| `nodeColor`        | `Color`                           | `.gray.opacity(0.5)` | Default node fill color          |
| `nodeColorMapper`  | `((MiniMapNodeProps) -> Color)?`  | `nil`                | Dynamic color by node properties |
| `selectedNodeColor`| `Color`                           | `.blue`              | Selected node fill color         |
| `nodeStrokeColor`  | `Color`                           | `.clear`             | Node border color                |
| `nodeStrokeWidth`  | `CGFloat`                         | `0`                  | Node border width                |
| `nodeBorderRadius` | `CGFloat`                         | `1`                  | Node corner radius               |
| `maskColor`        | `Color`                           | `.gray.opacity(0.1)` | Background mask color            |
| `width`            | `CGFloat`                         | `150`                | MiniMap width                    |
| `height`           | `CGFloat`                         | `100`                | MiniMap height                   |
| `pannable`         | `Bool`                            | `true`               | Click-drag to pan main viewport  |
| `zoomable`         | `Bool`                            | `false`              | Scroll to zoom (future)          |
| `position`         | `PanelPosition`                   | `.bottomRight`       | Panel position on canvas         |
| `nodeContent`      | `((MiniMapNodeProps) -> NodeContent)?`| `nil`             | Custom node view                 |

## MiniMapNodeProps

```swift
public struct MiniMapNodeProps: Sendable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let selected: Bool
    let type: String
}
```

## How It Works

The MiniMap reads all visible nodes from `SwiftFlowState`, computes a bounding box, and scales the entire graph to fit within its frame. A blue rectangle indicates the current viewport position. Edges are rendered as simple straight lines at reduced opacity.

Dragging within the MiniMap pans the main canvas viewport proportionally. When `pannable` is `false`, the MiniMap acts as a read-only overview.
