import Foundation
import Testing

@testable import SwiftFlow

@Suite("GeometryUtils")
struct GeometryUtilsTests {

  @Test func getNodesBoundsBasic() {
    let nodes = [
      Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
      Node(id: "2", position: XYPosition(x: 200, y: 100), data: "B"),
    ]
    let sizes: [String: CGSize] = [
      "1": CGSize(width: 100, height: 50),
      "2": CGSize(width: 100, height: 50),
    ]
    let bounds = getNodesBounds(nodes: nodes, nodeSizes: sizes)
    #expect(bounds.minX == 0)
    #expect(bounds.minY == 0)
    #expect(bounds.maxX == 300)  // 200 + 100
    #expect(bounds.maxY == 150)  // 100 + 50
  }

  @Test func getNodesBoundsEmpty() {
    let nodes: [Node<String>] = []
    let bounds = getNodesBounds(nodes: nodes, nodeSizes: [:])
    #expect(bounds == .zero)
  }

  @Test func getNodesBoundsHiddenExcluded() {
    let nodes = [
      Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
      Node(id: "2", position: XYPosition(x: 1000, y: 1000), data: "B", hidden: true),
    ]
    let sizes: [String: CGSize] = [
      "1": CGSize(width: 100, height: 50)
    ]
    let bounds = getNodesBounds(nodes: nodes, nodeSizes: sizes)
    #expect(bounds.maxX == 100)  // Only node 1
  }

  @Test func getNodesBoundsDefaultSizes() {
    let nodes = [
      Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")
    ]
    let bounds = getNodesBounds(nodes: nodes, nodeSizes: [:])
    #expect(bounds.width == 150)  // default width
    #expect(bounds.height == 50)  // default height
  }

  @Test func viewportForBounds() {
    let bounds = CGRect(x: 0, y: 0, width: 400, height: 200)
    let viewportSize = CGSize(width: 800, height: 600)
    let vp = getViewportForBounds(bounds: bounds, viewportSize: viewportSize, padding: 80)
    #expect(vp.zoom > 0)
    #expect(vp.zoom <= Viewport.maxZoom)
  }

  @Test func viewportForBoundsSmallContent() {
    let bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
    let viewportSize = CGSize(width: 800, height: 600)
    let vp = getViewportForBounds(bounds: bounds, viewportSize: viewportSize, maxZoom: 2.0)
    #expect(vp.zoom <= 2.0)  // Respects maxZoom
  }

  @Test func isNodeCheck() {
    let node = Node(id: "1", position: .zero, data: "hello")
    #expect(isNode(node, ofType: String.self))
    #expect(!isNode("not a node", ofType: String.self))
  }

  @Test func isEdgeCheck() {
    let edge = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    #expect(isEdge(edge, ofType: EmptyEdgeData.self))
    #expect(!isEdge("not an edge", ofType: EmptyEdgeData.self))
  }
  @Test func fittedBoundsAreCenteredWhenZoomIsCapped() {
    let bounds = CGRect(x: -100, y: 70, width: 100, height: 50)
    let vp = getViewportForBounds(
      bounds: bounds,
      viewportSize: CGSize(width: 800, height: 600), maxZoom: 1.5)
    #expect(vp.zoom == 1.5)
    #expect(bounds.midX * vp.zoom + vp.x == 400)
    #expect(bounds.midY * vp.zoom + vp.y == 300)
  }

  // MARK: - Absolute Positions and Origins

  @Test func childBoundsAreRelativeToParent() {
    let nodes = [
      Node(id: "p", position: XYPosition(x: 100, y: 100), data: "P"),
      Node(id: "c", position: XYPosition(x: 50, y: 20), data: "C", parentId: "p"),
    ]
    let sizes: [String: CGSize] = [
      "p": CGSize(width: 10, height: 10), "c": CGSize(width: 10, height: 10),
    ]
    let bounds = getNodesBounds(nodes: nodes, nodeSizes: sizes)
    #expect(bounds == CGRect(x: 100, y: 100, width: 60, height: 30))
  }

  @Test func nodeOriginShiftsTopLeft() {
    let nodes = [
      Node(id: "a", position: XYPosition(x: 100, y: 100), data: "A", origin: .center)
    ]
    let positions = nodeTopLeftPositions(
      nodes: nodes, nodeSizes: ["a": CGSize(width: 40, height: 20)])
    #expect(positions["a"] == XYPosition(x: 80, y: 90))
  }

  @Test func canvasNodeOriginAppliesToNodesWithDefaultOrigin() {
    let nodes = [Node(id: "a", position: XYPosition(x: 100, y: 100), data: "A")]
    let positions = nodeTopLeftPositions(
      nodes: nodes, nodeSizes: ["a": CGSize(width: 40, height: 20)], nodeOrigin: .center)
    #expect(positions["a"] == XYPosition(x: 80, y: 90))
  }

  @Test func cyclicParentsAreReportedAndIgnored() {
    let nodes = [
      Node(id: "a", position: XYPosition(x: 1, y: 0), data: "A", parentId: "b"),
      Node(id: "b", position: XYPosition(x: 2, y: 0), data: "B", parentId: "a"),
    ]
    var cycles: [String] = []
    let positions = nodeTopLeftPositions(
      nodes: nodes, nodeSizes: [:], onCycle: { cycles.append($0) })
    #expect(!cycles.isEmpty)
    #expect(positions.count == 2)
  }

  @Test func explicitNodeSizeIsUsedBeforeDefault() {
    let node = Node(id: "a", position: .zero, data: "A", width: 300, height: 120)
    #expect(resolvedNodeSize(node, nodeSizes: [:]) == CGSize(width: 300, height: 120))
    #expect(
      resolvedNodeSize(node, nodeSizes: ["a": CGSize(width: 1, height: 2)])
        == CGSize(width: 1, height: 2))
  }
}
