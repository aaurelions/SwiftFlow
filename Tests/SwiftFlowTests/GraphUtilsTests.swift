import Foundation
import Testing

@testable import SwiftFlow

@Suite("GraphUtils")
struct GraphUtilsTests {

  let nodes: [Node<String>] = [
    Node(id: "1", position: .zero, data: "A"),
    Node(id: "2", position: XYPosition(x: 200, y: 0), data: "B"),
    Node(id: "3", position: XYPosition(x: 400, y: 0), data: "C"),
    Node(id: "4", position: XYPosition(x: 0, y: 200), data: "D"),
  ]

  let edges: [Edge<EmptyEdgeData>] = [
    Edge(id: "e1", source: "1", target: "2"),
    Edge(id: "e2", source: "1", target: "3"),
    Edge(id: "e3", source: "2", target: "3"),
  ]

  @Test func incomersForNode3() {
    let node3 = nodes[2]
    let incomers = getIncomers(node: node3, nodes: nodes, edges: edges)
    let ids = Set(incomers.map(\.id))
    #expect(ids == ["1", "2"])
  }

  @Test func incomersNone() {
    let node1 = nodes[0]
    let incomers = getIncomers(node: node1, nodes: nodes, edges: edges)
    #expect(incomers.isEmpty)
  }

  @Test func outgoersForNode1() {
    let node1 = nodes[0]
    let outgoers = getOutgoers(node: node1, nodes: nodes, edges: edges)
    let ids = Set(outgoers.map(\.id))
    #expect(ids == ["2", "3"])
  }

  @Test func outgoersNone() {
    let node3 = nodes[2]
    let outgoers = getOutgoers(node: node3, nodes: nodes, edges: edges)
    #expect(outgoers.isEmpty)
  }

  @Test func connectedEdgesForSingleNode() {
    let node1 = nodes[0]
    let connected = getConnectedEdges(node: node1, edges: edges)
    #expect(connected.count == 2)
    let ids = Set(connected.map(\.id))
    #expect(ids == ["e1", "e2"])
  }

  @Test func connectedEdgesForMultipleNodes() {
    let selectedNodes = [nodes[0], nodes[1]]
    let connected = getConnectedEdges(nodes: selectedNodes, edges: edges)
    #expect(connected.count == 3)
  }

  @Test func connectedEdgesDisconnected() {
    let node4 = nodes[3]
    let connected = getConnectedEdges(node: node4, edges: edges)
    #expect(connected.isEmpty)
  }

  // MARK: - Deletion

  @Test func deletingParentRemovesDescendantsAndTheirEdges() {
    let nodes = [
      Node(id: "p", position: .zero, data: "P"),
      Node(id: "c", position: .zero, data: "C", parentId: "p"),
      Node(id: "g", position: .zero, data: "G", parentId: "c"),
      Node(id: "x", position: .zero, data: "X"),
    ]
    let edges = [
      Edge<EmptyEdgeData>(id: "cx", source: "c", target: "x"),
      Edge<EmptyEdgeData>(id: "xx", source: "x", target: "x"),
    ]
    let result = elementsToDelete(nodes: nodes, edges: edges, nodeIds: ["p"], edgeIds: [])
    #expect(Set(result.nodes.map(\.id)) == ["p", "c", "g"])
    #expect(result.edges.map(\.id) == ["cx"])
  }

  @Test func nonDeletableChildIsKept() {
    let nodes = [
      Node(id: "p", position: .zero, data: "P"),
      Node(id: "c", position: .zero, data: "C", parentId: "p", deletable: false),
    ]
    let edges: [Edge<EmptyEdgeData>] = []
    let result = elementsToDelete(nodes: nodes, edges: edges, nodeIds: ["p"], edgeIds: [])
    #expect(result.nodes.map(\.id) == ["p"])
  }
}
