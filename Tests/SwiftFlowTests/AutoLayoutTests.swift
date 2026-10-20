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
  @Test func invalidLayoutCountsAreSafe() {
    for columns in [0, -2] {
      let result = applyNodeChanges(
        computeAutoLayout(nodes: nodes, edges: edges, algorithm: .grid(columns: columns)),
        nodes: nodes)
      #expect(result.allSatisfy { $0.position.x == 0 })
      #expect(result[1].position.y > result[0].position.y)
    }
    for iterations in [0, -1] {
      #expect(
        computeAutoLayout(
          nodes: nodes, edges: edges, algorithm: .forceDirected(iterations: iterations)
        ).isEmpty)
    }
  }

  @Test func gridUsesLargestSizeInEachRowAndColumn() {
    let sizes: [String: CGSize] = [
      "1": CGSize(width: 400, height: 200),
      "2": CGSize(width: 50, height: 30),
      "3": CGSize(width: 80, height: 40),
    ]
    let result = applyNodeChanges(
      computeAutoLayout(nodes: nodes, edges: edges, algorithm: .grid(columns: 2), nodeSizes: sizes),
      nodes: nodes)
    #expect(result[1].position.x == 450)
    #expect(result[2].position.y == 250)
  }

  @Test func treePreservesInputOrderAndSpacesVariableSizes() {
    let sizes: [String: CGSize] = [
      "2": CGSize(width: 400, height: 200),
      "3": CGSize(width: 50, height: 30),
    ]
    for direction in [LayoutDirection.topToBottom, .leftToRight] {
      let result = applyNodeChanges(
        computeAutoLayout(
          nodes: nodes, edges: edges,
          algorithm: .tree(direction: direction), nodeSizes: sizes), nodes: nodes)
      if direction == .topToBottom {
        #expect(result[2].position.x - result[1].position.x == 450)
        #expect(result[1].position.x == -250)
      } else {
        #expect(result[2].position.y - result[1].position.y == 250)
        #expect(result[1].position.y == -140)
      }
    }
  }

}
