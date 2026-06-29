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

## Custom Handle Color

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
| `color`         | `Color`     | `.gray`   | Handle fill color                                 |
| `isConnectable` | `Bool`      | `true`    | Whether the handle accepts connection gestures    |

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

1. Render invisible hit-target circles at handle positions
2. Detect when a user starts dragging from a handle
3. Snap the connection line to nearby target handles during drag
4. Validate the connection based on `connectionMode` and `isValidConnection`

The `type` parameter is critical for `connectionMode: .strict`, which only allows source-to-target connections.

## Size

Handles are rendered as 12pt diameter circles with a white border and subtle shadow. The hit target is a 30pt diameter invisible circle for easy touch/mouse interaction.
