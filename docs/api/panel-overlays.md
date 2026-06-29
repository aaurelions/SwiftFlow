# Panel & Overlays

## Panel

A positional container for placing custom UI elements on the canvas.

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    MyNodeView(node: node)
} overlay: {
    Panel(position: .topRight) {
        VStack(spacing: 8) {
            Button("Add Node") { addNode() }
            Button("Reset View") { resetView() }
            Button("Export") { exportGraph() }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
```

### Parameters

| Parameter  | Type            | Default     | Description                |
| ---------- | --------------- | ----------- | -------------------------- |
| `position` | `PanelPosition` | `.topRight` | Position on canvas         |
| `content`  | `() -> Content` | —           | ViewBuilder for content    |

---

## NodeToolbar

A floating toolbar that appears near a selected node.

```swift
// Inside your node view or overlay
if node.selected {
    NodeToolbar(position: .top) {
        HStack(spacing: 4) {
            Button("Delete") { deleteNode(node.id) }
            Button("Duplicate") { duplicateNode(node) }
            Button("Copy") { copyNode(node) }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
}
```

The toolbar is positioned relative to the node and rendered above the graph content.

---

## EdgeToolbar

A floating toolbar near a selected edge.

```swift
EdgeToolbar(isVisible: edge.selected, position: CGPoint(x: midX, y: midY)) {
    HStack(spacing: 4) {
        Button("Delete") { removeEdge(edge.id) }
        Button("Add Label") { addLabel(edge.id) }
    }
    .padding(6)
    .background(.ultraThinMaterial)
    .cornerRadius(6)
}
```

### Parameters

| Parameter  | Type      | Description                                   |
| ---------- | --------- | --------------------------------------------- |
| `isVisible`| `Bool`    | Whether the toolbar is shown                  |
| `position` | `CGPoint` | Position in canvas coordinates                |
| `content`  | ViewBuilder | Toolbar content                             |

---

## NodeResizer

Add resize handles to a node. Supports 8-directional resize with configurable constraints.

```swift
NodeResizer(
    nodeId: node.id,
    direction: .bottomRight,
    minWidth: 100,
    maxWidth: 500,
    minHeight: 50,
    maxHeight: 400
) { width, height in
    onNodesChange?([.dimensions(id: node.id, width: width, height: height)])
}
```

For a single resize handle with more control:

```swift
NodeResizeControl(
    nodeId: node.id,
    position: .bottomRight,
    minWidth: 100,
    maxWidth: 500,
    minHeight: 50,
    maxHeight: 400
) { width, height in
    onNodesChange?([.dimensions(id: node.id, width: width, height: height)])
}
```

---

## ViewportPortal

Renders content in flow (canvas) coordinate space, positioning it relative to nodes rather than the screen.

```swift
ViewportPortal(viewport: viewport) {
    Text("Annotation")
        .font(.caption)
        .padding(4)
        .background(.yellow.opacity(0.8))
        .cornerRadius(4)
        .position(x: 100, y: 200)
}
```

Content inside `ViewportPortal` is rendered in the scrolling/pannable layer, so it moves with the graph.

---

## EdgeLabelRenderer

Renders edge labels or interactive controls at a specific position on the canvas, automatically counter-scaling for zoom to maintain readable size.

```swift
EdgeLabelRenderer(position: CGPoint(x: midX, y: midY)) {
    Button("Delete") {
        removeEdge(edge.id)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.mini)
}
```

---

## EdgeText

A positioned text label for use within custom edge rendering, typically at the midpoint of an edge.

```swift
EdgeText(
    x: labelX,
    y: labelY,
    label: "42 requests/s",
    font: .system(size: 11),
    foregroundColor: .primary,
    showBackground: true,
    backgroundColor: .white
)
```

### Parameters

| Parameter                | Type        | Default                                   | Description                      |
| ------------------------ | ----------- | ----------------------------------------- | -------------------------------- |
| `x`                      | `CGFloat`   | —                                         | Horizontal position (canvas coords) |
| `y`                      | `CGFloat`   | —                                         | Vertical position (canvas coords)  |
| `label`                  | `String`    | —                                         | Text content                     |
| `font`                   | `Font`      | `.system(size: 11)`                       | Text font                        |
| `foregroundColor`        | `Color`     | `.primary`                                | Text color                       |
| `showBackground`         | `Bool`      | `true`                                    | Whether to show a background     |
| `backgroundColor`        | `Color`     | `.white`                                  | Background fill                  |
| `backgroundPadding`      | `EdgeInsets`| `EdgeInsets(top:2,leading:6,bottom:2,trailing:6)` | Padding inside background |
| `backgroundCornerRadius` | `CGFloat`   | `4`                                       | Background corner radius         |

The label is hit-test disabled by default (`.allowsHitTesting(false)`) so it doesn't interfere with edge selection gestures. When `showBackground` is `true`, a rounded rectangle with 90% opacity is rendered behind the text.

---

## ControlButton

A styled button for use inside `Controls` or custom panels.

```swift
ControlButton(action: { customAction() }) {
    Image(systemName: "gearshape")
        .font(.system(size: 14, weight: .medium))
}
```

### Parameters

| Parameter | Type         | Description             |
| --------- | ------------ | ----------------------- |
| `action`  | `() -> Void` | Tap action              |
| `content` | ViewBuilder  | Button content builder  |

---

## PanelPosition

All overlay components that accept a `position` parameter use `PanelPosition`:

| `.topLeft`     | `.topCenter`     | `.topRight`     |
| `.centerLeft`  | `.center`        | `.centerRight`  |
| `.bottomLeft`  | `.bottomCenter`  | `.bottomRight`  |

This 9-point grid matches standard SwiftUI alignment positions.
