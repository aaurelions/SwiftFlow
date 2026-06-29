# SwiftFlowInstance

Programmatic controller for the canvas viewport and graph state queries. `SwiftFlowInstance` is an `ObservableObject` that provides imperative control over the viewport, coordinate conversion, and bounds calculation.

## Basic Setup

```swift
@StateObject var instance = SwiftFlowInstance()

SwiftFlow(
    nodes: nodes, edges: edges,
    swiftFlowInstance: instance, ...
) { node in ... }
```

## Published Properties

| Property     | Type                | Description                           |
| ------------ | ------------------- | ------------------------------------- |
| `viewport`   | `Viewport`          | Current viewport (pan + zoom) state   |
| `viewSize`   | `CGSize`            | Size of the canvas view in points     |
| `nodeSizes`  | `[String: CGSize]`  | Map of node ID to measured dimensions |

## Viewport Control

### getViewport()

```swift
public func getViewport() -> Viewport
```

Returns the current viewport state.

### setViewport(\_:animated:)

```swift
public func setViewport(_ vp: Viewport, animated: Bool = true)
```

Sets the viewport directly. When `animated` is `true`, transitions with a 0.3s ease-in-out animation.

```swift
instance.setViewport(Viewport(x: -100, y: -50, zoom: 1.5))
instance.setViewport(Viewport(x: 0, y: 0, zoom: 1), animated: false)
```

### fitView(nodes:nodeSizes:options:)

```swift
public func fitView<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize],
    options: FitViewOptions = FitViewOptions()
)
```

Adjusts the viewport to frame all (or specific) nodes. Uses `FitViewOptions` for configuration.

```swift
// Fit all visible nodes
instance.fitView(nodes: nodes, nodeSizes: instance.nodeSizes)

// Fit specific nodes with options
instance.fitView(
    nodes: nodes,
    nodeSizes: instance.nodeSizes,
    options: FitViewOptions(padding: 100, maxZoom: 2.0, duration: 0.8)
)
```

### setCenter(x:y:zoom:animated:)

```swift
public func setCenter(x: CGFloat, y: CGFloat, zoom: CGFloat? = nil, animated: Bool = true)
```

Centers the viewport on a canvas coordinate. If `zoom` is `nil`, preserves the current zoom level.

```swift
instance.setCenter(x: 250, y: 150)
instance.setCenter(x: 250, y: 150, zoom: 1.5)
```

### zoomTo(\_:animated:)

```swift
public func zoomTo(_ zoom: CGFloat, animated: Bool = true)
```

Sets the zoom level, preserving the current center point. Zoom is clamped to `[Viewport.minZoom, Viewport.maxZoom]`.

```swift
instance.zoomTo(1.5)
instance.zoomTo(2.0, animated: false)
```

### zoomIn / zoomOut

```swift
public func zoomIn(animated: Bool = true)
public func zoomOut(animated: Bool = true)
```

Zoom in/out by 25% relative to the current zoom level.

```swift
instance.zoomIn()
instance.zoomOut()
instance.zoomIn(animated: false)
```

### reset(animated:)

```swift
public func reset(animated: Bool = true)
```

Resets the viewport to identity (`x: 0, y: 0, zoom: 1.0`).

```swift
instance.reset()
instance.reset(animated: false)
```

## Coordinate Conversion

### screenToFlowPosition(\_:)

```swift
public func screenToFlowPosition(_ screenPoint: CGPoint) -> CGPoint
```

Converts a screen-space point to flow (canvas) coordinates, accounting for current pan and zoom.

```swift
let dropPoint = instance.screenToFlowPosition(CGPoint(x: 300, y: 200))
// Create a node at the drop position
let newNode = Node(id: UUID().uuidString, position: XYPosition(x: dropPoint.x, y: dropPoint.y), data: ...)
```

### flowToScreenPosition(\_:)

```swift
public func flowToScreenPosition(_ flowPoint: CGPoint) -> CGPoint
```

Converts a flow (canvas) coordinate to a screen-space position.

```swift
let screenPos = instance.flowToScreenPosition(CGPoint(x: node.position.x, y: node.position.y))
// Position a popover at screenPos
```

## Bounds Calculation

### getNodesBounds(nodes:nodeSizes:)

```swift
public func getNodesBounds<T: Equatable & Sendable>(
    nodes: [Node<T>],
    nodeSizes: [String: CGSize]
) -> CGRect
```

Returns the bounding rectangle of the given nodes, respecting their measured sizes.

```swift
let bounds = instance.getNodesBounds(nodes: selectedNodes, nodeSizes: instance.nodeSizes)
print("Width: \(bounds.width), Height: \(bounds.height)")
```

### getViewportForBounds(bounds:minZoom:maxZoom:padding:)

```swift
public func getViewportForBounds(
    bounds: CGRect,
    minZoom: CGFloat = Viewport.minZoom,
    maxZoom: CGFloat = Viewport.maxZoom,
    padding: CGFloat = 80
) -> Viewport
```

Computes the optimal viewport to display the given bounding rectangle.

```swift
let bounds = instance.getNodesBounds(nodes: nodes, nodeSizes: instance.nodeSizes)
let optimalViewport = instance.getViewportForBounds(
    bounds: bounds,
    minZoom: 0.5,
    maxZoom: 2.0,
    padding: 100
)
instance.setViewport(optimalViewport)
```

## Viewport Change Callback

```swift
instance.onViewportChange = { viewport in
    print("Viewport changed: \(viewport)")
}
```

## Environment Access

Access the instance from child views via the environment:

```swift
struct CustomNodeView: View {
    let node: Node<MyData>
    @Environment(\.swiftFlowInstance) var instance

    var body: some View {
        VStack {
            Text(node.data.label)
            Button("Focus") {
                instance?.setCenter(x: node.position.x, y: node.position.y, zoom: 1.5)
            }
        }
    }
}
```
