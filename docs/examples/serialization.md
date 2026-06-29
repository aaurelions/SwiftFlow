# Serialization Example

Demonstrates full graph serialization: JSON export, import, file save/load, clipboard copy/paste, and data model design for Codable support.

```swift
import SwiftUI
import SwiftFlow
import UniformTypeIdentifiers

// MARK: - Data Models (must be Codable for serialization)

struct SerNodeData: Equatable, Sendable, Codable {
    var label: String
    var value: String
    var config: NodeConfig
}

struct NodeConfig: Equatable, Sendable, Codable {
    var color: String  // "red", "blue", "green", "yellow"
    var shape: String   // "circle", "rectangle", "diamond"
    var size: String    // "small", "medium", "large"
}

struct SerEdgeData: Equatable, Sendable, Codable, Hashable {
    var relation: String  // "depends_on", "references", "extends"
    var weight: Double
    var description: String
}

// MARK: - Content View

struct SerializationExample: View {
    @State var nodes: [Node<SerNodeData>] = makeDemoNodes()
    @State var edges: [Edge<SerEdgeData>] = makeDemoEdges()
    @State var viewport: Viewport = .identity
    @State var statusMessage: String = "Ready"
    @State var jsonPreview: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                Text("Serialization Demo")
                    .font(.headline)

                Spacer()

                Button("Save") { saveToDisk() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button("Load") { loadFromDisk() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Divider().frame(height: 20)

                Button("Export JSON") { exportJSON() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Copy JSON") { copyJSON() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Reset") {
                    nodes = makeDemoNodes()
                    edges = makeDemoEdges()
                    statusMessage = "Reset to defaults"
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            HStack(spacing: 0) {
                // Canvas
                SwiftFlow(
                    nodes: nodes,
                    edges: edges,
                    onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
                    onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
                    onConnect: { edges = addEdge($0, edges: edges) },
                    onViewportChange: { viewport = $0 }
                ) { node in
                    SerNodeView(node: node)
                } overlay: {
                    Background(variant: .dots, gap: 25)
                    Controls(position: .bottomLeft)
                    MiniMap()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // JSON preview sidebar
                if !jsonPreview.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("JSON Preview")
                                .font(.caption.bold())
                            Spacer()
                            Button("✕") { jsonPreview = "" }
                                .buttonStyle(.plain)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)

                        ScrollView {
                            Text(jsonPreview)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                    }
                    .frame(width: 280)
                    .background(Color(white: 0.12))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .overlay(alignment: .bottom) {
            Text(statusMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
                .padding(8)
        }
    }

    // MARK: - Serialization Actions

    func saveToDisk() {
        do {
            let data = try toJSON(nodes: nodes, edges: edges, viewport: viewport)
            // In a real app, write to a file or UserDefaults
            UserDefaults.standard.set(data, forKey: "serialization-demo-graph")
            statusMessage = "Saved: \(nodes.count) nodes, \(edges.count) edges"
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: "serialization-demo-graph") else {
            statusMessage = "No saved graph found"
            return
        }
        do {
            let doc = try fromJSON(data) as SwiftFlowDocument<SerNodeData, SerEdgeData>
            nodes = doc.nodes
            edges = doc.edges
            viewport = doc.viewport ?? .identity
            statusMessage = "Loaded: \(nodes.count) nodes, \(edges.count) edges"
        } catch {
            statusMessage = "Load failed: \(error.localizedDescription)"
        }
    }

    func exportJSON() {
        do {
            let jsonString = try toJSONString(nodes: nodes, edges: edges, viewport: viewport)
            jsonPreview = jsonString
            statusMessage = "JSON exported (\(jsonString.count) chars)"
        } catch {
            statusMessage = "JSON export failed: \(error.localizedDescription)"
        }
    }

    func copyJSON() {
        do {
            let jsonString = try toJSONString(nodes: nodes, edges: edges, viewport: viewport)
            #if canImport(AppKit)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(jsonString, forType: .string)
            #endif
            statusMessage = "JSON copied to clipboard"
        } catch {
            statusMessage = "Copy failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Node View

struct SerNodeView: View {
    let node: Node<SerNodeData>

    private var nodeColor: Color {
        switch node.data.config.color {
        case "red":    return .red.opacity(0.15)
        case "blue":   return .blue.opacity(0.15)
        case "green":  return .green.opacity(0.15)
        case "yellow": return .yellow.opacity(0.15)
        default:       return .gray.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch node.data.config.color {
        case "red":    return .red
        case "blue":   return .blue
        case "green":  return .green
        case "yellow": return .yellow
        default:       return .gray
        }
    }

    private var cornerRadius: CGFloat {
        switch node.data.config.shape {
        case "circle":   return 50
        case "diamond":  return 4
        default:         return 8
        }
    }

    private var nodeScale: CGFloat {
        switch node.data.config.size {
        case "small":  return 0.85
        case "large":  return 1.15
        default:       return 1.0
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Handle(nodeId: node.id, id: "in", type: .target,
                   position: .left, color: borderColor)
            VStack(spacing: 4) {
                Text(node.data.label)
                    .font(.system(size: 12, weight: .semibold))
                Text(node.data.config.color)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            Handle(nodeId: node.id, id: "out", type: .source,
                   position: .right, color: borderColor)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(nodeColor)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(node.selected ? borderColor : Color.gray.opacity(0.3),
                        lineWidth: node.selected ? 2 : 1)
        )
        .scaleEffect(nodeScale)
    }
}

// MARK: - Demo Data

func makeDemoNodes() -> [Node<SerNodeData>] {
    [
        Node(id: "n1", position: XYPosition(x: 100, y: 150),
             data: SerNodeData(label: "Auth Service",
                               value: "v2.1.0",
                               config: NodeConfig(color: "blue", shape: "rectangle", size: "large"))),
        Node(id: "n2", position: XYPosition(x: 400, y: 80),
             data: SerNodeData(label: "Database",
                               value: "pg-14",
                               config: NodeConfig(color: "green", shape: "rectangle", size: "medium"))),
        Node(id: "n3", position: XYPosition(x: 400, y: 220),
             data: SerNodeData(label: "Cache",
                               value: "redis-7",
                               config: NodeConfig(color: "red", shape: "circle", size: "small"))),
        Node(id: "n4", position: XYPosition(x: 650, y: 150),
             data: SerNodeData(label: "API Gateway",
                               value: "v3.0.0",
                               config: NodeConfig(color: "yellow", shape: "rectangle", size: "medium"))),
    ]
}

func makeDemoEdges() -> [Edge<SerEdgeData>] {
    [
        Edge(id: "e1", source: "n1", target: "n2",
             type: .smoothstep,
             label: "depends_on",
             markerEnd: .arrowClosed,
             data: SerEdgeData(relation: "depends_on", weight: 1.0,
                               description: "Auth requires database")),
        Edge(id: "e2", source: "n1", target: "n3",
             type: .smoothstep,
             label: "uses",
             markerEnd: .arrowClosed,
             data: SerEdgeData(relation: "references", weight: 0.5,
                               description: "Auth uses cache")),
        Edge(id: "e3", source: "n2", target: "n4",
             type: .smoothstep,
             label: "feeds",
             markerEnd: .arrowClosed,
             data: SerEdgeData(relation: "depends_on", weight: 1.0,
                               description: "Gateway reads from database")),
        Edge(id: "e4", source: "n3", target: "n4",
             type: .smoothstep,
             label: "feeds",
             markerEnd: .arrowClosed,
             data: SerEdgeData(relation: "depends_on", weight: 0.8,
                               description: "Gateway reads from cache")),
    ]
}

// MARK: - Preview

#Preview {
    SerializationExample()
}
```

## What This Example Demonstrates

- **Codable node data**: `SerNodeData` with nested `NodeConfig` struct — all conforming to `Codable`
- **Codable edge data**: `SerEdgeData` with custom relation, weight, and description fields
- **JSON export**: `toJSONString()` generates formatted JSON with nodes, edges, and viewport
- **JSON import**: `fromJSON()` / `fromJSONString()` parses back into `SwiftFlowDocument`
- **File persistence**: Save/load via `UserDefaults` as a quick demonstration of persistence
- **Clipboard integration**: `copyJSON()` copies the graph JSON to clipboard
- **Viewport persistence**: Viewport state is included in the JSON and restored on load
- **JSON preview panel**: Sidebar shows the serialized JSON for inspection
- **Custom edge labels**: Edges display relation labels at midpoint
- **Config-driven rendering**: Node appearance (color, shape, size) is driven by serializable config data
- **Type-safe deserialization**: The `SwiftFlowDocument<SerNodeData, SerEdgeData>` type ensures correct data types
