# Theming

SwiftFlow provides a comprehensive theming system for customizing the visual appearance of the entire canvas.

## Using Preset Themes

Three built-in themes are available:

```swift
// Light theme (default)
SwiftFlow(nodes: nodes, edges: edges, ..., theme: .default) { ... }

// Dark theme
SwiftFlow(nodes: nodes, edges: edges, ..., theme: .dark) { ... }

// Explicit light theme
SwiftFlow(nodes: nodes, edges: edges, ..., theme: .light) { ... }
```

## Creating Custom Themes

Create a `SwiftFlowTheme` instance with your own values:

```swift
let customTheme = SwiftFlowTheme(
    edgeColor: .blue.opacity(0.6),
    edgeSelectedColor: .cyan,
    edgeWidth: 2.5,
    edgeSelectedWidth: 4,
    nodeBackgroundColor: .white,
    nodeSelectedBorderColor: .blue,
    nodeSelectedBorderWidth: 2,
    handleColor: .orange,
    handleBorderColor: .white,
    handleSize: 14,
    selectionBoxColor: .blue.opacity(0.1),
    selectionBoxBorderColor: .blue.opacity(0.5),
    canvasBackgroundColor: .clear,
    gridColor: .gray.opacity(0.2),
    gridSpacing: 25,
    minimapBackgroundOpacity: 0.9,
    minimapNodeColor: .blue.opacity(0.3),
    minimapSelectedNodeColor: .cyan,
    snapLineColor: .cyan.opacity(0.5),
    snapLineWidth: 1,
    edgeLabelFont: .system(size: 12, weight: .medium),
    edgeLabelColor: .white,
    edgeLabelBackgroundColor: Color(white: 0.15)
)

SwiftFlow(nodes: nodes, edges: edges, ..., theme: customTheme) { ... }
```

## Modifying an Existing Theme

You can start from a preset and selectively override properties:

```swift
var theme = SwiftFlowTheme.dark
theme.edgeColor = .mint.opacity(0.5)
theme.edgeSelectedColor = .mint
theme.nodeSelectedBorderColor = .mint
theme.selectionBoxColor = .mint.opacity(0.1)
theme.selectionBoxBorderColor = .mint.opacity(0.5)

SwiftFlow(nodes: nodes, edges: edges, ..., theme: theme) { ... }
```

## Theme Properties Reference

### Edges

| Property            | Type     | Default (Light)          | Description                  |
| ------------------- | -------- | ------------------------ | ---------------------------- |
| `edgeColor`         | `Color`  | `.gray.opacity(0.6)`     | Unselected edge stroke color |
| `edgeSelectedColor` | `Color`  | `.blue`                  | Selected edge stroke color   |
| `edgeWidth`         | `CGFloat`| `2`                      | Unselected edge stroke width |
| `edgeSelectedWidth` | `CGFloat`| `3`                      | Selected edge stroke width   |

### Nodes

| Property                  | Type     | Default          | Description                  |
| ------------------------- | -------- | ---------------- | ---------------------------- |
| `nodeBackgroundColor`     | `Color`  | `.white`         | Default node background      |
| `nodeSelectedBorderColor` | `Color`  | `.blue`          | Selected node border color   |
| `nodeSelectedBorderWidth` | `CGFloat`| `2`              | Selected node border width   |

### Handles

| Property            | Type     | Default  | Description            |
| ------------------- | -------- | -------- | ---------------------- |
| `handleColor`       | `Color`  | `.gray`  | Handle fill color      |
| `handleBorderColor` | `Color`  | `.white` | Handle border color    |
| `handleSize`        | `CGFloat`| `12`     | Handle diameter        |

### Selection

| Property                   | Type     | Default               | Description               |
| -------------------------- | -------- | --------------------- | ------------------------- |
| `selectionBoxColor`        | `Color`  | `.blue.opacity(0.1)`  | Selection box fill        |
| `selectionBoxBorderColor`  | `Color`  | `.blue.opacity(0.5)`  | Selection box border      |

### Canvas

| Property               | Type     | Default              | Description                    |
| ---------------------- | -------- | -------------------- | ------------------------------ |
| `canvasBackgroundColor`| `Color`  | `.clear`             | Canvas background fill         |
| `gridColor`            | `Color`  | `.gray.opacity(0.3)` | Background pattern color       |
| `gridSpacing`          | `CGFloat`| `20`                 | Background pattern gap         |

### MiniMap

| Property                  | Type     | Default              | Description                 |
| ------------------------- | -------- | -------------------- | --------------------------- |
| `minimapBackgroundOpacity`| `CGFloat`| `0.9`                | Minimap background opacity  |
| `minimapNodeColor`        | `Color`  | `.gray.opacity(0.5)` | Default node color in minimap |
| `minimapSelectedNodeColor`| `Color`  | `.blue`              | Selected node color in minimap |

### Snap Lines

| Property        | Type     | Default               | Description          |
| --------------- | -------- | --------------------- | -------------------- |
| `snapLineColor` | `Color`  | `.blue.opacity(0.5)`  | Snap guide color     |
| `snapLineWidth` | `CGFloat`| `1`                   | Snap guide width     |

### Edge Labels

| Property                  | Type     | Default                      | Description              |
| ------------------------- | -------- | ---------------------------- | ------------------------ |
| `edgeLabelFont`           | `Font`   | `.system(size: 11)`          | Edge label font          |
| `edgeLabelColor`          | `Color`  | `.primary`                   | Edge label text color    |
| `edgeLabelBackgroundColor`| `Color`  | `Color(white: 0.2)`          | Edge label background    |

## ColorMode

The `colorMode` parameter controls which color scheme is used by SwiftFlow components:

```swift
// Follow system appearance (default)
SwiftFlow(..., colorMode: .system) { ... }

// Force light mode
SwiftFlow(..., colorMode: .light) { ... }

// Force dark mode
SwiftFlow(..., colorMode: .dark) { ... }
```

| Value     | Description                     |
| --------- | ------------------------------- |
| `.light`  | Light mode colors               |
| `.dark`   | Dark mode colors                |
| `.system` | Follows system appearance       |

## Node-Level Styling

Individual nodes and edges can override theme defaults via their `style` property:

### NodeStyle

```swift
let styledNode = Node(
    id: "styled",
    position: XYPosition(x: 100, y: 100),
    data: "Custom",
    style: NodeStyle(
        backgroundColor: .orange.opacity(0.2),
        borderColor: .orange,
        borderWidth: 2,
        borderRadius: 12,
        opacity: 0.9
    )
)
```

| Property        | Type      | Description                              |
| --------------- | --------- | ---------------------------------------- |
| `backgroundColor`| `Color?`  | Node fill color (overrides theme)        |
| `borderColor`   | `Color?`  | Node border color (overrides theme)      |
| `borderWidth`   | `CGFloat?`| Node border width (overrides theme)      |
| `borderRadius`  | `CGFloat?`| Node corner radius                       |
| `opacity`       | `Double?` | Node opacity                             |

### EdgeStyle

```swift
let styledEdge = Edge(
    id: "styled-edge",
    source: "1", target: "2",
    style: EdgeStyle(
        strokeColor: .purple,
        strokeWidth: 3,
        opacity: 0.8
    )
)
```

| Property      | Type      | Description                              |
| ------------- | --------- | ---------------------------------------- |
| `strokeColor` | `Color?`  | Edge stroke color (overrides theme)      |
| `strokeWidth` | `CGFloat?`| Edge stroke width (overrides theme)      |
| `opacity`     | `Double?` | Edge opacity                             |
