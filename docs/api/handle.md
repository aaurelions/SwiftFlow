# Handle

Connection endpoints on nodes. Place inside your custom node view to make nodes connectable.

## Basic Usage

```swift
HStack(spacing: 0) {
    // Target handle on the left (receives connections)
    Handle(nodeId: node.id, id: "input", type: .target, position: .left)

    Text(node.data)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

    // Source handle on the right (initiates connections)
    Handle(nodeId: node.id, id: "output", type: .source, position: .right)
}
```

## Multi-Handle Nodes

Nodes can have multiple handles. Each handle needs a unique `id` within the node:

```swift
VStack {
    // Top target handles
    HStack {
        Handle(nodeId: node.id, id: "t1", type: .target, position: .top)
        Handle(nodeId: node.id, id: "t2", type: .target, position: .top)
    }

    Text(node.data).padding()

    // Bottom source handles
    HStack {
        Handle(nodeId: node.id, id: "b1", type: .source, position: .bottom)
        Handle(nodeId: node.id, id: "b2", type: .source, position: .bottom)
    }
}
```

When creating edges, the specific handle IDs are stored in `sourceHandle` and `targetHandle` on the `Edge`.

`position` is the node side the handle sits on: place the view on that side in your node layout. The canvas routes edges using this `position`, so top/bottom handles leave and enter in the correct direction and arrow markers follow the path ends.

An edge whose `sourceHandle`/`targetHandle` is `nil` attaches to the first handle of that type on the node (React Flow behavior). If a node has no rendered handle, the edge attaches to the center of the side given by `Node.sourcePosition`/`targetPosition` (defaults: right/left).

## Custom Handle Color

By default handles use `theme.handleColor`; pass `color` to override per handle.

```swift
// Red input
Handle(nodeId: node.id, id: "in", type: .target, position: .left, color: .red)

// Green output
Handle(nodeId: node.id, id: "out", type: .source, position: .right, color: .green)
```

## Disabling Connections per Handle

```swift
Handle(nodeId: node.id, id: "locked", type: .source, position: .right, isConnectable: false)
```

## Parameters

| Parameter       | Type        | Default   | Description                                       |
| --------------- | ----------- | --------- | ------------------------------------------------- |
| `nodeId`        | `String`    | —         | Parent node ID (required)                         |
| `id`            | `String`    | —         | Handle identifier (unique per node, required)     |
| `type`          | `HandleType`| `.source` | `.source` or `.target`                            |
| `position`      | `Position`  | —         | Visual placement: `.top`, `.bottom`, `.left`, `.right` |
| `color`         | `Color?`    | `nil`     | Handle fill color; `nil` uses `theme.handleColor` |
| `isConnectable` | `Bool`      | `true`    | Whether the handle accepts connection gestures (respected by the canvas) |

## HandleType

| Value    | Description                          |
| -------- | ------------------------------------ |
| `.source`| Initiates connections (drag out)     |
| `.target`| Receives connections (drag into)     |

## Position

| Value    | Visual Placement |
| -------- | ---------------- |
| `.top`   | Top edge         |
| `.bottom`| Bottom edge      |
| `.left`  | Left edge        |
| `.right` | Right edge       |

## How It Works

Handles report their positions and types to the SwiftFlow canvas via SwiftUI `PreferenceKey`. The canvas uses this data to:

1. Render invisible hit-target circles at handle positions (skipped for handles with `isConnectable: false`)
2. Detect when a user starts dragging from a handle
3. Snap the connection line to nearby target handles during drag
4. Validate the connection based on `connectionMode` and `isValidConnection`

The `type` parameter is critical for `connectionMode: .strict`, which only allows source-to-target connections.

## Size

Handles are rendered as circles sized by `theme.handleSize` (default 12pt) with a `theme.handleBorderColor` border (default white) and a subtle shadow. The hit target is a 30pt diameter invisible circle for easy touch/mouse interaction.
