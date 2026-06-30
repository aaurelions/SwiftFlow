import Combine
import SwiftUI

/// Observable store managing the complete state of a SwiftFlow graph.
///
/// Use `SwiftFlowStore` with `SwiftFlowProvider` for centralized state management,
/// similar to React hook pattern.
///
/// ```swift
/// @StateObject var store = SwiftFlowStore<MyData, EmptyEdgeData>(
///     nodes: initialNodes,
///     edges: initialEdges
/// )
///
/// SwiftFlow(
///     nodes: store.nodes,
///     edges: store.edges,
///     onNodesChange: { store.onNodesChange($0) },
///     onEdgesChange: { store.onEdgesChange($0) },
///     onConnect: { store.onConnect($0) }
/// ) { node in ... }
/// ```
@MainActor
public class SwiftFlowStore<
  NodeData: Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable
>: ObservableObject {
  @Published public var nodes: [Node<NodeData>]
  @Published public var edges: [Edge<EdgeData>]
  @Published public var viewport: Viewport = .identity
  @Published public var selectedNodeIds: Set<String> = []
  @Published public var selectedEdgeIds: Set<String> = []

  public init(nodes: [Node<NodeData>] = [], edges: [Edge<EdgeData>] = []) {
    self.nodes = nodes
    self.edges = edges
  }

  /// Applies an array of node changes to the current nodes.
  public func onNodesChange(_ changes: [NodeChange<NodeData>]) {
    nodes = applyNodeChanges(changes, nodes: nodes)
    selectedNodeIds = Set(nodes.filter(\.selected).map(\.id))
  }

  /// Applies an array of edge changes to the current edges.
  public func onEdgesChange(_ changes: [EdgeChange<EdgeData>]) {
    edges = applyEdgeChanges(changes, edges: edges)
    selectedEdgeIds = Set(edges.filter(\.selected).map(\.id))
  }

  /// Creates a new edge from a connection.
  public func onConnect(_ connection: Connection, defaults: DefaultEdgeOptions? = nil) {
    edges = addEdge(connection, edges: edges, defaults: defaults)
  }

  /// Returns a specific node by ID.
  public func getNode(id: String) -> Node<NodeData>? {
    nodes.first { $0.id == id }
  }

  /// Returns a specific edge by ID.
  public func getEdge(id: String) -> Edge<EdgeData>? {
    edges.first { $0.id == id }
  }

  /// Returns data for the specified node IDs.
  ///
  /// Subscribe to changes via Combine's `$nodes` publisher filtered by ID.
  ///
  /// ```swift
  /// let data = store.getNodesData(ids: ["node-1", "node-2"])
  /// ```
  public func getNodesData(ids: [String]) -> [(id: String, data: NodeData)] {
    let idSet = Set(ids)
    return nodes.filter { idSet.contains($0.id) }.map { ($0.id, $0.data) }
  }

  /// Returns connections for a specific node, optionally filtered by handle type.
  ///
  /// ```swift
  /// let incoming = store.getNodeConnections(nodeId: "1", handleType: .target)
  /// ```
  public func getNodeConnections(
    nodeId: String,
    handleType: HandleType? = nil
  ) -> [Connection] {
    edges.compactMap { edge in
      switch handleType {
      case .source where edge.source == nodeId:
        return Connection(
          source: edge.source, target: edge.target,
          sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle
        )
      case .target where edge.target == nodeId:
        return Connection(
          source: edge.source, target: edge.target,
          sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle
        )
      case nil where edge.source == nodeId || edge.target == nodeId:
        return Connection(
          source: edge.source, target: edge.target,
          sourceHandle: edge.sourceHandle, targetHandle: edge.targetHandle
        )
      default:
        return nil
      }
    }
  }

  /// Whether all nodes have been measured (have known sizes).
  ///
  /// Returns `true` when every node has a non-nil `width` and `height`.
  public var nodesInitialized: Bool {
    !nodes.isEmpty && nodes.allSatisfy { $0.width != nil && $0.height != nil }
  }

  /// Returns a Combine publisher that emits `NodeData` whenever the
  /// specified node's data changes. Useful for fine-grained reactivity
  /// without re-rendering on every graph change.
  ///
  /// ```swift
  /// store.nodeDataPublisher(id: "node-1")
  ///     .sink { data in print("Node 1 data:", data) }
  /// ```
  public func nodeDataPublisher(id: String) -> AnyPublisher<NodeData, Never> {
    $nodes
      .compactMap { nodes in nodes.first(where: { $0.id == id })?.data }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  /// Deletes nodes and edges by ID, returning the deleted elements.
  @discardableResult
  public func deleteElements(
    nodeIds: [String] = [],
    edgeIds: [String] = []
  ) -> (nodes: [Node<NodeData>], edges: [Edge<EdgeData>]) {
    let deletedNodes = nodes.filter { nodeIds.contains($0.id) }
    let deletedEdges = edges.filter { edgeIds.contains($0.id) }
    if !nodeIds.isEmpty {
      let changes = nodeIds.map { NodeChange<NodeData>.remove(id: $0) }
      onNodesChange(changes)
    }
    if !edgeIds.isEmpty {
      let changes = edgeIds.map { EdgeChange<EdgeData>.remove(id: $0) }
      onEdgesChange(changes)
    }
    return (nodes: deletedNodes, edges: deletedEdges)
  }
}
