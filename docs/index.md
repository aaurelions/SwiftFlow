---
layout: home

hero:
  name: SwiftFlow
  text: SwiftUI Node Graph Editor
  tagline: Build interactive flow diagrams, workflow editors, mind maps, and visual programming interfaces on iOS and macOS.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: API Reference
      link: /api/swiftflow-canvas

features:
  - icon: 🎨
    title: Interactive Canvas
    details: Pan, zoom (scroll, pinch, double-click), and navigate with keyboard shortcuts. Selection box with partial or full containment modes.
  - icon: 🔗
    title: Node Connections
    details: Connect nodes by dragging from handles. Supports bezier, straight, step, smoothstep, and simplebezier edge types with markers, labels, and animation.
  - icon: 🧩
    title: Customizable Nodes
    details: Bring your own SwiftUI views via @ViewBuilder. Each node carries generic data, custom styling, and interactive properties.
  - icon: 🧭
    title: Overlay Components
    details: Background patterns (dots, lines, cross), minimap with viewport tracking, zoom controls, floating toolbars, and positional panels.
  - icon: ♻️
    title: Undo / Redo
    details: Built-in undo/redo stack on macOS with Cmd+Z and Cmd+Shift+Z. Copy/paste with automatic ID remapping.
  - icon: 📐
    title: Auto Layout
    details: Tree (hierarchical), force-directed, and grid layout algorithms. Async computation for large graphs with 50+ nodes.
  - icon: 💾
    title: Serialization
    details: JSON import/export with Codable support. Serialize and restore complete graph state including viewport position.
  - icon: ♿
    title: Accessible
    details: VoiceOver labels, keyboard navigation, and configurable accessibility announcements for selection and connection events.
  - icon: 🎯
    title: ReactFlow Compatible Design
    details: ReactFlow concepts and utility semantics adapted for SwiftUI conventions and native platform behavior.
---

## Quick Start

```swift
import SwiftUI
import SwiftFlow

struct ContentView: View {
    @State var nodes: [Node<String>] = [
        Node(id: "1", position: XYPosition(x: 0, y: 0), data: "Input"),
        Node(id: "2", position: XYPosition(x: 250, y: 100), data: "Output"),
    ]
    @State var edges: [FlowEdge<EmptyEdgeData>] = [
        FlowEdge(id: "e1-2", source: "1", target: "2"),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) }
        ) { node in
            Text(node.data)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))
        } overlay: {
            Background(variant: .dots)
            Controls()
            MiniMap()
        }
    }
}
```

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 16.0+           |
| macOS    | 13.0+           |
| Swift    | 6.2+            |

SwiftFlow is a **zero-dependency** library — pure SwiftUI, no third-party packages.

---

## What You Can Build

![AI Flow — an interactive workflow editor built with SwiftFlow](/screenshot.png)

*An AI request flow editor with classified outputs, built in under 150 lines of SwiftUI.* See the full [AI Flow example](/examples/ai-flow) for source code and setup instructions.
