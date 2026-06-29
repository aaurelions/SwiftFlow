# Resizable Nodes Example

Demonstrates resizable nodes with `NodeResizeControl`, `NodeResizer`, and `NodeToolbar` for per-node contextual actions.

```swift
import SwiftUI
import SwiftFlow

// MARK: - Data Models

struct ResizeNodeData: Equatable, Sendable, Codable {
    var title: String
    var content: String
}

// MARK: - Content View

struct ResizableNodesExample: View {
    @State var nodes: [Node<ResizeNodeData>] = [
        Node(
            id: "note1",
            position: XYPosition(x: 100, y: 100),
            data: ResizeNodeData(title: "Meeting Notes", content: "Discuss Q4 roadmap and resource allocation for the engineering team."),
            type: "note",
            width: 240, height: 160
        ),
        Node(
            id: "note2",
            position: XYPosition(x: 400, y: 100),
            data: ResizeNodeData(title: "Action Items", content: "1. Update API schema\n2. Fix edge rendering\n3. Write unit tests\n4. Deploy to staging"),
            type: "note",
            width: 200, height: 200
        ),
        Node(
            id: "card1",
            position: XYPosition(x: 100, y: 350),
            data: ResizeNodeData(title: "Product Card", content: "Price: $29.99\nIn stock: Yes\nSKU: PROD-001"),
            type: "card",
            width: 220, height: 130
        ),
    ]

    @State var edges: [Edge<EmptyEdgeData>] = [
        Edge(id: "e1", source: "note1", target: "note2",
             type: .smoothstep, markerEnd: .arrowClosed),
        Edge(id: "e2", source: "note2", target: "card1",
             type: .smoothstep, markerEnd: .arrowClosed),
    ]

    var body: some View {
        SwiftFlow(
            nodes: nodes,
            edges: edges,
            onNodesChange: { nodes = applyNodeChanges($0, nodes: nodes) },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            snapToGrid: true,
            snapGrid: (x: 10, y: 10)
        ) { node in
            ResizableNodeView(node: node,
                onResize: { w, h in
                    nodes = applyNodeChanges([
                        .dimensions(id: node.id, width: w, height: h)
                    ], nodes: nodes)
                },
                onDuplicate: {
                    duplicateNode(node)
                },
                onDelete: {
                    deleteNode(node)
                }
            )
        } overlay: {
            Background(variant: .lines, color: .gray.opacity(0.1), gap: 40)
            Controls()
            MiniMap()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func duplicateNode(_ node: Node<ResizeNodeData>) {
        var copy = node
        copy.id = "\(node.id)-copy-\(nodes.count)"
        copy.position = XYPosition(x: node.position.x + 40, y: node.position.y + 40)
        copy.selected = false
        nodes = applyNodeChanges([.add(item: copy)], nodes: nodes)
    }

    func deleteNode(_ node: Node<ResizeNodeData>) {
        let connectedEdgeIds = edges
            .filter { $0.source == node.id || $0.target == node.id }
            .map(\.id)
        nodes = applyNodeChanges([.remove(id: node.id)], nodes: nodes)
        edges = applyEdgeChanges(connectedEdgeIds.map { .remove(id: $0) }, edges: edges)
    }
}

// MARK: - Resizable Node View

struct ResizableNodeView: View {
    let node: Node<ResizeNodeData>
    let onResize: (CGFloat, CGFloat) -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    private var accentColor: Color {
        switch node.type {
        case "note":  return .blue
        case "card":  return .purple
        default:      return .gray
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Node content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                    Text(node.data.title)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.1))

                Divider()

                // Content
                Text(node.data.content)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)

                // Connection handles at bottom
                HStack {
                    Handle(nodeId: node.id, id: "in", type: .target,
                           position: .left, color: accentColor)
                    Spacer()
                    Handle(nodeId: node.id, id: "out", type: .source,
                           position: .right, color: accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(node.selected ? accentColor : Color.gray.opacity(0.3),
                            lineWidth: node.selected ? 2 : 1)
            )

            // Resize handles (visible when selected)
            if node.selected {
                // Corner handles
                NodeResizeControl(
                    nodeId: node.id,
                    position: .bottomRight,
                    minWidth: 120, maxWidth: 600,
                    minHeight: 80, maxHeight: 500,
                    color: accentColor,
                    handleSize: 11,
                    onResize: onResize
                )
                NodeResizeControl(
                    nodeId: node.id,
                    position: .bottomLeft,
                    minWidth: 120, maxWidth: 600,
                    minHeight: 80, maxHeight: 500,
                    color: accentColor,
                    handleSize: 11,
                    onResize: onResize
                )
                NodeResizeControl(
                    nodeId: node.id,
                    position: .topRight,
                    minWidth: 120, maxWidth: 600,
                    minHeight: 80, maxHeight: 500,
                    color: accentColor,
                    handleSize: 11,
                    onResize: onResize
                )

                // Edge handles
                NodeResizeControl(
                    nodeId: node.id,
                    position: .right,
                    minWidth: 120, maxWidth: 600,
                    minHeight: 80, maxHeight: 500,
                    color: accentColor,
                    handleSize: 9,
                    onResize: onResize
                )
                NodeResizeControl(
                    nodeId: node.id,
                    position: .bottom,
                    minWidth: 120, maxWidth: 600,
                    minHeight: 80, maxHeight: 500,
                    color: accentColor,
                    handleSize: 9,
                    onResize: onResize
                )

                // NodeToolbar for quick actions
                NodeToolbar(position: .top, align: .center, offset: 10) {
                    HStack(spacing: 4) {
                        Button(action: {
                            onResize(300, 200)
                        }) {
                            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .help("Reset size")

                        Divider().frame(height: 14)

                        Button(action: onDuplicate) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .help("Duplicate")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .help("Delete")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                }
            }
        }
        .frame(width: max(node.width ?? 240, node.width ?? 240),
               height: max(node.height ?? 160, node.height ?? 160))
    }
}

// MARK: - Preview

#Preview {
    ResizableNodesExample()
}
```

## What This Example Demonstrates

- **NodeResizeControl**: Individual resize handles at specific positions (corners and edges) with per-handle constraints
- **Multi-handle resize**: Five resize handles (three corners, two edges) for comprehensive resizing
- **Per-node dimensions**: Nodes use `width` and `height` properties for explicit sizing
- **Dimension change application**: Using `NodeChange.dimensions` to update node size through the change pipeline
- **Snap-to-grid with resize**: Grid snapping works alongside manual resize for aligned layouts
- **NodeToolbar**: Contextual floating toolbar with reset size, duplicate, and delete actions
- **Selection-aware UI**: Resize handles and toolbar only appear when the node is selected
- **Accent color theming**: Resize handles and node decorations match the node type color
- **Handle layering**: ZStack ensures resize handles render on top of node content
- **Custom sized nodes**: Explicit width/height override the default measured-from-content sizing
