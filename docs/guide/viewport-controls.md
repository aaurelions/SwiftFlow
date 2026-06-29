# Viewport Controls

SwiftFlow provides programmatic control over the canvas viewport via `SwiftFlowInstance`. This gives you imperative access to fit-to-view, zoom, pan, and coordinate conversion.

## Basic Setup

Create a `SwiftFlowInstance` and pass it to the canvas:

```swift
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(
    nodes: nodes, edges: edges,
    swiftFlowInstance: instance, ...
) { node in ... }
```

## Fit View

Adjust the viewport to show all (or specific) nodes:

```swift
// Fit all visible nodes
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)

// Fit specific nodes
let options = FitViewOptions(
    padding: 80,
    maxZoom: 1.5,
    duration: 0.5,
    nodeIds: ["node-1", "node-2"]
)
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes, options: options)
```

`FitViewOptions` parameters:

| Parameter           | Type           | Default           | Description                           |
| ------------------- | -------------- | ----------------- | ------------------------------------- |
| `padding`           | `CGFloat`      | `80`              | Padding around fitted content (pts)   |
| `includeHiddenNodes`| `Bool`         | `false`           | Include hidden nodes in bounds calc   |
| `minZoom`           | `CGFloat`      | `Viewport.minZoom`| Minimum zoom after fitting            |
| `maxZoom`           | `CGFloat`      | `1.5`             | Maximum zoom after fitting            |
| `duration`          | `TimeInterval?`| `0.3`             | Animation duration; `nil` = instant   |
| `nodeIds`           | `[String]?`    | `nil`             | Specific nodes to fit; `nil` = all    |

## Zoom Control

```swift
// Zoom in by 25%
instance.zoomIn()

// Zoom out by 25%
instance.zoomOut()

// Set exact zoom level (preserves center)
instance.zoomTo(1.5)

// Set zoom (with or without animation)
instance.zoomTo(2.0, animated: true)
```

## Pan / Center

Center the viewport on a specific canvas coordinate:

```swift
// Center on a point at the current zoom level
instance.setCenter(x: 250, y: 150)

// Center on a point at a specific zoom level
instance.setCenter(x: 250, y: 150, zoom: 1.5, animated: true)
```

## Direct Viewport Manipulation

Get and set the viewport directly:

```swift
// Read current viewport
let currentVp = instance.getViewport()
print("x: \(currentVp.x), y: \(currentVp.y), zoom: \(currentVp.zoom)")

// Set viewport directly
instance.setViewport(Viewport(x: -100, y: -50, zoom: 1.2))

// Set without animation
instance.setViewport(Viewport(x: 0, y: 0, zoom: 1.0), animated: false)
```

## Reset

Reset the viewport to identity (origin at 100% zoom):

```swift
instance.reset()
instance.reset(animated: false)
```

## Coordinate Conversion

Convert between screen and flow (canvas) coordinates:

```swift
// Screen point to flow coordinates (considering current pan/zoom)
let screenPoint = CGPoint(x: 300, y: 200)
let flowPosition = instance.screenToFlowPosition(screenPoint)

// Flow coordinate to screen position
let screenPosition = instance.flowToScreenPosition(CGPoint(x: 100, y: 100))
```

This is useful for placing elements at canvas positions from screen-space interactions (e.g., dropping a new node from a palette).

## Bounds Calculation

Get the bounding rectangle of nodes:

```swift
let bounds = instance.getNodesBounds(nodes: nodes, nodeSizes: instance.nodeSizes)
// bounds is a CGRect: (x, y, width, height)
```

Compute the optimal viewport for given bounds:

```swift
let bounds = instance.getNodesBounds(nodes: selectedNodes, nodeSizes: instance.nodeSizes)
let optimalViewport = instance.getViewportForBounds(
    bounds: bounds,
    minZoom: 0.5,
    maxZoom: 2.0,
    padding: 100
)
instance.setViewport(optimalViewport)
```

## Accessing from Child Views

Pass the instance through the SwiftUI environment:

```swift
struct MyNodeView: View {
    let node: Node<MyData>
    @Environment(\.swiftFlowInstance) var instance

    var body: some View {
        VStack {
            Text(node.data.label)
            Button("Center Here") {
                instance?.setCenter(x: node.position.x, y: node.position.y, zoom: 1)
            }
        }
    }
}
```

## Listening to Viewport Changes

Track viewport changes reactively:

```swift
@StateObject var instance = SwiftFlowInstance()

// In onAppear or Task
instance.onViewportChange = { viewport in
    print("Viewport: x=\(viewport.x), y=\(viewport.y), zoom=\(viewport.zoom)")
}
```

Alternatively, use the `onViewportChange` callback on `SwiftFlow`:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    onViewportChange: { viewport in
        saveViewport(viewport)
    }
) { ... }
```

## Auto-Fit on Load

Use the `fitView` parameter on `SwiftFlow` to auto-fit all nodes on first render:

```swift
SwiftFlow(nodes: nodes, edges: edges, ...,
    fitView: true,
    fitViewOptions: FitViewOptions(padding: 80, maxZoom: 1.5, duration: 0.5)
) { ... }
```

## Complete Example

```swift
struct ViewportControlsExample: View {
    @State var nodes: [Node<String>] = [...]
    @StateObject var instance = SwiftFlowInstance()

    var body: some View {
        VStack(spacing: 0) {
            // Viewport control toolbar
            HStack {
                Button("Fit All") {
                    instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)
                }
                Button("Zoom In") { instance.zoomIn() }
                Button("Zoom Out") { instance.zoomOut() }
                Button("Reset") { instance.reset() }
                Spacer()
                Text("Zoom: \(String(format: "%.0f%%", instance.viewport.zoom * 100))")
                    .font(.caption.monospaced())
            }
            .padding()
            .background(.ultraThinMaterial)

            SwiftFlow(
                nodes: nodes, edges: edges,
                swiftFlowInstance: instance, ...
            ) { node in
                Text(node.data).padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white))
            }
        }
    }
}
```
