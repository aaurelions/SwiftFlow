# Serialization

SwiftFlow supports JSON import and export for persisting graph state.

## Prerequisites

Serialization requires your `NodeData` and `EdgeData` types to conform to `Codable`:

```swift
struct MyNodeData: Equatable, Sendable, Codable {
    var label: String
    var color: String
}

struct MyEdgeData: Equatable, Sendable, Codable, Hashable {
    var weight: Double
    var description: String
}
```

Nodes and edges become `Codable` automatically when their data types conform to `Codable`.

## Export

### toJSON

```swift
func toJSON<NodeData: Codable, EdgeData: Codable>(
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>],
    viewport: Viewport? = nil
) throws -> Data
```

Returns `Data` suitable for writing to a file:

```swift
do {
    let jsonData = try toJSON(nodes: nodes, edges: edges, viewport: viewport)
    try jsonData.write(to: fileURL)
} catch {
    print("Export failed: \(error)")
}
```

### toJSONString

```swift
func toJSONString<NodeData: Codable, EdgeData: Codable>(
    nodes: [Node<NodeData>],
    edges: [Edge<EdgeData>],
    viewport: Viewport? = nil
) throws -> String
```

Returns a formatted JSON string:

```swift
if let jsonString = try? toJSONString(nodes: nodes, edges: edges) {
    print(jsonString)
}
```

## Import

### fromJSON

```swift
func fromJSON<NodeData: Codable, EdgeData: Codable>(
    _ data: Data
) throws -> SwiftFlowDocument<NodeData, EdgeData>
```

Parses JSON data into a `SwiftFlowDocument`:

```swift
do {
    let data = try Data(contentsOf: fileURL)
    let doc = try fromJSON(data) as SwiftFlowDocument<MyNodeData, MyEdgeData>
    nodes = doc.nodes
    edges = doc.edges
    viewport = doc.viewport
} catch {
    print("Import failed: \(error)")
}
```

### fromJSONString

```swift
func fromJSONString<NodeData: Codable, EdgeData: Codable>(
    _ string: String
) throws -> SwiftFlowDocument<NodeData, EdgeData>
```

Parses a JSON string:

```swift
let json = """
{
  "nodes": [...],
  "edges": [...],
  "viewport": { "x": 0, "y": 0, "zoom": 1 }
}
"""
if let doc = try? fromJSONString(json) as SwiftFlowDocument<MyNodeData, MyEdgeData> {
    nodes = doc.nodes
    edges = doc.edges
}
```

## SwiftFlowDocument

The deserialized document structure:

```swift
public struct SwiftFlowDocument<NodeData: Codable, EdgeData: Codable> {
    var nodes: [Node<NodeData>]
    var edges: [Edge<EdgeData>]
    var viewport: Viewport
}
```

## Complete Export/Import Example

```swift
struct FlowEditor: View {
    @State var nodes: [Node<MyNodeData>] = [...]
    @State var edges: [Edge<MyEdgeData>] = [...]
    @State var viewport: Viewport = .identity

    var body: some View {
        VStack {
            HStack {
                Button("Save") { saveGraph() }
                Button("Load") { loadGraph() }
            }

            SwiftFlow(
                nodes: nodes, edges: edges,
                onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
                onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
                onConnect: { edges = addEdge($0, edges: edges) },
                onViewportChange: { viewport = $0 }
            ) { node in
                Text(node.data.label)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(colorFor(node.data.color)))
            }
        }
    }

    func saveGraph() {
        guard let data = try? toJSON(nodes: nodes, edges: edges, viewport: viewport) else { return }
        UserDefaults.standard.set(data, forKey: "saved-graph")
    }

    func loadGraph() {
        guard let data = UserDefaults.standard.data(forKey: "saved-graph"),
              let doc = try? fromJSON(data) as SwiftFlowDocument<MyNodeData, MyEdgeData>
        else { return }
        nodes = doc.nodes
        edges = doc.edges
        viewport = doc.viewport
    }
}
```

## JSON Structure

The output JSON has this structure:

```json
{
  "nodes": [
    {
      "id": "1",
      "position": { "x": 100, "y": 200 },
      "data": { "label": "Start", "color": "green" },
      "type": "default",
      "selected": false,
      "hidden": false,
      "draggable": true,
      ...
    }
  ],
  "edges": [
    {
      "id": "e1-2",
      "source": "1",
      "target": "2",
      "sourceHandle": "out",
      "targetHandle": "in",
      "type": "bezier",
      "animated": false,
      "data": { "weight": 1.0 },
      ...
    }
  ],
  "viewport": {
    "x": 0,
    "y": 0,
    "zoom": 1
  }
}
```

## Limitations

- `NodeStyle` and `EdgeStyle` (which contain `Color` values) are not currently encoded during serialization. These properties are restored to `nil` on import.
- `NodeExtent` is not encoded; extent constraints must be re-applied after import.
- Custom SwiftUI views (from ViewBuilder closures) are not preserved — only the data model is stored.
