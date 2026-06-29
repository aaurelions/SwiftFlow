# Background

A configurable background pattern for the SwiftFlow canvas. Renders a dot, line, or cross pattern that tracks with viewport pan and zoom.

## Basic Usage

```swift
SwiftFlow(nodes: nodes, edges: edges, ...) { node in
    MyNodeView(node: node)
} overlay: {
    Background(variant: .dots)
}
```

## Variants

```swift
// Dot grid (default)
Background(variant: .dots)

// Line grid
Background(variant: .lines)

// Cross-hair pattern
Background(variant: .cross)
```

## Customization

```swift
// Custom color and spacing
Background(
    variant: .dots,
    color: .blue.opacity(0.15),
    gap: 25,
    size: 2
)

// Dense dot grid
Background(variant: .dots, gap: 10, size: 1, color: .gray.opacity(0.2))

// Light grid lines
Background(variant: .lines, color: .gray.opacity(0.15), gap: 50)
```

## Layering Multiple Backgrounds

Use `id` to layer multiple background patterns:

```swift
overlay: {
    // Small dense dots
    Background(id: "small-grid", variant: .dots, gap: 10, size: 0.5, color: .gray.opacity(0.1))

    // Large grid lines on top
    Background(id: "large-grid", variant: .lines, gap: 100, color: .gray.opacity(0.15))
}
```

## Parameters

| Parameter | Type                | Default              | Description                          |
| --------- | ------------------- | -------------------- | ------------------------------------ |
| `id`      | `String?`           | `nil`                | Identifier for layering backgrounds  |
| `variant` | `BackgroundVariant` | `.dots`              | Pattern type                         |
| `color`   | `Color`             | `.gray.opacity(0.3)` | Pattern color                        |
| `gap`     | `CGFloat`           | `20`                 | Spacing between pattern elements     |
| `size`    | `CGFloat`           | `1.5`                | Size of elements (dots/crosses)      |

## BackgroundVariant

| Value   | Description                            |
| ------- | -------------------------------------- |
| `.dots` | Regular dot grid pattern               |
| `.lines`| Horizontal and vertical line grid      |
| `.cross`| Cross-hair pattern at each intersection|

## Performance

Background patterns are rendered using SwiftUI `Canvas` for efficient GPU-accelerated drawing. The pattern recalculates on viewport changes (pan and zoom) to maintain consistent spacing in screen coordinates.

## Built-in Background (Legacy)

For backward compatibility, SwiftFlow also accepts a `backgroundVariant` parameter directly on the canvas:

```swift
SwiftFlow(
    nodes: nodes, edges: edges, ...,
    backgroundVariant: .dots
) { node in ... }
```

Using the overlay `Background` component is preferred as it supports layering and more customization.
