import Foundation
import Testing

@testable import SwiftFlow

@Suite("AutoLayout")
struct AutoLayoutTests {

  let nodes: [Node<String>] = [
    Node(id: "1", position: .zero, data: "A"),
    Node(id: "2", position: .zero, data: "B"),
    Node(id: "3", position: .zero, data: "C"),
  ]

  let edges: [Edge<EmptyEdgeData>] = [
    Edge(id: "e1", source: "1", target: "2"),
    Edge(id: "e2", source: "1", target: "3"),
  ]

  @Test func treeLayoutTopToBottom() {
    let changes = computeAutoLayout(
      nodes: nodes, edges: edges, algorithm: .tree(direction: .topToBottom))
    #expect(!changes.isEmpty)
    let result = applyNodeChanges(changes, nodes: nodes)
    // Root (node 1) should be at level 0
    let n1 = result.first { $0.id == "1" }!
    let n2 = result.first { $0.id == "2" }!
    #expect(n1.position.y < n2.position.y)
  }

  @Test func treeLayoutLeftToRight() {
    let changes = computeAutoLayout(
      nodes: nodes, edges: edges, algorithm: .tree(direction: .leftToRight))
    let result = applyNodeChanges(changes, nodes: nodes)
    let n1 = result.first { $0.id == "1" }!
    let n2 = result.first { $0.id == "2" }!
    #expect(n1.position.x < n2.position.x)
  }

  @Test func treeLayoutBottomToTop() {
    let changes = computeAutoLayout(
      nodes: nodes, edges: edges, algorithm: .tree(direction: .bottomToTop))
    let result = applyNodeChanges(changes, nodes: nodes)
    let n1 = result.first { $0.id == "1" }!
    let n2 = result.first { $0.id == "2" }!
    #expect(n1.position.y > n2.position.y)
  }

  @Test func treeLayoutRightToLeft() {
    let changes = computeAutoLayout(
      nodes: nodes, edges: edges, algorithm: .tree(direction: .rightToLeft))
    let result = applyNodeChanges(changes, nodes: nodes)
    let n1 = result.first { $0.id == "1" }!
    let n2 = result.first { $0.id == "2" }!
    #expect(n1.position.x > n2.position.x)
  }

  @Test func gridLayout() {
    let changes = computeAutoLayout(nodes: nodes, edges: edges, algorithm: .grid(columns: 2))
    let result = applyNodeChanges(changes, nodes: nodes)
    // 3 nodes in 2 columns = 2 rows
    let n1 = result[0]
    let n2 = result[1]
    let n3 = result[2]
    // Node 1 and 2 should be in the same row (same Y)
    #expect(n1.position.y == n2.position.y)
    // Node 3 should be in the next row
    #expect(n3.position.y > n1.position.y)
  }

  @Test func forceDirectedLayout() {
    let overlappingNodes: [Node<String>] = [
      Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
      Node(id: "2", position: XYPosition(x: 0, y: 0), data: "B"),
      Node(id: "3", position: XYPosition(x: 0, y: 0), data: "C"),
    ]
    let changes = computeAutoLayout(
      nodes: overlappingNodes, edges: edges,
      algorithm: .forceDirected(iterations: 50)
    )
    let result = applyNodeChanges(changes, nodes: overlappingNodes)
    // Nodes should have spread apart
    let positions = result.map { $0.position }
    let allSame = positions.allSatisfy { $0 == positions[0] }
    #expect(!allSame)
  }

  @Test func emptyNodesReturnsNoChanges() {
    let changes = computeAutoLayout(
      nodes: [Node<String>](), edges: [Edge<EmptyEdgeData>](),
      algorithm: .tree()
    )
    #expect(changes.isEmpty)
  }

  @Test func singleNodeForceDirected() {
    let singleNode = [Node(id: "1", position: .zero, data: "A")]
    let emptyEdges: [Edge<EmptyEdgeData>] = []
    let changes = computeAutoLayout(
      nodes: singleNode, edges: emptyEdges,
      algorithm: .forceDirected()
    )
    #expect(changes.isEmpty)
  }

  @Test func asyncLayout() async {
    let changes = await computeAutoLayoutAsync(
      nodes: nodes, edges: edges,
      algorithm: .grid(columns: 2)
    )
    #expect(!changes.isEmpty)
  }
}
