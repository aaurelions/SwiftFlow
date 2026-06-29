# Installation

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 16.0+           |
| macOS    | 13.0+           |
| Swift    | 6.2+            |

SwiftFlow is a **zero-dependency** library — pure SwiftUI, no third-party packages required.

## Swift Package Manager

### Via Xcode

1. Open your project in Xcode.
2. Select **File > Add Package Dependencies...**
3. Enter the SwiftFlow repository URL.
4. Choose version rules and add to your target.

### Via Package.swift

For local development with the demo package checked out beside your app, add SwiftFlow as a path dependency in your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    dependencies: [
        .package(path: "../SwiftFlow"),
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "SwiftFlow", package: "SwiftFlow"),
            ]
        ),
    ]
)
```

## Import

After adding the dependency, import SwiftFlow in any file that uses it:

```swift
import SwiftFlow
```

The `FlowEdge` type alias is also available to avoid ambiguity with SwiftUI's built-in `Edge` type:

```swift
// Use FlowEdge when the compiler can't disambiguate:
let edges: [FlowEdge<EmptyEdgeData>] = [
    FlowEdge(id: "e1", source: "1", target: "2")
]

// Or use the qualified form when declaring a concrete array:
let qualifiedEdges: [SwiftFlow.Edge<EmptyEdgeData>] = [
    SwiftFlow.Edge(id: "e2", source: "2", target: "3")
]
```

## Platform Notes

### macOS

Full keyboard shortcut support including:
- **Cmd+A**: Select all
- **Cmd+C / Cmd+V**: Copy / paste nodes
- **Cmd+Z / Cmd+Shift+Z**: Undo / redo
- **Delete / Backspace**: Delete selected
- **Arrow keys**: Nudge selected nodes (hold Shift for 10pt stepping)
- Right-click context menus via `onNodeContextMenu` / `onEdgeContextMenu`

### iOS

Keyboard shortcuts are limited on iOS. Primarily designed for touch interaction:
- Tap to select nodes and edges
- Drag to move nodes
- Pinch to zoom
- Long-press triggers context menu callbacks
- Hover events (`onNodeMouseEnter`, `onNodeMouseLeave`) are not available

## Next Steps

Once installed, follow the **[Getting Started](/guide/getting-started)** guide to create your first graph.
