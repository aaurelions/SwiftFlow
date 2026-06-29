# Types Reference

Complete reference of all public types in SwiftFlow.

## Core Types

| Type                      | Description                                             |
| ------------------------- | ------------------------------------------------------- |
| `Node<NodeData>`          | Graph node with generic data                            |
| `Edge<EdgeData>`          | Graph edge with generic data                            |
| `FlowEdge`                | Type alias for `Edge` (avoids `SwiftUI.Edge` ambiguity) |
| `EmptyEdgeData`           | Empty data type for edges without custom data           |
| `Connection`              | Pending connection between handles                      |
| `Viewport`                | Camera state (pan + zoom)                               |
| `XYPosition`              | 2D coordinate                                           |
| `InternalNode<T>`         | Extended node with computed layout                      |

## Handle Types

| Type            | Description                                           |
| --------------- | ----------------------------------------------------- |
| `HandleType`    | `.source` or `.target`                                |
| `Position`      | Handle position: `.top`, `.bottom`, `.left`, `.right` |
| `NodeHandle`    | Explicit handle position and dimensions               |

## Edge Types

| Type                | Description                        |
| ------------------- | ---------------------------------- |
| `EdgeType`          | `.default`, `.bezier`, `.straight`, `.step`, `.smoothstep`, `.simplebezier` |
| `EdgeMarker`        | Endpoint marker configuration      |
| `MarkerType`        | `.arrow` or `.arrowClosed`         |
| `EdgePathResult`    | Path + label position result       |
| `ConnectionLineType`| Type alias for `EdgeType`          |
| `EdgeStyle`         | Per-edge visual overrides          |

## Change Types

| Type              | Cases                                                              |
| ----------------- | ------------------------------------------------------------------ |
| `NodeChange<T>`   | `.position`, `.selection`, `.remove`, `.add`, `.dimensions`, `.replace` |
| `EdgeChange<E>`   | `.selection`, `.remove`, `.add`, `.replace`                        |

## State Management

| Type                        | Description                                      |
| --------------------------- | ------------------------------------------------ |
| `SwiftFlowStore<N, E>`      | Centralized state management ObservableObject     |
| `SwiftFlowProvider<N, E, Content>` | View wrapper providing store to environment |
| `SwiftFlowState`           | Internal canvas state (injected via environment)  |
| `SwiftFlowInstance`        | Programmatic viewport and graph control           |
| `AnyNodeSnapshot`          | Type-erased node snapshot for overlays            |
| `AnyEdgeSnapshot`          | Type-erased edge snapshot for overlays            |
| `ConnectionState`          | In-progress connection drag state                 |

## Component Types

| Type                | Description                          |
| ------------------- | ------------------------------------ |
| `PanelPosition`     | 9-position enum for overlay placement|
| `BackgroundVariant` | `.dots`, `.lines`, `.cross`          |
| `MiniMapNodeProps`  | Properties for custom MiniMap nodes  |
| `ResizeDirection`   | 8-direction resize handle placement  |
| `ControlButton`     | Styled button for Controls panel     |
| `EdgeText`          | Positioned edge label with background|

## Configuration Types

| Type                  | Description                                    |
| --------------------- | ---------------------------------------------- |
| `SwiftFlowTheme`      | Comprehensive theme with presets               |
| `FitViewOptions`      | Fit-view animation and constraint configuration|
| `DefaultEdgeOptions`  | Default properties for newly created edges     |
| `KeyboardShortcuts`   | Key codes and nudge distances                  |
| `AccessibilityConfig` | VoiceOver behavior and label texts             |
| `NodeStyle`           | Per-node visual overrides                      |
| `EdgeStyle`           | Per-edge visual overrides                      |

## Constraint Types

| Type                | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `CoordinateExtent`  | Boundary constraints for dragging                    |
| `NodeExtent`        | `.parent` or `.coordinateExtent(CoordinateExtent)`   |
| `NodeOrigin`        | Node anchor point (0–1 normalized)                   |

## Mode Enums

| Type               | Values                                  | Description                       |
| ------------------ | --------------------------------------- | --------------------------------- |
| `SelectionMode`    | `.partial`, `.full`                     | Selection box containment mode    |
| `ConnectionMode`   | `.strict`, `.loose`                     | Handle connection validation      |
| `ColorMode`        | `.light`, `.dark`, `.system`            | Color scheme                      |
| `ZIndexMode`       | `.auto`, `.basic`, `.manual`            | Z-ordering strategy               |
| `PanOnScrollMode`  | `.free`, `.vertical`, `.horizontal`     | Scroll panning direction          |

## Event Types

| Type                  | Description                                     |
| --------------------- | ----------------------------------------------- |
| `IsValidConnection`   | Type alias: `(Connection) -> Bool`              |
| `OnConnectStartParams`| Connection start event data                     |
| `BeforeDeleteResult`  | `.cancel` or `.delete(nodes: [Node], edges: [Edge])` |

## Layout Types

| Type              | Values                                              |
| ----------------- | --------------------------------------------------- |
| `LayoutAlgorithm` | `.tree(...)`, `.forceDirected(...)`, `.grid(...)`   |
| `LayoutDirection` | `.topToBottom`, `.bottomToTop`, `.leftToRight`, `.rightToLeft` |

## Serialization Types

| Type                          | Description                      |
| ----------------------------- | -------------------------------- |
| `SwiftFlowDocument<N, E>`     | Serializable graph snapshot      |

## Utility Types

| Type              | Description                                 |
| ----------------- | ------------------------------------------- |
| `KeyCode`         | Platform-agnostic key code with named constants |
| `Rect`            | Type alias for `CGRect`                     |
| `SnapLine`        | Internal type for snap alignment guides     |

## Generic Constraints

All generic types in SwiftFlow follow these protocol requirements:

| Generic       | Required Conformance                         |
| ------------- | -------------------------------------------- |
| `NodeData`    | `Equatable & Sendable`                       |
| `EdgeData`    | `Equatable & Sendable & Hashable`            |

For `Codable` support (serialization), both types must additionally conform to `Codable`.
