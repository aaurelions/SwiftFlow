# MiniMap

An interactive overview of the graph showing all nodes, edges, and the current viewport position. Click and drag to pan the main viewport; pinch or magnify to zoom it when `zoomable` is enabled. Pan and zoom gestures are active only while the canvas is interactive (`SwiftFlowState.isInteractive`).

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
| `nodeColor`        | `Color?`                          | `nil`                | Node fill color; `nil` uses `theme.minimapNodeColor` |
| `nodeColorMapper`  | `((MiniMapNodeProps) -> Color)?`  | `nil`                | Dynamic color by node properties |
| `selectedNodeColor`| `Color?`                          | `nil`                | Selected node fill color; `nil` uses `theme.minimapSelectedNodeColor` |
| `nodeStrokeColor`  | `Color`                           | `.clear`             | Node border color                |
| `nodeStrokeWidth`  | `CGFloat`                         | `0`                  | Node border width                |
| `nodeBorderRadius` | `CGFloat`                         | `1`                  | Node corner radius               |
| `maskColor`        | `Color`                           | `.gray.opacity(0.1)` | Color covering the area outside the visible viewport |
| `width`            | `CGFloat`                         | `150`                | MiniMap width                    |
| `height`           | `CGFloat`                         | `100`                | MiniMap height                   |
| `pannable`         | `Bool`                            | `true`               | Click-drag to pan main viewport  |
| `zoomable`         | `Bool`                            | `false`              | Pinch/magnify to zoom main viewport |
| `position`         | `PanelPosition`                   | `.bottomRight`       | Panel position on canvas         |
| `nodeContent`      | `((MiniMapNodeProps) -> NodeContent)?`| `nil`             | Custom node view                 |

## MiniMapNodeProps

```swift
public struct MiniMapNodeProps: Sendable {
    public let id: String
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    public let selected: Bool
    public let type: String
}
```

## How It Works

The MiniMap reads all visible nodes and the current viewport from `SwiftFlowState`, then computes a bounding box covering both the visible canvas area and every node, so the viewport indicator stays accurate even when the graph is small or far away. It scales the whole box to fit within its frame; a blue rectangle indicates the current viewport position. Edges are rendered as simple straight lines below the nodes at reduced opacity.

The MiniMap is drawn on a material background whose opacity is `theme.minimapBackgroundOpacity`, and `maskColor` covers everything outside the visible viewport (React Flow semantics). Its VoiceOver label comes from `accessibilityConfig.minimapAriaLabel`.

Dragging within the MiniMap pans the main canvas viewport proportionally; when `zoomable` is `true`, a magnification gesture zooms the main viewport around its current center. Both gestures respect the canvas `isInteractive` state and are ignored while it is disabled. When `pannable` is `false`, the MiniMap acts as a read-only overview.
