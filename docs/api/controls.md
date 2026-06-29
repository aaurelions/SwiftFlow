# Controls

Zoom and fit-to-view control buttons for the SwiftFlow canvas.

## Basic Usage

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    MyNodeView(node: node)
} overlay: {
    Controls()
}
```

## Customization

```swift
// Zoom only (no fit button)
Controls(showZoom: true, showFitView: false)

// Fit only (no zoom buttons)
Controls(showZoom: false, showFitView: true)

// Different position
Controls(position: .bottomRight)

// With interactive toggle
Controls(showInteractive: true)
```

## Adding Custom Buttons

Extend Controls with your own buttons:

```swift
Controls(position: .bottomLeft) {
    Divider()
    ControlButton(action: {
        // Custom action
    }) {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 14, weight: .medium))
    }
}
```

Use `ControlButton` for consistent styling with the built-in zoom buttons.

## Parameters

| Property          | Type            | Default       | Description                                    |
| ----------------- | --------------- | ------------- | ---------------------------------------------- |
| `showZoom`        | `Bool`          | `true`        | Show zoom in/out buttons and zoom percentage   |
| `showFitView`     | `Bool`          | `true`        | Show fit-to-view button                        |
| `showInteractive` | `Bool`          | `false`       | Show interactive mode toggle                   |
| `position`        | `PanelPosition` | `.bottomLeft` | Panel position on canvas                       |
| `children`        | `() -> Children`| `EmptyView()` | ViewBuilder for additional custom buttons      |

## PanelPosition Values

| `.topLeft`     | `.topCenter`     | `.topRight`     |
| `.centerLeft`  | `.center`        | `.centerRight`  |
| `.bottomLeft`  | `.bottomCenter`  | `.bottomRight`  |

## How It Works

Controls reads viewport state from the `SwiftFlowState` environment object and applies changes through it. The zoom buttons call `zoomIn()`, `zoomOut()`, and `zoomTo(1.0)` on the state, while the fit button calls `fitView()`.

The zoom percentage display shows the current zoom level as an integer percentage (e.g., "100%" at default zoom).

## Styling

Controls are rendered with a `.ultraThinMaterial` background, 8pt corner radius, and a subtle gray border. The panel is `fixedSize()` so it doesn't expand to fill the canvas.
