import SwiftUI

/// A view wrapper that provides a `SwiftFlowStore` to child views via `@EnvironmentObject`.
///
/// Use `SwiftFlowProvider` to share graph state across multiple views.
///
/// ```swift
/// SwiftFlowProvider(nodes: initialNodes, edges: initialEdges) { store in
///     SwiftFlow(
///         nodes: store.nodes,
///         edges: store.edges,
///         onNodesChange: { store.onNodesChange($0) },
///         onEdgesChange: { store.onEdgesChange($0) },
///         onConnect: { store.onConnect($0) }
///     ) { node in
///         MyNodeView(node: node)
///     }
/// }
/// ```
public struct SwiftFlowProvider<
    NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable, Content: View
>: View {
    @StateObject private var store: SwiftFlowStore<NodeData, EdgeData>
    @ViewBuilder public var content: (SwiftFlowStore<NodeData, EdgeData>) -> Content

    public init(
        nodes: [Node<NodeData>] = [],
        edges: [Edge<EdgeData>] = [],
        @ViewBuilder content: @escaping (SwiftFlowStore<NodeData, EdgeData>) -> Content
    ) {
        _store = StateObject(wrappedValue: SwiftFlowStore(nodes: nodes, edges: edges))
        self.content = content
    }

    public var body: some View {
        content(store)
            .environmentObject(store)
    }
}
