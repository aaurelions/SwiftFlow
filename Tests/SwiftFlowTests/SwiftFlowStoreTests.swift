import Combine
import Foundation
import Testing

@testable import SwiftFlow

@Suite("SwiftFlowStore")
struct SwiftFlowStoreTests {

  @MainActor
  @Test func initWithDefaults() {
    let store = SwiftFlowStore<String, EmptyEdgeData>()
    #expect(store.nodes.isEmpty)
    #expect(store.edges.isEmpty)
    #expect(store.viewport == .identity)
    #expect(store.selectedNodeIds.isEmpty)
    #expect(store.selectedEdgeIds.isEmpty)
  }

  @MainActor
  @Test func initWithData() {
    let nodes = [Node(id: "1", position: .zero, data: "A")]
    let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
    let store = SwiftFlowStore(nodes: nodes, edges: edges)
    #expect(store.nodes.count == 1)
    #expect(store.edges.count == 1)
  }

  @MainActor
  @Test func onNodesChange() {
    let store = SwiftFlowStore(
      nodes: [Node(id: "1", position: .zero, data: "A")],
      edges: [Edge<EmptyEdgeData>]()
    )
    store.onNodesChange([.selection(id: "1", selected: true)])
    #expect(store.nodes[0].selected == true)
    #expect(store.selectedNodeIds == ["1"])
  }

  @MainActor
  @Test func onEdgesChange() {
    let store = SwiftFlowStore(
      nodes: [Node<String>](),
      edges: [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
    )
    store.onEdgesChange([.selection(id: "e1", selected: true)])
    #expect(store.edges[0].selected == true)
    #expect(store.selectedEdgeIds == ["e1"])
  }

  @MainActor
  @Test func onConnect() {
    let store = SwiftFlowStore<String, EmptyEdgeData>()
    store.onConnect(Connection(source: "1", target: "2"))
    #expect(store.edges.count == 1)
    #expect(store.edges[0].source == "1")
    #expect(store.edges[0].target == "2")
  }

  @MainActor
  @Test func onConnectWithDefaults() {
    let store = SwiftFlowStore<String, EmptyEdgeData>()
    let defaults = DefaultEdgeOptions(type: .smoothstep, animated: true)
    store.onConnect(Connection(source: "1", target: "2"), defaults: defaults)
    #expect(store.edges[0].type == .smoothstep)
    #expect(store.edges[0].animated == true)
  }

  @MainActor
  @Test func getNode() {
    let store = SwiftFlowStore(
      nodes: [Node(id: "1", position: .zero, data: "Hello")],
      edges: [Edge<EmptyEdgeData>]()
    )
    let node = store.getNode(id: "1")
    #expect(node?.data == "Hello")
    #expect(store.getNode(id: "nonexistent") == nil)
  }

  @MainActor
  @Test func getEdge() {
    let store = SwiftFlowStore(
      nodes: [Node<String>](),
      edges: [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
    )
    let edge = store.getEdge(id: "e1")
    #expect(edge?.source == "1")
    #expect(store.getEdge(id: "nonexistent") == nil)
  }

  @MainActor
  @Test func getNodesData() {
    let store = SwiftFlowStore(
      nodes: [
        Node(id: "1", position: .zero, data: "A"),
        Node(id: "2", position: .zero, data: "B"),
        Node(id: "3", position: .zero, data: "C"),
      ],
      edges: [Edge<EmptyEdgeData>]()
    )
    let data = store.getNodesData(ids: ["1", "3"])
    #expect(data.count == 2)
    let ids = Set(data.map(\.id))
    #expect(ids == ["1", "3"])
  }

  @MainActor
  @Test func getNodeConnections() {
    let store = SwiftFlowStore(
      nodes: [Node<String>](),
      edges: [
        Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2"),
        Edge<EmptyEdgeData>(id: "e2", source: "2", target: "3"),
        Edge<EmptyEdgeData>(id: "e3", source: "1", target: "3"),
      ]
    )
    let allConns = store.getNodeConnections(nodeId: "1")
    #expect(allConns.count == 2)

    let sourceConns = store.getNodeConnections(nodeId: "1", handleType: .source)
    #expect(sourceConns.count == 2)

    let targetConns = store.getNodeConnections(nodeId: "1", handleType: .target)
    #expect(targetConns.count == 0)

    let targetConns2 = store.getNodeConnections(nodeId: "2", handleType: .target)
    #expect(targetConns2.count == 1)
  }

  @MainActor
  @Test func nodesInitialized() {
    let store = SwiftFlowStore(
      nodes: [Node(id: "1", position: .zero, data: "A")],
      edges: [Edge<EmptyEdgeData>]()
    )
    #expect(store.nodesInitialized == false)  // width/height are nil

    store.onNodesChange([.dimensions(id: "1", width: 100, height: 50)])
    #expect(store.nodesInitialized == true)
  }

  @MainActor
  @Test func nodesInitializedEmpty() {
    let store = SwiftFlowStore<String, EmptyEdgeData>()
    #expect(store.nodesInitialized == false)
  }

  @MainActor
  @Test func deleteElements() {
    let store = SwiftFlowStore(
      nodes: [
        Node(id: "1", position: .zero, data: "A"),
        Node(id: "2", position: .zero, data: "B"),
      ],
      edges: [
        Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
      ]
    )
    let deleted = store.deleteElements(nodeIds: ["1"], edgeIds: ["e1"])
    #expect(deleted.nodes.count == 1)
    #expect(deleted.edges.count == 1)
    #expect(store.nodes.count == 1)
    #expect(store.nodes[0].id == "2")
    #expect(store.edges.isEmpty)
  }

  @MainActor
  @Test func nodeDataPublisher() {
    let store = SwiftFlowStore(
      nodes: [Node(id: "1", position: .zero, data: "Initial")],
      edges: [Edge<EmptyEdgeData>]()
    )
    var received: [String] = []
    let cancellable = store.nodeDataPublisher(id: "1")
      .sink { data in received.append(data) }

    // Initial value
    #expect(received == ["Initial"])

    // Update data
    var updated = store.nodes[0]
    updated.data = "Updated"
    store.onNodesChange([.replace(id: "1", item: updated)])
    #expect(received == ["Initial", "Updated"])

    // Same data shouldn't fire (removeDuplicates)
    var sameData = store.nodes[0]
    sameData.position = XYPosition(x: 999, y: 999)  // Different position, same data
    store.onNodesChange([.replace(id: "1", item: sameData)])
    #expect(received == ["Initial", "Updated"])  // No new emission

    _ = cancellable
  }

  @MainActor
  @Test func selectionTracking() {
    let store = SwiftFlowStore(
      nodes: [
        Node(id: "1", position: .zero, data: "A"),
        Node(id: "2", position: .zero, data: "B"),
      ],
      edges: [Edge<EmptyEdgeData>]()
    )
    store.onNodesChange([
      .selection(id: "1", selected: true),
      .selection(id: "2", selected: true),
    ])
    #expect(store.selectedNodeIds == ["1", "2"])

    store.onNodesChange([.selection(id: "1", selected: false)])
    #expect(store.selectedNodeIds == ["2"])
  }
}
