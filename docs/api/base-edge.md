# BaseEdge

A building block for creating custom edge views. `BaseEdge` renders a path with configurable stroke style, and optionally displays a label at the midpoint.

## Basic Usage

```swift
BaseEdge(path: path, color: .red, width: 3, label: "Error")
```

Use `BaseEdge` inside `edgeContent` when you need custom edge rendering with label support:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    edgeContent: { edge, pathResult in
        AnyView(
            BaseEdge(
                pathResult: pathResult,
                color: edge.selected ? .cyan : .gray.opacity(0.6),
                width: edge.selected ? 3 : 2,
                animated: edge.animated,
                label: edge.label
            )
        )
    }
) { node in ... }
```

## Parameters

| Parameter        | Type       | Default              | Description                              |
| ---------------- | ---------- | -------------------- | ---------------------------------------- |
| `path`           | `Path`     | —                    | The path to stroke                       |
| `color`          | `Color`    | `.gray.opacity(0.6)` | Stroke color                             |
| `width`          | `CGFloat`  | `2`                  | Stroke width                             |
| `animated`       | `Bool`     | `false`              | Enable animated dash pattern             |
| `dashPhase`      | `CGFloat`  | `0`                  | Dash phase offset for animation          |
| `label`          | `String?`  | `nil`                | Text label at midpoint                   |
| `labelPosition`  | `CGPoint?` | `nil`                | Position for the label; `nil` = auto mid |
| `labelFont`      | `Font`     | `.system(size: 11)`  | Label font                               |
| `labelColor`     | `Color`    | `.primary`           | Label text color                         |
| `labelBackground`| `Color`    | `.white`             | Label background color                   |

## EdgePathResult Convenience Init

`BaseEdge` also accepts an `EdgePathResult` directly, automatically using the computed label position:

```swift
let result = getEdgePathResult(
    type: .bezier,
    sourceX: sPos.x, sourceY: sPos.y,
    targetX: tPos.x, targetY: tPos.y
)

BaseEdge(
    pathResult: result,
    color: .blue,
    width: 2,
    label: edge.label
)
```

## Custom Edge Rendering with BaseEdge

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    edgeContent: { edge, pathResult in
        AnyView(
            ZStack {
                // Glow layer for selected edges
                if edge.selected {
                    pathResult.path.stroke(
                        .blue.opacity(0.15),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                    )
                }

                // Main edge
                BaseEdge(
                    pathResult: pathResult,
                    color: edge.selected ? .cyan : .gray,
                    width: edge.selected ? 3 : 2,
                    animated: edge.animated,
                    label: edge.label,
                    labelFont: .system(size: 10, weight: .medium),
                    labelColor: .white,
                    labelBackground: Color(white: 0.2)
                )
            }
        )
    }
) { node in ... }
```

## How It Compares to Built-in Edges

The built-in edge rendering (when `edgeContent` is `nil`) uses the theme's `edgeColor`, `edgeSelectedColor`, `edgeWidth`, and `edgeSelectedWidth` properties. `BaseEdge` gives you full control — use it when you need:

- Custom colors per edge type
- Layered effects (glows, shadows)
- Custom label fonts or backgrounds
- Gradients or animated strokes beyond simple dash patterns

---

## EdgeText

A positioned text label for use within custom edge rendering, typically at the midpoint of an edge.

```swift
EdgeText(x: labelX, y: labelY, label: "42 requests/s")
```

### Parameters

| Parameter                | Type        | Default                                               | Description                    |
| ------------------------ | ----------- | ----------------------------------------------------- | ------------------------------ |
| `x`                      | `CGFloat`   | —                                                     | Horizontal position (canvas coords) |
| `y`                      | `CGFloat`   | —                                                     | Vertical position (canvas coords)   |
| `label`                  | `String`    | —                                                     | Text content                   |
| `font`                   | `Font`      | `.system(size: 11)`                                   | Text font                      |
| `foregroundColor`        | `Color`     | `.primary`                                            | Text color                     |
| `showBackground`         | `Bool`      | `true`                                                | Whether to show background     |
| `backgroundColor`        | `Color`     | `.white`                                              | Background fill                |
| `backgroundPadding`      | `EdgeInsets`| `EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)` | Padding inside background |
| `backgroundCornerRadius` | `CGFloat`   | `4`                                                   | Background corner radius       |

`EdgeText` is hit-test disabled by default to avoid interfering with edge selection gestures.
