import Testing
import Foundation
@testable import SwiftFlow

@Suite("NodeIntersection")
struct NodeIntersectionTests {

    @Test func intersectingNodes() {
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 50, y: 25), data: "B"),
            Node(id: "3", position: XYPosition(x: 500, y: 500), data: "C"),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
            "3": CGSize(width: 100, height: 50),
        ]
        let intersecting = getIntersectingNodes(node: nodes[0], nodes: nodes, nodeSizes: sizes)
        #expect(intersecting.count == 1)
        #expect(intersecting[0].id == "2")
    }

    @Test func noIntersection() {
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 500, y: 500), data: "B"),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        let intersecting = getIntersectingNodes(node: nodes[0], nodes: nodes, nodeSizes: sizes)
        #expect(intersecting.isEmpty)
    }

    @Test func hiddenNodesExcluded() {
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 0, y: 0), data: "B", hidden: true),
        ]
        let intersecting = getIntersectingNodes(node: nodes[0], nodes: nodes)
        #expect(intersecting.isEmpty)
    }

    @Test func isNodeIntersectingTrue() {
        let a = Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")
        let b = Node(id: "2", position: XYPosition(x: 50, y: 25), data: "B")
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        #expect(isNodeIntersecting(node: a, otherNode: b, nodeSizes: sizes))
    }

    @Test func isNodeIntersectingFalse() {
        let a = Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")
        let b = Node(id: "2", position: XYPosition(x: 500, y: 500), data: "B")
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        #expect(!isNodeIntersecting(node: a, otherNode: b, nodeSizes: sizes))
    }

    @Test func defaultSizesUsed() {
        let a = Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")
        let b = Node(id: "2", position: XYPosition(x: 100, y: 25), data: "B")
        // Default size is 150x50, so 100 < 150, they should overlap
        #expect(isNodeIntersecting(node: a, otherNode: b))
    }
}
